import 'dart:typed_data';

enum PathSelectionMode { directCurrent, directHistorical, flood, nearestRouter }

class PathSelection {
  final PathSelectionMode mode;
  final Uint8List pathBytes;
  final int hopCount;
  final int hashSize;
  final String? relayName;
  final String? relayKey6;

  const PathSelection({
    required this.mode,
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
    this.relayName,
    this.relayKey6,
  });

  PathSelection.flood()
    : mode = PathSelectionMode.flood,
      pathBytes = Uint8List(0),
      hopCount = -1,
      hashSize = 1,
      relayName = null,
      relayKey6 = null;

  bool get usesFlood => mode == PathSelectionMode.flood;
  bool get hasDirectPath => !usesFlood && pathBytes.isNotEmpty && hopCount > 0;

  String get canonicalPath {
    if (!hasDirectPath) return '';
    final hops = <String>[];
    for (var index = 0; index < pathBytes.length; index += hashSize) {
      hops.add(
        pathBytes
            .sublist(index, index + hashSize)
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase(),
      );
    }
    return hops.join(',');
  }

  PathSelection copyWith({
    PathSelectionMode? mode,
    Uint8List? pathBytes,
    int? hopCount,
    int? hashSize,
    String? relayName,
    String? relayKey6,
  }) {
    return PathSelection(
      mode: mode ?? this.mode,
      pathBytes: pathBytes ?? this.pathBytes,
      hopCount: hopCount ?? this.hopCount,
      hashSize: hashSize ?? this.hashSize,
      relayName: relayName ?? this.relayName,
      relayKey6: relayKey6 ?? this.relayKey6,
    );
  }
}
