import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/contact.dart';
import '../models/contact_telemetry.dart';
import '../models/message.dart';
import '../models/ble_packet_log.dart';
import 'buffer_reader.dart';
import 'buffer_writer.dart';
import 'meshcore_constants.dart';
import 'meshcore_opcode_names.dart';

/// Callback types for MeshCore events
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
typedef OnErrorCallback = void Function(String error);
typedef OnConnectionStateCallback = void Function(bool isConnected);

/// MeshCore BLE Service - handles all BLE communication
class MeshCoreBleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _txSubscription;

  // Event callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
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
  OnErrorCallback? onError;

  // Internal state
  final List<Contact> _pendingContacts = [];
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Packet counters
  int _rxPacketCount = 0;
  int _txPacketCount = 0;
  int get rxPacketCount => _rxPacketCount;
  int get txPacketCount => _txPacketCount;

  // Activity callbacks (for blinking indicators)
  VoidCallback? onRxActivity;
  VoidCallback? onTxActivity;

  // Packet logging
  final List<BlePacketLog> _packetLogs = [];
  List<BlePacketLog> get packetLogs => List.unmodifiable(_packetLogs);
  static const int _maxLogSize = 1000; // Keep last 1000 packets

  /// Scan for MeshCore devices
  Stream<BluetoothDevice> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    try {
      print('🔍 [BLE] Starting scan for MeshCore devices...');
      print('  Service UUID: ${MeshCoreConstants.bleServiceUuid}');
      print('  Timeout: ${timeout.inSeconds}s');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(MeshCoreConstants.bleServiceUuid)],
      );
      print('✅ [BLE] Scan started successfully');

      // Listen to scan results
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

      // Listen to TX characteristic
      print('🔵 [BLE] Setting up TX characteristic listener...');
      _txSubscription = _txCharacteristic!.lastValueStream.listen(
        _onDataReceived,
        onError: (error) {
          print('❌ [BLE] TX notification error: $error');
          onError?.call('TX notification error: $error');
        },
      );
      print('✅ [BLE] TX listener configured');

      _isConnected = true;
      print('🔵 [BLE] Notifying connection state change: connected');
      onConnectionStateChanged?.call(true);

      // Send initial device query
      print('🔵 [BLE] Sending initial device query...');
      await _sendDeviceQuery();
      print('✅ [BLE] Device query sent');

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
      await _txSubscription?.cancel();
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

  /// Write data to RX characteristic
  Future<void> _writeData(Uint8List data) async {
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
    final count = reader.readUInt32LE();
    // Optional: notify about expected count
  }

  /// Handle Contact response
  void _handleContact(BufferReader reader) {
    try {
      print('  [Contact] Parsing contact...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final publicKey = reader.readBytes(32);
      print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final typeByte = reader.readByte();
      final type = ContactType.fromValue(typeByte);
      print('    Type byte: $typeByte → Type: $type');

      final flags = reader.readByte();
      print('    Flags: $flags (0x${flags.toRadixString(16).padLeft(2, '0')})');

      final outPathLen = reader.readInt8();
      print('    Out path length: $outPathLen');

      final outPath = reader.readBytes(64);
      print('    Out path: ${outPath.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...');

      final advName = reader.readCString(32);
      print('    Advertised name: "$advName"');

      final lastAdvert = reader.readUInt32LE();
      print('    Last advert timestamp: $lastAdvert');

      final advLat = reader.readInt32LE();
      print('    Latitude (raw int32): $advLat');
      print('    Latitude (decimal): ${advLat / 1000000.0}°');

      final advLon = reader.readInt32LE();
      print('    Longitude (raw int32): $advLon');
      print('    Longitude (decimal): ${advLon / 1000000.0}°');

      final lastMod = reader.readUInt32LE();
      print('    Last modified timestamp: $lastMod');

      final contact = Contact(
        publicKey: publicKey,
        type: type,
        flags: flags,
        outPathLen: outPathLen,
        outPath: outPath,
        advName: advName,
        lastAdvert: lastAdvert,
        advLat: advLat,
        advLon: advLon,
        lastMod: lastMod,
      );

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

  /// Handle Sent confirmation response (RESP_CODE_SENT)
  ///
  /// Protocol format:
  /// - 1 byte: send type (1=flood, 0=direct)
  /// - 4 bytes: expected ACK code or TAG
  /// - 4 bytes: suggested timeout (uint32, milliseconds)
  void _handleSentConfirmation(BufferReader reader) {
    try {
      print('  [Sent] Parsing sent confirmation...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 9) {
        final sendType = reader.readByte();
        final sendTypeStr = sendType == 1 ? 'flood' : 'direct';
        print('    Send type: $sendType ($sendTypeStr)');

        final expectedAckOrTag = reader.readBytes(4);
        print('    Expected ACK/TAG: ${expectedAckOrTag.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        final suggestedTimeout = reader.readUInt32LE();
        print('    Suggested timeout: ${suggestedTimeout}ms');

        print('  ✅ [Sent] Message sent successfully ($sendTypeStr mode, timeout: ${suggestedTimeout}ms)');

        // TODO: Store ACK/TAG to match with PUSH_CODE_SEND_CONFIRMED later
      } else {
        print('  ⚠️ [Sent] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [Sent] Parsing error: $e');
      // Don't call onError - sent confirmations are informational
    }
  }

  /// Handle ContactMsgRecv response
  void _handleContactMessage(BufferReader reader) {
    try {
      print('  [ContactMessage] Parsing contact message...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final pubKeyPrefix = reader.readBytes(6);
      print('    Sender public key prefix: ${pubKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final pathLen = reader.readByte();
      print('    Path length: $pathLen');

      final txtTypeByte = reader.readByte();
      final txtType = MessageTextType.fromValue(txtTypeByte);
      print('    Text type byte: $txtTypeByte → Type: $txtType');

      final senderTimestamp = reader.readUInt32LE();
      print('    Sender timestamp: $senderTimestamp (${DateTime.fromMillisecondsSinceEpoch(senderTimestamp * 1000)})');

      // Handle different message types
      String text;
      Uint8List? signature;

      if (txtType == MessageTextType.signedPlain) {
        // Signed message format: [64-byte signature][UTF-8 text]
        print('    Signed message detected - extracting signature');

        if (reader.remainingBytesCount < 64) {
          print('    ⚠️ Insufficient bytes for signature (${reader.remainingBytesCount} < 64)');
          // Try to read as plain text anyway
          text = reader.readString();
        } else {
          signature = reader.readBytes(64);
          print('    Signature (first 16 bytes): ${signature.sublist(0, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');

          // Remaining bytes are the actual text
          if (reader.hasRemaining) {
            text = reader.readString();
          } else {
            text = '';
            print('    ⚠️ No text content after signature');
          }
        }
      } else {
        // Plain text message
        text = reader.readString();
      }

      print('    Text: "$text"');

      final message = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_${pubKeyPrefix.map((b) => b.toRadixString(16)).join()}',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: pubKeyPrefix,
        pathLen: pathLen,
        textType: txtType,
        senderTimestamp: senderTimestamp,
        text: text,
        receivedAt: DateTime.now(),
      );

      print('  ✅ [ContactMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      print('  ❌ [ContactMessage] Parsing error: $e');
      onError?.call('Contact message parsing error: $e');
    }
  }

  /// Handle ChannelMsgRecv response
  void _handleChannelMessage(BufferReader reader) {
    try {
      print('  [ChannelMessage] Parsing channel message...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final channelIdx = reader.readInt8();
      print('    Channel index: $channelIdx');

      final pathLen = reader.readByte();
      print('    Path length: $pathLen');

      final txtTypeByte = reader.readByte();
      final txtType = MessageTextType.fromValue(txtTypeByte);
      print('    Text type byte: $txtTypeByte → Type: $txtType');

      final senderTimestamp = reader.readUInt32LE();
      print('    Sender timestamp: $senderTimestamp (${DateTime.fromMillisecondsSinceEpoch(senderTimestamp * 1000)})');

      // Handle different message types
      String text;
      Uint8List? signature;

      if (txtType == MessageTextType.signedPlain) {
        // Signed message format: [64-byte signature][UTF-8 text]
        print('    Signed message detected - extracting signature');

        if (reader.remainingBytesCount < 64) {
          print('    ⚠️ Insufficient bytes for signature (${reader.remainingBytesCount} < 64)');
          // Try to read as plain text anyway
          text = reader.readString();
        } else {
          signature = reader.readBytes(64);
          print('    Signature (first 16 bytes): ${signature.sublist(0, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');

          // Remaining bytes are the actual text
          if (reader.hasRemaining) {
            text = reader.readString();
          } else {
            text = '';
            print('    ⚠️ No text content after signature');
          }
        }
      } else {
        // Plain text message
        text = reader.readString();
      }

      print('    Text: "$text"');

      final message = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_ch$channelIdx',
        messageType: MessageType.channel,
        channelIdx: channelIdx,
        pathLen: pathLen,
        textType: txtType,
        senderTimestamp: senderTimestamp,
        text: text,
        receivedAt: DateTime.now(),
      );

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
      print('  [Telemetry] Parsing telemetry response...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final reserved = reader.readByte();
      print('    Reserved byte: $reserved');

      final pubKeyPrefix = reader.readBytes(6);
      print('    Public key prefix: ${pubKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final lppSensorData = reader.readRemainingBytes();
      print('    LPP sensor data length: ${lppSensorData.length} bytes');
      print('    LPP sensor data (hex): ${lppSensorData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      print('  ✅ [Telemetry] Parsed successfully');
      onTelemetryReceived?.call(pubKeyPrefix, lppSensorData);
    } catch (e) {
      print('  ❌ [Telemetry] Parsing error: $e');
      onError?.call('Telemetry parsing error: $e');
    }
  }

  /// Handle DeviceInfo response
  /// Handle DeviceInfo response (RESP_CODE_DEVICE_INFO)
  ///
  /// Protocol format:
  /// - 1 byte: firmware version
  /// - 1 byte: max contacts ÷ 2 (ver 3+)
  /// - 1 byte: max channels (ver 3+)
  /// - 4 bytes: BLE PIN (uint32, ver 3+)
  /// - 12 bytes: firmware build date (ASCII null-terminated)
  /// - 40 bytes: manufacturer model (ASCII null-terminated)
  /// - 20 bytes: semantic version (ASCII null-terminated)
  void _handleDeviceInfo(BufferReader reader) {
    try {
      print('  [DeviceInfo] Parsing device info...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount < 1) {
        print('  [DeviceInfo] No data to parse');
        return;
      }

      final firmwareVersion = reader.readByte();
      print('    Firmware version: $firmwareVersion');

      int? maxContacts;
      int? maxChannels;
      int? blePin;
      if (reader.remainingBytesCount >= 6) {
        final maxContactsDiv2 = reader.readByte();
        maxContacts = maxContactsDiv2 * 2;
        print('    Max contacts: $maxContacts');

        maxChannels = reader.readByte();
        print('    Max channels: $maxChannels');

        blePin = reader.readUInt32LE();
        print('    BLE PIN: $blePin');
      }

      String? firmwareBuildDate;
      if (reader.remainingBytesCount >= 12) {
        final buildDateBytes = reader.readBytes(12);
        firmwareBuildDate = String.fromCharCodes(buildDateBytes.takeWhile((b) => b != 0));
        print('    Firmware build date: "$firmwareBuildDate"');
      }

      String? manufacturerModel;
      if (reader.remainingBytesCount >= 40) {
        final modelBytes = reader.readBytes(40);
        manufacturerModel = String.fromCharCodes(modelBytes.takeWhile((b) => b != 0));
        print('    Manufacturer model: "$manufacturerModel"');
      }

      String? semanticVersion;
      if (reader.remainingBytesCount >= 20) {
        final versionBytes = reader.readBytes(20);
        semanticVersion = String.fromCharCodes(versionBytes.takeWhile((b) => b != 0));
        print('    Semantic version: "$semanticVersion"');
      }

      // Call callback with parsed data
      onDeviceInfoReceived?.call({
        'firmwareVersion': firmwareVersion,
        'maxContacts': maxContacts,
        'maxChannels': maxChannels,
        'blePin': blePin,
        'firmwareBuildDate': firmwareBuildDate,
        'manufacturerModel': manufacturerModel,
        'semanticVersion': semanticVersion,
      });

      print('  ✅ [DeviceInfo] Parsed successfully');
    } catch (e) {
      print('  ❌ [DeviceInfo] Parsing error: $e');
      onError?.call('DeviceInfo parsing error: $e');
    }
  }

  /// Handle SelfInfo response
  void _handleSelfInfo(BufferReader reader) {
    try {
      print('  [SelfInfo] Parsing self info...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // SelfInfo format (RESP_CODE_SELF_INFO):
      // - 1 byte: type (ADV_TYPE_*)
      // - 1 byte: tx power (dBm, current)
      // - 1 byte: max tx power (dBm, max radio supports)
      // - 32 bytes: public key
      // - 4 bytes: adv lat * 1E6 (int32)
      // - 4 bytes: adv lon * 1E6 (int32)
      // - 1 byte: multi ACKs (0=no extra, 1=send extra ACK)
      // - 1 byte: advert location policy (0=don't share, 1=share)
      // - 1 byte: telemetry modes (bits 0-1: Base, bits 2-3: Location)
      // - 1 byte: manual add contacts (0 or 1)
      // - 4 bytes: radio freq * 1000 (uint32)
      // - 4 bytes: radio bw (kHz) * 1000 (uint32)
      // - 1 byte: spreading factor
      // - 1 byte: coding rate
      // - remaining: self name (null-terminated varchar)

      if (reader.remainingBytesCount < 54) {
        print('  [SelfInfo] Insufficient data: ${reader.remainingBytesCount} bytes');
        // Just consume remaining bytes to avoid errors
        reader.readRemainingBytes();
        return;
      }

      print('    📍 BYTE-BY-BYTE PARSING DEBUG:');
      print('    Position before reads: offset=0, remaining=${reader.remainingBytesCount}');

      // NO protocol version byte - it starts with device type!
      final deviceType = reader.readByte();
      print('    [Byte 0] Device type: $deviceType (0x${deviceType.toRadixString(16).padLeft(2, '0')})');

      final txPower = reader.readByte();
      print('    [Byte 1] TX power: $txPower dBm (0x${txPower.toRadixString(16).padLeft(2, '0')})');

      final maxTxPower = reader.readByte();
      print('    [Byte 2] Max TX power: $maxTxPower dBm (0x${maxTxPower.toRadixString(16).padLeft(2, '0')})');

      final publicKey = reader.readBytes(32);
      print('    [Bytes 3-34] Public key (32 bytes): ${publicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');

      final advLatBytes = reader.readBytes(4);
      final advLat = ByteData.sublistView(Uint8List.fromList(advLatBytes)).getInt32(0, Endian.little);
      print('    [Bytes 35-38] Adv Lat (raw bytes): ${advLatBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 35-38] Adv Lat (int32 LE): $advLat');
      print('    [Bytes 35-38] Adv Lat (decimal): ${advLat / 1000000.0}°');

      final advLonBytes = reader.readBytes(4);
      final advLon = ByteData.sublistView(Uint8List.fromList(advLonBytes)).getInt32(0, Endian.little);
      print('    [Bytes 39-42] Adv Lon (raw bytes): ${advLonBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 39-42] Adv Lon (int32 LE): $advLon');
      print('    [Bytes 39-42] Adv Lon (decimal): ${advLon / 1000000.0}°');

      final multiAcks = reader.readByte();
      print('    [Byte 43] Multi ACKs: $multiAcks (0x${multiAcks.toRadixString(16).padLeft(2, '0')})');

      final advertLocPolicy = reader.readByte();
      print('    [Byte 44] Advert Loc Policy: $advertLocPolicy (0x${advertLocPolicy.toRadixString(16).padLeft(2, '0')})');

      final telemetryModes = reader.readByte();
      print('    [Byte 45] Telemetry Modes: $telemetryModes (0x${telemetryModes.toRadixString(16).padLeft(2, '0')})');

      final manualAddContacts = reader.readByte();
      print('    [Byte 46] Manual Add Contacts: $manualAddContacts (0x${manualAddContacts.toRadixString(16).padLeft(2, '0')})');

      final radioFreqBytes = reader.readBytes(4);
      final radioFreq = ByteData.sublistView(Uint8List.fromList(radioFreqBytes)).getUint32(0, Endian.little);
      print('    [Bytes 47-50] Radio Freq (raw bytes): ${radioFreqBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 47-50] Radio Freq (uint32 LE): $radioFreq');
      print('    [Bytes 47-50] Radio Freq (MHz): ${radioFreq / 1000.0}');

      final radioBwBytes = reader.readBytes(4);
      final radioBw = ByteData.sublistView(Uint8List.fromList(radioBwBytes)).getUint32(0, Endian.little);
      print('    [Bytes 51-54] Radio BW (raw bytes): ${radioBwBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 51-54] Radio BW (uint32 LE): $radioBw');
      print('    [Bytes 51-54] Radio BW (kHz): ${radioBw / 1000.0}');

      final radioSf = reader.readByte();
      print('    [Byte 55] Radio SF: $radioSf (0x${radioSf.toRadixString(16).padLeft(2, '0')})');

      final radioCr = reader.readByte();
      print('    [Byte 56] Radio CR: $radioCr (0x${radioCr.toRadixString(16).padLeft(2, '0')})');

      print('    Remaining bytes after radio params: ${reader.remainingBytesCount}');

      String? selfName;
      if (reader.hasRemaining) {
        final nameBytes = reader.readRemainingBytes();
        print('    Self name bytes (hex): ${nameBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        print('    Self name bytes (ASCII): ${nameBytes.map((b) => b >= 32 && b <= 126 ? String.fromCharCode(b) : '.')}');
        selfName = String.fromCharCodes(nameBytes.takeWhile((b) => b != 0));
        print('    Self name (parsed): "$selfName"');
      }

      print('    ✅ PARSED SUMMARY:');
      print('       Type: $deviceType');
      print('       TX Power: $txPower / $maxTxPower dBm');
      print('       Position: ${advLat / 1000000.0}°, ${advLon / 1000000.0}°');
      print('       Flags: multiAcks=$multiAcks, locPolicy=$advertLocPolicy, telemetry=$telemetryModes, manual=$manualAddContacts');
      print('       Radio: freq=${radioFreq / 1000.0} MHz, bw=${radioBw / 1000.0} kHz, sf=$radioSf, cr=$radioCr');
      print('       Name: "$selfName"');

      // Call callback with parsed data
      onSelfInfoReceived?.call({
        'deviceType': deviceType,
        'txPower': txPower,
        'maxTxPower': maxTxPower,
        'publicKey': publicKey,
        'advLat': advLat,
        'advLon': advLon,
        'manualAddContacts': manualAddContacts == 1,
        'radioFreq': radioFreq,
        'radioBw': radioBw,
        'radioSf': radioSf,
        'radioCr': radioCr,
        'selfName': selfName,
      });

      print('  ✅ [SelfInfo] Parsed successfully');
    } catch (e) {
      print('  ❌ [SelfInfo] Parsing error: $e');
      // Don't call onError for self info - it's not critical
    }
  }

  /// Handle Advert push
  void _handleAdvert(BufferReader reader) {
    try {
      print('  [Advert] Parsing advert...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // Advert format: 32 bytes public key
      if (reader.remainingBytesCount >= 32) {
        final publicKey = reader.readBytes(32);
        print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
      }

      // Consume any remaining bytes
      if (reader.hasRemaining) {
        reader.readRemainingBytes();
      }

      print('  ✅ [Advert] Parsed successfully');
    } catch (e) {
      print('  ❌ [Advert] Parsing error: $e');
      // Don't call onError - adverts are informational
    }
  }

  /// Handle LogRxData push
  void _handleLogRxData(BufferReader reader) {
    try {
      print('  [LogRxData] Parsing log rx data...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // This is encrypted/encoded data - just consume it
      final data = reader.readRemainingBytes();
      print('    Data length: ${data.length} bytes');
      print('  ✅ [LogRxData] Parsed successfully');
    } catch (e) {
      print('  ❌ [LogRxData] Parsing error: $e');
      // Don't call onError - logs are informational
    }
  }

  /// Handle NewAdvert push
  void _handleNewAdvert(BufferReader reader) {
    try {
      print('  [NewAdvert] Parsing new advertisement...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // NewAdvert format is identical to Contact response:
      // - 32 bytes: public key
      // - 1 byte: type
      // - 1 byte: flags
      // - 1 byte: outPathLen
      // - 64 bytes: outPath
      // - 32 bytes: advName (null-terminated string)
      // - 4 bytes: lastAdvert (uint32)
      // - 4 bytes: advLat (int32)
      // - 4 bytes: advLon (int32)
      // - 4 bytes: lastMod (uint32)

      final publicKey = reader.readBytes(32);
      print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final typeByte = reader.readByte();
      final type = ContactType.fromValue(typeByte);
      print('    Type byte: $typeByte → Type: $type');

      final flags = reader.readByte();
      print('    Flags: $flags (0x${flags.toRadixString(16).padLeft(2, '0')})');

      final outPathLen = reader.readInt8();
      print('    Out path length: $outPathLen');

      final outPath = reader.readBytes(64);
      print('    Out path: ${outPath.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...');

      final advName = reader.readCString(32);
      print('    Advertised name: "$advName"');

      final lastAdvert = reader.readUInt32LE();
      print('    Last advert timestamp: $lastAdvert');

      final advLat = reader.readInt32LE();
      print('    Latitude (raw int32): $advLat');
      print('    Latitude (decimal): ${advLat / 1000000.0}°');

      final advLon = reader.readInt32LE();
      print('    Longitude (raw int32): $advLon');
      print('    Longitude (decimal): ${advLon / 1000000.0}°');

      final lastMod = reader.readUInt32LE();
      print('    Last modified timestamp: $lastMod');

      final contact = Contact(
        publicKey: publicKey,
        type: type,
        flags: flags,
        outPathLen: outPathLen,
        outPath: outPath,
        advName: advName,
        lastAdvert: lastAdvert,
        advLat: advLat,
        advLon: advLon,
        lastMod: lastMod,
      );

      print('  ✅ [NewAdvert] Parsed successfully - new contact advertised on network');
      // Call the contact received callback to add/update the contact
      onContactReceived?.call(contact);
    } catch (e) {
      print('  ❌ [NewAdvert] Parsing error: $e');
      onError?.call('NewAdvert parsing error: $e');
    }
  }

  /// Handle SendConfirmed push (PUSH_CODE_SEND_CONFIRMED)
  ///
  /// Protocol format:
  /// - 4 bytes: ACK code
  /// - 4 bytes: round trip time (uint32, milliseconds)
  void _handleSendConfirmed(BufferReader reader) {
    try {
      print('  [SendConfirmed] Parsing send confirmed...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 8) {
        final ackCode = reader.readBytes(4);
        print('    ACK code: ${ackCode.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        final roundTripTime = reader.readUInt32LE();
        print('    Round trip time: ${roundTripTime}ms');

        print('  ✅ [SendConfirmed] Message delivery confirmed (RTT: ${roundTripTime}ms)');

        // TODO: Match ACK code with pending sends and notify UI
      } else {
        print('  ⚠️ [SendConfirmed] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [SendConfirmed] Parsing error: $e');
      // Don't call onError - confirmations are informational
    }
  }

  /// Handle MsgWaiting push (PUSH_CODE_MSG_WAITING)
  ///
  /// This push notification indicates that new messages are waiting
  /// in the device queue and should be fetched using syncNextMessage()
  void _handleMsgWaiting(BufferReader reader) {
    try {
      print('  [MsgWaiting] New message(s) waiting in queue');
      print('  ✅ [MsgWaiting] Notifying callback to fetch messages');
      onMessageWaiting?.call();
    } catch (e) {
      print('  ❌ [MsgWaiting] Parsing error: $e');
      // Don't call onError - this is informational
    }
  }

  /// Handle LoginSuccess push (PUSH_CODE_LOGIN_SUCCESS)
  ///
  /// Protocol format:
  /// - 1 byte: permissions (lowest bit = is_admin)
  /// - 6 bytes: public key prefix (first 6 bytes)
  /// - 4 bytes: tag (int32)
  /// - 1 byte: (V7+) new permissions
  void _handleLoginSuccess(BufferReader reader) {
    try {
      print('  [LoginSuccess] Parsing login success...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 11) {
        final permissions = reader.readByte();
        final isAdmin = (permissions & 0x01) != 0;
        print('    Permissions: $permissions (admin: $isAdmin)');

        final publicKeyPrefix = reader.readBytes(6);
        print('    Room public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

        final tag = reader.readInt32LE();
        print('    Tag: $tag');

        // V7+ new permissions byte
        int? newPermissions;
        if (reader.hasRemaining) {
          newPermissions = reader.readByte();
          print('    New permissions (V7+): $newPermissions');
        }

        print('  ✅ [LoginSuccess] Successfully logged into room');
        onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
      } else {
        print('  ⚠️ [LoginSuccess] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [LoginSuccess] Parsing error: $e');
      onError?.call('Login success parsing error: $e');
    }
  }

  /// Handle LoginFail push (PUSH_CODE_LOGIN_FAIL)
  ///
  /// Protocol format:
  /// - 1 byte: reserved (zero)
  /// - 6 bytes: public key prefix (first 6 bytes)
  void _handleLoginFail(BufferReader reader) {
    try {
      print('  [LoginFail] Parsing login fail...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 7) {
        final reserved = reader.readByte();
        print('    Reserved: $reserved');

        final publicKeyPrefix = reader.readBytes(6);
        print('    Room public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

        print('  ❌ [LoginFail] Failed to login to room (incorrect password or access denied)');
        onLoginFail?.call(publicKeyPrefix);
      } else {
        print('  ⚠️ [LoginFail] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [LoginFail] Parsing error: $e');
      onError?.call('Login fail parsing error: $e');
    }
  }

  /// Handle Error response (RESP_CODE_ERR)
  ///
  /// Protocol format:
  /// - 1 byte: error code (ERR_CODE_*)
  void _handleError(BufferReader reader) {
    try {
      print('  [Error] Parsing error response...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.hasRemaining) {
        final errorCode = reader.readByte();
        String errorMsg = 'Error code: $errorCode';

        switch (errorCode) {
          case MeshCoreConstants.errUnsupportedCmd:
            errorMsg = 'Unsupported command';
            break;
          case MeshCoreConstants.errNotFound:
            errorMsg = 'Not found';
            break;
          case MeshCoreConstants.errTableFull:
            errorMsg = 'Table full';
            break;
          case MeshCoreConstants.errBadState:
            errorMsg = 'Bad state';
            break;
          case MeshCoreConstants.errFileIoError:
            errorMsg = 'File I/O error';
            break;
          case MeshCoreConstants.errIllegalArg:
            errorMsg = 'Illegal argument';
            break;
        }

        print('  ❌ [Error] $errorMsg');
        onError?.call(errorMsg);
      }
    } catch (e) {
      print('  ❌ [Error] Parsing error: $e');
    }
  }

  /// Send AppStart command
  Future<void> _sendAppStart() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdAppStart);
    writer.writeByte(1); // appVer
    writer.writeBytes(Uint8List(6)); // reserved
    writer.writeString('MeshCore SAR'); // appName
    await _writeData(writer.toBytes());
  }

  /// Send DeviceQuery command
  Future<void> _sendDeviceQuery() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdDeviceQuery);
    writer.writeByte(MeshCoreConstants.supportedCompanionProtocolVersion);
    await _writeData(writer.toBytes());
    await _sendAppStart();
  }

  /// Refresh device info (public method)
  Future<void> refreshDeviceInfo() async {
    await _sendDeviceQuery();
  }

  /// Get contacts from device
  Future<void> getContacts() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetContacts);
    await _writeData(writer.toBytes());
  }

  /// Send text message to contact (DM)
  ///
  /// Protocol format (CMD_SEND_TXT_MSG):
  /// - 1 byte: command code (2)
  /// - 1 byte: text type (TXT_TYPE_*, 0=plain)
  /// - 1 byte: attempt (0-3, attempt number)
  /// - 4 bytes: sender timestamp (uint32, epoch seconds)
  /// - 6 bytes: recipient public key prefix (first 6 bytes)
  /// - N bytes: text (remainder of frame, varchar, max 160 bytes)
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
    int textType = 0, // TXT_TYPE_PLAIN
    int attempt = 0,
  }) async {
    if (text.length > 160) {
      throw ArgumentError('Text message exceeds 160 character limit');
    }

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTxtMsg); // 0x02
    writer.writeByte(textType); // TXT_TYPE_*
    writer.writeByte(attempt); // 0-3
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000); // epoch seconds
    writer.writeBytes(contactPublicKey.sublist(0, 6)); // first 6 bytes of public key
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Send flood-mode text message to channel
  ///
  /// Protocol format (CMD_SEND_CHANNEL_TXT_MSG):
  /// - 1 byte: command code (3)
  /// - 1 byte: text type (TXT_TYPE_*, 0=plain)
  /// - 1 byte: channel index (reserved, 0 for 'public')
  /// - 4 bytes: sender timestamp (uint32, epoch seconds)
  /// - N bytes: text (remainder of frame, max 160 - len(advert_name) - 2)
  ///
  /// Note: For SAR messages, ensure text starts with "S:<emoji>:<lat>,<lon>"
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
    int textType = 0, // TXT_TYPE_PLAIN
  }) async {
    // Note: Max length depends on advert name length, but typically ~140 chars
    if (text.length > 160) {
      throw ArgumentError('Channel message too long (max ~160 characters)');
    }

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendChannelTxtMsg); // 0x03
    writer.writeByte(textType); // TXT_TYPE_*
    writer.writeByte(channelIdx); // 0 for 'public' channel
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000); // epoch seconds
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Request telemetry from contact
  /// [zeroHop] - if true, only direct connection (no mesh forwarding)
  Future<void> requestTelemetry(Uint8List contactPublicKey, {bool zeroHop = false}) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTelemetryReq);
    writer.writeByte(zeroHop ? 0 : 255); // hop count: 0 = direct only, 255 = unlimited
    writer.writeByte(0); // reserved
    writer.writeByte(0); // reserved
    writer.writeBytes(contactPublicKey);
    await _writeData(writer.toBytes());
  }

  /// Get battery voltage
  Future<void> getBatteryVoltage() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetBatteryVoltage);
    await _writeData(writer.toBytes());
  }

  /// Sync next message from device queue
  /// Returns true if a message was retrieved, false if no more messages
  Future<void> syncNextMessage() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSyncNextMessage);
    await _writeData(writer.toBytes());
  }

  /// Set device time
  Future<void> setDeviceTime() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetDeviceTime);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await _writeData(writer.toBytes());
  }

  /// Send self advertisement packet to mesh network
  ///
  /// This broadcasts the device's current advertisement data (name, location, etc.)
  /// to the mesh network. The device uses its internally stored values from
  /// setAdvertName() and setAdvertLatLon().
  ///
  /// Protocol format (CMD_SEND_SELF_ADVERT):
  /// - 1 byte: command code (7)
  /// - 1 byte: type (0=zero-hop/local, 1=flood/mesh-wide)
  ///
  /// [floodMode] - if true, broadcast to entire mesh network (default)
  ///               if false, only send to direct neighbors (zero-hop)
  Future<void> sendSelfAdvert({bool floodMode = true}) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendSelfAdvert);
    writer.writeByte(floodMode ? MeshCoreConstants.selfAdvertFlood : MeshCoreConstants.selfAdvertZeroHop);
    await _writeData(writer.toBytes());
  }

  /// Set advertised name
  Future<void> setAdvertName(String name) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetAdvertName);
    writer.writeString(name);
    await _writeData(writer.toBytes());
  }

  /// Set advertised latitude and longitude
  Future<void> setAdvertLatLon({
    required double latitude,
    required double longitude,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetAdvertLatLon);
    writer.writeInt32LE((latitude * 1000000).round());
    writer.writeInt32LE((longitude * 1000000).round());
    await _writeData(writer.toBytes());
  }

  /// Set radio parameters
  Future<void> setRadioParams({
    required int frequency, // Hz
    required int bandwidth, // 0-9 (see bandwidth options)
    required int spreadingFactor, // 7-12
    required int codingRate, // 5-8
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetRadioParams);
    writer.writeUInt32LE(frequency);
    writer.writeUInt16LE(bandwidth);
    writer.writeByte(spreadingFactor);
    writer.writeByte(codingRate);
    await _writeData(writer.toBytes());
  }

  /// Set transmit power
  Future<void> setTxPower(int powerDbm) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetTxPower);
    writer.writeByte(powerDbm);
    await _writeData(writer.toBytes());
  }

  /// Set other parameters (telemetry modes, advert location policy, manual add contacts)
  ///
  /// Protocol format (CMD_SET_OTHER_PARAMS):
  /// - 1 byte: command code (38)
  /// - 1 byte: manual add contacts (0 or 1)
  /// - 1 byte: telemetry modes (bits 0-1: Base mode, bits 2-3: Location mode)
  ///           Modes: 0=DENY, 1=apply contact.flags, 2=ALLOW ALL
  /// - 1 byte: advert location policy (0=don't share, 1=share)
  /// - 1 byte: multi ACKs (0=no extra, 1=send extra ACK)
  Future<void> setOtherParams({
    required int manualAddContacts, // 0 or 1
    required int telemetryModes, // bits 0-1: Base, bits 2-3: Location
    required int advertLocationPolicy, // 0=don't share, 1=share
    int multiAcks = 0, // 0=no extra, 1=send extra
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetOtherParams);
    writer.writeByte(manualAddContacts);
    writer.writeByte(telemetryModes);
    writer.writeByte(advertLocationPolicy);
    writer.writeByte(multiAcks);
    await _writeData(writer.toBytes());
  }

  /// Send login request to room or repeater
  ///
  /// Protocol format (CMD_SEND_LOGIN):
  /// - 1 byte: command code (26)
  /// - 32 bytes: public key (room or repeater)
  /// - N bytes: password (remainder of frame, varchar, max 15 bytes)
  ///
  /// Response: PUSH_CODE_LOGIN_SUCCESS (0x85) or PUSH_CODE_LOGIN_FAIL (0x86)
  Future<void> loginToRoom({
    required Uint8List roomPublicKey,
    required String password,
  }) async {
    if (password.length > 15) {
      throw ArgumentError('Password exceeds 15 character limit');
    }

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendLogin);
    writer.writeBytes(roomPublicKey); // 32 bytes
    writer.writeString(password); // Max 15 bytes
    await _writeData(writer.toBytes());
  }

  /// Log a packet
  void _logPacket(Uint8List data, PacketDirection direction, {int? responseCode}) {
    // Add new packet
    _packetLogs.add(BlePacketLog(
      timestamp: DateTime.now(),
      rawData: data,
      direction: direction,
      responseCode: responseCode,
      description: _getPacketDescription(responseCode, direction),
    ));

    // Limit log size to prevent memory issues
    if (_packetLogs.length > _maxLogSize) {
      _packetLogs.removeAt(0);
    }
  }

  /// Get human-readable description of packet
  String? _getPacketDescription(int? code, PacketDirection direction) {
    if (direction == PacketDirection.tx) {
      // TX packets - command codes
      switch (code) {
        case MeshCoreConstants.cmdGetContacts:
          return 'Get Contacts';
        case MeshCoreConstants.cmdSendTxtMsg:
          return 'Send Text Message';
        case MeshCoreConstants.cmdSendChannelTxtMsg:
          return 'Send Channel Message';
        case MeshCoreConstants.cmdSendTelemetryReq:
          return 'Request Telemetry';
        case MeshCoreConstants.cmdDeviceQuery:
          return 'Device Query';
        case MeshCoreConstants.cmdAppStart:
          return 'App Start';
        default:
          return null;
      }
    } else {
      // RX packets - response codes
      switch (code) {
        case MeshCoreConstants.respContactsStart:
          return 'Contacts Start';
        case MeshCoreConstants.respContact:
          return 'Contact Info';
        case MeshCoreConstants.respEndOfContacts:
          return 'End of Contacts';
        case MeshCoreConstants.respSent:
          return 'Message Sent';
        case MeshCoreConstants.respContactMsgRecv:
          return 'Contact Message';
        case MeshCoreConstants.respChannelMsgRecv:
          return 'Channel Message';
        case MeshCoreConstants.pushTelemetryResponse:
          return 'Telemetry Data';
        case MeshCoreConstants.respDeviceInfo:
          return 'Device Info';
        case MeshCoreConstants.respSelfInfo:
          return 'Self Info';
        case MeshCoreConstants.pushAdvert:
          return 'Advertisement';
        case MeshCoreConstants.pushLogRxData:
          return 'Log RX Data';
        case MeshCoreConstants.pushNewAdvert:
          return 'New Advertisement';
        case MeshCoreConstants.respNoMoreMessages:
          return 'No More Messages';
        case MeshCoreConstants.respOk:
          return 'OK';
        case MeshCoreConstants.respErr:
          return 'ERROR';
        default:
          return null;
      }
    }
  }

  /// Clear packet logs
  void clearPacketLogs() {
    _packetLogs.clear();
  }

  /// Reset packet counters
  void resetCounters() {
    _rxPacketCount = 0;
    _txPacketCount = 0;
  }

  /// Dispose resources
  void dispose() {
    _txSubscription?.cancel();
    _pendingContacts.clear();
    _packetLogs.clear();
  }
}
