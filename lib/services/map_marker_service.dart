import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';
import '../widgets/map/location_pointer.dart';

/// Centralized service for map marker management.
///
/// This service handles:
/// - Contact marker generation
/// - SAR marker generation
/// - User location marker
/// - Distance calculations (Haversine formula)
/// - Bearing/azimuth calculations
/// - Marker color assignment
/// - Marker icon selection
///
/// Uses singleton pattern for consistent behavior across the app.
class MapMarkerService {
  // Singleton pattern
  static final MapMarkerService _instance = MapMarkerService._internal();
  factory MapMarkerService() => _instance;
  MapMarkerService._internal();

  /// Generate markers for team member contacts.
  ///
  /// Parameters:
  /// - [contacts]: List of contacts with location data
  /// - [context]: Build context for theme access
  /// - [onTap]: Callback when a marker is tapped
  /// - [mapRotation]: Current map rotation in degrees (for counter-rotation)
  ///
  /// Returns a list of markers positioned at contact locations.
  List<Marker> generateContactMarkers({
    required List<Contact> contacts,
    required BuildContext context,
    Function(Contact)? onTap,
    double mapRotation = 0,
    Position? userPosition,
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
          angle: -mapRotation * pi / 180,
          child: GestureDetector(
            onTap: onTap != null ? () => onTap(contact) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location update time indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: getLocationAgeColor(contact),
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
                // Marker icon
                Container(
                  decoration: BoxDecoration(
                    color: getContactMarkerColor(contact, context),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
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
                          getContactMarkerIcon(contact),
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
                    color: Colors.black.withValues(alpha: 0.7),
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

  /// Generate markers for SAR events.
  ///
  /// Parameters:
  /// - [sarMarkers]: List of SAR markers to display
  /// - [context]: Build context for theme access
  /// - [onTap]: Callback when a marker is tapped
  /// - [mapRotation]: Current map rotation in degrees (for counter-rotation)
  ///
  /// Returns a list of markers positioned at SAR event locations.
  List<Marker> generateSarMarkers({
    required List<SarMarker> sarMarkers,
    required BuildContext context,
    Function(SarMarker)? onTap,
    double mapRotation = 0,
  }) {
    return sarMarkers.map((marker) {
      return Marker(
        point: marker.location,
        width: 90,
        height: 100,
        rotate: false, // Don't rotate the entire marker with map
        child: Transform.rotate(
          angle: -mapRotation * pi / 180,
          child: GestureDetector(
            onTap: onTap != null ? () => onTap(marker) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time ago label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: getSarMarkerColor(marker.type),
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
                    color: getSarMarkerColor(marker.type),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
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
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    marker.displayName,  // Uses notes if available, otherwise type.displayName
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
    }).toList();
  }

  /// Generate user location marker with directional pointer.
  ///
  /// Parameters:
  /// - [position]: Current GPS position
  /// - [heading]: Current heading in degrees (0-360, where 0 = North)
  ///   Pass null or -1 if heading unavailable
  /// - [context]: Build context for theme access
  ///
  /// Returns null if position is unavailable.
  Marker? generateUserLocationMarker({
    required Position? position,
    double? heading,
    required BuildContext context,
  }) {
    if (position == null) return null;

    return Marker(
      point: LatLng(position.latitude, position.longitude),
      width: 60,
      height: 60,
      rotate: false, // Don't rotate with map - we handle rotation internally
      child: LocationPointer(
        heading: heading,
        color: Theme.of(context).colorScheme.primary,
        size: 60,
      ),
    );
  }

  /// Calculate distance between two lat/lon points using Haversine formula.
  ///
  /// Parameters:
  /// - [lat1]: Starting latitude in decimal degrees
  /// - [lon1]: Starting longitude in decimal degrees
  /// - [lat2]: Ending latitude in decimal degrees
  /// - [lon2]: Ending longitude in decimal degrees
  ///
  /// Returns distance in meters.
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
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

  /// Calculate bearing/azimuth from point 1 to point 2.
  ///
  /// Parameters:
  /// - [lat1]: Starting latitude in decimal degrees
  /// - [lon1]: Starting longitude in decimal degrees
  /// - [lat2]: Ending latitude in decimal degrees
  /// - [lon2]: Ending longitude in decimal degrees
  ///
  /// Returns bearing in degrees (0-360), where 0 is North, 90 is East.
  double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = (lon2 - lon1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  /// Convert bearing to cardinal direction.
  ///
  /// Parameters:
  /// - [bearing]: Bearing in degrees (0-360)
  ///
  /// Returns cardinal direction (N, NE, E, SE, S, SW, W, NW).
  String bearingToCardinal(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Format distance for display.
  ///
  /// Parameters:
  /// - [meters]: Distance in meters
  ///
  /// Returns formatted string (e.g., "123m" or "1.2km").
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get color for SAR marker type.
  ///
  /// Parameters:
  /// - [type]: SAR marker type
  ///
  /// Returns color for marker background.
  Color getSarMarkerColor(SarMarkerType type) {
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

  /// Get color for contact marker based on contact type.
  ///
  /// Parameters:
  /// - [contact]: Contact to get color for
  /// - [context]: Build context for theme access
  ///
  /// Returns color for marker background.
  Color getContactMarkerColor(Contact contact, BuildContext context) {
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

  /// Get icon for contact marker based on contact type.
  ///
  /// Parameters:
  /// - [contact]: Contact to get icon for
  ///
  /// Returns icon data for marker.
  IconData getContactMarkerIcon(Contact contact) {
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

  /// Get color for location age indicator.
  ///
  /// Color indicates how recent the location update is:
  /// - Green: < 5 minutes (very recent)
  /// - Light blue: 5-30 minutes (recent)
  /// - Orange: 30 minutes - 2 hours (getting old)
  /// - Red: > 2 hours (stale)
  /// - Grey: Unknown
  ///
  /// Parameters:
  /// - [contact]: Contact to check location age for
  ///
  /// Returns color for location age indicator.
  Color getLocationAgeColor(Contact contact) {
    final updateTime = contact.locationUpdateTime;
    if (updateTime == null) return Colors.grey;

    final diff = DateTime.now().difference(updateTime);
    if (diff.inMinutes < 5) return Colors.green; // Very recent
    if (diff.inMinutes < 30) return Colors.lightBlue; // Recent
    if (diff.inHours < 2) return Colors.orange; // Getting old
    return Colors.red; // Stale
  }

  /// Cluster markers if too many are visible.
  ///
  /// This is a placeholder for future clustering implementation.
  /// When implemented, it should group nearby markers into clusters
  /// to improve performance and reduce visual clutter.
  ///
  /// Parameters:
  /// - [markers]: All markers to potentially cluster
  /// - [maxVisibleMarkers]: Maximum number of individual markers to show
  ///
  /// Returns list of markers (clustered or original).
  List<Marker> clusterMarkers({
    required List<Marker> markers,
    required int maxVisibleMarkers,
  }) {
    // TODO: Implement marker clustering algorithm
    // For now, just return all markers
    return markers;
  }

  /// Calculate optimal map center from list of points.
  ///
  /// Parameters:
  /// - [contacts]: Contacts with locations
  /// - [sarMarkers]: SAR markers with locations
  /// - [defaultCenter]: Fallback center if no points available
  ///
  /// Returns center point (average of all locations).
  LatLng calculateCenter({
    required List<Contact> contacts,
    required List<SarMarker> sarMarkers,
    LatLng? defaultCenter,
  }) {
    final allPoints = <LatLng>[];

    for (final contact in contacts) {
      if (contact.displayLocation != null) {
        allPoints.add(contact.displayLocation!);
      }
    }

    for (final marker in sarMarkers) {
      allPoints.add(marker.location);
    }

    if (allPoints.isEmpty) {
      return defaultCenter ?? const LatLng(46.0569, 14.5058); // Ljubljana, Slovenia
    }

    double lat = 0, lng = 0;
    for (final point in allPoints) {
      lat += point.latitude;
      lng += point.longitude;
    }

    return LatLng(lat / allPoints.length, lng / allPoints.length);
  }

  /// Check if two positions are close enough to be considered the same location.
  ///
  /// Parameters:
  /// - [lat1]: First latitude
  /// - [lon1]: First longitude
  /// - [lat2]: Second latitude
  /// - [lon2]: Second longitude
  /// - [thresholdMeters]: Distance threshold in meters (default: 50)
  ///
  /// Returns true if points are within threshold distance.
  bool isNearby({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    double thresholdMeters = 50,
  }) {
    final distance = calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
    return distance <= thresholdMeters;
  }
}
