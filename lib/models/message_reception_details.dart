const int _transmitEstimateToleranceMs = 1500;

int? sanitizeEstimatedTransmitMs({
  required int? estimatedTransmitMs,
  required int? senderToReceiptMs,
}) {
  if (estimatedTransmitMs == null || estimatedTransmitMs <= 0) {
    return null;
  }

  if (senderToReceiptMs == null || senderToReceiptMs <= 0) {
    return estimatedTransmitMs;
  }

  // Sender timestamps are second-granularity, so allow a small cushion before
  // treating the estimate as impossible for the observed delivery time.
  if (estimatedTransmitMs > senderToReceiptMs + _transmitEstimateToleranceMs) {
    return null;
  }

  return estimatedTransmitMs;
}

class MessageReceptionDetails {
  final DateTime capturedAt;
  final DateTime? packetLoggedAt;
  final int? rssiDbm;
  final double? snrDb;
  final List<int>? pathBytes;
  final int? senderToReceiptMs;
  final int? estimatedTransmitMs;
  final int? postTransmitDelayMs;

  const MessageReceptionDetails({
    required this.capturedAt,
    this.packetLoggedAt,
    this.rssiDbm,
    this.snrDb,
    this.pathBytes,
    this.senderToReceiptMs,
    this.estimatedTransmitMs,
    this.postTransmitDelayMs,
  });

  String? get pathBytesHex => pathBytes == null || pathBytes!.isEmpty
      ? null
      : pathBytes!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

  Map<String, dynamic> toJson() {
    return {
      'capturedAtMillis': capturedAt.millisecondsSinceEpoch,
      'packetLoggedAtMillis': packetLoggedAt?.millisecondsSinceEpoch,
      'rssiDbm': rssiDbm,
      'snrDb': snrDb,
      'pathBytes': pathBytes,
      'senderToReceiptMs': senderToReceiptMs,
      'estimatedTransmitMs': estimatedTransmitMs,
      'postTransmitDelayMs': postTransmitDelayMs,
    };
  }

  static MessageReceptionDetails? fromJson(Map<String, dynamic> json) {
    final capturedAtMillis = json['capturedAtMillis'];
    if (capturedAtMillis is! int) {
      return null;
    }

    final pathBytes = json['pathBytes'];
    return MessageReceptionDetails(
      capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMillis),
      packetLoggedAt: json['packetLoggedAtMillis'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              json['packetLoggedAtMillis'] as int,
            )
          : null,
      rssiDbm: json['rssiDbm'] as int?,
      snrDb: (json['snrDb'] as num?)?.toDouble(),
      pathBytes: pathBytes is List
          ? pathBytes.whereType<num>().map((b) => b.toInt()).toList()
          : null,
      senderToReceiptMs: json['senderToReceiptMs'] as int?,
      estimatedTransmitMs: json['estimatedTransmitMs'] as int?,
      postTransmitDelayMs: json['postTransmitDelayMs'] as int?,
    );
  }
}
