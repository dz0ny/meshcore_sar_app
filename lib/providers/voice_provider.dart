import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import 'helpers/raw_session_retransmit.dart';
import '../utils/voice_message_parser.dart';
import '../services/voice_codec_service.dart';
import '../services/voice_player_service.dart';

/// Reassembly state for one voice session.
class VoiceSession {
  final String sessionId;
  final VoicePacketMode mode;
  final int total;
  final List<VoicePacket?> packets; // indexed by packet.index
  DateTime? firstPacketAt;
  DateTime? lastPacketAt;

  VoiceSession({
    required this.sessionId,
    required this.mode,
    required this.total,
  }) : packets = List.filled(total, null);

  int get receivedCount => packets.where((p) => p != null).length;
  bool get isComplete => receivedCount == total;

  Duration? estimateRemaining() {
    if (isComplete) return Duration.zero;
    if (firstPacketAt == null || lastPacketAt == null) return null;
    if (receivedCount < 2) return null;

    final elapsedMs = lastPacketAt!.difference(firstPacketAt!).inMilliseconds;
    if (elapsedMs <= 0) return null;
    final avgMsPerPacket = elapsedMs / (receivedCount - 1);
    final remaining = total - receivedCount;
    if (remaining <= 0) return Duration.zero;
    return Duration(milliseconds: (avgMsPerPacket * remaining).round());
  }

  /// Total estimated audio duration in seconds (sum of all received packets).
  double get estimatedDurationSeconds {
    var ms = 0;
    for (final p in packets) {
      if (p != null) ms += p.durationMs;
    }
    return ms / 1000.0;
  }
}

/// Manages incoming voice packet sessions and coordinates playback.
class VoiceProvider with ChangeNotifier {
  static const String _voiceSessionsStorageKey = 'stored_voice_sessions_v1';
  static const int maxDirectPayloadHops = 3;
  final VoiceCodecService _codec;
  final VoicePlayerService _player;
  late final StreamSubscription<void> _playerEventsSub;

  /// Active sessions keyed by sessionId.
  final Map<String, VoiceSession> _sessions = {};
  final Set<String> _ignoredIncomingSessions = {};

  /// Currently playing session ID, or null.
  String? _playingSessionId;

  /// Hook for sending a raw voice payload to a destination contact path.
  Future<void> Function({
    required Uint8List contactPath,
    required int contactPathLen,
    required Uint8List payload,
  })?
  sendRawPacketCallback;

  final Map<String, _OutgoingVoiceSession> _outgoingSessions = {};

  VoiceProvider({
    required VoiceCodecService codec,
    required VoicePlayerService player,
  }) : _codec = codec,
       _player = player {
    _playerEventsSub = _player.events.listen((_) {
      if (_playingSessionId != null &&
          !_player.isPlaying &&
          _player.duration.inMilliseconds > 0 &&
          _player.position >= _player.duration) {
        _playingSessionId = null;
      }
      notifyListeners();
    });
    _restorePersistedVoiceData();
  }

  // ── Session accessors ────────────────────────────────────────────────────

  VoiceSession? session(String sessionId) => _sessions[sessionId];
  bool isComplete(String sessionId) =>
      _sessions[sessionId]?.isComplete ?? false;
  bool isPlaying(String sessionId) => _playingSessionId == sessionId;
  Duration get playbackPosition => _player.position;
  Duration get playbackDuration => _player.duration;

  double playbackProgress(String sessionId) {
    if (_playingSessionId != sessionId) return 0.0;
    final totalMs = _player.duration.inMilliseconds;
    if (totalMs <= 0) return 0.0;
    final posMs = _player.position.inMilliseconds.clamp(0, totalMs);
    return posMs / totalMs;
  }

  bool hasOutgoingSession(String sessionId) =>
      _outgoingSessions.containsKey(sessionId);
  Duration? estimateRemainingTransferTime(String sessionId) =>
      _sessions[sessionId]?.estimateRemaining();
  bool isReceiveCanceled(String sessionId) =>
      _ignoredIncomingSessions.contains(sessionId);

  List<int> missingPacketIndices(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) return const [];
    final missing = <int>[];
    for (var i = 0; i < session.total; i++) {
      if (session.packets[i] == null) missing.add(i);
    }
    return missing;
  }

  List<int> availablePacketIndices(String sessionId) {
    final outgoing = _outgoingSessions[sessionId];
    if (outgoing != null) {
      return outgoing.packets.map((packet) => packet.index).toList()..sort();
    }

    final session = _sessions[sessionId];
    if (session == null) return const [];
    final indices = <int>[];
    for (var i = 0; i < session.packets.length; i++) {
      if (session.packets[i] != null) {
        indices.add(i);
      }
    }
    return indices;
  }

  // ── Packet reception ─────────────────────────────────────────────────────

  /// Add an incoming [packet] to its session.  Creates the session on first packet.
  /// Returns true if the session just became complete.
  bool addPacket(VoicePacket packet) {
    if (_ignoredIncomingSessions.contains(packet.sessionId)) {
      debugPrint(
        '⏹️ [VoiceProvider] Ignoring canceled incoming session ${packet.sessionId}',
      );
      return false;
    }
    _sessions.putIfAbsent(packet.sessionId, () {
      if (packet.total < 1) {
        throw StateError(
          'Voice envelope missing for compact packet ${packet.sessionId}',
        );
      }
      return VoiceSession(
        sessionId: packet.sessionId,
        mode: packet.mode,
        total: packet.total,
      );
    });

    final session = _sessions[packet.sessionId]!;
    if (packet.index < session.total) {
      final wasMissing = session.packets[packet.index] == null;
      session.packets[packet.index] = packet;
      if (wasMissing) {
        final now = DateTime.now();
        session.firstPacketAt ??= now;
        session.lastPacketAt = now;
      }
    }

    final justComplete = session.isComplete;
    _persistVoiceData();
    notifyListeners();
    return justComplete;
  }

  void cancelIncomingSession(String sessionId) {
    _ignoredIncomingSessions.add(sessionId);
    _sessions.remove(sessionId);
    if (_playingSessionId == sessionId) {
      unawaited(_player.stop());
      _playingSessionId = null;
    }
    _persistVoiceData();
    notifyListeners();
  }

  void resumeIncomingSession(String sessionId) {
    if (_ignoredIncomingSessions.remove(sessionId)) {
      notifyListeners();
    }
  }

  void registerEnvelope(VoiceEnvelope envelope) {
    if (_ignoredIncomingSessions.contains(envelope.sessionId)) {
      return;
    }
    final existing = _sessions[envelope.sessionId];
    if (existing == null) {
      _sessions[envelope.sessionId] = VoiceSession(
        sessionId: envelope.sessionId,
        mode: envelope.mode,
        total: envelope.total,
      );
      _persistVoiceData();
      notifyListeners();
      return;
    }

    final needsMerge =
        existing.total != envelope.total || existing.mode != envelope.mode;
    if (!needsMerge) {
      notifyListeners();
      return;
    }

    final merged = VoiceSession(
      sessionId: envelope.sessionId,
      mode: envelope.mode,
      total: envelope.total,
    );
    merged.firstPacketAt = existing.firstPacketAt;
    merged.lastPacketAt = existing.lastPacketAt;
    for (final packet in existing.packets) {
      if (packet == null) continue;
      if (packet.index < merged.total) {
        merged.packets[packet.index] = packet;
      }
    }
    _sessions[envelope.sessionId] = merged;
    _persistVoiceData();
    notifyListeners();
  }

  /// Cache encoded packets for deferred voice serving.
  void cacheOutgoingSession(String sessionId, List<VoicePacket> packets) {
    if (packets.isEmpty) return;
    _outgoingSessions[sessionId] = _OutgoingVoiceSession(
      sessionId: sessionId,
      packets: List<VoicePacket>.from(packets),
    );
    _persistVoiceData();
  }

  /// Stream a cached voice session to a requester over raw direct packets.
  Future<bool> serveSessionTo({
    required String sessionId,
    required Contact requester,
    Set<int>? requestedIndices,
  }) async {
    final outgoing = _outgoingSessions[sessionId];
    final packets = outgoing != null
        ? List<VoicePacket>.from(outgoing.packets)
        : _sessions[sessionId]?.packets.whereType<VoicePacket>().toList() ??
              const <VoicePacket>[];
    if (packets.isEmpty) {
      debugPrint(
        '⚠️ [VoiceProvider] No cached or received session for $sessionId',
      );
      return false;
    }
    return serveCachedSessionFragments<VoicePacket>(
      providerLabel: 'VoiceProvider',
      sessionId: sessionId,
      requester: requester,
      fragments: packets,
      maxDirectPayloadHops: maxDirectPayloadHops,
      indexOf: (packet) => packet.index,
      encodeBinary: (packet) => packet.encodeBinary(),
      sendRawPacket: sendRawPacketCallback,
      requestedIndices: requestedIndices,
    );
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  /// Decode and play the voice session with [sessionId].
  /// Plays whatever packets are available (handles partial reception gracefully).
  Future<void> play(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null) {
      debugPrint(
        '❌ [VoiceProvider] play($sessionId) — session not found, known: ${_sessions.keys.toList()}',
      );
      return;
    }

    debugPrint(
      '🎙️ [VoiceProvider] play($sessionId): ${session.receivedCount}/${session.total} packets, mode=${session.mode.label}',
    );

    try {
      final pcm = await _codec.decodePackets(session.packets, session.mode);
      debugPrint('🎙️ [VoiceProvider] decoded ${pcm.length} PCM samples');
      _playingSessionId = sessionId;
      notifyListeners();
      await _player.play(pcm);
    } catch (e, st) {
      debugPrint('❌ [VoiceProvider] Playback error: $e\n$st');
      if (_playingSessionId == sessionId) {
        _playingSessionId = null;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playingSessionId = null;
    notifyListeners();
  }

  Future<void> clearStoredVoiceData() async {
    _sessions.clear();
    _outgoingSessions.clear();
    _ignoredIncomingSessions.clear();
    _playingSessionId = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_voiceSessionsStorageKey);
    } catch (e) {
      debugPrint('❌ [VoiceProvider] Failed to clear stored voice data: $e');
    }
  }

  Future<void> _persistVoiceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'incoming': _sessions.values
            .map(
              (session) => {
                'sessionId': session.sessionId,
                'modeId': session.mode.id,
                'total': session.total,
                'packets': session.packets.map((p) => p?.encodeText()).toList(),
              },
            )
            .toList(),
        'outgoing': _outgoingSessions.values
            .map(
              (session) => {
                'sessionId': session.sessionId,
                'packets': session.packets.map((p) => p.encodeText()).toList(),
              },
            )
            .toList(),
      };
      await prefs.setString(_voiceSessionsStorageKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('❌ [VoiceProvider] Failed to persist voice data: $e');
    }
  }

  Future<void> _restorePersistedVoiceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_voiceSessionsStorageKey);
      if (raw == null || raw.isEmpty) return;

      final parsed = jsonDecode(raw) as Map<String, dynamic>;

      final incoming = parsed['incoming'] as List<dynamic>? ?? const [];
      for (final item in incoming) {
        final map = item as Map<String, dynamic>;
        final sessionId = map['sessionId'] as String?;
        final modeId = map['modeId'] as int?;
        final total = map['total'] as int?;
        if (sessionId == null ||
            modeId == null ||
            total == null ||
            total <= 0) {
          continue;
        }
        final mode = VoicePacketMode.fromId(modeId);
        final session = VoiceSession(
          sessionId: sessionId,
          mode: mode,
          total: total,
        );
        final packets = map['packets'] as List<dynamic>? ?? const [];
        for (var i = 0; i < packets.length && i < session.total; i++) {
          final encoded = packets[i] as String?;
          if (encoded == null || encoded.isEmpty) continue;
          final packet = VoicePacket.tryParseText(encoded);
          if (packet != null && packet.index < session.total) {
            session.packets[packet.index] = packet;
          }
        }
        _sessions[sessionId] = session;
      }

      final outgoing = parsed['outgoing'] as List<dynamic>? ?? const [];
      for (final item in outgoing) {
        final map = item as Map<String, dynamic>;
        final sessionId = map['sessionId'] as String?;
        if (sessionId == null || sessionId.isEmpty) continue;
        final packetsRaw = map['packets'] as List<dynamic>? ?? const [];
        final packets = <VoicePacket>[];
        for (final encoded in packetsRaw) {
          final packet = VoicePacket.tryParseText((encoded ?? '') as String);
          if (packet != null) packets.add(packet);
        }
        if (packets.isNotEmpty) {
          _outgoingSessions[sessionId] = _OutgoingVoiceSession(
            sessionId: sessionId,
            packets: packets,
          );
        }
      }

      notifyListeners();
      debugPrint(
        '🎙️ [VoiceProvider] Restored ${_sessions.length} incoming and ${_outgoingSessions.length} outgoing voice sessions',
      );
    } catch (e) {
      debugPrint('❌ [VoiceProvider] Failed to restore voice data: $e');
    }
  }

  @override
  void dispose() {
    _playerEventsSub.cancel();
    _player.dispose();
    super.dispose();
  }
}

class _OutgoingVoiceSession {
  final String sessionId;
  final List<VoicePacket> packets;

  const _OutgoingVoiceSession({required this.sessionId, required this.packets});
}
