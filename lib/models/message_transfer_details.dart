class MessageTransferDownloader {
  final String requesterKey6;
  final String? requesterName;
  final int transferCount;
  final DateTime lastTransferredAt;

  const MessageTransferDownloader({
    required this.requesterKey6,
    this.requesterName,
    required this.transferCount,
    required this.lastTransferredAt,
  });

  MessageTransferDownloader copyWith({
    String? requesterKey6,
    String? requesterName,
    int? transferCount,
    DateTime? lastTransferredAt,
  }) {
    return MessageTransferDownloader(
      requesterKey6: requesterKey6 ?? this.requesterKey6,
      requesterName: requesterName ?? this.requesterName,
      transferCount: transferCount ?? this.transferCount,
      lastTransferredAt: lastTransferredAt ?? this.lastTransferredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requesterKey6': requesterKey6,
      'requesterName': requesterName,
      'transferCount': transferCount,
      'lastTransferredAtMillis': lastTransferredAt.millisecondsSinceEpoch,
    };
  }

  static MessageTransferDownloader? fromJson(Map<String, dynamic> json) {
    final requesterKey6 = json['requesterKey6'];
    final transferCount = json['transferCount'];
    final lastTransferredAtMillis = json['lastTransferredAtMillis'];
    if (requesterKey6 is! String ||
        transferCount is! int ||
        lastTransferredAtMillis is! int) {
      return null;
    }

    return MessageTransferDownloader(
      requesterKey6: requesterKey6,
      requesterName: json['requesterName'] as String?,
      transferCount: transferCount,
      lastTransferredAt: DateTime.fromMillisecondsSinceEpoch(
        lastTransferredAtMillis,
      ),
    );
  }
}

class MessageTransferDetails {
  final int totalTransfers;
  final List<MessageTransferDownloader> downloaders;

  const MessageTransferDetails({
    required this.totalTransfers,
    required this.downloaders,
  });

  const MessageTransferDetails.empty()
    : totalTransfers = 0,
      downloaders = const [];

  MessageTransferDetails registerTransfer({
    required String requesterKey6,
    String? requesterName,
    DateTime? transferredAt,
  }) {
    final eventAt = transferredAt ?? DateTime.now();
    final normalizedName = requesterName?.trim();
    final updatedDownloaders = List<MessageTransferDownloader>.from(
      downloaders,
    );
    final index = updatedDownloaders.indexWhere(
      (entry) => entry.requesterKey6 == requesterKey6,
    );

    if (index == -1) {
      updatedDownloaders.add(
        MessageTransferDownloader(
          requesterKey6: requesterKey6,
          requesterName: normalizedName?.isEmpty ?? true
              ? null
              : normalizedName,
          transferCount: 1,
          lastTransferredAt: eventAt,
        ),
      );
    } else {
      final existing = updatedDownloaders[index];
      updatedDownloaders[index] = existing.copyWith(
        requesterName: normalizedName?.isEmpty ?? true
            ? existing.requesterName
            : normalizedName,
        transferCount: existing.transferCount + 1,
        lastTransferredAt: eventAt,
      );
    }

    updatedDownloaders.sort(
      (a, b) => b.lastTransferredAt.compareTo(a.lastTransferredAt),
    );

    return MessageTransferDetails(
      totalTransfers: totalTransfers + 1,
      downloaders: updatedDownloaders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTransfers': totalTransfers,
      'downloaders': downloaders.map((entry) => entry.toJson()).toList(),
    };
  }

  static MessageTransferDetails? fromJson(Map<String, dynamic> json) {
    final totalTransfers = json['totalTransfers'];
    if (totalTransfers is! int) {
      return null;
    }

    final rawDownloaders = json['downloaders'] as List<dynamic>? ?? const [];
    final downloaders = rawDownloaders
        .whereType<Map<String, dynamic>>()
        .map(MessageTransferDownloader.fromJson)
        .whereType<MessageTransferDownloader>()
        .toList();

    return MessageTransferDetails(
      totalTransfers: totalTransfers,
      downloaders: downloaders,
    );
  }
}
