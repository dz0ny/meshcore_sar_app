import 'dart:convert';
import 'dart:typed_data';
import '../../models/contact.dart';
import '../buffer_writer.dart';
import '../meshcore_constants.dart';

/// Builds outgoing BLE frames for the MeshCore device
class FrameBuilder {
  /// Build DeviceQuery command
  static Uint8List buildDeviceQuery() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdDeviceQuery);
    writer.writeByte(MeshCoreConstants.supportedCompanionProtocolVersion);
    return writer.toBytes();
  }

  /// Build AppStart command
  static Uint8List buildAppStart() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdAppStart);
    writer.writeByte(1); // appVer
    writer.writeBytes(Uint8List(6)); // reserved
    writer.writeString('MeshCore SAR'); // appName
    return writer.toBytes();
  }

  /// Build GetContacts command
  static Uint8List buildGetContacts() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetContacts);
    return writer.toBytes();
  }

  /// Build GetContactByKey command - retrieves a single contact by public key
  static Uint8List buildGetContactByKey(Uint8List publicKey) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetContactByKey); // 0x1E (30)
    writer.writeBytes(publicKey); // 32 bytes
    return writer.toBytes();
  }

  /// Build AddUpdateContact command
  static Uint8List buildAddUpdateContact(Contact contact) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdAddUpdateContact); // 0x09
    writer.writeBytes(contact.publicKey); // 32 bytes
    writer.writeByte(contact.type.value); // ADV_TYPE_*
    writer.writeByte(contact.flags); // flags
    writer.writeInt8(contact.outPathLen); // path length (signed byte)
    writer.writeBytes(contact.outPath); // 64 bytes

    // Write name as null-terminated string in 32-byte field
    final nameBytes = Uint8List(32);
    final encoded = utf8.encode(contact.advName);
    final copyLen = encoded.length > 31 ? 31 : encoded.length;
    nameBytes.setRange(0, copyLen, encoded);
    writer.writeBytes(nameBytes);

    writer.writeUInt32LE(contact.lastAdvert); // timestamp
    writer.writeInt32LE(contact.advLat); // latitude * 1E6
    writer.writeInt32LE(contact.advLon); // longitude * 1E6

    return writer.toBytes();
  }

  /// Build SendTxtMsg command
  static Uint8List buildSendTxtMsg({
    required Uint8List contactPublicKey,
    required String text,
    int textType = 0,
    int attempt = 0,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTxtMsg); // 0x02
    writer.writeByte(textType); // TXT_TYPE_*
    writer.writeByte(attempt); // 0-3
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeBytes(contactPublicKey.sublist(0, 6));
    writer.writeString(text);
    return writer.toBytes();
  }

  /// Build SendChannelTxtMsg command
  static Uint8List buildSendChannelTxtMsg({
    required int channelIdx,
    required String text,
    int textType = 0,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendChannelTxtMsg); // 0x03
    writer.writeByte(textType); // TXT_TYPE_*
    writer.writeByte(channelIdx); // 0 for 'public' channel
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeString(text);
    return writer.toBytes();
  }

  /// Build SendTelemetryReq command (deprecated)
  @Deprecated('Use buildSendBinaryReq() instead')
  static Uint8List buildSendTelemetryReq(Uint8List contactPublicKey, {bool zeroHop = false}) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTelemetryReq);
    writer.writeByte(zeroHop ? 0 : 255);
    writer.writeByte(0); // reserved
    writer.writeByte(0); // reserved
    writer.writeBytes(contactPublicKey);
    return writer.toBytes();
  }

  /// Build SendBinaryReq command
  static Uint8List buildSendBinaryReq({
    required Uint8List contactPublicKey,
    required Uint8List requestData,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendBinaryReq); // 0x32 (50)
    writer.writeBytes(contactPublicKey); // 32 bytes
    writer.writeBytes(requestData); // request code + params
    return writer.toBytes();
  }

  /// Build GetBatteryVoltage command
  static Uint8List buildGetBatteryAndStorage() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetBatteryVoltage);
    return writer.toBytes();
  }

  /// Build SyncNextMessage command
  static Uint8List buildSyncNextMessage() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSyncNextMessage);
    return writer.toBytes();
  }

  /// Build GetDeviceTime command
  static Uint8List buildGetDeviceTime() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetDeviceTime);
    return writer.toBytes();
  }

  /// Build SetDeviceTime command
  static Uint8List buildSetDeviceTime() {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetDeviceTime);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return writer.toBytes();
  }

  /// Build SendSelfAdvert command
  static Uint8List buildSendSelfAdvert({bool floodMode = true}) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendSelfAdvert);
    writer.writeByte(floodMode ? MeshCoreConstants.selfAdvertFlood : MeshCoreConstants.selfAdvertZeroHop);
    return writer.toBytes();
  }

  /// Build SetAdvertName command
  static Uint8List buildSetAdvertName(String name) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetAdvertName);
    writer.writeString(name);
    return writer.toBytes();
  }

  /// Build SetAdvertLatLon command
  static Uint8List buildSetAdvertLatLon({
    required double latitude,
    required double longitude,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetAdvertLatLon);
    writer.writeInt32LE((latitude * 1000000).round());
    writer.writeInt32LE((longitude * 1000000).round());
    return writer.toBytes();
  }

  /// Build SetRadioParams command
  static Uint8List buildSetRadioParams({
    required int frequency,
    required int bandwidth,
    required int spreadingFactor,
    required int codingRate,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetRadioParams);
    writer.writeUInt32LE(frequency);
    writer.writeUInt16LE(bandwidth);
    writer.writeByte(spreadingFactor);
    writer.writeByte(codingRate);
    return writer.toBytes();
  }

  /// Build SetTxPower command
  static Uint8List buildSetTxPower(int powerDbm) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetTxPower);
    writer.writeByte(powerDbm);
    return writer.toBytes();
  }

  /// Build SetOtherParams command
  static Uint8List buildSetOtherParams({
    required int manualAddContacts,
    required int telemetryModes,
    required int advertLocationPolicy,
    int multiAcks = 0,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetOtherParams);
    writer.writeByte(manualAddContacts);
    writer.writeByte(telemetryModes);
    writer.writeByte(advertLocationPolicy);
    writer.writeByte(multiAcks);
    return writer.toBytes();
  }

  /// Build SendLogin command
  static Uint8List buildSendLogin({
    required Uint8List roomPublicKey,
    required String password,
  }) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendLogin); // 0x1A
    writer.writeBytes(roomPublicKey); // 32 bytes
    writer.writeString(password); // Max 15 bytes, null-terminated
    return writer.toBytes();
  }

  /// Build SendStatusReq command
  static Uint8List buildSendStatusReq(Uint8List contactPublicKey) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendStatusReq); // 0x1B
    writer.writeBytes(contactPublicKey); // 32 bytes
    return writer.toBytes();
  }

  /// Build ResetPath command - clears learned path for a contact
  static Uint8List buildResetPath(Uint8List contactPublicKey) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdResetPath); // 0x0D (13)
    writer.writeBytes(contactPublicKey); // 32 bytes
    return writer.toBytes();
  }

  /// Build RemoveContact command - removes a contact from the device
  static Uint8List buildRemoveContact(Uint8List contactPublicKey) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdRemoveContact); // 0x0F (15)
    writer.writeBytes(contactPublicKey); // 32 bytes
    return writer.toBytes();
  }

  /// Build GetChannel command - retrieves information for a specific channel
  static Uint8List buildGetChannel(int channelIdx) {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetChannel); // 0x1F (31)
    writer.writeByte(channelIdx); // 0-39 typically
    return writer.toBytes();
  }

  /// Build SetChannel command - sets the name and secret for a specific channel
  ///
  /// Format: [cmd(1)][channel_idx(1)][name(32)][secret(16)]
  /// Secret must be exactly 16 bytes (128-bit key)
  static Uint8List buildSetChannel({
    required int channelIdx,
    required String channelName,
    required List<int> secret,
  }) {
    if (secret.length != 16) {
      throw ArgumentError('Channel secret must be exactly 16 bytes (got ${secret.length})');
    }

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetChannel); // 0x20 (32)
    writer.writeByte(channelIdx); // 0-39 typically

    // Write channel name as null-terminated string in 32-byte field
    final nameBytes = Uint8List(32);
    final encoded = utf8.encode(channelName);
    final copyLen = encoded.length > 31 ? 31 : encoded.length;
    nameBytes.setRange(0, copyLen, encoded);
    writer.writeBytes(nameBytes);

    // Write 16-byte secret
    writer.writeBytes(Uint8List.fromList(secret));

    return writer.toBytes();
  }
}
