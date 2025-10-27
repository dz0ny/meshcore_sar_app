import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';
import '../models/sar_template.dart';
import '../l10n/app_localizations.dart';

class MapMarkers {
  static List<Marker> createTeamMemberMarkers(
    List<Contact> contacts,
    BuildContext context, {
    Function(Contact)? onContactTap,
    double mapRotation = 0,
  }) {
    return contacts.map((contact) {
      final location = contact.displayLocation;
      if (location == null) return null;

      return Marker(
        point: location,
        width: 80,
        height: 100,
        rotate: false, // Don't rotate the entire marker with map
        child: Transform.rotate(
          angle: -mapRotation * 3.14159265359 / 180,
          child: GestureDetector(
            onTap: () {
              if (onContactTap != null) {
                onContactTap(contact);
              } else {
                _showContactInfo(context, contact);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location update time indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getLocationAgeColor(contact),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    contact.timeSinceLocationUpdate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Marker icon or emoji
                Container(
                  decoration: BoxDecoration(
                    color: _getContactTypeColor(contact, context),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: contact.roleEmoji != null
                      ? Text(
                          contact.roleEmoji!,
                          style: const TextStyle(fontSize: 18),
                        )
                      : Icon(
                          _getContactTypeIcon(contact),
                          color: Colors.white,
                          size: 18,
                        ),
                ),
                const SizedBox(height: 2),
                // Name label (without emoji)
                Container(
                  constraints: const BoxConstraints(maxWidth: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    contact.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  static List<Marker> createSarMarkers(
    List<SarMarker> sarMarkers,
    BuildContext context, {
    Function(SarMarker)? onSarMarkerTap,
    double mapRotation = 0,
  }) {
    return sarMarkers.map((marker) {
      return Marker(
        point: marker.location,
        width: 90,
        height: 100,
        rotate: false, // Don't rotate the entire marker with map
        child: Transform.rotate(
          angle: -mapRotation * 3.14159265359 / 180,
          child: GestureDetector(
            onTap: () {
              if (onSarMarkerTap != null) {
                onSarMarkerTap(marker);
              } else {
                _showSarMarkerInfo(context, marker);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time ago label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getSarMarkerColor(marker),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    marker.timeAgo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Marker emoji/icon
                Container(
                  decoration: BoxDecoration(
                    color: _getSarMarkerColor(marker),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    marker.emoji,  // Use custom emoji if available
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 2),
                // Type label
                Container(
                  constraints: const BoxConstraints(maxWidth: 90),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Builder(
                    builder: (context) {
                      // Debug: Print what we're actually displaying
                      debugPrint('🗺️ [MapMarker] Displaying SAR marker:');
                      debugPrint('   marker.notes: "${marker.notes}"');
                      debugPrint('   marker.type: ${marker.type}');
                      debugPrint('   marker.type.displayName: ${marker.type.displayName}');
                      debugPrint('   marker.displayName: ${marker.displayName}');

                      return Text(
                        marker.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  static void _showContactInfo(BuildContext context, Contact contact) {
    // Import provider to get all contacts and SAR markers for detailed view
    // This will be handled by importing the screen's detailed compass dialog
    // Since we can't directly access _DetailedCompassDialog from here,
    // we'll pass a callback to the screen
    // For now, show the simple dialog as a fallback
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (contact.roleEmoji != null)
              Text(contact.roleEmoji!, style: const TextStyle(fontSize: 24))
            else
              Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(contact.displayName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.displayLocation != null) ...[
              _InfoRow(
                'Location',
                '${contact.displayLocation!.latitude.toStringAsFixed(6)}, ${contact.displayLocation!.longitude.toStringAsFixed(6)}',
              ),
            ],
            if (contact.telemetry?.batteryMilliVolts != null)
              _InfoRow(
                'Voltage',
                '${(contact.telemetry!.batteryMilliVolts! / 1000).toStringAsFixed(3)}V'
                '${contact.telemetry!.batteryPercentage != null ? ' (${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%)' : ''}',
              )
            else if (contact.displayBattery != null)
              _InfoRow('Battery', '${contact.displayBattery!.round()}%'),
            if (contact.telemetry?.temperature != null)
              _InfoRow(
                  'Temperature', '${contact.telemetry!.temperature!.toStringAsFixed(1)}°C'),
            if (contact.telemetry?.humidity != null)
              _InfoRow('Humidity', '${contact.telemetry!.humidity!.toStringAsFixed(1)}%'),
            if (contact.telemetry?.pressure != null)
              _InfoRow('Pressure', '${contact.telemetry!.pressure!.toStringAsFixed(1)} hPa'),
            _InfoRow('Last Seen', contact.timeSinceLastSeen),
            _InfoRow('Public Key', contact.publicKeyShort),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  static void _showSarMarkerInfo(BuildContext context, SarMarker marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(marker.emoji, style: const TextStyle(fontSize: 24)),  // Use custom emoji if available
            const SizedBox(width: 8),
            Expanded(child: Text(marker.displayName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              'Location',
              '${marker.location.latitude.toStringAsFixed(6)}, ${marker.location.longitude.toStringAsFixed(6)}',
            ),
            _InfoRow('Reported', marker.timeAgo),
            if (marker.senderName != null)
              _InfoRow('Reporter', marker.senderName!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  static Color _getLocationAgeColor(Contact contact) {
    final updateTime = contact.locationUpdateTime;
    if (updateTime == null) return Colors.grey;

    final diff = DateTime.now().difference(updateTime);
    if (diff.inMinutes < 5) return Colors.green; // Very recent
    if (diff.inMinutes < 30) return Colors.lightBlue; // Recent
    if (diff.inHours < 2) return Colors.orange; // Getting old
    return Colors.red; // Stale
  }

  static Color _getSarMarkerColor(SarMarker marker) {
    // If marker has a color index, use it (new format)
    if (marker.colorIndex != null && marker.colorIndex! >= 0 && marker.colorIndex! < 8) {
      final colorHex = SarTemplate.getColorFromIndex(marker.colorIndex!);
      final hexCode = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    }

    // Otherwise fall back to type-based colors (old format or backward compatibility)
    switch (marker.type) {
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

  static Color _getContactTypeColor(Contact contact, BuildContext context) {
    switch (contact.type) {
      case ContactType.chat:
        return Theme.of(context).colorScheme.primary; // Blue for team members
      case ContactType.repeater:
        return Colors.deepPurple; // Purple for repeaters
      case ContactType.room:
        return Colors.teal; // Teal for rooms
      case ContactType.channel:
        return Colors.orange; // Orange for channels
      case ContactType.none:
        return Colors.grey;
    }
  }

  static IconData _getContactTypeIcon(Contact contact) {
    switch (contact.type) {
      case ContactType.chat:
        return Icons.person; // Person for team members
      case ContactType.repeater:
        return Icons.router; // Router icon for repeaters
      case ContactType.room:
        return Icons.forum; // Forum/chat icon for rooms
      case ContactType.channel:
        return Icons.public; // Public icon for channels
      case ContactType.none:
        return Icons.help_outline;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
