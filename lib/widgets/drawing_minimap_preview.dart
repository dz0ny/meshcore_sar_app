import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import '../models/map_drawing.dart';

/// Minimap preview widget for map drawings
/// Renders a small 80x80px preview of a drawing on a map background
class DrawingMinimapPreview extends StatelessWidget {
  final MapDrawing drawing;
  final Widget? tileLayer;

  const DrawingMinimapPreview({
    super.key,
    required this.drawing,
    this.tileLayer,
  });

  /// Calculate bounds for the drawing to fit in the preview
  flutter_map.LatLngBounds _calculateBounds() {
    if (drawing is LineDrawing) {
      final lineDrawing = drawing as LineDrawing;
      if (lineDrawing.points.isEmpty) {
        // Fallback to default bounds if no points
        return flutter_map.LatLngBounds(
          const LatLng(0, 0),
          const LatLng(0.01, 0.01),
        );
      }

      // Calculate bounds from points
      double minLat = lineDrawing.points.first.latitude;
      double maxLat = lineDrawing.points.first.latitude;
      double minLon = lineDrawing.points.first.longitude;
      double maxLon = lineDrawing.points.first.longitude;

      for (final point in lineDrawing.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLon) minLon = point.longitude;
        if (point.longitude > maxLon) maxLon = point.longitude;
      }

      // Add padding (10% on each side)
      final latPadding = (maxLat - minLat) * 0.1;
      final lonPadding = (maxLon - minLon) * 0.1;

      return flutter_map.LatLngBounds(
        LatLng(minLat - latPadding, minLon - lonPadding),
        LatLng(maxLat + latPadding, maxLon + lonPadding),
      );
    } else if (drawing is RectangleDrawing) {
      final rectDrawing = drawing as RectangleDrawing;

      // Add padding (10% on each side)
      final latDiff = (rectDrawing.bottomRight.latitude - rectDrawing.topLeft.latitude).abs();
      final lonDiff = (rectDrawing.bottomRight.longitude - rectDrawing.topLeft.longitude).abs();
      final latPadding = latDiff * 0.1;
      final lonPadding = lonDiff * 0.1;

      return flutter_map.LatLngBounds(
        LatLng(
          rectDrawing.topLeft.latitude - latPadding,
          rectDrawing.topLeft.longitude - lonPadding,
        ),
        LatLng(
          rectDrawing.bottomRight.latitude + latPadding,
          rectDrawing.bottomRight.longitude + lonPadding,
        ),
      );
    }

    // Fallback to default bounds
    return flutter_map.LatLngBounds(
      const LatLng(0, 0),
      const LatLng(0.01, 0.01),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _calculateBounds();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: flutter_map.FlutterMap(
          options: flutter_map.MapOptions(
            initialCameraFit: flutter_map.CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(8),
            ),
            interactionOptions: const flutter_map.InteractionOptions(
              flags: flutter_map.InteractiveFlag.none, // Disable all interactions
            ),
          ),
          children: [
            // Use provided tile layer or fallback to gray background
            if (tileLayer != null)
              tileLayer!
            else
              Container(color: Colors.grey.shade300),

            // Render the drawing
            if (drawing is LineDrawing)
              flutter_map.PolylineLayer(
                polylines: [
                  flutter_map.Polyline(
                    points: (drawing as LineDrawing).points,
                    strokeWidth: 3.0,
                    color: drawing.color,
                  ),
                ],
              )
            else if (drawing is RectangleDrawing)
              flutter_map.PolygonLayer(
                polygons: [
                  flutter_map.Polygon(
                    points: (drawing as RectangleDrawing).corners,
                    color: drawing.color.withValues(alpha: 0.3),
                    borderColor: drawing.color,
                    borderStrokeWidth: 3.0,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
