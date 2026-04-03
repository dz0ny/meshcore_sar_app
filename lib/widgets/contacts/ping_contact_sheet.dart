import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/contact.dart';
import '../../providers/connection_provider.dart';
import '../../services/location_tracking_service.dart';
import '../../utils/link_quality.dart';
import '../../utils/time_ago_extensions.dart';

class PingContactSheet extends StatefulWidget {
  final Contact contact;

  const PingContactSheet({super.key, required this.contact});

  @override
  State<PingContactSheet> createState() => _PingContactSheetState();
}

class _PingEntry {
  final RelayPingResult result;
  final DateTime timestamp;
  final String? distance;

  const _PingEntry({
    required this.result,
    required this.timestamp,
    this.distance,
  });
}

class _PingContactSheetState extends State<PingContactSheet> {
  static const Duration _autoPingInterval = Duration(seconds: 2);
  static const Duration _maxAutoPingDelay = Duration(seconds: 5);
  static const int _maxHistoryEntries = 24;
  static const double _maxHistoryHeight = 320;
  static const Duration _timeoutPenalty = Duration(seconds: 10);

  bool _pinging = false;
  bool _autoPingEnabled = false;
  final List<_PingEntry> _history = [];
  final _PingCuePlayer _cuePlayer = _PingCuePlayer();
  Timer? _autoPingTimer;

  @override
  void initState() {
    super.initState();
    _doPing();
  }

  @override
  void dispose() {
    _autoPingTimer?.cancel();
    _cuePlayer.dispose();
    super.dispose();
  }

  Future<void> _doPing() async {
    if (_pinging) {
      return;
    }
    setState(() => _pinging = true);
    final connectionProvider = context.read<ConnectionProvider>();
    final distance = _distanceText();
    final result = await connectionProvider.pingRelay(widget.contact);
    if (!mounted) return;
    setState(() {
      _pinging = false;
      _history.insert(
        0,
        _PingEntry(
          result: result,
          timestamp: DateTime.now(),
          distance: distance,
        ),
      );
      if (_history.length > _maxHistoryEntries) {
        _history.removeRange(_maxHistoryEntries, _history.length);
      }
    });
    await _maybePlayCue(result);
    _scheduleNextAutoPing(result);
  }

  Future<void> _maybePlayCue(RelayPingResult result) async {
    if (!_autoPingEnabled) {
      return;
    }

    final previous = _history.length >= 2 ? _history[1].result : null;
    await _cuePlayer.playCue(result, previous: previous);
  }

  void _setAutoPingEnabled(bool enabled) {
    setState(() {
      _autoPingEnabled = enabled;
    });
    _autoPingTimer?.cancel();
    if (!enabled) {
      return;
    }
    _scheduleNextAutoPing();
  }

  void _scheduleNextAutoPing([RelayPingResult? result]) {
    _autoPingTimer?.cancel();
    if (!_autoPingEnabled || !mounted) {
      return;
    }
    final responseDelay = result == null
        ? Duration.zero
        : result.success
        ? Duration(milliseconds: result.durationMs)
        : _timeoutPenalty;
    final nextDelay = _autoPingInterval + responseDelay;
    final clampedDelay = nextDelay > _maxAutoPingDelay
        ? _maxAutoPingDelay
        : nextDelay;
    _autoPingTimer = Timer(clampedDelay, () {
      unawaited(_doPing());
    });
  }

  String? _distanceText() {
    final location = widget.contact.displayLocation;
    if (location == null) return null;
    final currentPosition = LocationTrackingService().currentPosition;
    if (currentPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      location.latitude,
      location.longitude,
    );
    if (meters < 1000) return '${meters.round()} m';
    if (meters < 10000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnrPill(BuildContext context, String direction, double snrDb) {
    final quality = linkQualityLabel(null, snrDb);
    final color = linkQualityColor(quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            direction == 'there'
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${snrDb.toStringAsFixed(1)} dB',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, _PingEntry entry, int seq) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = entry.result;
    final age = DateTime.now().difference(entry.timestamp);
    final timeAgo = age.toLocalizedTimeAgoWithSeconds(context);

    if (!r.success) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: colorScheme.error.withValues(alpha: 0.15),
              child: Text(
                '$seq',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Timeout',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              timeAgo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Text(
                  '$seq',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildPill(
                context,
                icon: Icons.timer_outlined,
                label: '${r.durationMs} ms',
              ),
              const SizedBox(width: 6),
              _buildSnrPill(context, 'there', r.snrThere),
              const SizedBox(width: 6),
              _buildSnrPill(context, 'back', r.snrBack),
              const Spacer(),
              Text(
                timeAgo,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Row(
              children: [
                if (entry.distance != null) ...[
                  Icon(
                    Icons.straighten,
                    size: 10,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    entry.distance!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ping ${widget.contact.displayName}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _pinging ? null : _doPing,
                  icon: _pinging
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.network_ping, size: 18),
                  label: Text(_pinging ? 'Pinging...' : 'Ping again'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.contact.publicKeyShort,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _autoPingEnabled
                        ? Icons.radar_rounded
                        : Icons.radar_outlined,
                    color: _autoPingEnabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto ping',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '2s sonar cues for there/back SNR',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _autoPingEnabled,
                    onChanged: _setAutoPingEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_history.isEmpty && !_pinging)
              Text(
                'No ping results yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: _maxHistoryHeight,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _history.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) =>
                      _buildResultRow(context, _history[index], index + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PingCuePlayer {
  static const double _fairSnrThresholdDb = 0;

  AudioPlayer? _player;

  Future<void> playCue(
    RelayPingResult result, {
    RelayPingResult? previous,
  }) async {
    _player ??= AudioPlayer();
    final player = _player!;
    final filePath = await _writeCueFile(
      result,
      previous: previous,
    );
    await player.stop();
    await player.setVolume(1.0);
    await player.play(DeviceFileSource(filePath));
  }

  Future<String> _writeCueFile(
    RelayPingResult result, {
    RelayPingResult? previous,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/ping_sonar_alert.wav');
    final samples = _buildCueSamples(result, previous: previous);
    final wavBytes = _buildWav(samples, sampleRate: 16000);
    await file.writeAsBytes(wavBytes, flush: true);
    return file.path;
  }

  Int16List _buildCueSamples(
    RelayPingResult result, {
    RelayPingResult? previous,
  }) {
    const sampleRate = 16000;
    final segments = <double>[];
    if (!result.success) {
      segments.addAll(
        _timeoutAlert(sampleRate),
      );
    } else {
      segments.addAll(
        _tone(
          sampleRate,
          frequencyHz: _frequencyForSnr(result.snrThere),
          durationMs: 90,
          amplitude: 0.42,
        ),
      );
      segments.addAll(_silence(sampleRate, durationMs: 35));
      segments.addAll(
        _tone(
          sampleRate,
          frequencyHz: _frequencyForSnr(result.snrBack),
          durationMs: 90,
          amplitude: 0.42,
        ),
      );
      final belowFair =
          result.snrThere < _fairSnrThresholdDb &&
          result.snrBack < _fairSnrThresholdDb;
      final worsening =
          previous != null &&
          result.snrThere < previous.snrThere &&
          result.snrBack < previous.snrBack;
      if (belowFair && worsening) {
        segments.addAll(_silence(sampleRate, durationMs: 40));
        segments.addAll(
          _descendingAlert(sampleRate, baseFrequencyHz: 520),
        );
      }
    }
    final pcm = Int16List(segments.length);
    for (var i = 0; i < segments.length; i++) {
      pcm[i] = (segments[i] * 32767).round().clamp(-32768, 32767);
    }
    return pcm;
  }

  double _frequencyForSnr(double snrDb) {
    final clamped = snrDb.clamp(-12.0, 12.0);
    final normalized = (clamped + 12.0) / 24.0;
    return 320 + (normalized * 900);
  }

  List<double> _descendingAlert(int sampleRate, {required double baseFrequencyHz}) {
    return <double>[
      ..._tone(
        sampleRate,
        frequencyHz: baseFrequencyHz,
        durationMs: 80,
        amplitude: 0.44,
      ),
      ..._silence(sampleRate, durationMs: 30),
      ..._tone(
        sampleRate,
        frequencyHz: baseFrequencyHz * 0.82,
        durationMs: 110,
        amplitude: 0.40,
      ),
    ];
  }

  List<double> _timeoutAlert(int sampleRate) {
    return <double>[
      ..._tone(
        sampleRate,
        frequencyHz: 240,
        durationMs: 180,
        amplitude: 0.46,
      ),
      ..._silence(sampleRate, durationMs: 60),
      ..._tone(
        sampleRate,
        frequencyHz: 180,
        durationMs: 220,
        amplitude: 0.52,
      ),
    ];
  }

  List<double> _tone(
    int sampleRate, {
    required double frequencyHz,
    required int durationMs,
    required double amplitude,
  }) {
    final sampleCount = (sampleRate * durationMs / 1000).round();
    return List<double>.generate(sampleCount, (index) {
      final t = index / sampleRate;
      final envelope = math.sin(math.pi * index / sampleCount);
      return math.sin(2 * math.pi * frequencyHz * t) * amplitude * envelope;
    });
  }

  List<double> _silence(int sampleRate, {required int durationMs}) {
    final sampleCount = (sampleRate * durationMs / 1000).round();
    return List<double>.filled(sampleCount, 0);
  }

  Uint8List _buildWav(Int16List samples, {required int sampleRate}) {
    const numChannels = 1;
    const bitsPerSample = 16;
    const audioFormat = 1;
    final dataSize = samples.length * 2;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final totalSize = 36 + dataSize;
    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    void writeString(String value) {
      for (final codeUnit in value.codeUnits) {
        buffer.setUint8(offset++, codeUnit);
      }
    }

    void writeUint32(int value) {
      buffer.setUint32(offset, value, Endian.little);
      offset += 4;
    }

    void writeUint16(int value) {
      buffer.setUint16(offset, value, Endian.little);
      offset += 2;
    }

    writeString('RIFF');
    writeUint32(totalSize);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(audioFormat);
    writeUint16(numChannels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(blockAlign);
    writeUint16(bitsPerSample);
    writeString('data');
    writeUint32(dataSize);

    for (final sample in samples) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _player?.dispose();
  }
}
