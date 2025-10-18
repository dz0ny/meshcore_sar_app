import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../models/ble_packet_log.dart';
import '../../models/sent_message_tracker.dart';
import '../buffer_reader.dart';
import '../meshcore_constants.dart';
import '../meshcore_opcode_names.dart';
import '../protocol/frame_parser.dart';
import 'ble_command_queue.dart';

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
typedef OnChannelInfoCallback = void Function(int channelIdx, String channelName);
typedef OnMessageEchoDetectedCallback = void Function(String messageId, int echoCount, int snrRaw, int rssiDbm);

/// Processes incoming responses from the BLE device
class BleResponseHandler {
  StreamSubscription? _txSubscription;
  final List<Contact> _pendingContacts = [];
  int _rxPacketCount = 0;
  final List<BlePacketLog> _packetLogs = [];
  static const int _maxLogSize = 1000;

  // Reference to command queue for completing pending commands
  BleCommandQueue? _commandQueue;

  // Echo detection for public channel messages
  final Map<String, SentMessageTracker> _sentMessageTrackers = {};
  static const int _maxTrackers = 100;
  static const Duration _trackerTTL = Duration(minutes: 5);

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
  OnChannelInfoCallback? onChannelInfoReceived;
  OnMessageEchoDetectedCallback? onMessageEchoDetected;
  VoidCallback? onRxActivity;

  // Track the last command that was sent, so we can retry if it fails with ERR_CODE_NOT_FOUND
  Uint8List? _lastContactPublicKey;

  // Getters
  int get rxPacketCount => _rxPacketCount;
  List<BlePacketLog> get packetLogs => List.unmodifiable(_packetLogs);

  /// Set the command queue for completing pending commands
  void setCommandQueue(BleCommandQueue? queue) {
    _commandQueue = queue;
  }

  /// Subscribe to TX characteristic notifications
  void subscribeToNotifications(BluetoothCharacteristic txCharacteristic) {
    _txSubscription = txCharacteristic.lastValueStream.listen(
      _onDataReceived,
      onError: (error) {
        debugPrint('❌ [BLE] TX notification error: $error');
        onError?.call('TX notification error: $error');
      },
    );
  }

  /// Handle incoming data from TX characteristic
  void _onDataReceived(List<int> data) {
    try {
      // Handle empty data
      if (data.isEmpty) {
        debugPrint('⚠️ [RX] Empty data received, ignoring');
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

      debugPrint('📥 [RX] Received: $opcodeName ($opcodeHex)');
      debugPrint('  Data size: ${data.length} bytes');
      debugPrint('  Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      debugPrint('  Payload: ${reader.remainingBytesCount} bytes');

      // Log RX packet (before processing so we capture everything)
      _logPacket(dataBytes, PacketDirection.rx, responseCode: responseCode);

      switch (responseCode) {
        case MeshCoreConstants.respContactsStart:
          debugPrint('  → Handling ContactsStart');
          _handleContactsStart(reader);
          break;
        case MeshCoreConstants.respContact:
          debugPrint('  → Handling Contact');
          _handleContact(reader);
          break;
        case MeshCoreConstants.respEndOfContacts:
          debugPrint('  → Handling EndOfContacts');
          _handleEndOfContacts(reader);
          break;
        case MeshCoreConstants.respSent:
          debugPrint('  → Handling Sent confirmation');
          _handleSentConfirmation(reader);
          break;
        case MeshCoreConstants.respContactMsgRecv:
          debugPrint('  → Handling ContactMessage');
          _handleContactMessage(reader);
          break;
        case MeshCoreConstants.respChannelMsgRecv:
          debugPrint('  → Handling ChannelMessage');
          _handleChannelMessage(reader);
          break;
        case MeshCoreConstants.pushTelemetryResponse:
          debugPrint('  → Handling TelemetryResponse');
          _handleTelemetryResponse(reader);
          break;
        case MeshCoreConstants.pushBinaryResponse:
          debugPrint('  → Handling BinaryResponse');
          _handleBinaryResponse(reader);
          break;
        case MeshCoreConstants.respDeviceInfo:
          debugPrint('  → Handling DeviceInfo');
          _handleDeviceInfo(reader);
          break;
        case MeshCoreConstants.respSelfInfo:
          debugPrint('  → Handling SelfInfo');
          _handleSelfInfo(reader);
          break;
        case MeshCoreConstants.pushAdvert:
          debugPrint('  → Handling Advert push');
          _handleAdvert(reader);
          break;
        case MeshCoreConstants.pushPathUpdated:
          debugPrint('  → Handling PathUpdated push');
          _handlePathUpdated(reader);
          break;
        case MeshCoreConstants.pushLogRxData:
          debugPrint('  → Handling LogRxData push');
          _handleLogRxData(reader);
          break;
        case MeshCoreConstants.pushNewAdvert:
          debugPrint('  → Handling NewAdvert push');
          _handleNewAdvert(reader);
          break;
        case MeshCoreConstants.pushSendConfirmed:
          debugPrint('  → Handling SendConfirmed push');
          _handleSendConfirmed(reader);
          break;
        case MeshCoreConstants.pushMsgWaiting:
          debugPrint('  → Handling MsgWaiting push');
          _handleMsgWaiting(reader);
          break;
        case MeshCoreConstants.pushLoginSuccess:
          debugPrint('  → Handling LoginSuccess push');
          _handleLoginSuccess(reader);
          break;
        case MeshCoreConstants.pushLoginFail:
          debugPrint('  → Handling LoginFail push');
          _handleLoginFail(reader);
          break;
        case MeshCoreConstants.pushStatusResponse:
          debugPrint('  → Handling StatusResponse push');
          _handleStatusResponse(reader);
          break;
        case MeshCoreConstants.respCurrTime:
          debugPrint('  → Handling CurrentTime');
          _handleCurrentTime(reader);
          break;
        case MeshCoreConstants.respBatteryVoltage:
          debugPrint('  → Handling BatteryAndStorage');
          _handleBatteryAndStorage(reader);
          break;
        case MeshCoreConstants.respChannelInfo:
          debugPrint('  → Handling ChannelInfo');
          _handleChannelInfo(reader);
          break;
        case MeshCoreConstants.respNoMoreMessages:
          debugPrint('  → Response: No More Messages');
          onNoMoreMessages?.call();
          break;
        case MeshCoreConstants.respOk:
          debugPrint('  → Response: OK');
          // Complete any pending ACK command
          _commandQueue?.completeCommand<void>(MeshCoreConstants.respOk, null);
          break;
        case MeshCoreConstants.respErr:
          debugPrint('  → Response: ERROR');
          _handleError(reader);
          break;
        default:
          debugPrint('  ⚠️ Unknown response code: $responseCode');
          break;
      }
      debugPrint('✅ [BLE] Data parsed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [BLE] Data parsing error: $e');
      debugPrint('  Stack trace: $stackTrace');
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
      debugPrint('  ✅ [Contact] Parsed successfully: ${contact.advName}');
      debugPrint('     outPathLen: ${contact.outPathLen} (${contact.pathDescription})');
      _pendingContacts.add(contact);
      onContactReceived?.call(contact);
    } catch (e) {
      debugPrint('  ❌ [Contact] Parsing error: $e');
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
        debugPrint('  ✅ [Sent] Message sent successfully');

        // Complete any pending command waiting for sent confirmation
        _commandQueue?.completeCommand<Map<String, dynamic>>(
          MeshCoreConstants.respSent,
          result,
        );

        onMessageSent?.call(
          result['expectedAckTag'] as int,
          result['suggestedTimeout'] as int,
          result['isFloodMode'] as bool,
        );
      }
    } catch (e) {
      debugPrint('  ❌ [Sent] Parsing error: $e');
    }
  }

  /// Handle ContactMessage response
  void _handleContactMessage(BufferReader reader) {
    try {
      final message = FrameParser.parseContactMessage(reader);
      debugPrint('  ✅ [ContactMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      debugPrint('  ❌ [ContactMessage] Parsing error: $e');
      onError?.call('Contact message parsing error: $e');
    }
  }

  /// Handle ChannelMessage response
  void _handleChannelMessage(BufferReader reader) {
    try {
      final message = FrameParser.parseChannelMessage(reader);
      debugPrint('  ✅ [ChannelMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      debugPrint('  ❌ [ChannelMessage] Parsing error: $e');
      onError?.call('Channel message parsing error: $e');
    }
  }

  /// Handle TelemetryResponse push
  void _handleTelemetryResponse(BufferReader reader) {
    try {
      final result = FrameParser.parseTelemetryResponse(reader);
      debugPrint('  ✅ [Telemetry] Parsed successfully');
      onTelemetryReceived?.call(
        result['publicKeyPrefix'] as Uint8List,
        result['lppSensorData'] as Uint8List,
      );
    } catch (e) {
      debugPrint('  ❌ [Telemetry] Parsing error: $e');
      onError?.call('Telemetry parsing error: $e');
    }
  }

  /// Handle BinaryResponse push
  void _handleBinaryResponse(BufferReader reader) {
    try {
      final result = FrameParser.parseBinaryResponse(reader);
      debugPrint('  ✅ [BinaryResponse] Parsed successfully');
      onBinaryResponse?.call(
        result['publicKeyPrefix'] as Uint8List,
        result['tag'] as int,
        result['responseData'] as Uint8List,
      );
    } catch (e) {
      debugPrint('  ❌ [BinaryResponse] Parsing error: $e');
      onError?.call('Binary response parsing error: $e');
    }
  }

  /// Handle DeviceInfo response
  void _handleDeviceInfo(BufferReader reader) {
    try {
      final info = FrameParser.parseDeviceInfo(reader);

      // Complete any pending command waiting for device info
      _commandQueue?.completeCommand<Map<String, dynamic>>(
        MeshCoreConstants.respDeviceInfo,
        info,
      );

      onDeviceInfoReceived?.call(info);
      debugPrint('  ✅ [DeviceInfo] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [DeviceInfo] Parsing error: $e');
      onError?.call('DeviceInfo parsing error: $e');
    }
  }

  /// Handle SelfInfo response
  void _handleSelfInfo(BufferReader reader) {
    try {
      final info = FrameParser.parseSelfInfo(reader);

      // Complete any pending command waiting for self info
      if (info.isNotEmpty) {
        _commandQueue?.completeCommand<Map<String, dynamic>>(
          MeshCoreConstants.respSelfInfo,
          info,
        );
        onSelfInfoReceived?.call(info);
      }

      debugPrint('  ✅ [SelfInfo] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [SelfInfo] Parsing error: $e');
    }
  }

  /// Handle Advert push
  void _handleAdvert(BufferReader reader) {
    try {
      final publicKey = FrameParser.parseAdvert(reader);
      if (publicKey != null) {
        onAdvertReceived?.call(publicKey);
      }
      debugPrint('  ✅ [Advert] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [Advert] Parsing error: $e');
    }
  }

  /// Handle PathUpdated push
  void _handlePathUpdated(BufferReader reader) {
    try {
      final publicKey = FrameParser.parsePathUpdated(reader);
      if (publicKey != null) {
        onPathUpdated?.call(publicKey);
      }
      debugPrint('  ✅ [PathUpdated] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [PathUpdated] Parsing error: $e');
    }
  }

  /// Handle LogRxData push - includes extensive decoding logic
  void _handleLogRxData(BufferReader reader) {
    try {
      debugPrint('  [LogRxData] Parsing log rx data from over-the-air packet...');
      final data = reader.readRemainingBytes();

      if (data.length < 2) {
        debugPrint('  ⚠️ [LogRxData] Insufficient data');
        return;
      }

      final snrRaw = data[0];
      final snrDb = (snrRaw.toSigned(8)) / 4.0;
      debugPrint('    SNR: ${snrDb.toStringAsFixed(2)} dB');

      final rssiDbm = data[1].toSigned(8);
      debugPrint('    RSSI: $rssiDbm dBm');

      if (data.length <= 2) {
        debugPrint('  ⚠️ [LogRxData] No raw packet data');
        return;
      }

      final rawPacketData = data.sublist(2);
      debugPrint('    Raw packet data: ${rawPacketData.length} bytes');

      // Decode packet header and path for display
      if (rawPacketData.length >= 2) {
        final header = rawPacketData[0];
        final payloadType = (header >> 2) & 0x0F;
        final pathLen = rawPacketData[1];

        debugPrint('    Packet type: 0x${payloadType.toRadixString(16).padLeft(2, '0')}');

        if (pathLen > 0 && rawPacketData.length >= 2 + pathLen) {
          final path = rawPacketData.sublist(2, 2 + pathLen);
          final pathStr = path.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' → ');
          debugPrint('    Path ($pathLen hops): $pathStr');

          // Highlight multi-hop packets
          if (pathLen > 1) {
            debugPrint('    🔄 MULTI-HOP PACKET! Original sender: 0x${path[0].toRadixString(16).padLeft(2, '0')}');
          }

          // Check if our node hash is in the path
          if (_ourNodeHash != null && path.contains(_ourNodeHash!)) {
            debugPrint('    ✅✅✅ ECHO DETECTED! Path contains our hash (0x${_ourNodeHash!.toRadixString(16).padLeft(2, '0')}) ✅✅✅');
            if (path[0] == _ourNodeHash) {
              debugPrint('    👉 WE are the original sender!');
            } else {
              debugPrint('    👉 Original sender: 0x${path[0].toRadixString(16).padLeft(2, '0')}, WE sent it to the network');
            }
          } else {
            debugPrint('    ℹ️  Does NOT contain our hash (not our message)');
          }
        } else {
          debugPrint('    Path length: $pathLen');
        }
      }

      // Calculate entropy
      final uniqueBytes = rawPacketData.toSet().length;
      final entropy = uniqueBytes / rawPacketData.length;
      final isLikelyEncrypted = entropy > 0.7;

      // First, try to associate this packet with a recently sent message (within 2s)
      _associatePacketWithSentMessage(rawPacketData);

      // Then, check if this packet matches any sent message (echo detection)
      _checkForEcho(rawPacketData, snrRaw, rssiDbm);

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

      debugPrint('  ✅ [LogRxData] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [LogRxData] Parsing error: $e');
    }
  }

  /// Simple hash function for packet identification (replaces SHA256)
  String _simplePacketHash(Uint8List packet) {
    // Use a simple hash based on packet length and first/last bytes
    // This is sufficient for short-lived echo detection (5 min TTL)
    if (packet.isEmpty) return '0';

    int hash = packet.length;
    // Mix in bytes from start, middle, and end
    for (int i = 0; i < packet.length && i < 8; i++) {
      hash = ((hash << 5) - hash) + packet[i];
      hash = hash & 0xFFFFFFFF; // Keep 32-bit
    }
    if (packet.length > 16) {
      for (int i = packet.length ~/ 2; i < packet.length ~/ 2 + 8 && i < packet.length; i++) {
        hash = ((hash << 5) - hash) + packet[i];
        hash = hash & 0xFFFFFFFF;
      }
    }
    if (packet.length > 8) {
      for (int i = packet.length - 8; i < packet.length; i++) {
        hash = ((hash << 5) - hash) + packet[i];
        hash = hash & 0xFFFFFFFF;
      }
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Check if received packet is an echo of a sent message
  void _checkForEcho(Uint8List rawPacket, int snrRaw, int rssiDbm) {
    try {
      debugPrint('  🔍 [Echo] _checkForEcho called, packet size: ${rawPacket.length} bytes');

      // Need at least header + path_len
      if (rawPacket.length < 2) {
        debugPrint('  ⚠️ [Echo] Packet too short');
        return;
      }

      final header = rawPacket[0];
      final payloadType = (header >> 2) & 0x0F;
      debugPrint('  🔍 [Echo] Payload type: 0x${payloadType.toRadixString(16).padLeft(2, '0')}');
      if (payloadType != 0x05) {
        debugPrint('  ⚠️ [Echo] Not GRP_TXT, ignoring');
        return; // Only track GRP_TXT
      }

      final pathLen = rawPacket[1];
      debugPrint('  🔍 [Echo] Path length: $pathLen');
      if (pathLen == 0 || rawPacket.length < 2 + pathLen) {
        debugPrint('  ⚠️ [Echo] Invalid path length');
        return;
      }

      // Extract path for unique echo tracking
      final path = rawPacket.sublist(2, 2 + pathLen);
      final pathSignature = path.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

      // Check if our node hash is in the path (meaning this is our message being rebroadcast)
      final containsOurHash = _ourNodeHash != null && path.contains(_ourNodeHash!);
      if (!containsOurHash) {
        // This packet doesn't have our hash in the path, so it's not our message
        return;
      }

      // Extract encrypted payload
      final payloadStart = 2 + pathLen;
      final encryptedPayload = rawPacket.sublist(payloadStart);
      final payloadHash = _simplePacketHash(encryptedPayload);

      // Check if we have a matching sent message (by payload hash)
      final tracker = _sentMessageTrackers[payloadHash];
      if (tracker != null && !tracker.isExpired) {
        // Check if this is a NEW path (different from already seen paths)
        if (!tracker.uniqueEchoPaths.contains(pathSignature)) {
          // New echo detected via different path!
          tracker.uniqueEchoPaths.add(pathSignature);
          tracker.echoCount++;
          tracker.echoTimestamps.add(DateTime.now());

          debugPrint('  🔊 [Echo] New echo detected!');
          debugPrint('     Message: ${tracker.messageId}');
          debugPrint('     Path: $pathSignature');
          debugPrint('     Total echoes: ${tracker.echoCount}');
          debugPrint('     Unique paths: ${tracker.uniqueEchoPaths.length}');

          // Notify callback
          onMessageEchoDetected?.call(tracker.messageId, tracker.echoCount, snrRaw, rssiDbm);
        } else {
          debugPrint('  ♻️ [Echo] Duplicate path (already counted): $pathSignature');
        }
      }

      // Cleanup expired trackers
      _cleanupExpiredTrackers();
    } catch (e) {
      debugPrint('  ⚠️ [Echo] Error checking for echo: $e');
    }
  }

  /// Track a sent public channel message for echo detection
  ///
  /// NEW STRATEGY: Since firmware doesn't log our own transmissions,
  /// we track ANY GRP_TXT packets that arrive shortly after sending.
  /// The first packet with matching encrypted payload is likely our message,
  /// and subsequent packets with the same payload are echoes.
  void trackSentMessage(String messageId, Uint8List? rawPacket) {
    try {
      final now = DateTime.now();
      final tracker = SentMessageTracker(
        messageId: messageId,
        packetHashHex: 'pending', // Will be filled when we capture ANY packet
        rawPacket: null,
        sentTime: now,
        expiryTime: now.add(_trackerTTL),
      );

      // Store by message ID temporarily
      _sentMessageTrackers[messageId] = tracker;
      debugPrint('  📤 [Echo] Tracking message $messageId (will match any GRP_TXT within 10000ms)');
      debugPrint('  📊 [Echo] Total trackers: ${_sentMessageTrackers.length}');

      // Cleanup if too many trackers
      if (_sentMessageTrackers.length > _maxTrackers) {
        _cleanupOldestTrackers();
      }
    } catch (e) {
      debugPrint('  ⚠️ [Echo] Error tracking sent message: $e');
    }
  }

  // Store our node hash (first byte of our public key) for sender identification
  int? _ourNodeHash;

  /// Set our node hash for packet identification
  void setOurNodeHash(int nodeHash) {
    _ourNodeHash = nodeHash;
    debugPrint('  🔑 [Echo] Our node hash set to: 0x${nodeHash.toRadixString(16).padLeft(2, '0')}');
    debugPrint('  ℹ️  [Echo] Will track packets containing our hash in the path');
  }

  /// Associate a captured packet with a sent message
  ///
  /// NEW STRATEGY: Firmware doesn't log our own transmissions, only echoes!
  /// So we capture the FIRST GRP_TXT packet after sending (likely an echo),
  /// then count additional instances of the same packet payload.
  ///
  /// Packet structure for GRP_TXT:
  /// [0] = header (route type + payload type + version)
  /// [1] = path_len
  /// [2] = path[0] = sender's node hash
  /// [3+] = rest of path + encrypted payload
  void _associatePacketWithSentMessage(Uint8List rawPacket) {
    try {
      debugPrint('  🔍 [Echo] _associatePacketWithSentMessage called, packet size: ${rawPacket.length}');

      // Need at least 3 bytes: header + path_len + first path byte
      if (rawPacket.length < 3) {
        debugPrint('  ⚠️ [Echo] Packet too short for association');
        return;
      }

      // Check if this is a GRP_TXT packet (payload type = 0x05)
      final header = rawPacket[0];
      final payloadType = (header >> 2) & 0x0F;
      debugPrint('  🔍 [Echo] Association check - Payload type: 0x${payloadType.toRadixString(16).padLeft(2, '0')}');
      if (payloadType != 0x05) { // Not a group message
        debugPrint('  ⚠️ [Echo] Not GRP_TXT, skipping association');
        return;
      }

      final pathLen = rawPacket[1];
      debugPrint('  🔍 [Echo] Path length for association: $pathLen');
      if (pathLen == 0) {
        debugPrint('  ⚠️ [Echo] Path length is 0, skipping');
        return;
      }

      final now = DateTime.now();

      // Extract the path from the packet for unique echo tracking
      final path = rawPacket.sublist(2, 2 + pathLen);
      final pathSignature = path.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

      // Check if our node hash is in the path (meaning this is our message being rebroadcast)
      final containsOurHash = _ourNodeHash != null && path.contains(_ourNodeHash!);
      if (!containsOurHash) {
        // This packet doesn't have our hash in the path, so it's not our message
        return;
      }

      debugPrint('  ✅ [Echo] Packet contains our hash (0x${_ourNodeHash!.toRadixString(16).padLeft(2, '0')}) in path: $pathSignature');

      // Extract encrypted payload (everything after path)
      final payloadStart = 2 + pathLen;
      final encryptedPayload = rawPacket.sublist(payloadStart);
      // Hash only the encrypted payload to identify the same message
      final payloadHash = _simplePacketHash(encryptedPayload);

      // Find pending trackers (within 10000ms window)
      for (final entry in _sentMessageTrackers.entries.toList()) {
        final tracker = entry.value;
        if (tracker.packetHashHex != 'pending') continue;

        final timeSinceSent = now.difference(tracker.sentTime);
        if (timeSinceSent.inMilliseconds > 10000) continue; // Outside window

        // This is the FIRST packet we see after sending - associate it!
        // Remove old entry by message ID
        _sentMessageTrackers.remove(entry.key);

        // Create updated tracker stored by payload hash
        final updatedTracker = SentMessageTracker(
          messageId: tracker.messageId,
          packetHashHex: payloadHash, // Use payload hash to identify message
          rawPacket: rawPacket,
          sentTime: tracker.sentTime,
          expiryTime: tracker.expiryTime,
          echoCount: 1, // This first packet counts as an echo
          uniqueEchoPaths: {pathSignature}, // Track unique paths
          echoTimestamps: [now],
        );

        _sentMessageTrackers[payloadHash] = updatedTracker;
        debugPrint('  📦 [Echo] Captured packet for tracking!');
        debugPrint('     Message ID: ${tracker.messageId}');
        debugPrint('     Path: $pathSignature');
        debugPrint('     Time delta: ${timeSinceSent.inMilliseconds}ms');
        debugPrint('     Payload hash: $payloadHash');
        debugPrint('     Echo count: 1 (first detection)');

        // Notify immediately that we have 1 echo
        onMessageEchoDetected?.call(tracker.messageId, 1, 0, 0);
        break; // Only associate with first pending tracker
      }
    } catch (e) {
      debugPrint('  ⚠️ [Echo] Error associating packet: $e');
    }
  }

  /// Remove expired trackers
  void _cleanupExpiredTrackers() {
    final expiredCount = _sentMessageTrackers.values.where((t) => t.isExpired).length;
    if (expiredCount > 0) {
      debugPrint('  🧹 [Echo] Cleaning up $expiredCount expired tracker(s)');
    }
    _sentMessageTrackers.removeWhere((key, tracker) {
      if (tracker.isExpired && tracker.packetHashHex == 'pending') {
        debugPrint('  ⏱️ [Echo] Tracker expired without capturing: ${tracker.messageId}');
      }
      return tracker.isExpired;
    });
  }

  /// Remove oldest trackers when limit exceeded
  void _cleanupOldestTrackers() {
    if (_sentMessageTrackers.length <= _maxTrackers) return;

    // Sort by sent time and remove oldest
    final sortedEntries = _sentMessageTrackers.entries.toList()
      ..sort((a, b) => a.value.sentTime.compareTo(b.value.sentTime));

    final toRemove = sortedEntries.take(_sentMessageTrackers.length - _maxTrackers);
    for (final entry in toRemove) {
      _sentMessageTrackers.remove(entry.key);
    }

    debugPrint('  🧹 [Echo] Cleaned up ${toRemove.length} old trackers');
  }

  /// Handle NewAdvert push
  void _handleNewAdvert(BufferReader reader) {
    try {
      final contact = FrameParser.parseContact(reader);
      debugPrint('  ✅ [NewAdvert] Parsed successfully: ${contact.advName}');
      debugPrint('     outPathLen: ${contact.outPathLen} (${contact.pathDescription})');
      onContactReceived?.call(contact);
    } catch (e) {
      debugPrint('  ❌ [NewAdvert] Parsing error: $e');
      onError?.call('NewAdvert parsing error: $e');
    }
  }

  /// Handle SendConfirmed push
  void _handleSendConfirmed(BufferReader reader) {
    try {
      final result = FrameParser.parseSendConfirmed(reader);
      if (result.isNotEmpty) {
        debugPrint('  ✅ [SendConfirmed] Message delivery confirmed');
        onMessageDelivered?.call(
          result['ackCode'] as int,
          result['roundTripTime'] as int,
        );
      }
    } catch (e) {
      debugPrint('  ❌ [SendConfirmed] Parsing error: $e');
    }
  }

  /// Handle MsgWaiting push
  void _handleMsgWaiting(BufferReader reader) {
    try {
      debugPrint('  [MsgWaiting] New message(s) waiting in queue');
      onMessageWaiting?.call();
    } catch (e) {
      debugPrint('  ❌ [MsgWaiting] Parsing error: $e');
    }
  }

  /// Handle LoginSuccess push
  void _handleLoginSuccess(BufferReader reader) {
    try {
      final result = FrameParser.parseLoginSuccess(reader);
      if (result.isNotEmpty) {
        debugPrint('  ✅ [LoginSuccess] Successfully logged into room');
        onLoginSuccess?.call(
          result['publicKeyPrefix'] as Uint8List,
          result['permissions'] as int,
          result['isAdmin'] as bool,
          result['tag'] as int,
        );
      }
    } catch (e) {
      debugPrint('  ❌ [LoginSuccess] Parsing error: $e');
      onError?.call('Login success parsing error: $e');
    }
  }

  /// Handle LoginFail push
  void _handleLoginFail(BufferReader reader) {
    try {
      final publicKeyPrefix = FrameParser.parseLoginFail(reader);
      if (publicKeyPrefix != null) {
        debugPrint('  ❌ [LoginFail] Failed to login to room');
        onLoginFail?.call(publicKeyPrefix);
      }
    } catch (e) {
      debugPrint('  ❌ [LoginFail] Parsing error: $e');
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
            debugPrint('    Status data (text): $statusText');
          }
        } catch (e) {
          // Not text data
        }

        debugPrint('  ✅ [StatusResponse] Received status response');
        onStatusResponse?.call(
          result['publicKeyPrefix'] as Uint8List,
          result['statusData'] as Uint8List,
        );
      }
    } catch (e) {
      debugPrint('  ❌ [StatusResponse] Parsing error: $e');
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
        debugPrint('    Clock drift: $drift seconds');
      }
      debugPrint('  ✅ [CurrentTime] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [CurrentTime] Parsing error: $e');
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
      debugPrint('  ✅ [BatteryAndStorage] Parsed successfully');
    } catch (e) {
      debugPrint('  ❌ [BatteryAndStorage] Parsing error: $e');
      onError?.call('BatteryAndStorage parsing error: $e');
    }
  }

  /// Handle ChannelInfo response
  void _handleChannelInfo(BufferReader reader) {
    try {
      final info = FrameParser.parseChannelInfo(reader);
      if (info.isNotEmpty) {
        final channelIdx = info['channelIdx'] as int;
        final channelName = info['channelName'] as String;

        debugPrint('  ✅ [ChannelInfo] Channel $channelIdx: "${channelName}"');
        onChannelInfoReceived?.call(channelIdx, channelName);
      }
    } catch (e) {
      debugPrint('  ❌ [ChannelInfo] Parsing error: $e');
      onError?.call('ChannelInfo parsing error: $e');
    }
  }

  /// Handle Error response
  void _handleError(BufferReader reader) {
    try {
      final errorCode = FrameParser.parseError(reader);
      if (errorCode != null) {
        final errorMsg = FrameParser.getErrorMessage(errorCode);
        debugPrint('  ❌ [Error] $errorMsg');

        // Complete any pending ACK command with error
        _commandQueue?.completeCommandWithError(
          MeshCoreConstants.respOk,  // Command was expecting OK, got ERR
          errorMsg,
          errorCode: errorCode,
        );

        // Special handling for ERR_CODE_NOT_FOUND (2) - contact not in radio
        if (errorCode == 2) {  // ERR_CODE_NOT_FOUND
          debugPrint('  ⚠️ [Error] Contact not found in radio - attempting auto-recovery');
          onContactNotFound?.call(_lastContactPublicKey);
        }

        onError?.call(errorMsg, errorCode: errorCode);
      }
    } catch (e) {
      debugPrint('  ❌ [Error] Parsing error: $e');
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
