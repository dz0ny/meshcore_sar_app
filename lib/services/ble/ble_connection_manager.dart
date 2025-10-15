import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../meshcore_constants.dart';

/// Callback types for connection events
typedef OnConnectionStateCallback = void Function(bool isConnected);
typedef OnErrorCallback = void Function(String error);

/// Manages BLE connection lifecycle
class BleConnectionManager {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  bool _isConnected = false;

  // Callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
  OnErrorCallback? onError;

  // Getters
  bool get isConnected => _isConnected;
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
      print('🔵 [BLE] Notifying connection state change: connected');
      onConnectionStateChanged?.call(true);

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

  /// Dispose resources
  void dispose() {
    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
  }
}
