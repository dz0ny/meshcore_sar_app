import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/messages_provider.dart';
import '../../models/map_drawing.dart';
import '../../models/contact.dart';
import '../../l10n/app_localizations.dart';

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
                    _getTitleForMode(drawingProvider.drawingMode, context),
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
                      tooltip: AppLocalizations.of(context)!.cancel,
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
                      tooltip: AppLocalizations.of(context)!.completeLine,
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
                      tooltip: AppLocalizations.of(context)!.clearAll,
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
      builder: (context) => SingleChildScrollView(
        child: Container(
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
                      AppLocalizations.of(context)!.drawingTools,
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
                title: Text(AppLocalizations.of(context)!.drawLine),
                subtitle: Text(AppLocalizations.of(context)!.drawLineDesc),
                onTap: () {
                  Navigator.pop(context);
                  drawingProvider.setDrawingMode(DrawingMode.line);
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop_square),
                title: Text(AppLocalizations.of(context)!.drawRectangle),
                subtitle: Text(AppLocalizations.of(context)!.drawRectangleDesc),
                onTap: () {
                  Navigator.pop(context);
                  drawingProvider.setDrawingMode(DrawingMode.rectangle);
                },
              ),
              const Divider(),
              // Toggle received drawings visibility
              SwitchListTile(
                secondary: Icon(
                  drawingProvider.showReceivedDrawings
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                title: Text(AppLocalizations.of(context)!.showReceivedDrawings),
                subtitle: Text(
                  drawingProvider.showReceivedDrawings
                      ? AppLocalizations.of(context)!.showingAllDrawings
                      : AppLocalizations.of(context)!.showingOnlyYourDrawings,
                ),
                value: drawingProvider.showReceivedDrawings,
                onChanged: (value) {
                  drawingProvider.toggleReceivedDrawings();
                },
              ),
              // Toggle SAR markers visibility
              SwitchListTile(
                secondary: Icon(
                  drawingProvider.showSarMarkers
                      ? Icons.pin_drop
                      : Icons.pin_drop_outlined,
                ),
                title: Text(AppLocalizations.of(context)!.showSarMarkers),
                subtitle: Text(
                  drawingProvider.showSarMarkers
                      ? AppLocalizations.of(context)!.showingSarMarkers
                      : AppLocalizations.of(context)!.hidingSarMarkers,
                ),
                value: drawingProvider.showSarMarkers,
                onChanged: (value) {
                  drawingProvider.toggleSarMarkers();
                },
              ),
              if (drawingProvider.drawings.isNotEmpty) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.shareDrawings),
                  subtitle: Text(
                    AppLocalizations.of(context)!.broadcastDrawingsToTeam(
                      drawingProvider.drawings.length,
                      drawingProvider.drawings.length > 1 ? 's' : '',
                    ),
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
                  title: Text(AppLocalizations.of(context)!.clearAllDrawings),
                  subtitle: Text(
                    AppLocalizations.of(context)!.removeAllDrawings(
                      drawingProvider.drawings.length,
                      drawingProvider.drawings.length > 1 ? 's' : '',
                    ),
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
        title: Text(AppLocalizations.of(context)!.clearAllDrawings),
        content: Text(
          AppLocalizations.of(context)!.deleteAllDrawingsConfirm(
            drawingProvider.drawings.length,
            drawingProvider.drawings.length > 1 ? 's' : '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              drawingProvider.clearAllDrawings();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.clearAll),
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
  String _getTitleForMode(DrawingMode mode, BuildContext context) {
    switch (mode) {
      case DrawingMode.line:
        return AppLocalizations.of(context)!.drawLine;
      case DrawingMode.rectangle:
        return AppLocalizations.of(context)!.drawRectangle;
      case DrawingMode.none:
        return AppLocalizations.of(context)!.drawing;
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
    final connectionProvider = Provider.of<ConnectionProvider>(
      context,
      listen: false,
    );
    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );

    debugPrint(
      '  Connection status: ${connectionProvider.deviceInfo.isConnected}',
    );

    if (!connectionProvider.deviceInfo.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deviceNotConnected),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noLocalDrawings),
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
      builder: (sheetContext) => SingleChildScrollView(
        child: Container(
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
                        AppLocalizations.of(context)!.shareDrawingsCount(
                          localDrawings.length,
                          localDrawings.length > 1 ? 's' : '',
                        ),
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
                title: Text(AppLocalizations.of(context)!.publicChannel),
                subtitle: Text(AppLocalizations.of(context)!.broadcastToAll),
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
                    subtitle: Text(
                      AppLocalizations.of(context)!.storedPermanently,
                    ),
                    onTap: () async {
                      debugPrint(
                        '📤 [DrawingToolbar] Room ${room.advName} tapped',
                      );
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

    final drawingProvider = Provider.of<DrawingProvider>(
      context,
      listen: false,
    );
    int successCount = 0;

    for (final drawing in drawings) {
      try {
        debugPrint('  Creating message for drawing ${drawing.id}...');
        // Sender name is no longer included in JSON - will be extracted from packet metadata
        final message = drawingProvider.createDrawingBroadcastMessage(drawing);
        debugPrint(
          '  Message created (${message.length} chars): ${message.substring(0, message.length > 100 ? 100 : message.length)}...',
        );
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
    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    messagesProvider.logSystemMessage(
      text:
          '📤 ${l10n.drawingsSentToPublicChannel(drawings.length, drawings.length > 1 ? 's' : '')}',
      level: 'info',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.drawingsSharedToPublicChannel(successCount, drawings.length),
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

    final drawingProvider = Provider.of<DrawingProvider>(
      context,
      listen: false,
    );
    int successCount = 0;

    for (final drawing in drawings) {
      try {
        debugPrint('  Creating message for drawing ${drawing.id}...');
        // Sender name is no longer included in JSON - will be extracted from packet metadata
        final message = drawingProvider.createDrawingBroadcastMessage(drawing);
        debugPrint(
          '  Message created (${message.length} chars): ${message.substring(0, message.length > 100 ? 100 : message.length)}...',
        );
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
    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    final l10nRoom = AppLocalizations.of(context)!;
    messagesProvider.logSystemMessage(
      text:
          '📤 ${l10nRoom.sentDrawingsToRoom(
            drawings.length,
            drawings.length > 1 ? 's' : '',
            room.advName,
          )}',
      level: 'info',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10nRoom.sharedDrawingsToRoom(
            successCount,
            drawings.length,
            drawings.length > 1 ? 's' : '',
            room.advName,
          ),
        ),
        backgroundColor: successCount == drawings.length
            ? Colors.green
            : Colors.orange,
      ),
    );
  }
}
