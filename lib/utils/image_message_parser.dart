import 'dart:typed_data';

const int _maxCompanionFrameBytes = 172; // MeshCore MAX_FRAME_SIZE
const int _cmdSendRawDataOverheadBytes = 2; // cmd + pathLen
const int _maxMeshPacketPayloadBytes = 184; // MeshCore MAX_PACKET_PAYLOAD
const int _meshPacketHeaderBytes = 2; // mesh header bytes before path/payload
const int _imagePacketHeaderBytes = 6; // image packet binary header in payload
const int _defaultLoRaSf = 10; // MeshCore companion defaults (SF10)
const int _defaultLoRaCr = 5; // MeshCore companion defaults (4/5)
const int _defaultLoRaBwHz = 250000; // MeshCore companion defaults (250kHz)
const int _defaultLoRaPreambleSymbols = 8;
const int _defaultLoRaCrcEnabled = 1;
const int _defaultLoRaExplicitHeader = 1;
const double _defaultAirtimeBudgetFactor = 1.0; // one half duty-cycle

/// Compressed image format used in the image packet protocol.
enum ImageFormat {
  avif(0, 'AVIF'),
  jpeg(1, 'JPEG');

  const ImageFormat(this.id, this.label);
  final int id;
  final String label;

  static ImageFormat fromId(int id) => ImageFormat.values.firstWhere(
    (f) => f.id == id,
    orElse: () => ImageFormat.avif,
  );
}

/// A single binary fragment of a compressed image.
///
/// Binary format (direct contacts, via pushRawData / cmdSendRawData):
///   [0x49 'I'][sessionId:4B][idx:1B][imageData...]
///
/// Legacy default is 152 data bytes per fragment.
class ImagePacket {
  final String sessionId; // 8 hex chars (4 bytes)
  final ImageFormat format;
  final int index; // 0-based
  final int total; // total fragment count (1..255)
  final Uint8List data;

  const ImagePacket({
    required this.sessionId,
    required this.format,
    required this.index,
    required this.total,
    required this.data,
  });

  static const int _magic = 0x49; // 'I'
  static const int _headerLen = 6; // magic(1)+session(4)+idx(1)
  static const int maxDataBytes =
      152; // Conservative default for compatibility.

  static bool isImageBinary(Uint8List payload) =>
      payload.isNotEmpty && payload[0] == _magic;

  static ImagePacket? tryParseBinary(Uint8List payload) {
    if (payload.length < _headerLen) return null;
    if (payload[0] != _magic) return null;
    try {
      final sessionId = payload
          .sublist(1, 5)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final index = payload[5];
      final data = payload.sublist(_headerLen);
      return ImagePacket(
        sessionId: sessionId,
        format: ImageFormat.avif,
        index: index,
        total: 0,
        data: data,
      );
    } catch (_) {
      return null;
    }
  }

  Uint8List encodeBinary() {
    final sessionBytes = Uint8List(4);
    for (var i = 0; i < 4; i++) {
      sessionBytes[i] = int.parse(
        sessionId.substring(i * 2, i * 2 + 2),
        radix: 16,
      );
    }
    final out = Uint8List(_headerLen + data.length);
    out[0] = _magic;
    out.setRange(1, 5, sessionBytes);
    out[5] = index;
    out.setRange(_headerLen, out.length, data);
    return out;
  }

  @override
  String toString() {
    final suffix = total > 0 ? ' ${format.label} [$index/${total - 1}]' : ' [$index]';
    return 'ImagePacket($sessionId$suffix ${data.length}B)';
  }
}

/// Compute the maximum safe image data bytes for a direct route path.
///
/// This accounts for:
/// - companion command-frame limit (MAX_FRAME_SIZE=172),
/// - cmdSendRawData overhead (`cmd` + `pathLen`),
/// - image packet binary header (8 bytes),
/// - mesh packet payload limit (MAX_PACKET_PAYLOAD=184).
///
/// Path length follows Contact.outPathLen semantics: 0 = direct, 1+ = hops.
int safeImageDataBytesForPath(int pathLen) {
  final normalizedPathLen = pathLen.clamp(0, 64).toInt();
  final maxRawPayloadFromCommandFrame =
      _maxCompanionFrameBytes -
      _cmdSendRawDataOverheadBytes -
      normalizedPathLen;
  final maxRawPayloadFromMesh =
      _maxMeshPacketPayloadBytes - ImagePacket._headerLen;
  final maxRawPayload = maxRawPayloadFromCommandFrame < maxRawPayloadFromMesh
      ? maxRawPayloadFromCommandFrame
      : maxRawPayloadFromMesh;
  final maxData = maxRawPayload - ImagePacket._headerLen;
  // Keep a safety margin below the theoretical direct-route ceiling.
  // Fragments at the absolute 172-byte command-frame limit have proven flaky
  // in practice, so cap to the conservative protocol default.
  return maxData.clamp(1, ImagePacket.maxDataBytes).toInt();
}

/// Approximate end-to-end transmit time for image fragments on MeshCore LoRa.
///
/// The estimate uses:
/// - LoRa airtime math with MeshCore companion defaults (SF10/BW250/CR5),
/// - MeshCore airtime budget pacing (default factor 1.0),
/// - hop multiplier (`pathLen + 1`) for direct routed packets.
Duration estimateImageTransmitDuration({
  required int fragmentCount,
  required int sizeBytes,
  int pathLen = 0,
  int? radioBw,
  int? radioSf,
  int? radioCr,
}) {
  if (fragmentCount <= 0 || sizeBytes <= 0) return Duration.zero;

  final safePathLen = pathLen.clamp(0, 64);
  final hops = safePathLen + 1;
  final baseDataPerFragment = sizeBytes ~/ fragmentCount;
  final extraBytes = sizeBytes % fragmentCount;
  var totalMs = 0.0;

  for (var i = 0; i < fragmentCount; i++) {
    final fragmentDataBytes = baseDataPerFragment + (i < extraBytes ? 1 : 0);
    final loraLen =
        _meshPacketHeaderBytes +
        safePathLen +
        _imagePacketHeaderBytes +
        fragmentDataBytes;
    final airtimeMs = _estimateLoRaAirtimeMs(
      loraLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    totalMs += airtimeMs * (1.0 + _defaultAirtimeBudgetFactor) * hops;
  }

  return Duration(milliseconds: totalMs.round());
}

double _estimateLoRaAirtimeMs(
  int payloadLenBytes, {
  int? radioBw,
  int? radioSf,
  int? radioCr,
}) {
  final sf = _normalizeSf(radioSf);
  final bw = _resolveBandwidthHz(radioBw).toDouble();
  final cr = (_normalizeCr(radioCr) - 4).clamp(1, 4);
  final ih = _defaultLoRaExplicitHeader == 1 ? 0 : 1;
  final de = (sf >= 11 && _defaultLoRaBwHz <= 125000) ? 1 : 0;

  final symbolMs = ((1 << sf) / bw) * 1000.0;
  final preambleMs = (_defaultLoRaPreambleSymbols + 4.25) * symbolMs;

  final num =
      (8 * payloadLenBytes) -
      (4 * sf) +
      28 +
      (16 * _defaultLoRaCrcEnabled) -
      (20 * ih);
  final den = 4 * (sf - (2 * de));
  final payloadSymCoeff = den <= 0 ? 0 : (num / den).ceil();
  final payloadSymbols =
      8 + (payloadSymCoeff < 0 ? 0 : payloadSymCoeff) * (cr + 4);
  final payloadMs = payloadSymbols * symbolMs;

  return preambleMs + payloadMs;
}

int _normalizeSf(int? value) {
  if (value == null) return _defaultLoRaSf;
  if (value >= 5 && value <= 12) return value;
  return _defaultLoRaSf;
}

int _normalizeCr(int? value) {
  if (value == null) return _defaultLoRaCr;
  if (value >= 5 && value <= 8) return value;
  return _defaultLoRaCr;
}

int _resolveBandwidthHz(int? rawBw) {
  if (rawBw == null) return _defaultLoRaBwHz;
  if (rawBw > 1000) return rawBw;
  switch (rawBw) {
    case 0:
      return 7800;
    case 1:
      return 10400;
    case 2:
      return 15600;
    case 3:
      return 20800;
    case 4:
      return 31250;
    case 5:
      return 41700;
    case 6:
      return 62500;
    case 7:
      return 125000;
    case 8:
      return 250000;
    case 9:
      return 500000;
    default:
      return _defaultLoRaBwHz;
  }
}

/// Envelope announcing image availability (control plane).
///
/// Text format:
///   IE4:{sid}:{fmt}:{total}:{w}:{h}:{bytes}
/// Example:
///   IE4:deadbeef:0:7:3k:3k:t6
class ImageEnvelope {
  static const String _prefixV4 = 'IE4:';

  final String sessionId; // 8 hex chars
  final ImageFormat format;
  final int total; // total fragment count
  final int width;
  final int height;
  final int sizeBytes; // total compressed image size
  final int version;

  const ImageEnvelope({
    required this.sessionId,
    required this.format,
    required this.total,
    required this.width,
    required this.height,
    required this.sizeBytes,
    this.version = 4,
  });

  static bool isEnvelope(String text) => text.startsWith(_prefixV4);

  static ImageEnvelope? tryParse(String text) {
    if (!isEnvelope(text)) return null;
    final body = text.substring(_prefixV4.length);
    final parts = body.split(':');
    if (parts.length != 6) return null;
    try {
      final sid = _decodeSessionId(parts[0]);
      final fmtId = _parseInt(parts[1], base36: true);
      final total = _parseInt(parts[2], base36: true);
      final w = _parseInt(parts[3], base36: true);
      final h = _parseInt(parts[4], base36: true);
      final bytes = _parseInt(parts[5], base36: true);

      if (sid == null) return null;
      if (fmtId == null) return null;
      if (total == null || total < 1 || total > 255) return null;
      if (w == null || h == null || w < 1 || h < 1) return null;
      if (bytes == null || bytes < 1) return null;

      return ImageEnvelope(
        sessionId: sid,
        format: ImageFormat.fromId(fmtId),
        total: total,
        width: w,
        height: h,
        sizeBytes: bytes,
        version: 4,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() =>
      '$_prefixV4${_encodeSessionId(sessionId)}:'
      '${_toBase36(format.id)}:${_toBase36(total)}:${_toBase36(width)}:'
      '${_toBase36(height)}:${_toBase36(sizeBytes)}';
}

/// Direct request to fetch image fragments (control plane).
///
/// Text format:
///   IR4:{sid}:{want}:{requesterKey6}
/// Example:
///   IR4:deadbeef:a:aabbccddeeff
class ImageFetchRequest {
  static const String _prefixV4 = 'IR4:';
  static const int _binaryMagic = 0x69; // 'i'

  final String sessionId;
  final String want; // 'all' or 'missing'
  final List<int> missingIndices;
  final String requesterKey6; // 12 hex chars
  final int version;

  const ImageFetchRequest({
    required this.sessionId,
    this.want = 'all',
    this.missingIndices = const [],
    required this.requesterKey6,
    this.version = 4,
  });

  static bool isRequest(String text) => text.startsWith(_prefixV4);
  static bool isRequestBinary(Uint8List payload) =>
      payload.isNotEmpty && payload[0] == _binaryMagic;

  static ImageFetchRequest? tryParse(String text) {
    if (!isRequest(text)) return null;
    final body = text.substring(_prefixV4.length);
    final parts = body.split(':');
    if (parts.length != 3) return null;
    try {
      final sid = _decodeSessionId(parts[0]);
      final wantToken = parts[1];
      final requesterKey6 = parts[2];
      final normalizedWant = wantToken == 'a'
          ? 'all'
          : ((wantToken.startsWith('m')) ? 'missing' : wantToken);

      if (sid == null) return null;
      final missingIndices = <int>[];
      if (normalizedWant == 'missing') {
        final encoded = wantToken.substring(1);
        if (encoded.isEmpty) return null;
        missingIndices.addAll(_decodeMissingIndicesCompact(encoded));
        if (missingIndices.isEmpty) return null;
      } else if (normalizedWant != 'all') {
        return null;
      }
      if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(requesterKey6)) return null;

      return ImageFetchRequest(
        sessionId: sid,
        want: normalizedWant,
        missingIndices: missingIndices,
        requesterKey6: requesterKey6.toLowerCase(),
        version: 4,
      );
    } catch (_) {
      return null;
    }
  }

  static ImageFetchRequest? tryParseBinary(Uint8List payload) {
    if (!isRequestBinary(payload)) return null;
    if (payload.length < 13) return null; // magic+sid+flags+key6+count
    try {
      final sid = payload
          .sublist(1, 5)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();
      final flags = payload[5];
      final requesterKey6 = payload
          .sublist(6, 12)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();
      final missingCount = payload[12];
      if (payload.length != 13 + missingCount) return null;
      final wantMissing = (flags & 0x01) == 0x01;
      final missing = <int>[];
      for (var i = 0; i < missingCount; i++) {
        missing.add(payload[13 + i]);
      }
      return ImageFetchRequest(
        sessionId: sid,
        want: wantMissing ? 'missing' : 'all',
        missingIndices: missing,
        requesterKey6: requesterKey6,
        version: 4,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() {
    final wantToken = want == 'missing' && missingIndices.isNotEmpty
        ? 'm${_encodeMissingIndicesCompact(missingIndices)}'
        : (want == 'all' ? 'a' : want);
    return '$_prefixV4${_encodeSessionId(sessionId)}:$wantToken:${requesterKey6.toLowerCase()}';
  }

  Uint8List encodeBinary() {
    if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(sessionId)) {
      throw ArgumentError.value(sessionId, 'sessionId', 'Expected 8 hex chars');
    }
    if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(requesterKey6)) {
      throw ArgumentError.value(
        requesterKey6,
        'requesterKey6',
        'Expected 12 hex chars',
      );
    }
    final useMissing = want == 'missing' && missingIndices.isNotEmpty;
    final missing = useMissing
        ? missingIndices.where((v) => v >= 0 && v <= 254).toList()
        : <int>[];

    final out = Uint8List(13 + missing.length);
    out[0] = _binaryMagic;
    for (var i = 0; i < 4; i++) {
      out[1 + i] = int.parse(sessionId.substring(i * 2, i * 2 + 2), radix: 16);
    }
    out[5] = useMissing ? 0x01 : 0x00;
    for (var i = 0; i < 6; i++) {
      out[6 + i] = int.parse(
        requesterKey6.substring(i * 2, i * 2 + 2),
        radix: 16,
      );
    }
    out[12] = missing.length;
    for (var i = 0; i < missing.length; i++) {
      out[13 + i] = missing[i];
    }
    return out;
  }
}

/// Per-fragment ACK for raw image payload packets.
///
/// Binary format:
///   [0x6a 'j'][sessionId:4B][index:1B]
class ImageFragmentAck {
  static const int _binaryMagic = 0x6a; // 'j'

  final String sessionId; // 8 hex chars
  final int index; // 0..254

  const ImageFragmentAck({required this.sessionId, required this.index});

  static bool isImageFragmentAckBinary(Uint8List payload) =>
      payload.length == 6 && payload[0] == _binaryMagic;

  static ImageFragmentAck? tryParseBinary(Uint8List payload) {
    if (!isImageFragmentAckBinary(payload)) return null;
    try {
      final sid = payload
          .sublist(1, 5)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();
      final idx = payload[5];
      return ImageFragmentAck(sessionId: sid, index: idx);
    } catch (_) {
      return null;
    }
  }

  Uint8List encodeBinary() {
    if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(sessionId)) {
      throw ArgumentError.value(sessionId, 'sessionId', 'Expected 8 hex chars');
    }
    if (index < 0 || index > 254) {
      throw ArgumentError.value(index, 'index', 'Expected 0..254');
    }
    final out = Uint8List(6);
    out[0] = _binaryMagic;
    for (var i = 0; i < 4; i++) {
      out[1 + i] = int.parse(sessionId.substring(i * 2, i * 2 + 2), radix: 16);
    }
    out[5] = index;
    return out;
  }
}

int? _parseInt(String token, {required bool base36}) =>
    int.tryParse(token, radix: base36 ? 36 : 10);

String _toBase36(int value) => value.toRadixString(36);

String _encodeSessionId(String sessionIdHex) {
  if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(sessionIdHex)) {
    throw ArgumentError.value(
      sessionIdHex,
      'sessionIdHex',
      'Expected 8 hex chars',
    );
  }
  final value = int.parse(sessionIdHex, radix: 16);
  return value.toRadixString(36);
}

String? _decodeSessionId(String token) {
  if (!RegExp(r'^[0-9a-z]{1,7}$').hasMatch(token)) return null;
  final value = int.tryParse(token, radix: 36);
  if (value == null || value < 0 || value > 0xFFFFFFFF) return null;
  return value.toRadixString(16).padLeft(8, '0');
}

String _encodeMissingIndicesCompact(List<int> indices) {
  final sorted = indices.where((v) => v >= 0 && v <= 254).toSet().toList()
    ..sort();
  if (sorted.isEmpty) return '';
  final chunks = <String>[];
  var start = sorted.first;
  var prev = sorted.first;
  for (var i = 1; i < sorted.length; i++) {
    final curr = sorted[i];
    if (curr == prev + 1) {
      prev = curr;
      continue;
    }
    chunks.add(
      start == prev
          ? _toBase36(start)
          : '${_toBase36(start)}-${_toBase36(prev)}',
    );
    start = curr;
    prev = curr;
  }
  chunks.add(
    start == prev ? _toBase36(start) : '${_toBase36(start)}-${_toBase36(prev)}',
  );
  return chunks.join('.');
}

List<int> _decodeMissingIndicesCompact(String encoded) {
  final out = <int>[];
  for (final token in encoded.split('.')) {
    if (token.isEmpty) continue;
    if (!token.contains('-')) {
      final value = int.tryParse(token, radix: 36);
      if (value == null || value < 0 || value > 254) return const [];
      out.add(value);
      continue;
    }
    final parts = token.split('-');
    if (parts.length != 2) return const [];
    final start = int.tryParse(parts[0], radix: 36);
    final end = int.tryParse(parts[1], radix: 36);
    if (start == null || end == null || start < 0 || end > 254 || start > end) {
      return const [];
    }
    for (var i = start; i <= end; i++) {
      out.add(i);
    }
  }
  return out;
}

/// Fragment the compressed image bytes into [ImagePacket] list.
///
/// [sessionId] must be 8 lowercase hex chars.
/// [format] is the image format used.
/// Returns at most 255 packets; excess bytes are silently dropped.
List<ImagePacket> fragmentImage({
  required String sessionId,
  required ImageFormat format,
  required Uint8List bytes,
  int maxDataBytes = ImagePacket.maxDataBytes,
}) {
  final chunkSize = maxDataBytes.clamp(1, 255).toInt();
  final chunks = <Uint8List>[];
  for (var offset = 0; offset < bytes.length; offset += chunkSize) {
    final end = (offset + chunkSize).clamp(0, bytes.length);
    chunks.add(bytes.sublist(offset, end));
    if (chunks.length == 255) break; // protocol limit
  }
  final total = chunks.length;
  return [
    for (var i = 0; i < total; i++)
      ImagePacket(
        sessionId: sessionId,
        format: format,
        index: i,
        total: total,
        data: chunks[i],
      ),
  ];
}

/// Reassemble image bytes from received [packets].
///
/// Returns null if any fragment is missing.
Uint8List? reassembleImage(List<ImagePacket?> packets) {
  if (packets.isEmpty) return null;
  if (packets.any((p) => p == null)) return null;
  final merged = <int>[];
  for (final p in packets) {
    merged.addAll(p!.data);
  }
  return Uint8List.fromList(merged);
}
