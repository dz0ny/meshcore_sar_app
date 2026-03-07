import 'dart:typed_data';

const int _swarmMagic = 0x6d; // 'm'
const int _swarmKindRequest = 0x01;
const int _swarmKindAvailability = 0x02;

class MediaSwarmRequest {
  final String mediaType;
  final String sessionId;
  final String requesterKey6;
  final List<int> missingIndices;

  const MediaSwarmRequest({
    required this.mediaType,
    required this.sessionId,
    required this.requesterKey6,
    this.missingIndices = const [],
  });

  bool get requestsAll => missingIndices.isEmpty;

  Uint8List encodeBinary() {
    final normalizedMissing = missingIndices.toSet().toList()..sort();
    final out = Uint8List(14 + normalizedMissing.length);
    out[0] = _swarmMagic;
    out[1] = _swarmKindRequest;
    out[2] = _encodeMediaType(mediaType);
    _writeSessionId(out, 3, sessionId);
    _writeKey6(out, 7, requesterKey6);
    out[13] = normalizedMissing.length;
    for (var i = 0; i < normalizedMissing.length; i++) {
      out[14 + i] = normalizedMissing[i];
    }
    return out;
  }

  static MediaSwarmRequest? tryParseBinary(Uint8List payload) {
    if (payload.length < 14 ||
        payload[0] != _swarmMagic ||
        payload[1] != _swarmKindRequest) {
      return null;
    }

    final mediaType = _decodeMediaType(payload[2]);
    if (mediaType == null) return null;

    final missingCount = payload[13];
    if (payload.length != 14 + missingCount) {
      return null;
    }

    return MediaSwarmRequest(
      mediaType: mediaType,
      sessionId: _readSessionId(payload, 3),
      requesterKey6: _readKey6(payload, 7),
      missingIndices: payload.sublist(14),
    );
  }
}

class MediaSwarmAvailability {
  final String mediaType;
  final String sessionId;
  final String requesterKey6;
  final String responderKey6;
  final List<int> availableIndices;

  const MediaSwarmAvailability({
    required this.mediaType,
    required this.sessionId,
    required this.requesterKey6,
    required this.responderKey6,
    required this.availableIndices,
  });

  bool get servesAll => availableIndices.isEmpty;

  Uint8List encodeBinary() {
    final normalizedAvailable = availableIndices.toSet().toList()..sort();
    final out = Uint8List(20 + normalizedAvailable.length);
    out[0] = _swarmMagic;
    out[1] = _swarmKindAvailability;
    out[2] = _encodeMediaType(mediaType);
    _writeSessionId(out, 3, sessionId);
    _writeKey6(out, 7, requesterKey6);
    _writeKey6(out, 13, responderKey6);
    out[19] = normalizedAvailable.length;
    for (var i = 0; i < normalizedAvailable.length; i++) {
      out[20 + i] = normalizedAvailable[i];
    }
    return out;
  }

  static MediaSwarmAvailability? tryParseBinary(Uint8List payload) {
    if (payload.length < 20 ||
        payload[0] != _swarmMagic ||
        payload[1] != _swarmKindAvailability) {
      return null;
    }

    final mediaType = _decodeMediaType(payload[2]);
    if (mediaType == null) return null;

    final availableCount = payload[19];
    if (payload.length != 20 + availableCount) {
      return null;
    }

    return MediaSwarmAvailability(
      mediaType: mediaType,
      sessionId: _readSessionId(payload, 3),
      requesterKey6: _readKey6(payload, 7),
      responderKey6: _readKey6(payload, 13),
      availableIndices: payload.sublist(20),
    );
  }
}

int _encodeMediaType(String mediaType) {
  return switch (mediaType) {
    'voice' => 0x01,
    'image' => 0x02,
    _ => throw ArgumentError.value(mediaType, 'mediaType'),
  };
}

String? _decodeMediaType(int raw) {
  return switch (raw) {
    0x01 => 'voice',
    0x02 => 'image',
    _ => null,
  };
}

void _writeSessionId(Uint8List out, int offset, String sessionId) {
  if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(sessionId)) {
    throw ArgumentError.value(sessionId, 'sessionId', 'Expected 8 hex chars');
  }
  for (var i = 0; i < 4; i++) {
    out[offset + i] = int.parse(
      sessionId.substring(i * 2, i * 2 + 2),
      radix: 16,
    );
  }
}

String _readSessionId(Uint8List payload, int offset) {
  return payload
      .sublist(offset, offset + 4)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

void _writeKey6(Uint8List out, int offset, String key6) {
  if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(key6)) {
    throw ArgumentError.value(key6, 'key6', 'Expected 12 hex chars');
  }
  for (var i = 0; i < 6; i++) {
    out[offset + i] = int.parse(key6.substring(i * 2, i * 2 + 2), radix: 16);
  }
}

String _readKey6(Uint8List payload, int offset) {
  return payload
      .sublist(offset, offset + 6)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
