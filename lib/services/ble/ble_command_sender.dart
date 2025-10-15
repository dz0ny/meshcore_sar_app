import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../meshcore_opcode_names.dart';
import '../../models/ble_packet_log.dart';

/// Callback types for sender events
typedef OnErrorCallback = void Function(String error);

/// Sends commands to the BLE device
class BleCommandSender {
  BluetoothCharacteristic? _rxCharacteristic;
  int _txPacketCount = 0;
  final List<BlePacketLog> _packetLogs = [];
  static const int _maxLogSize = 1000;

  // Callbacks
  OnErrorCallback? onError;
  VoidCallback? onTxActivity;

  // Getters
  int get txPacketCount => _txPacketCount;
  List<BlePacketLog> get packetLogs => List.unmodifiable(_packetLogs);

  /// Set the RX characteristic to write to
  void setRxCharacteristic(BluetoothCharacteristic? characteristic) {
    _rxCharacteristic = characteristic;
  }

  /// Write data to RX characteristic
  Future<void> writeData(Uint8List data) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected');
    }
    try {
      // Extract command code from first byte
      final commandCode = data.isNotEmpty ? data[0] : null;
      final opcodeName = commandCode != null
          ? MeshCoreOpcodeNames.getCommandName(commandCode)
          : 'UNKNOWN';
      final opcodeHex = commandCode != null
          ? '0x${commandCode.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          : 'N/A';

      print('📤 [TX] Sending command: $opcodeName ($opcodeHex)');
      print('  Data size: ${data.length} bytes');
      print('  Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Check if the characteristic supports write without response
      final supportsWriteWithoutResponse = _rxCharacteristic!.properties.writeWithoutResponse;
      final supportsWrite = _rxCharacteristic!.properties.write;

      if (supportsWriteWithoutResponse) {
        await _rxCharacteristic!.write(data, withoutResponse: true);
      } else if (supportsWrite) {
        await _rxCharacteristic!.write(data, withoutResponse: false);
      } else {
        throw Exception('Characteristic does not support write operations');
      }

      // Log TX packet
      _logPacket(data, PacketDirection.tx, responseCode: commandCode);

      // Increment TX packet counter and trigger activity indicator
      _txPacketCount++;
      onTxActivity?.call();

      print('✅ [TX] Command sent successfully');
    } catch (e) {
      print('❌ [TX] Write error: $e');
      onError?.call('Write error: $e');
      rethrow;
    }
  }

  /// Log a packet
  void _logPacket(Uint8List data, PacketDirection direction, {int? responseCode}) {
    // Add new packet
    _packetLogs.add(BlePacketLog(
      timestamp: DateTime.now(),
      rawData: data,
      direction: direction,
      responseCode: responseCode,
      description: _getPacketDescription(responseCode),
    ));

    // Limit log size to prevent memory issues
    if (_packetLogs.length > _maxLogSize) {
      _packetLogs.removeAt(0);
    }
  }

  /// Get human-readable description of packet
  String? _getPacketDescription(int? code) {
    // TX packets - command codes
    switch (code) {
      case 4: // cmdGetContacts
        return 'Get Contacts';
      case 2: // cmdSendTxtMsg
        return 'Send Text Message';
      case 3: // cmdSendChannelTxtMsg
        return 'Send Channel Message';
      case 39: // cmdSendTelemetryReq
        return 'Request Telemetry';
      case 22: // cmdDeviceQuery
        return 'Device Query';
      case 1: // cmdAppStart
        return 'App Start';
      case 27: // cmdSendStatusReq
        return 'Status Request';
      default:
        return null;
    }
  }

  /// Reset packet counter
  void resetCounter() {
    _txPacketCount = 0;
  }

  /// Clear packet logs
  void clearPacketLogs() {
    _packetLogs.clear();
  }

  /// Dispose resources
  void dispose() {
    _rxCharacteristic = null;
    _packetLogs.clear();
  }
}
