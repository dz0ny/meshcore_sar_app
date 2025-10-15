import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../models/map_drawing.dart';

/// Toolbar for drawing controls on the map
class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, drawingProvider, _) {
        if (!drawingProvider.isDrawing) {
          // Show compact floating button when not in drawing mode
          return FloatingActionButton.small(
            heroTag: 'drawing_tool',
            onPressed: () => _showDrawingMenu(context, drawingProvider),
            child: const Icon(Icons.edit),
          );
        }

        // Show full toolbar when in drawing mode
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title bar with close button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForMode(drawingProvider.drawingMode),
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTitleForMode(drawingProvider.drawingMode),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => drawingProvider.exitDrawingMode(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Color picker
              Wrap(
                spacing: 8,
                children: DrawingColors.palette.map((color) {
                  final isSelected = drawingProvider.selectedColor == color;
                  return GestureDetector(
                    onTap: () => drawingProvider.setColor(color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey.shade300,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel current drawing
                  if (drawingProvider.currentLinePoints.isNotEmpty ||
                      drawingProvider.rectangleStartPoint != null)
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: () => drawingProvider.cancelCurrentDrawing(),
                      tooltip: 'Cancel',
                    ),
                  // Complete line drawing
                  if (drawingProvider.drawingMode == DrawingMode.line &&
                      drawingProvider.currentLinePoints.length >= 2)
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => drawingProvider.completeLine(),
                      tooltip: 'Complete Line',
                      color: Colors.green,
                    ),
                  // Clear all drawings
                  if (drawingProvider.drawings.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: () => _showClearAllDialog(context, drawingProvider),
                      tooltip: 'Clear All',
                      color: Colors.red,
                    ),
                ],
              ),
              // Instructions
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getInstructions(drawingProvider.drawingMode),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show drawing mode selection menu
  void _showDrawingMenu(BuildContext context, DrawingProvider drawingProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 12),
                  Text(
                    'Drawing Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Draw Line'),
              subtitle: const Text('Draw a freehand line on the map'),
              onTap: () {
                Navigator.pop(context);
                drawingProvider.setDrawingMode(DrawingMode.line);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Draw Rectangle'),
              subtitle: const Text('Draw a rectangular area on the map'),
              onTap: () {
                Navigator.pop(context);
                drawingProvider.setDrawingMode(DrawingMode.rectangle);
              },
            ),
            if (drawingProvider.drawings.isNotEmpty) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Clear All Drawings'),
                subtitle: Text('Remove all ${drawingProvider.drawings.length} drawings'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearAllDialog(context, drawingProvider);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show clear all confirmation dialog
  void _showClearAllDialog(BuildContext context, DrawingProvider drawingProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Drawings'),
        content: Text(
          'Delete all ${drawingProvider.drawings.length} drawings from the map?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              drawingProvider.clearAllDrawings();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Get icon for drawing mode
  IconData _getIconForMode(DrawingMode mode) {
    switch (mode) {
      case DrawingMode.line:
        return Icons.show_chart;
      case DrawingMode.rectangle:
        return Icons.crop_square;
      case DrawingMode.none:
        return Icons.edit;
    }
  }

  /// Get title for drawing mode
  String _getTitleForMode(DrawingMode mode) {
    switch (mode) {
      case DrawingMode.line:
        return 'Draw Line';
      case DrawingMode.rectangle:
        return 'Draw Rectangle';
      case DrawingMode.none:
        return 'Drawing';
    }
  }

  /// Get instructions for drawing mode
  String _getInstructions(DrawingMode mode) {
    switch (mode) {
      case DrawingMode.line:
        return 'Tap map to add points\nTap ✓ to finish';
      case DrawingMode.rectangle:
        return 'Tap start point, then end point';
      case DrawingMode.none:
        return '';
    }
  }
}
