import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/message_destination_preferences.dart';
import '../../utils/toast_logger.dart';
import '../../l10n/app_localizations.dart';

class DirectMessageSheet extends StatefulWidget {
  final Contact contact;

  const DirectMessageSheet({super.key, required this.contact});

  @override
  State<DirectMessageSheet> createState() => _DirectMessageSheetState();
}

class _DirectMessageSheetState extends State<DirectMessageSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _characterCount = 0;
  static const int _maxCharacters = 160;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _textController.text.length;
    });
  }

  /// Insert current GPS location at cursor position
  Future<void> _insertCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ToastLogger.error(context, 'Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ToastLogger.error(context, 'Location permission permanently denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Format location text
      final locationText = '📍 Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}';

      // Check if adding location would exceed limit
      final currentText = _textController.text;
      if (currentText.length + locationText.length > _maxCharacters) {
        if (!mounted) return;
        ToastLogger.error(context, 'Adding location would exceed 160 character limit');
        return;
      }

      // Insert at cursor position or append
      final selection = _textController.selection;
      final newText = currentText.replaceRange(
        selection.start >= 0 ? selection.start : currentText.length,
        selection.end >= 0 ? selection.end : currentText.length,
        locationText,
      );

      _textController.text = newText;

      // Move cursor to end of inserted text
      final newCursorPosition = (selection.start >= 0 ? selection.start : currentText.length) + locationText.length;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPosition),
      );

      if (!mounted) return;
      ToastLogger.success(context, 'Location inserted');
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, 'Failed to get location: $e');
    }
  }

  Future<void> _sendDirectMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ToastLogger.error(context, AppLocalizations.of(context)!.notConnectedToDevice);
      return;
    }

    try {
      // Create message ID
      final messageId = '${DateTime.now().millisecondsSinceEpoch}_dm_sent';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Get current device's public key (first 6 bytes)
      final devicePublicKey = connectionProvider.deviceInfo.publicKey;
      final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

      // Create sent message object with recipient public key for retry support
      final sentMessage = Message(
        id: messageId,
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderPublicKeyPrefix,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp,
        text: text,
        receivedAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
        recipientPublicKey: widget.contact.publicKey, // Store recipient for retry
      );

      // Add to messages list with "sending" status
      // Pass contact for retry logic
      messagesProvider.addSentMessage(sentMessage, contact: widget.contact);

      // Send direct message to contact (include contact for path logging)
      final sentSuccessfully = await connectionProvider.sendTextMessage(
        contactPublicKey: widget.contact.publicKey,
        text: text,
        messageId: messageId, // Pass message ID for tracking
        contact: widget.contact,
      );

      if (!sentSuccessfully) {
        // Mark message as failed if sending failed
        messagesProvider.markMessageFailed(messageId);
      }

      // Save the recipient to preferences so messages tab filters to this contact
      final recipientType = widget.contact.type == ContactType.room
          ? MessageDestinationPreferences.destinationTypeRoom
          : MessageDestinationPreferences.destinationTypeContact;
      await MessageDestinationPreferences.setDestination(
        recipientType,
        recipientPublicKey: widget.contact.publicKeyHex,
      );

      _textController.clear();
      _focusNode.unfocus();

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ToastLogger.success(context, AppLocalizations.of(context)!.directMessageSentTo(widget.contact.displayName));
    } catch (e) {
      if (!mounted) return;
      ToastLogger.error(context, AppLocalizations.of(context)!.failedToSend(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appProvider = context.watch<AppProvider>();
    final isSimpleMode = appProvider.isSimpleMode;
    final contactLocation = widget.contact.displayLocation;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.directMessage,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.contact.displayName,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Spacer to keep title centered
              ],
            ),
          ),

          // Mini map in simple mode (scrollable content)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (isSimpleMode && contactLocation != null) ...[
                    GestureDetector(
                      onTap: () {
                        // Hide keyboard when tapping on map
                        _focusNode.unfocus();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              contactLocation.latitude,
                              contactLocation.longitude,
                            ),
                            initialZoom: 13.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.meshcore.sar',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    contactLocation.latitude,
                                    contactLocation.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: colorScheme.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location coordinates
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gps_fixed, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${contactLocation.latitude.toStringAsFixed(5)}, ${contactLocation.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLength: _maxCharacters,
                  maxLines: 3,
                  autofocus: true,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeYourMessage,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    counterText: '', // Hide default counter
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendDirectMessage(),
                ),
                // Always-visible character counter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$_characterCount / $_maxCharacters',
                        style: TextStyle(
                          fontSize: 12,
                          color: _characterCount > 155
                              ? Colors.red
                              : (_characterCount > 140
                                  ? Colors.orange
                                  : colorScheme.onSurfaceVariant),
                          fontWeight: _characterCount > 140 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Location and Send buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _insertCurrentLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(AppLocalizations.of(context)!.myLocation),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _textController.text.trim().isEmpty
                            ? null
                            : _sendDirectMessage,
                        icon: const Icon(Icons.send),
                        label: Text(AppLocalizations.of(context)!.sendDirectMessage),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                          disabledForegroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
