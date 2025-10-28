import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/drawing_provider.dart';
import '../providers/app_provider.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../widgets/messages/sar_update_sheet.dart';
import '../widgets/messages/recipient_selector_sheet.dart';
import '../widgets/messages/message_bubble.dart';
import '../services/message_destination_preferences.dart';
import '../utils/toast_logger.dart';
import '../l10n/app_localizations.dart';

class MessagesTab extends StatefulWidget {
  final VoidCallback onNavigateToMap;

  const MessagesTab({super.key, required this.onNavigateToMap});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _characterCount = 0;
  static const int _maxCharacters = 160;
  String? _highlightedMessageId;

  // Message destination state
  String _destinationType =
      MessageDestinationPreferences.destinationTypeChannel;
  Contact? _selectedRecipient;

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
    // Load saved message destination
    _loadSavedDestination();
    // Mark all messages as read when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().markAllAsRead();
      _checkForNavigationRequest();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload saved destination and check for navigation request whenever dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedDestination();
      _checkForNavigationRequest();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkForNavigationRequest() {
    final messagesProvider = context.read<MessagesProvider>();
    final targetMessageId = messagesProvider.targetMessageId;

    if (targetMessageId != null) {
      _scrollToMessage(targetMessageId);
      messagesProvider.clearMessageNavigation();
    }
  }

  void _scrollToMessage(String messageId) {
    final messagesProvider = context.read<MessagesProvider>();
    final messages = _getFilteredMessages(messagesProvider);

    final messageIndex = messages.indexWhere((m) => m.id == messageId);

    if (messageIndex != -1 && _scrollController.hasClients) {
      // Calculate position - accounting for reverse list
      final itemHeight = 80.0; // Approximate height of a message bubble
      final targetOffset = messageIndex * itemHeight;

      // Scroll to the message
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      // Highlight the message briefly
      setState(() {
        _highlightedMessageId = messageId;
      });

      // Clear highlight after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _textController.text.length;
    });
  }

  /// Load saved message destination from preferences
  Future<void> _loadSavedDestination() async {
    final savedDestination =
        await MessageDestinationPreferences.getDestination();

    if (savedDestination == null || !mounted) {
      // Default to public channel
      return;
    }

    final type = savedDestination['type']!;
    final publicKey = savedDestination['publicKey'];

    setState(() {
      _destinationType = type;
    });

    // If it's a contact or room, try to find it in the contacts list
    if (publicKey != null && mounted) {
      final contactsProvider = context.read<ContactsProvider>();
      final contact = contactsProvider.contacts.where((c) {
        return c.publicKeyHex == publicKey;
      }).firstOrNull;

      if (contact != null) {
        setState(() {
          _selectedRecipient = contact;
        });
      } else {
        // Contact/room not found, fallback to public channel
        debugPrint(
          '⚠️ [MessagesTab] Saved recipient not found, falling back to public channel',
        );
        setState(() {
          _destinationType =
              MessageDestinationPreferences.destinationTypeChannel;
          _selectedRecipient = null;
        });
        await MessageDestinationPreferences.clearDestination();
      }
    }
  }

  /// Show recipient selector bottom sheet
  void _showRecipientSelector() {
    final contactsProvider = context.read<ContactsProvider>();

    // Filter contacts by type
    final contacts = contactsProvider.contacts
        .where((c) => c.type == ContactType.chat)
        .toList();
    final rooms = contactsProvider.contacts
        .where((c) => c.type == ContactType.room)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipientSelectorSheet(
        contacts: contacts,
        rooms: rooms,
        currentDestinationType: _destinationType,
        currentRecipientPublicKey: _selectedRecipient?.publicKeyHex,
        onSelect: _onRecipientSelected,
      ),
    );
  }

  /// Handle recipient selection
  Future<void> _onRecipientSelected(String type, Contact? recipient) async {
    // Get display name before async gap
    final recipientName =
        type == MessageDestinationPreferences.destinationTypeChannel
        ? AppLocalizations.of(context)!.publicChannel
        : (recipient?.displayName ?? recipient?.advName ?? 'Unknown');

    setState(() {
      _destinationType = type;
      _selectedRecipient = recipient;
    });

    // Save to preferences
    await MessageDestinationPreferences.setDestination(
      type,
      recipientPublicKey: recipient?.publicKeyHex,
    );

    // Show confirmation toast
    if (!mounted) return;
  }

  /// Get icon for current destination type
  IconData _getDestinationIcon() {
    if (_destinationType ==
        MessageDestinationPreferences.destinationTypeChannel) {
      return Icons.public;
    } else if (_destinationType ==
        MessageDestinationPreferences.destinationTypeRoom) {
      return Icons.meeting_room;
    } else {
      return Icons.person;
    }
  }

  /// Get tooltip for destination button
  String _getDestinationTooltip() {
    final l10n = AppLocalizations.of(context)!;
    if (_destinationType ==
        MessageDestinationPreferences.destinationTypeChannel) {
      return '${l10n.publicChannel} (tap to change)';
    } else if (_selectedRecipient != null) {
      final recipientName =
          _selectedRecipient!.displayName ?? _selectedRecipient!.advName;
      return '$recipientName (tap to change)';
    }
    return 'Select recipient';
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final contactsProvider = context.read<ContactsProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    try {
      // Check destination type and send accordingly
      if (_destinationType ==
          MessageDestinationPreferences.destinationTypeChannel) {
        // Send to public channel
        await _sendToChannel(text, connectionProvider, messagesProvider);
      } else if (_selectedRecipient != null) {
        // Send to contact or room
        await _sendToRecipient(
          text,
          connectionProvider,
          messagesProvider,
          contactsProvider,
        );
      } else {
        // Fallback to public channel if no recipient selected
        debugPrint(
          '⚠️ [MessagesTab] No recipient selected, falling back to channel',
        );
        await _sendToChannel(text, connectionProvider, messagesProvider);
      }

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to send: $e');
    }
  }

  /// Send message to public channel
  Future<void> _sendToChannel(
    String text,
    ConnectionProvider connectionProvider,
    MessagesProvider messagesProvider,
  ) async {
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
  }

  /// Send message to contact or room
  Future<void> _sendToRecipient(
    String text,
    ConnectionProvider connectionProvider,
    MessagesProvider messagesProvider,
    ContactsProvider contactsProvider,
  ) async {
    if (_selectedRecipient == null) return;

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
      text: text,
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
      recipientPublicKey: _selectedRecipient!.publicKey,
    );

    // Add to messages list with "sending" status
    messagesProvider.addSentMessage(sentMessage);

    // Send message to selected recipient
    final sentSuccessfully = await connectionProvider.sendTextMessage(
      contactPublicKey: _selectedRecipient!.publicKey,
      text: text,
      messageId: messageId,
      contact: _selectedRecipient,
    );

    if (!sentSuccessfully) {
      // Mark message as failed if sending failed
      messagesProvider.markMessageFailed(messageId);
    }
  }

  void _showSarDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SarUpdateSheet(
        onSend:
            (
              emoji,
              name,
              position,
              roomPublicKey,
              sendToChannel,
              colorIndex,
            ) async {
              await _sendSarMessage(
                emoji,
                name,
                position,
                roomPublicKey,
                sendToChannel,
                colorIndex,
              );
            },
      ),
    );
  }

  Future<void> _sendSarMessage(
    String emoji,
    String name,
    Position position,
    Uint8List? roomPublicKey,
    bool sendToChannel,
    int colorIndex,
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
      // New format: S:<emoji>:<colorIndex>:<latitude>,<longitude>:<name>
      // Round coordinates to 5 decimal places (~1m accuracy) since most GPS is only that accurate
      final sarMessage =
          'S:$emoji:${colorIndex.toString()}:${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)}:$name';

      if (sendToChannel) {
        // Create message ID
        final messageId =
            '${DateTime.now().millisecondsSinceEpoch}_channel_sent';
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
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          channelIdx: 0,
          // SAR marker data is automatically added by SarMessageParser.enhanceMessage in MessagesProvider
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        // Send to public channel (ephemeral, over-the-air only)
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: sarMessage,
          messageId: messageId,
        );

        if (!mounted) return;
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
          text: sarMessage,
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
              _publicKeysMatch(c.publicKey, roomPublicKey);
        }).firstOrNull;

        // Send SAR message to selected room (persisted and immutable)
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: roomPublicKey!,
          text: sarMessage,
          messageId: messageId, // Pass message ID so it can be tracked
          contact: roomContact, // Include contact for path status logging
        );

        if (!sentSuccessfully) {
          // Mark message as failed if sending failed
          messagesProvider.markMessageFailed(messageId);
        }

        if (!mounted) return;
        ToastLogger.success(context, 'SAR marker sent to room');
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
      debugPrint(
        '🔄 [MessagesTab] Manual refresh triggered - syncing messages',
      );
      if (!mounted) return;
    } catch (e) {
      debugPrint('❌ [MessagesTab] Sync error: $e');
      if (!mounted) return;
      ToastLogger.error(context, 'Sync failed: $e');
    }
  }

  List<Message> _getFilteredMessages(MessagesProvider messagesProvider) {
    // Get all recent messages
    final allMessages = messagesProvider.getRecentMessages(count: 100);

    // Get simple mode setting from AppProvider
    final appProvider = context.read<AppProvider>();
    final isSimpleMode = appProvider.isSimpleMode;

    List<Message> filteredMessages;

    // If public channel is selected, show ALL messages
    if (_destinationType ==
            MessageDestinationPreferences.destinationTypeChannel &&
        _selectedRecipient == null) {
      filteredMessages = allMessages;
    }
    // If a contact or room is selected, filter by recipient
    else if ((_destinationType ==
                MessageDestinationPreferences.destinationTypeContact ||
            _destinationType ==
                MessageDestinationPreferences.destinationTypeRoom) &&
        _selectedRecipient != null) {
      filteredMessages = allMessages.where((message) {
        // Include messages sent TO this recipient
        if (message.recipientPublicKey != null &&
            message.recipientPublicKey!.length >= 6 &&
            _selectedRecipient!.publicKey.length >= 6) {
          // Compare first 6 bytes (public key prefix)
          final recipientPrefix = message.recipientPublicKey!.sublist(0, 6);
          final selectedPrefix = _selectedRecipient!.publicKey.sublist(0, 6);
          if (_publicKeysMatch(recipientPrefix, selectedPrefix)) {
            return true;
          }
        }

        // Include messages received FROM this recipient
        if (message.senderPublicKeyPrefix != null &&
            message.senderPublicKeyPrefix!.length >= 6 &&
            _selectedRecipient!.publicKey.length >= 6) {
          final senderPrefix = message.senderPublicKeyPrefix!.sublist(0, 6);
          final selectedPrefix = _selectedRecipient!.publicKey.sublist(0, 6);
          if (_publicKeysMatch(senderPrefix, selectedPrefix)) {
            return true;
          }
        }

        return false;
      }).toList();
    } else {
      // Default: show all messages (fallback case)
      filteredMessages = allMessages;
    }

    // In simple mode, filter out system messages (toast logs)
    if (isSimpleMode) {
      filteredMessages = filteredMessages
          .where((message) => !message.isSystemMessage)
          .toList();
    }

    return filteredMessages;
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
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
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
                                        AppLocalizations.of(
                                          context,
                                        )!.noMessagesYet,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.pullDownToSync,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isHighlighted =
                              message.id == _highlightedMessageId;

                          return MessageBubble(
                            message: message,
                            isHighlighted: isHighlighted,
                            onNavigateToMap: widget.onNavigateToMap,
                            onTap:
                                message.isSarMarker &&
                                    message.sarGpsCoordinates != null
                                ? () {
                                    final mapProvider = context
                                        .read<MapProvider>();
                                    mapProvider.navigateToLocation(
                                      location: message.sarGpsCoordinates!,
                                      zoom: 15.0,
                                    );
                                    widget.onNavigateToMap();
                                  }
                                : message.isDrawing && message.drawingId != null
                                ? () {
                                    debugPrint('🗺️ [MessagesTab] Drawing tapped! ID: ${message.drawingId}');
                                    final mapProvider = context
                                        .read<MapProvider>();
                                    final drawingProvider = context
                                        .read<DrawingProvider>();
                                    mapProvider.navigateToDrawing(
                                      message.drawingId!,
                                      drawingProvider,
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
                    tooltip: AppLocalizations.of(context)!.sendSarMarker,
                    onPressed: _showSarDialog,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Destination switcher button
                  IconButton(
                    icon: Icon(_getDestinationIcon()),
                    tooltip: _getDestinationTooltip(),
                    onPressed: _showRecipientSelector,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _destinationType ==
                              MessageDestinationPreferences
                                  .destinationTypeChannel
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          _destinationType ==
                              MessageDestinationPreferences
                                  .destinationTypeChannel
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
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
                        hintText: AppLocalizations.of(context)!.typeYourMessage,
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

