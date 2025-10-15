import 'package:latlong2/latlong.dart';

/// Single advertisement location point in a contact's movement history
class AdvertLocation {
  final LatLng location;
  final DateTime timestamp;

  AdvertLocation({
    required this.location,
    required this.timestamp,
  });

  /// Get friendly time ago display
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  String toString() {
    return 'AdvertLocation(lat: ${location.latitude.toStringAsFixed(6)}, '
           'lon: ${location.longitude.toStringAsFixed(6)}, '
           'time: ${timestamp.toIso8601String()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvertLocation &&
           other.location.latitude == location.latitude &&
           other.location.longitude == location.longitude &&
           other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(location.latitude, location.longitude, timestamp);
}
