import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshcore_client/meshcore_client.dart' show MeshCoreConstants;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/drawing_provider.dart';
import '../providers/voice_provider.dart';
import '../providers/app_provider.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../widgets/messages/sar_update_sheet.dart';
import '../widgets/messages/recipient_selector_sheet.dart';
import '../widgets/messages/messages_composer.dart';
import '../widgets/messages/messages_content.dart';
import '../widgets/common/contact_avatar.dart';
import '../services/message_destination_preferences.dart';
import '../services/voice_bitrate_preferences.dart';
import '../services/voice_recorder_service.dart';
import '../services/voice_codec_service.dart';
import '../utils/toast_logger.dart';
import '../utils/key_comparison.dart';
import '../utils/contact_sorting.dart';
import '../utils/voice_message_parser.dart';
import '../utils/image_message_parser.dart';
import '../utils/tictactoe_message_parser.dart';
import '../providers/image_provider.dart' as ip;
import '../services/image_codec_service.dart';
import '../services/image_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';

class MessagesTab extends StatefulWidget {
  final VoidCallback? onNavigateToMap;
  final bool isActive;

  const MessagesTab({super.key, this.onNavigateToMap, this.isActive = true});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _ComposerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ComposerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = enabled
        ? color
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                enabled
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surfaceContainerHighest,
                enabled
                    ? effectiveColor.withValues(alpha: 0.08)
                    : colorScheme.surfaceContainerHigh,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: enabled
                  ? effectiveColor.withValues(alpha: 0.16)
                  : colorScheme.outlineVariant.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: enabled ? 0.08 : 0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(
                      alpha: enabled ? 0.14 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: effectiveColor, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagesTabState extends State<MessagesTab> {
  static const int _maxContactMessageBytes = 156;
  static const int _maxChannelMessageBytes = 127;
  static const double _composerOverlayHeight = 148;
  static const Duration _channelAutoReadDelay = Duration(seconds: 5);

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _messageByteCount = 0;
  String? _highlightedMessageId;
  Timer? _highlightTimer; // Timer for clearing message highlight
  Timer? _channelReadTimer;
  String? _pendingChannelReadKey;
  bool _suppressMentionTrigger = false;
  TextRange? _activeMentionRange;
  String _mentionQuery = '';
  List<Contact> _mentionSuggestions = const [];

  // Message destination state
  String _destinationType =
      MessageDestinationPreferences.destinationTypeChannel;
  Contact? _selectedRecipient;

  // Image sending state
  bool _isSendingImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Voice recording state
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  bool _isRecording = false;
  bool _isSendingVoice = false;
  static const Duration _maxVoiceRecordingDuration = Duration(seconds: 30);
  static const double _silenceRmsThreshold = 500.0;
  static const double _silencePeakThreshold = 1400.0;
  static const int _maxInteriorSilentChunks = 2;
  bool get _voiceSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  StreamSubscription<Int16List>? _voiceStreamSub;
  String? _currentVoiceSessionId;
  final List<Int16List> _recordedChunks = [];
  VoicePacketMode? _activeVoiceMode;
  int _selectedVoiceBitrate = VoiceBitratePreferences.defaultBitrate;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleComposerChanged);
    _focusNode.addListener(_handleFocusChanged);
    // Load saved message destination
    _loadSavedDestination();
    _loadVoiceSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForNavigationRequest();
    });
  }

  Future<void> _loadVoiceSettings() async {
    final bitrate = await VoiceBitratePreferences.getBitrate();
    if (!mounted) return;
    setState(() {
      _selectedVoiceBitrate = bitrate;
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
    _highlightTimer?.cancel();
    _channelReadTimer?.cancel();
    _voiceStreamSub?.cancel();
    _voiceRecorder.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MessagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncChannelAutoReadTimer(context.read<MessagesProvider>());
    }
  }

  void _checkForNavigationRequest() {
    final messagesProvider = context.read<MessagesProvider>();
    final targetMessageId = messagesProvider.targetMessageId;
    final targetDestinationType = messagesProvider.targetDestinationType;

    if (targetMessageId != null) {
      _scrollToMessage(targetMessageId);
      messagesProvider.clearMessageNavigation();
    }

    if (targetDestinationType != null) {
      _applyPendingDestination(
        type: targetDestinationType,
        recipientPublicKeyHex: messagesProvider.targetRecipientPublicKeyHex,
      );
      messagesProvider.clearDestinationNavigation();
    }
  }

  void _scrollToMessage(String messageId) {
    final messagesProvider = context.read<MessagesProvider>();
    final messages = messagesProvider.buildDisplayMessages(
      _getFilteredMessages(messagesProvider),
    );

    final messageIndex = messages.indexWhere(
      (entry) => entry.message.id == messageId,
    );

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

      // Clear highlight after 2 seconds using a properly managed Timer
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }

  void _handleComposerChanged() {
    _updateCharacterCount();

    if (_suppressMentionTrigger) {
      return;
    }

    _updateMentionSuggestions(_textController.value);
  }

  void _updateCharacterCount() {
    setState(() {
      _messageByteCount = utf8.encode(_textController.text).length;
    });
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _clearMentionSuggestions();
      return;
    }

    if (_suppressMentionTrigger) {
      return;
    }

    _updateMentionSuggestions(_textController.value);
  }

  void _updateMentionSuggestions(TextEditingValue value) {
    final triggerRange = _getMentionTriggerRange(value);
    if (triggerRange == null) {
      _clearMentionSuggestions();
      return;
    }

    final query = value.text.substring(
      triggerRange.start + 1,
      triggerRange.end,
    );
    final contacts = _buildMentionSuggestions(query);
    if (!mounted) {
      return;
    }

    setState(() {
      _activeMentionRange = triggerRange;
      _mentionQuery = query;
      _mentionSuggestions = contacts;
    });
  }

  void _clearMentionSuggestions() {
    if (_activeMentionRange == null &&
        _mentionQuery.isEmpty &&
        _mentionSuggestions.isEmpty) {
      return;
    }

    setState(() {
      _activeMentionRange = null;
      _mentionQuery = '';
      _mentionSuggestions = const [];
    });
  }

  TextRange? _getMentionTriggerRange(TextEditingValue value) {
    if (!value.selection.isValid || !value.selection.isCollapsed) {
      return null;
    }

    final cursorOffset = value.selection.baseOffset;
    if (cursorOffset <= 0) {
      return null;
    }

    final text = value.text;
    final triggerStart = text.lastIndexOf('@', cursorOffset - 1);
    if (triggerStart == -1) {
      return null;
    }

    final leadingChar = triggerStart > 0 ? text[triggerStart - 1] : null;
    if (leadingChar != null && !RegExp(r'[\s\(\[\{]').hasMatch(leadingChar)) {
      return null;
    }

    final query = text.substring(triggerStart + 1, cursorOffset);
    if (query.contains(RegExp(r'[\s@\[\]\n\r]'))) {
      return null;
    }

    return TextRange(start: triggerStart, end: cursorOffset);
  }

  List<Contact> _buildMentionSuggestions(String query) {
    final contactsProvider = context.read<ContactsProvider>();
    final normalizedQuery = query.trim().toLowerCase();
    final contacts =
        contactsProvider.chatContacts.where((contact) {
          if (normalizedQuery.isEmpty) return true;
          return contact.displayName.toLowerCase().contains(normalizedQuery);
        }).toList()..sort((a, b) {
          final primary = compareContactsByFavouriteThenLastSeen(a, b);
          if (primary != 0) {
            return primary;
          }

          final aName = a.displayName.toLowerCase();
          final bName = b.displayName.toLowerCase();
          final aStarts =
              normalizedQuery.isNotEmpty && aName.startsWith(normalizedQuery);
          final bStarts =
              normalizedQuery.isNotEmpty && bName.startsWith(normalizedQuery);
          if (aStarts != bStarts) {
            return aStarts ? -1 : 1;
          }

          return compareContactsByDisplayName(a, b);
        });

    return contacts.take(8).toList(growable: false);
  }

  int get _maxMessageBytes =>
      _destinationType == MessageDestinationPreferences.destinationTypeChannel
      ? _maxChannelMessageBytes
      : _maxContactMessageBytes;

  TextInputFormatter get _messageByteLimiter =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (utf8.encode(newValue.text).length <= _maxMessageBytes) {
          return newValue;
        }
        return oldValue;
      });

  void _enforceMessageByteLimit() {
    final currentText = _textController.text;
    if (utf8.encode(currentText).length <= _maxMessageBytes) {
      _updateCharacterCount();
      return;
    }

    var truncated = currentText;
    while (truncated.isNotEmpty &&
        utf8.encode(truncated).length > _maxMessageBytes) {
      truncated = truncated.substring(0, truncated.length - 1);
    }

    _textController.value = _textController.value.copyWith(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
      composing: TextRange.empty,
    );
    _updateCharacterCount();
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

    _enforceMessageByteLimit();
  }

  /// Show recipient selector bottom sheet
  void _showRecipientSelector() {
    final contactsProvider = context.read<ContactsProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    final contacts = List<Contact>.from(contactsProvider.chatContacts)
      ..sort((a, b) {
        final primary = compareContactsByFavouriteThenLastSeen(a, b);
        if (primary != 0) {
          return primary;
        }

        return compareContactsByDisplayName(a, b);
      });
    final rooms = List<Contact>.from(contactsProvider.rooms)
      ..sort((a, b) {
        final primary = compareContactsByLastSeen(a, b);
        if (primary != 0) {
          return primary;
        }

        return compareContactsByDisplayName(a, b);
      });
    final channels = List<Contact>.from(contactsProvider.channels)
      ..sort((a, b) {
        final primary = compareContactsByLastSeen(a, b);
        if (primary != 0) {
          return primary;
        }

        return compareContactsByDisplayName(a, b);
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipientSelectorSheet(
        contacts: contacts,
        rooms: rooms,
        channels: channels,
        unreadCount: messagesProvider.unreadCount,
        unreadCountsByPublicKey: {
          for (final contact in [...contacts, ...rooms, ...channels])
            contact.publicKeyHex: messagesProvider.getUnreadCountForDestination(
              contact,
            ),
        },
        currentDestinationType: _destinationType,
        currentRecipientPublicKey: _selectedRecipient?.publicKeyHex,
        onSelect: _onRecipientSelected,
      ),
    );
  }

  /// Handle recipient selection
  Future<void> _onRecipientSelected(String type, Contact? recipient) async {
    setState(() {
      _destinationType = type;
      _selectedRecipient = recipient;
    });

    _markCurrentDestinationAsRead();

    _enforceMessageByteLimit();

    // Save to preferences
    await MessageDestinationPreferences.setDestination(
      type,
      recipientPublicKey: recipient?.publicKeyHex,
    );

    // Show confirmation toast
    if (!mounted) return;
  }

  Future<void> _applyPendingDestination({
    required String type,
    String? recipientPublicKeyHex,
  }) async {
    Contact? recipient;
    if (recipientPublicKeyHex != null) {
      final contactsProvider = context.read<ContactsProvider>();
      recipient = contactsProvider.contacts.where((contact) {
        return contact.publicKeyHex == recipientPublicKeyHex;
      }).firstOrNull;
    }

    await _onRecipientSelected(type, recipient);
    if (!mounted) return;
    _focusNode.requestFocus();
  }

  void _insertReplyMention(String displayName, {TextRange? replacementRange}) {
    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) return;

    final mention = '@[$trimmedName] ';
    final value = _textController.value;
    final selection = replacementRange ?? value.selection;
    final hasSelection =
        selection.isValid &&
        selection.start >= 0 &&
        selection.end >= selection.start;

    final start = hasSelection ? selection.start : value.text.length;
    final end = hasSelection ? selection.end : value.text.length;
    final nextText = value.text.replaceRange(start, end, mention);
    final nextOffset = start + mention.length;

    _suppressMentionTrigger = true;
    _textController.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
    _suppressMentionTrigger = false;
    _clearMentionSuggestions();
    _enforceMessageByteLimit();
  }

  void _selectMention(Contact contact) {
    _insertReplyMention(
      contact.displayName,
      replacementRange: _activeMentionRange,
    );
    _focusNode.requestFocus();
  }

  Future<void> _replyToMessage(Message message) async {
    final contactsProvider = context.read<ContactsProvider>();
    Contact? senderContact;
    String? senderDisplayName;

    String destinationType;
    Contact? recipient;

    if (message.isChannelMessage) {
      final channelIdx = message.channelIdx ?? 0;
      destinationType = MessageDestinationPreferences.destinationTypeChannel;

      if (channelIdx != 0) {
        recipient = contactsProvider.channels.where((contact) {
          return contact.publicKey.length > 1 &&
              contact.publicKey[1] == channelIdx;
        }).firstOrNull;

        if (recipient == null) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.cannotReplyContactNotFound,
          );
          return;
        }
      }

      final senderPrefix = message.senderPublicKeyPrefix;
      if (senderPrefix != null && senderPrefix.length >= 6) {
        senderContact = contactsProvider.findContactByPrefix(senderPrefix);
      }
      senderDisplayName =
          senderContact?.displayName ?? message.senderName?.trim();
    } else {
      final roomRecipient = message.recipientPublicKey == null
          ? null
          : contactsProvider.findContactByKey(message.recipientPublicKey!);

      if (roomRecipient?.isRoom == true) {
        destinationType = MessageDestinationPreferences.destinationTypeRoom;
        recipient = roomRecipient;

        final senderPrefix = message.senderPublicKeyPrefix;
        if (senderPrefix != null && senderPrefix.length >= 6) {
          senderContact = contactsProvider.findContactByPrefix(senderPrefix);
        }
        senderDisplayName =
            senderContact?.displayName ?? message.senderName?.trim();
      } else {
        final senderPrefix = message.senderPublicKeyPrefix;
        if (senderPrefix == null || senderPrefix.length < 6) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.cannotReplySenderMissing,
          );
          return;
        }

        recipient = contactsProvider.findContactByPrefix(senderPrefix);
        if (recipient == null) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.cannotReplyContactNotFound,
          );
          return;
        }

        destinationType = recipient.isRoom
            ? MessageDestinationPreferences.destinationTypeRoom
            : MessageDestinationPreferences.destinationTypeContact;
      }
    }

    await _onRecipientSelected(destinationType, recipient);
    if (!mounted) return;
    if ((message.isChannelMessage || recipient?.isRoom == true) &&
        senderDisplayName != null &&
        senderDisplayName.isNotEmpty) {
      _insertReplyMention(senderDisplayName);
    }
    _focusNode.requestFocus();
  }

  /// Get icon for current destination type
  IconData _getDestinationIcon() {
    if (_destinationType == MessageDestinationPreferences.destinationTypeAll) {
      return Icons.all_inbox;
    } else if (_destinationType ==
        MessageDestinationPreferences.destinationTypeChannel) {
      return Icons.public;
    } else if (_destinationType ==
        MessageDestinationPreferences.destinationTypeRoom) {
      return Icons.meeting_room;
    } else {
      return Icons.person;
    }
  }

  String _getDestinationLabel() {
    if (_destinationType == MessageDestinationPreferences.destinationTypeAll) {
      return AppLocalizations.of(context)!.showAll;
    }
    if (_destinationType ==
            MessageDestinationPreferences.destinationTypeChannel &&
        _selectedRecipient != null) {
      return _selectedRecipient!.getLocalizedDisplayName(context);
    }
    if (_selectedRecipient != null) {
      return _selectedRecipient!.displayName;
    }
    return 'Public Channel';
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

    if (_destinationType == MessageDestinationPreferences.destinationTypeAll) {
      if (!mounted) return;
      ToastLogger.error(context, 'Select a channel, contact, or room first');
      return;
    }

    _textController.clear();

    try {
      // Check destination type and send accordingly
      if (_destinationType ==
          MessageDestinationPreferences.destinationTypeChannel) {
        // Send to selected channel (or public channel if none selected)
        final channelIdx =
            _selectedRecipient?.publicKey[1] ??
            0; // Extract channel index from pseudo public key
        await _sendToChannel(
          text,
          connectionProvider,
          messagesProvider,
          channelIdx,
        );
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
          '⚠️ [MessagesTab] No recipient selected, falling back to public channel',
        );
        await _sendToChannel(text, connectionProvider, messagesProvider, 0);
      }

      _markCurrentDestinationAsRead();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      if (_textController.text.isEmpty) {
        _textController.text = text;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
        _focusNode.requestFocus();
      }
      ToastLogger.error(context, 'Failed to send: $e');
    }
  }

  /// Send message to channel
  Future<void> _sendToChannel(
    String text,
    ConnectionProvider connectionProvider,
    MessagesProvider messagesProvider,
    int channelIdx,
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
      channelIdx: channelIdx,
    );

    // Add to messages list with "sending" status
    messagesProvider.addSentMessage(sentMessage, contact: _selectedRecipient);

    // Send to selected channel
    await connectionProvider.sendChannelMessage(
      channelIdx: channelIdx,
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
    messagesProvider.addSentMessage(sentMessage, contact: _selectedRecipient);

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

  Future<void> _startTicTacToeGame() async {
    if (!mounted) return;
    if (_destinationType !=
            MessageDestinationPreferences.destinationTypeContact ||
        _selectedRecipient == null) {
      ToastLogger.warning(
        context,
        'Tic-Tac-Toe works only in direct messages. Choose a contact first.',
      );
      return;
    }

    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    final devicePublicKey = connectionProvider.deviceInfo.publicKey;
    if (devicePublicKey == null || devicePublicKey.length < 6) {
      ToastLogger.error(context, 'Device key unavailable');
      return;
    }

    final gameId = List.generate(
      8,
      (_) => math.Random.secure().nextInt(16).toRadixString(16),
    ).join();
    final starterKey6 = devicePublicKey
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
    final startMessage = TicTacToeMessageParser.encodeStart(
      gameId: gameId,
      starterKey6: starterKey6,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    await _sendToRecipient(
      startMessage,
      connectionProvider,
      messagesProvider,
      contactsProvider,
    );
  }

  // ── Image sending ───────────────────────────────────────────────────────────

  Future<void> _pickAndSendImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_isSendingImage) return;
    final shouldContinue = await _confirmPublicChannelMediaSend('image');
    if (!shouldContinue) return;
    if (!mounted) return;
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    // Pick image.
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;
    final rawBytes = await picked.readAsBytes();

    setState(() => _isSendingImage = true);
    String? failedMessageId;
    try {
      // Compress AVIF using user-selected size, compression and color mode.
      final maxSize = await ImagePreferences.getMaxSize();
      final compression = await ImagePreferences.getCompression();
      final grayscale = await ImagePreferences.getGrayscale();
      final ultraMode = await ImagePreferences.getUltraMode();
      final effectiveMaxSize = ImagePreferences.effectiveMaxSize(
        maxSize,
        ultraMode: ultraMode,
      );
      final result = await ImageCodecService.compress(
        rawBytes,
        maxDimension: effectiveMaxSize,
        compression: compression,
        grayscale: grayscale,
        ultraMode: ultraMode,
      );
      if (result == null) {
        if (!mounted) return;
        ToastLogger.error(context, 'Image compression failed');
        return;
      }
      final compressed = result.bytes;

      // Generate session ID (4 random bytes → 8 hex chars).
      final sessionId = List.generate(
        8,
        (_) => math.Random().nextInt(16).toRadixString(16),
      ).join();

      // Fragment.
      var imageDataBytesPerFragment = ImagePacket.maxDataBytes;
      if (_destinationType ==
              MessageDestinationPreferences.destinationTypeContact &&
          _selectedRecipient != null &&
          _selectedRecipient!.routeHasPath) {
        imageDataBytesPerFragment = safeImageDataBytesForPath(
          _selectedRecipient!.routeHopCount,
        );
      }

      final fragments = fragmentImage(
        sessionId: sessionId,
        format: ImageFormat.avif,
        bytes: compressed,
        maxDataBytes: imageDataBytesPerFragment,
      );

      if (fragments.isEmpty) {
        if (!mounted) return;
        ToastLogger.error(context, 'Image fragmentation failed');
        return;
      }

      // Build envelope.
      final deviceKey = connectionProvider.deviceInfo.publicKey;
      if (deviceKey == null || deviceKey.length < 6) {
        if (!mounted) return;
        ToastLogger.error(context, 'Device key unavailable');
        return;
      }
      final envelope = ImageEnvelope(
        sessionId: sessionId,
        format: ImageFormat.avif,
        total: fragments.length,
        width: result.width,
        height: result.height,
        sizeBytes: compressed.length,
      );

      if (!mounted) return;

      // Cache for deferred serving.
      final imageProvider = context.read<ip.ImageProvider>();
      imageProvider.cacheOutgoingSession(sessionId, fragments, envelope);

      // Add local placeholder message.
      final msgId = 'img_${sessionId}_sent';
      failedMessageId = msgId;
      final isChannel =
          _destinationType ==
          MessageDestinationPreferences.destinationTypeChannel;
      final channelIdx = isChannel
          ? (_selectedRecipient?.publicKey[1] ?? 0)
          : null;
      final recipient = _selectedRecipient;
      final placeholder = Message(
        id: msgId,
        messageType: isChannel ? MessageType.channel : MessageType.contact,
        channelIdx: channelIdx,
        senderPublicKeyPrefix: deviceKey.sublist(0, 6),
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        text: envelope.encode(),
        receivedAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
        recipientPublicKey: isChannel ? null : recipient?.publicKey,
      );
      messagesProvider.addSentMessage(placeholder, contact: recipient);

      // Send IE1 envelope via normal message path.
      final envelopeText = envelope.encode();

      if (isChannel) {
        await connectionProvider.sendChannelMessage(
          channelIdx: channelIdx ?? 0,
          text: envelopeText,
          messageId: msgId,
        );
      } else if (recipient != null) {
        final sent = await connectionProvider.sendTextMessage(
          contactPublicKey: recipient.publicKey,
          text: envelopeText,
          messageId: msgId,
          contact: recipient,
        );
        if (!sent) {
          messagesProvider.markMessageFailed(msgId);
          if (!mounted) return;
          ToastLogger.error(context, 'Failed to announce image');
          return;
        }
      } else {
        messagesProvider.markMessageFailed(msgId);
        if (!mounted) return;
        ToastLogger.error(context, 'No recipient selected');
        return;
      }

      debugPrint(
        '📷 [Image] Sent IE1 for session $sessionId: '
        '${fragments.length} fragments, ${compressed.length}B, '
        'chunk=${imageDataBytesPerFragment}B',
      );

      if (isChannel) {
        for (final fragment in fragments) {
          await connectionProvider.sendChannelData(
            channelIdx: channelIdx ?? 0,
            dataType: MeshCoreConstants.dataTypeDev,
            payload: fragment.encodeBinary(),
          );
        }
      }

      // Image fragments are always served on demand after an explicit IR2
      // fetch request, including direct contacts.
    } catch (e, st) {
      debugPrint('❌ [Image] _pickAndSendImage: $e\n$st');
      if (failedMessageId != null) {
        messagesProvider.markMessageFailed(failedMessageId);
      }
      if (!mounted) return;
      ToastLogger.error(context, 'Image send failed');
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  // ── Voice recording ────────────────────────────────────────────────────────

  Future<void> _startVoiceRecording() async {
    if (_isSendingVoice || _isRecording) return;
    debugPrint('🎙️ [Voice] _startVoiceRecording called');
    // Read fresh voice preferences so settings changes apply immediately.
    final selectedBitrate = await VoiceBitratePreferences.getBitrate();
    if (mounted) {
      setState(() {
        _selectedVoiceBitrate = selectedBitrate;
      });
    } else {
      _selectedVoiceBitrate = selectedBitrate;
    }
    final hasPermission = await _voiceRecorder.requestPermission();
    debugPrint('🎙️ [Voice] hasPermission=$hasPermission');
    if (!hasPermission) {
      if (!mounted) return;
      ToastLogger.error(context, 'Microphone permission required for voice');
      return;
    }

    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    debugPrint(
      '🎙️ [Voice] isConnected=${connectionProvider.deviceInfo.isConnected}',
    );
    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    // Generate a new session ID (4 random bytes → 8 hex chars)
    final rng = math.Random.secure();
    _currentVoiceSessionId = List.generate(
      4,
      (_) => rng.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    _activeVoiceMode = VoiceBitratePreferences.toVoiceMode(
      _selectedVoiceBitrate,
    );
    final packetDuration = Duration(
      milliseconds: _activeVoiceMode!.packetDurationMs,
    );
    final maxVoicePackets = _maxVoicePacketsForMode(_activeVoiceMode!);

    debugPrint(
      '🎙️ [Voice] session=$_currentVoiceSessionId mode=$_activeVoiceMode chunkDuration=${packetDuration.inMilliseconds}ms maxPackets=$maxVoicePackets',
    );

    _recordedChunks.clear();
    setState(() => _isRecording = true);

    try {
      final stream = _voiceRecorder.startCapture(
        chunkDuration: packetDuration,
        sampleRateHz: _activeVoiceMode!.sampleRateHz,
        enableBandPassFilter: appProvider.isVoiceBandPassFilterEnabled,
        enableCompressor: appProvider.isVoiceCompressorEnabled,
        enableLimiter: appProvider.isVoiceLimiterEnabled,
        enableAutoGain: appProvider.isVoiceAutoGainEnabled,
        enableEchoCancellation: appProvider.isVoiceEchoCancellationEnabled,
        enableNoiseSuppression: appProvider.isVoiceNoiseSuppressionEnabled,
      );
      debugPrint('🎙️ [Voice] capture started, listening for chunks...');
      _voiceStreamSub = stream.listen(
        (pcmChunk) {
          if (!_isRecording) return;
          _recordedChunks.add(pcmChunk);
          debugPrint(
            '🎙️ [Voice] chunk #${_recordedChunks.length} received: ${pcmChunk.length} samples',
          );
          setState(() {});
          if (_recordedChunks.length >= maxVoicePackets) {
            debugPrint('🎙️ [Voice] max packets reached, stopping');
            _stopAndSendVoice();
          }
        },
        onError: (e) {
          debugPrint('❌ [Voice] stream error: $e');
          _stopAndSendVoice();
        },
        onDone: () => debugPrint('🎙️ [Voice] stream done'),
      );
    } catch (e) {
      debugPrint('❌ [Voice] startCapture threw: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  int _maxVoicePacketsForMode(VoicePacketMode mode) {
    final packets =
        _maxVoiceRecordingDuration.inMilliseconds ~/ mode.packetDurationMs;
    return packets < 1 ? 1 : packets;
  }

  Future<void> _stopAndSendVoice() async {
    if (!_isRecording) return;
    final trimSilenceEnabled = context
        .read<AppProvider>()
        .isVoiceSilenceTrimmingEnabled;
    debugPrint(
      '🎙️ [Voice] _stopAndSendVoice: ${_recordedChunks.length} chunks buffered',
    );

    await _voiceStreamSub?.cancel();
    _voiceStreamSub = null;
    await _voiceRecorder.stopCapture();

    final rawChunks = List<Int16List>.from(_recordedChunks);
    final trimmedChunks = trimSilenceEnabled
        ? _trimSilence(rawChunks)
        : rawChunks;
    final sessionId = _currentVoiceSessionId;
    final mode = _activeVoiceMode;
    final chunks = mode == null
        ? trimmedChunks
        : _prepareChunksForSending(trimmedChunks, mode);
    _recordedChunks.clear();

    debugPrint(
      '🎙️ [Voice] silence trim enabled=$trimSilenceEnabled: raw=${rawChunks.length} chunks -> kept=${chunks.length} chunks',
    );

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isSendingVoice = chunks.isNotEmpty && sessionId != null;
      });
    }

    if (chunks.isEmpty || sessionId == null || mode == null || !mounted) {
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _currentVoiceSessionId = null;
        });
      }
      return;
    }

    final shouldContinue = await _confirmPublicChannelMediaSend('voice');
    if (!shouldContinue) {
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _currentVoiceSessionId = null;
        });
      }
      return;
    }

    try {
      await _encodeAndSendAllPackets(
        chunks: chunks,
        sessionId: sessionId,
        mode: mode,
      );
    } catch (e, st) {
      debugPrint('❌ [Voice] _encodeAndSendAllPackets threw: $e\n$st');
    } finally {
      debugPrint(
        '🎙️ [Voice] _stopAndSendVoice finally: resetting _isSendingVoice',
      );
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _currentVoiceSessionId = null;
        });
      }
    }
  }

  Future<void> _encodeAndSendAllPackets({
    required List<Int16List> chunks,
    required String sessionId,
    required VoicePacketMode mode,
  }) async {
    final total = chunks.length;
    final codec = VoiceCodecService();
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final voiceProvider = context.read<VoiceProvider>();
    final msgId = 'voice_${sessionId}_sent';
    final devicePublicKey = connectionProvider.deviceInfo.publicKey;
    final senderPublicKeyPrefix =
        devicePublicKey != null && devicePublicKey.length >= 6
        ? devicePublicKey.sublist(0, 6)
        : null;
    final isChannel =
        _destinationType ==
        MessageDestinationPreferences.destinationTypeChannel;
    final recipient = _selectedRecipient;
    final channelIdx = isChannel ? (recipient?.publicKey[1] ?? 0) : null;

    final encodedPackets = <VoicePacket>[];
    debugPrint(
      '🎙️ [Voice] encoding $total packets for deferred voice fetch, mode=${mode.label}, session=$sessionId',
    );
    for (var i = 0; i < total; i++) {
      if (!mounted) return;
      try {
        final codec2Data = await codec.encode(chunks[i], mode);
        debugPrint(
          '🎙️ [Voice] packet $i/$total encoded: ${codec2Data.length} bytes',
        );
        final packet = VoicePacket(
          sessionId: sessionId,
          mode: mode,
          index: i,
          total: total,
          codec2Data: codec2Data,
        );

        encodedPackets.add(packet);
        voiceProvider.addPacket(packet);
      } catch (e, st) {
        debugPrint('❌ [Voice] packet $i encode error: $e\n$st');
      }
    }

    if (encodedPackets.isEmpty) {
      debugPrint('❌ [Voice] No packets encoded for session $sessionId');
      messagesProvider.markMessageFailed(msgId);
      return;
    }

    voiceProvider.cacheOutgoingSession(sessionId, encodedPackets);

    if (senderPublicKeyPrefix == null || senderPublicKeyPrefix.length < 6) {
      debugPrint('❌ [Voice] Missing device public key prefix for envelope');
      messagesProvider.markMessageFailed(msgId);
      return;
    }

    final durationMs = encodedPackets.fold<int>(
      0,
      (sum, p) => sum + p.durationMs,
    );
    final envelope = VoiceEnvelope(
      sessionId: sessionId,
      mode: mode,
      total: encodedPackets.length,
      durationMs: durationMs,
      version: 3,
    );
    final envelopeText = envelope.encodeText();

    // Insert placeholder with real VE1 envelope text so technical details are populated.
    final sentMsg = Message(
      id: msgId,
      messageType: (!isChannel && recipient != null)
          ? MessageType.contact
          : MessageType.channel,
      senderPublicKeyPrefix: senderPublicKeyPrefix,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      text: envelopeText,
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sent,
      isVoice: true,
      voiceId: sessionId,
      channelIdx: channelIdx,
      recipientPublicKey: isChannel ? null : recipient?.publicKey,
    );
    messagesProvider.addSentMessage(sentMsg, contact: recipient);

    try {
      if (isChannel) {
        await connectionProvider.sendChannelMessage(
          channelIdx: channelIdx ?? 0,
          text: envelopeText,
          messageId: msgId,
        );
      } else if (recipient != null) {
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: recipient.publicKey,
          text: envelopeText,
          messageId: msgId,
          contact: recipient,
        );
        if (!sentSuccessfully) {
          messagesProvider.markMessageFailed(msgId);
          return;
        }
      } else {
        messagesProvider.markMessageFailed(msgId);
        if (!mounted) return;
        ToastLogger.error(context, 'No recipient selected');
        return;
      }
    } catch (e, st) {
      debugPrint('❌ [Voice] envelope send error: $e\n$st');
      messagesProvider.markMessageFailed(msgId);
      return;
    }

    debugPrint('🎙️ [Voice] envelope sent for session $sessionId');
    if (isChannel) {
      for (final packet in encodedPackets) {
        await connectionProvider.sendChannelData(
          channelIdx: channelIdx ?? 0,
          dataType: MeshCoreConstants.dataTypeDev,
          payload: packet.encodeBinary(),
        );
      }
    }
    // Mark the placeholder message as "sent" (ackTag=0, timeout=0 = no ACK tracking).
    // addSentMessage() forces deliveryStatus.sending; we upgrade it here so the
    // bubble shows "Sent" instead of "Sending" once all packets are on the wire.
    // For channels this is also set by the onMessageSent callback, but this is harmless.
    messagesProvider.markMessageSent(msgId, 0, 0);
  }

  List<Int16List> _prepareChunksForSending(
    List<Int16List> chunks,
    VoicePacketMode mode,
  ) {
    return chunks;
  }

  List<Int16List> _trimSilence(List<Int16List> chunks) {
    if (chunks.isEmpty) return chunks;

    final isSilent = chunks.map(_isSilentChunk).toList();
    final firstVoice = isSilent.indexWhere((silent) => !silent);
    if (firstVoice == -1) return const [];

    final lastVoice = isSilent.lastIndexWhere((silent) => !silent);
    if (lastVoice < firstVoice) return const [];

    final trimmed = <Int16List>[];
    var interiorSilentRun = 0;
    for (var i = firstVoice; i <= lastVoice; i++) {
      if (isSilent[i]) {
        interiorSilentRun++;
        if (interiorSilentRun <= _maxInteriorSilentChunks) {
          trimmed.add(chunks[i]);
        }
      } else {
        interiorSilentRun = 0;
        trimmed.add(chunks[i]);
      }
    }
    return trimmed;
  }

  bool _isSilentChunk(Int16List chunk) {
    if (chunk.isEmpty) return true;

    final rms = _chunkRms(chunk);
    final peak = _chunkPeak(chunk);
    return rms < _silenceRmsThreshold && peak < _silencePeakThreshold;
  }

  double _chunkRms(Int16List chunk) {
    var sumSquares = 0.0;
    for (final sample in chunk) {
      sumSquares += sample * sample;
    }
    return math.sqrt(sumSquares / chunk.length);
  }

  int _chunkPeak(Int16List chunk) {
    var peak = 0;
    for (final sample in chunk) {
      final absSample = sample.abs();
      if (absSample > peak) {
        peak = absSample;
      }
    }
    return peak;
  }

  bool _isPublicChannelSelected() {
    if (_destinationType !=
        MessageDestinationPreferences.destinationTypeChannel) {
      return false;
    }
    final channelIdx = _selectedRecipient?.publicKey[1] ?? 0;
    return channelIdx == 0;
  }

  Future<bool> _confirmPublicChannelMediaSend(String mediaType) async {
    if (!_isPublicChannelSelected() || !mounted) return true;

    final decision = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sendToPublicChannel),
        content: Text(
          'You are about to send $mediaType to the Public Channel. '
          'This is not advised because everyone on the mesh may receive it. '
          'Choose a private or tagged channel unless this is what you want.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context)!.sendAnyway),
          ),
        ],
      ),
    );

    return decision ?? false;
  }

  // ── SAR dialog ─────────────────────────────────────────────────────────────

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
              sendToAllContacts,
              colorIndex,
            ) async {
              await _sendSarMessage(
                emoji,
                name,
                position,
                roomPublicKey,
                sendToChannel,
                sendToAllContacts,
                colorIndex,
              );
            },
      ),
    );
  }

  Future<void> _runAfterSheetDismissal(
    BuildContext sheetContext,
    Future<void> Function() action,
  ) async {
    Navigator.pop(sheetContext);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await action();
  }

  void _showComposerActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final l10n = AppLocalizations.of(context)!;

        Future<void> runAction(Future<void> Function() action) async {
          await _runAfterSheetDismissal(sheetContext, action);
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.72,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surfaceContainerLow,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                  bottom: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'More actions',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search, share, or start something from this chat.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            tooltip: l10n.close,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final actions = <Widget>[
                          _ComposerActionTile(
                            icon: Icons.search_rounded,
                            title: l10n.searchMessages,
                            subtitle: 'Find text in the current conversation',
                            color: const Color(0xFF2B6CB0),
                            onTap: () => runAction(() async {
                              _showFilteredMessageSearch();
                            }),
                          ),
                          _ComposerActionTile(
                            icon: Icons.add_location_alt_rounded,
                            title: l10n.sendSarMarker,
                            subtitle: 'Share a marker with coordinates',
                            color: const Color(0xFFB45309),
                            onTap: () => runAction(() async {
                              _showSarDialog();
                            }),
                          ),
                          if (_voiceSupported)
                            _ComposerActionTile(
                              icon: _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              title: _isRecording
                                  ? 'Stop recording'
                                  : 'Record voice',
                              subtitle: _isSendingVoice
                                  ? 'Voice message is sending'
                                  : _isRecording
                                  ? 'Finish and send your clip'
                                  : 'Capture and send a voice note',
                              color: const Color(0xFF7C3AED),
                              enabled: !_isSendingVoice,
                              onTap: !_isSendingVoice
                                  ? () => runAction(() async {
                                      if (_isRecording) {
                                        await _stopAndSendVoice();
                                      } else {
                                        await _startVoiceRecording();
                                      }
                                    })
                                  : null,
                            ),
                          _ComposerActionTile(
                            icon: Icons.photo_library_rounded,
                            title: l10n.sendImageFromGallery,
                            subtitle: 'Choose an image from your library',
                            color: const Color(0xFF0F766E),
                            enabled: !_isSendingImage,
                            onTap: !_isSendingImage
                                ? () => runAction(() async {
                                    await _pickAndSendImage(
                                      source: ImageSource.gallery,
                                    );
                                  })
                                : null,
                          ),
                          _ComposerActionTile(
                            icon: Icons.camera_alt_rounded,
                            title: l10n.takePhoto,
                            subtitle: 'Capture something right now',
                            color: const Color(0xFF2563EB),
                            enabled: !_isSendingImage,
                            onTap: !_isSendingImage
                                ? () => runAction(() async {
                                    await _pickAndSendImage(
                                      source: ImageSource.camera,
                                    );
                                  })
                                : null,
                          ),
                          _ComposerActionTile(
                            icon: Icons.grid_3x3_rounded,
                            title: l10n.startTictactoe,
                            subtitle: l10n.dmOnly,
                            color: const Color(0xFFBE185D),
                            onTap: () => runAction(() async {
                              await _startTicTacToeGame();
                            }),
                          ),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: actions.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 126,
                              ),
                          itemBuilder: (context, index) => actions[index],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFilteredMessageSearch() {
    final messagesProvider = context.read<MessagesProvider>();
    final scopedMessages = _getFilteredMessages(messagesProvider);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final matches = query.isEmpty
                ? scopedMessages
                : scopedMessages.where((message) {
                    return message.text.toLowerCase().contains(query) ||
                        (message.senderName?.toLowerCase().contains(query) ??
                            false);
                  }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.72,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search in current filter',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      setModalState(() {});
                                    },
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      Expanded(
                        child: matches.isEmpty
                            ? Center(
                                child: Text(
                                  query.isEmpty
                                      ? 'No messages in this filter'
                                      : 'No matches in this filter',
                                ),
                              )
                            : ListView.separated(
                                itemCount: matches.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final message = matches[index];
                                  final title =
                                      message.senderName?.trim().isNotEmpty ==
                                          true
                                      ? message.senderName!
                                      : message.isSentMessage
                                      ? 'You'
                                      : _getDestinationLabel();

                                  return ListTile(
                                    title: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      message.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      _scrollToMessage(message.id);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  Widget _buildDestinationAvatar(BuildContext context) {
    final recipient = _selectedRecipient;
    if (recipient != null) {
      return ContactAvatar(
        contact: recipient,
        radius: 14,
        displayName: _getDestinationLabel(),
      );
    }

    return Icon(
      _getDestinationIcon(),
      size: 17,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Future<void> _sendSarMessage(
    String emoji,
    String name,
    Position position,
    Uint8List? roomPublicKey,
    bool sendToChannel,
    bool sendToAllContacts,
    int colorIndex,
  ) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    if (!sendToChannel && !sendToAllContacts && roomPublicKey == null) {
      if (!mounted) return;
      ToastLogger.error(
        context,
        'Please select a destination to send SAR marker',
      );
      return;
    }

    try {
      // New format: S:<emoji>:<colorIndex>:<latitude>,<longitude>:<name>
      // Round coordinates to 5 decimal places (~1m accuracy) since most GPS is only that accurate
      final sarMessage =
          'S:$emoji:${colorIndex.toString()}:${position.latitude.toStringAsFixed(5)},${position.longitude.toStringAsFixed(5)}:$name';

      if (sendToAllContacts) {
        // Send to all chat contacts (ContactType.chat)
        final contactsProvider = context.read<ContactsProvider>();
        final chatContacts = contactsProvider.chatContacts;

        if (chatContacts.isEmpty) {
          if (!mounted) return;
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.noContactsAvailable,
          );
          return;
        }

        // Create a single grouped message instead of multiple individual messages
        final groupId = '${DateTime.now().millisecondsSinceEpoch}_group';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create recipient list
        final recipients = chatContacts.map((contact) {
          return MessageRecipient(
            publicKey: contact.publicKey,
            displayName: contact.displayName,
            deliveryStatus: MessageDeliveryStatus.sending,
            sentAt: DateTime.now(),
          );
        }).toList();

        // Create single grouped message
        final groupedMessage = Message(
          id: groupId,
          messageType: MessageType.contact,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          groupId: groupId,
          recipients: recipients,
        );

        // Add the grouped message to the list
        messagesProvider.addSentMessage(groupedMessage);

        // Send to each contact and track status
        int successCount = 0;
        for (final contact in chatContacts) {
          final individualMessageId = '${groupId}_${contact.publicKeyShort}';

          // Register this individual send as part of the grouped message
          messagesProvider.registerGroupedMessageSend(
            individualMessageId,
            groupId,
            contact.publicKey,
          );

          // Send SAR message to contact (with ACK tracking)
          final sentSuccessfully = await connectionProvider.sendTextMessage(
            contactPublicKey: contact.publicKey,
            text: sarMessage,
            messageId: individualMessageId,
            contact: contact,
          );

          if (sentSuccessfully) {
            successCount++;
          } else {
            // Update recipient status in grouped message
            messagesProvider.updateGroupedMessageRecipientStatus(
              groupId,
              contact.publicKey,
              MessageDeliveryStatus.failed,
            );
          }

          // Add 1 second delay between sends to ensure:
          // 1. Different timestamps (messages sent in different seconds)
          // 2. Radio has time to fully process previous message and assign ACK tag
          // This ensures each message gets a unique ACK tag from the radio
          if (contact != chatContacts.last) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!mounted) return;
        ToastLogger.success(
          context,
          AppLocalizations.of(context)!.sarMarkerSentToContacts(successCount),
        );
      } else if (sendToChannel) {
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

        // Look up the room contact for path logging
        final contactsProvider = context.read<ContactsProvider>();
        final roomContact = contactsProvider.contacts.where((c) {
          return c.publicKey.length >= roomPublicKey!.length &&
              c.publicKey.matches(roomPublicKey);
        }).firstOrNull;

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage, contact: roomContact);

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

  void _markCurrentDestinationAsRead() {
    _channelReadTimer?.cancel();
    _pendingChannelReadKey = null;
    context.read<MessagesProvider>().markDestinationAsRead(
      destinationType: _destinationType,
      contact: _selectedRecipient,
    );
  }

  void _syncChannelAutoReadTimer(MessagesProvider messagesProvider) {
    if (!widget.isActive ||
        _destinationType !=
            MessageDestinationPreferences.destinationTypeChannel) {
      _channelReadTimer?.cancel();
      _pendingChannelReadKey = null;
      return;
    }

    final channelIdx = _selectedRecipient?.publicKey[1] ?? 0;
    final unreadCount = messagesProvider.getUnreadCountForChannel(channelIdx);

    if (unreadCount <= 0) {
      _channelReadTimer?.cancel();
      _pendingChannelReadKey = null;
      return;
    }

    final nextKey = '$channelIdx:$unreadCount';
    if (_pendingChannelReadKey == nextKey &&
        _channelReadTimer?.isActive == true) {
      return;
    }

    _channelReadTimer?.cancel();
    _pendingChannelReadKey = nextKey;
    _channelReadTimer = Timer(_channelAutoReadDelay, () {
      if (!mounted || !widget.isActive) {
        return;
      }

      if (_destinationType !=
          MessageDestinationPreferences.destinationTypeChannel) {
        return;
      }

      final currentChannelIdx = _selectedRecipient?.publicKey[1] ?? 0;
      if (currentChannelIdx != channelIdx) {
        return;
      }

      final latestProvider = context.read<MessagesProvider>();
      if (latestProvider.getUnreadCountForChannel(channelIdx) <= 0) {
        return;
      }

      _markCurrentDestinationAsRead();
    });
  }

  List<Message> _getFilteredMessages(MessagesProvider messagesProvider) {
    // Get all recent messages
    final allMessages = messagesProvider.getRecentMessages(count: 100);

    List<Message> filteredMessages;

    // If channel destination is selected, filter by selected channel.
    if (_destinationType == MessageDestinationPreferences.destinationTypeAll) {
      filteredMessages = allMessages;
    } else if (_destinationType ==
        MessageDestinationPreferences.destinationTypeChannel) {
      final selectedChannelIdx = _selectedRecipient?.publicKey[1] ?? 0;
      filteredMessages = allMessages
          .where(
            (message) =>
                message.isChannelMessage &&
                (message.channelIdx ?? 0) == selectedChannelIdx,
          )
          .toList();
    }
    // If a contact or room is selected, filter by recipient/sender prefixes.
    else if ((_destinationType ==
                MessageDestinationPreferences.destinationTypeContact ||
            _destinationType ==
                MessageDestinationPreferences.destinationTypeRoom) &&
        _selectedRecipient != null) {
      filteredMessages = allMessages.where((message) {
        if (!message.isContactMessage) {
          return false;
        }

        // Include messages sent TO this recipient
        if (message.recipientPublicKey != null &&
            message.recipientPublicKey!.length >= 6 &&
            _selectedRecipient!.publicKey.length >= 6) {
          // Compare first 6 bytes (public key prefix)
          final recipientPrefix = message.recipientPublicKey!.sublist(0, 6);
          final selectedPrefix = _selectedRecipient!.publicKey.sublist(0, 6);
          if (recipientPrefix.matches(selectedPrefix)) {
            return true;
          }
        }

        // Include messages received FROM this recipient
        if (message.senderPublicKeyPrefix != null &&
            message.senderPublicKeyPrefix!.length >= 6 &&
            _selectedRecipient!.publicKey.length >= 6) {
          final senderPrefix = message.senderPublicKeyPrefix!.sublist(0, 6);
          final selectedPrefix = _selectedRecipient!.publicKey.sublist(0, 6);
          if (senderPrefix.matches(selectedPrefix)) {
            return true;
          }
        }

        return false;
      }).toList();
    } else {
      // Default: show all messages (fallback case)
      filteredMessages = allMessages;
    }

    return filteredMessages
        .where((message) => !message.isSystemMessage)
        .toList();
  }

  void _handleMessageTap(Message message) {
    if (widget.onNavigateToMap == null) return;

    if (message.isSarMarker) {
      final mapProvider = context.read<MapProvider>();
      final marker = message.toSarMarker();
      if (marker == null) {
        return;
      }
      final error = mapProvider.navigateToSarMarker(marker);
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      widget.onNavigateToMap?.call();
      return;
    }

    if (message.isDrawing && message.drawingId != null) {
      debugPrint('🗺️ [MessagesTab] Drawing tapped! ID: ${message.drawingId}');
      final mapProvider = context.read<MapProvider>();
      final drawingProvider = context.read<DrawingProvider>();
      final error = mapProvider.navigateToDrawing(
        message.drawingId!,
        drawingProvider,
      );
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      widget.onNavigateToMap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, messagesProvider, child) {
        _syncChannelAutoReadTimer(messagesProvider);
        final messages = messagesProvider.buildDisplayMessages(
          _getFilteredMessages(messagesProvider),
        );
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        final composerBottomPadding = bottomInset > 0 ? 2.0 : 10.0;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Positioned.fill(
                child: MessagesContent(
                  messages: messages,
                  scrollController: _scrollController,
                  highlightedMessageId: _highlightedMessageId,
                  bottomContentPadding:
                      _composerOverlayHeight + composerBottomPadding,
                  onRefresh: _handleRefresh,
                  onNavigateToMap: widget.onNavigateToMap,
                  onMessageTap: _handleMessageTap,
                  onReplyToMessage: _replyToMessage,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MessagesComposer(
                  textController: _textController,
                  focusNode: _focusNode,
                  messageByteLimiter: _messageByteLimiter,
                  messageByteCount: _messageByteCount,
                  maxMessageBytes: _maxMessageBytes,
                  isRecording: _isRecording,
                  isSendingVoice: _isSendingVoice,
                  voiceSupported: _voiceSupported,
                  bottomPadding: composerBottomPadding,
                  destinationLabel: _getDestinationLabel(),
                  destinationAvatar: _buildDestinationAvatar(context),
                  mentionSuggestions: _mentionSuggestions,
                  mentionQuery: _mentionQuery,
                  onMentionSelected: _selectMention,
                  onShowComposerActions: _showComposerActions,
                  onShowRecipientSelector: _showRecipientSelector,
                  onStartVoiceRecording: _startVoiceRecording,
                  onStopAndSendVoice: _stopAndSendVoice,
                  onSendMessage: _sendMessage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
