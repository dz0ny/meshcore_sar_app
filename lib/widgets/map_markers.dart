import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';

class MapMarkers {
  static List<Marker> createTeamMemberMarkers(
    List<Contact> contacts,
    BuildContext context,
  ) {
    return contacts.map((contact) {
      final location = contact.displayLocation;
      if (location == null) return null;

      return Marker(
        point: location,
        width: 80,
        height: 100,
        child: GestureDetector(
          onTap: () => _showContactInfo(context, contact),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Battery indicator
              if (contact.displayBattery != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getBatteryColor(contact.displayBattery!),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${contact.displayBattery!.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (contact.displayBattery != null) const SizedBox(height: 2),
              // Marker icon
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
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
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 2),
              // Name label
              Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  contact.advName,
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
      );
    }).whereType<Marker>().toList();
  }

  static List<Marker> createSarMarkers(
    List<SarMarker> sarMarkers,
    BuildContext context,
  ) {
    return sarMarkers.map((marker) {
      return Marker(
        point: marker.location,
        width: 90,
        height: 100,
        child: GestureDetector(
          onTap: () => _showSarMarkerInfo(context, marker),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time ago label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _getSarMarkerColor(marker.type),
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
                  color: _getSarMarkerColor(marker.type),
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
                  marker.type.emoji,
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
                child: Text(
                  marker.type.displayName,
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
      );
    }).toList();
  }

  static void _showContactInfo(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(contact.advName)),
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
            if (contact.displayBattery != null)
              _InfoRow('Battery', '${contact.displayBattery!.round()}%'),
            if (contact.telemetry?.temperature != null)
              _InfoRow(
                  'Temperature', '${contact.telemetry!.temperature!.toStringAsFixed(1)}°C'),
            _InfoRow('Last Seen', contact.timeSinceLastSeen),
            _InfoRow('Public Key', contact.publicKeyShort),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
            Text(marker.type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(marker.type.displayName)),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Color _getBatteryColor(double percentage) {
    if (percentage > 50) return Colors.green;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }

  static Color _getSarMarkerColor(SarMarkerType type) {
    switch (type) {
      case SarMarkerType.foundPerson:
        return Colors.green;
      case SarMarkerType.fire:
        return Colors.red;
      case SarMarkerType.stagingArea:
        return Colors.orange;
      case SarMarkerType.unknown:
        return Colors.grey;
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
