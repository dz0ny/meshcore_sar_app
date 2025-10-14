import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
import '../models/contact.dart';

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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
            // Login button for rooms (except public channel)
            if (contact.type == ContactType.room && contact.advName != 'Public Channel')
              IconButton(
                icon: const Icon(Icons.login, size: 20),
                onPressed: () => _showRoomLoginDialog(context, contact),
                tooltip: 'Login to room',
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
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loginToRoom() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    setState(() {
      _isLoggingIn = true;
    });

    try {
      // Send login request to room
      await connectionProvider.loginToRoom(
        roomPublicKey: widget.contact.publicKey,
        password: password,
      );

      _passwordController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login request sent to ${widget.contact.displayName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to login: $e'),
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
      height: MediaQuery.of(context).size.height * 0.6,
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
                    'Enter the password to access this room. You will receive a confirmation once logged in.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Spacer(),

          // Password input
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
                    hintText: 'Enter room password',
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
                    onPressed: _isLoggingIn || _passwordController.text.trim().isEmpty
                        ? null
                        : _loginToRoom,
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
    );
  }
}
