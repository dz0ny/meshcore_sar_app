import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../models/map_drawing.dart';

/// Widget that renders map drawings as polylines
class DrawingLayer extends StatelessWidget {
  final List<MapDrawing> drawings;
  final MapDrawing? previewDrawing;

  const DrawingLayer({
    super.key,
    required this.drawings,
    this.previewDrawing,
  });

  @override
  Widget build(BuildContext context) {
    final List<Polyline> polylines = [];

    // Add completed drawings
    for (final drawing in drawings) {
      polylines.add(_createPolyline(drawing, isPreview: false));
    }

    // Add preview drawing (if any)
    if (previewDrawing != null) {
      polylines.add(_createPolyline(previewDrawing!, isPreview: true));
    }

    return PolylineLayer(polylines: polylines);
  }

  /// Create a polyline from a drawing
  Polyline _createPolyline(MapDrawing drawing, {required bool isPreview}) {
    final points = _getPoints(drawing);
    final opacity = isPreview ? 0.6 : 1.0;

    return Polyline(
      points: points,
      color: drawing.color.withOpacity(opacity),
      strokeWidth: 4.0,
      borderColor: Colors.white.withOpacity(opacity * 0.8),
      borderStrokeWidth: 1.0,
    );
  }

  /// Get points from a drawing based on its type
  List<LatLng> _getPoints(MapDrawing drawing) {
    if (drawing is LineDrawing) {
      return drawing.points;
    } else if (drawing is RectangleDrawing) {
      return drawing.corners;
    }
    return [];
  }
}

/// Widget that shows drawing markers (start/end points)
class DrawingMarkersLayer extends StatelessWidget {
  final List<MapDrawing> drawings;
  final Function(String drawingId)? onDeleteDrawing;

  const DrawingMarkersLayer({
    super.key,
    required this.drawings,
    this.onDeleteDrawing,
  });

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = [];

    // Add delete markers for each drawing (at the center point)
    for (final drawing in drawings) {
      final centerPoint = _getCenterPoint(drawing);
      if (centerPoint != null) {
        markers.add(
          Marker(
            point: centerPoint,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (onDeleteDrawing != null) {
                  _showDeleteDialog(context, drawing);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: drawing.color.withOpacity(0.9),
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
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    return MarkerLayer(markers: markers);
  }

  /// Get the center point of a drawing
  LatLng? _getCenterPoint(MapDrawing drawing) {
    if (drawing is LineDrawing && drawing.points.isNotEmpty) {
      // Use the middle point of the line
      final midIndex = drawing.points.length ~/ 2;
      return drawing.points[midIndex];
    } else if (drawing is RectangleDrawing) {
      // Use the center of the rectangle
      return LatLng(
        (drawing.topLeft.latitude + drawing.bottomRight.latitude) / 2,
        (drawing.topLeft.longitude + drawing.bottomRight.longitude) / 2,
      );
    }
    return null;
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, MapDrawing drawing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Drawing'),
        content: Text(
          'Delete this ${drawing.type.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteDrawing?.call(drawing.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
