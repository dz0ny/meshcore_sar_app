import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/contacts_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/contacts/contact_tile.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  Position? _currentPosition;

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
    final appProvider = context.read<AppProvider>();
    await appProvider.refresh();
    // Also refresh location
    await _getCurrentLocation();
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
                ...chatContacts.map(
                  (contact) => ContactTile(
                    contact: contact,
                    currentPosition: _currentPosition,
                    calculateDistance: _calculateDistanceInMeters,
                    formatDistance: _formatDistance,
                  ),
                ),
                const Divider(height: 32),
              ],

              // Repeaters
              if (repeaters.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Repeaters',
                  count: repeaters.length,
                  icon: Icons.router,
                ),
                ...repeaters.map(
                  (contact) => ContactTile(
                    contact: contact,
                    currentPosition: _currentPosition,
                    calculateDistance: _calculateDistanceInMeters,
                    formatDistance: _formatDistance,
                  ),
                ),
                const Divider(height: 32),
              ],

              // Rooms/Channels
              if (rooms.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Rooms',
                  count: rooms.length,
                  icon: Icons.tag,
                ),
                ...rooms.map(
                  (contact) => ContactTile(
                    contact: contact,
                    currentPosition: _currentPosition,
                    calculateDistance: _calculateDistanceInMeters,
                    formatDistance: _formatDistance,
                  ),
                ),
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
