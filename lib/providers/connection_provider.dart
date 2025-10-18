import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_info.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/room_login_state.dart';
import '../services/meshcore_ble_service.dart';
import '../utils/sar_message_parser.dart';
import 'helpers/room_login_manager.dart';
import 'helpers/message_delivery_tracker.dart';
import 'helpers/ping_tracker.dart';

/// Pending send operation for auto-recovery
class _PendingSendOperation {
  final Uint8List contactPublicKey;
  final String text;
  final String? messageId;
  final Contact? contact;
  final int retryAttempt;

  _PendingSendOperation({
    required this.contactPublicKey,
    required this.text,
    this.messageId,
    this.contact,
    this.retryAttempt = 0,
  });
}

/// Result of a ping (telemetry request) operation
class PingResult {
  final bool success;
  final bool usedFlooding;
  final bool timedOut;
  final bool retriedWithFlooding;

  const PingResult({
    required this.success,
    required this.usedFlooding,
    required this.timedOut,
    this.retriedWithFlooding = false,
  });
}

/// Scanned device with RSSI information
class ScannedDevice {
  final BluetoothDevice device;
  final int rssi;

  ScannedDevice({required this.device, required this.rssi});
}

/// Connection Provider - manages MeshCore BLE connection
class ConnectionProvider with ChangeNotifier {
  final MeshCoreBleService _bleService = MeshCoreBleService();

  /// Expose BLE service for background location tracking
  MeshCoreBleService get bleService => _bleService;

  DeviceInfo _deviceInfo = DeviceInfo();
  DeviceInfo get deviceInfo => _deviceInfo;

  List<ScannedDevice> _scannedDevices = [];
  List<ScannedDevice> get scannedDevices => _scannedDevices;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  String? _error;
  String? get error => _error;

  // Activity indicators (for blinking)
  bool _rxActivity = false;
  bool _txActivity = false;
  bool get rxActivity => _rxActivity;
  bool get txActivity => _txActivity;

  Timer? _rxActivityTimer;
  Timer? _txActivityTimer;

  // Packet counters
  int get rxPacketCount => _bleService.rxPacketCount;
  int get txPacketCount => _bleService.txPacketCount;

  // Reconnection state (exposed from BLE service)
  bool get isReconnecting => _bleService.isReconnecting;
  int get reconnectionAttempt => _bleService.reconnectionAttempt;
  int get maxReconnectionAttempts => _bleService.maxReconnectionAttempts;

  // Message sync state
  bool _noMoreMessages = false;
  // Prevent overlapping/too-frequent sync requests
  bool _isSyncingMessages = false;
  DateTime? _lastSyncNextRequestedAt;
  static const Duration _minSyncNextInterval = Duration(milliseconds: 150);

  // Lightweight guards for other commands that can be double-tapped
  bool _isLoginInProgress = false;
  DateTime? _lastLoginRequestedAt;
  static const Duration _minLoginInterval = Duration(seconds: 1);

  bool _isStatusRequestInProgress = false;
  DateTime? _lastStatusRequestedAt;
  static const Duration _minStatusInterval = Duration(milliseconds: 200);

  bool _isAdvertInProgress = false;
  DateTime? _lastAdvertRequestedAt;
  static const Duration _minAdvertInterval = Duration(milliseconds: 500);

  // Helper instances
  final RoomLoginManager _roomLoginManager = RoomLoginManager();
  final MessageDeliveryTracker _messageDeliveryTracker =
      MessageDeliveryTracker();
  final PingTracker _pingTracker = PingTracker();

  // Expose room login states
  Map<String, RoomLoginState> get roomLoginStates =>
      _roomLoginManager.roomLoginStates;

  // Callbacks for other providers
  Function(Contact)? onContactReceived;
  Function(List<Contact>)? onContactsComplete;
  Function(Message)? onMessageReceived;
  Function(Uint8List publicKey, Uint8List lppData)? onTelemetryReceived;
  Function(int channelIdx, String channelName)? onChannelInfoReceived;
  Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData)?
  onBinaryResponse;
  Function(Uint8List publicKey)? onPathUpdated;
  Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag)?
  onLoginSuccess;
  Function(Uint8List publicKeyPrefix)? onLoginFail;
  Function(String messageId, int expectedAckTag, int suggestedTimeoutMs)?
  onMessageSent;
  Function(int ackCode, int roundTripTimeMs)? onMessageDelivered;
  Function(String messageId, int echoCount, int snrRaw, int rssiDbm)?
  onMessageEchoDetected;
  Function(Uint8List publicKeyPrefix, Uint8List statusData)? onStatusResponse;

  // Track pending send operations for auto-recovery
  final Map<String, _PendingSendOperation> _pendingSendOperations = {};

  ConnectionProvider() {
    _initializeBleService();
  }

  void _initializeBleService() {
    _bleService.onConnectionStateChanged = (isConnected) {
      debugPrint('🔔 [Provider] Connection state callback fired: $isConnected');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: isConnected
            ? ConnectionState.connected
            : (_bleService.isReconnecting
                  ? ConnectionState.connecting
                  : ConnectionState.disconnected),
        lastUpdate: DateTime.now(),
      );
      debugPrint(
        '  Updated deviceInfo.connectionState: ${_deviceInfo.connectionState}',
      );
      debugPrint('  Updated deviceInfo.isConnected: ${_deviceInfo.isConnected}');
      debugPrint('  isReconnecting: ${_bleService.isReconnecting}');
      notifyListeners();
      debugPrint('  Notified listeners');
    };

    _bleService.onReconnectionAttempt = (attemptNumber, maxAttempts) {
      debugPrint('🔄 [Provider] Reconnection attempt $attemptNumber/$maxAttempts');
      // Notify UI to update reconnection status display
      notifyListeners();
    };

    _bleService.onError = (error, {int? errorCode}) {
      debugPrint('⚠️ [Provider] BLE error received: $error');
      debugPrint('  Error code: ${errorCode ?? "none"}');
      debugPrint('  Current connection state: ${_deviceInfo.connectionState}');

      _error = error;

      // Only set connection state to error if we're not already connected
      // Data parsing errors after connection shouldn't disconnect us
      if (_deviceInfo.connectionState != ConnectionState.connected) {
        debugPrint('  Setting connection state to error');
        _deviceInfo = _deviceInfo.copyWith(
          connectionState: ConnectionState.error,
        );
      } else {
        debugPrint(
          '  Keeping connection state as connected (ignoring data parsing error)',
        );
      }

      notifyListeners();
    };

    _bleService.onContactNotFound = (contactPublicKey) async {
      debugPrint('🔧 [Provider] Contact not found error detected - initiating auto-recovery');

      if (contactPublicKey == null) {
        debugPrint('  ⚠️ No contact public key available for recovery');
        return;
      }

      // Generate operation ID from public key
      final operationId = contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
      final pendingOp = _pendingSendOperations[operationId];

      if (pendingOp == null || pendingOp.contact == null) {
        debugPrint('  ⚠️ No pending operation found for recovery: $operationId');
        return;
      }

      debugPrint('  📋 Found pending operation for: ${pendingOp.contact!.advName}');
      debugPrint('  📤 Step 1: Adding contact to radio...');

      try {
        // Step 1: Add the contact to the radio
        await _bleService.addOrUpdateContact(pendingOp.contact!);

        // Small delay to ensure contact is added before retrying
        await Future.delayed(const Duration(milliseconds: 300));

        debugPrint('  ✅ Contact added successfully');
        debugPrint('  🔄 Step 2: Retrying message send...');

        // Step 2: Retry the send operation
        await _bleService.sendTextMessage(
          contactPublicKey: pendingOp.contactPublicKey,
          text: pendingOp.text,
          attempt: pendingOp.retryAttempt,
        );

        debugPrint('  ✅ Auto-recovery completed - message resent');

        // Clear pending operation after successful recovery
        _pendingSendOperations.remove(operationId);
      } catch (e) {
        debugPrint('  ❌ Auto-recovery failed: $e');
        _error = 'Auto-recovery failed: $e';
        notifyListeners();

        // Clear pending operation after failed recovery
        _pendingSendOperations.remove(operationId);
      }
    };

    _bleService.onContactReceived = (contact) {
      onContactReceived?.call(contact);
    };

    _bleService.onContactsComplete = (contacts) {
      onContactsComplete?.call(contacts);
    };

    _bleService.onChannelInfoReceived = (channelIdx, channelName) {
      onChannelInfoReceived?.call(channelIdx, channelName);
    };

    _bleService.onMessageReceived = (message) {
      // Parse SAR markers
      final enhancedMessage = SarMessageParser.enhanceMessage(message);
      onMessageReceived?.call(enhancedMessage);
    };

    _bleService.onTelemetryReceived = (publicKey, lppData) {
      // Mark ping as successful if this was a ping request
      _pingTracker.markPingSuccessful(publicKey);
      onTelemetryReceived?.call(publicKey, lppData);
    };

    _bleService.onBinaryResponse = (publicKeyPrefix, tag, responseData) {
      debugPrint('📥 [Provider] Binary response received');
      debugPrint(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );
      debugPrint('  Tag: $tag');
      debugPrint('  Response data: ${responseData.length} bytes');
      // Mark ping as successful if this was a ping request
      // Binary responses can also be telemetry responses (newer firmware)
      _pingTracker.markPingSuccessful(publicKeyPrefix);
      onBinaryResponse?.call(publicKeyPrefix, tag, responseData);
    };

    _bleService.onNoMoreMessages = () {
      debugPrint('📥 [Provider] Received NoMoreMessages signal');
      _noMoreMessages = true;
    };

    _bleService.onMessageWaiting = () {
      debugPrint(
        '📥 [Provider] PUSH_CODE_MSG_WAITING received - auto-fetching messages via event',
      );
      // Automatically fetch messages when push notification received
      // This is the CORRECT way to receive messages - room server pushes them
      syncAllMessages();
    };

    _bleService
        .onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      debugPrint('📥 [Provider] Login successful to room');
      debugPrint(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );
      debugPrint('  Permissions: $permissions, Admin: $isAdmin, Tag: $tag');

      // Update room login state via helper
      await _roomLoginManager.handleLoginSuccess(
        publicKeyPrefix: publicKeyPrefix,
        permissions: permissions,
        isAdmin: isAdmin,
        tag: tag,
      );
      notifyListeners();

      onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
    };

    _bleService.onLoginFail = (publicKeyPrefix) {
      debugPrint('📥 [Provider] Login failed to room');
      debugPrint(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );

      // Update room login state to logged out via helper
      _roomLoginManager.handleLoginFail(publicKeyPrefix: publicKeyPrefix);
      notifyListeners();

      onLoginFail?.call(publicKeyPrefix);
    };

    _bleService.onAdvertReceived = (publicKey) {
      debugPrint('📥 [Provider] Advert received from node');
      debugPrint(
        '  Public key: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      debugPrint(
        '  Note: Waiting for PUSH_CODE_NEW_ADVERT (0x8A) with full contact details',
      );
      // The companion radio will automatically send PUSH_CODE_NEW_ADVERT if manual_add_contacts=0
      // which will trigger onContactReceived callback and add/update the contact
    };

    _bleService.onPathUpdated = (publicKey) {
      debugPrint('📥 [Provider] Path updated for contact');
      debugPrint(
        '  Public key: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      debugPrint(
        '  Note: Mesh network discovered a new/better routing path to this contact',
      );
      // Forward the callback to ContactsProvider to trigger contact sync
      onPathUpdated?.call(publicKey);
    };

    _bleService
        .onMessageSent = (expectedAckTag, suggestedTimeoutMs, isFloodMode) {
      debugPrint(
        '📥 [Provider] Message sent - ACK tag: $expectedAckTag, timeout: ${suggestedTimeoutMs}ms',
      );

      // Pop the first pending message ID from the queue (FIFO) via helper
      final messageId = _messageDeliveryTracker.popPendingMessageId();

      if (messageId != null) {
        debugPrint('  Matched with message ID: $messageId');

        // Store the ACK tag to message ID mapping for delivery confirmation
        _messageDeliveryTracker.mapAckTagToMessageId(expectedAckTag, messageId);

        // Notify callback with message ID
        onMessageSent?.call(messageId, expectedAckTag, suggestedTimeoutMs);
      } else {
        debugPrint(
          '⚠️ [Provider] SENT response received but no pending message IDs',
        );
      }
    };

    _bleService.onMessageDelivered = (ackCode, roundTripTimeMs) {
      debugPrint(
        '📥 [Provider] Message delivered - ACK code: $ackCode, RTT: ${roundTripTimeMs}ms',
      );
      onMessageDelivered?.call(ackCode, roundTripTimeMs);
    };

    _bleService.onMessageEchoDetected = (messageId, echoCount, snrRaw, rssiDbm) {
      debugPrint(
        '🔊 [Provider] Echo detected - Message: $messageId, Count: $echoCount',
      );
      onMessageEchoDetected?.call(messageId, echoCount, snrRaw, rssiDbm);
    };

    _bleService.onStatusResponse = (publicKeyPrefix, statusData) {
      debugPrint('📥 [Provider] Status response received from node');
      debugPrint(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );
      debugPrint('  Status data: ${statusData.length} bytes');
      // Forward the callback to whoever needs it (e.g., ContactsProvider)
      onStatusResponse?.call(publicKeyPrefix, statusData);
    };

    _bleService.onDeviceInfoReceived = (deviceInfo) {
      debugPrint('📥 [Provider] Received DeviceInfo:');
      debugPrint('  Firmware Version: ${deviceInfo['firmwareVersion']}');
      debugPrint('  Max Contacts: ${deviceInfo['maxContacts']}');
      debugPrint('  Max Channels: ${deviceInfo['maxChannels']}');
      debugPrint('  BLE PIN: ${deviceInfo['blePin']}');
      debugPrint('  Build Date: ${deviceInfo['firmwareBuildDate']}');
      debugPrint('  Model: ${deviceInfo['manufacturerModel']}');
      debugPrint('  Version: ${deviceInfo['semanticVersion']}');

      _deviceInfo = _deviceInfo.copyWith(
        firmwareVersion: deviceInfo['firmwareVersion'] as int?,
        maxContacts: deviceInfo['maxContacts'] as int?,
        maxChannels: deviceInfo['maxChannels'] as int?,
        blePin: deviceInfo['blePin'] as int?,
        firmwareBuildDate: deviceInfo['firmwareBuildDate'] as String?,
        manufacturerModel: deviceInfo['manufacturerModel'] as String?,
        semanticVersion: deviceInfo['semanticVersion'] as String?,
      );
      notifyListeners();
      debugPrint('✅ [Provider] Device info updated with DeviceInfo');
    };

    _bleService.onSelfInfoReceived = (selfInfo) {
      debugPrint('📥 [Provider] Received SelfInfo:');
      debugPrint(
        '  TX Power: ${selfInfo['txPower']} / ${selfInfo['maxTxPower']} dBm',
      );
      debugPrint(
        '  Radio: freq=${selfInfo['radioFreq']}, bw=${selfInfo['radioBw']}, sf=${selfInfo['radioSf']}, cr=${selfInfo['radioCr']}',
      );
      debugPrint(
        '  Position: ${selfInfo['advLat'] / 1000000.0}, ${selfInfo['advLon'] / 1000000.0}',
      );
      debugPrint('  Self Name: ${selfInfo['selfName']}');

      _deviceInfo = _deviceInfo.copyWith(
        deviceType: selfInfo['deviceType'] as int?,
        txPower: selfInfo['txPower'] as int?,
        maxTxPower: selfInfo['maxTxPower'] as int?,
        publicKey: selfInfo['publicKey'] as Uint8List?,
        advLat: selfInfo['advLat'] as int?,
        advLon: selfInfo['advLon'] as int?,
        manualAddContacts: selfInfo['manualAddContacts'] as bool?,
        radioFreq: selfInfo['radioFreq'] as int?,
        radioBw: selfInfo['radioBw'] as int?,
        radioSf: selfInfo['radioSf'] as int?,
        radioCr: selfInfo['radioCr'] as int?,
        selfName: selfInfo['selfName'] as String?,
      );
      notifyListeners();
      debugPrint('✅ [Provider] Device info updated with SelfInfo');
    };

    // Activity indicators

    _bleService.onBatteryAndStorage = (millivolts, usedKb, totalKb) {
      debugPrint('📥 [Provider] Received BatteryAndStorage:');
      debugPrint(
        '  Battery: ${millivolts}mV (${(millivolts / 1000.0).toStringAsFixed(2)}V)',
      );
      if (usedKb != null) {
        debugPrint('  Storage Used: ${usedKb}KB');
      }
      if (totalKb != null) {
        debugPrint('  Storage Total: ${totalKb}KB');
        if (totalKb > 0 && usedKb != null) {
          final usedPercent = (usedKb / totalKb) * 100.0;
          debugPrint('  Storage Usage: ${usedPercent.toStringAsFixed(1)}%');
        }
      }

      _deviceInfo = _deviceInfo.copyWith(
        batteryMilliVolts: millivolts,
        storageUsedKb: usedKb,
        storageTotalKb: totalKb,
        lastUpdate: DateTime.now(),
      );
      notifyListeners();
      debugPrint('✅ [Provider] Device info updated with BatteryAndStorage');
    };
    _bleService.onRxActivity = () {
      _rxActivity = true;
      notifyListeners();

      // Reset after 100ms
      _rxActivityTimer?.cancel();
      _rxActivityTimer = Timer(const Duration(milliseconds: 100), () {
        _rxActivity = false;
        notifyListeners();
      });
    };

    _bleService.onTxActivity = () {
      _txActivity = true;
      notifyListeners();

      // Reset after 100ms
      _txActivityTimer?.cancel();
      _txActivityTimer = Timer(const Duration(milliseconds: 100), () {
        _txActivity = false;
        notifyListeners();
      });
    };

    _bleService.onRssiUpdate = (rssi) {
      _deviceInfo = _deviceInfo.copyWith(
        signalRssi: rssi,
        lastUpdate: DateTime.now(),
      );
      notifyListeners();
    };
  }

  /// Start scanning for MeshCore devices
  Future<void> startScan() async {
    debugPrint('🔍 [Provider] startScan() called');
    _isScanning = true;
    _scannedDevices.clear();
    _error = null;
    notifyListeners();
    debugPrint('✅ [Provider] Scan state initialized, notifying listeners');

    try {
      await for (final scanResult in _bleService.scanForDevices(
        timeout: const Duration(seconds: 10),
      )) {
        debugPrint('📱 [Provider] Scan result received from scan stream');
        final device = scanResult.device;
        final rssi = scanResult.rssi;

        if (!_scannedDevices.any((d) => d.device.remoteId == device.remoteId)) {
          _scannedDevices.add(ScannedDevice(device: device, rssi: rssi));
          debugPrint(
            '✅ [Provider] Added device to list: ${device.platformName} (RSSI: $rssi dBm), total: ${_scannedDevices.length}',
          );
          notifyListeners();
        } else {
          // Update RSSI if device already exists
          final index = _scannedDevices.indexWhere(
            (d) => d.device.remoteId == device.remoteId,
          );
          if (index != -1 && _scannedDevices[index].rssi != rssi) {
            _scannedDevices[index] = ScannedDevice(device: device, rssi: rssi);
            debugPrint(
              '  🔄 [Provider] Updated RSSI for ${device.platformName}: $rssi dBm',
            );
            notifyListeners();
          } else {
            debugPrint(
              '  ⏭️ [Provider] Device already in list with same RSSI, skipping',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Provider] Scan error: $e');
      _error = 'Scan error: $e';
    } finally {
      debugPrint('🏁 [Provider] Scan completed');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a device
  Future<bool> connect(BluetoothDevice device) async {
    debugPrint('🔵 [Provider] connect() called for device: ${device.platformName}');

    _deviceInfo = _deviceInfo.copyWith(
      deviceId: device.remoteId.toString(),
      deviceName: device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown',
      connectionState: ConnectionState.connecting,
    );
    _error = null;
    debugPrint('✅ [Provider] Device info updated to connecting state');
    notifyListeners();

    debugPrint('🔵 [Provider] Calling BLE service connect()...');
    final success = await _bleService.connect(device);

    if (success) {
      debugPrint('✅ [Provider] BLE service connect() returned success');
    } else {
      debugPrint('❌ [Provider] BLE service connect() returned failure');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: ConnectionState.error,
      );
      notifyListeners();
    }
    return success;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _deviceInfo = _deviceInfo.copyWith(
      connectionState: ConnectionState.disconnecting,
    );
    notifyListeners();

    await _bleService.disconnect();

    _deviceInfo = DeviceInfo(connectionState: ConnectionState.disconnected);
    _roomLoginManager
        .clearRoomLoginStates(); // Clear login states on disconnect
    _pingTracker.clearAll(); // Clear pending pings on disconnect
    _pendingSendOperations.clear(); // Clear pending operations on disconnect
    notifyListeners();
  }

  /// Cancel ongoing reconnection attempts
  /// This is useful when the user wants to manually disconnect during reconnection
  void cancelReconnection() {
    debugPrint('🔴 [Provider] User requested cancellation of reconnection');
    disconnect();
  }

  /// Get contacts from device
  Future<void> getContacts() async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.getContacts();
    } catch (e) {
      _error = 'Failed to get contacts: $e';
      notifyListeners();
    }
  }

  /// Sync all channels from device
  Future<void> syncChannels({int? maxChannels}) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      // Use maxChannels from device info if available, otherwise default to 40
      final channelCount = maxChannels ?? _deviceInfo.maxChannels ?? 40;
      await _bleService.syncAllChannels(maxChannels: channelCount);
    } catch (e) {
      _error = 'Failed to sync channels: $e';
      notifyListeners();
    }
  }

  /// Add or update a contact on the companion radio
  ///
  /// This manually adds a contact to the radio's internal contact table.
  /// Useful when a room contact was deleted or never advertised yet.
  Future<void> addOrUpdateContact(Contact contact) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.addOrUpdateContact(contact);
    } catch (e) {
      _error = 'Failed to add/update contact: $e';
      notifyListeners();
    }
  }

  /// Send text message to contact
  ///
  /// Returns true if the message was successfully sent to the BLE service.
  /// Note: This doesn't mean the message was delivered over the mesh network,
  /// only that it was queued on the companion radio.
  ///
  /// [messageId] - optional message ID to track delivery status
  /// [contact] - optional contact object for path status logging
  /// [retryAttempt] - retry attempt number (0 = first send, 1-3 = retries)
  Future<bool> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
    String? messageId,
    Contact? contact,
    int retryAttempt = 0,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return false;
    }

    try {
      // Log path status and retry info
      if (contact != null) {
        if (retryAttempt > 0) {
          debugPrint('🔄 [ConnectionProvider] Sending message to ${contact.advName} (retry $retryAttempt/3)');
        } else {
          debugPrint('📤 [ConnectionProvider] Sending message to ${contact.advName}');
        }
        debugPrint('   Type: ${contact.type.displayName}');
        debugPrint('   Path status: ${contact.pathDescription}');
        if (contact.hasPath) {
          debugPrint('   ✅ Using learned path (${contact.outPathLen} bytes)');
        } else {
          debugPrint('   ⚠️ No path available - will use flood mode');
        }
      } else if (retryAttempt > 0) {
        debugPrint('🔄 [ConnectionProvider] Sending message (retry $retryAttempt/3)');
      }

      // Track pending operation for auto-recovery (if contact not found in radio)
      if (contact != null) {
        final operationId = contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        _pendingSendOperations[operationId] = _PendingSendOperation(
          contactPublicKey: contactPublicKey,
          text: text,
          messageId: messageId,
          contact: contact,
          retryAttempt: retryAttempt,
        );
        debugPrint('  📝 Tracked pending operation for auto-recovery: $operationId');
      }

      // IMPORTANT: Track pending message BEFORE sending to avoid race condition
      // The SENT response can arrive so quickly that if we track after sending,
      // the callback will fire before we add the message ID to the queue.
      if (messageId != null) {
        _messageDeliveryTracker.trackPendingMessage(messageId);
        debugPrint('  Added message ID to pending queue BEFORE sending: $messageId');
      }

      // Send the message with retry attempt info
      await _bleService.sendTextMessage(
        contactPublicKey: contactPublicKey,
        text: text,
        attempt: retryAttempt,
      );

      // Clear pending operation after successful send (no error)
      // If ERR_CODE_NOT_FOUND occurs, the operation will be recovered automatically
      if (contact != null) {
        final operationId = contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
        // Use a small delay to allow error response to arrive before clearing
        Future.delayed(const Duration(milliseconds: 500), () {
          _pendingSendOperations.remove(operationId);
        });
      }

      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Send channel message
  ///
  /// [messageId] - optional message ID to track delivery status
  /// Note: Channel messages are ephemeral (not persisted), so they're marked
  /// as "sent" immediately upon receiving OK response from the device.
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
    String? messageId,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      debugPrint('📨 [ConnectionProvider] sendChannelMessage called:');
      debugPrint('  Channel: $channelIdx');
      debugPrint('  Text: $text');
      debugPrint('  MessageID: $messageId');

      await _bleService.sendChannelMessage(channelIdx: channelIdx, text: text);

      debugPrint('✅ [ConnectionProvider] BLE send completed');
      debugPrint('  Checking messageId: ${messageId != null ? "Present ($messageId)" : "NULL"}');

      // Channel messages are ephemeral (not persisted) - mark as "sent" immediately
      // They don't have ACK/TAG mechanism like direct messages
      if (messageId != null) {
        debugPrint('✅ [ConnectionProvider] Channel message sent successfully');
        debugPrint('  Message ID: $messageId');
        debugPrint('  onMessageSent callback exists: ${onMessageSent != null}');

        // Track for echo detection
        // The BLE handler will capture the packet via LOG_RX_DATA and associate it
        debugPrint('  Calling trackSentChannelMessage...');
        _bleService.trackSentChannelMessage(messageId);
        debugPrint('  trackSentChannelMessage completed');

        // Small delay to ensure the message is in the MessagesProvider list
        // before we try to mark it as sent
        await Future.delayed(const Duration(milliseconds: 50));

        // Use a dummy ACK tag (0) and timeout (0) for channel messages
        // This will trigger the callback to mark the message as "sent"
        debugPrint('  Calling onMessageSent callback...');
        onMessageSent?.call(messageId, 0, 0);
        debugPrint('  onMessageSent callback completed');
      }
    } catch (e) {
      _error = 'Failed to send channel message: $e';
      notifyListeners();
    }
  }

  /// Request telemetry from contact
  ///
  /// COMPATIBILITY NOTE: This method sends CMD_SEND_TELEMETRY_REQ (39).
  /// Depending on device firmware version, the response will be either:
  /// - PUSH_CODE_TELEMETRY_RESPONSE (0x8B) - older firmware
  /// - PUSH_CODE_BINARY_RESPONSE (0x8C) - newer firmware
  ///
  /// Both response types are handled via callbacks:
  /// - onTelemetryReceived (for 0x8B)
  /// - onBinaryResponse (for 0x8C)
  ///
  /// The app properly handles BOTH response types, so this method is NOT
  /// deprecated and should continue to be used for telemetry requests.
  ///
  /// [zeroHop] - if true, only direct connection (no mesh forwarding)
  Future<void> requestTelemetry(
    Uint8List contactPublicKey, {
    bool zeroHop = false,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.requestTelemetry(contactPublicKey, zeroHop: zeroHop);
    } catch (e) {
      _error = 'Failed to request telemetry: $e';
      notifyListeners();
    }
  }

  /// Smart ping with automatic fallback to flooding
  ///
  /// Sends a telemetry request (ping) to a contact, and if no response is
  /// received within timeout, automatically retries with flooding mode.
  ///
  /// Returns a PingResult with information about the response.
  ///
  /// [contact] - the contact to ping (used to determine if path exists)
  /// [onRetryWithFlooding] - optional callback when fallback to flooding occurs
  Future<PingResult> smartPing({
    required Uint8List contactPublicKey,
    required bool hasPath,
    Function()? onRetryWithFlooding,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return PingResult(success: false, usedFlooding: false, timedOut: true);
    }

    // First attempt: Use zeroHop (direct) if we have a path, otherwise use flooding
    final bool firstAttemptDirect = hasPath;

    try {
      // Track the ping request
      final pingFuture = _pingTracker.trackPing(
        publicKey: contactPublicKey,
        wasDirectAttempt: firstAttemptDirect,
      );

      // Send the ping
      await _bleService.requestTelemetry(contactPublicKey, zeroHop: true);

      // Wait for response or timeout
      final bool gotResponse = await pingFuture;

      if (gotResponse) {
        // Success on first attempt
        return PingResult(
          success: true,
          usedFlooding: !firstAttemptDirect,
          timedOut: false,
        );
      }

      // First attempt timed out - retry with flooding if first was direct
      if (firstAttemptDirect) {
        debugPrint(
          '⚠️ [Provider] Ping timeout on direct attempt, retrying with flooding...',
        );
        onRetryWithFlooding?.call();

        // Track the retry
        final retryFuture = _pingTracker.trackPing(
          publicKey: contactPublicKey,
          wasDirectAttempt: false,
        );

        // Retry with flooding (zeroHop=true acts as broadcast to neighbors)
        await _bleService.requestTelemetry(contactPublicKey, zeroHop: true);

        // Wait for response or timeout
        final bool gotRetryResponse = await retryFuture;

        return PingResult(
          success: gotRetryResponse,
          usedFlooding: true,
          timedOut: !gotRetryResponse,
          retriedWithFlooding: true,
        );
      }

      // First attempt was already flooding and it timed out
      return PingResult(success: false, usedFlooding: true, timedOut: true);
    } catch (e) {
      _error = 'Failed to ping contact: $e';
      notifyListeners();
      return PingResult(success: false, usedFlooding: false, timedOut: true);
    }
  }

  /// Send binary request to contact (modern replacement for requestTelemetry)
  ///
  /// Supports multiple request types:
  /// - Telemetry data (use MeshCoreConstants.binaryReqGetTelemetryData)
  /// - Average/min/max telemetry (use MeshCoreConstants.binaryReqGetAvgMinMax)
  /// - Access list (use MeshCoreConstants.binaryReqGetAccessList)
  /// - Neighbors list (use MeshCoreConstants.binaryReqGetNeighbours)
  ///
  /// Response arrives via onBinaryResponse callback with matching tag.
  ///
  /// Example - request telemetry:
  /// ```dart
  /// connectionProvider.onBinaryResponse = (prefix, tag, data) {
  ///   // Parse telemetry data (Cayenne LPP format)
  ///   final telemetry = CayenneLppParser.parse(data);
  /// };
  /// await connectionProvider.requestBinary(
  ///   contactPublicKey: contact.publicKey,
  ///   requestType: MeshCoreConstants.binaryReqGetTelemetryData,
  /// );
  /// ```
  Future<void> requestBinary({
    required Uint8List contactPublicKey,
    required int requestType,
    Uint8List? additionalParams,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      // Build request data: request type byte + optional params
      final requestData = Uint8List.fromList([
        requestType,
        if (additionalParams != null) ...additionalParams,
      ]);

      await _bleService.sendBinaryRequest(
        contactPublicKey: contactPublicKey,
        requestData: requestData,
      );
    } catch (e) {
      _error = 'Failed to send binary request: $e';
      notifyListeners();
    }
  }

  /// Get device time from companion radio to detect clock drift
  Future<void> getDeviceTime() async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.getDeviceTime();
    } catch (e) {
      _error = 'Failed to get device time: $e';
      notifyListeners();
    }
  }

  /// Set device time to current time
  Future<void> syncDeviceTime() async {
    if (!_bleService.isConnected) return;

    try {
      await _bleService.setDeviceTime();
    } catch (e) {
      _error = 'Failed to sync time: $e';
      notifyListeners();
    }
  }

  /// Set advertised name
  Future<void> setAdvertName(String name) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.setAdvertName(name);
    } catch (e) {
      _error = 'Failed to set name: $e';
      notifyListeners();
    }
  }

  /// Set advertised position
  Future<void> setAdvertLatLon({
    required double latitude,
    required double longitude,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.setAdvertLatLon(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      _error = 'Failed to set position: $e';
      notifyListeners();
    }
  }

  /// Send self advertisement to mesh network
  ///
  /// Broadcasts the device's current advertisement data (name, location, etc.)
  /// to the mesh network. Use this after updating position or name to notify
  /// other nodes of the change.
  ///
  /// [floodMode] - if true, broadcast to entire mesh (default for SAR ops)
  ///               if false, only send to direct neighbors (zero-hop)
  Future<void> sendSelfAdvert({bool floodMode = true}) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      if (_isAdvertInProgress) return;
      // Throttle rapid advert requests
      final now = DateTime.now();
      if (_lastAdvertRequestedAt != null) {
        final elapsed = now.difference(_lastAdvertRequestedAt!);
        if (elapsed < _minAdvertInterval) {
          final wait = _minAdvertInterval - elapsed;
          await Future.delayed(wait);
        }
      }
      _isAdvertInProgress = true;
      await _bleService.sendSelfAdvert(floodMode: floodMode);
      _lastAdvertRequestedAt = DateTime.now();
    } catch (e) {
      _error = 'Failed to send advertisement: $e';
      notifyListeners();
    } finally {
      _isAdvertInProgress = false;
    }
  }

  /// Set radio parameters
  Future<void> setRadioParams({
    required int frequency,
    required int bandwidth,
    required int spreadingFactor,
    required int codingRate,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.setRadioParams(
        frequency: frequency,
        bandwidth: bandwidth,
        spreadingFactor: spreadingFactor,
        codingRate: codingRate,
      );
    } catch (e) {
      _error = 'Failed to set radio params: $e';
      notifyListeners();
    }
  }

  /// Set transmit power
  Future<void> setTxPower(int powerDbm) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.setTxPower(powerDbm);
    } catch (e) {
      _error = 'Failed to set TX power: $e';
      notifyListeners();
    }
  }

  /// Set other parameters (telemetry modes, advert location policy)
  Future<void> setOtherParams({
    required int manualAddContacts,
    required int telemetryModes,
    required int advertLocationPolicy,
    int multiAcks = 0,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.setOtherParams(
        manualAddContacts: manualAddContacts,
        telemetryModes: telemetryModes,
        advertLocationPolicy: advertLocationPolicy,
        multiAcks: multiAcks,
      );
    } catch (e) {
      _error = 'Failed to set other params: $e';
      notifyListeners();
    }
  }

  /// Request fresh device info (triggers SelfInfo response)
  Future<void> refreshDeviceInfo() async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      // The device query command triggers a SelfInfo response
      await _bleService.refreshDeviceInfo();
    } catch (e) {
      _error = 'Failed to refresh device info: $e';
      notifyListeners();
    }
  }

  /// Request battery and storage information
  ///
  /// Queries the companion radio for:
  /// - Battery voltage in millivolts
  /// - Used storage in KB (if available)
  /// - Total storage in KB (if available)
  ///
  /// Results arrive via onBatteryAndStorage callback and update deviceInfo.
  Future<void> getBatteryAndStorage() async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.getBatteryAndStorage();
    } catch (e) {
      _error = 'Failed to get battery and storage: $e';
      notifyListeners();
    }
  }

  /// Sync messages from device queue
  /// Call this repeatedly until no more messages are available
  Future<bool> syncNextMessage() async {
    // Prevent re-entrancy and too-fast triggers
    if (_isSyncingMessages) {
      // Another sync (single or loop) is in progress
      return false;
    }

    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return false;
    }

    try {
      // Enforce a small gap between consecutive requests
      final now = DateTime.now();
      if (_lastSyncNextRequestedAt != null) {
        final elapsed = now.difference(_lastSyncNextRequestedAt!);
        if (elapsed < _minSyncNextInterval) {
          final remaining = _minSyncNextInterval - elapsed;
          await Future.delayed(remaining);
        }
      }

      _isSyncingMessages = true;
      await _bleService.syncNextMessage();
      _lastSyncNextRequestedAt = DateTime.now();
      return true;
    } catch (e) {
      _error = 'Failed to sync message: $e';
      notifyListeners();
      return false;
    } finally {
      _isSyncingMessages = false;
    }
  }

  /// Sync all waiting messages from device
  Future<int> syncAllMessages() async {
    if (_isSyncingMessages) {
      // Already syncing; avoid overlapping loops
      return 0;
    }

    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return 0;
    }

    int count = 0;
    _noMoreMessages = false; // Reset flag

    try {
      _isSyncingMessages = true;
      debugPrint('🔄 [Provider] Starting message sync loop...');
      debugPrint('  Initial _noMoreMessages state: $_noMoreMessages');

      // Keep syncing until we get NoMoreMessages response
      // The device will send ContactMsgRecv or ChannelMsgRecv responses
      // until it sends NoMoreMessages
      for (int i = 0; i < 100; i++) {
        // Safety limit
        // Check flag BEFORE sending (not after)
        if (_noMoreMessages) {
          debugPrint(
            '✅ [Provider] Message sync complete - NoMoreMessages flag set after $count requests',
          );
          break;
        }

        debugPrint(
          '📤 [Provider] Sync iteration ${i + 1}: Sending CMD_SYNC_NEXT_MESSAGE',
        );

        // Respect the minimum interval between requests
        final now = DateTime.now();
        if (_lastSyncNextRequestedAt != null) {
          final elapsed = now.difference(_lastSyncNextRequestedAt!);
          if (elapsed < _minSyncNextInterval) {
            final remaining = _minSyncNextInterval - elapsed;
            await Future.delayed(remaining);
          }
        }

        await _bleService.syncNextMessage();
        _lastSyncNextRequestedAt = DateTime.now();
        count++;

        // Small delay to allow response to be processed
        await Future.delayed(const Duration(milliseconds: 150));

        debugPrint('  After iteration ${i + 1}: _noMoreMessages=$_noMoreMessages');
      }

      if (!_noMoreMessages && count >= 100) {
        debugPrint(
          '⚠️ [Provider] Message sync stopped - reached safety limit of 100 requests without NoMoreMessages',
        );
      }

      debugPrint(
        '🏁 [Provider] Message sync finished: sent $count sync requests, _noMoreMessages=$_noMoreMessages',
      );
      return count;
    } catch (e) {
      debugPrint('❌ [Provider] Failed to sync messages: $e');
      _error = 'Failed to sync messages: $e';
      notifyListeners();
      return count;
    } finally {
      _isSyncingMessages = false;
    }
  }

  /// Login to a room or repeater
  ///
  /// Sends login request with password. Results will be delivered via
  /// onLoginSuccess or onLoginFail callbacks.
  ///
  /// Example usage:
  /// ```dart
  /// connectionProvider.onLoginSuccess = (pkPrefix, perms, isAdmin, tag) {
  ///   debugPrint('Successfully logged in to room!');
  /// };
  /// connectionProvider.onLoginFail = (pkPrefix) {
  ///   debugPrint('Login failed - incorrect password');
  /// };
  /// await connectionProvider.loginToRoom(
  ///   roomPublicKey: contact.publicKey,
  ///   password: 'secret123',
  /// );
  /// ```
  Future<void> loginToRoom({
    required Uint8List roomPublicKey,
    required String password,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      if (_isLoginInProgress) return;
      // Throttle rapid login attempts
      final now = DateTime.now();
      if (_lastLoginRequestedAt != null) {
        final elapsed = now.difference(_lastLoginRequestedAt!);
        if (elapsed < _minLoginInterval) {
          final wait = _minLoginInterval - elapsed;
          await Future.delayed(wait);
        }
      }
      _isLoginInProgress = true;
      await _bleService.loginToRoom(
        roomPublicKey: roomPublicKey,
        password: password,
      );
      _lastLoginRequestedAt = DateTime.now();
    } catch (e) {
      _error = 'Failed to send login request: $e';
      notifyListeners();
    } finally {
      _isLoginInProgress = false;
    }
  }

  /// Request status from repeater or sensor node
  ///
  /// Sends a status request to query operational status of a node.
  /// Results will be delivered via onStatusResponse callback.
  ///
  /// Example usage:
  /// ```dart
  /// connectionProvider.onStatusResponse = (publicKeyPrefix, statusData) {
  ///   debugPrint('Status from node: ${utf8.decode(statusData)}');
  /// };
  /// await connectionProvider.requestStatus(repeaterContact.publicKey);
  /// ```
  Future<void> requestStatus(Uint8List contactPublicKey) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      if (_isStatusRequestInProgress) return;
      // Throttle rapid status requests
      final now = DateTime.now();
      if (_lastStatusRequestedAt != null) {
        final elapsed = now.difference(_lastStatusRequestedAt!);
        if (elapsed < _minStatusInterval) {
          final wait = _minStatusInterval - elapsed;
          await Future.delayed(wait);
        }
      }
      _isStatusRequestInProgress = true;
      await _bleService.sendStatusRequest(contactPublicKey);
      _lastStatusRequestedAt = DateTime.now();
    } catch (e) {
      _error = 'Failed to send status request: $e';
      notifyListeners();
    } finally {
      _isStatusRequestInProgress = false;
    }
  }

  /// Reset routing path for a contact
  ///
  /// Clears the learned path to a contact, forcing the next message to use
  /// flood routing to discover a new route. Useful when:
  /// - A mobile repeater has moved and the path is broken
  /// - You want to find a better/shorter route
  /// - Direct messages are timing out due to path issues
  ///
  /// After calling this, the device will automatically fall back to flood mode
  /// for the next message to this contact, and learn a new path from the response.
  Future<void> resetPath(Uint8List contactPublicKey) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.resetPath(contactPublicKey);
    } catch (e) {
      _error = 'Failed to reset path: $e';
      notifyListeners();
    }
  }

  /// Remove a contact from the companion radio
  ///
  /// Deletes the contact from the device's internal contact table.
  /// The contact will no longer appear in the contact list and all
  /// routing information will be cleared.
  Future<void> removeContact(Uint8List contactPublicKey) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.removeContact(contactPublicKey);
    } catch (e) {
      _error = 'Failed to remove contact: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get login state for a room by public key prefix
  RoomLoginState? getRoomLoginState(Uint8List publicKeyPrefix) {
    return _roomLoginManager.getRoomLoginState(publicKeyPrefix);
  }

  /// Check if logged into a specific room
  bool isLoggedIntoRoom(Uint8List publicKeyPrefix) {
    return _roomLoginManager.isLoggedIntoRoom(publicKeyPrefix);
  }

  @override
  void dispose() {
    _rxActivityTimer?.cancel();
    _txActivityTimer?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
