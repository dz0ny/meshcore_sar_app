import '../../models/message.dart';
import '../../models/contact.dart';

/// Manages message retry state and logic
///
/// This helper class centralizes retry logic for direct messages, implementing
/// a progressive timeout strategy (4s, 8s, 12s) for messages sent to contacts
/// with learned routing paths.
class MessageRetryManager {
  // Track retry state for each message ID
  final Map<String, int> _retryAttempts = {};
  final Map<String, DateTime> _lastRetryTimes = {};

  // Progressive timeout values in milliseconds
  static const List<int> _timeouts = [4000, 8000, 12000];

  /// Get timeout for a specific retry attempt (0-2)
  /// Returns: 4000ms for attempt 0, 8000ms for attempt 1, 12000ms for attempt 2
  int getTimeoutForAttempt(int attempt) {
    if (attempt < 0 || attempt >= _timeouts.length) {
      return _timeouts.last; // Default to last timeout if out of range
    }
    return _timeouts[attempt];
  }

  /// Check if a message is eligible for retry
  ///
  /// Returns true if:
  /// - The message has retryAttempt < 3
  /// - The contact has a learned path (contact.hasPath == true)
  /// - The message hasn't used flood fallback yet
  ///
  /// Messages to contacts without paths should NOT retry (flood mode already broadcasts)
  bool canRetry(Message message, Contact contact) {
    // Never retry if already tried flood mode
    if (message.usedFloodFallback) {
      return false;
    }

    // Never retry beyond 3 attempts
    if (message.retryAttempt >= 3) {
      return false;
    }

    // Only retry if contact has a learned path
    // If no path, the device uses flood mode automatically - retrying won't help
    return contact.hasPath;
  }

  /// Check if should fall back to flood mode
  ///
  /// Returns true if:
  /// - Message has exhausted all 3 retry attempts
  /// - Contact still has no path
  /// - Hasn't already used flood fallback
  bool shouldUseFloodFallback(Message message, Contact contact) {
    return message.retryAttempt >= 3 &&
           !contact.hasPath &&
           !message.usedFloodFallback;
  }

  /// Track a retry attempt for a message
  void trackRetry(String messageId, int attempt) {
    _retryAttempts[messageId] = attempt;
    _lastRetryTimes[messageId] = DateTime.now();
  }

  /// Clear retry tracking for a message (on success or permanent failure)
  void clearRetry(String messageId) {
    _retryAttempts.remove(messageId);
    _lastRetryTimes.remove(messageId);
  }

  /// Clear all retry tracking (on disconnect)
  void clearAll() {
    _retryAttempts.clear();
    _lastRetryTimes.clear();
  }

  /// Get current retry attempt for a message (for debugging)
  int? getRetryAttempt(String messageId) {
    return _retryAttempts[messageId];
  }

  /// Get last retry time for a message (for debugging)
  DateTime? getLastRetryTime(String messageId) {
    return _lastRetryTimes[messageId];
  }
}
