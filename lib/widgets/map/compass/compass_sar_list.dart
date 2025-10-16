import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/sar_marker.dart';

/// SAR marker list section for the compass dialog.
/// Shows all filtered SAR markers sorted by distance with bearing information.
class CompassSarList extends StatelessWidget {
  final List<SarMarker> sarMarkers;
  final Position? position;
  final double? heading;
  final SarMarker? selectedSarMarker;
  final ValueChanged<SarMarker?> onSarMarkerTap;

  const CompassSarList({
    super.key,
    required this.sarMarkers,
    required this.position,
    this.heading,
    required this.selectedSarMarker,
    required this.onSarMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sarMarkers.isEmpty) {
      return const SizedBox.shrink();
    }

    if (position == null) {
      return Text(AppLocalizations.of(context)!.locationUnavailable);
    }

    // Calculate bearings and distances for SAR markers
    final markersWithBearing = sarMarkers.map((marker) {
      final bearing = _calculateBearing(
        position!.latitude,
        position!.longitude,
        marker.location.latitude,
        marker.location.longitude,
      );

      final distance = _calculateDistance(
        position!.latitude,
        position!.longitude,
        marker.location.latitude,
        marker.location.longitude,
      );

      return {
        'marker': marker,
        'bearing': bearing,
        'distance': distance,
      };
    }).toList();

    // Sort by distance
    markersWithBearing.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            l10n.sarMarkers,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...markersWithBearing.map((item) {
          final marker = item['marker'] as SarMarker;
          final bearing = item['bearing'] as double;
          final distance = item['distance'] as double;

          // Determine color and icon based on marker type
          Color markerColor;
          IconData markerIcon;
          switch (marker.type) {
            case SarMarkerType.foundPerson:
              markerColor = Colors.green;
              markerIcon = Icons.person_pin;
              break;
            case SarMarkerType.fire:
              markerColor = Colors.red;
              markerIcon = Icons.local_fire_department;
              break;
            case SarMarkerType.stagingArea:
              markerColor = Colors.orange;
              markerIcon = Icons.home_work;
              break;
            case SarMarkerType.object:
              markerColor = Colors.purple;
              markerIcon = Icons.inventory_2;
              break;
            case SarMarkerType.unknown:
              markerColor = Colors.grey;
              markerIcon = Icons.help_outline;
              break;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selectedSarMarker == marker
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: selectedSarMarker == marker
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                markerIcon,
                color: markerColor,
                size: 24,
              ),
              title: Text(marker.type.displayName),
              subtitle: Text(
                '${_bearingToCardinal(bearing)} • ${_formatDistance(distance)} • ${marker.timeAgo}',
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
                if (selectedSarMarker == marker) {
                  // Deselect if already selected
                  onSarMarkerTap(null);
                } else {
                  // Select this marker
                  onSarMarkerTap(marker);
                }
              },
            ),
          );
        }),
      ],
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
