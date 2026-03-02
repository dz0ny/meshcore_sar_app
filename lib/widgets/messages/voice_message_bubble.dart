import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/voice_provider.dart';
import '../../utils/voice_message_parser.dart';

/// A message bubble that shows a voice recording with play/stop controls.
class VoiceMessageBubble extends StatefulWidget {
  final Message message;
  final bool isSentByMe;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  bool _isRequesting = false;
  bool _autoPlayWhenReady = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final radioBw = context.select<ConnectionProvider, int?>(
      (p) => p.deviceInfo.radioBw,
    );
    final radioSf = context.select<ConnectionProvider, int?>(
      (p) => p.deviceInfo.radioSf,
    );
    final radioCr = context.select<ConnectionProvider, int?>(
      (p) => p.deviceInfo.radioCr,
    );
    final voiceId = widget.message.voiceId;
    if (voiceId == null) return const SizedBox.shrink();

    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, _) {
        final session = voiceProvider.session(voiceId);
        final envelope = VoiceEnvelope.tryParseText(widget.message.text);
        final isPlaying = voiceProvider.isPlaying(voiceId);
        final isComplete = voiceProvider.isComplete(voiceId);

        if (_isRequesting && isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _isRequesting = false;
            });
          });
        }

        if (_autoPlayWhenReady && isComplete && !isPlaying) {
          _autoPlayWhenReady = false;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await voiceProvider.play(voiceId);
          });
        }

        final received = session?.receivedCount ?? 0;
        final total = session?.total ?? envelope?.total ?? 0;
        final playbackProgress = voiceProvider.playbackProgress(voiceId);
        final requestProgress = total > 0
            ? (received / total).clamp(0.0, 1.0)
            : null;
        final durationSec =
            session?.estimatedDurationSeconds ??
            ((envelope?.durationMs ?? 0) / 1000.0);
        final durationLabel = _formatDuration(durationSec);
        final modeLabel = session?.mode.label ?? envelope?.mode.label ?? '?';
        final waveformBars = _resolveWaveformBars(
          session: session,
          messageText: widget.message.text,
        );
        final txEstimate = _resolveVoiceTransmitEstimate(
          session: session,
          envelope: envelope,
          messageText: widget.message.text,
          pathLen: widget.message.pathLen,
          radioBw: radioBw,
          radioSf: radioSf,
          radioCr: radioCr,
        );
        final txEstimateLabel = _formatTransmitEstimate(txEstimate);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                if (isPlaying) {
                  await voiceProvider.stop();
                  return;
                }
                if (isComplete) {
                  await voiceProvider.play(voiceId);
                  return;
                }
                await _requestAndPlayVoice(voiceId);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isSentByMe
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying
                      ? Icons.stop
                      : (_isRequesting ? Icons.downloading : Icons.play_arrow),
                  size: 28,
                  color: widget.isSentByMe
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPlaying || _isRequesting)
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: isPlaying ? playbackProgress : requestProgress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                  )
                else
                  _WaveformBar(isComplete: isComplete, bars: waveformBars),
                const SizedBox(height: 4),
                Text(
                  _buildStatusText(
                    durationLabel: durationLabel,
                    modeLabel: modeLabel,
                    txEstimateLabel: txEstimateLabel,
                    received: received,
                    total: total,
                    isComplete: isComplete,
                    isRequesting: _isRequesting,
                    errorText: _errorText,
                    requestingLabel: AppLocalizations.of(
                      context,
                    )!.requestingVoice,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestAndPlayVoice(String sessionId) async {
    if (_isRequesting) return;
    final sender = _resolveSenderContact();
    if (sender == null) {
      _setUnavailable();
      return;
    }

    final connectionProvider = context.read<ConnectionProvider>();
    final deviceKey = connectionProvider.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      _setUnavailable();
      return;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final request = VoiceFetchRequest(
      sessionId: sessionId,
      requesterKey6: requesterKey6,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      version: 1,
    );

    setState(() {
      _isRequesting = true;
      _autoPlayWhenReady = true;
      _errorText = null;
    });

    final sent = await connectionProvider.sendTextMessage(
      contactPublicKey: sender.publicKey,
      text: request.encodeText(),
      contact: sender,
    );
    if (!sent) {
      _setUnavailable();
    }
  }

  void _setUnavailable() {
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _autoPlayWhenReady = false;
      _errorText = AppLocalizations.of(context)!.voiceUnavailable;
    });
  }

  Contact? _resolveSenderContact() {
    final contactsProvider = context.read<ContactsProvider>();
    final senderPrefix = widget.message.senderPublicKeyPrefix;
    if (senderPrefix != null && senderPrefix.length >= 6) {
      final contact = contactsProvider.findContactByPrefix(
        Uint8List.fromList(senderPrefix.sublist(0, 6)),
      );
      if (contact != null) return contact;
    }

    final envelope = VoiceEnvelope.tryParseText(widget.message.text);
    if (envelope != null) {
      final contact = contactsProvider.findContactByPrefixHex(
        envelope.senderKey6,
      );
      if (contact != null) return contact;
    }

    return null;
  }

  static String _formatDuration(double seconds) {
    final s = seconds.round();
    if (s < 60) return '${s}s';
    return '${s ~/ 60}m ${s % 60}s';
  }

  static String _buildStatusText({
    required String durationLabel,
    required String modeLabel,
    required String txEstimateLabel,
    required int received,
    required int total,
    required bool isComplete,
    required bool isRequesting,
    required String? errorText,
    required String requestingLabel,
  }) {
    if (errorText != null) return errorText;
    final progress = total > 0 ? ' ($received/$total)' : '';
    if (isRequesting) {
      return '$requestingLabel$progress · $txEstimateLabel';
    }
    if (!isComplete && total > 0) {
      return '🎙️ $durationLabel · $modeLabel$progress · $txEstimateLabel';
    }
    return '🎙️ $durationLabel · $modeLabel · $txEstimateLabel';
  }

  List<double> _resolveWaveformBars({
    required VoiceSession? session,
    required String messageText,
  }) {
    if (session != null) {
      final fromSession = VoiceWaveform.buildBarsFromPackets(session.packets);
      if (fromSession.any((v) => v > 0.0)) return fromSession;
    }

    final legacyPacket = VoicePacket.tryParseText(messageText);
    if (legacyPacket != null) {
      final fromLegacy = VoiceWaveform.buildBarsFromPackets([legacyPacket]);
      if (fromLegacy.any((v) => v > 0.0)) return fromLegacy;
    }

    return const [];
  }

  Duration _resolveVoiceTransmitEstimate({
    required VoiceSession? session,
    required VoiceEnvelope? envelope,
    required String messageText,
    required int pathLen,
    required int? radioBw,
    required int? radioSf,
    required int? radioCr,
  }) {
    if (session != null) {
      final fromSession = estimateVoiceTransmitDurationFromPackets(
        packets: session.packets,
        pathLen: pathLen,
        radioBw: radioBw,
        radioSf: radioSf,
        radioCr: radioCr,
      );
      if (fromSession > Duration.zero) return fromSession;
    }

    if (envelope != null) {
      return estimateVoiceTransmitDuration(
        mode: envelope.mode,
        packetCount: envelope.total,
        durationMs: envelope.durationMs,
        pathLen: pathLen,
        radioBw: radioBw,
        radioSf: radioSf,
        radioCr: radioCr,
      );
    }

    final legacyPacket = VoicePacket.tryParseText(messageText);
    if (legacyPacket != null) {
      return estimateVoiceTransmitDuration(
        mode: legacyPacket.mode,
        packetCount: legacyPacket.total,
        durationMs: legacyPacket.durationMs * legacyPacket.total,
        pathLen: pathLen,
        radioBw: radioBw,
        radioSf: radioSf,
        radioCr: radioCr,
      );
    }
    return Duration.zero;
  }

  static String _formatTransmitEstimate(Duration value) {
    if (value <= Duration.zero) return '~0s tx';
    if (value.inSeconds < 60) return '~${value.inSeconds}s tx';
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    return '~${minutes}m ${seconds}s tx';
  }
}

/// Voice waveform rendered as a row of bars.
class _WaveformBar extends StatelessWidget {
  final bool isComplete;
  final List<double> bars;
  const _WaveformBar({required this.isComplete, required this.bars});

  @override
  Widget build(BuildContext context) {
    final heights = bars.isEmpty
        ? const [8.0, 12.0, 10.0, 14.0, 9.0, 12.0, 8.0, 11.0, 10.0, 13.0]
        : bars.map((v) => 6.0 + (v.clamp(0.0, 1.0) * 14.0)).toList();
    final color = isComplete
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
        : Colors.grey.withValues(alpha: 0.5);
    return Row(
      children: heights
          .map(
            (h) => Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
          .toList(),
    );
  }
}
