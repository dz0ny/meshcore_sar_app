import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Overlay widget that displays controls for download area selection.
/// The actual polygon should be rendered inside FlutterMap's children.
class DownloadAreaOverlay extends StatelessWidget {
  final LatLngBounds bounds;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DownloadAreaOverlay({
    super.key,
    required this.bounds,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Control buttons at the top
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Download Area Selection',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The blue rectangle shows the area to be downloaded. '
                    'To change the area, tap Cancel and select download again.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Area info at the bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Area Bounds',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'N: ${bounds.north.toStringAsFixed(4)}° '
                    'S: ${bounds.south.toStringAsFixed(4)}°',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'E: ${bounds.east.toStringAsFixed(4)}° '
                    'W: ${bounds.west.toStringAsFixed(4)}°',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
