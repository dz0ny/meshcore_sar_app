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

/// Message type (contact or channel)
enum MessageType {
  contact,
  channel,
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
    required this.receivedAt,
    this.senderName,
    this.deliveryStatus = MessageDeliveryStatus.received,
    this.expectedAckTag,
    this.suggestedTimeoutMs,
    this.roundTripTimeMs,
    this.deliveredAt,
    this.recipientPublicKey,
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

  /// Get friendly time since message was sent
  String get timeAgo {
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Get display name for sender
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
      notes: text,
    );
  }

  /// Get friendly delivery status description
  String get deliveryStatusText {
    switch (deliveryStatus) {
      case MessageDeliveryStatus.sending:
        return 'Sending...';
      case MessageDeliveryStatus.sent:
        return 'Sent';
      case MessageDeliveryStatus.delivered:
        if (roundTripTimeMs != null) {
          return 'Delivered (${roundTripTimeMs}ms)';
        }
        return 'Delivered';
      case MessageDeliveryStatus.failed:
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
    DateTime? receivedAt,
    String? senderName,
    MessageDeliveryStatus? deliveryStatus,
    int? expectedAckTag,
    int? suggestedTimeoutMs,
    int? roundTripTimeMs,
    DateTime? deliveredAt,
    Uint8List? recipientPublicKey,
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
      receivedAt: receivedAt ?? this.receivedAt,
      senderName: senderName ?? this.senderName,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      expectedAckTag: expectedAckTag ?? this.expectedAckTag,
      suggestedTimeoutMs: suggestedTimeoutMs ?? this.suggestedTimeoutMs,
      roundTripTimeMs: roundTripTimeMs ?? this.roundTripTimeMs,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      recipientPublicKey: recipientPublicKey ?? this.recipientPublicKey,
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
