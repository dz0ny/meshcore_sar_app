import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/contact.dart';
import '../models/contact_telemetry.dart';
import '../models/message.dart';
import 'buffer_reader.dart';
import 'buffer_writer.dart';
import 'meshcore_constants.dart';

/// Callback types for MeshCore events
typedef OnContactCallback = void Function(Contact contact);
typedef OnContactsCompleteCallback = void Function(List<Contact> contacts);
typedef OnMessageCallback = void Function(Message message);
typedef OnTelemetryCallback = void Function(Uint8List publicKey, Uint8List lppData);
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
  OnErrorCallback? onError;

  // Internal state
  final List<Contact> _pendingContacts = [];
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Scan for MeshCore devices
  Stream<BluetoothDevice> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(MeshCoreConstants.bleServiceUuid)],
      );

      // Listen to scan results
      await for (final scanResult in FlutterBluePlus.scanResults) {
        for (final result in scanResult) {
          if (result.advertisementData.serviceUuids
              .contains(Guid(MeshCoreConstants.bleServiceUuid))) {
            yield result.device;
          }
        }
      }
    } catch (e) {
      onError?.call('Scan error: $e');
    }
  }

  /// Connect to a MeshCore device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _device = device;

      // Connect to device
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
      );

      // Discover services
      final services = await device.discoverServices();

      // Find MeshCore service
      BluetoothService? meshCoreService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            MeshCoreConstants.bleServiceUuid.toLowerCase()) {
          meshCoreService = service;
          break;
        }
      }

      if (meshCoreService == null) {
        throw Exception('MeshCore service not found');
      }

      // Find RX and TX characteristics
      for (final characteristic in meshCoreService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        if (uuid == MeshCoreConstants.bleCharacteristicRxUuid.toLowerCase()) {
          _rxCharacteristic = characteristic;
        } else if (uuid ==
            MeshCoreConstants.bleCharacteristicTxUuid.toLowerCase()) {
          _txCharacteristic = characteristic;
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        throw Exception('Required characteristics not found');
      }

      // Enable notifications on TX characteristic
      await _txCharacteristic!.setNotifyValue(true);

      // Listen to TX characteristic
      _txSubscription = _txCharacteristic!.lastValueStream.listen(
        _onDataReceived,
        onError: (error) => onError?.call('TX notification error: $error'),
      );

      _isConnected = true;
      onConnectionStateChanged?.call(true);

      // Send initial device query
      await _sendDeviceQuery();

      return true;
    } catch (e) {
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
      await _rxCharacteristic!.write(data, withoutResponse: true);
    } catch (e) {
      onError?.call('Write error: $e');
      rethrow;
    }
  }

  /// Handle incoming data from TX characteristic
  void _onDataReceived(List<int> data) {
    try {
      final reader = BufferReader(Uint8List.fromList(data));
      final responseCode = reader.readByte();

      switch (responseCode) {
        case MeshCoreConstants.respContactsStart:
          _handleContactsStart(reader);
          break;
        case MeshCoreConstants.respContact:
          _handleContact(reader);
          break;
        case MeshCoreConstants.respEndOfContacts:
          _handleEndOfContacts(reader);
          break;
        case MeshCoreConstants.respContactMsgRecv:
          _handleContactMessage(reader);
          break;
        case MeshCoreConstants.respChannelMsgRecv:
          _handleChannelMessage(reader);
          break;
        case MeshCoreConstants.pushTelemetryResponse:
          _handleTelemetryResponse(reader);
          break;
        case MeshCoreConstants.respOk:
        case MeshCoreConstants.respErr:
          // Handle OK/Error responses if needed
          break;
        default:
          // Unknown response code
          break;
      }
    } catch (e) {
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
      final publicKey = reader.readBytes(32);
      final type = ContactType.fromValue(reader.readByte());
      final flags = reader.readByte();
      final outPathLen = reader.readInt8();
      final outPath = reader.readBytes(64);
      final advName = reader.readCString(32);
      final lastAdvert = reader.readUInt32LE();
      final advLat = reader.readInt32LE();
      final advLon = reader.readInt32LE();
      final lastMod = reader.readUInt32LE();

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

      _pendingContacts.add(contact);
      onContactReceived?.call(contact);
    } catch (e) {
      onError?.call('Contact parsing error: $e');
    }
  }

  /// Handle EndOfContacts response
  void _handleEndOfContacts(BufferReader reader) {
    onContactsComplete?.call(List.from(_pendingContacts));
    _pendingContacts.clear();
  }

  /// Handle ContactMsgRecv response
  void _handleContactMessage(BufferReader reader) {
    try {
      final pubKeyPrefix = reader.readBytes(6);
      final pathLen = reader.readByte();
      final txtType = MessageTextType.fromValue(reader.readByte());
      final senderTimestamp = reader.readUInt32LE();
      final text = reader.readString();

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

      onMessageReceived?.call(message);
    } catch (e) {
      onError?.call('Contact message parsing error: $e');
    }
  }

  /// Handle ChannelMsgRecv response
  void _handleChannelMessage(BufferReader reader) {
    try {
      final channelIdx = reader.readInt8();
      final pathLen = reader.readByte();
      final txtType = MessageTextType.fromValue(reader.readByte());
      final senderTimestamp = reader.readUInt32LE();
      final text = reader.readString();

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

      onMessageReceived?.call(message);
    } catch (e) {
      onError?.call('Channel message parsing error: $e');
    }
  }

  /// Handle TelemetryResponse push
  void _handleTelemetryResponse(BufferReader reader) {
    try {
      reader.readByte(); // reserved
      final pubKeyPrefix = reader.readBytes(6);
      final lppSensorData = reader.readRemainingBytes();

      onTelemetryReceived?.call(pubKeyPrefix, lppSensorData);
    } catch (e) {
      onError?.call('Telemetry parsing error: $e');
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

  /// Get contacts from device
  Future<void> getContacts() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetContacts);
    await _writeData(writer.toBytes());
  }

  /// Send text message to contact
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTxtMsg);
    writer.writeByte(MeshCoreConstants.txtTypePlain);
    writer.writeByte(0); // attempt
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeBytes(contactPublicKey.sublist(0, 6));
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Send channel text message
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendChannelTxtMsg);
    writer.writeByte(MeshCoreConstants.txtTypePlain);
    writer.writeByte(channelIdx);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Request telemetry from contact
  Future<void> requestTelemetry(Uint8List contactPublicKey) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTelemetryReq);
    writer.writeByte(0); // reserved
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

  /// Set device time
  Future<void> setDeviceTime() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetDeviceTime);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await _writeData(writer.toBytes());
  }

  /// Send flood advertisement with current location
  Future<void> sendFloodAdvertisement({
    required double latitude,
    required double longitude,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendSelfAdvert);
    writer.writeByte(MeshCoreConstants.selfAdvertFlood);
    writer.writeInt32LE((latitude * 10000).round());
    writer.writeInt32LE((longitude * 10000).round());
    await _writeData(writer.toBytes());
  }

  /// Dispose resources
  void dispose() {
    _txSubscription?.cancel();
    _pendingContacts.clear();
  }
}
