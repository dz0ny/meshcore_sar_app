/// Message delivery tracking helper
///
/// Manages message delivery tracking for sent messages, including:
/// - ACK tag to message ID mapping
/// - Pending sent message IDs queue
/// - Message sent/delivered coordination
class MessageDeliveryTracker {
  /// Map of ACK tag to message ID for delivery confirmation
  final Map<int, String> _ackTagToMessageId = {};

  /// Queue of pending message IDs (FIFO)
  /// Messages must be sent sequentially for proper matching
  final List<String> _pendingSentMessageIds = [];

  /// Track a pending message ID
  ///
  /// Add message ID to pending queue. When SENT response arrives,
  /// it will be matched with this message ID (FIFO order).
  void trackPendingMessage(String messageId) {
    _pendingSentMessageIds.add(messageId);
  }

  /// Get message ID for ACK tag and remove it from tracking
  ///
  /// Called when SENT response arrives. Returns the message ID
  /// that corresponds to this ACK tag (FIFO order).
  ///
  /// Returns null if no pending messages.
  String? popPendingMessageId() {
    if (_pendingSentMessageIds.isEmpty) {
      return null;
    }
    return _pendingSentMessageIds.removeAt(0);
  }

  /// Store ACK tag to message ID mapping
  ///
  /// Call this after receiving SENT response with expectedAckTag.
  /// Later, when SEND_CONFIRMED arrives with matching ackCode,
  /// you can look up the original message ID.
  void mapAckTagToMessageId(int ackTag, String messageId) {
    _ackTagToMessageId[ackTag] = messageId;
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

  /// Remove ACK tag mapping after delivery confirmed
  void removeAckTag(int ackCode) {
    _ackTagToMessageId.remove(ackCode);
  }

  /// Clear all tracking state
  void clearTracking() {
    _ackTagToMessageId.clear();
    _pendingSentMessageIds.clear();
  }

  /// Get count of pending messages
  int get pendingCount => _pendingSentMessageIds.length;

  /// Get count of tracked ACK tags
  int get ackTagCount => _ackTagToMessageId.length;
}
