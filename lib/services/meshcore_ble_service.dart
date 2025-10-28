import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/ble_packet_log.dart';
import 'ble/ble_connection_manager.dart';
import 'ble/ble_command_sender.dart';
import 'ble/ble_response_handler.dart';
import 'protocol/frame_builder.dart';
import 'meshcore_constants.dart';

/// Callback types for MeshCore events
typedef OnContactCallback = void Function(Contact contact);
typedef OnContactsCompleteCallback = void Function(List<Contact> contacts);
typedef OnMessageCallback = void Function(Message message);
typedef OnTelemetryCallback =
    void Function(Uint8List publicKey, Uint8List lppData);
typedef OnSelfInfoCallback = void Function(Map<String, dynamic> selfInfo);
typedef OnDeviceInfoCallback = void Function(Map<String, dynamic> deviceInfo);
typedef OnNoMoreMessagesCallback = void Function();
typedef OnMessageWaitingCallback = void Function();
typedef OnLoginSuccessCallback =
    void Function(
      Uint8List publicKeyPrefix,
      int permissions,
      bool isAdmin,
      int tag,
    );
typedef OnLoginFailCallback = void Function(Uint8List publicKeyPrefix);
typedef OnAdvertReceivedCallback = void Function(Uint8List publicKey);
typedef OnPathUpdatedCallback = void Function(Uint8List publicKey);
typedef OnMessageSentCallback =
    void Function(int expectedAckTag, int suggestedTimeoutMs, bool isFloodMode);
typedef OnMessageDeliveredCallback =
    void Function(int ackCode, int roundTripTimeMs);
typedef OnMessageEchoDetectedCallback =
    void Function(String messageId, int echoCount, int snrRaw, int rssiDbm);
typedef OnStatusResponseCallback =
    void Function(Uint8List publicKeyPrefix, Uint8List statusData);
typedef OnBinaryResponseCallback =
    void Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData);
typedef OnBatteryAndStorageCallback =
    void Function(int millivolts, int? usedKb, int? totalKb);
typedef OnErrorCallback = void Function(String error, {int? errorCode});
typedef OnContactNotFoundCallback = void Function(Uint8List? contactPublicKey);
typedef OnChannelInfoCallback =
    void Function(int channelIdx, String channelName);
typedef OnConnectionStateCallback = void Function(bool isConnected);
typedef OnReconnectionAttemptCallback =
    void Function(int attemptNumber, int maxAttempts);
typedef OnRssiUpdateCallback = void Function(int rssi);

/// MeshCore BLE Service - coordinates BLE communication components
class MeshCoreBleService {
  // Component instances
  final BleConnectionManager _connectionManager = BleConnectionManager();
  final BleCommandSender _commandSender = BleCommandSender();
  final BleResponseHandler _responseHandler = BleResponseHandler();

  // Event callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
  OnReconnectionAttemptCallback? onReconnectionAttempt;
  OnRssiUpdateCallback? onRssiUpdate;
  OnContactCallback? onContactReceived;
  OnContactsCompleteCallback? onContactsComplete;
  OnMessageCallback? onMessageReceived;
  OnTelemetryCallback? onTelemetryReceived;
  OnSelfInfoCallback? onSelfInfoReceived;
  OnDeviceInfoCallback? onDeviceInfoReceived;
  OnNoMoreMessagesCallback? onNoMoreMessages;
  OnMessageWaitingCallback? onMessageWaiting;
  OnLoginSuccessCallback? onLoginSuccess;
  OnLoginFailCallback? onLoginFail;
  OnAdvertReceivedCallback? onAdvertReceived;
  OnPathUpdatedCallback? onPathUpdated;
  OnMessageSentCallback? onMessageSent;
  OnMessageDeliveredCallback? onMessageDelivered;
  OnMessageEchoDetectedCallback? onMessageEchoDetected;
  OnStatusResponseCallback? onStatusResponse;
  OnBinaryResponseCallback? onBinaryResponse;
  OnBatteryAndStorageCallback? onBatteryAndStorage;
  OnErrorCallback? onError;
  OnContactNotFoundCallback? onContactNotFound;
  OnChannelInfoCallback? onChannelInfoReceived;

  // Activity callbacks (for blinking indicators)
  VoidCallback? onRxActivity;
  VoidCallback? onTxActivity;

  // Constructor
  MeshCoreBleService() {
    _setupCallbacks();
  }

  // Setup callbacks between components
  void _setupCallbacks() {
    // Connection manager callbacks
    _connectionManager.onConnectionStateChanged = (isConnected) {
      onConnectionStateChanged?.call(isConnected);
    };
    _connectionManager.onError = (error) {
      onError?.call(error);
    };
    _connectionManager.onReconnectionAttempt = (attemptNumber, maxAttempts) {
      debugPrint(
        '🔄 [Service] Reconnection attempt $attemptNumber/$maxAttempts',
      );
      onReconnectionAttempt?.call(attemptNumber, maxAttempts);
    };
    _connectionManager.onRssiUpdate = (rssi) {
      onRssiUpdate?.call(rssi);
    };

    // Command sender callbacks
    _commandSender.onError = (error) {
      onError?.call(error);
    };
    _commandSender.onTxActivity = () {
      onTxActivity?.call();
    };

    // Response handler callbacks
    _responseHandler.onContactReceived = (contact) {
      debugPrint('🔔 [BleService] onContactReceived - "${contact.advName}" - forwarding to ConnectionProvider');
      onContactReceived?.call(contact);
    };
    _responseHandler.onContactsComplete = (contacts) {
      debugPrint('🔔 [BleService] onContactsComplete - ${contacts.length} contacts - forwarding to ConnectionProvider');
      onContactsComplete?.call(contacts);
    };
    _responseHandler.onMessageReceived = (message) {
      debugPrint('🔔 [BleService] onMessageReceived - forwarding to ConnectionProvider');
      onMessageReceived?.call(message);
    };
    _responseHandler.onTelemetryReceived = (publicKey, lppData) {
      debugPrint('🔔 [BleService] onTelemetryReceived - ${lppData.length} bytes - forwarding to ConnectionProvider');
      onTelemetryReceived?.call(publicKey, lppData);
    };
    _responseHandler.onSelfInfoReceived = (selfInfo) {
      // Extract our node hash (first byte of public key) for echo detection
      if (selfInfo['publicKey'] != null) {
        final publicKey = selfInfo['publicKey'] as Uint8List;
        if (publicKey.isNotEmpty) {
          _responseHandler.setOurNodeHash(publicKey[0]);
        }
      }
      onSelfInfoReceived?.call(selfInfo);
    };
    _responseHandler.onDeviceInfoReceived = (deviceInfo) {
      onDeviceInfoReceived?.call(deviceInfo);
    };
    _responseHandler.onNoMoreMessages = () {
      onNoMoreMessages?.call();
    };
    _responseHandler.onMessageWaiting = () {
      onMessageWaiting?.call();
    };
    _responseHandler.onLoginSuccess =
        (publicKeyPrefix, permissions, isAdmin, tag) {
          onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
        };
    _responseHandler.onLoginFail = (publicKeyPrefix) {
      onLoginFail?.call(publicKeyPrefix);
    };
    _responseHandler.onAdvertReceived = (publicKey) {
      debugPrint('🔔 [BleService] onAdvertReceived - forwarding to ConnectionProvider');
      onAdvertReceived?.call(publicKey);
    };
    _responseHandler.onPathUpdated = (publicKey) {
      debugPrint('🔔 [BleService] onPathUpdated - forwarding to ConnectionProvider');
      onPathUpdated?.call(publicKey);
    };
    _responseHandler.onMessageSent =
        (expectedAckTag, suggestedTimeoutMs, isFloodMode) {
          onMessageSent?.call(expectedAckTag, suggestedTimeoutMs, isFloodMode);
        };
    _responseHandler.onMessageDelivered = (ackCode, roundTripTimeMs) {
      onMessageDelivered?.call(ackCode, roundTripTimeMs);
    };
    _responseHandler.onMessageEchoDetected =
        (messageId, echoCount, snrRaw, rssiDbm) {
          onMessageEchoDetected?.call(messageId, echoCount, snrRaw, rssiDbm);
        };
    _responseHandler.onStatusResponse = (publicKeyPrefix, statusData) {
      onStatusResponse?.call(publicKeyPrefix, statusData);
    };
    _responseHandler.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      onBinaryResponse?.call(publicKeyPrefix, tag, responseData);
    };
    _responseHandler.onBatteryAndStorage = (millivolts, usedKb, totalKb) {
      onBatteryAndStorage?.call(millivolts, usedKb, totalKb);
    };
    _responseHandler.onError = (error, {int? errorCode}) {
      onError?.call(error, errorCode: errorCode);
    };
    _responseHandler.onContactNotFound = (contactPublicKey) {
      onContactNotFound?.call(contactPublicKey);
    };
    _responseHandler.onChannelInfoReceived = (channelIdx, channelName) {
      onChannelInfoReceived?.call(channelIdx, channelName);
    };
    _responseHandler.onRxActivity = () {
      onRxActivity?.call();
    };
  }

  // Getters
  bool get isConnected => _connectionManager.isConnected;
  bool get isReconnecting => _connectionManager.isReconnecting;
  int get reconnectionAttempt => _connectionManager.reconnectionAttempt;
  int get maxReconnectionAttempts => _connectionManager.maxReconnectionAttempts;
  int get rxPacketCount => _responseHandler.rxPacketCount;
  int get txPacketCount => _commandSender.txPacketCount;
  List<BlePacketLog> get packetLogs {
    // Merge logs from both sender and handler
    final allLogs = [
      ..._commandSender.packetLogs,
      ..._responseHandler.packetLogs,
    ];
    allLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allLogs;
  }

  /// Scan for MeshCore devices
  Stream<ScanResult> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _connectionManager.scanForDevices(timeout: timeout);
  }

  /// Connect to a MeshCore device
  Future<bool> connect(BluetoothDevice device) async {
    final success = await _connectionManager.connect(device);
    if (success) {
      try {
        // Setup command sender with RX characteristic
        _commandSender.setRxCharacteristic(_connectionManager.rxCharacteristic);

        // Wire up command queue between sender and response handler
        _responseHandler.setCommandQueue(_commandSender.commandQueue);

        // Setup response handler with TX characteristic
        if (_connectionManager.txCharacteristic != null) {
          _responseHandler.subscribeToNotifications(
            _connectionManager.txCharacteristic!,
          );
        }

        // Send initial device query and wait for responses
        await _sendDeviceQuery();

        debugPrint('✅ [Service] Device initialization complete');
        return true;
      } catch (e) {
        debugPrint('❌ [Service] Device initialization failed: $e');
        // Disconnect on initialization failure
        await disconnect();
        onError?.call('Device initialization failed: $e');
        return false;
      }
    }
    return success;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    await _connectionManager.disconnect();
  }

  /// Send initial device query and sync clock
  Future<void> _sendDeviceQuery() async {
    // STEP 1: Send device query FIRST to get device capabilities
    // This is the first command to send per protocol documentation
    debugPrint(
      '🔍 [Service] Querying device information (CMD_DEVICE_QUERY)...',
    );
    final deviceInfo = await _commandSender
        .writeDataAndWaitForResponse<Map<String, dynamic>>(
          FrameBuilder.buildDeviceQuery(),
          MeshCoreConstants.respDeviceInfo,
        );
    debugPrint(
      '✅ [Service] Device info received: firmware=${deviceInfo['firmwareVersion']}',
    );

    // STEP 2: Send app start to initialize the app session
    // This is the first command after connection per protocol documentation
    debugPrint('🚀 [Service] Sending app start (CMD_APP_START)...');
    await _commandSender.writeDataAndWaitForResponse<Map<String, dynamic>>(
      FrameBuilder.buildAppStart(),
      MeshCoreConstants.respSelfInfo,
    );
    debugPrint('✅ [Service] Self info received: node initialized');

    // STEP 3: Set device clock AFTER initialization
    // This ensures the device has correct timestamps for all subsequent operations
    // Note: This command does not return an ACK, so we use writeData (fire-and-forget)
    debugPrint('⏰ [Service] Setting device clock (CMD_SET_DEVICE_TIME)...');
    await _commandSender.writeData(FrameBuilder.buildSetDeviceTime());
    debugPrint('✅ [Service] Device clock sent (no ACK expected)');
  }

  /// Refresh device info (public method)
  Future<void> refreshDeviceInfo() async {
    await _sendDeviceQuery();
  }

  /// Get contacts from device
  Future<void> getContacts() async {
    await _commandSender.writeData(FrameBuilder.buildGetContacts());
  }

  /// Get a single contact by public key from device
  ///
  /// This is more efficient than getContacts() when you only need to refresh
  /// one specific contact (e.g., after receiving an advertisement).
  ///
  /// The contact will be delivered via the onContactReceived callback.
  Future<void> getContactByKey(Uint8List publicKey) async {
    debugPrint('🔍 [BLE] Requesting single contact by key:');
    debugPrint(
      '    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
    );
    await _commandSender.writeData(FrameBuilder.buildGetContactByKey(publicKey));
  }

  /// Manually add or update a contact on the companion radio
  Future<void> addOrUpdateContact(Contact contact) async {
    debugPrint('📝 [BLE] Adding/updating contact on companion radio:');
    debugPrint('    Name: ${contact.advName}');
    debugPrint(
      '    Public key prefix: ${contact.publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );
    debugPrint('    Type: ${contact.type} (${contact.type.value})');

    await _commandSender.writeData(FrameBuilder.buildAddUpdateContact(contact));

    debugPrint('✅ [BLE] CMD_ADD_UPDATE_CONTACT sent');
  }

  /// Send text message to contact (DM)
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
    int textType = 0,
    int attempt = 0,
  }) async {
    if (text.length > 160) {
      throw ArgumentError('Text message exceeds 160 character limit');
    }

    // Track the last contact for auto-recovery if contact not found
    _responseHandler.setLastContactPublicKey(contactPublicKey);

    await _commandSender.writeData(
      FrameBuilder.buildSendTxtMsg(
        contactPublicKey: contactPublicKey,
        text: text,
        textType: textType,
        attempt: attempt,
      ),
    );
  }

  /// Send flood-mode text message to channel
  /// Track a sent channel message for echo detection
  void trackSentChannelMessage(String messageId) {
    debugPrint(
      '🔵 [MeshCoreBleService] trackSentChannelMessage called for: $messageId',
    );
    _responseHandler.trackSentMessage(messageId, null);
  }

  /// Send a text message to a channel (flood-mode broadcast)
  ///
  /// Channel messages are ephemeral and use flood routing (no ACKs).
  /// Use channel 0 for the default public channel.
  ///
  /// Note: Uses fire-and-forget mode since channel messages don't return
  /// delivery confirmation (they're broadcast to all nodes).
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
    int textType = 0,
  }) async {
    if (text.length > 160) {
      throw ArgumentError('Channel message too long (max ~160 characters)');
    }

    // Channel messages use fire-and-forget (no ACK expected)
    // The firmware responds with RESP_CODE_OK but we don't wait for it
    await _commandSender.writeData(
      FrameBuilder.buildSendChannelTxtMsg(
        channelIdx: channelIdx,
        text: text,
        textType: textType,
      ),
    );
  }

  /// Request telemetry from contact (deprecated)
  @Deprecated('Use sendBinaryRequest() instead for better functionality')
  Future<void> requestTelemetry(
    Uint8List contactPublicKey, {
    bool zeroHop = false,
  }) async {
    await _commandSender.writeData(
      FrameBuilder.buildSendTelemetryReq(contactPublicKey, zeroHop: zeroHop),
    );
  }

  /// Send binary request to contact
  Future<void> sendBinaryRequest({
    required Uint8List contactPublicKey,
    required Uint8List requestData,
  }) async {
    await _commandSender.writeData(
      FrameBuilder.buildSendBinaryReq(
        contactPublicKey: contactPublicKey,
        requestData: requestData,
      ),
    );
  }

  /// Get battery voltage and storage information
  Future<void> getBatteryAndStorage() async {
    await _commandSender.writeData(FrameBuilder.buildGetBatteryAndStorage());
  }

  /// Legacy method name for backward compatibility
  @Deprecated('Use getBatteryAndStorage() instead')
  Future<void> getBatteryVoltage() async {
    await getBatteryAndStorage();
  }

  /// Sync next message from device queue
  Future<void> syncNextMessage() async {
    await _commandSender.writeData(FrameBuilder.buildSyncNextMessage());
  }

  /// Get device time from companion radio
  Future<void> getDeviceTime() async {
    await _commandSender.writeData(FrameBuilder.buildGetDeviceTime());
  }

  /// Set device time
  Future<void> setDeviceTime() async {
    await _commandSender.writeData(FrameBuilder.buildSetDeviceTime());
  }

  /// Send self advertisement packet to mesh network
  Future<void> sendSelfAdvert({bool floodMode = true}) async {
    await _commandSender.writeData(
      FrameBuilder.buildSendSelfAdvert(floodMode: floodMode),
    );
  }

  /// Set advertised name
  Future<void> setAdvertName(String name) async {
    await _commandSender.writeDataAndWaitForAck(
      FrameBuilder.buildSetAdvertName(name),
    );
  }

  /// Set advertised latitude and longitude
  Future<void> setAdvertLatLon({
    required double latitude,
    required double longitude,
  }) async {
    // This command returns OK (0x00) response, so wait for acknowledgment
    await _commandSender.writeDataAndWaitForAck(
      FrameBuilder.buildSetAdvertLatLon(
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  /// Set radio parameters
  Future<void> setRadioParams({
    required int frequency,
    required int bandwidth,
    required int spreadingFactor,
    required int codingRate,
  }) async {
    await _commandSender.writeDataAndWaitForAck(
      FrameBuilder.buildSetRadioParams(
        frequency: frequency,
        bandwidth: bandwidth,
        spreadingFactor: spreadingFactor,
        codingRate: codingRate,
      ),
    );
  }

  /// Set transmit power
  Future<void> setTxPower(int powerDbm) async {
    await _commandSender.writeDataAndWaitForAck(
      FrameBuilder.buildSetTxPower(powerDbm),
    );
  }

  /// Set other parameters
  Future<void> setOtherParams({
    required int manualAddContacts,
    required int telemetryModes,
    required int advertLocationPolicy,
    int multiAcks = 0,
  }) async {
    await _commandSender.writeDataAndWaitForAck(
      FrameBuilder.buildSetOtherParams(
        manualAddContacts: manualAddContacts,
        telemetryModes: telemetryModes,
        advertLocationPolicy: advertLocationPolicy,
        multiAcks: multiAcks,
      ),
    );
  }

  /// Send login request to room or repeater
  Future<void> loginToRoom({
    required Uint8List roomPublicKey,
    required String password,
  }) async {
    if (password.length > 15) {
      throw ArgumentError('Password exceeds 15 character limit');
    }

    debugPrint('🔐 [BLE] Preparing login request:');
    debugPrint(
      '    Room public key prefix: ${roomPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );
    debugPrint(
      '    Password: ${"*" * password.length} (${password.length} chars)',
    );

    await _commandSender.writeData(
      FrameBuilder.buildSendLogin(
        roomPublicKey: roomPublicKey,
        password: password,
      ),
    );
  }

  /// Send status request to repeater or sensor node
  Future<void> sendStatusRequest(Uint8List contactPublicKey) async {
    debugPrint('📊 [BLE] Preparing status request:');
    debugPrint(
      '    Target node public key prefix: ${contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );

    await _commandSender.writeData(
      FrameBuilder.buildSendStatusReq(contactPublicKey),
    );
  }

  /// Reset path for a contact - forces next message to flood and re-learn route
  Future<void> resetPath(Uint8List contactPublicKey) async {
    debugPrint('🔄 [BLE] Resetting path for contact:');
    debugPrint(
      '    Contact public key prefix: ${contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );

    await _commandSender.writeData(
      FrameBuilder.buildResetPath(contactPublicKey),
    );
  }

  /// Remove a contact from the companion radio
  Future<void> removeContact(Uint8List contactPublicKey) async {
    debugPrint('🗑️ [BLE] Removing contact from companion radio:');
    debugPrint(
      '    Public key prefix: ${contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
    );

    await _commandSender.writeData(
      FrameBuilder.buildRemoveContact(contactPublicKey),
    );
    debugPrint('✅ [BLE] CMD_REMOVE_CONTACT sent');
  }

  /// Get information for a specific channel
  Future<void> getChannel(int channelIdx) async {
    await _commandSender.writeData(FrameBuilder.buildGetChannel(channelIdx));
  }

  /// Set the name and secret for a specific channel
  ///
  /// The secret must be exactly 16 bytes (128-bit encryption key).
  /// For the default public channel (channel 0), use [MeshCoreConstants.defaultPublicChannelSecret].
  Future<void> setChannel({
    required int channelIdx,
    required String channelName,
    required List<int> secret,
  }) async {
    debugPrint('📻 [BLE] Setting channel:');
    debugPrint('    Channel index: $channelIdx');
    debugPrint('    Channel name: $channelName');
    debugPrint('    Secret length: ${secret.length} bytes');

    await _commandSender.writeDataAndWaitForAck(
      FrameBuilder.buildSetChannel(
        channelIdx: channelIdx,
        channelName: channelName,
        secret: secret,
      ),
    );
    debugPrint('✅ [BLE] CMD_SET_CHANNEL sent successfully');
  }

  /// Sync all channels from the device (typically 0-39)
  /// This queries each channel to get its name and metadata
  Future<void> syncAllChannels({int maxChannels = 40}) async {
    debugPrint('📻 [Service] Syncing channels (0-${maxChannels - 1})...');

    for (int i = 0; i < maxChannels; i++) {
      await getChannel(i);
      // Small delay to avoid overwhelming the device
      await Future.delayed(const Duration(milliseconds: 50));
    }

    debugPrint('✅ [Service] Channel sync complete');
  }

  /// Clear packet logs
  void clearPacketLogs() {
    _commandSender.clearPacketLogs();
    _responseHandler.clearPacketLogs();
  }

  /// Reset packet counters
  void resetCounters() {
    _commandSender.resetCounter();
    _responseHandler.resetCounter();
  }

  /// Dispose resources
  void dispose() {
    _connectionManager.dispose();
    _commandSender.dispose();
    _responseHandler.dispose();
  }
}
