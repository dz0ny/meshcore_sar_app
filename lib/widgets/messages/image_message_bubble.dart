import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/app_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/image_provider.dart' as ip;
import '../../providers/messages_provider.dart';
import '../../utils/image_message_parser.dart';
import '../../utils/transmission_target_resolver.dart';
import 'transfer_timeout.dart';

/// A message bubble that shows a received or sent image.
///
/// On first render the image is not yet fetched (only the IE2 envelope is
/// known).  The user taps the thumbnail placeholder → IR2 fetch request is
/// sent → binary fragments stream in → bubble rebuilds with the full image.
class ImageMessageBubble extends StatefulWidget {
  final Message message;
  final bool isSentByMe;

  const ImageMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  static const int _maxFetchHops = 3;
  static const Duration _recentInboundActivityWindow = Duration(seconds: 3);
  bool _isRequesting = false;
  bool _isPartialRequest = false;
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
    final envelope = ImageEnvelope.tryParse(widget.message.text);
    if (envelope == null) return const SizedBox.shrink();

    return Consumer<ip.ImageProvider>(
      builder: (context, imageProvider, _) {
        final transferCount = context.select<MessagesProvider, int>(
          (provider) => provider.transferCountForSession(
            imageSessionId: envelope.sessionId,
          ),
        );
        final contactsProvider = context.read<ContactsProvider>();
        final session = imageProvider.session(envelope.sessionId);
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
        final isComplete = imageProvider.isComplete(envelope.sessionId);
        final eta = imageProvider.estimateRemainingTransferTime(
          envelope.sessionId,
        );

        if (_isRequesting && isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isRequesting = false;
                _isPartialRequest = false;
                _errorText = null;
              });
            }
          });
        }

        final received = session?.receivedCount ?? 0;
        final total = session?.total ?? envelope.total;
        final imageBytes = isComplete ? session?.imageBytes : null;
        final fragmentPresence =
            session?.fragments.map((fragment) => fragment != null).toList() ??
            List<bool>.filled(total, false);
        final isReceivingData =
            !_isRequesting &&
            !isComplete &&
            _hasRecentInboundActivity(
              lastReceivedAt: session?.lastFragmentAt,
              received: received,
              total: total,
            );

        return GestureDetector(
          onTap: isComplete
              ? () => _showFullScreen(context, imageBytes!)
              : null,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 256),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image area: 256×256 placeholder or actual image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageArea(
                    context,
                    imageBytes: imageBytes,
                    isComplete: isComplete,
                    isRequesting: _isRequesting,
                    isReceivingData: isReceivingData,
                    received: received,
                    total: total,
                    fragmentPresence: fragmentPresence,
                    envelope: envelope,
                    radioBw: radioBw,
                    radioSf: radioSf,
                    radioCr: radioCr,
                    pathLen: effectivePathLen,
                  ),
                ),
                const SizedBox(height: 4),
                // Status line
                Text(
                  _statusText(
                    isComplete: isComplete,
                    isRequesting: _isRequesting,
                    isReceivingData: isReceivingData,
                    isPartialRequest: _isPartialRequest,
                    received: received,
                    total: total,
                    envelope: envelope,
                    radioBw: radioBw,
                    radioSf: radioSf,
                    radioCr: radioCr,
                    error: _errorText,
                    isSentByMe: widget.isSentByMe,
                    eta: eta,
                    pathLen: effectivePathLen,
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
          ),
        );
      },
    );
  }

  Widget _buildImageArea(
    BuildContext context, {
    required Uint8List? imageBytes,
    required bool isComplete,
    required bool isRequesting,
    required bool isReceivingData,
    required int received,
    required int total,
    required List<bool> fragmentPresence,
    required ImageEnvelope envelope,
    required int? radioBw,
    required int? radioSf,
    required int? radioCr,
    required int pathLen,
  }) {
    if (isComplete && imageBytes != null) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: AvifImage.memory(imageBytes, fit: BoxFit.cover),
      );
    }

    // Placeholder with fetch/progress UI.
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        color: Colors.grey.shade800,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRequesting) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PacketBlockProgress(
                      presence: fragmentPresence,
                      activeColor: Theme.of(context).colorScheme.primary,
                      highlightMissing: _isPartialRequest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$received/$total',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => _cancelReceive(envelope.sessionId),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.white70,
                  tooltip: 'Cancel image receive',
                ),
              ),
            ] else if (_errorText != null) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, color: Colors.red, size: 36),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _requestAndFetch(
                      envelope,
                      radioBw: radioBw,
                      radioSf: radioSf,
                      radioCr: radioCr,
                      pathLen: pathLen,
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Tap-to-load icon.
              IconButton(
                onPressed: isReceivingData
                    ? null
                    : () => _requestAndFetch(
                        envelope,
                        radioBw: radioBw,
                        radioSf: radioSf,
                        radioCr: radioCr,
                        pathLen: pathLen,
                      ),
                icon: Icon(
                  isReceivingData
                      ? Icons.downloading_rounded
                      : Icons.download_rounded,
                  size: 40,
                ),
                color: Colors.white70,
                tooltip: isReceivingData
                    ? 'Image is already being received'
                    : 'Load image',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _requestAndFetch(
    ImageEnvelope envelope, {
    int? radioBw,
    int? radioSf,
    int? radioCr,
    int pathLen = 0,
  }) async {
    if (_isRequesting) return;

    final conn = context.read<ConnectionProvider>();
    final imageProvider = context.read<ip.ImageProvider>();
    imageProvider.resumeIncomingSession(envelope.sessionId);
    final contactsProvider = context.read<ContactsProvider>();
    final appProvider = context.read<AppProvider>();
    var resolution = await TransmissionTargetResolver.resolveFetchTarget(
      contactsProvider: contactsProvider,
      refreshContacts: conn.getContacts,
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
        'Cannot fetch image',
        'Sender contact is unknown. Sync contacts first.',
      );
      return;
    }
    if (resolution.failure == TransmissionTargetFailure.unknownRoute) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch image',
        'Sender route is unknown. Sync contacts/path first.',
      );
      return;
    }
    if (resolution.failure == TransmissionTargetFailure.tooFar) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch image',
        'Message is too far (${resolution.hops} hops, max ${resolution.maxHops}).',
      );
      return;
    }
    if (resolution.failure == TransmissionTargetFailure.unreachable) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch image',
        'Sender route did not respond to a path check. Sync contacts/path and try again.',
      );
      return;
    }

    var sender = resolution.target!;
    var routeVerified = await appProvider.verifyRawTransportRoute(sender);
    if (!mounted) return;
    if (!routeVerified) {
      await conn.getContacts();
      if (!mounted) return;
      resolution = await TransmissionTargetResolver.resolveFetchTarget(
        contactsProvider: contactsProvider,
        refreshContacts: conn.getContacts,
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
          'Cannot fetch image',
          'Sender contact is unknown. Sync contacts first.',
        );
        return;
      }
      if (resolution.failure == TransmissionTargetFailure.unknownRoute) {
        _clearRequestState();
        await _showBlockingAlert(
          'Cannot fetch image',
          'Sender route is unknown. Sync contacts/path first.',
        );
        return;
      }
      if (resolution.failure == TransmissionTargetFailure.tooFar) {
        _clearRequestState();
        await _showBlockingAlert(
          'Cannot fetch image',
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
          'Cannot fetch image',
          'Sender route did not respond on the raw transport path.',
        );
        return;
      }
    }

    if (!sender.routeSupportsLegacyRawTransport) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch image',
        'Sender route uses 3-byte hashes. Raw media fetch is not supported in this client yet.',
      );
      return;
    }

    if (sender.routeHopCount >= 2) {
      _showToast(
        'Image fetch over ${sender.routeHopCount} hops may take a while.',
      );
    }

    setState(() => _errorText = null);
    final deviceKey = conn.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      _clearRequestState();
      await _showBlockingAlert(
        'Cannot fetch image',
        'Device key is unavailable.',
      );
      return;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // If we already have some fragments, request only what's missing.
    final missing = imageProvider.missingFragmentIndices(envelope.sessionId);
    final isPartialResume =
        missing.isNotEmpty && missing.length < envelope.total;
    setState(() {
      _isRequesting = true;
      _isPartialRequest = isPartialResume;
      _errorText = null;
    });
    final request = isPartialResume
        ? ImageFetchRequest(
            sessionId: envelope.sessionId,
            want: 'missing',
            missingIndices: missing,
            requesterKey6: requesterKey6,
          )
        : ImageFetchRequest(
            sessionId: envelope.sessionId,
            requesterKey6: requesterKey6,
          );

    final payload = request.encodeBinary();
    try {
      debugPrint(
        '📷 [ImageMessageBubble] Outgoing image fetch request: session=${envelope.sessionId} want=${isPartialResume ? 'missing' : 'all'} target=${sender.advName} hops=${sender.routeHopCount}',
      );
      await conn.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.routeSignedPathLen,
        payload: payload,
      );
    } catch (_) {
      if (mounted) {
        _showToast('Image fetch failed to send request');
        setState(() {
          _isRequesting = false;
          _isPartialRequest = false;
          _errorText = 'Image unavailable right now';
        });
      }
      return;
    }
    if (!mounted) return;

    // Timeout = 2× estimated LoRa airtime (min 30s).
    final effectivePathLen = sender.routeHasPath
        ? sender.routeHopCount
        : pathLen;
    final txEstimate = estimateImageTransmitDuration(
      fragmentCount: missing.isEmpty ? envelope.total : missing.length,
      sizeBytes: missing.isEmpty
          ? envelope.sizeBytes
          : (envelope.sizeBytes * missing.length / envelope.total).round(),
      pathLen: effectivePathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    _requestTimeoutTimer?.cancel();
    _requestTimeoutTimer = TransferTimeout.start(
      txEstimate: txEstimate,
      onTimeout: () {
        if (mounted &&
            _isRequesting &&
            !imageProvider.isComplete(envelope.sessionId)) {
          _showToast('Image fetch timed out');
          setState(() {
            _isRequesting = false;
            _isPartialRequest = false;
            _errorText = 'Image fetch timed out';
          });
        }
      },
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _cancelReceive(String sessionId) {
    if (!mounted) return;
    _requestTimeoutTimer?.cancel();
    context.read<ip.ImageProvider>().cancelIncomingSession(sessionId);
    _showToast('Image receive canceled');
    setState(() {
      _isRequesting = false;
      _isPartialRequest = false;
      _errorText = 'Image receive canceled';
    });
  }

  void _clearRequestState() {
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _isPartialRequest = false;
    });
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

  static String _statusText({
    required bool isComplete,
    required bool isRequesting,
    required bool isReceivingData,
    required bool isPartialRequest,
    required int received,
    required int total,
    required ImageEnvelope envelope,
    required int pathLen,
    required int? radioBw,
    required int? radioSf,
    required int? radioCr,
    required String? error,
    required bool isSentByMe,
    required Duration? eta,
    required int transferCount,
  }) {
    final txEstimate = estimateImageTransmitDuration(
      fragmentCount: envelope.total,
      sizeBytes: envelope.sizeBytes,
      pathLen: pathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    final txEstimateLabel = _formatTransmitEstimate(txEstimate);

    if (error != null) return error;
    if (isRequesting) {
      final etaLabel = _formatEta(eta);
      final actionLabel = isPartialRequest
          ? '📥 Fetching missing fragments…'
          : '📥 Loading…';
      return '$actionLabel $received/$total · $etaLabel · $txEstimateLabel';
    }
    if (isReceivingData) {
      final etaLabel = _formatEta(eta);
      return '📥 Receiving… $received/$total · $etaLabel · $txEstimateLabel';
    }
    if (isComplete) {
      final base =
          '🖼️ ${envelope.width}×${envelope.height} ${envelope.format.label}';
      return isSentByMe
          ? '$base · ${envelope.total} seg · ${_formatTransferCount(transferCount)} · $txEstimateLabel'
          : '$base · $txEstimateLabel';
    }
    return isSentByMe
        ? '🖼️ ${envelope.width}×${envelope.height} · ${_formatTransferCount(transferCount)} · $txEstimateLabel'
        : '🖼️ Tap to load · ${envelope.width}×${envelope.height} · $txEstimateLabel';
  }

  static String _formatTransmitEstimate(Duration value) {
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

  void _showFullScreen(BuildContext context, Uint8List imageBytes) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      barrierLabel: 'Close image preview',
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 1000.0,
                clipBehavior: Clip.none,
                boundaryMargin: const EdgeInsets.all(100000),
                child: SizedBox.expand(
                  child: AvifImage.memory(imageBytes, fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );
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
      return const SizedBox(width: 96, height: 12);
    }

    final bucketCount = presence.length <= 24 ? presence.length : 24;
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
      width: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final fill in bucketFill)
            Expanded(
              child: Container(
                height: 12,
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
