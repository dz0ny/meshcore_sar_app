import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/messages_provider.dart';
import '../../models/map_drawing.dart';
import '../../models/contact.dart';

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
                color: Colors.black.withValues(alpha: 0.2),
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
              const SizedBox(height: 8),
              // Color picker - more compact
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: DrawingColors.palette.map((color) {
                  final isSelected = drawingProvider.selectedColor == color;
                  return GestureDetector(
                    onTap: () => drawingProvider.setColor(color),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
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
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  // Complete line drawing
                  if (drawingProvider.drawingMode == DrawingMode.line &&
                      drawingProvider.currentLinePoints.length >= 2)
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () => drawingProvider.completeLine(),
                      tooltip: 'Complete Line',
                      color: Colors.green,
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  // Clear all drawings
                  if (drawingProvider.drawings.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: () =>
                          _showClearAllDialog(context, drawingProvider),
                      tooltip: 'Clear All',
                      color: Colors.red,
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                ],
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
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share Drawings'),
                subtitle: Text(
                  'Broadcast ${drawingProvider.drawings.length} drawings to team',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  // Small delay to ensure first bottom sheet is fully closed
                  // before opening the second one
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (context.mounted) {
                    _showShareDrawingsDialog(context, drawingProvider);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Clear All Drawings'),
                subtitle: Text(
                  'Remove all ${drawingProvider.drawings.length} drawings',
                ),
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
  void _showClearAllDialog(
    BuildContext context,
    DrawingProvider drawingProvider,
  ) {
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  /// Show share drawings dialog
  void _showShareDrawingsDialog(
    BuildContext context,
    DrawingProvider drawingProvider,
  ) {
    debugPrint('🎨 [DrawingToolbar] _showShareDrawingsDialog called');

    // Capture the root context BEFORE showing the modal
    final rootContext = context;

    // Read providers BEFORE any async operations or dialogs
    // This ensures we have the correct BuildContext
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);

    debugPrint('  Connection status: ${connectionProvider.deviceInfo.isConnected}');

    if (!connectionProvider.deviceInfo.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get device name for sender identification
    final senderName = connectionProvider.deviceInfo.selfName ?? 'Unknown';

    // Filter drawings (only share local drawings, not received ones)
    final localDrawings = drawingProvider.drawings
        .where((d) => !d.isReceived)
        .toList();

    debugPrint('  Local drawings count: ${localDrawings.length}');
    debugPrint('  Total drawings count: ${drawingProvider.drawings.length}');

    if (localDrawings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No local drawings to share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get available rooms
    final rooms = contactsProvider.rooms;
    debugPrint('  Available rooms: ${rooms.length}');

    debugPrint('  Showing modal bottom sheet...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.share),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share ${localDrawings.length} Drawing${localDrawings.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Option: Send to Public Channel
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: const Text('Public Channel'),
              subtitle: const Text('Broadcast to all nearby nodes (ephemeral)'),
              onTap: () async {
                debugPrint('📤 [DrawingToolbar] Public Channel tapped');
                // Share BEFORE popping the navigator
                await _shareDrawingsToChannel(
                  sheetContext,
                  localDrawings,
                  connectionProvider,
                  senderName,
                );
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }
              },
            ),
            // Option: Send to Room
            if (rooms.isNotEmpty) ...[
              ...rooms.map(
                (room) => ListTile(
                  leading: const Icon(Icons.meeting_room, color: Colors.green),
                  title: Text(room.advName),
                  subtitle: const Text('Stored permanently in room'),
                  onTap: () async {
                    debugPrint('📤 [DrawingToolbar] Room ${room.advName} tapped');
                    // Share BEFORE popping the navigator
                    await _shareDrawingsToRoom(
                      sheetContext,
                      localDrawings,
                      connectionProvider,
                      senderName,
                      room,
                    );
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Share drawings to public channel
  Future<void> _shareDrawingsToChannel(
    BuildContext context,
    List<MapDrawing> drawings,
    ConnectionProvider connectionProvider,
    String senderName,
  ) async {
    debugPrint('📤 [DrawingToolbar] _shareDrawingsToChannel called');
    debugPrint('  Drawings to share: ${drawings.length}');
    debugPrint('  Sender name: $senderName');
    debugPrint('  Context mounted: ${context.mounted}');

    if (!context.mounted) {
      debugPrint('❌ Context not mounted, aborting');
      return;
    }

    final drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
    int successCount = 0;

    for (final drawing in drawings) {
      try {
        debugPrint('  Creating message for drawing ${drawing.id}...');
        // Sender name is no longer included in JSON - will be extracted from packet metadata
        final message = drawingProvider.createDrawingBroadcastMessage(drawing);
        debugPrint('  Message created (${message.length} chars): ${message.substring(0, message.length > 100 ? 100 : message.length)}...');
        debugPrint('  Sending to channel 0...');
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: message,
        );
        debugPrint('  ✅ Sent successfully');
        successCount++;
        // Small delay between messages to avoid overwhelming the device
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to share drawing ${drawing.id}: $e');
        debugPrint('  Stack trace: $stackTrace');
      }
    }

    debugPrint('  Share complete: $successCount/${drawings.length} sent');
    debugPrint('  Context mounted after send: ${context.mounted}');

    if (!context.mounted) {
      debugPrint('❌ Context not mounted, cannot show snackbar');
      return;
    }

    // Add informational message to chat
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    messagesProvider.logSystemMessage(
      text: '📤 Sent ${drawings.length} map drawing${drawings.length > 1 ? 's' : ''} to Public Channel',
      level: 'info',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Shared $successCount/${drawings.length} drawings to Public Channel',
        ),
        backgroundColor: successCount == drawings.length
            ? Colors.green
            : Colors.orange,
      ),
    );
  }

  /// Share drawings to a specific room
  Future<void> _shareDrawingsToRoom(
    BuildContext context,
    List<MapDrawing> drawings,
    ConnectionProvider connectionProvider,
    String senderName,
    Contact room,
  ) async {
    debugPrint('📤 [DrawingToolbar] _shareDrawingsToRoom called');
    debugPrint('  Room: ${room.advName}');
    debugPrint('  Drawings to share: ${drawings.length}');
    debugPrint('  Sender name: $senderName');
    debugPrint('  Context mounted: ${context.mounted}');

    if (!context.mounted) {
      debugPrint('❌ Context not mounted, aborting');
      return;
    }

    final drawingProvider = Provider.of<DrawingProvider>(context, listen: false);
    int successCount = 0;

    for (final drawing in drawings) {
      try {
        debugPrint('  Creating message for drawing ${drawing.id}...');
        // Sender name is no longer included in JSON - will be extracted from packet metadata
        final message = drawingProvider.createDrawingBroadcastMessage(drawing);
        debugPrint('  Message created (${message.length} chars): ${message.substring(0, message.length > 100 ? 100 : message.length)}...');
        debugPrint('  Sending to room ${room.advName}...');
        await connectionProvider.sendTextMessage(
          contactPublicKey: room.publicKey,
          text: message,
        );
        debugPrint('  ✅ Sent successfully');
        successCount++;
        // Small delay between messages to avoid overwhelming the device
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e, stackTrace) {
        debugPrint(
          '❌ Failed to share drawing ${drawing.id} to ${room.advName}: $e',
        );
        debugPrint('  Stack trace: $stackTrace');
      }
    }

    debugPrint('  Share complete: $successCount/${drawings.length} sent');
    debugPrint('  Context mounted after send: ${context.mounted}');

    if (!context.mounted) {
      debugPrint('❌ Context not mounted, cannot show snackbar');
      return;
    }

    // Add informational message to chat
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    messagesProvider.logSystemMessage(
      text: '📤 Sent ${drawings.length} map drawing${drawings.length > 1 ? 's' : ''} to ${room.advName}',
      level: 'info',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Shared $successCount/${drawings.length} drawings to ${room.advName}',
        ),
        backgroundColor: successCount == drawings.length
            ? Colors.green
            : Colors.orange,
      ),
    );
  }
}
