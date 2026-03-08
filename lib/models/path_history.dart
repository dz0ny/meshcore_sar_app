class PathRecord {
  final List<int> pathBytes;
  final int hopCount;
  final int hashSize;
  final int successCount;
  final int failureCount;
  final int lastRoundTripTimeMs;
  final DateTime lastUsedAt;

  const PathRecord({
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
    required this.successCount,
    required this.failureCount,
    required this.lastRoundTripTimeMs,
    required this.lastUsedAt,
  });

  String get signature =>
      pathBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  double get successRate =>
      (successCount + 1) / (successCount + failureCount + 2);

  PathRecord copyWith({
    List<int>? pathBytes,
    int? hopCount,
    int? hashSize,
    int? successCount,
    int? failureCount,
    int? lastRoundTripTimeMs,
    DateTime? lastUsedAt,
  }) {
    return PathRecord(
      pathBytes: pathBytes ?? this.pathBytes,
      hopCount: hopCount ?? this.hopCount,
      hashSize: hashSize ?? this.hashSize,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      lastRoundTripTimeMs: lastRoundTripTimeMs ?? this.lastRoundTripTimeMs,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path_bytes': pathBytes,
      'hop_count': hopCount,
      'hash_size': hashSize,
      'success_count': successCount,
      'failure_count': failureCount,
      'last_round_trip_time_ms': lastRoundTripTimeMs,
      'last_used_at': lastUsedAt.toIso8601String(),
    };
  }

  factory PathRecord.fromJson(Map<String, dynamic> json) {
    return PathRecord(
      pathBytes: (json['path_bytes'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value as int)
          .toList(),
      hopCount: json['hop_count'] as int? ?? 0,
      hashSize: json['hash_size'] as int? ?? 1,
      successCount: json['success_count'] as int? ?? 0,
      failureCount: json['failure_count'] as int? ?? 0,
      lastRoundTripTimeMs: json['last_round_trip_time_ms'] as int? ?? 0,
      lastUsedAt:
          DateTime.tryParse(json['last_used_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class FloodPathStats {
  final int successCount;
  final int failureCount;
  final int lastRoundTripTimeMs;
  final DateTime? lastUsedAt;

  const FloodPathStats({
    required this.successCount,
    required this.failureCount,
    required this.lastRoundTripTimeMs,
    required this.lastUsedAt,
  });

  const FloodPathStats.empty()
    : successCount = 0,
      failureCount = 0,
      lastRoundTripTimeMs = 0,
      lastUsedAt = null;

  FloodPathStats copyWith({
    int? successCount,
    int? failureCount,
    int? lastRoundTripTimeMs,
    DateTime? lastUsedAt,
  }) {
    return FloodPathStats(
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      lastRoundTripTimeMs: lastRoundTripTimeMs ?? this.lastRoundTripTimeMs,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success_count': successCount,
      'failure_count': failureCount,
      'last_round_trip_time_ms': lastRoundTripTimeMs,
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  factory FloodPathStats.fromJson(Map<String, dynamic> json) {
    return FloodPathStats(
      successCount: json['success_count'] as int? ?? 0,
      failureCount: json['failure_count'] as int? ?? 0,
      lastRoundTripTimeMs: json['last_round_trip_time_ms'] as int? ?? 0,
      lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
    );
  }
}

class ContactPathHistory {
  final String contactPublicKeyHex;
  final List<PathRecord> directPaths;
  final FloodPathStats floodStats;
  final int rotationIndex;

  const ContactPathHistory({
    required this.contactPublicKeyHex,
    required this.directPaths,
    required this.floodStats,
    required this.rotationIndex,
  });

  const ContactPathHistory.empty(this.contactPublicKeyHex)
    : directPaths = const <PathRecord>[],
      floodStats = const FloodPathStats.empty(),
      rotationIndex = 0;

  ContactPathHistory copyWith({
    List<PathRecord>? directPaths,
    FloodPathStats? floodStats,
    int? rotationIndex,
  }) {
    return ContactPathHistory(
      contactPublicKeyHex: contactPublicKeyHex,
      directPaths: directPaths ?? this.directPaths,
      floodStats: floodStats ?? this.floodStats,
      rotationIndex: rotationIndex ?? this.rotationIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'direct_paths': directPaths.map((record) => record.toJson()).toList(),
      'flood_stats': floodStats.toJson(),
      'rotation_index': rotationIndex,
    };
  }

  factory ContactPathHistory.fromJson(
    String contactPublicKeyHex,
    Map<String, dynamic> json,
  ) {
    return ContactPathHistory(
      contactPublicKeyHex: contactPublicKeyHex,
      directPaths: (json['direct_paths'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PathRecord.fromJson)
          .toList(),
      floodStats: json['flood_stats'] is Map<String, dynamic>
          ? FloodPathStats.fromJson(json['flood_stats'] as Map<String, dynamic>)
          : const FloodPathStats.empty(),
      rotationIndex: json['rotation_index'] as int? ?? 0,
    );
  }
}
