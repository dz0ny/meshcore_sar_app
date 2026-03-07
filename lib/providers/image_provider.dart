import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import 'helpers/raw_session_retransmit.dart';
import '../utils/image_message_parser.dart';

/// Reassembly state for one incoming image session.
class ImageSession {
  final String sessionId;
  final ImageFormat format;
  final int total;
  final int width;
  final int height;
  final List<ImagePacket?> fragments; // indexed by fragment.index
  DateTime? firstFragmentAt;
  DateTime? lastFragmentAt;

  ImageSession({
    required this.sessionId,
    required this.format,
    required this.total,
    required this.width,
    required this.height,
  }) : fragments = List.filled(total, null);

  int get receivedCount => fragments.where((f) => f != null).length;
  bool get isComplete => receivedCount == total;

  Duration? estimateRemaining() {
    if (isComplete) return Duration.zero;
    if (firstFragmentAt == null || lastFragmentAt == null) return null;
    if (receivedCount < 2) return null;

    final elapsedMs = lastFragmentAt!
        .difference(firstFragmentAt!)
        .inMilliseconds;
    if (elapsedMs <= 0) return null;
    final avgMsPerFragment = elapsedMs / (receivedCount - 1);
    final remaining = total - receivedCount;
    if (remaining <= 0) return Duration.zero;
    return Duration(milliseconds: (avgMsPerFragment * remaining).round());
  }

  /// Reassemble the complete image bytes, or null if any fragment is missing.
  Uint8List? get imageBytes => reassembleImage(fragments);
}

/// Manages incoming image sessions and outgoing image caches.
///
/// Mirrors [VoiceProvider] in architecture: on-demand fetch, deferred serving,
/// persistent storage of both incoming and outgoing session data.
class ImageProvider with ChangeNotifier {
  static const String _storageKey = 'stored_image_sessions_v1';
  static const Duration _outgoingTtl = Duration(minutes: 15);
  static const int maxDirectPayloadHops = 3;

  /// Incoming sessions keyed by sessionId.
  final Map<String, ImageSession> _sessions = {};
  final Set<String> _ignoredIncomingSessions = {};

  /// Outgoing sessions cached for deferred serving.
  final Map<String, _OutgoingSession> _outgoing = {};

  /// Hook for sending a raw binary payload to a contact.
  Future<void> Function({
    required Uint8List contactPath,
    required int contactPathLen,
    required Uint8List payload,
  })?
  sendRawPacketCallback;

  ImageProvider() {
    _restore();
  }

  // ── Accessors ────────────────────────────────────────────────────────────

  ImageSession? session(String sessionId) => _sessions[sessionId];
  bool isComplete(String sessionId) =>
      _sessions[sessionId]?.isComplete ?? false;
  bool hasOutgoing(String sessionId) => _outgoing.containsKey(sessionId);
  Duration? estimateRemainingTransferTime(String sessionId) =>
      _sessions[sessionId]?.estimateRemaining();
  bool isReceiveCanceled(String sessionId) =>
      _ignoredIncomingSessions.contains(sessionId);

  List<int> missingFragmentIndices(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return const [];
    final missing = <int>[];
    for (var i = 0; i < session.total; i++) {
      if (session.fragments[i] == null) missing.add(i);
    }
    return missing;
  }

  List<int> availableFragmentIndices(String sessionId) {
    final outgoing = _outgoing[sessionId];
    if (outgoing != null) {
      return outgoing.fragments.map((fragment) => fragment.index).toList()
        ..sort();
    }

    final session = _sessions[sessionId];
    if (session == null) return const [];
    final indices = <int>[];
    for (var i = 0; i < session.fragments.length; i++) {
      if (session.fragments[i] != null) {
        indices.add(i);
      }
    }
    return indices;
  }

  // ── Incoming fragment reception ──────────────────────────────────────────

  /// Add a received [fragment]. New compact fragments rely on prior envelope
  /// metadata for total/format, while legacy fragments can still self-describe.
  ///
  /// Returns true when the session just became complete.
  bool addFragment(ImagePacket fragment, {int width = 0, int height = 0}) {
    if (_ignoredIncomingSessions.contains(fragment.sessionId)) {
      debugPrint(
        '⏹️ [ImageProvider] Ignoring canceled incoming session ${fragment.sessionId}',
      );
      return false;
    }
    _sessions.putIfAbsent(fragment.sessionId, () {
      if (fragment.total < 1) {
        throw StateError(
          'Image envelope missing for compact fragment ${fragment.sessionId}',
        );
      }
      return ImageSession(
        sessionId: fragment.sessionId,
        format: fragment.format,
        total: fragment.total,
        width: width,
        height: height,
      );
    });

    final session = _sessions[fragment.sessionId]!;
    if (fragment.index < session.total) {
      final wasMissing = session.fragments[fragment.index] == null;
      session.fragments[fragment.index] = fragment;
      if (wasMissing) {
        final now = DateTime.now();
        session.firstFragmentAt ??= now;
        session.lastFragmentAt = now;
      }
    }

    final justComplete = session.isComplete;
    unawaited(_persist());
    notifyListeners();
    return justComplete;
  }

  void cancelIncomingSession(String sessionId) {
    _ignoredIncomingSessions.add(sessionId);
    _sessions.remove(sessionId);
    unawaited(_persist());
    notifyListeners();
  }

  void resumeIncomingSession(String sessionId) {
    if (_ignoredIncomingSessions.remove(sessionId)) {
      notifyListeners();
    }
  }

  /// Register envelope metadata for a session (called when IE1 is received
  /// before any binary fragments arrive).
  void registerEnvelope(ImageEnvelope envelope) {
    if (_ignoredIncomingSessions.contains(envelope.sessionId)) {
      return;
    }
    final existing = _sessions[envelope.sessionId];
    if (existing == null) {
      _sessions[envelope.sessionId] = ImageSession(
        sessionId: envelope.sessionId,
        format: envelope.format,
        total: envelope.total,
        width: envelope.width,
        height: envelope.height,
      );
      unawaited(_persist());
      notifyListeners();
      return;
    }

    final needsMerge =
        existing.width == 0 ||
        existing.height == 0 ||
        existing.total != envelope.total ||
        existing.format != envelope.format;
    if (!needsMerge) {
      notifyListeners();
      return;
    }

    final merged = ImageSession(
      sessionId: envelope.sessionId,
      format: envelope.format,
      total: envelope.total,
      width: envelope.width,
      height: envelope.height,
    );
    merged.firstFragmentAt = existing.firstFragmentAt;
    merged.lastFragmentAt = existing.lastFragmentAt;
    for (final fragment in existing.fragments) {
      if (fragment == null) continue;
      if (fragment.index < merged.total) {
        merged.fragments[fragment.index] = fragment;
      }
    }
    _sessions[envelope.sessionId] = merged;
    unawaited(_persist());
    notifyListeners();
  }

  // ── Outgoing session management ──────────────────────────────────────────

  /// Cache encoded fragments for deferred serving.
  ///
  /// Also registers the session as complete in [_sessions] so the local
  /// bubble can display the sent image immediately without a fetch round-trip.
  void cacheOutgoingSession(
    String sessionId,
    List<ImagePacket> fragments,
    ImageEnvelope envelope,
  ) {
    if (fragments.isEmpty) return;
    _evictExpiredOutgoing();
    _outgoing[sessionId] = _OutgoingSession(
      sessionId: sessionId,
      fragments: List<ImagePacket>.from(fragments),
      envelope: envelope,
      cachedAt: DateTime.now(),
    );

    // Populate incoming session so the bubble shows the image right away.
    final session = ImageSession(
      sessionId: sessionId,
      format: envelope.format,
      total: fragments.length,
      width: envelope.width,
      height: envelope.height,
    );
    for (final f in fragments) {
      if (f.index < session.total) session.fragments[f.index] = f;
    }
    _sessions[sessionId] = session;

    unawaited(_persist());
    notifyListeners();
  }

  /// Stream cached image fragments to [requester] via raw binary packets.
  Future<bool> serveSessionTo({
    required String sessionId,
    required Contact requester,
    Set<int>? requestedIndices,
  }) async {
    final outgoing = _outgoing[sessionId];
    final fragments = outgoing != null
        ? List<ImagePacket>.from(outgoing.fragments)
        : _sessions[sessionId]?.fragments.whereType<ImagePacket>().toList() ??
              const <ImagePacket>[];
    if (fragments.isEmpty) {
      debugPrint(
        '⚠️ [ImageProvider] No cached or received session for $sessionId',
      );
      return false;
    }
    return serveCachedSessionFragments<ImagePacket>(
      providerLabel: 'ImageProvider',
      sessionId: sessionId,
      requester: requester,
      fragments: fragments,
      maxDirectPayloadHops: maxDirectPayloadHops,
      indexOf: (fragment) => fragment.index,
      encodeBinary: (fragment) => fragment.encodeBinary(),
      sendRawPacket: sendRawPacketCallback,
      requestedIndices: requestedIndices,
    );
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    _sessions.clear();
    _outgoing.clear();
    _ignoredIncomingSessions.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('❌ [ImageProvider] Failed to clear storage: $e');
    }
  }

  void _evictExpiredOutgoing() {
    final now = DateTime.now();
    _outgoing.removeWhere((_, s) => now.difference(s.cachedAt) > _outgoingTtl);
  }

  Future<void> _persist() async {
    try {
      _evictExpiredOutgoing();
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'incoming': _sessions.values
            .map(
              (s) => {
                'sessionId': s.sessionId,
                'fmtId': s.format.id,
                'total': s.total,
                'width': s.width,
                'height': s.height,
                'fragments': s.fragments
                    .map(
                      (f) => f == null ? null : base64.encode(f.encodeBinary()),
                    )
                    .toList(),
              },
            )
            .toList(),
        'outgoing': _outgoing.values
            .map(
              (s) => {
                'sessionId': s.sessionId,
                'cachedAt': s.cachedAt.millisecondsSinceEpoch,
                'envelope': s.envelope.encode(),
                'fragments': s.fragments
                    .map((f) => base64.encode(f.encodeBinary()))
                    .toList(),
              },
            )
            .toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('❌ [ImageProvider] Failed to persist: $e');
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final parsed = jsonDecode(raw) as Map<String, dynamic>;

      for (final item in (parsed['incoming'] as List<dynamic>? ?? [])) {
        final map = item as Map<String, dynamic>;
        final sessionId = map['sessionId'] as String?;
        final fmtId = map['fmtId'] as int?;
        final total = map['total'] as int?;
        final width = map['width'] as int? ?? 256;
        final height = map['height'] as int? ?? 256;
        if (sessionId == null || fmtId == null || total == null || total <= 0) {
          continue;
        }
        final session = ImageSession(
          sessionId: sessionId,
          format: ImageFormat.fromId(fmtId),
          total: total,
          width: width,
          height: height,
        );
        final frags = map['fragments'] as List<dynamic>? ?? [];
        for (var i = 0; i < frags.length && i < total; i++) {
          final enc = frags[i] as String?;
          if (enc == null || enc.isEmpty) continue;
          final pkt = ImagePacket.tryParseBinary(base64.decode(enc));
          if (pkt != null && pkt.index < total) {
            session.fragments[pkt.index] = pkt;
          }
        }
        _sessions[sessionId] = session;
      }

      for (final item in (parsed['outgoing'] as List<dynamic>? ?? [])) {
        final map = item as Map<String, dynamic>;
        final sessionId = map['sessionId'] as String?;
        final cachedMs = map['cachedAt'] as int?;
        final envelopeText = map['envelope'] as String?;
        if (sessionId == null || cachedMs == null || envelopeText == null) {
          continue;
        }
        final envelope = ImageEnvelope.tryParse(envelopeText);
        if (envelope == null) continue;
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedMs);
        if (DateTime.now().difference(cachedAt) > _outgoingTtl) continue;

        final fragsRaw = map['fragments'] as List<dynamic>? ?? [];
        final fragments = <ImagePacket>[];
        for (final enc in fragsRaw) {
          final pkt = ImagePacket.tryParseBinary(
            base64.decode((enc ?? '') as String),
          );
          if (pkt != null) fragments.add(pkt);
        }
        if (fragments.isNotEmpty) {
          _outgoing[sessionId] = _OutgoingSession(
            sessionId: sessionId,
            fragments: fragments,
            envelope: envelope,
            cachedAt: cachedAt,
          );
        }
      }

      if (_sessions.isNotEmpty || _outgoing.isNotEmpty) {
        debugPrint(
          '📷 [ImageProvider] Restored ${_sessions.length} incoming, '
          '${_outgoing.length} outgoing sessions',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [ImageProvider] Failed to restore: $e');
    }
  }
}

class _OutgoingSession {
  final String sessionId;
  final List<ImagePacket> fragments;
  final ImageEnvelope envelope;
  final DateTime cachedAt;

  const _OutgoingSession({
    required this.sessionId,
    required this.fragments,
    required this.envelope,
    required this.cachedAt,
  });
}
