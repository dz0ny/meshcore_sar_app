import 'dart:convert';
import 'dart:math' as math;

import '../../models/message.dart';
import '../../models/contact.dart';

/// Manages message retry state and logic
///
/// This helper class centralizes retry logic for direct messages.
///
/// IMPORTANT: Based on MeshCore firmware analysis:
/// - Firmware calculates timeout based on path length and airtime
/// - Direct mode: ~(path_len * airtime * 2) + margin
/// - Flood mode: ~10-30 seconds for multi-hop
/// - Our retry delays (1s, 2s, 4s, 8s) are app-level backoff timers
/// - Firmware does NOT automatically retry - app must implement
class MessageRetryManager {
  // Track retry state for each message ID
  final Map<String, int> _retryAttempts = {};
  final Map<String, DateTime> _lastRetryTimes = {};
  final Map<String, int> _pathFailureStreaks = {};

  /// Max retry attempts when the contact has a known path.
  /// Sequence: 2 direct attempts, flood, then last successful route.
  static const int maxRetryAttemptsWithPath = 3;

  /// No retries for flood-only contacts (no known path).
  /// Value 0 means: don't retry at all, go straight to fallback/fail.
  static const int maxRetryAttemptsFloodOnly = 0;

  @Deprecated('Use maxRetryAttemptsForContact instead')
  static const int maxRetryAttempts = maxRetryAttemptsWithPath;

  // Retry backoff values in milliseconds.
  static const List<int> _retryDelays = [1000, 2000, 4000, 8000, 8000];
  static const int _defaultLoRaSf = 10;
  static const int _defaultLoRaCr = 5;
  static const int _defaultLoRaBwHz = 250000;
  static const int _defaultLoRaPreambleSymbols = 8;
  static const int _defaultLoRaCrcEnabled = 1;
  static const int _defaultLoRaExplicitHeader = 1;

  /// Get backoff delay for the next retry attempt.
  int getDelayForAttempt(int attempt) {
    if (attempt < 0 || attempt >= _retryDelays.length) {
      return _retryDelays.last;
    }
    return _retryDelays[attempt];
  }

  static final math.Random _rng = math.Random();

  /// Calculate a delivery-ACK timeout with random jitter.
  ///
  /// Matches the official MeshCore app: `suggestedTimeout + random(1-8s)`.
  /// The jitter prevents collision when multiple messages are in flight.
  int calculateAckTimeoutMs({
    required String text,
    required Contact? contact,
    int? suggestedTimeoutMs,
  }) {
    int baseTimeout;
    if (suggestedTimeoutMs != null && suggestedTimeoutMs > 0) {
      baseTimeout = suggestedTimeoutMs;
    } else {
      final payloadBytes = utf8.encode(text).length;
      final airtimeMs = _estimateLoRaAirtimeMs(payloadBytes);
      final hopCount = contact?.routeHasPath == true
          ? contact!.routeHopCount
          : -1;

      if (hopCount < 0) {
        baseTimeout = ((airtimeMs * 10) + 4000).clamp(10000, 30000);
      } else {
        baseTimeout = ((airtimeMs * (hopCount + 1) * 2) + 1500).clamp(4000, 20000);
      }
    }

    // Add random jitter: 500-2000ms to avoid collision
    final jitterMs = 500 + _rng.nextInt(1501);
    return baseTimeout + jitterMs;
  }

  /// Max attempts for a given contact based on whether it has a known path.
  static int maxRetryAttemptsForContact(Contact? contact) {
    final hasPath = contact?.routeHasPath ?? false;
    return hasPath ? maxRetryAttemptsWithPath : maxRetryAttemptsFloodOnly;
  }

  bool canRetry(Message message, Contact contact) {
    return message.retryAttempt < maxRetryAttemptsForContact(contact);
  }

  /// Whether this is the last retry attempt.
  /// When true, the caller should reset the path to force flood mode.
  ///
  /// Note: called AFTER retryAttempt has been incremented, so we compare
  /// directly against maxAttempts (not +1).
  bool isLastAttempt(Message message, Contact contact) {
    final maxAttempts = maxRetryAttemptsForContact(contact);
    return maxAttempts > 1 && message.retryAttempt >= maxAttempts;
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
