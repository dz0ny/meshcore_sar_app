import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_info.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/meshcore_ble_service.dart';
import '../services/cayenne_lpp_parser.dart';
import '../utils/sar_message_parser.dart';

/// Connection Provider - manages MeshCore BLE connection
class ConnectionProvider with ChangeNotifier {
  final MeshCoreBleService _bleService = MeshCoreBleService();

  /// Expose BLE service for background location tracking
  MeshCoreBleService get bleService => _bleService;

  DeviceInfo _deviceInfo = DeviceInfo();
  DeviceInfo get deviceInfo => _deviceInfo;

  List<BluetoothDevice> _scannedDevices = [];
  List<BluetoothDevice> get scannedDevices => _scannedDevices;

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

  // Message sync state
  bool _noMoreMessages = false;

  // Callbacks for other providers
  Function(Contact)? onContactReceived;
  Function(List<Contact>)? onContactsComplete;
  Function(Message)? onMessageReceived;
  Function(Uint8List publicKey, Uint8List lppData)? onTelemetryReceived;
  Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag)? onLoginSuccess;
  Function(Uint8List publicKeyPrefix)? onLoginFail;

  ConnectionProvider() {
    _initializeBleService();
  }

  void _initializeBleService() {
    _bleService.onConnectionStateChanged = (isConnected) {
      print('🔔 [Provider] Connection state callback fired: $isConnected');
      _deviceInfo = _deviceInfo.copyWith(
        connectionState: isConnected
            ? ConnectionState.connected
            : ConnectionState.disconnected,
        lastUpdate: DateTime.now(),
      );
      print('  Updated deviceInfo.connectionState: ${_deviceInfo.connectionState}');
      print('  Updated deviceInfo.isConnected: ${_deviceInfo.isConnected}');
      notifyListeners();
      print('  Notified listeners');
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
        print('  Keeping connection state as connected (ignoring data parsing error)');
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
      onTelemetryReceived?.call(publicKey, lppData);
    };

    _bleService.onNoMoreMessages = () {
      print('📥 [Provider] Received NoMoreMessages signal');
      _noMoreMessages = true;
    };

    _bleService.onMessageWaiting = () {
      print('📥 [Provider] Received MsgWaiting push - auto-fetching messages');
      // Automatically fetch messages when push notification received
      syncAllMessages();
    };

    _bleService.onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) {
      print('📥 [Provider] Login successful to room');
      print('  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
      print('  Permissions: $permissions, Admin: $isAdmin, Tag: $tag');
      onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
    };

    _bleService.onLoginFail = (publicKeyPrefix) {
      print('📥 [Provider] Login failed to room');
      print('  Public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
      onLoginFail?.call(publicKeyPrefix);
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
      print('  TX Power: ${selfInfo['txPower']} / ${selfInfo['maxTxPower']} dBm');
      print('  Radio: freq=${selfInfo['radioFreq']}, bw=${selfInfo['radioBw']}, sf=${selfInfo['radioSf']}, cr=${selfInfo['radioCr']}');
      print('  Position: ${selfInfo['advLat'] / 1000000.0}, ${selfInfo['advLon'] / 1000000.0}');
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
      await for (final device
          in _bleService.scanForDevices(timeout: const Duration(seconds: 10))) {
        print('📱 [Provider] Device received from scan stream');
        if (!_scannedDevices.any((d) => d.remoteId == device.remoteId)) {
          _scannedDevices.add(device);
          print('✅ [Provider] Added device to list: ${device.platformName}, total: ${_scannedDevices.length}');
          notifyListeners();
        } else {
          print('  ⏭️ [Provider] Device already in list, skipping');
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
      deviceName: device.platformName.isNotEmpty ? device.platformName : 'Unknown',
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

    _deviceInfo = DeviceInfo(
      connectionState: ConnectionState.disconnected,
    );
    notifyListeners();
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

  /// Send text message to contact
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.sendTextMessage(
        contactPublicKey: contactPublicKey,
        text: text,
      );
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  /// Send channel message
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
  }) async {
    if (!_bleService.isConnected) {
      _error = 'Not connected to device';
      notifyListeners();
      return;
    }

    try {
      await _bleService.sendChannelMessage(
        channelIdx: channelIdx,
        text: text,
      );
    } catch (e) {
      _error = 'Failed to send channel message: $e';
      notifyListeners();
    }
  }

  /// Request telemetry from contact
  /// [zeroHop] - if true, only direct connection (no mesh forwarding)
  Future<void> requestTelemetry(Uint8List contactPublicKey, {bool zeroHop = false}) async {
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
      print('🔄 [Provider] Starting message sync...');
      // Keep syncing until we get NoMoreMessages response
      // The device will send ContactMsgRecv or ChannelMsgRecv responses
      // until it sends NoMoreMessages
      for (int i = 0; i < 100; i++) {  // Safety limit
        if (_noMoreMessages) {
          print('✅ [Provider] Message sync complete - NoMoreMessages received after $count requests');
          break;
        }

        await _bleService.syncNextMessage();
        count++;

        // Small delay to allow response to be processed
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_noMoreMessages && count >= 100) {
        print('⚠️ [Provider] Message sync stopped - reached safety limit of 100 requests');
      }

      return count;
    } catch (e) {
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

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _rxActivityTimer?.cancel();
    _txActivityTimer?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
