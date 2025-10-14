import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';

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

  // Message recipient selection
  String? _selectedRecipientId; // null = broadcast to public channel (channel 0)
  MessageRecipientType _recipientType = MessageRecipientType.room;

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
    final contactsProvider = context.read<ContactsProvider>();

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
      if (_recipientType == MessageRecipientType.contact && _selectedRecipientId != null) {
        // Send to specific contact
        final contact = contactsProvider.contacts.firstWhere(
          (c) => c.publicKeyHex == _selectedRecipientId,
        );
        await connectionProvider.sendTextMessage(
          contactPublicKey: contact.publicKey,
          text: text,
        );
      } else {
        // Send to room/channel
        // Default to channel 0 (public channel) if no specific room selected
        int channelIdx = 0;

        if (_selectedRecipientId != null) {
          // Try to find selected room
          final rooms = contactsProvider.rooms;
          try {
            final targetRoom = rooms.firstWhere(
              (r) => r.publicKeyHex == _selectedRecipientId,
            );
            if (targetRoom.outPath.isNotEmpty) {
              channelIdx = targetRoom.outPath[0];
            }
          } catch (e) {
            // Room not found, use default channel 0
          }
        }

        await connectionProvider.sendChannelMessage(
          channelIdx: channelIdx,
          text: text,
        );
      }

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent'),
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

  void _showRecipientSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipientSelectorSheet(
        selectedRecipientId: _selectedRecipientId,
        selectedRecipientType: _recipientType,
        onSelect: (recipientId, recipientType) {
          setState(() {
            _selectedRecipientId = recipientId;
            _recipientType = recipientType;
          });

          // Fetch messages from the newly selected channel/room
          _syncMessagesForRecipient();
        },
      ),
    );
  }

  /// Sync all messages when recipient changes (for sending context)
  Future<void> _syncMessagesForRecipient() async {
    final appProvider = context.read<AppProvider>();

    if (!appProvider.connectionProvider.deviceInfo.isConnected) {
      return;
    }

    try {
      debugPrint('🔄 [MessagesTab] Syncing messages after recipient change...');
      final messageCount = await appProvider.syncMessages();

      if (!mounted) return;
      if (messageCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced $messageCount message${messageCount == 1 ? '' : 's'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [MessagesTab] Error syncing messages: $e');
    }
  }

  String _getRecipientDisplayName() {
    final contactsProvider = context.read<ContactsProvider>();

    if (_selectedRecipientId == null) {
      // Default to public channel
      return 'Public Channel';
    }

    if (_recipientType == MessageRecipientType.contact) {
      try {
        final contact = contactsProvider.contacts.firstWhere(
          (c) => c.publicKeyHex == _selectedRecipientId,
        );
        return contact.displayName;
      } catch (e) {
        return 'Public Channel';
      }
    } else {
      try {
        final room = contactsProvider.rooms.firstWhere(
          (r) => r.publicKeyHex == _selectedRecipientId,
        );
        return room.displayName;
      } catch (e) {
        return 'Public Channel';
      }
    }
  }

  void _showSarDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SarUpdateSheet(
        onSend: (sarType, position, notes) async {
          await _sendSarMessage(sarType, position, notes);
        },
      ),
    );
  }

  Future<void> _sendSarMessage(
    SarMarkerType sarType,
    Position position,
    String? notes,
  ) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();

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
      // Format: S:<emoji>:<latitude>,<longitude>
      final sarMessage = 'S:${sarType.emoji}:${position.latitude},${position.longitude}';

      // Add notes if provided
      final fullMessage = notes != null && notes.isNotEmpty
          ? '$sarMessage $notes'
          : sarMessage;

      // Send to selected recipient (contact or room)
      if (_recipientType == MessageRecipientType.contact && _selectedRecipientId != null) {
        // Send to specific contact
        final contact = contactsProvider.contacts.firstWhere(
          (c) => c.publicKeyHex == _selectedRecipientId,
        );
        await connectionProvider.sendTextMessage(
          contactPublicKey: contact.publicKey,
          text: fullMessage,
        );
      } else {
        // Send to room/channel
        // Default to channel 0 (public channel) if no specific room selected
        int channelIdx = 0;

        if (_selectedRecipientId != null) {
          // Try to find selected room
          final rooms = contactsProvider.rooms;
          try {
            final targetRoom = rooms.firstWhere(
              (r) => r.publicKeyHex == _selectedRecipientId,
            );
            if (targetRoom.outPath.isNotEmpty) {
              channelIdx = targetRoom.outPath[0];
            }
          } catch (e) {
            // Room not found, use default channel 0
          }
        }

        await connectionProvider.sendChannelMessage(
          channelIdx: channelIdx,
          text: fullMessage,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sarType.displayName} marker sent'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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


  Future<void> _handleRefresh() async {
    final appProvider = context.read<AppProvider>();
    final messageCount = await appProvider.syncMessages();

    if (!mounted) return;
    if (messageCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced $messageCount message${messageCount == 1 ? '' : 's'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView.builder(
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
              child: Column(
                children: [
                  // Recipient selector bar
                  Consumer<ContactsProvider>(
                    builder: (context, contactsProvider, child) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: _showRecipientSelector,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _recipientType == MessageRecipientType.contact
                                      ? Icons.person
                                      : Icons.tag,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'To: ${_getRecipientDisplayName()}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Message input row
                  Row(
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
          ],
        ),
      ),
    );
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

// SAR Update Sheet
class _SarUpdateSheet extends StatefulWidget {
  final Future<void> Function(SarMarkerType, Position, String?) onSend;

  const _SarUpdateSheet({required this.onSend});

  @override
  State<_SarUpdateSheet> createState() => _SarUpdateSheetState();
}

class _SarUpdateSheetState extends State<_SarUpdateSheet> {
  SarMarkerType _selectedType = SarMarkerType.foundPerson;
  Position? _currentPosition;
  bool _loadingLocation = false;
  String? _locationError;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _loadingLocation = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _loadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get location: $e';
          _loadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Send SAR Marker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Quick location marker',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marker type selection
                  const Text(
                    'Marker Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MarkerTypeChip(
                    type: SarMarkerType.foundPerson,
                    isSelected: _selectedType == SarMarkerType.foundPerson,
                    onTap: () => setState(() => _selectedType = SarMarkerType.foundPerson),
                  ),
                  const SizedBox(height: 8),
                  _MarkerTypeChip(
                    type: SarMarkerType.fire,
                    isSelected: _selectedType == SarMarkerType.fire,
                    onTap: () => setState(() => _selectedType = SarMarkerType.fire),
                  ),
                  const SizedBox(height: 8),
                  _MarkerTypeChip(
                    type: SarMarkerType.stagingArea,
                    isSelected: _selectedType == SarMarkerType.stagingArea,
                    onTap: () => setState(() => _selectedType = SarMarkerType.stagingArea),
                  ),
                  const SizedBox(height: 8),
                  _MarkerTypeChip(
                    type: SarMarkerType.object,
                    isSelected: _selectedType == SarMarkerType.object,
                    onTap: () => setState(() => _selectedType = SarMarkerType.object),
                  ),
                  const SizedBox(height: 24),

                  // Location display
                  const Text(
                    'Current Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingLocation)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Getting location...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  else if (_locationError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location Error',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _locationError!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            onPressed: _getCurrentLocation,
                            tooltip: 'Retry',
                          ),
                        ],
                      ),
                    )
                  else if (_currentPosition != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
                                onPressed: _getCurrentLocation,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Refresh location',
                              ),
                            ],
                          ),
                          if (_currentPosition!.accuracy != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.my_location,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Accuracy: ±${_currentPosition!.accuracy!.round()}m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Optional notes
                  const Text(
                    'Notes (optional)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 100,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add additional information...',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2D2D2D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Bottom action button
          Container(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _currentPosition == null
                      ? null
                      : () async {
                          await widget.onSend(
                            _selectedType,
                            _currentPosition!,
                            _notesController.text.trim().isEmpty
                                ? null
                                : _notesController.text.trim(),
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 20),
                  label: const Text(
                    'Send SAR Marker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Marker Type Chip widget
class _MarkerTypeChip extends StatelessWidget {
  final SarMarkerType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _MarkerTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  Color _getMarkerColor() {
    switch (type) {
      case SarMarkerType.foundPerson:
        return Colors.green;
      case SarMarkerType.fire:
        return Colors.red;
      case SarMarkerType.stagingArea:
        return Colors.orange;
      case SarMarkerType.object:
        return Colors.purple;
      case SarMarkerType.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMarkerColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.white,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// Message recipient type enum
enum MessageRecipientType {
  contact,
  room,
}

// Recipient Selector Sheet
class _RecipientSelectorSheet extends StatefulWidget {
  final String? selectedRecipientId;
  final MessageRecipientType selectedRecipientType;
  final void Function(String?, MessageRecipientType) onSelect;

  const _RecipientSelectorSheet({
    required this.selectedRecipientId,
    required this.selectedRecipientType,
    required this.onSelect,
  });

  @override
  State<_RecipientSelectorSheet> createState() => _RecipientSelectorSheetState();
}

class _RecipientSelectorSheetState extends State<_RecipientSelectorSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.selectedRecipientType == MessageRecipientType.contact ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Select Recipient',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.person),
                text: 'Contacts',
              ),
              Tab(
                icon: Icon(Icons.tag),
                text: 'Channels',
              ),
            ],
          ),
          // Tab view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Contacts tab
                Consumer<ContactsProvider>(
                  builder: (context, contactsProvider, child) {
                    final contacts = contactsProvider.chatContacts;

                    if (contacts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No contacts available'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final isSelected = widget.selectedRecipientType == MessageRecipientType.contact &&
                            widget.selectedRecipientId == contact.publicKeyHex;

                        return ListTile(
                          leading: CircleAvatar(
                            child: contact.roleEmoji != null
                                ? Text(contact.roleEmoji!)
                                : const Icon(Icons.person),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(
                            contact.publicKeyShort,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          selected: isSelected,
                          onTap: () {
                            widget.onSelect(contact.publicKeyHex, MessageRecipientType.contact);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
                // Channels/Rooms tab
                Consumer<ContactsProvider>(
                  builder: (context, contactsProvider, child) {
                    final rooms = contactsProvider.rooms;

                    if (rooms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tag, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No channels available'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final isSelected = widget.selectedRecipientType == MessageRecipientType.room &&
                            widget.selectedRecipientId == room.publicKeyHex;

                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.tag),
                          ),
                          title: Text(room.displayName),
                          subtitle: Text(
                            room.publicKeyShort,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          selected: isSelected,
                          onTap: () {
                            widget.onSelect(room.publicKeyHex, MessageRecipientType.room);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
