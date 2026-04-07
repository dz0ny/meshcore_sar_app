import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drawing_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/messages_provider.dart';
import '../../models/map_drawing.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/toast_logger.dart';
import '../drawing_minimap_preview.dart';

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
                  // Clear measurement
                  if (drawingProvider.drawingMode == DrawingMode.measure &&
                      drawingProvider.measurementPoint1 != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => drawingProvider.clearMeasurement(),
                      tooltip: AppLocalizations.of(context)!.clearMeasurement,
                      color: Colors.orange,
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
    // Capture root context for use after modal closes
    final rootContext = context;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(sheetContext)!.drawingTools,
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: Text(AppLocalizations.of(sheetContext)!.drawLine),
                subtitle: Text(AppLocalizations.of(sheetContext)!.drawLineDesc),
                onTap: () {
                  Navigator.pop(sheetContext);
                  drawingProvider.setDrawingMode(DrawingMode.line);
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop_square),
                title: Text(AppLocalizations.of(sheetContext)!.drawRectangle),
                subtitle: Text(
                  AppLocalizations.of(sheetContext)!.drawRectangleDesc,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  drawingProvider.setDrawingMode(DrawingMode.rectangle);
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: Text(AppLocalizations.of(sheetContext)!.measureDistance),
                subtitle: Text(
                  AppLocalizations.of(sheetContext)!.measureDistanceDesc,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  drawingProvider.setDrawingMode(DrawingMode.measure);
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
                title: Text(
                  AppLocalizations.of(sheetContext)!.showReceivedDrawings,
                ),
                subtitle: Text(
                  drawingProvider.showReceivedDrawings
                      ? AppLocalizations.of(sheetContext)!.showingAllDrawings
                      : AppLocalizations.of(
                          sheetContext,
                        )!.showingOnlyYourDrawings,
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
                title: Text(AppLocalizations.of(sheetContext)!.showSarMarkers),
                subtitle: Text(
                  drawingProvider.showSarMarkers
                      ? AppLocalizations.of(sheetContext)!.showingSarMarkers
                      : AppLocalizations.of(sheetContext)!.hidingSarMarkers,
                ),
                value: drawingProvider.showSarMarkers,
                onChanged: (value) {
                  drawingProvider.toggleSarMarkers();
                },
              ),
              // Drawings list with individual actions
              if (drawingProvider.drawings.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.layers, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(
                          sheetContext,
                        )!.yourDrawingsCount(drawingProvider.drawings.length),
                        style: Theme.of(sheetContext).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                ...drawingProvider.drawings.map((drawing) {
                  final isShared = drawing.isShared;
                  final typeStr = drawing is LineDrawing
                      ? AppLocalizations.of(sheetContext)!.line
                      : AppLocalizations.of(sheetContext)!.rectangle;
                  final colorName = DrawingColors.colorToName(drawing.color);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // Minimap preview
                        DrawingMinimapPreview(drawing: drawing),
                        const SizedBox(width: 12),
                        // Drawing info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                typeStr,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: drawing.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black26,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    colorName,
                                    style: Theme.of(
                                      sheetContext,
                                    ).textTheme.labelSmall,
                                  ),
                                  if (isShared) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(sheetContext)!.shared,
                                      style: Theme.of(sheetContext)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Share button
                            if (!isShared)
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  if (rootContext.mounted) {
                                    _showShareSingleDrawingDialog(
                                      rootContext,
                                      drawingProvider,
                                      drawing,
                                    );
                                  }
                                },
                                tooltip: AppLocalizations.of(context)!.share,
                                color: Colors.blue,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                              ),
                            const SizedBox(width: 4),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _showDeleteSingleDrawingDialog(
                                  rootContext,
                                  drawingProvider,
                                  drawing,
                                );
                              },
                              tooltip: AppLocalizations.of(context)!.delete,
                              color: Colors.red,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.blue),
                  title: Text(AppLocalizations.of(sheetContext)!.shareDrawings),
                  subtitle: Text(
                    AppLocalizations.of(sheetContext)!.broadcastDrawingsToTeam(
                      drawingProvider.drawings.length,
                      drawingProvider.drawings.length > 1 ? 's' : '',
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    // Small delay to ensure first bottom sheet is fully closed
                    // before opening the second one
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (rootContext.mounted) {
                      _showShareDrawingsDialog(rootContext, drawingProvider);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text(
                    AppLocalizations.of(sheetContext)!.clearAllDrawings,
                  ),
                  subtitle: Text(
                    AppLocalizations.of(sheetContext)!.removeAllDrawings(
                      drawingProvider.drawings.length,
                      drawingProvider.drawings.length > 1 ? 's' : '',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showClearAllDialog(rootContext, drawingProvider);
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
      case DrawingMode.measure:
        return Icons.straighten;
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
      case DrawingMode.measure:
        return AppLocalizations.of(context)!.measureDistance;
      case DrawingMode.none:
        return AppLocalizations.of(context)!.drawing;
    }
  }

  /// Show share drawings dialog
  void _showShareDrawingsDialog(
    BuildContext context,
    DrawingProvider drawingProvider,
  ) {
    debugPrint('🎨 [DrawingToolbar] _showShareDrawingsDialog called');

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
      debugPrint('  ❌ Not connected - showing error toast');
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.notConnectedToDevice,
        );
      }
      return;
    }

    // Get device name for sender identification
    final senderName = connectionProvider.deviceInfo.selfName ?? 'Unknown';

    // Filter drawings - only share unshared local drawings
    final unsharedDrawings = drawingProvider.getUnsharedDrawings();

    debugPrint('  Unshared drawings count: ${unsharedDrawings.length}');
    debugPrint('  Total drawings count: ${drawingProvider.drawings.length}');

    if (unsharedDrawings.isEmpty) {
      debugPrint('  ℹ️ No unshared drawings - showing info toast');
      if (context.mounted) {
        ToastLogger.info(context, 'All drawings have already been shared');
      }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.shareDrawingsCount(
                          unsharedDrawings.length,
                          unsharedDrawings.length > 1 ? 's' : '',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Option: Send to Public Channel
              ListTile(
                leading: Icon(Icons.public, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.publicChannel),
                subtitle: Text(AppLocalizations.of(context)!.broadcastToAll),
                onTap: () async {
                  debugPrint('📤 [DrawingToolbar] Public Channel tapped');
                  // Share BEFORE popping the navigator
                  await _shareDrawingsToChannel(
                    sheetContext,
                    unsharedDrawings,
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
                    leading: const Icon(
                      Icons.meeting_room,
                      color: Colors.green,
                    ),
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
                        unsharedDrawings,
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
    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    int successCount = 0;
    int alreadyShared = 0;

    for (final drawing in drawings) {
      // Skip if already shared
      if (drawing.isShared) {
        alreadyShared++;
        continue;
      }

      try {
        debugPrint('  Creating message for drawing ${drawing.id}...');
        // Sender name is no longer included in JSON - will be extracted from packet metadata
        final message = drawingProvider.createDrawingBroadcastMessage(drawing);
        debugPrint(
          '  Message created (${message.length} chars): ${message.substring(0, message.length > 100 ? 100 : message.length)}...',
        );

        // Create message ID and timestamp
        final messageId =
            '${DateTime.now().millisecondsSinceEpoch}_channel_drawing_sent';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Get current device's public key (first 6 bytes)
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create sent message object
        final sentMessage = Message(
          id: messageId,
          messageType: MessageType.channel,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: message,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          channelIdx: 0,
          isDrawing: true,
          drawingId: drawing.id,
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        debugPrint('  Sending to channel 0...');
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: message,
          messageId: messageId,
        );
        debugPrint('  ✅ Sent successfully');

        // Mark as shared after successful send
        drawingProvider.markDrawingAsShared(drawing.id);
        successCount++;

        // Small delay between messages to avoid overwhelming the device
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to share drawing ${drawing.id}: $e');
        debugPrint('  Stack trace: $stackTrace');
      }
    }

    debugPrint(
      '  Share complete: $successCount/${drawings.length} sent, $alreadyShared already shared',
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
    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    int successCount = 0;
    int alreadyShared = 0;

    for (final drawing in drawings) {
      // Skip if already shared
      if (drawing.isShared) {
        alreadyShared++;
        continue;
      }

      try {
        debugPrint('  Creating message for drawing ${drawing.id}...');
        // Sender name is no longer included in JSON - will be extracted from packet metadata
        final message = drawingProvider.createDrawingBroadcastMessage(drawing);
        debugPrint(
          '  Message created (${message.length} chars): ${message.substring(0, message.length > 100 ? 100 : message.length)}...',
        );

        // Create message ID and timestamp
        final messageId =
            '${DateTime.now().millisecondsSinceEpoch}_contact_drawing_sent';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Get current device's public key (first 6 bytes)
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        // Create sent message object
        final sentMessage = Message(
          id: messageId,
          messageType: MessageType.contact,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: message,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          recipientPublicKey: room.publicKey,
          isDrawing: true,
          drawingId: drawing.id,
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        debugPrint('  Sending to room ${room.advName}...');
        await connectionProvider.sendTextMessage(
          contactPublicKey: room.publicKey,
          text: message,
          messageId: messageId,
          contact: room,
        );
        debugPrint('  ✅ Sent successfully');

        // Mark as shared after successful send
        drawingProvider.markDrawingAsShared(drawing.id);
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

    debugPrint(
      '  Share complete: $successCount/${drawings.length} sent, $alreadyShared already shared',
    );
  }

  /// Show share dialog for a single drawing
  void _showShareSingleDrawingDialog(
    BuildContext context,
    DrawingProvider drawingProvider,
    MapDrawing drawing,
  ) {
    debugPrint(
      '🎨 [DrawingToolbar] _showShareSingleDrawingDialog called for ${drawing.id}',
    );

    // Read providers BEFORE any async operations or dialogs
    final connectionProvider = Provider.of<ConnectionProvider>(
      context,
      listen: false,
    );
    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );

    if (!connectionProvider.deviceInfo.isConnected) {
      debugPrint('  ❌ Not connected - showing error toast');
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.notConnectedToDevice,
        );
      }
      return;
    }

    // Get device name for sender identification
    final senderName = connectionProvider.deviceInfo.selfName ?? 'Unknown';

    // Get available rooms
    final rooms = contactsProvider.rooms;
    debugPrint('  Available rooms: ${rooms.length}');

    // Capture root context for provider access after modal closes
    final rootContext = context;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(sheetContext)!.shareDrawing,
                        style: Theme.of(sheetContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Option: Send to Public Channel
              ListTile(
                leading: const Icon(Icons.public, color: Colors.blue),
                title: Text(AppLocalizations.of(sheetContext)!.publicChannel),
                subtitle: Text(
                  AppLocalizations.of(sheetContext)!.shareWithAllNearbyDevices,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _shareDrawingsToChannel(
                    rootContext,
                    [drawing],
                    connectionProvider,
                    senderName,
                  );
                },
              ),
              // Option: Send to specific room
              if (rooms.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    AppLocalizations.of(sheetContext)!.shareToRoom,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...rooms.map((room) {
                  return ListTile(
                    leading: const Icon(
                      Icons.meeting_room,
                      color: Colors.orange,
                    ),
                    title: Text(room.advName),
                    subtitle: Text(
                      AppLocalizations.of(
                        sheetContext,
                      )!.sendToPersistentStorage,
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _shareDrawingsToRoom(
                        rootContext,
                        [drawing],
                        connectionProvider,
                        senderName,
                        room,
                      );
                    },
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show delete confirmation dialog for a single drawing
  void _showDeleteSingleDrawingDialog(
    BuildContext context,
    DrawingProvider drawingProvider,
    MapDrawing drawing,
  ) {
    final typeStr = drawing is LineDrawing
        ? AppLocalizations.of(context)!.line
        : AppLocalizations.of(context)!.rectangle;
    final colorName = DrawingColors.colorToName(drawing.color);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.deleteDrawing),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(dialogContext)!.deleteDrawingConfirm),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  DrawingMinimapPreview(drawing: drawing),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: drawing.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black26,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              colorName,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              drawingProvider.removeDrawing(drawing.id);
              ToastLogger.success(
                context,
                AppLocalizations.of(context)!.drawingDeleted,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(dialogContext)!.delete),
          ),
        ],
      ),
    );
  }
}
