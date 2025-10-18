import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../meshcore_constants.dart';

/// Callback types for connection events
typedef OnConnectionStateCallback = void Function(bool isConnected);
typedef OnErrorCallback = void Function(String error);
typedef OnReconnectionAttemptCallback =
    void Function(int attemptNumber, int maxAttempts);
typedef OnRssiUpdateCallback = void Function(int rssi);

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

  // RSSI monitoring
  Timer? _rssiTimer;
  int? _lastRssi;

  // SAR-optimized reconnection: ~15 minutes total
  // Pattern: Fast retries first (for temporary issues), then slower retries (for extended disconnections)
  static const int _maxReconnectionAttempts = 30;
  static const List<int> _reconnectionDelaysMs = [
    2000, // 2s  - immediate retry
    3000, // 3s  - quick retry
    5000, // 5s  - fast retry
    10000, // 10s - moderate retry
    15000, // 15s - longer retry
    30000, // 30s - extended retry
    30000, // 30s - keep trying every 30s after this
  ]; // Total: ~15 minutes of reconnection attempts

  // Callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
  OnErrorCallback? onError;
  OnReconnectionAttemptCallback? onReconnectionAttempt;
  OnRssiUpdateCallback? onRssiUpdate;

  // Getters
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  int get reconnectionAttempt => _reconnectionAttempt;
  int get maxReconnectionAttempts => _maxReconnectionAttempts;
  BluetoothDevice? get device => _device;
  BluetoothCharacteristic? get rxCharacteristic => _rxCharacteristic;
  BluetoothCharacteristic? get txCharacteristic => _txCharacteristic;

  /// Scan for MeshCore devices
  Stream<ScanResult> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    try {
      debugPrint('🔍 [BLE] Starting scan for MeshCore devices...');
      debugPrint('  Service UUID: ${MeshCoreConstants.bleServiceUuid}');
      debugPrint('  Timeout: ${timeout.inSeconds}s');

      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(MeshCoreConstants.bleServiceUuid)],
      );
      debugPrint('✅ [BLE] Scan started successfully');

      int deviceCount = 0;
      await for (final scanResult in FlutterBluePlus.scanResults) {
        debugPrint(
          '📡 [BLE] Scan results batch received: ${scanResult.length} results',
        );
        for (final result in scanResult) {
          debugPrint(
            '  Device: ${result.device.platformName} (${result.device.remoteId})',
          );
          debugPrint('    RSSI: ${result.rssi}');
          debugPrint('    Service UUIDs: ${result.advertisementData.serviceUuids}');

          if (result.advertisementData.serviceUuids.contains(
            Guid(MeshCoreConstants.bleServiceUuid),
          )) {
            deviceCount++;
            debugPrint('  ✅ MeshCore device found! Total: $deviceCount');
            yield result;
          } else {
            debugPrint('  ❌ Not a MeshCore device (service UUID mismatch)');
          }
        }
      }
      debugPrint('🏁 [BLE] Scan completed. Found $deviceCount MeshCore devices');
    } catch (e) {
      debugPrint('❌ [BLE] Scan error: $e');
      onError?.call('Scan error: $e');
    }
  }

  /// Connect to a MeshCore device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      debugPrint(
        '🔵 [BLE] Starting connection to device: ${device.platformName} (${device.remoteId})',
      );
      _device = device;

      // Connect to device
      debugPrint('🔵 [BLE] Calling device.connect() with 15s timeout...');
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
      );
      debugPrint('✅ [BLE] Device connected successfully');

      // Discover services
      debugPrint('🔵 [BLE] Discovering services...');
      final services = await device.discoverServices();
      debugPrint('✅ [BLE] Found ${services.length} services');

      // Log all discovered services for debugging
      for (final service in services) {
        debugPrint('  📋 Service: ${service.uuid}');
        for (final char in service.characteristics) {
          debugPrint('    - Characteristic: ${char.uuid}');
        }
      }

      // Find MeshCore service
      debugPrint(
        '🔵 [BLE] Looking for MeshCore service: ${MeshCoreConstants.bleServiceUuid}',
      );
      BluetoothService? meshCoreService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            MeshCoreConstants.bleServiceUuid.toLowerCase()) {
          meshCoreService = service;
          debugPrint('✅ [BLE] Found MeshCore service');
          break;
        }
      }

      if (meshCoreService == null) {
        debugPrint('❌ [BLE] MeshCore service not found!');
        throw Exception('MeshCore service not found');
      }

      // Find RX and TX characteristics
      debugPrint('🔵 [BLE] Looking for RX and TX characteristics...');
      debugPrint('  RX UUID: ${MeshCoreConstants.bleCharacteristicRxUuid}');
      debugPrint('  TX UUID: ${MeshCoreConstants.bleCharacteristicTxUuid}');

      for (final characteristic in meshCoreService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        debugPrint('  📋 Checking characteristic: $uuid');

        if (uuid == MeshCoreConstants.bleCharacteristicRxUuid.toLowerCase()) {
          _rxCharacteristic = characteristic;
          debugPrint('  ✅ Found RX characteristic');
        } else if (uuid ==
            MeshCoreConstants.bleCharacteristicTxUuid.toLowerCase()) {
          _txCharacteristic = characteristic;
          debugPrint('  ✅ Found TX characteristic');
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        debugPrint('❌ [BLE] Required characteristics not found!');
        debugPrint('  RX found: ${_rxCharacteristic != null}');
        debugPrint('  TX found: ${_txCharacteristic != null}');
        throw Exception('Required characteristics not found');
      }

      // Enable notifications on TX characteristic
      debugPrint('🔵 [BLE] Enabling notifications on TX characteristic...');
      await _txCharacteristic!.setNotifyValue(true);
      debugPrint('✅ [BLE] Notifications enabled');

      _isConnected = true;
      _reconnectionAttempt =
          0; // Reset reconnection counter on successful connection
      debugPrint('🔵 [BLE] Notifying connection state change: connected');
      onConnectionStateChanged?.call(true);

      // Monitor connection state for automatic reconnection
      _setupConnectionMonitoring();

      // Start RSSI monitoring
      _startRssiMonitoring();

      debugPrint('✅✅✅ [BLE] Connection completed successfully!');
      return true;
    } catch (e) {
      debugPrint('❌❌❌ [BLE] Connection failed: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      onError?.call('Connection error: $e');
      _isConnected = false;
      onConnectionStateChanged?.call(false);
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      debugPrint('🔴 [BLE] Disconnect requested by user');
      // Disable reconnection before disconnecting
      _reconnectionEnabled = false;
      _cancelReconnection();
      _stopRssiMonitoring();

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
    debugPrint(
      '🔵 [BLE] Setting up connection monitoring for device: ${_device?.platformName}',
    );

    // Cancel any existing subscription
    _connectionStateSubscription?.cancel();

    // Monitor connection state changes
    _connectionStateSubscription = _device?.connectionState.listen((state) {
      debugPrint('🔔 [BLE] Connection state changed: $state');

      if (state == BluetoothConnectionState.disconnected) {
        debugPrint('⚠️ [BLE] Device disconnected unexpectedly!');
        _isConnected = false;
        onConnectionStateChanged?.call(false);

        // Attempt automatic reconnection if enabled
        if (_reconnectionEnabled && !_isReconnecting) {
          debugPrint('🔄 [BLE] Starting automatic reconnection...');
          _attemptReconnection();
        }
      } else if (state == BluetoothConnectionState.connected) {
        debugPrint('✅ [BLE] Device connected');
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

    debugPrint(
      '🔄 [BLE] Reconnection attempt $_reconnectionAttempt of $_maxReconnectionAttempts',
    );
    onReconnectionAttempt?.call(_reconnectionAttempt, _maxReconnectionAttempts);

    if (_reconnectionAttempt > _maxReconnectionAttempts) {
      debugPrint(
        '❌ [BLE] Max reconnection attempts reached after ~15 minutes. Giving up.',
      );
      _isReconnecting = false;
      onError?.call(
        'Connection lost. Unable to reconnect after 15 minutes ($_maxReconnectionAttempts attempts).',
      );
      return;
    }

    // Calculate delay with exponential backoff (uses last delay for attempts beyond array length)
    final delayIndex = (_reconnectionAttempt - 1).clamp(
      0,
      _reconnectionDelaysMs.length - 1,
    );
    final delayMs = _reconnectionDelaysMs[delayIndex];

    debugPrint(
      '🔄 [BLE] Waiting ${(delayMs / 1000).toStringAsFixed(0)}s before reconnection attempt $_reconnectionAttempt...',
    );

    // Wait before attempting reconnection
    _reconnectionTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_reconnectionEnabled) {
        debugPrint('🔄 [BLE] Reconnection cancelled by user');
        _isReconnecting = false;
        return;
      }

      try {
        debugPrint('🔄 [BLE] Attempting to reconnect...');

        // Try to reconnect
        final success = await connect(_device!);

        if (success) {
          debugPrint('✅ [BLE] Reconnection successful!');
          _isReconnecting = false;
          _reconnectionAttempt = 0;
        } else {
          debugPrint('❌ [BLE] Reconnection attempt $_reconnectionAttempt failed');
          _isReconnecting = false;

          // Try again if we haven't reached max attempts
          if (_reconnectionAttempt < _maxReconnectionAttempts) {
            _attemptReconnection();
          } else {
            onError?.call(
              'Connection lost. Unable to reconnect after 15 minutes ($_maxReconnectionAttempts attempts).',
            );
          }
        }
      } catch (e) {
        debugPrint('❌ [BLE] Reconnection attempt $_reconnectionAttempt error: $e');
        _isReconnecting = false;

        // Try again if we haven't reached max attempts
        if (_reconnectionAttempt < _maxReconnectionAttempts) {
          _attemptReconnection();
        } else {
          onError?.call(
            'Connection lost. Unable to reconnect after 15 minutes: $e',
          );
        }
      }
    });
  }

  /// Cancel ongoing reconnection attempts
  void _cancelReconnection() {
    debugPrint('🔴 [BLE] Cancelling reconnection attempts');
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _isReconnecting = false;
    _reconnectionAttempt = 0;
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
  }

  /// Enable automatic reconnection (useful after user manually disconnects)
  void enableReconnection() {
    debugPrint('🔵 [BLE] Re-enabling automatic reconnection');
    _reconnectionEnabled = true;
  }

  /// Start monitoring RSSI in the background
  void _startRssiMonitoring() {
    debugPrint('📡 [BLE] Starting RSSI monitoring (every 5 seconds)');
    _stopRssiMonitoring(); // Cancel any existing timer

    _rssiTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_device != null && _isConnected) {
        try {
          final rssi = await _device!.readRssi();
          if (_lastRssi != rssi) {
            _lastRssi = rssi;
            onRssiUpdate?.call(rssi);
          }
        } catch (e) {
          debugPrint('⚠️ [BLE] Failed to read RSSI: $e');
        }
      }
    });
  }

  /// Stop RSSI monitoring
  void _stopRssiMonitoring() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
    _lastRssi = null;
    debugPrint('📡 [BLE] RSSI monitoring stopped');
  }

  /// Dispose resources
  void dispose() {
    debugPrint('🔴 [BLE] Disposing BLE connection manager');
    _cancelReconnection();
    _stopRssiMonitoring();
    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
  }
}
