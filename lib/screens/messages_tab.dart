import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../providers/connection_provider.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';
import '../widgets/messages/sar_update_sheet.dart';

class MessagesTab extends StatefulWidget {
  final VoidCallback onNavigateToMap;

  const MessagesTab({super.key, required this.onNavigateToMap});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _characterCount = 0;
  static const int _maxCharacters = 160;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _textController.text.length;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create message ID
      final messageId = '${DateTime.now().millisecondsSinceEpoch}_channel_sent';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Get current device's public key (first 6 bytes)
      final devicePublicKey = connectionProvider.deviceInfo.publicKey;
      final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

      // Create sent message object
      final sentMessage = Message(
        id: messageId,
        messageType: MessageType.channel,
        senderPublicKeyPrefix: senderPublicKeyPrefix,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp,
        text: text,
        receivedAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
        channelIdx: 0,
      );

      // Add to messages list with "sending" status
      messagesProvider.addSentMessage(sentMessage);

      // Send to public channel (channel 0)
      await connectionProvider.sendChannelMessage(
        channelIdx: 0,
        text: text,
        messageId: messageId,
      );

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent to public channel'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showSarDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SarUpdateSheet(
        onSend: (sarType, position, notes, roomPublicKey, sendToChannel) async {
          await _sendSarMessage(sarType, position, notes, roomPublicKey, sendToChannel);
        },
      ),
    );
  }

  Future<void> _sendSarMessage(
    SarMarkerType sarType,
    Position position,
    String? notes,
    Uint8List? roomPublicKey,
    bool sendToChannel,
  ) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!sendToChannel && roomPublicKey == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room to send SAR marker'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Format: S:<emoji>:<latitude>,<longitude>
      final sarMessage = 'S:${sarType.emoji}:${position.latitude},${position.longitude}';

      // Add notes if provided
      final fullMessage = notes != null && notes.isNotEmpty
          ? '$sarMessage $notes'
          : sarMessage;

      if (sendToChannel) {
        // Send to public channel (ephemeral, over-the-air only)
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: fullMessage,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sarType.displayName} marker broadcast to public channel'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Create message ID
        final messageId = '${DateTime.now().millisecondsSinceEpoch}_sent';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Get current device's public key (first 6 bytes)
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create sent message object with recipient public key for retry support
        final sentMessage = Message(
          id: messageId,
          messageType: MessageType.contact,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: fullMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          recipientPublicKey: roomPublicKey, // Store recipient for retry
          // SAR marker data is automatically added by SarMessageParser.enhanceMessage in MessagesProvider
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        // Send SAR message to selected room (persisted and immutable)
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: roomPublicKey!,
          text: fullMessage,
          messageId: messageId, // Pass message ID so it can be tracked
        );

        if (!sentSuccessfully) {
          // Mark message as failed if sending failed
          messagesProvider.markMessageFailed(messageId);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sarType.displayName} marker sent to room'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SAR marker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Removed _handleRefresh() - messages are synced automatically via PUSH_CODE_MSG_WAITING events

  List<Message> _getFilteredMessages(MessagesProvider messagesProvider) {
    // Show ALL messages regardless of recipient selection
    // The recipient selector only controls where NEW messages are sent
    return messagesProvider.getRecentMessages(count: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, messagesProvider, child) {
        final messages = _getFilteredMessages(messagesProvider);

        return Column(
          children: [
            // Messages list
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect to a device to start receiving messages',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _MessageBubble(
                          message: message,
                          onTap: message.isSarMarker &&
                                  message.sarGpsCoordinates != null
                              ? () {
                                  final mapProvider =
                                      context.read<MapProvider>();
                                  mapProvider.navigateToLocation(
                                    location: message.sarGpsCoordinates!,
                                    zoom: 15.0,
                                  );
                                  widget.onNavigateToMap();
                                }
                              : null,
                        );
                      },
                    ),
            ),

            // Message input area
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // SAR quick action button
                      IconButton(
                        icon: const Icon(Icons.add_location_alt),
                        tooltip: 'Send SAR marker',
                        onPressed: _showSarDialog,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text field with embedded send button
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLength: _maxCharacters,
                          maxLines: null,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: const TextStyle(fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            isDense: true,
                            counterText: _characterCount >= 150
                                ? '$_characterCount/$_maxCharacters'
                                : '',
                            counterStyle: TextStyle(
                              fontSize: 10,
                              color: _characterCount > _maxCharacters * 0.9
                                  ? Colors.orange
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                size: 22,
                                color: _textController.text.trim().isEmpty
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _textController.text.trim().isEmpty
                                  ? null
                                  : _sendMessage,
                              tooltip: 'Send',
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;

  const _MessageBubble({
    required this.message,
    this.onTap,
  });

  Future<void> _retryFailedMessage(BuildContext context, Message failedMessage) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to device'),
          backgroundColor: Colors.red,
        ),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot retry: recipient information missing'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Resend to the same room
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: failedMessage.recipientPublicKey!,
          text: failedMessage.text,
          messageId: retryMessageId,
        );

        if (!sentSuccessfully) {
          messagesProvider.markMessageFailed(retryMessageId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to resend message'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retrying message...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (failedMessage.messageType == MessageType.channel) {
        // Channel message retry
        await connectionProvider.sendChannelMessage(
          channelIdx: failedMessage.channelIdx ?? 0,
          text: failedMessage.text,
          messageId: retryMessageId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retrying message...'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retry failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSarMarker = message.isSarMarker;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Debug: Log message details
    if (message.text.startsWith('S:')) {
      debugPrint('🎨 [MessageBubble] Rendering SAR message:');
      debugPrint('   Text: ${message.text}');
      debugPrint('   isSarMarker: $isSarMarker');
      debugPrint('   sarMarkerType: ${message.sarMarkerType}');
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSarMarker
              ? _getSarMarkerColor(context, isDarkMode)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: isSarMarker
              ? Border.all(
                  color: _getSarMarkerBorderColor(context, isDarkMode),
                  width: 3,
                )
              : null,
          boxShadow: isSarMarker
              ? [
                  BoxShadow(
                    color: _getSarMarkerBorderColor(context, isDarkMode).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Sender and time
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
                          'SAR ALERT',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (message.isChannelMessage)
                    const Icon(Icons.tag, size: 16)
                  else
                    const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    message.displaySender,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
                const Spacer(),
                Text(
                  message.timeAgo,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: isSarMarker ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SAR marker content (simplified design matching message history)
            if (isSarMarker && message.sarMarkerType != null) ...[
              Row(
                children: [
                  Text(
                    message.sarMarkerType!.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sarMarkerType!.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (message.sarGpsCoordinates != null)
                          Text(
                            '${message.sarGpsCoordinates!.latitude.toStringAsFixed(5)}, ${message.sarGpsCoordinates!.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to view on map',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ]
            // Regular message content
            else
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            // Delivery status for sent messages
            if (message.isSentMessage) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getDeliveryStatusIcon(message.deliveryStatus),
                    size: 14,
                    color: _getDeliveryStatusColor(message.deliveryStatus),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.deliveryStatusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getDeliveryStatusColor(message.deliveryStatus),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  // Show retry button for failed messages
                  if (message.deliveryStatus == MessageDeliveryStatus.failed) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _retryFailedMessage(context, message),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Retry',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  Color _getSarMarkerColor(BuildContext context, bool isDarkMode) {
    if (message.sarMarkerType == null) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    // Use type-specific colors with alpha for background
    switch (message.sarMarkerType!) {
      case SarMarkerType.foundPerson:
        return isDarkMode
            ? const Color(0xFF1B5E20).withValues(alpha: 0.4)  // Dark green
            : const Color(0xFFC8E6C9).withValues(alpha: 0.9);  // Light green
      case SarMarkerType.fire:
        return isDarkMode
            ? const Color(0xFFB71C1C).withValues(alpha: 0.4)  // Dark red
            : const Color(0xFFFFCDD2).withValues(alpha: 0.9);  // Light red
      case SarMarkerType.stagingArea:
        return isDarkMode
            ? const Color(0xFF0D47A1).withValues(alpha: 0.4)  // Dark blue
            : const Color(0xFFBBDEFB).withValues(alpha: 0.9);  // Light blue
      case SarMarkerType.object:
        return isDarkMode
            ? const Color(0xFF4A148C).withValues(alpha: 0.4)  // Dark purple
            : const Color(0xFFE1BEE7).withValues(alpha: 0.9);  // Light purple
      case SarMarkerType.unknown:
        return isDarkMode
            ? const Color(0xFF424242).withValues(alpha: 0.4)  // Dark gray
            : const Color(0xFFEEEEEE).withValues(alpha: 0.9);  // Light gray
    }
  }

  Color _getSarMarkerBorderColor(BuildContext context, bool isDarkMode) {
    if (message.sarMarkerType == null) {
      return Theme.of(context).colorScheme.primary;
    }

    // Use vibrant type-specific colors for borders
    switch (message.sarMarkerType!) {
      case SarMarkerType.foundPerson:
        return const Color(0xFF4CAF50);  // Green
      case SarMarkerType.fire:
        return const Color(0xFFF44336);  // Red
      case SarMarkerType.stagingArea:
        return const Color(0xFF2196F3);  // Blue
      case SarMarkerType.object:
        return const Color(0xFF9C27B0);  // Purple
      case SarMarkerType.unknown:
        return const Color(0xFF9E9E9E);  // Gray
    }
  }

  /// Extract notes from SAR message text
  /// Returns text after the SAR marker format, or null if none
  String? _extractNotesFromMessage(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('S:')) return null;

    // Extract first line
    final firstLine = trimmed.split('\n').first;

    // Find the end of coordinates (after second colon and comma-separated numbers)
    final pattern = RegExp(r'^S:.:(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final match = pattern.firstMatch(firstLine);
    if (match == null) return null;

    // Extract notes from same line
    String? notes;
    if (match.end < firstLine.length) {
      notes = firstLine.substring(match.end).trim();
    }

    // Check for multi-line notes
    final lines = trimmed.split('\n');
    if (lines.length > 1) {
      final additionalNotes = lines.sublist(1).join('\n').trim();
      if (additionalNotes.isNotEmpty) {
        notes = notes != null && notes.isNotEmpty
            ? '$notes\n$additionalNotes'
            : additionalNotes;
      }
    }

    return notes != null && notes.isNotEmpty ? notes : null;
  }
}

