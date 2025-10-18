import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../meshcore_opcode_names.dart';
import '../../models/ble_packet_log.dart';
import 'ble_command_queue.dart';

/// Callback types for sender events
typedef OnErrorCallback = void Function(String error);

/// Sends commands to the BLE device
class BleCommandSender {
  BluetoothCharacteristic? _rxCharacteristic;
  int _txPacketCount = 0;
  final List<BlePacketLog> _packetLogs = [];
  static const int _maxLogSize = 1000;

  // Command queue for serialization and response waiting
  final BleCommandQueue _commandQueue = BleCommandQueue();

  // Callbacks
  OnErrorCallback? onError;
  VoidCallback? onTxActivity;

  // Getters
  int get txPacketCount => _txPacketCount;
  List<BlePacketLog> get packetLogs => List.unmodifiable(_packetLogs);
  BleCommandQueue get commandQueue => _commandQueue;

  /// Set the RX characteristic to write to
  void setRxCharacteristic(BluetoothCharacteristic? characteristic) {
    _rxCharacteristic = characteristic;
  }

  /// Write data to RX characteristic (fire-and-forget, no response expected)
  ///
  /// This method is for commands that don't expect any response.
  /// The command is queued and executed with proper spacing, but we don't wait
  /// for any acknowledgment.
  Future<void> writeData(Uint8List data) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected');
    }

    final commandCode = data.isNotEmpty ? data[0] : 0;

    // Enqueue the command (fire-and-forget)
    await _commandQueue.enqueue<void>(
      data: data,
      commandCode: commandCode,
      responseType: CommandResponseType.none,
    );

    // Actually send the data
    await _sendToDevice(data);
  }

  /// Write data and wait for ACK (RESP_CODE_OK or RESP_CODE_ERR)
  ///
  /// This method should be used for setup commands that return RESP_CODE_OK (0)
  /// on success or RESP_CODE_ERR (1) on failure.
  ///
  /// Examples: setAdvertLatLon, setAdvertName, setRadioParams, etc.
  Future<void> writeDataAndWaitForAck(Uint8List data) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected');
    }

    final commandCode = data.isNotEmpty ? data[0] : 0;

    // Enqueue the command (wait for ACK)
    await _commandQueue.enqueue<void>(
      data: data,
      commandCode: commandCode,
      responseType: CommandResponseType.ack,
    );

    // Actually send the data
    await _sendToDevice(data);
  }

  /// Write data and wait for specific response
  ///
  /// This method should be used for query commands that return specific data.
  ///
  /// Examples:
  /// - CMD_DEVICE_QUERY → RESP_CODE_DEVICE_INFO
  /// - CMD_APP_START → RESP_CODE_SELF_INFO
  /// - CMD_GET_CONTACTS → RESP_CODE_CONTACTS_START
  Future<T> writeDataAndWaitForResponse<T>(
    Uint8List data,
    int expectedResponseCode,
  ) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected');
    }

    final commandCode = data.isNotEmpty ? data[0] : 0;

    // Enqueue the command (wait for specific response)
    final responseFuture = _commandQueue.enqueue<T>(
      data: data,
      commandCode: commandCode,
      responseType: CommandResponseType.data,
      expectedResponseCode: expectedResponseCode,
    );

    // Actually send the data
    await _sendToDevice(data);

    // Wait for response
    return responseFuture;
  }

  /// Internal method to actually send data to the BLE device
  Future<void> _sendToDevice(Uint8List data) async {
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

      debugPrint('📤 [TX] Sending command: $opcodeName ($opcodeHex)');
      debugPrint('  Data size: ${data.length} bytes');
      debugPrint('  Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

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

      debugPrint('✅ [TX] Command sent successfully');
    } catch (e) {
      debugPrint('❌ [TX] Write error: $e');
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
    _commandQueue.dispose();
    _rxCharacteristic = null;
    _packetLogs.clear();
  }
}
