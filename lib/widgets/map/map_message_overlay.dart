import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../l10n/app_localizations.dart';

/// Message overlay widget for displaying recent messages on the map
/// Only shown in fullscreen mode on large screens (>= 800px width)
class MapMessageOverlay extends StatefulWidget {
  final List<Message> messages;
  final VoidCallback? onNavigateToMessages;
  final Function(String messageId)? onMessageTap;

  const MapMessageOverlay({
    super.key,
    required this.messages,
    this.onNavigateToMessages,
    this.onMessageTap,
  });

  @override
  State<MapMessageOverlay> createState() => _MapMessageOverlayState();
}

class _MapMessageOverlayState extends State<MapMessageOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void didUpdateWidget(MapMessageOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: true);
      });
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getMessageAccentColor(Message message) {
    if (message.isSarMarker) {
      return Colors.red;
    } else if (message.isChannelMessage) {
      return Colors.green;
    } else if (message.isContactMessage) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  IconData _getMessageIcon(Message message) {
    if (message.isSarMarker) {
      return Icons.emergency;
    } else if (message.isChannelMessage) {
      return Icons.campaign;
    } else if (message.isContactMessage) {
      return Icons.person;
    }
    return Icons.message;
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.message,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.recentMessages,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${widget.messages.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Message list
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: widget.messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                final accentColor = _getMessageAccentColor(message);
                final icon = _getMessageIcon(message);

                return GestureDetector(
                  onTap: () {
                    widget.onMessageTap?.call(message.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sender and time
                        Row(
                          children: [
                            Icon(
                              icon,
                              color: accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                message.displaySender,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              message.timeAgo,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Message preview
                        Text(
                          _truncateText(message.text, 60),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // SAR marker indicator
                        if (message.isSarMarker)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade300,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  message.sarMarkerType?.displayName ?? 'SAR Marker',
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
