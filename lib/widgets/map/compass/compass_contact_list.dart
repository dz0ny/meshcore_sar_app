import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/contact.dart';

/// Contact list section for the compass dialog.
/// Shows all contacts with location sorted by distance with bearing information.
/// Splits contacts by type: Persons/Team, Repeaters, and Rooms.
class CompassContactList extends StatelessWidget {
  final List<Contact> contacts;
  final Position? position;
  final double? heading;
  final Contact? selectedContact;
  final bool showContacts;
  final bool showRepeaters;
  final ValueChanged<Contact?> onContactTap;

  const CompassContactList({
    super.key,
    required this.contacts,
    required this.position,
    this.heading,
    required this.selectedContact,
    required this.showContacts,
    required this.showRepeaters,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (position == null) {
      return Text(AppLocalizations.of(context)!.locationUnavailable);
    }

    final l10n = AppLocalizations.of(context)!;

    // Split contacts by type
    final persons = <Map<String, dynamic>>[];
    final repeaters = <Map<String, dynamic>>[];
    final rooms = <Map<String, dynamic>>[];

    // Calculate bearings and distances for each contact
    for (final contact in contacts) {
      if (contact.displayLocation == null) continue;

      final bearing = _calculateBearing(
        position!.latitude,
        position!.longitude,
        contact.displayLocation!.latitude,
        contact.displayLocation!.longitude,
      );

      final distance = _calculateDistance(
        position!.latitude,
        position!.longitude,
        contact.displayLocation!.latitude,
        contact.displayLocation!.longitude,
      );

      final item = {
        'contact': contact,
        'bearing': bearing,
        'distance': distance,
      };

      if (contact.isRepeater) {
        repeaters.add(item);
      } else if (contact.isRoom) {
        rooms.add(item);
      } else {
        persons.add(item);
      }
    }

    // Sort each list by distance
    persons.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    repeaters.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    rooms.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Persons/Team section
        if (showContacts && persons.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
            child: Text(
              l10n.teamMembers,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...persons.map((item) => _buildContactTile(
                context,
                item,
                Icons.groups,
                Theme.of(context).colorScheme.primary,
              )),
        ],
        // Repeaters section
        if (showRepeaters && repeaters.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
            child: Text(
              l10n.repeaters,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...repeaters.map((item) => _buildContactTile(
                context,
                item,
                Icons.router,
                Colors.purple,
              )),
        ],
        // Rooms section
        if (rooms.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 12),
            child: Text(
              l10n.rooms,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...rooms.map((item) => _buildContactTile(
                context,
                item,
                Icons.meeting_room,
                Colors.teal,
              )),
        ],
      ],
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    Map<String, dynamic> item,
    IconData defaultIcon,
    Color iconColor,
  ) {
    final contact = item['contact'] as Contact;
    final bearing = item['bearing'] as double;
    final distance = item['distance'] as double;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selectedContact == contact
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: selectedContact == contact
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: contact.roleEmoji != null
            ? Text(
                contact.roleEmoji!,
                style: const TextStyle(fontSize: 24),
              )
            : Icon(
                defaultIcon,
                color: iconColor,
                size: 24,
              ),
        title: Text(contact.displayName),
        subtitle: Text(
          '${_bearingToCardinal(bearing)} • ${_formatDistance(distance)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${bearing.round()}°',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (heading != null)
              Text(
                _formatRelativeBearing(bearing, heading!, context),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
          ],
        ),
        onTap: () {
          if (selectedContact == contact) {
            // Deselect if already selected
            onContactTap(null);
          } else {
            // Select this contact
            onContactTap(contact);
          }
        },
      ),
    );
  }

  // Calculate bearing between two points (in degrees)
  double _calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  // Calculate distance between two points (in meters)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String _bearingToCardinal(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatRelativeBearing(double bearing, double heading, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Calculate relative bearing (how much to turn from current heading)
    double relative = bearing - heading;

    // Normalize to -180 to +180
    while (relative > 180) {
      relative -= 360;
    }
    while (relative < -180) {
      relative += 360;
    }

    final absRelative = relative.abs().round();

    if (absRelative < 10) {
      return l10n.ahead;
    } else if (relative > 0) {
      return l10n.degreesRight(absRelative);
    } else {
      return l10n.degreesLeft(absRelative);
    }
  }
}
