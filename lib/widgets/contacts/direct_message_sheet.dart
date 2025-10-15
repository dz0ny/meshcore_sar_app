import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/messages_provider.dart';
import '../../utils/toast_logger.dart';

class DirectMessageSheet extends StatefulWidget {
  final Contact contact;

  const DirectMessageSheet({super.key, required this.contact});

  @override
  State<DirectMessageSheet> createState() => _DirectMessageSheetState();
}

class _DirectMessageSheetState extends State<DirectMessageSheet> {
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

  Future<void> _sendDirectMessage() async {
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
      final messageId = '${DateTime.now().millisecondsSinceEpoch}_dm_sent';
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
        text: text,
        receivedAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
        recipientPublicKey: widget.contact.publicKey, // Store recipient for retry
      );

      // Add to messages list with "sending" status
      messagesProvider.addSentMessage(sentMessage);

      // Send direct message to contact (include contact for path logging)
      final sentSuccessfully = await connectionProvider.sendTextMessage(
        contactPublicKey: widget.contact.publicKey,
        text: text,
        messageId: messageId, // Pass message ID for tracking
        contact: widget.contact,
      );

      if (!sentSuccessfully) {
        // Mark message as failed if sending failed
        messagesProvider.markMessageFailed(messageId);
      }

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ToastLogger.success(context, 'Direct message sent to ${widget.contact.displayName}');
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to send: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Direct Message',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.contact.displayName,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Spacer to keep title centered
              ],
            ),
          ),

          // Info banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This message will be sent directly to ${widget.contact.displayName}. It will also appear in the main messages feed.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Spacer(),

          // Message input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLength: _maxCharacters,
                  maxLines: 3,
                  autofocus: true,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterText: _characterCount >= 150
                        ? '$_characterCount/$_maxCharacters'
                        : '',
                    counterStyle: TextStyle(
                      fontSize: 11,
                      color: _characterCount > _maxCharacters * 0.9
                          ? Colors.orange
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendDirectMessage(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _textController.text.trim().isEmpty
                        ? null
                        : _sendDirectMessage,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Direct Message'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
