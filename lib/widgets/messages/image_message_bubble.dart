import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../providers/app_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/image_provider.dart' as ip;
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
  bool _isRequesting = false;
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
        final contactsProvider = context.read<ContactsProvider>();
        final session = imageProvider.session(envelope.sessionId);
        final sender = TransmissionTargetResolver.resolveLocalTarget(
          contactsProvider: contactsProvider,
          isSentByMe: widget.isSentByMe,
          recipientPublicKey: widget.message.recipientPublicKey,
          senderPublicKeyPrefix: widget.message.senderPublicKeyPrefix,
          senderKey6FromEnvelope: envelope.senderKey6,
          senderName: widget.message.senderName,
        );
        final effectivePathLen = sender != null && sender.outPathLen >= 0
            ? sender.outPathLen
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
                _errorText = null;
              });
            }
          });
        }

        final received = session?.receivedCount ?? 0;
        final total = session?.total ?? envelope.total;
        final imageBytes = isComplete ? session?.imageBytes : null;

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
                    received: received,
                    total: total,
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
    required int received,
    required int total,
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
              // Download progress ring.
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: total > 0 ? received / total : null,
                  strokeWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '$received/$total',
                style: const TextStyle(color: Colors.white, fontSize: 11),
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
                onPressed: () => _requestAndFetch(
                  envelope,
                  radioBw: radioBw,
                  radioSf: radioSf,
                  radioCr: radioCr,
                  pathLen: pathLen,
                ),
                icon: const Icon(Icons.download_rounded, size: 40),
                color: Colors.white70,
                tooltip: 'Load image',
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
    setState(() {
      _isRequesting = true;
      _errorText = null;
    });

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
      senderKey6FromEnvelope: envelope.senderKey6,
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
        senderKey6FromEnvelope: envelope.senderKey6,
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

    if (sender.outPathLen >= 2) {
      _showToast(
        'Image fetch over ${sender.outPathLen} hops may take a while.',
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
    final request = isPartialResume
        ? ImageFetchRequest(
            sessionId: envelope.sessionId,
            want: 'missing',
            missingIndices: missing,
            requesterKey6: requesterKey6,
            timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          )
        : ImageFetchRequest(
            sessionId: envelope.sessionId,
            requesterKey6: requesterKey6,
            timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

    final payload = request.encodeBinary();
    try {
      debugPrint(
        '📷 [ImageMessageBubble] Outgoing image fetch request: session=${envelope.sessionId} want=${isPartialResume ? 'missing' : 'all'} target=${sender.advName} hops=${sender.outPathLen}',
      );
      await conn.sendRawVoicePacket(
        contactPath: sender.outPath,
        contactPathLen: sender.outPathLen,
        payload: payload,
      );
    } catch (_) {
      if (mounted) {
        _showToast('Image fetch failed to send request');
        setState(() {
          _isRequesting = false;
          _errorText = 'Image unavailable right now';
        });
      }
      return;
    }
    if (!mounted) return;

    // Timeout = 2× estimated LoRa airtime (min 30s).
    final effectivePathLen = sender.outPathLen >= 0
        ? sender.outPathLen
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
      _errorText = 'Image receive canceled';
    });
  }

  void _clearRequestState() {
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
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
      return '📥 Loading… $received/$total · $etaLabel · $txEstimateLabel';
    }
    if (isComplete) {
      final base =
          '🖼️ ${envelope.width}×${envelope.height} ${envelope.format.label}';
      return isSentByMe
          ? '$base · ${envelope.total} seg · $txEstimateLabel'
          : '$base · $txEstimateLabel';
    }
    return '🖼️ Tap to load · ${envelope.width}×${envelope.height} · $txEstimateLabel';
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
