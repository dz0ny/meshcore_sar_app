import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/contact.dart';
import '../../../models/sar_marker.dart';

/// Header component for the compass dialog showing compass rose,
/// heading, elevation, accuracy, and current location in multiple formats.
class CompassHeader extends StatelessWidget {
  final double? heading;
  final Position? position;
  final bool hasHeading;
  final Position? currentPosition;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final double zoomLevel;
  final double previousScale;
  final ValueChanged<double> onZoomUpdate;
  final VoidCallback onScaleStart;
  final VoidCallback onScaleEnd;

  const CompassHeader({
    super.key,
    required this.heading,
    required this.position,
    required this.hasHeading,
    required this.currentPosition,
    required this.contacts,
    required this.sarMarkers,
    required this.zoomLevel,
    required this.previousScale,
    required this.onZoomUpdate,
    required this.onScaleStart,
    required this.onScaleEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heading and Elevation info
        _buildInfoRow(context, heading, position),
        const SizedBox(height: 12),
        // Current location in multiple formats
        if (position != null) _LocationFormatToggle(position: position),
        const SizedBox(height: 12),
        // Large compass with zoom controls
        GestureDetector(
          onScaleStart: (details) {
            onScaleStart();
          },
          onScaleUpdate: (details) {
            onZoomUpdate(details.scale);
          },
          onScaleEnd: (details) {
            onScaleEnd();
          },
          child: SizedBox(
            width: 300,
            height: 300,
            child: _DetailedCompassPainter(
              heading: heading ?? 0,
              hasHeading: hasHeading,
              currentPosition: currentPosition,
              contacts: contacts,
              sarMarkers: sarMarkers,
              zoomLevel: zoomLevel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, double? heading, Position? position) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoCard(
          context,
          l10n.heading,
          heading != null ? '${heading.round()}°' : '--',
          Icons.explore,
        ),
        _buildInfoCard(
          context,
          l10n.elevation,
          position?.altitude != null
              ? '${position!.altitude.round()}m'
              : '--',
          Icons.terrain,
        ),
        _buildInfoCard(
          context,
          l10n.accuracy,
          position?.accuracy != null
              ? '±${position!.accuracy.round()}m'
              : '--',
          Icons.gps_fixed,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Detailed Compass Painter with contacts
class _DetailedCompassPainter extends StatelessWidget {
  final double heading;
  final bool hasHeading;
  final Position? currentPosition;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final double zoomLevel;

  const _DetailedCompassPainter({
    required this.heading,
    required this.hasHeading,
    required this.currentPosition,
    required this.contacts,
    required this.sarMarkers,
    this.zoomLevel = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LargeCompassPainter(
        heading: heading,
        hasHeading: hasHeading,
        currentPosition: currentPosition,
        contacts: contacts,
        sarMarkers: sarMarkers,
        zoomLevel: zoomLevel,
      ),
      child: Container(),
    );
  }
}

class _LargeCompassPainter extends CustomPainter {
  final double heading;
  final bool hasHeading;
  final Position? currentPosition;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final double zoomLevel;

  _LargeCompassPainter({
    required this.heading,
    required this.hasHeading,
    required this.currentPosition,
    required this.contacts,
    required this.sarMarkers,
    this.zoomLevel = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final circlePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw degree markers
    for (int i = 0; i < 360; i += 10) {
      final angle = i * pi / 180 - pi / 2 + heading * pi / 180;
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;

      final startRadius = isCardinal ? radius - 25 : (isMajor ? radius - 15 : radius - 10);
      final start = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final markerPaint = Paint()
        ..color = isCardinal ? Colors.red : Colors.grey
        ..strokeWidth = isCardinal ? 3 : (isMajor ? 2 : 1);

      canvas.drawLine(start, end, markerPaint);
    }

    // Draw cardinal directions
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2 + heading * pi / 180;
      final x = center.dx + (radius - 35) * cos(angle);
      final y = center.dy + (radius - 35) * sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: i == 0 ? Colors.red : Colors.grey.shade700,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw contacts as dots relative to distance, scaled by zoom level
    if (currentPosition != null && contacts.isNotEmpty) {
      // Calculate distances for all contacts
      final contactsWithDistance = contacts
          .where((c) => c.displayLocation != null)
          .map((contact) {
        final bearing = _calculateBearing(
          currentPosition!.latitude,
          currentPosition!.longitude,
          contact.displayLocation!.latitude,
          contact.displayLocation!.longitude,
        );
        final distance = _calculateDistance(
          currentPosition!.latitude,
          currentPosition!.longitude,
          contact.displayLocation!.latitude,
          contact.displayLocation!.longitude,
        );
        return {'contact': contact, 'bearing': bearing, 'distance': distance};
      }).toList();

      if (contactsWithDistance.isEmpty) return;

      // Base distance for zoom level 1.0 (in meters)
      // At 1x zoom, contacts within 1km appear inside the compass
      final baseDistance = 1000.0 / zoomLevel;

      for (final item in contactsWithDistance) {
        final bearing = item['bearing'] as double;
        final distance = item['distance'] as double;

        // Adjust bearing relative to current heading
        final relativeBearing = (bearing - heading + 360) % 360;
        final angle = relativeBearing * pi / 180 - pi / 2;

        // Calculate normalized distance (0 to 1, where 1 is at the rim)
        // Apply zoom level: higher zoom = contacts appear closer
        double normalizedDistance = (distance / baseDistance).clamp(0.0, 1.0);

        // Calculate contact position radius (from center to rim based on distance)
        final contactRadius = radius * normalizedDistance * 0.85; // 0.85 to keep inside rim

        // Position of contact dot
        final dotX = center.dx + contactRadius * cos(angle);
        final dotY = center.dy + contactRadius * sin(angle);

        // Draw line from center to contact
        final linePaint = Paint()
          ..color = Colors.lightBlue.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(
          center,
          Offset(dotX, dotY),
          linePaint,
        );

        // Draw contact dot (size varies with zoom)
        final dotSize = (6.0 * (1.0 + zoomLevel * 0.3)).clamp(4.0, 12.0);
        final dotPaint = Paint()
          ..color = Colors.lightBlue
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);

        // Draw darker shade border (same color family)
        final borderPaint = Paint()
          ..color = Colors.blue.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, borderPaint);

        // Draw distance label near the contact (only if not too crowded)
        if (zoomLevel >= 0.75) {
          final distanceText = _formatDistance(distance);
          final labelOffset = dotSize + 12;
          final labelX = center.dx + (contactRadius + labelOffset) * cos(angle);
          final labelY = center.dy + (contactRadius + labelOffset) * sin(angle);

          textPainter.text = TextSpan(
            text: distanceText,
            style: const TextStyle(
              color: Colors.lightBlue,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          // Draw background for readability
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(labelX, labelY),
              width: textPainter.width + 4,
              height: textPainter.height + 2,
            ),
            const Radius.circular(3),
          );
          final bgPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(bgRect, bgPaint);

          textPainter.paint(
            canvas,
            Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
          );
        }
      }
    }

    // Draw SAR markers as colored dots relative to distance, scaled by zoom level
    if (currentPosition != null && sarMarkers.isNotEmpty) {
      // Calculate distances for all SAR markers
      final markersWithDistance = sarMarkers.map((marker) {
        final bearing = _calculateBearing(
          currentPosition!.latitude,
          currentPosition!.longitude,
          marker.location.latitude,
          marker.location.longitude,
        );
        final distance = _calculateDistance(
          currentPosition!.latitude,
          currentPosition!.longitude,
          marker.location.latitude,
          marker.location.longitude,
        );
        return {'marker': marker, 'bearing': bearing, 'distance': distance};
      }).toList();

      // Base distance for zoom level 1.0 (in meters)
      final baseDistance = 1000.0 / zoomLevel;

      for (final item in markersWithDistance) {
        final marker = item['marker'] as SarMarker;
        final bearing = item['bearing'] as double;
        final distance = item['distance'] as double;

        // Adjust bearing relative to current heading
        final relativeBearing = (bearing - heading + 360) % 360;
        final angle = relativeBearing * pi / 180 - pi / 2;

        // Calculate normalized distance (0 to 1, where 1 is at the rim)
        double normalizedDistance = (distance / baseDistance).clamp(0.0, 1.0);

        // Calculate marker position radius (from center to rim based on distance)
        final markerRadius = radius * normalizedDistance * 0.85;

        // Position of marker dot
        final dotX = center.dx + markerRadius * cos(angle);
        final dotY = center.dy + markerRadius * sin(angle);

        // Determine color based on SAR marker type
        Color markerColor;
        Color borderColor;
        switch (marker.type) {
          case SarMarkerType.foundPerson:
            markerColor = Colors.green;
            borderColor = Colors.green.shade900;
            break;
          case SarMarkerType.fire:
            markerColor = Colors.red;
            borderColor = Colors.red.shade900;
            break;
          case SarMarkerType.stagingArea:
            markerColor = Colors.orange;
            borderColor = Colors.orange.shade900;
            break;
          case SarMarkerType.object:
            markerColor = Colors.purple;
            borderColor = Colors.purple.shade900;
            break;
          case SarMarkerType.unknown:
            markerColor = Colors.grey;
            borderColor = Colors.grey.shade900;
            break;
        }

        // Draw line from center to SAR marker
        final linePaint = Paint()
          ..color = markerColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(
          center,
          Offset(dotX, dotY),
          linePaint,
        );

        // Draw SAR marker dot (slightly larger than contacts)
        final dotSize = (8.0 * (1.0 + zoomLevel * 0.3)).clamp(6.0, 14.0);
        final dotPaint = Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);

        // Draw darker shade border (same color family)
        final borderPaint = Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, borderPaint);

        // Draw distance label near the SAR marker
        if (zoomLevel >= 0.75) {
          final distanceText = _formatDistance(distance);
          final labelOffset = dotSize + 14;
          final labelX = center.dx + (markerRadius + labelOffset) * cos(angle);
          final labelY = center.dy + (markerRadius + labelOffset) * sin(angle);

          textPainter.text = TextSpan(
            text: distanceText,
            style: TextStyle(
              color: markerColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          // Draw background for readability
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(labelX, labelY),
              width: textPainter.width + 4,
              height: textPainter.height + 2,
            ),
            const Radius.circular(3),
          );
          final bgPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(bgRect, bgPaint);

          textPainter.paint(
            canvas,
            Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
          );
        }
      }
    }

    // Draw center heading indicator (fixed pointing up)
    final indicatorPaint = Paint()
      ..color = hasHeading ? Colors.red : Colors.grey
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(center.dx, center.dy - 40)
      ..lineTo(center.dx - 10, center.dy + 10)
      ..lineTo(center.dx + 10, center.dy + 10)
      ..close();

    canvas.drawPath(path, indicatorPaint);
  }

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

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Location format toggle widget
class _LocationFormatToggle extends StatefulWidget {
  final Position? position;

  const _LocationFormatToggle({required this.position});

  @override
  State<_LocationFormatToggle> createState() => _LocationFormatToggleState();
}

class _LocationFormatToggleState extends State<_LocationFormatToggle> {
  bool _showDMS = false;

  String _formatDMS(double degrees, bool isLatitude) {
    final direction = isLatitude
        ? (degrees >= 0 ? 'N' : 'S')
        : (degrees >= 0 ? 'E' : 'W');

    final absolute = degrees.abs();
    final deg = absolute.floor();
    final minDecimal = (absolute - deg) * 60;
    final min = minDecimal.floor();
    final sec = (minDecimal - min) * 60;

    return '$deg°${min.toString().padLeft(2, '0')}\'${sec.toStringAsFixed(2).padLeft(5, '0')}"$direction';
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    if (position == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final String displayText;

    if (_showDMS) {
      displayText = '${_formatDMS(position.latitude, true)} ${_formatDMS(position.longitude, false)}';
    } else {
      displayText = l10n.latLonFormat(
        position.latitude.toStringAsFixed(5),
        position.longitude.toStringAsFixed(5),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showDMS = !_showDMS;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
          ),
        ),
      ),
    );
  }
}
