import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/messages_provider.dart';
import '../widgets/contacts/contact_tile.dart';
import '../widgets/contacts/add_channel_dialog.dart';

class ContactsTab extends StatefulWidget {
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;

  const ContactsTab({
    super.key,
    this.onNavigateToMap,
    this.onNavigateToMessages,
  });

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  Position? _currentPosition;
  final Set<String> _resolvingAdvertKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Mark all contacts as viewed when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().markAllAsViewed();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Silently fail if location not available
      debugPrint('Failed to get location: $e');
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    await appProvider.refresh();
    // Also refresh location
    if (!mounted) return;
    await _getCurrentLocation();
  }

  Future<void> _handleResolveAdvert(PendingAdvert advert) async {
    final keyHex = advert.publicKeyHex;
    if (_resolvingAdvertKeys.contains(keyHex)) return;

    setState(() {
      _resolvingAdvertKeys.add(keyHex);
    });

    try {
      await context.read<ConnectionProvider>().getContact(advert.publicKey);
    } finally {
      if (mounted) {
        setState(() {
          _resolvingAdvertKeys.remove(keyHex);
        });
      }
    }
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else if (meters < 10000) {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatRelativeTime(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  List<Contact> _sortContactsByDistance(List<Contact> contacts) {
    final sorted = List<Contact>.from(contacts);

    sorted.sort((a, b) {
      final distanceA = _distanceFromCurrentPosition(a);
      final distanceB = _distanceFromCurrentPosition(b);

      if (distanceA != null && distanceB != null) {
        final distanceCompare = distanceA.compareTo(distanceB);
        if (distanceCompare != 0) return distanceCompare;
      } else if (distanceA != null) {
        return -1;
      } else if (distanceB != null) {
        return 1;
      }

      return b.lastSeenTime.compareTo(a.lastSeenTime);
    });

    return sorted;
  }

  double? _distanceFromCurrentPosition(Contact contact) {
    final currentPosition = _currentPosition;
    final contactLocation = contact.displayLocation;
    if (currentPosition == null || contactLocation == null) {
      return null;
    }

    return _calculateDistanceInMeters(
      currentPosition.latitude,
      currentPosition.longitude,
      contactLocation.latitude,
      contactLocation.longitude,
    );
  }

  /// Show the add channel dialog
  Future<void> _showAddChannelDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AddChannelDialog(
        onCreateChannel: (name, secret) async {
          final connectionProvider = context.read<ConnectionProvider>();
          try {
            await connectionProvider.createChannel(
              channelName: name,
              channelSecret: secret,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.channelCreatedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.channelCreationFailed(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
            rethrow; // Re-throw to let dialog handle the error state
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer2<ContactsProvider, MessagesProvider>(
        builder: (context, contactsProvider, messagesProvider, child) {
          final chatContacts = _sortContactsByDistance(
            contactsProvider.chatContacts,
          );
          final repeaters = _sortContactsByDistance(contactsProvider.repeaters);
          final rooms = _sortContactsByDistance(contactsProvider.rooms);
          final channels = _sortContactsByDistance(contactsProvider.channels);
          final pendingAdverts = contactsProvider.pendingAdverts;

          // Check if there are any displayable contacts (excluding channels)
          final hasDisplayableContacts =
              chatContacts.isNotEmpty ||
              repeaters.isNotEmpty ||
              rooms.isNotEmpty ||
              pendingAdverts.isNotEmpty;

          if (!hasDisplayableContacts) {
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
                    l10n.noContactsYet,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.connectToDeviceToLoadContacts,
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
                // Pending adverts (public key only; quick resolve)
                if (pendingAdverts.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.pending,
                    count: pendingAdverts.length,
                    icon: Icons.person_add_alt_1,
                  ),
                  ...pendingAdverts.map(
                    (advert) => _PendingAdvertTile(
                      advert: advert,
                      subtitle:
                          '${l10n.publicKey}: ${advert.publicKeyHex}\n${l10n.lastSeen}: ${_formatRelativeTime(context, advert.receivedAt)}',
                      isResolving: _resolvingAdvertKeys.contains(
                        advert.publicKeyHex,
                      ),
                      onResolve: () => _handleResolveAdvert(advert),
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // Team Members (Chat contacts)
                if (chatContacts.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.teamMembers,
                    count: chatContacts.length,
                    icon: Icons.people,
                  ),
                  ...chatContacts.map(
                    (contact) => ContactTile(
                      contact: contact,
                      currentPosition: _currentPosition,
                      calculateDistance: _calculateDistanceInMeters,
                      formatDistance: _formatDistance,
                      onNavigateToMap: widget.onNavigateToMap,
                      onNavigateToMessages: widget.onNavigateToMessages,
                      messageCount: messagesProvider
                          .getMessageCountForDestination(contact),
                      unreadMessageCount: messagesProvider
                          .getUnreadCountForDestination(contact),
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // Repeaters
                if (repeaters.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.repeaters,
                    count: repeaters.length,
                    icon: Icons.router,
                  ),
                  ...repeaters.map(
                    (contact) => ContactTile(
                      contact: contact,
                      currentPosition: _currentPosition,
                      calculateDistance: _calculateDistanceInMeters,
                      formatDistance: _formatDistance,
                      onNavigateToMap: widget.onNavigateToMap,
                      onNavigateToMessages: widget.onNavigateToMessages,
                      messageCount: messagesProvider
                          .getMessageCountForDestination(contact),
                      unreadMessageCount: messagesProvider
                          .getUnreadCountForDestination(contact),
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // Rooms
                if (rooms.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.rooms,
                    count: rooms.length,
                    icon: Icons.tag,
                  ),
                  ...rooms.map(
                    (contact) => ContactTile(
                      contact: contact,
                      currentPosition: _currentPosition,
                      calculateDistance: _calculateDistanceInMeters,
                      formatDistance: _formatDistance,
                      onNavigateToMap: widget.onNavigateToMap,
                      onNavigateToMessages: widget.onNavigateToMessages,
                      messageCount: messagesProvider
                          .getMessageCountForDestination(contact),
                      unreadMessageCount: messagesProvider
                          .getUnreadCountForDestination(contact),
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // Channels (visible in both simple and advanced mode)
                _SectionHeader(
                  title: l10n.channels,
                  count: channels.length,
                  icon: Icons.broadcast_on_personal,
                ),
                if (channels.isNotEmpty) ...[
                  ...channels.map(
                    (contact) => ContactTile(
                      contact: contact,
                      currentPosition: _currentPosition,
                      calculateDistance: _calculateDistanceInMeters,
                      formatDistance: _formatDistance,
                      onNavigateToMap: widget.onNavigateToMap,
                      onNavigateToMessages: widget.onNavigateToMessages,
                      messageCount: messagesProvider
                          .getMessageCountForDestination(contact),
                      unreadMessageCount: messagesProvider
                          .getUnreadCountForDestination(contact),
                    ),
                  ),
                ],

                // Add Channel Button (visible in both simple and advanced mode, only show when connected)
                if (context.watch<ConnectionProvider>().deviceInfo.isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddChannelDialog(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.addChannel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingAdvertTile extends StatelessWidget {
  final PendingAdvert advert;
  final String subtitle;
  final bool isResolving;
  final VoidCallback onResolve;

  const _PendingAdvertTile({
    required this.advert,
    required this.subtitle,
    required this.isResolving,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
        title: Text(
          advert.shortDisplayKey,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: isResolving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Quick add',
                onPressed: onResolve,
              ),
      ),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
