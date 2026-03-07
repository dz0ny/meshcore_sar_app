import 'dart:typed_data';

/// Message delivery tracking helper
///
/// Manages message delivery tracking for sent messages, including:
/// - FIFO queue for matching RESP_CODE_SENT with message IDs
/// - ACK tag to message ID mapping
/// - Timeout tracking for stale ACK mappings
/// - Message sent/delivered coordination
///
/// IMPORTANT: Based on MeshCore firmware analysis:
/// - Firmware tracks max 8 pending ACKs in circular buffer
/// - ACK entries overwritten after 8 messages → need rate limiting
/// - Duplicate ACKs suppressed after first match
/// - No automatic retry → app must implement
class MessageDeliveryTracker {
  /// FIFO queue of pending message IDs
  /// Messages tracked here before sending, popped when RESP_CODE_SENT arrives
  final List<String> _pendingMessageIds = [];

  /// Contact-scoped FIFOs for matching direct-message SENT responses.
  final Map<String, List<String>> _pendingMessageIdsByContact = {};

  /// Map of ACK tag to message ID for delivery confirmation
  final Map<int, String> _ackTagToMessageId = {};

  /// Map of message ID to ACK tag (reverse mapping for cleanup)
  final Map<String, int> _messageIdToAckTag = {};

  /// Map of ACK tag to timestamp for timeout cleanup
  final Map<int, DateTime> _ackTagTimestamps = {};

  /// Track a pending message ID before sending
  ///
  /// This is called BEFORE sending the message. When RESP_CODE_SENT
  /// arrives, we pop from this FIFO queue to match with the ACK tag.
  void trackPendingMessage(String messageId) {
    _pendingMessageIds.add(messageId);
  }

  /// Track a pending direct message ID for a specific contact.
  void trackPendingDirectMessage(String messageId, Uint8List contactPublicKey) {
    trackPendingMessage(messageId);
    final contactKey = _contactKey(contactPublicKey);
    _pendingMessageIdsByContact
        .putIfAbsent(contactKey, () => [])
        .add(messageId);
  }

  /// Pop the next pending message ID from FIFO queue
  ///
  /// Called when RESP_CODE_SENT arrives. Returns null if queue empty.
  String? popPendingMessageId() {
    if (_pendingMessageIds.isEmpty) {
      return null;
    }
    return _pendingMessageIds.removeAt(0);
  }

  /// Pop the next pending direct message ID for a specific contact.
  ///
  /// Falls back to the legacy global FIFO if the contact queue is empty.
  String? popPendingDirectMessageId(Uint8List contactPublicKey) {
    final contactKey = _contactKey(contactPublicKey);
    final queue = _pendingMessageIdsByContact[contactKey];
    if (queue == null || queue.isEmpty) {
      return popPendingMessageId();
    }

    final messageId = queue.removeAt(0);
    if (queue.isEmpty) {
      _pendingMessageIdsByContact.remove(contactKey);
    }
    _pendingMessageIds.remove(messageId);
    return messageId;
  }

  /// Map ACK tag to message ID after RESP_CODE_SENT received
  ///
  /// Creates bidirectional mapping for efficient cleanup and tracking.
  ///
  /// WARNING: Firmware only tracks 8 pending ACKs! Caller should
  /// enforce rate limiting before calling this.
  void mapAckTagToMessageId(int ackTag, String messageId) {
    // Store bidirectional mapping
    _ackTagToMessageId[ackTag] = messageId;
    _messageIdToAckTag[messageId] = ackTag;
    _ackTagTimestamps[ackTag] = DateTime.now();
  }

  /// Get message ID for ACK code
  ///
  /// Called when SEND_CONFIRMED arrives. Returns the message ID
  /// that corresponds to this ACK code.
  ///
  /// Returns null if ACK tag not found.
  String? getMessageIdForAck(int ackCode) {
    return _ackTagToMessageId[ackCode];
  }

  /// Returns true once a message has been matched to a concrete ACK tag.
  bool hasAckForMessage(String messageId) {
    return _messageIdToAckTag.containsKey(messageId);
  }

  /// Remove ACK tag mapping after delivery confirmed or timeout
  ///
  /// Cleans up both forward and reverse mappings.
  void removeAckTag(int ackCode) {
    final messageId = _ackTagToMessageId.remove(ackCode);
    if (messageId != null) {
      _messageIdToAckTag.remove(messageId);
    }
    _ackTagTimestamps.remove(ackCode);
  }

  /// Remove ACK tag mapping by message ID
  ///
  /// Used when message times out or is cancelled.
  void removeByMessageId(String messageId) {
    final ackTag = _messageIdToAckTag.remove(messageId);
    if (ackTag != null) {
      _ackTagToMessageId.remove(ackTag);
      _ackTagTimestamps.remove(ackTag);
    }
    _pendingMessageIds.remove(messageId);
    final emptyKeys = <String>[];
    for (final entry in _pendingMessageIdsByContact.entries) {
      entry.value.remove(messageId);
      if (entry.value.isEmpty) {
        emptyKeys.add(entry.key);
      }
    }
    for (final key in emptyKeys) {
      _pendingMessageIdsByContact.remove(key);
    }
  }

  /// Clean up stale ACK mappings
  ///
  /// Removes ACK tags that haven't received delivery confirmation
  /// within the specified timeout (default: 5 minutes).
  ///
  /// Returns count of cleaned up entries.
  int cleanupStaleAcks({Duration timeout = const Duration(minutes: 5)}) {
    final now = DateTime.now();
    final staleAcks = <int>[];

    for (final entry in _ackTagTimestamps.entries) {
      if (now.difference(entry.value) > timeout) {
        staleAcks.add(entry.key);
      }
    }

    for (final ackTag in staleAcks) {
      removeAckTag(ackTag);
    }

    return staleAcks.length;
  }

  /// Clear all tracking state
  void clearTracking() {
    _pendingMessageIds.clear();
    _pendingMessageIdsByContact.clear();
    _ackTagToMessageId.clear();
    _messageIdToAckTag.clear();
    _ackTagTimestamps.clear();
  }

  /// Get count of pending ACK tags
  ///
  /// WARNING: Firmware only tracks 8 pending ACKs in circular buffer.
  /// If this exceeds 7, message sending should be rate limited.
  int get pendingCount => _ackTagToMessageId.length;

  /// Check if should rate limit message sending
  ///
  /// Returns true if >= 7 pending ACKs (stay under firmware limit of 8)
  bool get shouldRateLimit => pendingCount >= 7;

  /// Get oldest pending ACK timestamp (for debugging)
  DateTime? get oldestPendingTimestamp {
    if (_ackTagTimestamps.isEmpty) return null;
    return _ackTagTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Get diagnostic info for debugging
  Map<String, dynamic> getDiagnostics() {
    return {
      'pendingCount': pendingCount,
      'shouldRateLimit': shouldRateLimit,
      'oldestPending': oldestPendingTimestamp?.toIso8601String(),
      'ackTags': _ackTagToMessageId.keys.toList(),
      'pendingByContact': _pendingMessageIdsByContact.map(
        (key, value) => MapEntry(key, value.length),
      ),
    };
  }

  String _contactKey(Uint8List contactPublicKey) {
    return contactPublicKey
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
