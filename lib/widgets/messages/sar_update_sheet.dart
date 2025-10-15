import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';
import '../../models/sar_marker.dart';

/// SAR Update Sheet - Modal bottom sheet for creating and sending SAR markers
/// This widget is public so it can be used from both messages_tab.dart and map_tab.dart
class SarUpdateSheet extends StatefulWidget {
  final Future<void> Function(SarMarkerType, Position, String?, Uint8List?, bool) onSend;
  final Position? prePopulatedPosition;
  final bool allowLocationUpdate;

  const SarUpdateSheet({
    super.key,
    required this.onSend,
    this.prePopulatedPosition,
    this.allowLocationUpdate = true,
  });

  @override
  State<SarUpdateSheet> createState() => _SarUpdateSheetState();
}

class _SarUpdateSheetState extends State<SarUpdateSheet> {
  SarMarkerType _selectedType = SarMarkerType.foundPerson;
  Position? _currentPosition;
  bool _loadingLocation = false;
  String? _locationError;
  Contact? _selectedContact; // Can be room or channel (public channel is in contacts)
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use pre-populated position if provided, otherwise get current location
    if (widget.prePopulatedPosition != null) {
      _currentPosition = widget.prePopulatedPosition;
    } else {
      _getCurrentLocation();
    }
    _setDefaultDestination();
  }

  void _setDefaultDestination() {
    // Set default to first room, or first channel if no rooms exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactsProvider = context.read<ContactsProvider>();
      final destinations = contactsProvider.roomsAndChannels;

      if (destinations.isNotEmpty) {
        // Prefer rooms over channels
        final room = destinations.firstWhere(
          (c) => c.isRoom,
          orElse: () => destinations.first,
        );

        if (mounted) {
          setState(() {
            _selectedContact = room;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _loadingLocation = false;
        });
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _loadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get location: $e';
          _loadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Send SAR Marker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Quick location marker',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marker type selection
                  const Text(
                    'Marker Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MarkerTypeChip(
                    type: SarMarkerType.foundPerson,
                    isSelected: _selectedType == SarMarkerType.foundPerson,
                    onTap: () => setState(() => _selectedType = SarMarkerType.foundPerson),
                  ),
                  const SizedBox(height: 8),
                  MarkerTypeChip(
                    type: SarMarkerType.fire,
                    isSelected: _selectedType == SarMarkerType.fire,
                    onTap: () => setState(() => _selectedType = SarMarkerType.fire),
                  ),
                  const SizedBox(height: 8),
                  MarkerTypeChip(
                    type: SarMarkerType.stagingArea,
                    isSelected: _selectedType == SarMarkerType.stagingArea,
                    onTap: () => setState(() => _selectedType = SarMarkerType.stagingArea),
                  ),
                  const SizedBox(height: 8),
                  MarkerTypeChip(
                    type: SarMarkerType.object,
                    isSelected: _selectedType == SarMarkerType.object,
                    onTap: () => setState(() => _selectedType = SarMarkerType.object),
                  ),
                  const SizedBox(height: 24),

                  // Destination selection (compact dropdown with rooms and channel)
                  const Text(
                    'Send To',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<ContactsProvider>(
                    builder: (context, contactsProvider, child) {
                      // Get all valid destinations (rooms + channels)
                      final destinations = contactsProvider.roomsAndChannels;

                      if (destinations.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No destinations available.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Contact>(
                            value: _selectedContact,
                            hint: const Row(
                              children: [
                                Icon(Icons.arrow_drop_down_circle, size: 18, color: Colors.grey),
                                SizedBox(width: 12),
                                Text(
                                  'Select destination...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            dropdownColor: const Color(0xFF2D2D2D),
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            items: destinations.map((contact) {
                              return DropdownMenuItem<Contact>(
                                value: contact,
                                child: Row(
                                  children: [
                                    Icon(
                                      contact.isChannel ? Icons.public : Icons.storage,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        contact.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedContact = value);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Compact info banner
                  if (_selectedContact != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedContact!.isChannel
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedContact!.isChannel
                              ? Colors.orange.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _selectedContact!.isChannel
                                ? Icons.warning_amber
                                : Icons.check_circle_outline,
                            color: _selectedContact!.isChannel
                                ? Colors.orange
                                : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedContact!.isChannel
                                  ? 'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.'
                                  : 'Persistent: Stored immutably in room. Synced automatically and preserved offline.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Location display
                  Row(
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!widget.allowLocationUpdate) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'From Map',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingLocation)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Getting location...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  else if (_locationError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location Error',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _locationError!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            onPressed: _getCurrentLocation,
                            tooltip: 'Retry',
                          ),
                        ],
                      ),
                    )
                  else if (_currentPosition != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Only show refresh button if location updates are allowed
                              if (widget.allowLocationUpdate)
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
                                  onPressed: _getCurrentLocation,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Refresh location',
                                ),
                            ],
                          ),
                          if (_currentPosition!.accuracy != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.my_location,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Accuracy: ±${_currentPosition!.accuracy!.round()}m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Optional notes
                  const Text(
                    'Notes (optional)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 100,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add additional information...',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF2D2D2D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Bottom action button
          Container(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _currentPosition == null || _selectedContact == null
                      ? null
                      : () async {
                          await widget.onSend(
                            _selectedType,
                            _currentPosition!,
                            _notesController.text.trim().isEmpty
                                ? null
                                : _notesController.text.trim(),
                            _selectedContact!.isChannel
                                ? null
                                : _selectedContact!.publicKey,
                            _selectedContact!.isChannel,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send, size: 20),
                  label: const Text(
                    'Send SAR Marker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marker Type Chip widget - Displays a selectable SAR marker type
class MarkerTypeChip extends StatelessWidget {
  final SarMarkerType type;
  final bool isSelected;
  final VoidCallback onTap;

  const MarkerTypeChip({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  Color _getMarkerColor() {
    switch (type) {
      case SarMarkerType.foundPerson:
        return Colors.green;
      case SarMarkerType.fire:
        return Colors.red;
      case SarMarkerType.stagingArea:
        return Colors.orange;
      case SarMarkerType.object:
        return Colors.purple;
      case SarMarkerType.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMarkerColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.white,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
