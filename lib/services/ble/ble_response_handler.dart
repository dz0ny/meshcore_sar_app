import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../models/ble_packet_log.dart';
import '../buffer_reader.dart';
import '../meshcore_constants.dart';
import '../meshcore_opcode_names.dart';
import '../protocol/frame_parser.dart';

/// Callback types for response events
typedef OnContactCallback = void Function(Contact contact);
typedef OnContactsCompleteCallback = void Function(List<Contact> contacts);
typedef OnMessageCallback = void Function(Message message);
typedef OnTelemetryCallback = void Function(Uint8List publicKey, Uint8List lppData);
typedef OnSelfInfoCallback = void Function(Map<String, dynamic> selfInfo);
typedef OnDeviceInfoCallback = void Function(Map<String, dynamic> deviceInfo);
typedef OnNoMoreMessagesCallback = void Function();
typedef OnMessageWaitingCallback = void Function();
typedef OnLoginSuccessCallback = void Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag);
typedef OnLoginFailCallback = void Function(Uint8List publicKeyPrefix);
typedef OnAdvertReceivedCallback = void Function(Uint8List publicKey);
typedef OnPathUpdatedCallback = void Function(Uint8List publicKey);
typedef OnMessageSentCallback = void Function(int expectedAckTag, int suggestedTimeoutMs, bool isFloodMode);
typedef OnMessageDeliveredCallback = void Function(int ackCode, int roundTripTimeMs);
typedef OnStatusResponseCallback = void Function(Uint8List publicKeyPrefix, Uint8List statusData);
typedef OnBinaryResponseCallback = void Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData);
typedef OnBatteryAndStorageCallback = void Function(int millivolts, int? usedKb, int? totalKb);
typedef OnErrorCallback = void Function(String error, {int? errorCode});
typedef OnContactNotFoundCallback = void Function(Uint8List? contactPublicKey);

/// Processes incoming responses from the BLE device
class BleResponseHandler {
  StreamSubscription? _txSubscription;
  final List<Contact> _pendingContacts = [];
  int _rxPacketCount = 0;
  final List<BlePacketLog> _packetLogs = [];
  static const int _maxLogSize = 1000;

  // Callbacks
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
  OnStatusResponseCallback? onStatusResponse;
  OnBinaryResponseCallback? onBinaryResponse;
  OnBatteryAndStorageCallback? onBatteryAndStorage;
  OnErrorCallback? onError;
  OnContactNotFoundCallback? onContactNotFound;
  VoidCallback? onRxActivity;

  // Track the last command that was sent, so we can retry if it fails with ERR_CODE_NOT_FOUND
  Uint8List? _lastContactPublicKey;

  // Getters
  int get rxPacketCount => _rxPacketCount;
  List<BlePacketLog> get packetLogs => List.unmodifiable(_packetLogs);

  /// Subscribe to TX characteristic notifications
  void subscribeToNotifications(BluetoothCharacteristic txCharacteristic) {
    _txSubscription = txCharacteristic.lastValueStream.listen(
      _onDataReceived,
      onError: (error) {
        print('❌ [BLE] TX notification error: $error');
        onError?.call('TX notification error: $error');
      },
    );
  }

  /// Handle incoming data from TX characteristic
  void _onDataReceived(List<int> data) {
    try {
      // Handle empty data
      if (data.isEmpty) {
        print('⚠️ [RX] Empty data received, ignoring');
        return;
      }

      final dataBytes = Uint8List.fromList(data);

      // Increment RX packet counter and trigger activity indicator
      _rxPacketCount++;
      onRxActivity?.call();

      final reader = BufferReader(dataBytes);
      final responseCode = reader.readByte();

      // Get opcode name for logging
      final opcodeName = MeshCoreOpcodeNames.getOpcodeName(responseCode, isTx: false);
      final opcodeHex = '0x${responseCode.toRadixString(16).padLeft(2, '0').toUpperCase()}';

      print('📥 [RX] Received: $opcodeName ($opcodeHex)');
      print('  Data size: ${data.length} bytes');
      print('  Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('  Payload: ${reader.remainingBytesCount} bytes');

      // Log RX packet (before processing so we capture everything)
      _logPacket(dataBytes, PacketDirection.rx, responseCode: responseCode);

      switch (responseCode) {
        case MeshCoreConstants.respContactsStart:
          print('  → Handling ContactsStart');
          _handleContactsStart(reader);
          break;
        case MeshCoreConstants.respContact:
          print('  → Handling Contact');
          _handleContact(reader);
          break;
        case MeshCoreConstants.respEndOfContacts:
          print('  → Handling EndOfContacts');
          _handleEndOfContacts(reader);
          break;
        case MeshCoreConstants.respSent:
          print('  → Handling Sent confirmation');
          _handleSentConfirmation(reader);
          break;
        case MeshCoreConstants.respContactMsgRecv:
          print('  → Handling ContactMessage');
          _handleContactMessage(reader);
          break;
        case MeshCoreConstants.respChannelMsgRecv:
          print('  → Handling ChannelMessage');
          _handleChannelMessage(reader);
          break;
        case MeshCoreConstants.pushTelemetryResponse:
          print('  → Handling TelemetryResponse');
          _handleTelemetryResponse(reader);
          break;
        case MeshCoreConstants.pushBinaryResponse:
          print('  → Handling BinaryResponse');
          _handleBinaryResponse(reader);
          break;
        case MeshCoreConstants.respDeviceInfo:
          print('  → Handling DeviceInfo');
          _handleDeviceInfo(reader);
          break;
        case MeshCoreConstants.respSelfInfo:
          print('  → Handling SelfInfo');
          _handleSelfInfo(reader);
          break;
        case MeshCoreConstants.pushAdvert:
          print('  → Handling Advert push');
          _handleAdvert(reader);
          break;
        case MeshCoreConstants.pushPathUpdated:
          print('  → Handling PathUpdated push');
          _handlePathUpdated(reader);
          break;
        case MeshCoreConstants.pushLogRxData:
          print('  → Handling LogRxData push');
          _handleLogRxData(reader);
          break;
        case MeshCoreConstants.pushNewAdvert:
          print('  → Handling NewAdvert push');
          _handleNewAdvert(reader);
          break;
        case MeshCoreConstants.pushSendConfirmed:
          print('  → Handling SendConfirmed push');
          _handleSendConfirmed(reader);
          break;
        case MeshCoreConstants.pushMsgWaiting:
          print('  → Handling MsgWaiting push');
          _handleMsgWaiting(reader);
          break;
        case MeshCoreConstants.pushLoginSuccess:
          print('  → Handling LoginSuccess push');
          _handleLoginSuccess(reader);
          break;
        case MeshCoreConstants.pushLoginFail:
          print('  → Handling LoginFail push');
          _handleLoginFail(reader);
          break;
        case MeshCoreConstants.pushStatusResponse:
          print('  → Handling StatusResponse push');
          _handleStatusResponse(reader);
          break;
        case MeshCoreConstants.respCurrTime:
          print('  → Handling CurrentTime');
          _handleCurrentTime(reader);
          break;
        case MeshCoreConstants.respBatteryVoltage:
          print('  → Handling BatteryAndStorage');
          _handleBatteryAndStorage(reader);
          break;
        case MeshCoreConstants.respNoMoreMessages:
          print('  → Response: No More Messages');
          onNoMoreMessages?.call();
          break;
        case MeshCoreConstants.respOk:
          print('  → Response: OK');
          break;
        case MeshCoreConstants.respErr:
          print('  → Response: ERROR');
          _handleError(reader);
          break;
        default:
          print('  ⚠️ Unknown response code: $responseCode');
          break;
      }
      print('✅ [BLE] Data parsed successfully');
    } catch (e, stackTrace) {
      print('❌ [BLE] Data parsing error: $e');
      print('  Stack trace: $stackTrace');
      onError?.call('Data parsing error: $e');
    }
  }

  /// Handle ContactsStart response
  void _handleContactsStart(BufferReader reader) {
    _pendingContacts.clear();
    FrameParser.parseContactsStart(reader);
  }

  /// Handle Contact response
  void _handleContact(BufferReader reader) {
    try {
      final contact = FrameParser.parseContact(reader);
      print('  ✅ [Contact] Parsed successfully');
      _pendingContacts.add(contact);
      onContactReceived?.call(contact);
    } catch (e) {
      print('  ❌ [Contact] Parsing error: $e');
      onError?.call('Contact parsing error: $e');
    }
  }

  /// Handle EndOfContacts response
  void _handleEndOfContacts(BufferReader reader) {
    onContactsComplete?.call(List.from(_pendingContacts));
    _pendingContacts.clear();
  }

  /// Handle Sent confirmation response
  void _handleSentConfirmation(BufferReader reader) {
    try {
      final result = FrameParser.parseSentConfirmation(reader);
      if (result.isNotEmpty) {
        print('  ✅ [Sent] Message sent successfully');
        onMessageSent?.call(
          result['expectedAckTag'] as int,
          result['suggestedTimeout'] as int,
          result['isFloodMode'] as bool,
        );
      }
    } catch (e) {
      print('  ❌ [Sent] Parsing error: $e');
    }
  }

  /// Handle ContactMessage response
  void _handleContactMessage(BufferReader reader) {
    try {
      final message = FrameParser.parseContactMessage(reader);
      print('  ✅ [ContactMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      print('  ❌ [ContactMessage] Parsing error: $e');
      onError?.call('Contact message parsing error: $e');
    }
  }

  /// Handle ChannelMessage response
  void _handleChannelMessage(BufferReader reader) {
    try {
      final message = FrameParser.parseChannelMessage(reader);
      print('  ✅ [ChannelMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      print('  ❌ [ChannelMessage] Parsing error: $e');
      onError?.call('Channel message parsing error: $e');
    }
  }

  /// Handle TelemetryResponse push
  void _handleTelemetryResponse(BufferReader reader) {
    try {
      final result = FrameParser.parseTelemetryResponse(reader);
      print('  ✅ [Telemetry] Parsed successfully');
      onTelemetryReceived?.call(
        result['publicKeyPrefix'] as Uint8List,
        result['lppSensorData'] as Uint8List,
      );
    } catch (e) {
      print('  ❌ [Telemetry] Parsing error: $e');
      onError?.call('Telemetry parsing error: $e');
    }
  }

  /// Handle BinaryResponse push
  void _handleBinaryResponse(BufferReader reader) {
    try {
      final result = FrameParser.parseBinaryResponse(reader);
      print('  ✅ [BinaryResponse] Parsed successfully');
      onBinaryResponse?.call(
        result['publicKeyPrefix'] as Uint8List,
        result['tag'] as int,
        result['responseData'] as Uint8List,
      );
    } catch (e) {
      print('  ❌ [BinaryResponse] Parsing error: $e');
      onError?.call('Binary response parsing error: $e');
    }
  }

  /// Handle DeviceInfo response
  void _handleDeviceInfo(BufferReader reader) {
    try {
      final info = FrameParser.parseDeviceInfo(reader);
      onDeviceInfoReceived?.call(info);
      print('  ✅ [DeviceInfo] Parsed successfully');
    } catch (e) {
      print('  ❌ [DeviceInfo] Parsing error: $e');
      onError?.call('DeviceInfo parsing error: $e');
    }
  }

  /// Handle SelfInfo response
  void _handleSelfInfo(BufferReader reader) {
    try {
      final info = FrameParser.parseSelfInfo(reader);
      if (info.isNotEmpty) {
        onSelfInfoReceived?.call(info);
      }
      print('  ✅ [SelfInfo] Parsed successfully');
    } catch (e) {
      print('  ❌ [SelfInfo] Parsing error: $e');
    }
  }

  /// Handle Advert push
  void _handleAdvert(BufferReader reader) {
    try {
      final publicKey = FrameParser.parseAdvert(reader);
      if (publicKey != null) {
        onAdvertReceived?.call(publicKey);
      }
      print('  ✅ [Advert] Parsed successfully');
    } catch (e) {
      print('  ❌ [Advert] Parsing error: $e');
    }
  }

  /// Handle PathUpdated push
  void _handlePathUpdated(BufferReader reader) {
    try {
      final publicKey = FrameParser.parsePathUpdated(reader);
      if (publicKey != null) {
        onPathUpdated?.call(publicKey);
      }
      print('  ✅ [PathUpdated] Parsed successfully');
    } catch (e) {
      print('  ❌ [PathUpdated] Parsing error: $e');
    }
  }

  /// Handle LogRxData push - includes extensive decoding logic
  void _handleLogRxData(BufferReader reader) {
    try {
      print('  [LogRxData] Parsing log rx data from over-the-air packet...');
      final data = reader.readRemainingBytes();

      if (data.length < 2) {
        print('  ⚠️ [LogRxData] Insufficient data');
        return;
      }

      final snrRaw = data[0];
      final snrDb = (snrRaw.toSigned(8)) / 4.0;
      print('    SNR: ${snrDb.toStringAsFixed(2)} dB');

      final rssiDbm = data[1].toSigned(8);
      print('    RSSI: $rssiDbm dBm');

      if (data.length <= 2) {
        print('  ⚠️ [LogRxData] No raw packet data');
        return;
      }

      final rawPacketData = data.sublist(2);
      print('    Raw packet data: ${rawPacketData.length} bytes');

      // Calculate entropy
      final uniqueBytes = rawPacketData.toSet().length;
      final entropy = uniqueBytes / rawPacketData.length;
      final isLikelyEncrypted = entropy > 0.7;

      // Create decoded info for packet log (includes SNR and RSSI)
      final logRxDataInfo = LogRxDataInfo(
        entropy: entropy,
        isLikelyEncrypted: isLikelyEncrypted,
        snrDb: snrDb,
        rssiDbm: rssiDbm,
      );

      // Update the most recent packet log entry
      if (_packetLogs.isNotEmpty) {
        final lastLog = _packetLogs.last;
        if (lastLog.responseCode == MeshCoreConstants.pushLogRxData) {
          _packetLogs[_packetLogs.length - 1] = BlePacketLog(
            timestamp: lastLog.timestamp,
            rawData: lastLog.rawData,
            direction: lastLog.direction,
            responseCode: lastLog.responseCode,
            description: lastLog.description,
            logRxDataInfo: logRxDataInfo,
          );
        }
      }

      print('  ✅ [LogRxData] Parsed successfully');
    } catch (e) {
      print('  ❌ [LogRxData] Parsing error: $e');
    }
  }

  /// Handle NewAdvert push
  void _handleNewAdvert(BufferReader reader) {
    try {
      final contact = FrameParser.parseContact(reader);
      print('  ✅ [NewAdvert] Parsed successfully');
      onContactReceived?.call(contact);
    } catch (e) {
      print('  ❌ [NewAdvert] Parsing error: $e');
      onError?.call('NewAdvert parsing error: $e');
    }
  }

  /// Handle SendConfirmed push
  void _handleSendConfirmed(BufferReader reader) {
    try {
      final result = FrameParser.parseSendConfirmed(reader);
      if (result.isNotEmpty) {
        print('  ✅ [SendConfirmed] Message delivery confirmed');
        onMessageDelivered?.call(
          result['ackCode'] as int,
          result['roundTripTime'] as int,
        );
      }
    } catch (e) {
      print('  ❌ [SendConfirmed] Parsing error: $e');
    }
  }

  /// Handle MsgWaiting push
  void _handleMsgWaiting(BufferReader reader) {
    try {
      print('  [MsgWaiting] New message(s) waiting in queue');
      onMessageWaiting?.call();
    } catch (e) {
      print('  ❌ [MsgWaiting] Parsing error: $e');
    }
  }

  /// Handle LoginSuccess push
  void _handleLoginSuccess(BufferReader reader) {
    try {
      final result = FrameParser.parseLoginSuccess(reader);
      if (result.isNotEmpty) {
        print('  ✅ [LoginSuccess] Successfully logged into room');
        onLoginSuccess?.call(
          result['publicKeyPrefix'] as Uint8List,
          result['permissions'] as int,
          result['isAdmin'] as bool,
          result['tag'] as int,
        );
      }
    } catch (e) {
      print('  ❌ [LoginSuccess] Parsing error: $e');
      onError?.call('Login success parsing error: $e');
    }
  }

  /// Handle LoginFail push
  void _handleLoginFail(BufferReader reader) {
    try {
      final publicKeyPrefix = FrameParser.parseLoginFail(reader);
      if (publicKeyPrefix != null) {
        print('  ❌ [LoginFail] Failed to login to room');
        onLoginFail?.call(publicKeyPrefix);
      }
    } catch (e) {
      print('  ❌ [LoginFail] Parsing error: $e');
      onError?.call('Login fail parsing error: $e');
    }
  }

  /// Handle StatusResponse push
  void _handleStatusResponse(BufferReader reader) {
    try {
      final result = FrameParser.parseStatusResponse(reader);
      if (result.isNotEmpty) {
        // Try to decode as ASCII text if printable
        try {
          final statusData = result['statusData'] as Uint8List;
          final statusText = utf8.decode(statusData, allowMalformed: true);
          if (statusText.isNotEmpty && _isPrintableAscii(statusText)) {
            print('    Status data (text): $statusText');
          }
        } catch (e) {
          // Not text data
        }

        print('  ✅ [StatusResponse] Received status response');
        onStatusResponse?.call(
          result['publicKeyPrefix'] as Uint8List,
          result['statusData'] as Uint8List,
        );
      }
    } catch (e) {
      print('  ❌ [StatusResponse] Parsing error: $e');
      onError?.call('Status response parsing error: $e');
    }
  }

  /// Check if a string contains only printable ASCII characters
  bool _isPrintableAscii(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code < 32 || code > 126) {
        if (code != 10 && code != 13 && code != 9) {
          return false;
        }
      }
    }
    return true;
  }

  /// Handle CurrentTime response
  void _handleCurrentTime(BufferReader reader) {
    try {
      final deviceTime = FrameParser.parseCurrentTime(reader);
      if (deviceTime != null) {
        final appTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final drift = appTime - deviceTime;
        print('    Clock drift: $drift seconds');
      }
      print('  ✅ [CurrentTime] Parsed successfully');
    } catch (e) {
      print('  ❌ [CurrentTime] Parsing error: $e');
      onError?.call('CurrentTime parsing error: $e');
    }
  }

  /// Handle BatteryAndStorage response
  void _handleBatteryAndStorage(BufferReader reader) {
    try {
      final result = FrameParser.parseBatteryAndStorage(reader);
      if (result.isNotEmpty) {
        onBatteryAndStorage?.call(
          result['millivolts'] as int,
          result['usedKb'] as int?,
          result['totalKb'] as int?,
        );
      }
      print('  ✅ [BatteryAndStorage] Parsed successfully');
    } catch (e) {
      print('  ❌ [BatteryAndStorage] Parsing error: $e');
      onError?.call('BatteryAndStorage parsing error: $e');
    }
  }

  /// Handle Error response
  void _handleError(BufferReader reader) {
    try {
      final errorCode = FrameParser.parseError(reader);
      if (errorCode != null) {
        final errorMsg = FrameParser.getErrorMessage(errorCode);
        print('  ❌ [Error] $errorMsg');

        // Special handling for ERR_CODE_NOT_FOUND (2) - contact not in radio
        if (errorCode == 2) {  // ERR_CODE_NOT_FOUND
          print('  ⚠️ [Error] Contact not found in radio - attempting auto-recovery');
          onContactNotFound?.call(_lastContactPublicKey);
        }

        onError?.call(errorMsg, errorCode: errorCode);
      }
    } catch (e) {
      print('  ❌ [Error] Parsing error: $e');
    }
  }

  /// Track the last contact public key for retry logic
  void setLastContactPublicKey(Uint8List? publicKey) {
    _lastContactPublicKey = publicKey;
  }

  /// Log a packet
  void _logPacket(Uint8List data, PacketDirection direction, {int? responseCode}) {
    _packetLogs.add(BlePacketLog(
      timestamp: DateTime.now(),
      rawData: data,
      direction: direction,
      responseCode: responseCode,
      description: _getPacketDescription(responseCode),
    ));

    if (_packetLogs.length > _maxLogSize) {
      _packetLogs.removeAt(0);
    }
  }

  /// Get human-readable description of packet
  String? _getPacketDescription(int? code) {
    // RX packets - response codes
    switch (code) {
      case 2: // respContactsStart
        return 'Contacts Start';
      case 3: // respContact
        return 'Contact Info';
      case 4: // respEndOfContacts
        return 'End of Contacts';
      case 6: // respSent
        return 'Message Sent';
      case 7: // respContactMsgRecv
        return 'Contact Message';
      case 8: // respChannelMsgRecv
        return 'Channel Message';
      case 0x8B: // pushTelemetryResponse
        return 'Telemetry Data';
      case 13: // respDeviceInfo
        return 'Device Info';
      case 5: // respSelfInfo
        return 'Self Info';
      case 0x80: // pushAdvert
        return 'Advertisement';
      case 0x81: // pushPathUpdated
        return 'Path Updated';
      case 0x88: // pushLogRxData
        return 'Log RX Data';
      case 0x8A: // pushNewAdvert
        return 'New Advertisement';
      case 0x87: // pushStatusResponse
        return 'Status Response';
      case 10: // respNoMoreMessages
        return 'No More Messages';
      case 0: // respOk
        return 'OK';
      case 1: // respErr
        return 'ERROR';
      default:
        return null;
    }
  }

  /// Reset packet counter
  void resetCounter() {
    _rxPacketCount = 0;
  }

  /// Clear packet logs
  void clearPacketLogs() {
    _packetLogs.clear();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _txSubscription?.cancel();
    _pendingContacts.clear();
    _packetLogs.clear();
  }
}
