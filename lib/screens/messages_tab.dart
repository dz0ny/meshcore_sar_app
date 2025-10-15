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
import '../widgets/contacts/direct_message_sheet.dart';
import '../utils/toast_logger.dart';

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

  /// Helper method to compare two public keys for equality
  bool _publicKeysMatch(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) return false;
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateCharacterCount);
    // Mark all messages as read when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().markAllAsRead();
    });
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
      ToastLogger.error(context, 'Not connected to device');
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
      ToastLogger.success(context, 'Message sent to public channel');
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to send: $e');
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
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    if (!sendToChannel && roomPublicKey == null) {
      if (!mounted) return;
      ToastLogger.error(context, 'Please select a room to send SAR marker');
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
        ToastLogger.warning(context, '${sarType.displayName} marker broadcast to public channel');
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

        // Look up the room contact for path logging
        final contactsProvider = context.read<ContactsProvider>();
        final roomContact = contactsProvider.contacts.where((c) {
          return c.publicKey.length >= roomPublicKey!.length &&
                 _publicKeysMatch(c.publicKey, roomPublicKey!);
        }).firstOrNull;

        // Send SAR message to selected room (persisted and immutable)
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: roomPublicKey!,
          text: fullMessage,
          messageId: messageId, // Pass message ID so it can be tracked
          contact: roomContact, // Include contact for path status logging
        );

        if (!sentSuccessfully) {
          // Mark message as failed if sending failed
          messagesProvider.markMessageFailed(messageId);
        }

        if (!mounted) return;
        ToastLogger.success(context, '${sarType.displayName} marker sent to room');
      }
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to send SAR marker: $e');
    }
  }


  /// Handle pull-to-refresh for manual message sync
  /// This is a FALLBACK mechanism - messages are normally synced automatically via PUSH_CODE_MSG_WAITING
  Future<void> _handleRefresh() async {
    final connectionProvider = context.read<ConnectionProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.warning(context, 'Not connected - cannot sync messages');
      return;
    }

    try {
      print('🔄 [MessagesTab] Manual refresh triggered - syncing messages');
      final messageCount = await connectionProvider.syncAllMessages();
      print('✅ [MessagesTab] Synced $messageCount message(s)');

      if (!mounted) return;
      if (messageCount > 0) {
        ToastLogger.success(context, 'Synced $messageCount message(s)');
      } else {
        ToastLogger.info(context, 'No new messages');
      }
    } catch (e) {
      print('❌ [MessagesTab] Sync error: $e');
      if (!mounted) return;
      ToastLogger.error(context, 'Sync failed: $e');
    }
  }

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
            // Messages list with pull-to-refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: messages.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
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
                                    'Pull down to sync messages',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];

                        // Display system messages with minimal styling
                        if (message.isSystemMessage) {
                          return _SystemMessageBubble(message: message);
                        }

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

  /// Helper method to compare two public keys for equality
  bool _publicKeysMatch(Uint8List key1, Uint8List key2) {
    if (key1.length != key2.length) return false;
    for (int i = 0; i < key1.length; i++) {
      if (key1[i] != key2[i]) return false;
    }
    return true;
  }

  Future<void> _retryFailedMessage(BuildContext context, Message failedMessage) async {
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
          ToastLogger.error(context, 'Cannot retry: recipient information missing');
          return;
        }

        // Look up the room contact for path logging
        final contactsProvider = context.read<ContactsProvider>();
        final roomContact = contactsProvider.contacts.where((c) {
          return c.publicKey.length >= failedMessage.recipientPublicKey!.length &&
                 _publicKeysMatch(c.publicKey, failedMessage.recipientPublicKey!);
        }).firstOrNull;

        // Resend to the same room
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: failedMessage.recipientPublicKey!,
          text: failedMessage.text,
          messageId: retryMessageId,
          contact: roomContact, // Include contact for path status logging
        );

        if (!sentSuccessfully) {
          messagesProvider.markMessageFailed(retryMessageId);
          ToastLogger.error(context, 'Failed to resend message');
        } else {
          ToastLogger.info(context, 'Retrying message...');
        }
      } else if (failedMessage.messageType == MessageType.channel) {
        // Channel message retry
        await connectionProvider.sendChannelMessage(
          channelIdx: failedMessage.channelIdx ?? 0,
          text: failedMessage.text,
          messageId: retryMessageId,
        );

        ToastLogger.info(context, 'Retrying message...');
      }
    } catch (e) {
      ToastLogger.error(context, 'Retry failed: $e');
    }
  }

  void _showMessageOptions(BuildContext context) {
    // Determine if this is own message
    final connectionProvider = context.read<ConnectionProvider>();
    final selfPublicKey = connectionProvider.deviceInfo.publicKey;
    final isOwnMessage = message.isSentMessage || message.isFromSelf(selfPublicKey);

    // Check if we can reply to this message (must be contact message from someone else)
    final canReply = message.isContactMessage &&
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
              title: const Text('Copy text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ToastLogger.success(context, 'Text copied to clipboard');
              },
            ),
            // Delete message option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete message', style: TextStyle(color: Colors.red)),
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
        .sublist(0, message.senderPublicKeyPrefix!.length < 6 ? message.senderPublicKeyPrefix!.length : 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');

    final senderContact = contactsProvider.contacts.where((c) {
      return c.publicKeyHex.startsWith(senderKeyHex);
    }).firstOrNull;

    if (senderContact == null) {
      ToastLogger.error(context, 'Cannot reply: contact not found');
      return;
    }

    // Show direct message sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DirectMessageSheet(contact: senderContact),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final messagesProvider = context.read<MessagesProvider>();
              messagesProvider.deleteMessage(message.id);
              Navigator.pop(context);
              ToastLogger.info(context, 'Message deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSarMarker = message.isSarMarker;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine if this is own message
    // Use isSentMessage (delivery status) as primary check since it's more reliable
    // after loading from storage
    final connectionProvider = context.read<ConnectionProvider>();
    final selfPublicKey = connectionProvider.deviceInfo.publicKey;
    final isOwnMessage = message.isSentMessage || message.isFromSelf(selfPublicKey);

    // Debug logging for sent messages
    if (message.isSentMessage) {
      debugPrint('🔍 [MessageBubble] Sent message check:');
      debugPrint('   Message ID: ${message.id}');
      debugPrint('   Delivery Status: ${message.deliveryStatus.name}');
      debugPrint('   isSentMessage: ${message.isSentMessage}');
      debugPrint('   isOwnMessage: $isOwnMessage');
      debugPrint('   Has recipientPublicKey: ${message.recipientPublicKey != null}');
      if (message.recipientPublicKey != null) {
        debugPrint('   Recipient key (first 12 hex): ${message.recipientPublicKey!.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
      }
    }

    // Look up contact information for rich display name
    final contactsProvider = context.read<ContactsProvider>();
    dynamic senderContact;
    if (message.senderPublicKeyPrefix != null && !isOwnMessage) {
      // Find contact by public key prefix (first 6 bytes)
      final senderKeyHex = message.senderPublicKeyPrefix!
          .sublist(0, message.senderPublicKeyPrefix!.length < 6 ? message.senderPublicKeyPrefix!.length : 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');

      senderContact = contactsProvider.contacts.where((c) {
        return c.publicKeyHex.startsWith(senderKeyHex);
      }).firstOrNull;
    }

    // Get rich display name (with emoji if available)
    final displayName = isOwnMessage
        ? 'You'
        : message.getRichDisplayName(senderContact);

    // For sent direct messages, look up recipient contact
    dynamic recipientContact;
    String? recipientDisplayName;
    if (isOwnMessage && message.isContactMessage && message.recipientPublicKey != null) {
      // Find recipient by public key
      final recipientKeyHex = message.recipientPublicKey!
          .sublist(0, message.recipientPublicKey!.length < 6 ? message.recipientPublicKey!.length : 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');

      debugPrint('🔍 [MessageBubble] Looking up recipient:');
      debugPrint('   Recipient key hex: $recipientKeyHex');
      debugPrint('   Available contacts: ${contactsProvider.contacts.length}');

      // Debug: Print all contact keys for comparison
      for (final c in contactsProvider.contacts) {
        debugPrint('   Contact: ${c.displayName ?? c.advName}');
        debugPrint('      Key: ${c.publicKeyHex}');
        debugPrint('      First 12 chars: ${c.publicKeyHex.substring(0, c.publicKeyHex.length >= 12 ? 12 : c.publicKeyHex.length)}');
        debugPrint('      Matches: ${c.publicKeyHex.startsWith(recipientKeyHex)}');
      }

      recipientContact = contactsProvider.contacts.where((c) {
        final matches = c.publicKeyHex.startsWith(recipientKeyHex);
        if (matches) {
          debugPrint('   ✅ Found match: ${c.displayName ?? c.advName}');
        }
        return matches;
      }).firstOrNull;

      if (recipientContact != null) {
        // Get rich display name with emoji
        final roleEmoji = recipientContact.roleEmoji;
        if (roleEmoji != null && roleEmoji.isNotEmpty) {
          recipientDisplayName = '$roleEmoji ${recipientContact.displayName}';
        } else {
          recipientDisplayName = recipientContact.displayName ?? recipientContact.advName;
        }
        debugPrint('   Final recipient name: $recipientDisplayName');
      } else {
        debugPrint('   ❌ No recipient contact found');
      }
    }

    // Debug: Log message details
    if (message.text.startsWith('S:')) {
      debugPrint('🎨 [MessageBubble] Rendering SAR message:');
      debugPrint('   Text: ${message.text}');
      debugPrint('   isSarMarker: $isSarMarker');
      debugPrint('   sarMarkerType: ${message.sarMarkerType}');
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSarMarker
              ? _getSarMarkerColor(context, isDarkMode)
              : _getMessageBubbleColor(context, isOwnMessage, isDarkMode),
          borderRadius: BorderRadius.circular(12),
          border: isSarMarker
              ? Border.all(
                  color: _getSarMarkerBorderColor(context, isDarkMode),
                  width: 2,
                )
              : isOwnMessage
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : !message.isRead && !message.isSentMessage && !message.isSystemMessage
                      ? Border.all(
                          color: Colors.blue,
                          width: 1.5,
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
                // Unread indicator badge
                if (!message.isRead && !message.isSentMessage && !message.isSystemMessage && !isSarMarker)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
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
                  if (isOwnMessage)
                    Icon(Icons.account_circle, size: 16, color: Theme.of(context).colorScheme.primary)
                  else if (message.isChannelMessage)
                    const Icon(Icons.tag, size: 16)
                  else
                    const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOwnMessage ? Theme.of(context).colorScheme.primary : null,
                        ),
                  ),
                  // Show recipient for sent direct messages
                  if (isOwnMessage && message.isContactMessage && recipientDisplayName != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipientDisplayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
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
            const SizedBox(height: 8),

            // SAR marker content (simplified design matching message history)
            if (isSarMarker && message.sarMarkerType != null) ...[
              Row(
                children: [
                  Text(
                    message.sarMarkerType!.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sarMarkerType!.displayName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (message.sarGpsCoordinates != null)
                          Text(
                            '${message.sarGpsCoordinates!.latitude.toStringAsFixed(5)}, ${message.sarGpsCoordinates!.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
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
                    message.deliveryStatusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _getDeliveryStatusColor(message.deliveryStatus),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  // Show retry button for failed messages
                  if (message.deliveryStatus == MessageDeliveryStatus.failed) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _retryFailedMessage(context, message),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Color _getMessageBubbleColor(BuildContext context, bool isOwnMessage, bool isDarkMode) {
    if (isOwnMessage) {
      // Own messages: slightly highlighted with primary color tint
      return isDarkMode
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15);
    } else {
      // Others' messages: default surface color
      return Theme.of(context).colorScheme.surfaceVariant;
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

/// System message bubble - compact log-style display
class _SystemMessageBubble extends StatelessWidget {
  final Message message;

  const _SystemMessageBubble({required this.message});

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
          Icon(
            _getLevelIcon(level),
            size: 14,
            color: levelColor,
          ),
          const SizedBox(width: 6),
          Text(
            message.timeAgo,
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

