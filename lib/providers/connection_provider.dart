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
  Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData)?
  onBinaryResponse;
  Function(Uint8List publicKey)? onPathUpdated;
  Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag)?
  onLoginSuccess;
  Function(Uint8List publicKeyPrefix)? onLoginFail;
  Function(String messageId, int expectedAckTag, int suggestedTimeoutMs)?
  onMessageSent;
  Function(int ackCode, int roundTripTimeMs)? onMessageDelivered;
  Function(Uint8List publicKeyPrefix, Uint8List statusData)? onStatusResponse;

  ConnectionProvider() {
    _initializeBleService();
  }

  void _initializeBleService() {
    _bleService.onConnectionStateChanged = (isConnected) {
      print('🔔 [Provider] Connection state callback fired: $isConnected');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: isConnected
            ? ConnectionState.connected
            : (_bleService.isReconnecting
                  ? ConnectionState.connecting
                  : ConnectionState.disconnected),
        lastUpdate: DateTime.now(),
      );
      print(
        '  Updated deviceInfo.connectionState: ${_deviceInfo.connectionState}',
      );
      print('  Updated deviceInfo.isConnected: ${_deviceInfo.isConnected}');
      print('  isReconnecting: ${_bleService.isReconnecting}');
      notifyListeners();
      print('  Notified listeners');
    };

    _bleService.onReconnectionAttempt = (attemptNumber, maxAttempts) {
      print('🔄 [Provider] Reconnection attempt $attemptNumber/$maxAttempts');
      // Notify UI to update reconnection status display
      notifyListeners();
    };

    _bleService.onError = (error) {
      print('⚠️ [Provider] BLE error received: $error');
      print('  Current connection state: ${_deviceInfo.connectionState}');

      _error = error;

      // Only set connection state to error if we're not already connected
      // Data parsing errors after connection shouldn't disconnect us
      if (_deviceInfo.connectionState != ConnectionState.connected) {
        print('  Setting connection state to error');
        _deviceInfo = _deviceInfo.copyWith(
          connectionState: ConnectionState.error,
        );
      } else {
        print(
          '  Keeping connection state as connected (ignoring data parsing error)',
        );
      }

      notifyListeners();
    };

    _bleService.onContactReceived = (contact) {
      onContactReceived?.call(contact);
    };

    _bleService.onContactsComplete = (contacts) {
      onContactsComplete?.call(contacts);
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
      print('📥 [Provider] Binary response received');
      print(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );
      print('  Tag: $tag');
      print('  Response data: ${responseData.length} bytes');
      // Mark ping as successful if this was a ping request
      // Binary responses can also be telemetry responses (newer firmware)
      _pingTracker.markPingSuccessful(publicKeyPrefix);
      onBinaryResponse?.call(publicKeyPrefix, tag, responseData);
    };

    _bleService.onNoMoreMessages = () {
      print('📥 [Provider] Received NoMoreMessages signal');
      _noMoreMessages = true;
    };

    _bleService.onMessageWaiting = () {
      print(
        '📥 [Provider] PUSH_CODE_MSG_WAITING received - auto-fetching messages via event',
      );
      // Automatically fetch messages when push notification received
      // This is the CORRECT way to receive messages - room server pushes them
      syncAllMessages();
    };

    _bleService
        .onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      print('📥 [Provider] Login successful to room');
      print(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );
      print('  Permissions: $permissions, Admin: $isAdmin, Tag: $tag');

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
      print('📥 [Provider] Login failed to room');
      print(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );

      // Update room login state to logged out via helper
      _roomLoginManager.handleLoginFail(publicKeyPrefix: publicKeyPrefix);
      notifyListeners();

      onLoginFail?.call(publicKeyPrefix);
    };

    _bleService.onAdvertReceived = (publicKey) {
      print('📥 [Provider] Advert received from node');
      print(
        '  Public key: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      print(
        '  Note: Waiting for PUSH_CODE_NEW_ADVERT (0x8A) with full contact details',
      );
      // The companion radio will automatically send PUSH_CODE_NEW_ADVERT if manual_add_contacts=0
      // which will trigger onContactReceived callback and add/update the contact
    };

    _bleService.onPathUpdated = (publicKey) {
      print('📥 [Provider] Path updated for contact');
      print(
        '  Public key: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...',
      );
      print(
        '  Note: Mesh network discovered a new/better routing path to this contact',
      );
      // Forward the callback to ContactsProvider to trigger contact sync
      onPathUpdated?.call(publicKey);
    };

    _bleService
        .onMessageSent = (expectedAckTag, suggestedTimeoutMs, isFloodMode) {
      print(
        '📥 [Provider] Message sent - ACK tag: $expectedAckTag, timeout: ${suggestedTimeoutMs}ms',
      );

      // Pop the first pending message ID from the queue (FIFO) via helper
      final messageId = _messageDeliveryTracker.popPendingMessageId();

      if (messageId != null) {
        print('  Matched with message ID: $messageId');

        // Store the ACK tag to message ID mapping for delivery confirmation
        _messageDeliveryTracker.mapAckTagToMessageId(expectedAckTag, messageId);

        // Notify callback with message ID
        onMessageSent?.call(messageId, expectedAckTag, suggestedTimeoutMs);
      } else {
        print(
          '⚠️ [Provider] SENT response received but no pending message IDs',
        );
      }
    };

    _bleService.onMessageDelivered = (ackCode, roundTripTimeMs) {
      print(
        '📥 [Provider] Message delivered - ACK code: $ackCode, RTT: ${roundTripTimeMs}ms',
      );
      onMessageDelivered?.call(ackCode, roundTripTimeMs);
    };

    _bleService.onStatusResponse = (publicKeyPrefix, statusData) {
      print('📥 [Provider] Status response received from node');
      print(
        '  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}',
      );
      print('  Status data: ${statusData.length} bytes');
      // Forward the callback to whoever needs it (e.g., ContactsProvider)
      onStatusResponse?.call(publicKeyPrefix, statusData);
    };

    _bleService.onDeviceInfoReceived = (deviceInfo) {
      print('📥 [Provider] Received DeviceInfo:');
      print('  Firmware Version: ${deviceInfo['firmwareVersion']}');
      print('  Max Contacts: ${deviceInfo['maxContacts']}');
      print('  Max Channels: ${deviceInfo['maxChannels']}');
      print('  BLE PIN: ${deviceInfo['blePin']}');
      print('  Build Date: ${deviceInfo['firmwareBuildDate']}');
      print('  Model: ${deviceInfo['manufacturerModel']}');
      print('  Version: ${deviceInfo['semanticVersion']}');

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
      print('✅ [Provider] Device info updated with DeviceInfo');
    };

    _bleService.onSelfInfoReceived = (selfInfo) {
      print('📥 [Provider] Received SelfInfo:');
      print(
        '  TX Power: ${selfInfo['txPower']} / ${selfInfo['maxTxPower']} dBm',
      );
      print(
        '  Radio: freq=${selfInfo['radioFreq']}, bw=${selfInfo['radioBw']}, sf=${selfInfo['radioSf']}, cr=${selfInfo['radioCr']}',
      );
      print(
        '  Position: ${selfInfo['advLat'] / 1000000.0}, ${selfInfo['advLon'] / 1000000.0}',
      );
      print('  Self Name: ${selfInfo['selfName']}');

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
      print('✅ [Provider] Device info updated with SelfInfo');
    };

    // Activity indicators

    _bleService.onBatteryAndStorage = (millivolts, usedKb, totalKb) {
      print('📥 [Provider] Received BatteryAndStorage:');
      print(
        '  Battery: ${millivolts}mV (${(millivolts / 1000.0).toStringAsFixed(2)}V)',
      );
      if (usedKb != null) {
        print('  Storage Used: ${usedKb}KB');
      }
      if (totalKb != null) {
        print('  Storage Total: ${totalKb}KB');
        if (totalKb > 0 && usedKb != null) {
          final usedPercent = (usedKb / totalKb) * 100.0;
          print('  Storage Usage: ${usedPercent.toStringAsFixed(1)}%');
        }
      }

      _deviceInfo = _deviceInfo.copyWith(
        batteryMilliVolts: millivolts,
        storageUsedKb: usedKb,
        storageTotalKb: totalKb,
        lastUpdate: DateTime.now(),
      );
      notifyListeners();
      print('✅ [Provider] Device info updated with BatteryAndStorage');
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
    print('🔍 [Provider] startScan() called');
    _isScanning = true;
    _scannedDevices.clear();
    _error = null;
    notifyListeners();
    print('✅ [Provider] Scan state initialized, notifying listeners');

    try {
      await for (final scanResult in _bleService.scanForDevices(
        timeout: const Duration(seconds: 10),
      )) {
        print('📱 [Provider] Scan result received from scan stream');
        final device = scanResult.device;
        final rssi = scanResult.rssi;

        if (!_scannedDevices.any((d) => d.device.remoteId == device.remoteId)) {
          _scannedDevices.add(ScannedDevice(device: device, rssi: rssi));
          print(
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
            print(
              '  🔄 [Provider] Updated RSSI for ${device.platformName}: $rssi dBm',
            );
            notifyListeners();
          } else {
            print(
              '  ⏭️ [Provider] Device already in list with same RSSI, skipping',
            );
          }
        }
      }
    } catch (e) {
      print('❌ [Provider] Scan error: $e');
      _error = 'Scan error: $e';
    } finally {
      print('🏁 [Provider] Scan completed');
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
    print('🔵 [Provider] connect() called for device: ${device.platformName}');

    _deviceInfo = _deviceInfo.copyWith(
      deviceId: device.remoteId.toString(),
      deviceName: device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown',
      connectionState: ConnectionState.connecting,
    );
    _error = null;
    print('✅ [Provider] Device info updated to connecting state');
    notifyListeners();

    print('🔵 [Provider] Calling BLE service connect()...');
    final success = await _bleService.connect(device);

    if (success) {
      print('✅ [Provider] BLE service connect() returned success');
    } else {
      print('❌ [Provider] BLE service connect() returned failure');
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
    notifyListeners();
  }

  /// Cancel ongoing reconnection attempts
  /// This is useful when the user wants to manually disconnect during reconnection
  void cancelReconnection() {
    print('🔴 [Provider] User requested cancellation of reconnection');
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
  Future<bool> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
    String? messageId,
    Contact? contact,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return false;
    }

    try {
      // Log path status if contact info is available
      if (contact != null) {
        print('📤 [ConnectionProvider] Sending message to ${contact.advName}');
        print('   Type: ${contact.type.displayName}');
        print('   Path status: ${contact.pathDescription}');
        if (contact.hasPath) {
          print('   ✅ Using learned path (${contact.outPathLen} bytes)');
        } else {
          print('   ⚠️ No path available - will use flood mode');
        }
      }

      // IMPORTANT: Track pending message BEFORE sending to avoid race condition
      // The SENT response can arrive so quickly that if we track after sending,
      // the callback will fire before we add the message ID to the queue.
      if (messageId != null) {
        _messageDeliveryTracker.trackPendingMessage(messageId);
        print('  Added message ID to pending queue BEFORE sending: $messageId');
      }

      // Send the message
      await _bleService.sendTextMessage(
        contactPublicKey: contactPublicKey,
        text: text,
      );

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
      await _bleService.sendChannelMessage(channelIdx: channelIdx, text: text);

      // Channel messages are ephemeral (not persisted) - mark as "sent" immediately
      // They don't have ACK/TAG mechanism like direct messages
      if (messageId != null) {
        print('✅ [ConnectionProvider] Channel message sent successfully');
        print('  Message ID: $messageId');
        print('  onMessageSent callback exists: ${onMessageSent != null}');

        // Small delay to ensure the message is in the MessagesProvider list
        // before we try to mark it as sent
        await Future.delayed(const Duration(milliseconds: 50));

        // Use a dummy ACK tag (0) and timeout (0) for channel messages
        // This will trigger the callback to mark the message as "sent"
        print('  Calling onMessageSent callback...');
        onMessageSent?.call(messageId, 0, 0);
        print('  onMessageSent callback completed');
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
        print(
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
      await _bleService.sendSelfAdvert(floodMode: floodMode);
    } catch (e) {
      _error = 'Failed to send advertisement: $e';
      notifyListeners();
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
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return false;
    }

    try {
      await _bleService.syncNextMessage();
      return true;
    } catch (e) {
      _error = 'Failed to sync message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sync all waiting messages from device
  Future<int> syncAllMessages() async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return 0;
    }

    int count = 0;
    _noMoreMessages = false; // Reset flag

    try {
      print('🔄 [Provider] Starting message sync loop...');
      print('  Initial _noMoreMessages state: $_noMoreMessages');

      // Keep syncing until we get NoMoreMessages response
      // The device will send ContactMsgRecv or ChannelMsgRecv responses
      // until it sends NoMoreMessages
      for (int i = 0; i < 100; i++) {
        // Safety limit
        // Check flag BEFORE sending (not after)
        if (_noMoreMessages) {
          print(
            '✅ [Provider] Message sync complete - NoMoreMessages flag set after $count requests',
          );
          break;
        }

        print(
          '📤 [Provider] Sync iteration ${i + 1}: Sending CMD_SYNC_NEXT_MESSAGE',
        );

        await _bleService.syncNextMessage();
        count++;

        // Small delay to allow response to be processed
        await Future.delayed(const Duration(milliseconds: 150));

        print('  After iteration ${i + 1}: _noMoreMessages=$_noMoreMessages');
      }

      if (!_noMoreMessages && count >= 100) {
        print(
          '⚠️ [Provider] Message sync stopped - reached safety limit of 100 requests without NoMoreMessages',
        );
      }

      print(
        '🏁 [Provider] Message sync finished: sent $count sync requests, _noMoreMessages=$_noMoreMessages',
      );
      return count;
    } catch (e) {
      print('❌ [Provider] Failed to sync messages: $e');
      _error = 'Failed to sync messages: $e';
      notifyListeners();
      return count;
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
  ///   print('Successfully logged in to room!');
  /// };
  /// connectionProvider.onLoginFail = (pkPrefix) {
  ///   print('Login failed - incorrect password');
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
      await _bleService.loginToRoom(
        roomPublicKey: roomPublicKey,
        password: password,
      );
    } catch (e) {
      _error = 'Failed to send login request: $e';
      notifyListeners();
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
  ///   print('Status from node: ${utf8.decode(statusData)}');
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
      await _bleService.sendStatusRequest(contactPublicKey);
    } catch (e) {
      _error = 'Failed to send status request: $e';
      notifyListeners();
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
