import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Map Debug Info Widget
/// Displays current zoom level and visible bounds in bottom-left corner
class MapDebugInfo extends StatefulWidget {
  final MapController mapController;

  const MapDebugInfo({super.key, required this.mapController});

  @override
  State<MapDebugInfo> createState() => _MapDebugInfoState();
}

class _MapDebugInfoState extends State<MapDebugInfo> {
  StreamSubscription<MapEvent>? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to map events and trigger rebuild
    _mapEventSubscription = widget.mapController.mapEventStream.listen((event) {
      if (mounted) {
        setState(() {
          // Rebuild when map moves, zooms, or rotates
        });
      }
    });
  }

  @override
  void dispose() {
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final camera = widget.mapController.camera;
      final bounds = camera.visibleBounds;

      return Card(
        color: Colors.black.withValues(alpha: 0.7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Z: ${camera.zoom.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'N: ${bounds.north.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'S: ${bounds.south.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'E: ${bounds.east.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'W: ${bounds.west.toStringAsFixed(5)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Map not ready yet
      return const SizedBox.shrink();
    }
  }
}
