import 'dart:convert';

import '../../models/message.dart';
import '../../models/contact.dart';

/// Manages message retry state and logic
///
/// This helper class centralizes retry logic for direct messages, implementing
/// a progressive timeout strategy (4s, 8s, 12s) for messages sent to contacts
/// with learned routing paths.
///
/// IMPORTANT: Based on MeshCore firmware analysis:
/// - Firmware calculates timeout based on path length and airtime
/// - Direct mode: ~(path_len * airtime * 2) + margin
/// - Flood mode: ~10-30 seconds for multi-hop
/// - Our timeouts (4s, 8s, 12s) are conservative for direct paths
/// - Firmware does NOT automatically retry - app must implement
class MessageRetryManager {
  // Track retry state for each message ID
  final Map<String, int> _retryAttempts = {};
  final Map<String, DateTime> _lastRetryTimes = {};
  final Map<String, int> _pathFailureStreaks = {};

  // Progressive timeout values in milliseconds
  // These are app-level timeouts, separate from firmware's suggested timeout
  // Firmware timeout is for ACK arrival, these are for retry attempts
  static const List<int> _timeouts = [4000, 8000, 12000];
  static const int _defaultLoRaSf = 10;
  static const int _defaultLoRaCr = 5;
  static const int _defaultLoRaBwHz = 250000;
  static const int _defaultLoRaPreambleSymbols = 8;
  static const int _defaultLoRaCrcEnabled = 1;
  static const int _defaultLoRaExplicitHeader = 1;

  /// Get timeout for a specific retry attempt (0-2)
  /// Returns: 4000ms for attempt 0, 8000ms for attempt 1, 12000ms for attempt 2
  int getTimeoutForAttempt(int attempt) {
    if (attempt < 0 || attempt >= _timeouts.length) {
      return _timeouts.last; // Default to last timeout if out of range
    }
    return _timeouts[attempt];
  }

  /// Calculate a conservative delivery-ACK timeout when firmware doesn't
  /// provide one or returns an invalid value.
  int calculateAckTimeoutMs({
    required String text,
    required Contact? contact,
    int? suggestedTimeoutMs,
  }) {
    if (suggestedTimeoutMs != null && suggestedTimeoutMs > 0) {
      return suggestedTimeoutMs;
    }

    final payloadBytes = utf8.encode(text).length;
    final airtimeMs = _estimateLoRaAirtimeMs(payloadBytes);
    final hopCount = contact?.routeHasPath == true
        ? contact!.routeHopCount
        : -1;

    if (hopCount < 0) {
      return ((airtimeMs * 10) + 4000).clamp(10000, 30000);
    }

    return ((airtimeMs * (hopCount + 1) * 2) + 1500).clamp(4000, 20000);
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
    return contact.routeHasPath;
  }

  /// Check if should fall back to flood mode
  ///
  /// Returns true if:
  /// - Message has exhausted all 3 retry attempts with direct mode
  /// - Contact HAS a learned path (so direct mode was used)
  /// - Hasn't already used flood fallback
  ///
  /// IMPORTANT: Only contacts WITH paths need flood fallback.
  /// Contacts without paths already use flood mode automatically.
  bool shouldUseFloodFallback(Message message, Contact contact) {
    return message.retryAttempt >= 3 &&
        contact.routeHasPath &&
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
    _pathFailureStreaks.clear();
  }

  /// Get current retry attempt for a message (for debugging)
  int? getRetryAttempt(String messageId) {
    return _retryAttempts[messageId];
  }

  /// Get last retry time for a message (for debugging)
  DateTime? getLastRetryTime(String messageId) {
    return _lastRetryTimes[messageId];
  }

  /// Record a successful delivery for a contact and clear any accumulated
  /// route failure streak for future sends.
  void recordDeliverySuccess(Contact contact) {
    _pathFailureStreaks.remove(contact.publicKeyHex);
  }

  /// Record a permanent route failure for a contact.
  ///
  /// Returns the updated failure streak so callers can decide when to reset
  /// the learned path on the radio and in local state.
  int recordPathFailure(Contact contact) {
    final contactKey = contact.publicKeyHex;
    final next = (_pathFailureStreaks[contactKey] ?? 0) + 1;
    _pathFailureStreaks[contactKey] = next;
    return next;
  }

  int? getPathFailureStreak(Contact contact) {
    return _pathFailureStreaks[contact.publicKeyHex];
  }

  int _estimateLoRaAirtimeMs(int payloadLenBytes) {
    final sf = _defaultLoRaSf;
    final bw = _defaultLoRaBwHz.toDouble();
    final cr = (_defaultLoRaCr - 4).clamp(1, 4);
    final ih = _defaultLoRaExplicitHeader == 1 ? 0 : 1;
    final de = (sf >= 11 && _defaultLoRaBwHz <= 125000) ? 1 : 0;

    final symbolMs = ((1 << sf) / bw) * 1000.0;
    final preambleMs = (_defaultLoRaPreambleSymbols + 4.25) * symbolMs;

    final num =
        (8 * payloadLenBytes) -
        (4 * sf) +
        28 +
        (16 * _defaultLoRaCrcEnabled) -
        (20 * ih);
    final den = 4 * (sf - (2 * de));
    final payloadSymCoeff = den <= 0 ? 0 : (num / den).ceil();
    final payloadSymbols =
        8 + (payloadSymCoeff < 0 ? 0 : payloadSymCoeff) * (cr + 4);
    final payloadMs = payloadSymbols * symbolMs;

    return (preambleMs + payloadMs).ceil();
  }
}
