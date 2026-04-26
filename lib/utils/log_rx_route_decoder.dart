import 'dart:typed_data';

import '../models/contact.dart';

class DecodedLogRxRoute {
  final int payloadType;
  final int pathDescriptor;
  final List<int> pathBytes;
  final int hashSize;

  const DecodedLogRxRoute({
    required this.payloadType,
    required this.pathDescriptor,
    required this.pathBytes,
    required this.hashSize,
  });

  List<String> get hopHashes =>
      LogRxRouteDecoder.splitHopHashes(pathBytes, hashSize: hashSize);

  int get hopCount => hopHashes.length;

  String? get originalSenderHashHex =>
      hopHashes.isEmpty ? null : hopHashes.first;
}

class ResolvedNodeHash {
  final String hashHex;
  final String label;
  final bool isOwnNode;
  final bool isUniqueMatch;
  final int matchCount;
  final double? latitude;
  final double? longitude;

  const ResolvedNodeHash({
    required this.hashHex,
    required this.label,
    required this.isOwnNode,
    required this.isUniqueMatch,
    required this.matchCount,
    this.latitude,
    this.longitude,
  });

  String get hexLabel => '0x${hashHex.toUpperCase()}';
}

class LogRxRouteDecoder {
  const LogRxRouteDecoder._();

  static DecodedLogRxRoute? decode(
    Uint8List rawData, {
    int? preferredHashSize,
  }) {
    if (rawData.length < 5 || rawData[0] != 0x88) return null;

    final rawPacketData = rawData.sublist(3);
    if (rawPacketData.length < 2) return null;

    final header = rawPacketData[0];
    final routeType = header & 0x03;
    final payloadType = (header >> 2) & 0x0F;

    var index = 1;
    if (routeType == 0x00 || routeType == 0x03) {
      if (rawPacketData.length < index + 5) return null;
      index += 4;
    }

    if (rawPacketData.length <= index) return null;
    final pathDescriptor = rawPacketData[index++];
    final pathMode = (pathDescriptor & 0xFF) >> 6;
    final pathByteLen = pathMode == 0
        ? pathDescriptor
        : descriptorByteLength(pathDescriptor);
    if (pathByteLen == null || rawPacketData.length < index + pathByteLen) {
      return null;
    }
    final pathBytes = rawPacketData.sublist(index, index + pathByteLen);
    final hashSize = pathMode == 0
        ? 1
        : (descriptorHashSize(pathDescriptor) ??
              inferHashSize(pathBytes, preferredHashSize: preferredHashSize));

    return DecodedLogRxRoute(
      payloadType: payloadType,
      pathDescriptor: pathDescriptor,
      pathBytes: pathBytes,
      hashSize: hashSize,
    );
  }

  static int? descriptorHashSize(int pathDescriptor) {
    final normalized = pathDescriptor & 0xFF;
    final mode = normalized >> 6;
    if (mode == 3) return null;
    return mode + 1;
  }

  static int? descriptorHopCount(int pathDescriptor) {
    final hashSize = descriptorHashSize(pathDescriptor);
    if (hashSize == null) return null;
    return (pathDescriptor & 0xFF) & 0x3F;
  }

  static int? descriptorByteLength(int pathDescriptor) {
    final hashSize = descriptorHashSize(pathDescriptor);
    final hopCount = descriptorHopCount(pathDescriptor);
    if (hashSize == null || hopCount == null) return null;
    final byteLen = hopCount * hashSize;
    return byteLen <= 64 ? byteLen : null;
  }

  static int inferHashSize(List<int> pathBytes, {int? preferredHashSize}) {
    if (pathBytes.isEmpty) return 1;

    final normalizedPreferred =
        preferredHashSize != null &&
            preferredHashSize >= 1 &&
            preferredHashSize <= 3
        ? preferredHashSize
        : null;
    if (normalizedPreferred != null &&
        pathBytes.length % normalizedPreferred == 0) {
      return normalizedPreferred;
    }

    for (final candidate in const [3, 2, 1]) {
      if (pathBytes.length % candidate == 0) {
        return candidate;
      }
    }

    return 1;
  }

  static List<String> splitHopHashes(
    List<int> pathBytes, {
    required int hashSize,
  }) {
    if (pathBytes.isEmpty) return const [];
    if (hashSize < 1 || hashSize > 3 || pathBytes.length % hashSize != 0) {
      return pathBytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .toList();
    }

    final hops = <String>[];
    for (var index = 0; index < pathBytes.length; index += hashSize) {
      hops.add(
        pathBytes
            .sublist(index, index + hashSize)
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(),
      );
    }
    return hops;
  }

  static List<int> reverseHopBytes(
    List<int> pathBytes, {
    required int hashSize,
  }) {
    if (pathBytes.isEmpty) return const [];
    if (hashSize < 1 || hashSize > 3 || pathBytes.length % hashSize != 0) {
      return List<int>.from(pathBytes.reversed);
    }

    final reversed = <int>[];
    for (
      var index = pathBytes.length - hashSize;
      index >= 0;
      index -= hashSize
    ) {
      reversed.addAll(pathBytes.sublist(index, index + hashSize));
    }
    return reversed;
  }

  static ResolvedNodeHash resolveHash(
    String hashHex, {
    required Iterable<Contact> contacts,
    Uint8List? ownPublicKey,
    String? ownName,
    double? ownLatitude,
    double? ownLongitude,
  }) {
    final normalizedHashHex = hashHex.toLowerCase();
    final ownKeyHex = _bytesToHex(ownPublicKey);
    if (ownKeyHex != null && ownKeyHex.startsWith(normalizedHashHex)) {
      final ownLabel = (ownName != null && ownName.trim().isNotEmpty)
          ? '$ownName (you)'
          : 'You';
      return ResolvedNodeHash(
        hashHex: normalizedHashHex,
        label: ownLabel,
        isOwnNode: true,
        isUniqueMatch: true,
        matchCount: 1,
        latitude: ownLatitude,
        longitude: ownLongitude,
      );
    }

    final matches = contacts.where((contact) {
      return contact.publicKeyHex.toLowerCase().startsWith(normalizedHashHex);
    }).toList();

    if (matches.isEmpty) {
      return ResolvedNodeHash(
        hashHex: normalizedHashHex,
        label: 'Unknown',
        isOwnNode: false,
        isUniqueMatch: false,
        matchCount: 0,
      );
    }

    if (matches.length == 1) {
      final location = matches.first.displayLocation;
      return ResolvedNodeHash(
        hashHex: normalizedHashHex,
        label: matches.first.displayName,
        isOwnNode: false,
        isUniqueMatch: true,
        matchCount: 1,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
    }

    final candidateNames = matches
        .map((contact) => contact.displayName)
        .where((name) => name.trim().isNotEmpty)
        .take(2)
        .join(', ');
    final extraCount = matches.length - 2;
    final label = candidateNames.isEmpty
        ? '${matches.length} contacts'
        : extraCount > 0
        ? '$candidateNames +$extraCount'
        : candidateNames;
    return ResolvedNodeHash(
      hashHex: normalizedHashHex,
      label: label,
      isOwnNode: false,
      isUniqueMatch: false,
      matchCount: matches.length,
    );
  }

  static String? _bytesToHex(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();
  }
}
