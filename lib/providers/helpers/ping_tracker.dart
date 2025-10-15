import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper class to track pending ping (telemetry) requests
/// and implement automatic fallback to flooding if no response received
class PingTracker {
  // Map of public key hex string to ping request state
  final Map<String, _PingRequest> _pendingPings = {};

  // Timeout duration for ping responses (seconds)
  static const int _pingTimeoutSeconds = 5;

  /// Track a new ping request
  /// Returns a Future that completes when either:
  /// - A response is received (completes with true)
  /// - Timeout occurs (completes with false)
  Future<bool> trackPing({
    required Uint8List publicKey,
    required bool wasDirectAttempt,
  }) {
    final String keyHex = _publicKeyToHex(publicKey);

    // Cancel any existing pending ping for this contact
    _pendingPings[keyHex]?.cancel();

    // Create new ping request tracker
    final completer = Completer<bool>();
    final timer = Timer(const Duration(seconds: _pingTimeoutSeconds), () {
      // Timeout occurred - mark as failed
      _pendingPings.remove(keyHex);
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    _pendingPings[keyHex] = _PingRequest(
      publicKey: publicKey,
      wasDirectAttempt: wasDirectAttempt,
      timer: timer,
      completer: completer,
    );

    return completer.future;
  }

  /// Mark a ping as successful (response received)
  /// Should be called when telemetry response arrives
  void markPingSuccessful(Uint8List publicKey) {
    final String keyHex = _publicKeyToHex(publicKey);
    final request = _pendingPings.remove(keyHex);

    if (request != null) {
      request.cancel();
      if (!request.completer.isCompleted) {
        request.completer.complete(true);
      }
    }
  }

  /// Check if there's a pending ping for this contact
  bool hasPendingPing(Uint8List publicKey) {
    final String keyHex = _publicKeyToHex(publicKey);
    return _pendingPings.containsKey(keyHex);
  }

  /// Get pending ping info (was it a direct attempt?)
  bool? wasPingDirect(Uint8List publicKey) {
    final String keyHex = _publicKeyToHex(publicKey);
    return _pendingPings[keyHex]?.wasDirectAttempt;
  }

  /// Clear all pending pings (useful on disconnect)
  void clearAll() {
    for (final request in _pendingPings.values) {
      request.cancel();
    }
    _pendingPings.clear();
  }

  /// Convert public key to hex string for map key
  String _publicKeyToHex(Uint8List publicKey) {
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}

/// Internal class to track a single ping request
class _PingRequest {
  final Uint8List publicKey;
  final bool wasDirectAttempt;
  final Timer timer;
  final Completer<bool> completer;

  _PingRequest({
    required this.publicKey,
    required this.wasDirectAttempt,
    required this.timer,
    required this.completer,
  });

  void cancel() {
    timer.cancel();
  }
}
