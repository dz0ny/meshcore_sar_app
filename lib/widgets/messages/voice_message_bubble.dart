import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/app_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/voice_provider.dart';
import '../../utils/transmission_target_resolver.dart';
import '../../utils/voice_message_parser.dart';
import 'transfer_timeout.dart';

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
  static const int _maxFetchHops = 3;
  static const Duration _recentInboundActivityWindow = Duration(seconds: 3);
  bool _isRequesting = false;
  bool _isPartialRequest = false;
  bool _autoPlayWhenReady = false;
  String? _errorText;
  Timer? _requestTimeoutTimer;

  @override
  void dispose() {
    _requestTimeoutTimer?.cancel();
    super.dispose();
  }

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
        final transferCount = context.select<MessagesProvider, int>(
          (provider) =>
              provider.transferCountForSession(voiceSessionId: voiceId),
        );
        final contactsProvider = context.read<ContactsProvider>();
        final session = voiceProvider.session(voiceId);
        final envelope = VoiceEnvelope.tryParseText(widget.message.text);
        final sender = TransmissionTargetResolver.resolveLocalTarget(
          contactsProvider: contactsProvider,
          isSentByMe: widget.isSentByMe,
          recipientPublicKey: widget.message.recipientPublicKey,
          senderPublicKeyPrefix: widget.message.senderPublicKeyPrefix,
          senderName: widget.message.senderName,
        );
        final effectivePathLen = sender != null && sender.routeHasPath
            ? sender.routeHopCount
            : widget.message.pathLen;
        final isPlaying = voiceProvider.isPlaying(voiceId);
        final isComplete = voiceProvider.isComplete(voiceId);

        if (_isRequesting && isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _isRequesting = false;
              _isPartialRequest = false;
              _errorText = null;
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
        final packetPresence =
            session?.packets.map((packet) => packet != null).toList() ??
            List<bool>.filled(total, false);
        final isReceivingData =
            !_isRequesting &&
            !isComplete &&
            _hasRecentInboundActivity(
              lastReceivedAt: session?.lastPacketAt,
              received: received,
              total: total,
            );
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
          pathLen: effectivePathLen,
          radioBw: radioBw,
          radioSf: radioSf,
          radioCr: radioCr,
        );
        final txEstimateLabel = _formatTransmitEstimate(txEstimate);
        final eta = voiceProvider.estimateRemainingTransferTime(voiceId);

        Future<void> handlePrimaryTap() async {
          if (isPlaying) {
            await voiceProvider.stop();
            return;
          }
          if (_isRequesting) {
            _cancelReceive(voiceId);
            return;
          }
          if (isComplete) {
            await voiceProvider.play(voiceId);
            return;
          }
          if (isReceivingData) {
            return;
          }
          await _requestAndPlayVoice(
            voiceId,
            envelope: envelope,
            radioBw: radioBw,
            radioSf: radioSf,
            radioCr: radioCr,
            pathLen: effectivePathLen,
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: handlePrimaryTap,
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
                      : (_isRequesting
                            ? Icons.close
                            : (isReceivingData
                                  ? Icons.downloading_rounded
                                  : Icons.play_arrow)),
                  size: 28,
                  color: widget.isSentByMe
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer
                            .withValues(alpha: isReceivingData ? 0.6 : 1.0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPlaying)
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: playbackProgress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                  )
                else if ((_isRequesting || isReceivingData) && total > 0)
                  _PacketBlockProgress(
                    presence: packetPresence,
                    activeColor: widget.isSentByMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                    highlightMissing: _isPartialRequest,
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
                    isReceivingData: isReceivingData,
                    isPartialRequest: _isPartialRequest,
                    errorText: _errorText,
                    requestingLabel: AppLocalizations.of(
                      context,
                    )!.requestingVoice,
                    eta: eta,
                    isSentByMe: widget.isSentByMe,
                    transferCount: transferCount,
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

  Future<void> _requestAndPlayVoice(
    String sessionId, {
    VoiceEnvelope? envelope,
    int? radioBw,
    int? radioSf,
    int? radioCr,
    int pathLen = 0,
  }) async {
    if (_isRequesting) return;
    setState(() {
      _isRequesting = true;
      _isPartialRequest = false;
      _autoPlayWhenReady = true;
      _errorText = null;
    });

    final connectionProvider = context.read<ConnectionProvider>();
    final voiceProvider = context.read<VoiceProvider>();
    voiceProvider.resumeIncomingSession(sessionId);
    final contactsProvider = context.read<ContactsProvider>();
    final appProvider = context.read<AppProvider>();
    var resolution = await TransmissionTargetResolver.resolveFetchTarget(
      contactsProvider: contactsProvider,
      refreshContacts: connectionProvider.getContacts,
      isSentByMe: widget.isSentByMe,
      recipientPublicKey: widget.message.recipientPublicKey,
      senderPublicKeyPrefix: widget.message.senderPublicKeyPrefix,
      senderName: widget.message.senderName,
      maxFetchHops: _maxFetchHops,
    );
    if (!mounted) return;

    if (resolution.failure == TransmissionTargetFailure.unknownContact) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch voice',
        'Sender contact is unknown. Sync contacts first.',
      );
      return;
    }
    if (resolution.failure == TransmissionTargetFailure.unknownRoute) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch voice',
        'Sender route is unknown. Sync contacts/path first.',
      );
      return;
    }
    if (resolution.failure == TransmissionTargetFailure.tooFar) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch voice',
        'Message is too far (${resolution.hops} hops, max ${resolution.maxHops}).',
      );
      return;
    }
    if (resolution.failure == TransmissionTargetFailure.unreachable) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch voice',
        'Sender route did not respond to a path check. Sync contacts/path and try again.',
      );
      return;
    }

    var sender = resolution.target!;
    var routeVerified = await appProvider.verifyRawTransportRoute(sender);
    if (!mounted) return;
    if (!routeVerified) {
      await connectionProvider.getContacts();
      if (!mounted) return;
      resolution = await TransmissionTargetResolver.resolveFetchTarget(
        contactsProvider: contactsProvider,
        refreshContacts: connectionProvider.getContacts,
        isSentByMe: widget.isSentByMe,
        recipientPublicKey: widget.message.recipientPublicKey,
        senderPublicKeyPrefix: widget.message.senderPublicKeyPrefix,
        senderName: widget.message.senderName,
        maxFetchHops: _maxFetchHops,
      );
      if (!mounted) return;
      if (resolution.failure == TransmissionTargetFailure.unknownContact) {
        _clearRequestState();
        await _showBlockingAlert(
          'Cannot fetch voice',
          'Sender contact is unknown. Sync contacts first.',
        );
        return;
      }
      if (resolution.failure == TransmissionTargetFailure.unknownRoute) {
        _clearRequestState();
        await _showBlockingAlert(
          'Cannot fetch voice',
          'Sender route is unknown. Sync contacts/path first.',
        );
        return;
      }
      if (resolution.failure == TransmissionTargetFailure.tooFar) {
        _clearRequestState();
        await _showBlockingAlert(
          'Cannot fetch voice',
          'Message is too far (${resolution.hops} hops, max ${resolution.maxHops}).',
        );
        return;
      }
      sender = resolution.target!;
      routeVerified = await appProvider.verifyRawTransportRoute(sender);
      if (!mounted) return;
      if (!routeVerified) {
        _clearRequestState();
        await _showBlockingAlert(
          'Cannot fetch voice',
          'Sender route did not respond on the raw transport path.',
        );
        return;
      }
    }

    if (!sender.routeSupportsLegacyRawTransport) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch voice',
        'Sender route uses 3-byte hashes. Raw media fetch is not supported in this client yet.',
      );
      return;
    }

    if (sender.routeHopCount >= 2) {
      _showToast(
        'Voice fetch over ${sender.routeHopCount} hops may take a while.',
      );
    }

    final deviceKey = connectionProvider.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch voice',
        'Device key is unavailable.',
      );
      return;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final missing = voiceProvider.missingPacketIndices(sessionId);
    final totalPackets = sessionPacketCount(
      voiceProvider: voiceProvider,
      sessionId: sessionId,
      envelope: envelope,
    );
    final isPartialResume =
        missing.isNotEmpty && totalPackets > 0 && missing.length < totalPackets;
    if (_isPartialRequest != isPartialResume && mounted) {
      setState(() {
        _isPartialRequest = isPartialResume;
      });
    }
    final request = isPartialResume
        ? VoiceFetchRequest(
            sessionId: sessionId,
            want: 'missing',
            missingIndices: missing,
            requesterKey6: requesterKey6,
          )
        : VoiceFetchRequest(
            sessionId: sessionId,
            requesterKey6: requesterKey6,
          );

    try {
      debugPrint(
        '🎙️ [VoiceMessageBubble] Outgoing voice fetch request: session=$sessionId want=${isPartialResume ? 'missing' : 'all'} target=${sender.advName} hops=${sender.routeHopCount}',
      );
      await connectionProvider.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.routeSignedPathLen,
        payload: request.encodeBinary(),
      );
    } catch (_) {
      _setUnavailable();
      return;
    }

    // Timeout = 2× estimated LoRa airtime (min 30s).
    final effectivePathLen = sender.routeHasPath
        ? sender.routeHopCount
        : pathLen;
    final estimatedDurationMs =
        envelope != null &&
            totalPackets > 0 &&
            missing.isNotEmpty &&
            missing.length < totalPackets
        ? ((envelope.durationMs * missing.length) / totalPackets).round()
        : envelope?.durationMs;
    final txEstimate = envelope != null
        ? estimateVoiceTransmitDuration(
            packetCount: isPartialResume ? missing.length : envelope.total,
            mode: envelope.mode,
            durationMs: estimatedDurationMs ?? envelope.durationMs,
            pathLen: effectivePathLen,
            radioBw: radioBw,
            radioSf: radioSf,
            radioCr: radioCr,
          )
        : const Duration(seconds: 15);
    _requestTimeoutTimer?.cancel();
    _requestTimeoutTimer = TransferTimeout.start(
      txEstimate: txEstimate,
      onTimeout: () {
        if (mounted && _isRequesting) {
          _setUnavailable();
        }
      },
    );
  }

  int sessionPacketCount({
    required VoiceProvider voiceProvider,
    required String sessionId,
    required VoiceEnvelope? envelope,
  }) {
    return voiceProvider.session(sessionId)?.total ?? envelope?.total ?? 0;
  }

  void _setUnavailable() {
    if (!mounted) return;
    _showToast(AppLocalizations.of(context)!.voiceUnavailable);
    setState(() {
      _isRequesting = false;
      _isPartialRequest = false;
      _autoPlayWhenReady = false;
      _errorText = AppLocalizations.of(context)!.voiceUnavailable;
    });
  }

  void _clearRequestState() {
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _isPartialRequest = false;
      _autoPlayWhenReady = false;
    });
  }

  void _cancelReceive(String sessionId) {
    if (!mounted) return;
    _requestTimeoutTimer?.cancel();
    context.read<VoiceProvider>().cancelIncomingSession(sessionId);
    _showToast('Voice receive canceled');
    setState(() {
      _isRequesting = false;
      _isPartialRequest = false;
      _autoPlayWhenReady = false;
      _errorText = 'Voice receive canceled';
    });
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _showBlockingAlert(String title, String message) async {
    if (!mounted) return;
    _showToast('$title: $message');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    required bool isReceivingData,
    required bool isPartialRequest,
    required String? errorText,
    required String requestingLabel,
    required Duration? eta,
    required bool isSentByMe,
    required int transferCount,
  }) {
    if (errorText != null) return errorText;
    final progress = total > 0 ? ' ($received/$total)' : '';
    if (isRequesting) {
      final actionLabel = isPartialRequest
          ? 'Fetching missing voice fragments'
          : requestingLabel;
      return '$actionLabel$progress · ${_formatEta(eta)} · $txEstimateLabel';
    }
    if (isReceivingData) {
      return 'Receiving voice$progress · ${_formatEta(eta)} · $txEstimateLabel';
    }
    if (!isComplete && total > 0) {
      return isSentByMe
          ? '🎙️ $durationLabel · $modeLabel$progress · ${_formatTransferCount(transferCount)} · $txEstimateLabel'
          : '🎙️ $durationLabel · $modeLabel$progress · $txEstimateLabel';
    }
    return isSentByMe
        ? '🎙️ $durationLabel · $modeLabel · ${_formatTransferCount(transferCount)} · $txEstimateLabel'
        : '🎙️ $durationLabel · $modeLabel · $txEstimateLabel';
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

  static String _formatEta(Duration? eta) {
    if (eta == null || eta <= Duration.zero) return 'ETA --';
    if (eta.inSeconds < 60) return 'ETA ~${eta.inSeconds}s';
    final minutes = eta.inMinutes;
    final seconds = eta.inSeconds % 60;
    return 'ETA ~${minutes}m ${seconds}s';
  }

  static String _formatTransferCount(int transferCount) {
    return '$transferCount transfer${transferCount == 1 ? '' : 's'}';
  }

  bool _hasRecentInboundActivity({
    required DateTime? lastReceivedAt,
    required int received,
    required int total,
  }) {
    if (lastReceivedAt == null || received <= 0 || received >= total) {
      return false;
    }
    return DateTime.now().difference(lastReceivedAt) <=
        _recentInboundActivityWindow;
  }
}

class _PacketBlockProgress extends StatelessWidget {
  final List<bool> presence;
  final Color activeColor;
  final bool highlightMissing;

  const _PacketBlockProgress({
    required this.presence,
    required this.activeColor,
    this.highlightMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (presence.isEmpty) {
      return const SizedBox(width: 100, height: 16);
    }

    final bucketCount = presence.length <= 20 ? presence.length : 20;
    final bucketFill = List<double>.generate(bucketCount, (bucketIndex) {
      final start = (bucketIndex * presence.length) ~/ bucketCount;
      final end = ((bucketIndex + 1) * presence.length) ~/ bucketCount;
      final safeEnd = end <= start ? start + 1 : end;
      final slice = presence.sublist(start, safeEnd);
      final received = slice.where((value) => value).length;
      return slice.isEmpty ? 0.0 : received / slice.length;
    });
    final missingColor = highlightMissing
        ? Colors.amberAccent
        : Colors.white.withValues(alpha: 0.14);

    return SizedBox(
      width: 100,
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final fill in bucketFill)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: fill > 0
                      ? activeColor.withValues(alpha: 0.18 + (0.72 * fill))
                      : missingColor.withValues(
                          alpha: highlightMissing ? 0.45 : 0.14,
                        ),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: fill > 0
                        ? Colors.white.withValues(alpha: 0.18)
                        : missingColor.withValues(
                            alpha: highlightMissing ? 0.7 : 0.18,
                          ),
                    width: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
