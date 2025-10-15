import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../meshcore_constants.dart';

/// Callback types for connection events
typedef OnConnectionStateCallback = void Function(bool isConnected);
typedef OnErrorCallback = void Function(String error);
typedef OnReconnectionAttemptCallback = void Function(int attemptNumber, int maxAttempts);

/// Manages BLE connection lifecycle with automatic reconnection
class BleConnectionManager {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  bool _isConnected = false;

  // Reconnection state
  bool _reconnectionEnabled = true;
  bool _isReconnecting = false;
  int _reconnectionAttempt = 0;
  Timer? _reconnectionTimer;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  static const int _maxReconnectionAttempts = 5;
  static const List<int> _reconnectionDelaysMs = [1000, 2000, 3000, 5000, 10000]; // Exponential backoff

  // Callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
  OnErrorCallback? onError;
  OnReconnectionAttemptCallback? onReconnectionAttempt;

  // Getters
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  int get reconnectionAttempt => _reconnectionAttempt;
  int get maxReconnectionAttempts => _maxReconnectionAttempts;
  BluetoothDevice? get device => _device;
  BluetoothCharacteristic? get rxCharacteristic => _rxCharacteristic;
  BluetoothCharacteristic? get txCharacteristic => _txCharacteristic;

  /// Scan for MeshCore devices
  Stream<BluetoothDevice> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    try {
      print('🔍 [BLE] Starting scan for MeshCore devices...');
      print('  Service UUID: ${MeshCoreConstants.bleServiceUuid}');
      print('  Timeout: ${timeout.inSeconds}s');

      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(MeshCoreConstants.bleServiceUuid)],
      );
      print('✅ [BLE] Scan started successfully');

      int deviceCount = 0;
      await for (final scanResult in FlutterBluePlus.scanResults) {
        print('📡 [BLE] Scan results batch received: ${scanResult.length} results');
        for (final result in scanResult) {
          print('  Device: ${result.device.platformName} (${result.device.remoteId})');
          print('    RSSI: ${result.rssi}');
          print('    Service UUIDs: ${result.advertisementData.serviceUuids}');

          if (result.advertisementData.serviceUuids
              .contains(Guid(MeshCoreConstants.bleServiceUuid))) {
            deviceCount++;
            print('  ✅ MeshCore device found! Total: $deviceCount');
            yield result.device;
          } else {
            print('  ❌ Not a MeshCore device (service UUID mismatch)');
          }
        }
      }
      print('🏁 [BLE] Scan completed. Found $deviceCount MeshCore devices');
    } catch (e) {
      print('❌ [BLE] Scan error: $e');
      onError?.call('Scan error: $e');
    }
  }

  /// Connect to a MeshCore device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      print('🔵 [BLE] Starting connection to device: ${device.platformName} (${device.remoteId})');
      _device = device;

      // Connect to device
      print('🔵 [BLE] Calling device.connect() with 15s timeout...');
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
      );
      print('✅ [BLE] Device connected successfully');

      // Discover services
      print('🔵 [BLE] Discovering services...');
      final services = await device.discoverServices();
      print('✅ [BLE] Found ${services.length} services');

      // Log all discovered services for debugging
      for (final service in services) {
        print('  📋 Service: ${service.uuid}');
        for (final char in service.characteristics) {
          print('    - Characteristic: ${char.uuid}');
        }
      }

      // Find MeshCore service
      print('🔵 [BLE] Looking for MeshCore service: ${MeshCoreConstants.bleServiceUuid}');
      BluetoothService? meshCoreService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            MeshCoreConstants.bleServiceUuid.toLowerCase()) {
          meshCoreService = service;
          print('✅ [BLE] Found MeshCore service');
          break;
        }
      }

      if (meshCoreService == null) {
        print('❌ [BLE] MeshCore service not found!');
        throw Exception('MeshCore service not found');
      }

      // Find RX and TX characteristics
      print('🔵 [BLE] Looking for RX and TX characteristics...');
      print('  RX UUID: ${MeshCoreConstants.bleCharacteristicRxUuid}');
      print('  TX UUID: ${MeshCoreConstants.bleCharacteristicTxUuid}');

      for (final characteristic in meshCoreService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        print('  📋 Checking characteristic: $uuid');

        if (uuid == MeshCoreConstants.bleCharacteristicRxUuid.toLowerCase()) {
          _rxCharacteristic = characteristic;
          print('  ✅ Found RX characteristic');
        } else if (uuid ==
            MeshCoreConstants.bleCharacteristicTxUuid.toLowerCase()) {
          _txCharacteristic = characteristic;
          print('  ✅ Found TX characteristic');
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        print('❌ [BLE] Required characteristics not found!');
        print('  RX found: ${_rxCharacteristic != null}');
        print('  TX found: ${_txCharacteristic != null}');
        throw Exception('Required characteristics not found');
      }

      // Enable notifications on TX characteristic
      print('🔵 [BLE] Enabling notifications on TX characteristic...');
      await _txCharacteristic!.setNotifyValue(true);
      print('✅ [BLE] Notifications enabled');

      _isConnected = true;
      _reconnectionAttempt = 0; // Reset reconnection counter on successful connection
      print('🔵 [BLE] Notifying connection state change: connected');
      onConnectionStateChanged?.call(true);

      // Monitor connection state for automatic reconnection
      _setupConnectionMonitoring();

      print('✅✅✅ [BLE] Connection completed successfully!');
      return true;
    } catch (e) {
      print('❌❌❌ [BLE] Connection failed: $e');
      print('Stack trace: ${StackTrace.current}');
      onError?.call('Connection error: $e');
      _isConnected = false;
      onConnectionStateChanged?.call(false);
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      print('🔴 [BLE] Disconnect requested by user');
      // Disable reconnection before disconnecting
      _reconnectionEnabled = false;
      _cancelReconnection();

      await _device?.disconnect();
      _isConnected = false;
      _device = null;
      _rxCharacteristic = null;
      _txCharacteristic = null;
      onConnectionStateChanged?.call(false);
    } catch (e) {
      onError?.call('Disconnect error: $e');
    }
  }

  /// Setup connection monitoring for automatic reconnection
  void _setupConnectionMonitoring() {
    print('🔵 [BLE] Setting up connection monitoring for device: ${_device?.platformName}');

    // Cancel any existing subscription
    _connectionStateSubscription?.cancel();

    // Monitor connection state changes
    _connectionStateSubscription = _device?.connectionState.listen((state) {
      print('🔔 [BLE] Connection state changed: $state');

      if (state == BluetoothConnectionState.disconnected) {
        print('⚠️ [BLE] Device disconnected unexpectedly!');
        _isConnected = false;
        onConnectionStateChanged?.call(false);

        // Attempt automatic reconnection if enabled
        if (_reconnectionEnabled && !_isReconnecting) {
          print('🔄 [BLE] Starting automatic reconnection...');
          _attemptReconnection();
        }
      } else if (state == BluetoothConnectionState.connected) {
        print('✅ [BLE] Device connected');
        _isConnected = true;
        _reconnectionAttempt = 0;
        _isReconnecting = false;
        onConnectionStateChanged?.call(true);
      }
    });
  }

  /// Attempt to reconnect to the device
  Future<void> _attemptReconnection() async {
    if (_device == null || _isReconnecting || !_reconnectionEnabled) {
      return;
    }

    _isReconnecting = true;
    _reconnectionAttempt++;

    print('🔄 [BLE] Reconnection attempt $_reconnectionAttempt of $_maxReconnectionAttempts');
    onReconnectionAttempt?.call(_reconnectionAttempt, _maxReconnectionAttempts);

    if (_reconnectionAttempt > _maxReconnectionAttempts) {
      print('❌ [BLE] Max reconnection attempts reached. Giving up.');
      _isReconnecting = false;
      onError?.call('Connection lost. Max reconnection attempts ($_maxReconnectionAttempts) reached.');
      return;
    }

    // Calculate delay with exponential backoff
    final delayIndex = (_reconnectionAttempt - 1).clamp(0, _reconnectionDelaysMs.length - 1);
    final delayMs = _reconnectionDelaysMs[delayIndex];

    print('🔄 [BLE] Waiting ${delayMs}ms before reconnection attempt $_reconnectionAttempt...');

    // Wait before attempting reconnection
    _reconnectionTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_reconnectionEnabled) {
        print('🔄 [BLE] Reconnection cancelled by user');
        _isReconnecting = false;
        return;
      }

      try {
        print('🔄 [BLE] Attempting to reconnect...');

        // Try to reconnect
        final success = await connect(_device!);

        if (success) {
          print('✅ [BLE] Reconnection successful!');
          _isReconnecting = false;
          _reconnectionAttempt = 0;
        } else {
          print('❌ [BLE] Reconnection attempt $_reconnectionAttempt failed');
          _isReconnecting = false;

          // Try again if we haven't reached max attempts
          if (_reconnectionAttempt < _maxReconnectionAttempts) {
            _attemptReconnection();
          } else {
            onError?.call('Connection lost. Unable to reconnect after $_maxReconnectionAttempts attempts.');
          }
        }
      } catch (e) {
        print('❌ [BLE] Reconnection attempt $_reconnectionAttempt error: $e');
        _isReconnecting = false;

        // Try again if we haven't reached max attempts
        if (_reconnectionAttempt < _maxReconnectionAttempts) {
          _attemptReconnection();
        } else {
          onError?.call('Connection lost. Unable to reconnect: $e');
        }
      }
    });
  }

  /// Cancel ongoing reconnection attempts
  void _cancelReconnection() {
    print('🔴 [BLE] Cancelling reconnection attempts');
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _isReconnecting = false;
    _reconnectionAttempt = 0;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
  }

  /// Enable automatic reconnection (useful after user manually disconnects)
  void enableReconnection() {
    print('🔵 [BLE] Re-enabling automatic reconnection');
    _reconnectionEnabled = true;
  }

  /// Dispose resources
  void dispose() {
    print('🔴 [BLE] Disposing BLE connection manager');
    _cancelReconnection();
    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
  }
}
