import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../models/sar_marker.dart';
import '../../models/sar_template.dart';
import '../../models/map_drawing.dart';
import '../../providers/messages_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/drawing_provider.dart';
import '../contacts/direct_message_sheet.dart';
import '../drawing_minimap_preview.dart';
import '../../services/sar_template_service.dart';
import '../../utils/toast_logger.dart';
import '../../utils/sar_message_parser.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/message_extensions.dart';

/// Reusable message bubble widget that displays messages with various types:
/// - Regular text messages (channel or direct)
/// - SAR markers (styled with SAR-specific colors and badges)
/// - Drawing messages (with minimap preview)
/// - System messages (compact log-style display)
class MessageBubble extends StatelessWidget {
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

  /// Helper method to compare two public keys for equality
  bool _publicKeysMatch(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) return false;
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) return false;
    }
    return true;
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
            'Cannot retry: recipient information missing',
          );
          return;
        }

        // Look up the room contact for path logging
        final contactsProvider = context.read<ContactsProvider>();
        final roomContact = contactsProvider.contacts.where((c) {
          return c.publicKey.length >=
                  failedMessage.recipientPublicKey!.length &&
              _publicKeysMatch(c.publicKey, failedMessage.recipientPublicKey!);
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
        message.isSentMessage || message.isFromSelf(selfPublicKey);

    // Check if we can reply to this message (must be contact message from someone else)
    final canReply =
        message.isContactMessage &&
        !isOwnMessage &&
        message.senderPublicKeyPrefix != null;

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
                title: const Text('Reply'),
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
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ToastLogger.success(
                  context,
                  AppLocalizations.of(context)!.textCopiedToClipboard,
                );
              },
            ),
            // Save as Template option (only for SAR markers without existing template)
            if (message.isSarMarker)
              Builder(
                builder: (context) {
                  // Extract emoji from SAR message
                  final sarInfo = SarMessageParser.parse(message.text);
                  if (sarInfo == null || sarInfo.emoji.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Check if template with this emoji already exists
                  final sarTemplateService = SarTemplateService();
                  final templateExists = sarTemplateService.templates
                      .any((t) => t.emoji == sarInfo.emoji);

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
            if (message.isSarMarker && message.sarGpsCoordinates != null)
              ListTile(
                leading: const Icon(Icons.share_location),
                title: Text(AppLocalizations.of(context)!.shareLocation),
                onTap: () {
                  Navigator.pop(context);
                  _shareLocation(context);
                },
              ),
            // Navigate to drawing option (only for drawing messages)
            if (message.isDrawing && message.drawingId != null)
              ListTile(
                leading: const Icon(Icons.map),
                title: Text(AppLocalizations.of(context)!.navigateToDrawing),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDrawing(context);
                },
              ),
            // Copy coordinates option (only for drawing messages)
            if (message.isDrawing && message.drawingId != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(AppLocalizations.of(context)!.copyCoordinates),
                onTap: () {
                  Navigator.pop(context);
                  _copyDrawingCoordinates(context);
                },
              ),
            // Hide from map option (only for drawing messages)
            if (message.isDrawing && message.drawingId != null)
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: Text(AppLocalizations.of(context)!.hideFromMap),
                onTap: () {
                  Navigator.pop(context);
                  _hideDrawingFromMap(context);
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

  void _showReplySheet(BuildContext context) {
    // Find the sender contact by public key prefix
    final contactsProvider = context.read<ContactsProvider>();

    if (message.senderPublicKeyPrefix == null) {
      ToastLogger.error(context, 'Cannot reply: sender information missing');
      return;
    }

    // Find contact by public key prefix (first 6 bytes)
    final senderKeyHex = message.senderPublicKeyPrefix!
        .sublist(
          0,
          message.senderPublicKeyPrefix!.length < 6
              ? message.senderPublicKeyPrefix!.length
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
      builder: (context) => DirectMessageSheet(
        contact: senderContact,
      ),
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
              messagesProvider.deleteMessage(message.id);

              // Also delete the drawing if this is a drawing message
              if (message.isDrawing && message.drawingId != null) {
                final drawingProvider = context.read<DrawingProvider>();
                drawingProvider.removeDrawing(message.drawingId!);
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
    if (message.sarGpsCoordinates == null) {
      ToastLogger.error(context, 'No GPS coordinates available');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final coords = message.sarGpsCoordinates!;

    // Get SAR marker type emoji/name
    String markerInfo = '';
    if (message.sarMarkerType != null) {
      markerInfo = message.sarMarkerType!.emoji;
      if (message.sarNotes != null && message.sarNotes!.isNotEmpty) {
        markerInfo += ' ${message.sarNotes}';
      }
    } else if (message.sarCustomEmoji != null) {
      markerInfo = message.sarCustomEmoji!;
      if (message.sarNotes != null && message.sarNotes!.isNotEmpty) {
        markerInfo += ' ${message.sarNotes}';
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
    if (!message.isSarMarker) {
      ToastLogger.error(context, 'Not a SAR marker');
      return;
    }

    try {
      // Parse the SAR message to create a template
      final template = SarTemplate.fromSarMessage(message.text);

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
      ToastLogger.success(
        context,
        AppLocalizations.of(context)!.templateSaved,
      );
    } catch (e) {
      debugPrint('Error saving template: $e');
      if (!context.mounted) return;
      ToastLogger.error(context, 'Failed to save template: $e');
    }
  }

  void _navigateToDrawing(BuildContext context) {
    if (message.drawingId == null) return;
    onNavigateToMap?.call();
  }

  void _copyDrawingCoordinates(BuildContext context) {
    if (message.drawingId == null) return;

    final drawingProvider = context.read<DrawingProvider>();
    final drawing = drawingProvider.getDrawingById(message.drawingId!);

    if (drawing == null) {
      ToastLogger.error(context, 'Drawing not found');
      return;
    }

    // Format coordinates based on drawing type
    String coordinatesText;
    if (drawing is LineDrawing) {
      coordinatesText = drawing.points
          .map(
            (p) => '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
          )
          .join('\n');
    } else if (drawing is RectangleDrawing) {
      coordinatesText = drawing.corners
          .map((p) => '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}')
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
    if (message.drawingId == null) return;

    final drawingProvider = context.read<DrawingProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    // Remove the drawing from map and delete the message
    drawingProvider.removeDrawingAndMessage(message.drawingId!, messagesProvider);

    ToastLogger.success(
      context,
      'Drawing removed from map',
    );
  }

  Color _getMessageBubbleColor(
    BuildContext context,
    bool isOwnMessage,
    bool isDarkMode,
  ) {
    if (isOwnMessage) {
      // Own messages: slightly highlighted with primary color tint
      return isDarkMode
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15);
    } else {
      // Others' messages: default surface color
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _getSarMarkerColor(BuildContext context, bool isDarkMode) {
    if (message.sarMarkerType == null) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    // Use type-specific colors with alpha for background
    switch (message.sarMarkerType!) {
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
    if (message.sarMarkerType == null) {
      return Theme.of(context).colorScheme.primary;
    }

    // Use vibrant type-specific colors for borders
    switch (message.sarMarkerType!) {
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

  @override
  Widget build(BuildContext context) {
    // Display system messages with minimal styling
    if (message.isSystemMessage) {
      return SystemMessageBubble(message: message);
    }

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

    // For sent direct messages, look up recipient contact
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
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: isCompact ? null : () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : isSarMarker
              ? _getSarMarkerColor(context, isDarkMode)
              : message.isDrawing
              ? (isDarkMode
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08))
              : _getMessageBubbleColor(context, isOwnMessage, isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  width: 2,
                )
              : isOwnMessage
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : !message.isRead &&
                    !message.isSentMessage &&
                    !message.isSystemMessage
              ? Border.all(color: Colors.blue, width: 1.5)
              : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ]
              : isSarMarker || message.isDrawing
              ? [
                  BoxShadow(
                    color: (isSarMarker
                        ? _getSarMarkerBorderColor(context, isDarkMode)
                        : Theme.of(context).colorScheme.primary
                    ).withValues(alpha: 0.3),
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
                          const Icon(
                            Icons.draw,
                            size: 16,
                            color: Colors.white,
                          ),
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
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOwnMessage
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Show recipient for sent direct messages
                if (isOwnMessage &&
                    message.isContactMessage &&
                    recipientDisplayName != null &&
                    !isCompact) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      recipientDisplayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                // Time for regular messages (not shown for SAR/drawing as it's already above)
                if (!isSarMarker && !message.isDrawing)
                  Text(
                    message.getLocalizedTimeAgo(context),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // SAR marker content
            if (isSarMarker && message.sarMarkerType != null) ...[
              Row(
                children: [
                  Text(
                    message.sarCustomEmoji ?? message.sarMarkerType!.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sarNotes != null &&
                                  message.sarNotes!.isNotEmpty
                              ? message.sarNotes!
                              : message.sarMarkerType!.getLocalizedName(
                                  context,
                                ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (message.sarGpsCoordinates != null)
                          Text(
                            '${message.sarGpsCoordinates!.latitude.toStringAsFixed(5)}, ${message.sarGpsCoordinates!.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                      ],
                    ),
                  ),
                  if (!isCompact)
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ]
            // Drawing message content (skip in compact mode - drawings hidden)
            else if (message.isDrawing && message.drawingId != null && !isCompact)
              Consumer<DrawingProvider>(
                builder: (context, drawingProvider, child) {
                  final drawing = drawingProvider.getDrawingById(message.drawingId!);

                  if (drawing == null) {
                    return Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }

                  final String drawingTypeLabel;
                  if (drawing is LineDrawing) {
                    drawingTypeLabel = AppLocalizations.of(context)!.lineDrawing;
                  } else if (drawing is RectangleDrawing) {
                    drawingTypeLabel = AppLocalizations.of(context)!.rectangleDrawing;
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
            // Regular message content
            else if (!message.isDrawing || isCompact)
              Text(message.text, style: Theme.of(context).textTheme.bodyMedium),

            // Delivery status for sent messages (skip in compact mode)
            if (message.isSentMessage && !isCompact) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getDeliveryStatusIcon(message.deliveryStatus),
                    size: 12,
                    color: _getDeliveryStatusColor(message.deliveryStatus),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    message.getLocalizedDeliveryStatus(context),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _getDeliveryStatusColor(message.deliveryStatus),
                      fontStyle: FontStyle.italic,
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
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
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
