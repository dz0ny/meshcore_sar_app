import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/contacts_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
import '../models/contact.dart';
import '../models/room_login_state.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  Future<void> _handleRefresh() async {
    final appProvider = context.read<AppProvider>();
    await appProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, contactsProvider, child) {
        final chatContacts = contactsProvider.chatContacts;
        final repeaters = contactsProvider.repeaters;
        final rooms = contactsProvider.rooms;

        if (contactsProvider.contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.contacts_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No contacts yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to a device to load contacts',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
            // Team Members (Chat contacts)
            if (chatContacts.isNotEmpty) ...[
              _SectionHeader(
                title: 'Team Members',
                count: chatContacts.length,
                icon: Icons.people,
              ),
              ...chatContacts.map((contact) => _ContactTile(contact: contact)),
              const Divider(height: 32),
            ],

            // Repeaters
            if (repeaters.isNotEmpty) ...[
              _SectionHeader(
                title: 'Repeaters',
                count: repeaters.length,
                icon: Icons.router,
              ),
              ...repeaters.map((contact) => _ContactTile(contact: contact)),
              const Divider(height: 32),
            ],

            // Rooms/Channels
            if (rooms.isNotEmpty) ...[
              _SectionHeader(
                title: 'Rooms/Channels',
                count: rooms.length,
                icon: Icons.tag,
              ),
              ...rooms.map((contact) => _ContactTile(contact: contact)),
            ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;

  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final hasTelemetry = contact.telemetry != null && contact.telemetry!.isRecent;
    final battery = contact.displayBattery;
    final location = contact.displayLocation;

    // Get room login state if this is a room
    final connectionProvider = context.watch<ConnectionProvider>();
    final roomLoginState = contact.type == ContactType.room
        ? connectionProvider.getRoomLoginState(contact.publicKeyPrefix)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getTypeColor(contact.type, context),
              child: contact.roleEmoji != null
                  ? Text(
                      contact.roleEmoji!,
                      style: const TextStyle(fontSize: 24),
                    )
                  : Icon(
                      _getTypeIcon(contact.type),
                      color: Colors.white,
                    ),
            ),
            // Room login status indicator badge
            if (contact.type == ContactType.room && roomLoginState != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getRoomStatusColor(roomLoginState),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _getRoomStatusIcon(roomLoginState),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room name with battery indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    contact.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Battery indicator
                if (battery != null) ...[
                  Icon(
                    _getBatteryIcon(battery),
                    size: 16,
                    color: _getBatteryColor(battery),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${battery.round()}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            // Room login status badges on second line
            if (roomLoginState != null && roomLoginState.isLoggedIn) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (roomLoginState.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 10, color: Colors.red),
                          const SizedBox(width: 2),
                          Text(
                            'Admin',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (roomLoginState.isAdmin) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 10, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          'Logged In',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Type and last seen
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(contact.type, context).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contact.type.displayName,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: contact.isRecentlySeen ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  contact.timeSinceLastSeen,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Telemetry info
            Row(
              children: [
                if (hasTelemetry)
                  const Icon(Icons.sensors, size: 12, color: Colors.green)
                else
                  const Icon(Icons.sensors_off, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                if (location != null)
                  Expanded(
                    child: Text(
                      'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    'No GPS data',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message icon - only for chat contacts
            if (contact.type == ContactType.chat)
              IconButton(
                icon: const Icon(Icons.message, size: 20),
                onPressed: () => _showDirectMessageDialog(context, contact),
                tooltip: 'Send direct message',
              ),
            // Telemetry refresh button
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: () {
                final connectionProvider = context.read<ConnectionProvider>();
                connectionProvider.requestTelemetry(contact.publicKey);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Requesting telemetry from ${contact.displayName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Request telemetry',
            ),
          ],
        ),
        onTap: () => _showContactDetails(context, contact),
        onLongPress: () {
          final connectionProvider = context.read<ConnectionProvider>();
          connectionProvider.requestTelemetry(contact.publicKey, zeroHop: true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pinging ${contact.displayName} (direct connection)...'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showDirectMessageDialog(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DirectMessageSheet(contact: contact),
    );
  }

  void _showRoomLoginDialog(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoomLoginSheet(contact: contact),
    );
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    // Get room login state
    final connectionProvider = context.read<ConnectionProvider>();
    final roomLoginState = contact.type == ContactType.room
        ? connectionProvider.getRoomLoginState(contact.publicKeyPrefix)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getTypeColor(contact.type, context),
                    child: contact.roleEmoji != null
                        ? Text(
                            contact.roleEmoji!,
                            style: const TextStyle(fontSize: 24),
                          )
                        : Icon(
                            _getTypeIcon(contact.type),
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailRow('Type', contact.type.displayName),
                  _DetailRow('Public Key', contact.publicKeyShort),
                  _DetailRow('Last Seen', contact.timeSinceLastSeen),
                  const SizedBox(height: 16),
                  // Room Login Status
                  if (roomLoginState != null) ...[
                    const Text(
                      'Room Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      'Login Status',
                      roomLoginState.isLoggedIn ? 'Logged In' : 'Not Logged In',
                    ),
                    if (roomLoginState.isLoggedIn) ...[
                      _DetailRow(
                        'Admin Access',
                        roomLoginState.isAdmin ? 'Yes' : 'No',
                      ),
                      _DetailRow(
                        'Permissions',
                        roomLoginState.permissions.toString(),
                      ),
                      if (roomLoginState.loginDurationFormatted != null)
                        _DetailRow(
                          'Logged In',
                          roomLoginState.loginDurationFormatted!,
                        ),
                    ],
                    _DetailRow(
                      'Password Saved',
                      roomLoginState.hasPassword ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (contact.displayLocation != null) ...[
                    const Text(
                      'Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow('Latitude', contact.displayLocation!.latitude.toStringAsFixed(6)),
                    _DetailRow('Longitude', contact.displayLocation!.longitude.toStringAsFixed(6)),
                    const SizedBox(height: 16),
                  ],
                  if (contact.telemetry != null) ...[
                    const Text(
                      'Telemetry:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (contact.telemetry!.batteryMilliVolts != null)
                      _DetailRow(
                        'Voltage',
                        '${(contact.telemetry!.batteryMilliVolts! / 1000).toStringAsFixed(3)}V'
                        '${contact.telemetry!.batteryPercentage != null ? ' (${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%)' : ''}',
                      )
                    else if (contact.telemetry!.batteryPercentage != null)
                      _DetailRow('Battery', '${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%'),
                    if (contact.telemetry!.temperature != null)
                      _DetailRow('Temperature', '${contact.telemetry!.temperature!.toStringAsFixed(1)}°C'),
                    if (contact.telemetry!.humidity != null)
                      _DetailRow('Humidity', '${contact.telemetry!.humidity!.toStringAsFixed(1)}%'),
                    if (contact.telemetry!.pressure != null)
                      _DetailRow('Pressure', '${contact.telemetry!.pressure!.toStringAsFixed(1)} hPa'),
                    if (contact.telemetry!.gpsLocation != null)
                      _DetailRow(
                        'GPS (Telemetry)',
                        '${contact.telemetry!.gpsLocation!.latitude.toStringAsFixed(6)}, ${contact.telemetry!.gpsLocation!.longitude.toStringAsFixed(6)}',
                      ),
                    _DetailRow(
                      'Updated',
                      '${_formatTimestamp(contact.telemetry!.timestamp)} (${_formatTimeAgo(contact.telemetry!.timestamp)})',
                    ),
                  ],
                  // Room Login button for room contacts (except Public Channel)
                  if (contact.type == ContactType.room && contact.advName != 'Public Channel') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close details first
                          _showRoomLoginDialog(context, contact);
                        },
                        icon: const Icon(Icons.login),
                        label: Text(roomLoginState?.isLoggedIn == true ? 'Re-Login to Room' : 'Login to Room'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _getTypeColor(contact.type, context),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.chat:
        return Icons.person;
      case ContactType.repeater:
        return Icons.router;
      case ContactType.room:
        return Icons.tag;
      default:
        return Icons.help;
    }
  }

  Color _getTypeColor(ContactType type, BuildContext context) {
    switch (type) {
      case ContactType.chat:
        return Theme.of(context).colorScheme.primary;
      case ContactType.repeater:
        return Colors.green;
      case ContactType.room:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getBatteryIcon(double percentage) {
    if (percentage > 80) return Icons.battery_full;
    if (percentage > 50) return Icons.battery_5_bar;
    if (percentage > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(double percentage) {
    if (percentage > 50) return Colors.green;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }

  /// Get room login status color
  Color _getRoomStatusColor(RoomLoginState state) {
    if (!state.isLoggedIn) {
      return Colors.grey; // Grey for not logged in
    }
    if (state.isAdmin) {
      return Colors.red; // Red for admin
    }
    return Colors.green; // Green for logged in (non-admin)
  }

  /// Get room login status icon
  IconData _getRoomStatusIcon(RoomLoginState state) {
    if (!state.isLoggedIn) {
      return Icons.lock; // Lock for not logged in
    }
    if (state.isAdmin) {
      return Icons.admin_panel_settings; // Admin icon for admin
    }
    return Icons.check; // Check for logged in (non-admin)
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (timestampDate == today) {
      // Today - show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    } else {
      // Another day - show date and time
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

// Direct Message Sheet Widget
class _DirectMessageSheet extends StatefulWidget {
  final Contact contact;

  const _DirectMessageSheet({required this.contact});

  @override
  State<_DirectMessageSheet> createState() => _DirectMessageSheetState();
}

class _DirectMessageSheetState extends State<_DirectMessageSheet> {
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
      // Send direct message to contact
      await connectionProvider.sendTextMessage(
        contactPublicKey: widget.contact.publicKey,
        text: text,
      );

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Direct message sent to ${widget.contact.displayName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Direct Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.contact.displayName,
                        style: const TextStyle(
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
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterText: _characterCount >= 150
                        ? '$_characterCount/$_maxCharacters'
                        : '',
                    counterStyle: TextStyle(
                      fontSize: 11,
                      color: _characterCount > _maxCharacters * 0.9
                          ? Colors.orange
                          : Colors.grey,
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

// Room Login Sheet Widget
class _RoomLoginSheet extends StatefulWidget {
  final Contact contact;

  const _RoomLoginSheet({required this.contact});

  @override
  State<_RoomLoginSheet> createState() => _RoomLoginSheetState();
}

class _RoomLoginSheetState extends State<_RoomLoginSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPassword();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Load saved password for this room, or use default "hello"
  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final roomKey = 'room_password_${widget.contact.publicKeyHex}';
    final savedPassword = prefs.getString(roomKey) ?? 'hello';
    _passwordController.text = savedPassword;
  }

  /// Save password for this room
  Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final roomKey = 'room_password_${widget.contact.publicKeyHex}';
    await prefs.setString(roomKey, password);
  }

  Future<void> _loginToRoom() async {
    final password = _passwordController.text.trim().isEmpty
        ? 'hello'
        : _passwordController.text.trim();

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

    setState(() {
      _isLoggingIn = true;
    });

    // 🕐 CLOCK DRIFT CHECK: Get device time to detect synchronization issues
    print('🕐 [RoomLogin] Checking for clock drift between app and radio...');
    try {
      await connectionProvider.getDeviceTime();
      // Give time for response to be logged
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ [RoomLogin] Failed to get device time: $e');
      // Don't fail login - this is just a diagnostic check
    }

    // 🔍 PRE-LOGIN CHECK: Ensure room contact exists in device
    print('🔍 [RoomLogin] Checking if room "${widget.contact.advName}" exists in contacts...');
    print('   Target public key prefix: ${widget.contact.publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

    // Check if the room exists in our local contacts
    bool roomExists = contactsProvider.rooms.any(
      (room) => room.publicKeyHex == widget.contact.publicKeyHex,
    );

    print('   Local contact list: ${roomExists ? "✅ Found" : "❌ Not found"}');

    if (!roomExists) {
      print('⚠️ [RoomLogin] Room not in local contacts - syncing with device...');

      try {
        // Sync contacts from device
        await connectionProvider.getContacts();

        // Give time for contacts to be processed
        await Future.delayed(const Duration(milliseconds: 800));

        // Check again after sync
        roomExists = contactsProvider.rooms.any(
          (room) => room.publicKeyHex == widget.contact.publicKeyHex,
        );

        print('   After sync: ${roomExists ? "✅ Found" : "❌ Still not found"}');

        if (!roomExists) {
          // Room still doesn't exist on the device - try to add it manually
          print('❌ [RoomLogin] Room still not found after sync');
          print('🔧 [RoomLogin] Attempting to add room contact to companion radio...');

          try {
            // Manually add the room contact to the radio's flash storage
            await connectionProvider.addOrUpdateContact(widget.contact);

            print('✅ [RoomLogin] Room contact added via CMD_ADD_UPDATE_CONTACT');
            print('   Waiting 500ms for radio to save to flash...');

            // Give the radio time to save the contact to flash
            await Future.delayed(const Duration(milliseconds: 500));

            print('✅ [RoomLogin] Room contact should now be available - proceeding with login');
          } catch (e) {
            print('❌ [RoomLogin] Failed to add room contact: $e');

            if (!mounted) return;

            setState(() {
              _isLoggingIn = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to add room to device: $e\n\n'
                  'The room may not have advertised yet.\n'
                  'Try waiting for the room to broadcast.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 7),
              ),
            );

            // Log available rooms for debugging
            final availableRooms = contactsProvider.rooms;
            print('📋 [RoomLogin] Available rooms on device (${availableRooms.length}):');
            for (final room in availableRooms) {
              print('   - ${room.advName} (${room.publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')})');
            }

            return;
          }
        }

        print('✅ [RoomLogin] Room contact found after sync - proceeding with login');
      } catch (e) {
        print('❌ [RoomLogin] Contact sync failed: $e');

        if (!mounted) return;

        setState(() {
          _isLoggingIn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      print('✅ [RoomLogin] Room contact found in local contacts - proceeding with login');
    }

    // Save password before sending
    await _savePassword(password);

    // Set up login callbacks
    Function(Uint8List, int, bool, int)? originalOnSuccess;
    Function(Uint8List)? originalOnFail;

    originalOnSuccess = connectionProvider.onLoginSuccess;
    originalOnFail = connectionProvider.onLoginFail;

    connectionProvider.onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      // Restore original callback
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      print('✅ [RoomLogin] Login successful! Tag: $tag, Permissions: $permissions, Admin: $isAdmin');
      print('📡 [RoomLogin] Room server will now push messages automatically via PUSH_CODE_MSG_WAITING');
      print('   Messages will be fetched when onMessageWaiting callback is triggered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in successfully! Waiting for room messages...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    };

    connectionProvider.onLoginFail = (publicKeyPrefix) {
      // Restore original callback
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      print('❌ [RoomLogin] Login failed - incorrect password');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed - incorrect password'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    };

    try {
      // Send login request to room
      await connectionProvider.loginToRoom(
        roomPublicKey: widget.contact.publicKey,
        password: password,
      );

      _focusNode.unfocus();

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging in to ${widget.contact.displayName}...'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Restore original callbacks on error
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send login: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Login to Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.contact.displayName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enter the password to access this room. Password defaults to "hello" and will be saved for future use.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Password input (fixed at bottom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _passwordController,
                  focusNode: _focusNode,
                  maxLength: 15, // Max password length from protocol
                  obscureText: _obscurePassword,
                  autofocus: true,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: 'Enter room password (default: hello)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loginToRoom(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoggingIn ? null : _loginToRoom,
                    icon: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoggingIn ? 'Logging in...' : 'Login'),
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
    ),
    );
  }
}
