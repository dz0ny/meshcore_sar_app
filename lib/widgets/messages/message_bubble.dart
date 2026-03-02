import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../models/sar_marker.dart';
import '../../models/sar_template.dart';
import '../../models/map_drawing.dart';
import '../../providers/messages_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/voice_provider.dart';
import '../../providers/image_provider.dart' as ip;
import '../contacts/direct_message_sheet.dart';
import '../drawing_minimap_preview.dart';
import '../../services/sar_template_service.dart';
import '../../utils/toast_logger.dart';
import '../../utils/sar_message_parser.dart';
import '../../utils/key_comparison.dart';
import '../../utils/voice_message_parser.dart';
import '../../utils/image_message_parser.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/message_extensions.dart';
import 'voice_message_bubble.dart';
import 'image_message_bubble.dart';

/// Reusable message bubble widget that displays messages with various types:
/// - Regular text messages (channel or direct)
/// - SAR markers (styled with SAR-specific colors and badges)
/// - Drawing messages (with minimap preview)
/// - System messages (compact log-style display)
/// - Grouped messages (expandable recipient list)
class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final VoidCallback? onNavigateToMap;

  /// Compact mode for fullscreen map overlay (simplified styling)
  final bool isCompact;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.isHighlighted = false,
    this.onNavigateToMap,
    this.isCompact = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when message properties change (especially recipient statuses)
    if (oldWidget.message.id == widget.message.id) {
      // Same message, but properties might have changed
      setState(() {
        // Trigger rebuild to show updated delivery counts
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _retryFailedMessage(
    BuildContext context,
    Message failedMessage,
  ) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    try {
      // Create new message ID for retry
      final retryMessageId = '${failedMessage.id}_retry';

      // Create retry message
      final retryMessage = failedMessage.copyWith(
        id: retryMessageId,
        deliveryStatus: MessageDeliveryStatus.sending,
      );

      // Add retry message to provider
      messagesProvider.addSentMessage(retryMessage);

      // Resend the message
      if (failedMessage.messageType == MessageType.contact) {
        // Direct message retry (for SAR markers sent to rooms)
        if (failedMessage.recipientPublicKey == null) {
          messagesProvider.markMessageFailed(retryMessageId);
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.cannotRetryMissingRecipient,
          );
          return;
        }

        // Look up the room contact for path logging
        final contactsProvider = context.read<ContactsProvider>();
        final roomContact = contactsProvider.contacts.where((c) {
          return c.publicKey.length >=
                  failedMessage.recipientPublicKey!.length &&
              c.publicKey.matches(failedMessage.recipientPublicKey!);
        }).firstOrNull;

        // Resend to the same room
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: failedMessage.recipientPublicKey!,
          text: failedMessage.text,
          messageId: retryMessageId,
          contact: roomContact,
        );

        if (!context.mounted) return;

        if (!sentSuccessfully) {
          messagesProvider.markMessageFailed(retryMessageId);
          ToastLogger.error(context, 'Failed to resend message');
        }
      } else if (failedMessage.messageType == MessageType.channel) {
        // Channel message retry
        await connectionProvider.sendChannelMessage(
          channelIdx: failedMessage.channelIdx ?? 0,
          text: failedMessage.text,
          messageId: retryMessageId,
        );

        if (!context.mounted) return;
      }
    } catch (e) {
      if (!context.mounted) return;
      ToastLogger.error(context, 'Retry failed: $e');
    }
  }

  void _showMessageOptions(BuildContext context) {
    // Determine if this is own message
    final connectionProvider = context.read<ConnectionProvider>();
    final selfPublicKey = connectionProvider.deviceInfo.publicKey;
    final isOwnMessage =
        widget.message.isSentMessage ||
        widget.message.isFromSelf(selfPublicKey);

    // Check if we can reply to this message (must be contact message from someone else)
    final canReply =
        widget.message.isContactMessage &&
        !isOwnMessage &&
        widget.message.senderPublicKeyPrefix != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply option (only for contact messages from others)
            if (canReply)
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(AppLocalizations.of(context)!.reply),
                onTap: () {
                  Navigator.pop(context);
                  _showReplySheet(context);
                },
              ),
            // Copy text option
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(AppLocalizations.of(context)!.copyText),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.message.text));
                Navigator.pop(context);
                ToastLogger.success(
                  context,
                  AppLocalizations.of(context)!.textCopiedToClipboard,
                );
              },
            ),
            // Save as Template option (only for SAR markers without existing template)
            if (widget.message.isSarMarker)
              Builder(
                builder: (context) {
                  // Extract emoji from SAR message
                  final sarInfo = SarMessageParser.parse(widget.message.text);
                  if (sarInfo == null || sarInfo.emoji.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Check if template with this emoji already exists
                  final sarTemplateService = SarTemplateService();
                  final templateExists = sarTemplateService.templates.any(
                    (t) => t.emoji == sarInfo.emoji,
                  );

                  if (templateExists) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: const Icon(Icons.bookmark_add),
                    title: Text(AppLocalizations.of(context)!.saveAsTemplate),
                    onTap: () {
                      Navigator.pop(context);
                      _saveAsTemplate(context);
                    },
                  );
                },
              ),
            // Share location option (only for SAR markers with GPS coordinates)
            if (widget.message.isSarMarker &&
                widget.message.sarGpsCoordinates != null)
              ListTile(
                leading: const Icon(Icons.share_location),
                title: Text(AppLocalizations.of(context)!.shareLocation),
                onTap: () {
                  Navigator.pop(context);
                  _shareLocation(context);
                },
              ),
            // Navigate to drawing option (only for drawing messages)
            if (widget.message.isDrawing && widget.message.drawingId != null)
              ListTile(
                leading: const Icon(Icons.map),
                title: Text(AppLocalizations.of(context)!.navigateToDrawing),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDrawing(context);
                },
              ),
            // Copy coordinates option (only for drawing messages)
            if (widget.message.isDrawing && widget.message.drawingId != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(AppLocalizations.of(context)!.copyCoordinates),
                onTap: () {
                  Navigator.pop(context);
                  _copyDrawingCoordinates(context);
                },
              ),
            // Hide from map option (only for drawing messages)
            if (widget.message.isDrawing && widget.message.drawingId != null)
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: Text(AppLocalizations.of(context)!.hideFromMap),
                onTap: () {
                  Navigator.pop(context);
                  _hideDrawingFromMap(context);
                },
              ),
            // Technical details option
            ListTile(
              leading: const Icon(Icons.data_object),
              title: Text(AppLocalizations.of(context)!.technicalDetails),
              onTap: () {
                Navigator.pop(context);
                _showTechnicalDetails(context);
              },
            ),
            // Delete message option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTechnicalDetails(BuildContext context) {
    final connectionProvider = context.read<ConnectionProvider>();
    final radioBw = connectionProvider.deviceInfo.radioBw;
    final radioSf = connectionProvider.deviceInfo.radioSf;
    final radioCr = connectionProvider.deviceInfo.radioCr;
    final contactsProvider = context.read<ContactsProvider>();
    final voiceProvider = context.read<VoiceProvider>();
    final imageProvider = context.read<ip.ImageProvider>();
    final selfPublicKey = connectionProvider.deviceInfo.publicKey;
    final isOwnMessage =
        widget.message.isSentMessage ||
        widget.message.isFromSelf(selfPublicKey);

    String? senderName;
    if (widget.message.senderPublicKeyPrefix != null) {
      final senderKeyHex = widget.message.senderPublicKeyPrefix!
          .sublist(
            0,
            widget.message.senderPublicKeyPrefix!.length < 6
                ? widget.message.senderPublicKeyPrefix!.length
                : 6,
          )
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
      final senderContact = contactsProvider.contacts
          .where((c) => c.publicKeyHex.startsWith(senderKeyHex))
          .firstOrNull;
      senderName = senderContact?.advName;
    }

    String? recipientName;
    if (widget.message.recipientPublicKey != null) {
      final recipientKeyHex = widget.message.recipientPublicKey!
          .sublist(
            0,
            widget.message.recipientPublicKey!.length < 6
                ? widget.message.recipientPublicKey!.length
                : 6,
          )
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
      final recipientContact = contactsProvider.contacts
          .where((c) => c.publicKeyHex.startsWith(recipientKeyHex))
          .firstOrNull;
      recipientName = recipientContact?.advName;
    }

    final envelope = VoiceEnvelope.tryParseText(widget.message.text);
    final legacyVoicePacket = VoicePacket.tryParseText(widget.message.text);
    final voiceSession = widget.message.voiceId != null
        ? voiceProvider.session(widget.message.voiceId!)
        : null;

    final imageEnvelope = ImageEnvelope.tryParse(widget.message.text);
    final imageSession = imageEnvelope != null
        ? imageProvider.session(imageEnvelope.sessionId)
        : null;
    final imageTxEstimate = imageEnvelope != null
        ? estimateImageTransmitDuration(
            fragmentCount: imageEnvelope.total,
            sizeBytes: imageEnvelope.sizeBytes,
            pathLen: widget.message.pathLen,
            radioBw: radioBw,
            radioSf: radioSf,
            radioCr: radioCr,
          )
        : Duration.zero;
    final voiceTxEstimate = voiceSession != null
        ? estimateVoiceTransmitDurationFromPackets(
            packets: voiceSession.packets,
            pathLen: widget.message.pathLen,
            radioBw: radioBw,
            radioSf: radioSf,
            radioCr: radioCr,
          )
        : envelope != null
        ? estimateVoiceTransmitDuration(
            mode: envelope.mode,
            packetCount: envelope.total,
            durationMs: envelope.durationMs,
            pathLen: widget.message.pathLen,
            radioBw: radioBw,
            radioSf: radioSf,
            radioCr: radioCr,
          )
        : legacyVoicePacket != null
        ? estimateVoiceTransmitDuration(
            mode: legacyVoicePacket.mode,
            packetCount: legacyVoicePacket.total,
            durationMs: legacyVoicePacket.durationMs * legacyVoicePacket.total,
            pathLen: widget.message.pathLen,
            radioBw: radioBw,
            radioSf: radioSf,
            radioCr: radioCr,
          )
        : Duration.zero;

    final senderPrefixHex = widget.message.senderPublicKeyPrefix
        ?.map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final recipientKey = widget.message.recipientPublicKey;
    final recipientPrefixHex = recipientKey
        ?.sublist(0, recipientKey.length < 6 ? recipientKey.length : 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final snrDb = widget.message.lastEchoSnrRaw != null
        ? (widget.message.lastEchoSnrRaw!.toSigned(8) / 4.0)
        : null;

    final rawLines = <String>[
      'Message ID: ${widget.message.id}',
      'Type: ${widget.message.messageType.name}',
      'Text type: ${widget.message.textType.name}',
      'Own message: $isOwnMessage',
      'Sent message: ${widget.message.isSentMessage}',
      'Read: ${widget.message.isRead}',
      'Status: ${widget.message.deliveryStatus.name}',
      'Path length (nodes/hops): ${widget.message.pathLen}',
      'Sender timestamp: ${widget.message.senderTimestamp} (${widget.message.sentAt.toIso8601String()})',
      'Received at: ${widget.message.receivedAt.toIso8601String()}',
      'Channel index: ${widget.message.channelIdx ?? '-'}',
      'Echo count: ${widget.message.echoCount}',
      'Last echo RSSI: ${widget.message.lastEchoRssiDbm ?? '-'}',
      'Last echo SNR: ${snrDb?.toStringAsFixed(2) ?? '-'}',
      'Expected ACK tag: ${widget.message.expectedAckTag ?? '-'}',
      'Suggested timeout ms: ${widget.message.suggestedTimeoutMs ?? '-'}',
      'Round-trip ms: ${widget.message.roundTripTimeMs ?? '-'}',
      'Retry attempt: ${widget.message.retryAttempt}',
      'Used flood fallback: ${widget.message.usedFloodFallback}',
      'Sender key prefix: ${senderPrefixHex ?? '-'}',
      'Sender name: ${senderName ?? widget.message.senderName ?? '-'}',
      'Recipient key prefix: ${recipientPrefixHex ?? '-'}',
      'Recipient name: ${recipientName ?? '-'}',
      'Drawing flag: ${widget.message.isDrawing}',
      'Drawing ID: ${widget.message.drawingId ?? '-'}',
      'SAR flag: ${widget.message.isSarMarker}',
      'Voice flag: ${widget.message.isVoice}',
      'Voice ID: ${widget.message.voiceId ?? '-'}',
      'Text length: ${widget.message.text.length}',
    ];

    if (widget.message.isVoice) {
      rawLines.add('--- Voice Technical ---');
      if (envelope != null) {
        rawLines.add('Envelope format: VE1 compact');
        rawLines.add(
          'Voice mode: ${envelope.mode.label} (id=${envelope.mode.id})',
        );
        rawLines.add('Segments total (envelope): ${envelope.total}');
        rawLines.add(
          'Estimated duration ms (envelope): ${envelope.durationMs}',
        );
        rawLines.add('Envelope senderKey6: ${envelope.senderKey6}');
        rawLines.add('Envelope ts: ${envelope.timestampSec}');
        rawLines.add('Envelope ver: ${envelope.version}');
      } else if (legacyVoicePacket != null) {
        rawLines.add('Envelope format: legacy V packet');
        rawLines.add(
          'Legacy segment index/total: ${legacyVoicePacket.index + 1}/${legacyVoicePacket.total}',
        );
        rawLines.add(
          'Legacy codec mode: ${legacyVoicePacket.mode.label} (id=${legacyVoicePacket.mode.id})',
        );
      } else {
        rawLines.add('Envelope format: unknown');
      }

      if (voiceSession != null) {
        rawLines.add('Session present locally: yes');
        rawLines.add('Session mode: ${voiceSession.mode.label}');
        rawLines.add(
          'Session segments received/total: ${voiceSession.receivedCount}/${voiceSession.total}',
        );
        rawLines.add('Session complete: ${voiceSession.isComplete}');
        rawLines.add(
          'Session estimated duration s: ${voiceSession.estimatedDurationSeconds.toStringAsFixed(2)}',
        );
        rawLines.add(
          'Estimated voice tx: ~${voiceTxEstimate.inSeconds}s (current radio)',
        );
      } else {
        rawLines.add('Session present locally: no');
        if (voiceTxEstimate > Duration.zero) {
          rawLines.add(
            'Estimated voice tx: ~${voiceTxEstimate.inSeconds}s (current radio)',
          );
        }
      }
    }

    if (imageEnvelope != null) {
      rawLines.add('--- Image Technical ---');
      rawLines.add('Envelope format: IE1');
      rawLines.add('Session ID: ${imageEnvelope.sessionId}');
      rawLines.add(
        'Image format: ${imageEnvelope.format.label} (id=${imageEnvelope.format.id})',
      );
      rawLines.add(
        'Dimensions: ${imageEnvelope.width}×${imageEnvelope.height}',
      );
      rawLines.add('Fragments total (envelope): ${imageEnvelope.total}');
      rawLines.add('Compressed size (envelope): ${imageEnvelope.sizeBytes} B');
      rawLines.add(
        'Estimated image tx: ~${imageTxEstimate.inSeconds}s (current radio)',
      );
      rawLines.add('Envelope senderKey6: ${imageEnvelope.senderKey6}');
      rawLines.add('Envelope ts: ${imageEnvelope.timestampSec}');
      rawLines.add('Envelope ver: ${imageEnvelope.version}');

      if (imageSession != null) {
        rawLines.add('Session present locally: yes');
        rawLines.add(
          'Fragments received/total: ${imageSession.receivedCount}/${imageSession.total}',
        );
        rawLines.add('Session complete: ${imageSession.isComplete}');
        final kb = (imageSession.imageBytes?.length ?? 0) / 1024.0;
        rawLines.add(
          'Reassembled size: ${imageSession.imageBytes != null ? '${kb.toStringAsFixed(1)} kB' : '-'}',
        );
      } else {
        rawLines.add('Session present locally: no');
      }
    }

    final l10n = AppLocalizations.of(context)!;

    void copyField(String value) {
      Clipboard.setData(ClipboardData(text: value));
      ToastLogger.success(context, l10n.textCopiedToClipboard);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.messageTechnicalDetails),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _techBadge(
                      context,
                      icon: Icons.message,
                      label: widget.message.messageType.name.toUpperCase(),
                    ),
                    _techBadge(
                      context,
                      icon: Icons.route,
                      label:
                          '${widget.message.pathLen} hop${widget.message.pathLen == 1 ? '' : 's'}',
                    ),
                    _techBadge(
                      context,
                      icon: Icons.account_tree_outlined,
                      label:
                          '${widget.message.echoCount} node${widget.message.echoCount == 1 ? '' : 's'}',
                    ),
                    if (widget.message.channelIdx != null)
                      _techBadge(
                        context,
                        icon: Icons.group_work,
                        label: 'CH ${widget.message.channelIdx}',
                      ),
                  ],
                ),
                if (widget.message.lastEchoRssiDbm != null ||
                    snrDb != null) ...[
                  const SizedBox(height: 12),
                  _techSection(
                    context,
                    icon: Icons.network_check,
                    title: l10n.linkQuality,
                    child: Column(
                      children: [
                        if (widget.message.lastEchoRssiDbm != null)
                          _signalRow(
                            context,
                            label: 'RSSI',
                            valueLabel: '${widget.message.lastEchoRssiDbm} dBm',
                            normalized:
                                ((widget.message.lastEchoRssiDbm!.toDouble() +
                                            120.0) /
                                        70.0)
                                    .clamp(0.0, 1.0),
                            color: widget.message.lastEchoRssiDbm! >= -80
                                ? Colors.green
                                : widget.message.lastEchoRssiDbm! >= -95
                                ? Colors.amber
                                : Colors.redAccent,
                          ),
                        if (snrDb != null) ...[
                          const SizedBox(height: 8),
                          _signalRow(
                            context,
                            label: 'SNR',
                            valueLabel: '${snrDb.toStringAsFixed(1)} dB',
                            normalized: ((snrDb + 20.0) / 40.0).clamp(0.0, 1.0),
                            color: snrDb >= 10
                                ? Colors.green
                                : snrDb >= 0
                                ? Colors.amber
                                : Colors.redAccent,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _techSection(
                  context,
                  icon: Icons.tune,
                  title: l10n.delivery,
                  child: Column(
                    children: [
                      _detailRow(
                        context,
                        label: l10n.status,
                        value: widget.message.deliveryStatus.name,
                      ),
                      _detailRow(
                        context,
                        label: l10n.expectedAckTag,
                        value: widget.message.expectedAckTag?.toString() ?? '-',
                      ),
                      _detailRow(
                        context,
                        label: l10n.roundTrip,
                        value: widget.message.roundTripTimeMs != null
                            ? '${widget.message.roundTripTimeMs} ms'
                            : '-',
                      ),
                      _detailRow(
                        context,
                        label: l10n.retryAttempt,
                        value: widget.message.retryAttempt.toString(),
                      ),
                      _detailRow(
                        context,
                        label: l10n.floodFallback,
                        value: widget.message.usedFloodFallback
                            ? l10n.yes
                            : l10n.no,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _techSection(
                  context,
                  icon: Icons.badge,
                  title: l10n.identity,
                  child: Column(
                    children: [
                      _detailRow(
                        context,
                        label: l10n.messageId,
                        value: widget.message.id,
                        onCopy: () => copyField(widget.message.id),
                      ),
                      _detailRow(
                        context,
                        label: l10n.sender,
                        value: senderName ?? widget.message.senderName ?? '-',
                      ),
                      _detailRow(
                        context,
                        label: l10n.senderKey,
                        value: senderPrefixHex ?? '-',
                        onCopy: senderPrefixHex != null
                            ? () => copyField(senderPrefixHex)
                            : null,
                      ),
                      _detailRow(
                        context,
                        label: l10n.recipient,
                        value: recipientName ?? '-',
                      ),
                      _detailRow(
                        context,
                        label: l10n.recipientKey,
                        value: recipientPrefixHex ?? '-',
                        onCopy: recipientPrefixHex != null
                            ? () => copyField(recipientPrefixHex)
                            : null,
                      ),
                    ],
                  ),
                ),
                if (widget.message.isVoice) ...[
                  const SizedBox(height: 12),
                  _techSection(
                    context,
                    icon: Icons.graphic_eq,
                    title: l10n.voice,
                    child: Column(
                      children: [
                        _detailRow(
                          context,
                          label: l10n.voiceId,
                          value: widget.message.voiceId ?? '-',
                        ),
                        _detailRow(
                          context,
                          label: l10n.envelope,
                          value: envelope != null
                              ? 'VE1 compact'
                              : legacyVoicePacket != null
                              ? 'Legacy V packet'
                              : l10n.unknown,
                        ),
                        if (voiceSession != null)
                          _detailRow(
                            context,
                            label: l10n.sessionProgress,
                            value:
                                '${voiceSession.receivedCount}/${voiceSession.total} segments',
                          ),
                        if (voiceSession != null)
                          _detailRow(
                            context,
                            label: l10n.complete,
                            value: voiceSession.isComplete ? l10n.yes : l10n.no,
                          ),
                        if (voiceTxEstimate > Duration.zero)
                          _detailRow(
                            context,
                            label: 'Estimated tx',
                            value: voiceTxEstimate.inSeconds < 60
                                ? '~${voiceTxEstimate.inSeconds}s'
                                : '~${voiceTxEstimate.inMinutes}m ${voiceTxEstimate.inSeconds % 60}s',
                          ),
                      ],
                    ),
                  ),
                ],
                if (imageEnvelope != null) ...[
                  const SizedBox(height: 12),
                  _techSection(
                    context,
                    icon: Icons.image_outlined,
                    title: 'Image',
                    child: Column(
                      children: [
                        _detailRow(context, label: l10n.envelope, value: 'IE1'),
                        _detailRow(
                          context,
                          label: 'Format',
                          value: imageEnvelope.format.label,
                        ),
                        _detailRow(
                          context,
                          label: 'Dimensions',
                          value:
                              '${imageEnvelope.width}×${imageEnvelope.height}',
                        ),
                        _detailRow(
                          context,
                          label: 'Segments',
                          value: imageSession != null
                              ? '${imageSession.receivedCount}/${imageSession.total}'
                              : '${imageEnvelope.total}',
                        ),
                        if (imageSession != null)
                          _detailRow(
                            context,
                            label: l10n.complete,
                            value: imageSession.isComplete ? l10n.yes : l10n.no,
                          ),
                        if (imageTxEstimate > Duration.zero)
                          _detailRow(
                            context,
                            label: 'Estimated tx',
                            value: imageTxEstimate.inSeconds < 60
                                ? '~${imageTxEstimate.inSeconds}s'
                                : '~${imageTxEstimate.inMinutes}m ${imageTxEstimate.inSeconds % 60}s',
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    l10n.rawDump,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        rawLines.join('\n'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _techSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _techBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 14),
              visualDensity: VisualDensity.compact,
              tooltip: 'Copy $label',
            ),
        ],
      ),
    );
  }

  Widget _signalRow(
    BuildContext context, {
    required String label,
    required String valueLabel,
    required double normalized,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: normalized,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showReplySheet(BuildContext context) {
    // Find the sender contact by public key prefix
    final contactsProvider = context.read<ContactsProvider>();

    if (widget.message.senderPublicKeyPrefix == null) {
      ToastLogger.error(context, 'Cannot reply: sender information missing');
      return;
    }

    // Find contact by public key prefix (first 6 bytes)
    final senderKeyHex = widget.message.senderPublicKeyPrefix!
        .sublist(
          0,
          widget.message.senderPublicKeyPrefix!.length < 6
              ? widget.message.senderPublicKeyPrefix!.length
              : 6,
        )
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    final senderContact = contactsProvider.contacts.where((c) {
      return c.publicKeyHex.startsWith(senderKeyHex);
    }).firstOrNull;

    if (senderContact == null) {
      ToastLogger.error(context, 'Cannot reply: contact not found');
      return;
    }

    // Show direct message sheet for the sender
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DirectMessageSheet(contact: senderContact),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.deleteMessageConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final messagesProvider = context.read<MessagesProvider>();
              messagesProvider.deleteMessage(widget.message.id);

              // Also delete the drawing if this is a drawing message
              if (widget.message.isDrawing &&
                  widget.message.drawingId != null) {
                final drawingProvider = context.read<DrawingProvider>();
                drawingProvider.removeDrawing(widget.message.drawingId!);
              }

              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _shareLocation(BuildContext context) {
    if (widget.message.sarGpsCoordinates == null) {
      ToastLogger.error(context, 'No GPS coordinates available');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final coords = widget.message.sarGpsCoordinates!;

    // Get SAR marker type emoji/name
    String markerInfo = '';
    if (widget.message.sarMarkerType != null) {
      markerInfo = widget.message.sarMarkerType!.emoji;
      if (widget.message.sarNotes != null &&
          widget.message.sarNotes!.isNotEmpty) {
        markerInfo += ' ${widget.message.sarNotes}';
      }
    } else if (widget.message.sarCustomEmoji != null) {
      markerInfo = widget.message.sarCustomEmoji!;
      if (widget.message.sarNotes != null &&
          widget.message.sarNotes!.isNotEmpty) {
        markerInfo += ' ${widget.message.sarNotes}';
      }
    }

    // Format coordinates with 6 decimal places (≈0.1m precision)
    final lat = coords.latitude.toStringAsFixed(6);
    final lon = coords.longitude.toStringAsFixed(6);

    // Build share text
    final shareText = l10n.shareLocationText(
      markerInfo,
      lat,
      lon,
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    // Share the location
    SharePlus.instance.share(
      ShareParams(text: shareText, subject: l10n.sarLocationShare),
    );
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    if (!widget.message.isSarMarker) {
      ToastLogger.error(context, 'Not a SAR marker');
      return;
    }

    try {
      // Parse the SAR message to create a template
      final template = SarTemplate.fromSarMessage(widget.message.text);

      // Get SAR template service
      final sarTemplateService = SarTemplateService();

      // Check if template with this emoji already exists
      final existingTemplates = sarTemplateService.templates
          .where((t) => t.emoji == template.emoji)
          .toList();

      if (existingTemplates.isNotEmpty) {
        if (!context.mounted) return;
        ToastLogger.warning(
          context,
          AppLocalizations.of(context)!.templateAlreadyExists,
        );
        return;
      }

      // Save the template
      await sarTemplateService.addTemplate(template);

      if (!context.mounted) return;
      ToastLogger.success(context, AppLocalizations.of(context)!.templateSaved);
    } catch (e) {
      debugPrint('Error saving template: $e');
      if (!context.mounted) return;
      ToastLogger.error(context, 'Failed to save template: $e');
    }
  }

  void _navigateToDrawing(BuildContext context) {
    if (widget.message.drawingId == null) return;
    widget.onNavigateToMap?.call();
  }

  void _copyDrawingCoordinates(BuildContext context) {
    if (widget.message.drawingId == null) return;

    final drawingProvider = context.read<DrawingProvider>();
    final drawing = drawingProvider.getDrawingById(widget.message.drawingId!);

    if (drawing == null) {
      ToastLogger.error(context, 'Drawing not found');
      return;
    }

    // Format coordinates based on drawing type
    String coordinatesText;
    if (drawing is LineDrawing) {
      coordinatesText = drawing.points
          .map(
            (p) =>
                '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
          )
          .join('\n');
    } else if (drawing is RectangleDrawing) {
      coordinatesText = drawing.corners
          .map(
            (p) =>
                '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
          )
          .join('\n');
    } else {
      ToastLogger.error(context, 'Unknown drawing type');
      return;
    }

    Clipboard.setData(ClipboardData(text: coordinatesText));
    ToastLogger.success(
      context,
      AppLocalizations.of(context)!.textCopiedToClipboard,
    );
  }

  void _hideDrawingFromMap(BuildContext context) {
    if (widget.message.drawingId == null) return;

    final drawingProvider = context.read<DrawingProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    // Remove the drawing from map and delete the message
    drawingProvider.removeDrawingAndMessage(
      widget.message.drawingId!,
      messagesProvider,
    );

    ToastLogger.success(context, 'Drawing removed from map');
  }

  Color _getMessageBubbleColor(
    BuildContext context,
    bool isOwnMessage,
    bool isDarkMode,
  ) {
    if (isOwnMessage) {
      // Own messages: slightly highlighted with primary color tint
      return isDarkMode
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.15);
    } else {
      // Others' messages: default surface color
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _getSarMarkerColor(BuildContext context, bool isDarkMode) {
    if (widget.message.sarMarkerType == null) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    // Use type-specific colors with alpha for background
    switch (widget.message.sarMarkerType!) {
      case SarMarkerType.foundPerson:
        return isDarkMode
            ? const Color(0xFF1B5E20).withValues(alpha: 0.4)
            : const Color(0xFFC8E6C9).withValues(alpha: 0.9);
      case SarMarkerType.fire:
        return isDarkMode
            ? const Color(0xFFB71C1C).withValues(alpha: 0.4)
            : const Color(0xFFFFCDD2).withValues(alpha: 0.9);
      case SarMarkerType.stagingArea:
        return isDarkMode
            ? const Color(0xFF0D47A1).withValues(alpha: 0.4)
            : const Color(0xFFBBDEFB).withValues(alpha: 0.9);
      case SarMarkerType.object:
        return isDarkMode
            ? const Color(0xFF4A148C).withValues(alpha: 0.4)
            : const Color(0xFFE1BEE7).withValues(alpha: 0.9);
      case SarMarkerType.unknown:
        return isDarkMode
            ? const Color(0xFF424242).withValues(alpha: 0.4)
            : const Color(0xFFEEEEEE).withValues(alpha: 0.9);
    }
  }

  Color _getSarMarkerBorderColor(BuildContext context, bool isDarkMode) {
    if (widget.message.sarMarkerType == null) {
      return Theme.of(context).colorScheme.primary;
    }

    // Use vibrant type-specific colors for borders
    switch (widget.message.sarMarkerType!) {
      case SarMarkerType.foundPerson:
        return const Color(0xFF4CAF50); // Green
      case SarMarkerType.fire:
        return const Color(0xFFF44336); // Red
      case SarMarkerType.stagingArea:
        return const Color(0xFF2196F3); // Blue
      case SarMarkerType.object:
        return const Color(0xFF9C27B0); // Purple
      case SarMarkerType.unknown:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  IconData _getDeliveryStatusIcon(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Icons.schedule;
      case MessageDeliveryStatus.sent:
        return Icons.check;
      case MessageDeliveryStatus.delivered:
        return Icons.done_all;
      case MessageDeliveryStatus.failed:
        return Icons.error_outline;
      case MessageDeliveryStatus.received:
        return Icons.inbox;
    }
  }

  Color _getDeliveryStatusColor(MessageDeliveryStatus status) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Colors.orange;
      case MessageDeliveryStatus.sent:
        return Colors.blue;
      case MessageDeliveryStatus.delivered:
        return Colors.green;
      case MessageDeliveryStatus.failed:
        return Colors.red;
      case MessageDeliveryStatus.received:
        return Colors.grey;
    }
  }

  Widget _buildChannelEchoStatus(BuildContext context, Message message) {
    final statusColor = _getDeliveryStatusColor(message.deliveryStatus);
    final hasEcho = message.echoCount > 0;

    if (!hasEcho) {
      return Text(
        message.getLocalizedDeliveryStatus(context),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final rssi = message.lastEchoRssiDbm;
    final snr = message.lastEchoSnrRaw != null
        ? message.lastEchoSnrRaw!.toSigned(8) / 4.0
        : null;
    final quality = _linkQualityLabel(rssi, snr);
    final qualityColor = _linkQualityColor(quality);

    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _techChip(
          context,
          icon: Icons.hub_outlined,
          label: 'x${message.echoCount}',
          color: statusColor,
        ),
        if (message.expectedAckTag != null)
          _techChip(
            context,
            icon: Icons.tag,
            label:
                'ACK ${message.expectedAckTag!.toRadixString(16).toUpperCase()}',
            color: Colors.indigo,
          ),
        _techChip(
          context,
          icon: Icons.bolt,
          label: quality,
          color: qualityColor,
        ),
        if (message.lastEchoRssiDbm != null)
          _signalCapsule(
            context,
            icon: Icons.network_cell,
            label: message.lastEchoRssiDbm!.toString(),
            filled: _rssiScore(message.lastEchoRssiDbm!),
            color: Colors.blueGrey,
          ),
        if (message.lastEchoSnrRaw != null)
          _signalCapsule(
            context,
            icon: Icons.graphic_eq,
            label: (message.lastEchoSnrRaw!.toSigned(8) / 4.0).toStringAsFixed(
              1,
            ),
            filled: _snrScore(message.lastEchoSnrRaw!.toSigned(8) / 4.0),
            color: Colors.teal,
          ),
      ],
    );
  }

  Widget _techChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalCapsule(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int filled,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final active = i < filled;
              return Container(
                width: 3,
                height: (4 + i).toDouble(),
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: active ? color : color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  int _rssiScore(int rssiDbm) => ((rssiDbm + 120) / 10).round().clamp(0, 5);

  int _snrScore(double snrDb) => ((snrDb + 5.0) / 5.0).round().clamp(0, 5);

  String _linkQualityLabel(int? rssiDbm, double? snrDb) {
    var score = 0;
    if (rssiDbm != null) score += _rssiScore(rssiDbm);
    if (snrDb != null) score += _snrScore(snrDb);
    if (score >= 8) return 'Excellent';
    if (score >= 6) return 'Good';
    if (score >= 4) return 'Fair';
    return 'Weak';
  }

  Color _linkQualityColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display system messages with minimal styling
    if (widget.message.isSystemMessage) {
      return SystemMessageBubble(message: widget.message);
    }

    final message = widget.message;
    final isSarMarker = message.isSarMarker;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine if this is own message
    final connectionProvider = context.read<ConnectionProvider>();
    final selfPublicKey = connectionProvider.deviceInfo.publicKey;
    final isOwnMessage =
        message.isSentMessage || message.isFromSelf(selfPublicKey);

    // Look up contact information for rich display name
    final contactsProvider = context.read<ContactsProvider>();
    dynamic senderContact;
    if (message.senderPublicKeyPrefix != null && !isOwnMessage) {
      final senderKeyHex = message.senderPublicKeyPrefix!
          .sublist(
            0,
            message.senderPublicKeyPrefix!.length < 6
                ? message.senderPublicKeyPrefix!.length
                : 6,
          )
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');

      senderContact = contactsProvider.contacts.where((c) {
        return c.publicKeyHex.startsWith(senderKeyHex);
      }).firstOrNull;
    }

    // Get rich display name (with emoji if available)
    final displayName = isOwnMessage
        ? AppLocalizations.of(context)!.you
        : message.getRichDisplayName(senderContact);
    final l10n = AppLocalizations.of(context)!;

    // For sent direct/channel messages, look up destination display label
    dynamic recipientContact;
    String? recipientDisplayName;
    if (isOwnMessage &&
        message.isContactMessage &&
        message.recipientPublicKey != null) {
      final recipientKeyHex = message.recipientPublicKey!
          .sublist(
            0,
            message.recipientPublicKey!.length < 6
                ? message.recipientPublicKey!.length
                : 6,
          )
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');

      recipientContact = contactsProvider.contacts.where((c) {
        final matches = c.publicKeyHex.startsWith(recipientKeyHex);
        return matches;
      }).firstOrNull;

      if (recipientContact != null) {
        final roleEmoji = recipientContact.roleEmoji;
        if (roleEmoji != null && roleEmoji.isNotEmpty) {
          recipientDisplayName = '$roleEmoji ${recipientContact.displayName}';
        } else {
          recipientDisplayName =
              recipientContact.displayName ?? recipientContact.advName;
        }
      }
    } else if (isOwnMessage && message.isChannelMessage) {
      if (message.channelIdx == 0) {
        recipientDisplayName = l10n.publicChannel;
      } else {
        final channelContact = contactsProvider.channels.where((c) {
          return c.publicKey.length > 1 && c.publicKey[1] == message.channelIdx;
        }).firstOrNull;
        recipientDisplayName =
            channelContact?.getLocalizedDisplayName(context) ??
            '${l10n.channel} ${message.channelIdx}';
      }
    }

    final recipientSubtitle =
        isOwnMessage && message.isChannelMessage && recipientDisplayName != null
        ? '${l10n.channel}: $recipientDisplayName'
        : recipientDisplayName;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.isCompact ? null : () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : isSarMarker
              ? _getSarMarkerColor(context, isDarkMode)
              : message.isDrawing
              ? (isDarkMode
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08))
              : _getMessageBubbleColor(context, isOwnMessage, isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: widget.isHighlighted
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : isSarMarker
              ? Border.all(
                  color: _getSarMarkerBorderColor(context, isDarkMode),
                  width: 2,
                )
              : message.isDrawing
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.4),
                  width: 2,
                )
              : isOwnMessage
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : !message.isRead &&
                    !message.isSentMessage &&
                    !message.isSystemMessage
              ? Border.all(color: Colors.blue, width: 1.5)
              : null,
          boxShadow: widget.isHighlighted
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : isSarMarker || message.isDrawing
              ? [
                  BoxShadow(
                    color:
                        (isSarMarker
                                ? _getSarMarkerBorderColor(context, isDarkMode)
                                : Theme.of(context).colorScheme.primary)
                            .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Badge (if SAR or drawing) and time
            if (isSarMarker || message.isDrawing)
              Row(
                children: [
                  if (isSarMarker)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getSarMarkerBorderColor(context, isDarkMode),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.sarAlert,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    )
                  else if (message.isDrawing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.draw, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.mapDrawing,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Text(
                    message.getLocalizedTimeAgo(context),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: isSarMarker
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),

            // Sender info row (shown for all messages)
            Row(
              children: [
                // Unread indicator badge (only for regular messages, not SAR/drawing)
                if (!message.isRead &&
                    !message.isSentMessage &&
                    !message.isSystemMessage &&
                    !isSarMarker &&
                    !message.isDrawing)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (isOwnMessage)
                  Icon(
                    Icons.account_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  )
                else if (message.isChannelMessage)
                  const Icon(Icons.tag, size: 16)
                else
                  const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isOwnMessage
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Show destination for sent direct/channel messages on a separate line
                      if (isOwnMessage &&
                          recipientSubtitle != null &&
                          !widget.isCompact) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                recipientSubtitle,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.color
                                          ?.withValues(alpha: 0.75),
                                      fontStyle: FontStyle.italic,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Time for regular messages (not shown for SAR/drawing as it's already above)
                if (!isSarMarker && !message.isDrawing) ...[
                  const SizedBox(width: 8),
                  // Hop count indicator for received messages
                  if (!isOwnMessage && message.pathLen < 255) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.alt_route,
                      size: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.labelSmall?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      message.pathLen == 0 ? 'direct' : '${message.pathLen}hop',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.labelSmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    message.getLocalizedTimeAgo(context),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // SAR marker content
            if (isSarMarker && message.sarMarkerType != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.sarCustomEmoji ?? message.sarMarkerType!.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message.sarNotes != null &&
                                  message.sarNotes!.isNotEmpty
                              ? message.sarNotes!
                              : message.sarMarkerType!.getLocalizedName(
                                  context,
                                ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!widget.isCompact)
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  if (message.sarGpsCoordinates != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${message.sarGpsCoordinates!.latitude.toStringAsFixed(5)}, ${message.sarGpsCoordinates!.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ]
            // Drawing message content (skip in compact mode - drawings hidden)
            else if (message.isDrawing &&
                message.drawingId != null &&
                !widget.isCompact)
              Consumer<DrawingProvider>(
                builder: (context, drawingProvider, child) {
                  final drawing = drawingProvider.getDrawingById(
                    message.drawingId!,
                  );

                  if (drawing == null) {
                    return Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }

                  final String drawingTypeLabel;
                  if (drawing is LineDrawing) {
                    drawingTypeLabel = AppLocalizations.of(
                      context,
                    )!.lineDrawing;
                  } else if (drawing is RectangleDrawing) {
                    drawingTypeLabel = AppLocalizations.of(
                      context,
                    )!.rectangleDrawing;
                  } else {
                    drawingTypeLabel = AppLocalizations.of(context)!.drawing;
                  }

                  final colorName = DrawingColors.colorToName(drawing.color);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DrawingMinimapPreview(drawing: drawing),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drawingTypeLabel,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: drawing.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black26,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  colorName,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                },
              )
            // Voice message content
            else if (message.isVoice &&
                message.voiceId != null &&
                !widget.isCompact)
              VoiceMessageBubble(message: message, isSentByMe: isOwnMessage)
            // Image message content (IE1 envelope)
            else if (ImageEnvelope.isEnvelope(message.text) &&
                !widget.isCompact)
              ImageMessageBubble(message: message, isSentByMe: isOwnMessage)
            // Regular message content
            else if (!message.isDrawing || widget.isCompact)
              Text(message.text, style: Theme.of(context).textTheme.bodyMedium),

            // Delivery status for sent messages (skip in compact mode)
            if (message.isSentMessage && !widget.isCompact) ...[
              const SizedBox(height: 6),
              // Debug: Log grouped message detection
              Builder(
                builder: (context) {
                  if (message.isGroupedMessage) {
                    debugPrint(
                      '🎯 [MessageBubble] Rendering grouped message: ${message.id}',
                    );
                    debugPrint(
                      '  Recipients: ${message.recipients?.length ?? 0}',
                    );
                    debugPrint(
                      '  Delivered: ${message.deliveredRecipientsCount}',
                    );
                    debugPrint('  Failed: ${message.failedRecipientsCount}');
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Show grouped message delivery count
              if (message.isGroupedMessage) ...[
                GestureDetector(
                  onTap: _toggleExpanded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            message.deliveredRecipientsCount ==
                                    message.recipients!.length
                                ? Icons.done_all
                                : message.failedRecipientsCount > 0
                                ? Icons.error_outline
                                : Icons.schedule,
                            size: 12,
                            color:
                                message.deliveredRecipientsCount ==
                                    message.recipients!.length
                                ? Colors.green
                                : message.failedRecipientsCount > 0
                                ? Colors.red
                                : Colors.orange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            message.deliveredRecipientsCount ==
                                    message.recipients!.length
                                ? AppLocalizations.of(context)!.allDelivered
                                : AppLocalizations.of(
                                    context,
                                  )!.deliveredToContacts(
                                    message.deliveredRecipientsCount,
                                    message.recipients!.length,
                                  ),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color:
                                      message.deliveredRecipientsCount ==
                                          message.recipients!.length
                                      ? Colors.green
                                      : message.failedRecipientsCount > 0
                                      ? Colors.red
                                      : Colors.orange,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).textTheme.labelSmall?.color,
                          ),
                        ],
                      ),
                      // Expandable recipient details
                      if (_isExpanded) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.recipientDetails,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              ...message.recipients!.map((recipient) {
                                final Color statusColor;
                                final IconData statusIcon;
                                final String statusText;

                                switch (recipient.deliveryStatus) {
                                  case MessageDeliveryStatus.delivered:
                                    statusColor = Colors.green;
                                    statusIcon = Icons.check_circle;
                                    statusText =
                                        recipient.roundTripTimeMs != null
                                        ? '${recipient.roundTripTimeMs}ms'
                                        : AppLocalizations.of(
                                            context,
                                          )!.delivered;
                                    break;
                                  case MessageDeliveryStatus.failed:
                                    statusColor = Colors.red;
                                    statusIcon = Icons.cancel;
                                    statusText = AppLocalizations.of(
                                      context,
                                    )!.failed;
                                    break;
                                  case MessageDeliveryStatus.sending:
                                  case MessageDeliveryStatus.sent:
                                  default:
                                    statusColor = Colors.orange;
                                    statusIcon = Icons.schedule;
                                    statusText = AppLocalizations.of(
                                      context,
                                    )!.pending;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 14,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          recipient.displayName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        statusText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ]
              // Show single message delivery status
              else
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      _getDeliveryStatusIcon(message.deliveryStatus),
                      size: 12,
                      color: _getDeliveryStatusColor(message.deliveryStatus),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child:
                            message.isChannelMessage &&
                                message.deliveryStatus ==
                                    MessageDeliveryStatus.sent
                            ? _buildChannelEchoStatus(context, message)
                            : Text(
                                message.getLocalizedDeliveryStatus(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: _getDeliveryStatusColor(
                                        message.deliveryStatus,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                      ),
                    ),
                    // Show retry button for failed messages
                    if (message.deliveryStatus ==
                        MessageDeliveryStatus.failed) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _retryFailedMessage(context, message),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Retry',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// System message bubble - compact log-style display
class SystemMessageBubble extends StatelessWidget {
  final Message message;

  const SystemMessageBubble({super.key, required this.message});

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue.shade300;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final level = message.senderName ?? 'info';
    final levelColor = _getLevelColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? levelColor.withValues(alpha: 0.1)
            : levelColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(_getLevelIcon(level), size: 14, color: levelColor),
          const SizedBox(width: 6),
          Text(
            message.getLocalizedTimeAgo(context),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
