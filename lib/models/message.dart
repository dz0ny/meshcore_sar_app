import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'sar_marker.dart';

/// Message text types from MeshCore protocol
enum MessageTextType {
  plain(0),
  cliData(1),
  signedPlain(2);

  const MessageTextType(this.value);
  final int value;

  static MessageTextType fromValue(int value) {
    return MessageTextType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageTextType.plain,
    );
  }
}

/// Message type (contact, channel, or system)
enum MessageType {
  contact,
  channel,
  system, // System messages (log entries, status updates)
}

/// Message delivery status
enum MessageDeliveryStatus {
  sending,     // Message is being sent
  sent,        // Message queued with expected ACK
  delivered,   // Delivery confirmed (ACK received)
  failed,      // Delivery failed
  received,    // Message received from another contact
}

/// MeshCore message model
class Message {
  final String id;
  final MessageType messageType;
  final Uint8List? senderPublicKeyPrefix; // 6 bytes for contact messages
  final int? channelIdx; // For channel messages
  final int pathLen;
  final MessageTextType textType;
  final int senderTimestamp; // Unix timestamp
  final String text;

  // SAR marker data (if this is a SAR message)
  final bool isSarMarker;
  final SarMarkerType? sarMarkerType;
  final LatLng? sarGpsCoordinates;
  final String? sarNotes; // Optional message/notes for SAR marker

  // Display metadata
  final DateTime receivedAt;
  final String? senderName;

  // Delivery tracking (for sent messages)
  final MessageDeliveryStatus deliveryStatus;
  final int? expectedAckTag; // Expected ACK/TAG from SENT response
  final int? suggestedTimeoutMs; // Suggested timeout from SENT response
  final int? roundTripTimeMs; // RTT from SEND_CONFIRMED
  final DateTime? deliveredAt; // When delivery was confirmed
  final Uint8List? recipientPublicKey; // Full 32-byte public key of recipient (for retry)

  // Retry tracking (for automatic retry with progressive timeouts)
  final int retryAttempt; // Current retry attempt (0-3), 0 = first send
  final DateTime? lastRetryAt; // When last retry was sent
  final bool usedFloodFallback; // Whether message fell back to flood mode after retries

  // Read status tracking
  final bool isRead; // Whether message has been read by user

  Message({
    required this.id,
    required this.messageType,
    this.senderPublicKeyPrefix,
    this.channelIdx,
    required this.pathLen,
    required this.textType,
    required this.senderTimestamp,
    required this.text,
    this.isSarMarker = false,
    this.sarMarkerType,
    this.sarGpsCoordinates,
    this.sarNotes,
    required this.receivedAt,
    this.senderName,
    this.deliveryStatus = MessageDeliveryStatus.received,
    this.expectedAckTag,
    this.suggestedTimeoutMs,
    this.roundTripTimeMs,
    this.deliveredAt,
    this.recipientPublicKey,
    this.retryAttempt = 0,
    this.lastRetryAt,
    this.usedFloodFallback = false,
    this.isRead = false,
  });

  /// Get sender public key as hex string
  String? get senderKeyShort {
    if (senderPublicKeyPrefix == null) return null;
    return senderPublicKeyPrefix!
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  /// Get sender timestamp as DateTime
  DateTime get sentAt {
    return DateTime.fromMillisecondsSinceEpoch(senderTimestamp * 1000);
  }

  /// Check if message is from a channel
  bool get isChannelMessage => messageType == MessageType.channel;

  /// Check if message is from a contact
  bool get isContactMessage => messageType == MessageType.contact;

  /// Check if message is a system message
  bool get isSystemMessage => messageType == MessageType.system;

  /// Get friendly time since message was sent
  String get timeAgo {
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Get display name for sender (basic fallback without contact info)
  String get displaySender {
    if (senderName != null && senderName!.isNotEmpty) {
      return senderName!;
    }
    if (senderKeyShort != null) {
      return senderKeyShort!.substring(0, 8);
    }
    if (isChannelMessage && channelIdx != null) {
      return 'Channel $channelIdx';
    }
    return 'Unknown';
  }

  /// Get rich display name for sender using contact information
  /// Returns emoji + display name if available, otherwise falls back to displaySender
  String getRichDisplayName(dynamic contact) {
    if (contact == null) return displaySender;

    // If contact has roleEmoji, use it with displayName
    final roleEmoji = contact.roleEmoji;
    if (roleEmoji != null && roleEmoji.isNotEmpty) {
      return '$roleEmoji ${contact.displayName}';
    }

    // Otherwise just use advName or displayName
    return contact.displayName ?? contact.advName ?? displaySender;
  }

  /// Convert to SAR marker if applicable
  SarMarker? toSarMarker() {
    if (!isSarMarker || sarMarkerType == null || sarGpsCoordinates == null) {
      return null;
    }

    return SarMarker(
      id: id,
      type: sarMarkerType!,
      location: sarGpsCoordinates!,
      timestamp: sentAt,
      senderPublicKey: senderPublicKeyPrefix,
      senderName: senderName,
      notes: sarNotes, // Use dedicated notes field instead of full text
    );
  }

  /// Get friendly delivery status description
  String get deliveryStatusText {
    switch (deliveryStatus) {
      case MessageDeliveryStatus.sending:
        if (retryAttempt > 0) {
          return 'Retrying ($retryAttempt/3)...';
        }
        return 'Sending...';

      case MessageDeliveryStatus.sent:
        if (retryAttempt > 0) {
          return 'Sent (retry $retryAttempt)';
        }
        return 'Sent';

      case MessageDeliveryStatus.delivered:
        final rttText = roundTripTimeMs != null ? '${roundTripTimeMs}ms' : '';
        if (retryAttempt > 0 && rttText.isNotEmpty) {
          return 'Delivered ($rttText) [retry $retryAttempt]';
        } else if (retryAttempt > 0) {
          return 'Delivered [retry $retryAttempt]';
        } else if (rttText.isNotEmpty) {
          return 'Delivered ($rttText)';
        }
        return 'Delivered';

      case MessageDeliveryStatus.failed:
        if (usedFloodFallback) {
          return 'Failed (tried flood)';
        }
        if (retryAttempt > 0) {
          final retryWord = retryAttempt == 1 ? 'retry' : 'retries';
          return 'Failed (after $retryAttempt $retryWord)';
        }
        return 'Failed';

      case MessageDeliveryStatus.received:
        return '';
    }
  }

  /// Check if this is a sent message (not received)
  bool get isSentMessage => deliveryStatus != MessageDeliveryStatus.received;

  /// Check if this message is from self (own message)
  /// [selfPublicKey] - the device's own public key (first 6 bytes)
  bool isFromSelf(Uint8List? selfPublicKey) {
    if (selfPublicKey == null || selfPublicKey.length < 6) return false;

    // Compare sender public key prefix with self public key prefix
    if (senderPublicKeyPrefix != null && senderPublicKeyPrefix!.length >= 6) {
      return senderPublicKeyPrefix![0] == selfPublicKey[0] &&
             senderPublicKeyPrefix![1] == selfPublicKey[1] &&
             senderPublicKeyPrefix![2] == selfPublicKey[2] &&
             senderPublicKeyPrefix![3] == selfPublicKey[3] &&
             senderPublicKeyPrefix![4] == selfPublicKey[4] &&
             senderPublicKeyPrefix![5] == selfPublicKey[5];
    }

    return false;
  }

  Message copyWith({
    String? id,
    MessageType? messageType,
    Uint8List? senderPublicKeyPrefix,
    int? channelIdx,
    int? pathLen,
    MessageTextType? textType,
    int? senderTimestamp,
    String? text,
    bool? isSarMarker,
    SarMarkerType? sarMarkerType,
    LatLng? sarGpsCoordinates,
    String? sarNotes,
    DateTime? receivedAt,
    String? senderName,
    MessageDeliveryStatus? deliveryStatus,
    int? expectedAckTag,
    int? suggestedTimeoutMs,
    int? roundTripTimeMs,
    DateTime? deliveredAt,
    Uint8List? recipientPublicKey,
    int? retryAttempt,
    DateTime? lastRetryAt,
    bool? usedFloodFallback,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      messageType: messageType ?? this.messageType,
      senderPublicKeyPrefix: senderPublicKeyPrefix ?? this.senderPublicKeyPrefix,
      channelIdx: channelIdx ?? this.channelIdx,
      pathLen: pathLen ?? this.pathLen,
      textType: textType ?? this.textType,
      senderTimestamp: senderTimestamp ?? this.senderTimestamp,
      text: text ?? this.text,
      isSarMarker: isSarMarker ?? this.isSarMarker,
      sarMarkerType: sarMarkerType ?? this.sarMarkerType,
      sarGpsCoordinates: sarGpsCoordinates ?? this.sarGpsCoordinates,
      sarNotes: sarNotes ?? this.sarNotes,
      receivedAt: receivedAt ?? this.receivedAt,
      senderName: senderName ?? this.senderName,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      expectedAckTag: expectedAckTag ?? this.expectedAckTag,
      suggestedTimeoutMs: suggestedTimeoutMs ?? this.suggestedTimeoutMs,
      roundTripTimeMs: roundTripTimeMs ?? this.roundTripTimeMs,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      recipientPublicKey: recipientPublicKey ?? this.recipientPublicKey,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      usedFloodFallback: usedFloodFallback ?? this.usedFloodFallback,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    if (isSarMarker) {
      return 'Message(SAR: ${sarMarkerType?.displayName}, from: $displaySender)';
    }
    return 'Message(from: $displaySender, text: ${text.length > 30 ? '${text.substring(0, 30)}...' : text})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
