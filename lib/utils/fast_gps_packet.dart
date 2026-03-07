import 'dart:typed_data';

class FastGpsPacket {
  static const int magic = 0x47; // 'G'
  static const int _payloadLength = 19;
  // Store coordinates in microdegrees. This preserves sub-meter precision,
  // which comfortably satisfies the meter-accuracy requirement.
  static const double coordinateScale = 1e6;

  final String senderKey6;
  final double latitude;
  final double longitude;
  final int timestampSeconds;

  const FastGpsPacket({
    required this.senderKey6,
    required this.latitude,
    required this.longitude,
    required this.timestampSeconds,
  });

  static bool isFastGpsBinary(Uint8List payload) =>
      payload.length == _payloadLength && payload[0] == magic;

  static FastGpsPacket? tryParseBinary(Uint8List payload) {
    if (!isFastGpsBinary(payload)) return null;

    final key6 = payload
        .sublist(1, 7)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final data = ByteData.sublistView(payload);
    final latitude = data.getInt32(7, Endian.little) / coordinateScale;
    final longitude = data.getInt32(11, Endian.little) / coordinateScale;
    final timestampSeconds = data.getUint32(15, Endian.little);

    if (!_isValidCoordinate(latitude, longitude)) {
      return null;
    }

    return FastGpsPacket(
      senderKey6: key6,
      latitude: latitude,
      longitude: longitude,
      timestampSeconds: timestampSeconds,
    );
  }

  Uint8List encodeBinary() {
    final out = Uint8List(_payloadLength);
    final data = ByteData.sublistView(out);
    out[0] = magic;
    for (var i = 0; i < 6; i++) {
      out[1 + i] = int.parse(senderKey6.substring(i * 2, i * 2 + 2), radix: 16);
    }
    data.setInt32(7, (latitude * coordinateScale).round(), Endian.little);
    data.setInt32(11, (longitude * coordinateScale).round(), Endian.little);
    data.setUint32(15, timestampSeconds, Endian.little);
    return out;
  }

  static bool _isValidCoordinate(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    return latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }
}
