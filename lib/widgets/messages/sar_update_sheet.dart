import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact.dart';
import '../../models/sar_template.dart';
import '../../services/validation_service.dart';
import '../../services/sar_template_service.dart';
import '../../l10n/app_localizations.dart';

/// SAR Update Sheet - Modal bottom sheet for creating and sending SAR markers
/// This widget is public so it can be used from both messages_tab.dart and map_tab.dart
class SarUpdateSheet extends StatefulWidget {
  final Future<void> Function(
    String emoji,
    String name,
    Position,
    Uint8List?,
    bool,
    bool sendToAllContacts,
    int colorIndex,
  )
  onSend;
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
  SarTemplate? _selectedTemplate;
  List<SarTemplate> _templates = [];
  final SarTemplateService _templateService = SarTemplateService();
  Position? _currentPosition;
  bool _loadingLocation = false;
  String? _locationError;
  Contact?
  _selectedContact; // Can be room or channel (public channel is in contacts)
  bool _sendToAllContacts = false; // New option: send to all team contacts
  final TextEditingController _notesController = TextEditingController();

  // Manual coordinates
  bool _useManualCoordinates = false;
  final TextEditingController _manualLatController = TextEditingController();
  final TextEditingController _manualLonController = TextEditingController();
  String? _latitudeError;
  String? _longitudeError;

  @override
  void initState() {
    super.initState();
    _initializeTemplates();
    // Use pre-populated position if provided, otherwise get current location
    if (widget.prePopulatedPosition != null) {
      _currentPosition = widget.prePopulatedPosition;
    } else {
      _getCurrentLocation();
    }
    _setDefaultDestination();
  }

  Future<void> _initializeTemplates() async {
    if (!_templateService.isInitialized) {
      await _templateService.initialize();
    }
    if (mounted) {
      setState(() {
        _templates = _templateService.templates;
        // Select first template by default
        if (_templates.isNotEmpty) {
          _selectedTemplate = _templates.first;
        }
      });
    }
  }

  void _setDefaultDestination() {
    // Set default destination with priority for SAR operations:
    // 1. "All Team Contacts" - broadcast to entire team (DEFAULT for SAR)
    // 2. Individual team contact - if only one contact exists
    // 3. Rooms (persistent storage)
    // 4. Public channel (fallback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactsProvider = context.read<ContactsProvider>();

      // Get all possible destinations (rooms + channels)
      final roomsAndChannels = contactsProvider.roomsAndChannels;

      // Get known team contacts (for direct messaging)
      final teamContacts = contactsProvider.contacts
          .where((c) => c.isChat)
          .toList();

      // Priority 1: Default to "All Team Contacts" if multiple team members exist
      // This is the most appropriate for SAR operations (broadcast critical info)
      if (teamContacts.length > 1) {
        if (mounted) {
          setState(() {
            _sendToAllContacts = true;
            _selectedContact = null;
          });
        }
        return;
      }

      // Priority 2: If only one team contact, use it directly
      if (teamContacts.length == 1) {
        if (mounted) {
          setState(() {
            _sendToAllContacts = false;
            _selectedContact = teamContacts.first;
          });
        }
        return;
      }

      // Priority 3: Fall back to rooms (persistent storage)
      if (roomsAndChannels.any((c) => c.isRoom)) {
        if (mounted) {
          setState(() {
            _sendToAllContacts = false;
            _selectedContact = roomsAndChannels.firstWhere((c) => c.isRoom);
          });
        }
        return;
      }

      // Priority 4: Fall back to public channel
      if (roomsAndChannels.isNotEmpty) {
        if (mounted) {
          setState(() {
            _sendToAllContacts = false;
            _selectedContact = roomsAndChannels.first;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _manualLatController.dispose();
    _manualLonController.dispose();
    super.dispose();
  }

  /// Validate manual latitude input
  void _validateLatitude(String value) {
    final validator = ValidationService();
    if (value.isEmpty) {
      setState(() {
        _latitudeError = null;
      });
      return;
    }

    final lat = double.tryParse(value.trim());
    final result = validator.validateLatitude(lat);
    setState(() {
      _latitudeError = result.isValid ? null : result.errorMessage;
    });
  }

  /// Validate manual longitude input
  void _validateLongitude(String value) {
    final validator = ValidationService();
    if (value.isEmpty) {
      setState(() {
        _longitudeError = null;
      });
      return;
    }

    final lon = double.tryParse(value.trim());
    final result = validator.validateLongitude(lon);
    setState(() {
      _longitudeError = result.isValid ? null : result.errorMessage;
    });
  }

  /// Get position from manual coordinates or GPS
  Position? _getPosition() {
    if (_useManualCoordinates) {
      // Parse manual coordinates
      final lat = double.tryParse(_manualLatController.text.trim());
      final lon = double.tryParse(_manualLonController.text.trim());

      if (lat == null || lon == null) return null;

      // Validate coordinates
      final validator = ValidationService();
      final latResult = validator.validateLatitude(lat);
      final lonResult = validator.validateLongitude(lon);

      if (!latResult.isValid || !lonResult.isValid) return null;

      // Create a Position object with manual coordinates
      return Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 0.0, // Manual coordinates have perfect accuracy
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } else {
      return _currentPosition;
    }
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
    // Get keyboard height to adjust padding
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 100),
      child: Container(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                          AppLocalizations.of(context)!.sendSarMarker,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.quickLocationMarker,
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  // Add bottom padding for button area (button + padding + safe area)
                  // Button height ~48px + container padding 32px + safe area
                  bottom: 80 + bottomSafeArea,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Marker type selection
                    Text(
                      AppLocalizations.of(context)!.markerType,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._templates.map((template) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TemplateChip(
                          template: template,
                          isSelected: _selectedTemplate?.id == template.id,
                          onTap: () =>
                              setState(() => _selectedTemplate = template),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Destination selection (compact dropdown with rooms, channels, and all contacts)
                    Text(
                      AppLocalizations.of(context)!.sendTo,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<ContactsProvider>(
                      builder: (context, contactsProvider, child) {
                        // Get individual team contacts (chat type)
                        final teamContacts = contactsProvider.chatContacts;

                        // Get rooms and channels
                        final roomsAndChannels = contactsProvider.roomsAndChannels;

                        // Build destinations list with priority:
                        // 1. Team contacts first (most reliable for SAR)
                        // 2. Rooms second (persistent storage)
                        // 3. Channels last (ephemeral, fallback)
                        final destinations = <Contact>[
                          ...teamContacts,
                          ...roomsAndChannels.where((c) => c.isRoom),
                          ...roomsAndChannels.where((c) => c.isChannel),
                        ];

                        final chatContactsCount = teamContacts.length;

                        if (destinations.isEmpty && chatContactsCount == 0) {
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
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noDestinationsAvailable,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sendToAllContacts ? 'all_contacts' : _selectedContact?.publicKeyHex,
                              hint: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_drop_down_circle,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.selectDestination,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              dropdownColor:
                                  colorScheme.surfaceContainerHighest,
                              isExpanded: true,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: colorScheme.onSurface,
                              ),
                              items: [
                                // Add "All Team Contacts" option if there are any chat contacts
                                if (chatContactsCount > 0)
                                  DropdownMenuItem<String>(
                                    value: 'all_contacts',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.group,
                                          size: 18,
                                          color: colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(context)!.allTeamContacts,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Add all destinations (team contacts, rooms, channels)
                                ...destinations.map((contact) {
                                  // Choose icon based on contact type
                                  IconData iconData;
                                  if (contact.isChat) {
                                    iconData = Icons.person; // Team member
                                  } else if (contact.isRoom) {
                                    iconData = Icons.storage; // Room (persistent)
                                  } else {
                                    iconData = Icons.public; // Channel (ephemeral)
                                  }

                                  return DropdownMenuItem<String>(
                                    value: contact.publicKeyHex,
                                    child: Row(
                                      children: [
                                        Icon(
                                          iconData,
                                          size: 18,
                                          color: colorScheme.onSurface,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            contact.getLocalizedDisplayName(
                                              context,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  if (value == 'all_contacts') {
                                    _sendToAllContacts = true;
                                    _selectedContact = null;
                                  } else {
                                    _sendToAllContacts = false;
                                    _selectedContact = destinations.firstWhere(
                                      (c) => c.publicKeyHex == value,
                                    );
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Compact info banner
                    Consumer<ContactsProvider>(
                      builder: (context, contactsProvider, child) {
                        if (_sendToAllContacts) {
                          final chatContactsCount = contactsProvider.chatContacts.length;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.directMessagesInfo(chatContactsCount),
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (_selectedContact != null) {
                          return Container(
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
                                        ? AppLocalizations.of(
                                            context,
                                          )!.ephemeralBroadcastInfo
                                        : AppLocalizations.of(
                                            context,
                                          )!.persistentRoomInfo,
                                    style: TextStyle(
                                      color: _selectedContact!.isChannel
                                          ? Colors.orange.shade900
                                          : Colors.blue.shade900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 24),

                    // Location display
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.location,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!widget.allowLocationUpdate) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.fromMap,
                              style: const TextStyle(
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
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              AppLocalizations.of(context)!.gettingLocation,
                              style: TextStyle(color: colorScheme.onSurface),
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
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.locationError,
                                    style: const TextStyle(
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
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.red,
                              ),
                              onPressed: _getCurrentLocation,
                              tooltip: AppLocalizations.of(context)!.retry,
                            ),
                          ],
                        ),
                      )
                    else if (_currentPosition != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
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
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                // Only show refresh button if location updates are allowed
                                if (widget.allowLocationUpdate)
                                  IconButton(
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 20,
                                      color: colorScheme.onSurface,
                                    ),
                                    onPressed: _getCurrentLocation,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: AppLocalizations.of(
                                      context,
                                    )!.refreshLocation,
                                  ),
                              ],
                            ),
                            ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.accuracyMeters(
                                      _currentPosition!.accuracy.round(),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Manual coordinates toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_location_alt,
                            size: 20,
                            color: colorScheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.manualCoordinates,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.enterCoordinatesManually,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _useManualCoordinates,
                            onChanged: (value) {
                              setState(() {
                                _useManualCoordinates = value;
                                // Clear errors when toggling
                                _latitudeError = null;
                                _longitudeError = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Manual coordinate input fields
                    if (_useManualCoordinates) ...[
                      const SizedBox(height: 16),
                      // Latitude input
                      TextField(
                        controller: _manualLatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.latitudeLabel,
                          hintText: '46.0569',
                          errorText: _latitudeError,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: _validateLatitude,
                      ),
                      const SizedBox(height: 12),
                      // Longitude input
                      TextField(
                        controller: _manualLonController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.longitudeLabel,
                          hintText: '14.5058',
                          errorText: _longitudeError,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: _validateLongitude,
                      ),
                      const SizedBox(height: 8),
                      // Example hint
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.exampleCoordinates,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Optional notes
                    Text(
                      AppLocalizations.of(context)!.notesOptional,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 100,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.addAdditionalInformation,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
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
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (!_sendToAllContacts && _selectedContact == null) ||
                            _selectedTemplate == null
                        ? null
                        : () async {
                            final validator = ValidationService();
                            final notes = _notesController.text.trim();

                            // Validate notes length if provided
                            if (notes.isNotEmpty) {
                              final notesResult = validator.validateName(
                                notes,
                                maxLength: 100,
                              );
                              if (!notesResult.isValid) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(notesResult.errorMessage!),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            // Get position (from manual input or GPS)
                            final position = _getPosition();
                            if (position == null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _useManualCoordinates
                                          ? 'Please enter valid coordinates'
                                          : 'Location not available',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            // Validate coordinates
                            final coordResult = validator.validateCoordinates(
                              position.latitude,
                              position.longitude,
                            );
                            if (!coordResult.isValid) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(coordResult.errorMessage!),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            // Validate location accuracy (warn if >50m) - only for GPS
                            if (!_useManualCoordinates && position.accuracy > 50.0) {
                              final shouldContinue = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.lowLocationAccuracy,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.lowAccuracyWarning(
                                      position.accuracy.round(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        AppLocalizations.of(context)!.continue_,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldContinue != true) return;
                            }

                            // Combine template name with optional notes
                            String displayText;
                            if (notes.isNotEmpty) {
                              // Include both template name and custom notes
                              displayText =
                                  '${_selectedTemplate!.name} - $notes';
                            } else {
                              // Just the template name
                              displayText = _selectedTemplate!.name;
                            }

                            // Send SAR marker with emoji, display text, and color index
                            await widget.onSend(
                              _selectedTemplate!.emoji,
                              displayText,
                              position,
                              _sendToAllContacts
                                  ? null
                                  : (_selectedContact!.isChannel
                                      ? null
                                      : _selectedContact!.publicKey),
                              _sendToAllContacts
                                  ? false
                                  : _selectedContact!.isChannel,
                              _sendToAllContacts,
                              _selectedTemplate!.getColorIndex(), // Include color index
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
                    label: Text(
                      AppLocalizations.of(context)!.sendSarMarker,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Template Chip widget - Displays a selectable SAR template
class TemplateChip extends StatelessWidget {
  final SarTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const TemplateChip({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = template.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: isSelected
              ? Border.all(color: color, width: 2)
              : Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.getLocalizedName(context),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : colorScheme.onSurface,
                    ),
                  ),
                  if (template.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
