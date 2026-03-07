import 'dart:convert';
import 'dart:typed_data';

const int _meshPacketHeaderBytes = 2; // mesh header bytes before path/payload
const int _voicePacketHeaderBytes = 6; // voice packet binary header in payload
const int _defaultLoRaSf = 10; // MeshCore companion defaults (SF10)
const int _defaultLoRaCr = 5; // MeshCore companion defaults (4/5)
const int _defaultLoRaBwHz = 250000; // MeshCore companion defaults (250kHz)
const int _defaultLoRaPreambleSymbols = 8;
const int _defaultLoRaCrcEnabled = 1;
const int _defaultLoRaExplicitHeader = 1;
const double _defaultAirtimeBudgetFactor = 1.0; // one half duty-cycle

/// Identifies which Codec2 mode was used for a voice packet.
/// Matches the modeId byte in the text/binary packet header.
enum VoicePacketMode {
  mode700c(0, '700C'),
  mode1200(1, '1200'),
  mode2400(2, '2400'),
  mode1300(3, '1300'),
  mode1400(4, '1400'),
  mode1600(5, '1600'),
  mode3200(6, '3200');

  const VoicePacketMode(this.id, this.label);
  final int id;
  final String label;

  static VoicePacketMode fromId(int id) => VoicePacketMode.values.firstWhere(
    (m) => m.id == id,
    orElse: () => VoicePacketMode.mode1300,
  );
}

/// A single Codec2-encoded chunk belonging to a multi-packet voice session.
///
/// Text format (channels):
///   V:{sessionId8hex}:{modeId}:{index}/{total}:{base64Codec2}
///
/// Binary format (direct contacts, received via pushRawData):
///   [0x56 'V'][sessionId:4B][index:1B][codec2Data...]
class VoicePacket {
  final String sessionId; // 8 hex chars (4 bytes)
  final VoicePacketMode mode;
  final int index; // 0-based
  final int total; // total packet count
  final Uint8List codec2Data;

  const VoicePacket({
    required this.sessionId,
    required this.mode,
    required this.index,
    required this.total,
    required this.codec2Data,
  });

  // ── Text (channel) format ────────────────────────────────────────────────

  static const String _textPrefix = 'V:';

  static bool isVoiceText(String text) => text.startsWith(_textPrefix);

  /// Parse a text-format voice packet.  Returns null on failure.
  static VoicePacket? tryParseText(String text) {
    if (!text.startsWith(_textPrefix)) return null;
    try {
      final body = text.substring(_textPrefix.length);
      final parts = body.split(':');
      // parts: [sessionId, modeId, 'idx/total', base64data]
      if (parts.length != 4) return null;

      final sessionId = parts[0];
      if (sessionId.length != 8) return null;

      final modeId = int.tryParse(parts[1]);
      if (modeId == null) return null;

      final indexTotal = parts[2].split('/');
      if (indexTotal.length != 2) return null;
      final index = int.tryParse(indexTotal[0]);
      final total = int.tryParse(indexTotal[1]);
      if (index == null || total == null || total < 1) return null;

      final codec2Data = base64.decode(parts[3]);

      return VoicePacket(
        sessionId: sessionId,
        mode: VoicePacketMode.fromId(modeId),
        index: index,
        total: total,
        codec2Data: codec2Data,
      );
    } catch (_) {
      return null;
    }
  }

  /// Encode as text (channel format).  Max ~198 chars for 700C/1200/2400.
  String encodeText() {
    final b64 = base64.encode(codec2Data);
    return 'V:$sessionId:${mode.id}:$index/$total:$b64';
  }

  // ── Binary format ────────────────────────────────────────────────────────

  static const int _binaryMagic = 0x56; // 'V'
  static const int _binaryHeaderLen = 6; // magic(1)+session(4)+idx(1)

  static bool isVoiceBinary(Uint8List payload) =>
      payload.isNotEmpty && payload[0] == _binaryMagic;

  /// Parse binary-format voice packet (from pushRawData payload).
  static VoicePacket? tryParseBinary(Uint8List payload) {
    if (payload.length < _binaryHeaderLen) return null;
    if (payload[0] != _binaryMagic) return null;
    try {
      final sessionBytes = payload.sublist(1, 5);
      final sessionId = sessionBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final index = payload[5];
      final codec2Data = payload.sublist(_binaryHeaderLen);
      return VoicePacket(
        sessionId: sessionId,
        mode: VoicePacketMode.mode1300,
        index: index,
        total: 0,
        codec2Data: codec2Data,
      );
    } catch (_) {
      return null;
    }
  }

  /// Encode as binary payload (for cmdSendRawData).
  Uint8List encodeBinary() {
    final sessionBytes = Uint8List(4);
    for (var i = 0; i < 4; i++) {
      sessionBytes[i] = int.parse(
        sessionId.substring(i * 2, i * 2 + 2),
        radix: 16,
      );
    }
    final out = Uint8List(_binaryHeaderLen + codec2Data.length);
    out[0] = _binaryMagic;
    out.setRange(1, 5, sessionBytes);
    out[5] = index;
    out.setRange(_binaryHeaderLen, out.length, codec2Data);
    return out;
  }

  // ── Duration helpers ─────────────────────────────────────────────────────

  /// Estimated audio duration of this packet in milliseconds.
  int get durationMs {
    // bytesPerSecond for each mode
    final bps = switch (mode) {
      VoicePacketMode.mode700c => 100,
      VoicePacketMode.mode1200 => 150,
      VoicePacketMode.mode1300 => 175,
      VoicePacketMode.mode1400 => 175,
      VoicePacketMode.mode1600 => 200,
      VoicePacketMode.mode2400 => 300,
      VoicePacketMode.mode3200 => 400,
    };
    if (bps == 0) return 0;
    return (codec2Data.length * 1000 ~/ bps).clamp(0, 1500);
  }

  @override
  String toString() {
    final suffix = total > 0 ? ' ${mode.label} [$index/${total - 1}]' : ' [$index]';
    return 'VoicePacket($sessionId$suffix ${codec2Data.length}B)';
  }
}

/// Lightweight public/direct message envelope advertising voice availability.
///
/// Text format:
///   VE3:{sid}:{mode}:{total}:{durS}
/// Example:
///   VE3:00112233:1:4:4
class VoiceEnvelope {
  static const String _prefix = 'VE3:';

  final String sessionId;
  final VoicePacketMode mode;
  final int total;
  final int durationMs;
  final int version;

  const VoiceEnvelope({
    required this.sessionId,
    required this.mode,
    required this.total,
    required this.durationMs,
    this.version = 3,
  });

  static bool isVoiceEnvelopeText(String text) => text.startsWith(_prefix);

  static VoiceEnvelope? tryParseText(String text) {
    if (!isVoiceEnvelopeText(text)) return null;
    final body = text.substring(_prefix.length);
    return _tryParse(body);
  }

  static VoiceEnvelope? _tryParse(String body) {
    final parts = body.split(':');
    if (parts.length != 4) return null;
    try {
      final sid = _decodeSessionId(parts[0]);
      final mode = _parseInt(parts[1], base36: true);
      final total = _parseInt(parts[2], base36: true);
      final durS = _parseInt(parts[3], base36: true);

      if (sid == null) {
        return null;
      }
      if (mode == null || mode < 0 || mode >= VoicePacketMode.values.length) {
        return null;
      }
      if (total == null || total < 1 || total > 255) return null;
      if (durS == null || durS < 0 || durS > 10 * 60) return null;

      return VoiceEnvelope(
        sessionId: sid,
        mode: VoicePacketMode.fromId(mode),
        total: total,
        durationMs: durS * 1000,
        version: 3,
      );
    } catch (_) {
      return null;
    }
  }

  String encodeText() {
    final durationSec = (durationMs / 1000).ceil().clamp(0, 10 * 60);
    return '$_prefix${_encodeSessionId(sessionId)}:${_toBase36(mode.id)}:${_toBase36(total)}:${_toBase36(durationSec)}';
  }
}

int voiceModeBytesPerSecond(VoicePacketMode mode) => switch (mode) {
  VoicePacketMode.mode700c => 100,
  VoicePacketMode.mode1200 => 150,
  VoicePacketMode.mode1300 => 175,
  VoicePacketMode.mode1400 => 175,
  VoicePacketMode.mode1600 => 200,
  VoicePacketMode.mode2400 => 300,
  VoicePacketMode.mode3200 => 400,
};

/// Approximate end-to-end transmit time for a voice session over MeshCore LoRa.
///
/// Uses envelope-level metadata (mode + duration + packet count) when only the
/// envelope is available and packet bytes are not yet received locally.
Duration estimateVoiceTransmitDuration({
  required VoicePacketMode mode,
  required int packetCount,
  required int durationMs,
  int pathLen = 0,
  int? radioBw,
  int? radioSf,
  int? radioCr,
}) {
  if (packetCount <= 0 || durationMs <= 0) return Duration.zero;

  final bytesPerSecond = voiceModeBytesPerSecond(mode);
  final totalCodecBytes = (durationMs * bytesPerSecond / 1000.0).round();
  final safePathLen = pathLen.clamp(0, 64);
  final hops = safePathLen + 1;
  final baseBytesPerPacket = totalCodecBytes ~/ packetCount;
  final extraBytes = totalCodecBytes % packetCount;
  var totalMs = 0.0;

  for (var i = 0; i < packetCount; i++) {
    final codecBytes = baseBytesPerPacket + (i < extraBytes ? 1 : 0);
    final loraLen =
        _meshPacketHeaderBytes +
        safePathLen +
        _voicePacketHeaderBytes +
        codecBytes;
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

/// Approximate transmit time using actually received voice packet sizes.
Duration estimateVoiceTransmitDurationFromPackets({
  required Iterable<VoicePacket?> packets,
  int pathLen = 0,
  int? radioBw,
  int? radioSf,
  int? radioCr,
}) {
  final safePathLen = pathLen.clamp(0, 64);
  final hops = safePathLen + 1;
  var totalMs = 0.0;

  for (final packet in packets) {
    if (packet == null) continue;
    final loraLen =
        _meshPacketHeaderBytes +
        safePathLen +
        _voicePacketHeaderBytes +
        packet.codec2Data.length;
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

/// Direct control-plane request to fetch voice packets for a session.
///
/// Text format:
///   VR3:{sid}:{want}:{requesterKey6}
/// Example:
///   VR3:00112233:a:aabbccddeeff
class VoiceFetchRequest {
  static const String _prefix = 'VR3:';
  static const int _binaryMagic = 0x72; // 'r'

  final String sessionId;
  final String want;
  final List<int> missingIndices;
  final String requesterKey6;
  final int version;

  const VoiceFetchRequest({
    required this.sessionId,
    this.want = 'all',
    this.missingIndices = const [],
    required this.requesterKey6,
    this.version = 3,
  });

  static bool isVoiceFetchRequestText(String text) =>
      text.startsWith(_prefix);
  static bool isVoiceFetchRequestBinary(Uint8List payload) =>
      payload.isNotEmpty && payload[0] == _binaryMagic;

  static VoiceFetchRequest? tryParseText(String text) {
    if (!isVoiceFetchRequestText(text)) return null;
    final body = text.substring(_prefix.length);
    return _tryParse(body);
  }

  static VoiceFetchRequest? tryParseBinary(Uint8List payload) {
    if (!isVoiceFetchRequestBinary(payload)) return null;
    if (payload.length < 13) return null; // magic+sid+flags+key6+count
    try {
      final sidBytes = payload.sublist(1, 5);
      final sid = sidBytes
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
      return VoiceFetchRequest(
        sessionId: sid,
        want: wantMissing ? 'missing' : 'all',
        missingIndices: missing,
        requesterKey6: requesterKey6,
        version: 3,
      );
    } catch (_) {
      return null;
    }
  }

  static VoiceFetchRequest? _tryParse(String body) {
    final parts = body.split(':');
    if (parts.length != 3) return null;
    try {
      final sid = _decodeSessionId(parts[0]);
      final wantToken = parts[1];
      final requesterKey6 = parts[2];
      final normalizedWant = wantToken == 'a'
          ? 'all'
          : ((wantToken.startsWith('m'))
                ? 'missing'
                : wantToken);

      if (sid == null) {
        return null;
      }
      final missingIndices = <int>[];
      if (normalizedWant == 'missing') {
        final encoded = wantToken.substring(1);
        if (encoded.isEmpty) return null;
        missingIndices.addAll(_decodeMissingIndicesCompact(encoded));
        if (missingIndices.isEmpty) return null;
      } else if (normalizedWant != 'all') {
        return null;
      }
      if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(requesterKey6)) {
        return null;
      }

      return VoiceFetchRequest(
        sessionId: sid,
        want: normalizedWant,
        missingIndices: missingIndices,
        requesterKey6: requesterKey6.toLowerCase(),
        version: 3,
      );
    } catch (_) {
      return null;
    }
  }

  String encodeText() {
    final wantToken = want == 'missing' && missingIndices.isNotEmpty
        ? 'm${_encodeMissingIndicesCompact(missingIndices)}'
        : (want == 'all' ? 'a' : want);
    return '$_prefix${_encodeSessionId(sessionId)}:$wantToken:${requesterKey6.toLowerCase()}';
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

/// Per-fragment ACK for raw voice payload packets.
///
/// Binary format:
///   [0x76 'v'][sessionId:4B][index:1B]
class VoiceFragmentAck {
  static const int _binaryMagic = 0x76; // 'v'

  final String sessionId; // 8 hex chars
  final int index; // 0..254

  const VoiceFragmentAck({required this.sessionId, required this.index});

  static bool isVoiceFragmentAckBinary(Uint8List payload) =>
      payload.length == 6 && payload[0] == _binaryMagic;

  static VoiceFragmentAck? tryParseBinary(Uint8List payload) {
    if (!isVoiceFragmentAckBinary(payload)) return null;
    try {
      final sid = payload
          .sublist(1, 5)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();
      final idx = payload[5];
      return VoiceFragmentAck(sessionId: sid, index: idx);
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
    throw ArgumentError.value(sessionIdHex, 'sessionIdHex', 'Expected 8 hex chars');
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
  final sorted = indices
      .where((v) => v >= 0 && v <= 254)
      .toSet()
      .toList()
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
      start == prev ? _toBase36(start) : '${_toBase36(start)}-${_toBase36(prev)}',
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

/// Builds a compact visual waveform from real voice packet bytes.
///
/// Note: This uses the encoded Codec2 packet bytes as the source so it works
/// even before full PCM decode/playback is available.
class VoiceWaveform {
  static List<double> buildBarsFromPackets(
    Iterable<VoicePacket?> packets, {
    int bars = 24,
  }) {
    if (bars <= 0) return const [];

    final merged = <int>[];
    for (final pkt in packets) {
      if (pkt == null || pkt.codec2Data.isEmpty) continue;
      merged.addAll(pkt.codec2Data);
    }
    if (merged.isEmpty) return List<double>.filled(bars, 0.0);

    final out = List<double>.filled(bars, 0.0);
    for (var i = 0; i < bars; i++) {
      final start = (i * merged.length) ~/ bars;
      var end = ((i + 1) * merged.length) ~/ bars;
      if (end <= start) end = start + 1;
      if (end > merged.length) end = merged.length;

      var sum = 0.0;
      for (var j = start; j < end; j++) {
        final centered = (merged[j] - 128).abs();
        sum += centered / 127.0;
      }
      out[i] = (sum / (end - start)).clamp(0.0, 1.0);
    }

    // Light smoothing to avoid jittery adjacent bars.
    if (bars > 2) {
      final smoothed = List<double>.from(out);
      for (var i = 1; i < bars - 1; i++) {
        smoothed[i] = ((out[i - 1] + out[i] + out[i + 1]) / 3.0).clamp(
          0.0,
          1.0,
        );
      }
      return smoothed;
    }
    return out;
  }
}
