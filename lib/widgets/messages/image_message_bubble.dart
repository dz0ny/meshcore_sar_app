import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/image_provider.dart' as ip;
import '../../utils/image_message_parser.dart';

/// A message bubble that shows a received or sent image.
///
/// On first render the image is not yet fetched (only the IE1 envelope is
/// known).  The user taps the thumbnail placeholder → IR1 fetch request is
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
  bool _isRequesting = false;
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
    final envelope = ImageEnvelope.tryParse(widget.message.text);
    if (envelope == null) return const SizedBox.shrink();

    return Consumer<ip.ImageProvider>(
      builder: (context, imageProvider, _) {
        final session = imageProvider.session(envelope.sessionId);
        final isComplete = imageProvider.isComplete(envelope.sessionId);

        if (_isRequesting && isComplete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isRequesting = false);
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
                    pathLen: widget.message.pathLen,
                    radioBw: radioBw,
                    radioSf: radioSf,
                    radioCr: radioCr,
                    error: _errorText,
                    isSentByMe: widget.isSentByMe,
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
            ] else if (_errorText != null) ...[
              const Icon(Icons.broken_image, color: Colors.red, size: 36),
            ] else ...[
              // Tap-to-load icon.
              IconButton(
                onPressed: () => _requestAndFetch(envelope),
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

  Future<void> _requestAndFetch(ImageEnvelope envelope) async {
    if (_isRequesting) return;
    final sender = _resolveSender(envelope);
    if (sender == null) {
      setState(() => _errorText = 'Sender not reachable');
      return;
    }

    final conn = context.read<ConnectionProvider>();
    final deviceKey = conn.deviceInfo.publicKey;
    if (deviceKey == null || deviceKey.length < 6) {
      setState(() => _errorText = 'Device key unavailable');
      return;
    }

    final requesterKey6 = deviceKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final request = ImageFetchRequest(
      sessionId: envelope.sessionId,
      requesterKey6: requesterKey6,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    setState(() {
      _isRequesting = true;
      _errorText = null;
    });

    final sent = await conn.sendTextMessage(
      contactPublicKey: sender.publicKey,
      text: request.encode(),
      contact: sender,
    );
    if (!sent && mounted) {
      setState(() {
        _isRequesting = false;
        _errorText = 'Image unavailable right now';
      });
    }
  }

  Contact? _resolveSender(ImageEnvelope envelope) {
    final contactsProvider = context.read<ContactsProvider>();
    final senderPrefix = widget.message.senderPublicKeyPrefix;
    if (senderPrefix != null && senderPrefix.length >= 6) {
      final c = contactsProvider.findContactByPrefix(
        Uint8List.fromList(senderPrefix.sublist(0, 6)),
      );
      if (c != null) return c;
    }
    return contactsProvider.findContactByPrefixHex(envelope.senderKey6);
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
    if (isRequesting) return '📥 Loading… $received/$total · $txEstimateLabel';
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
