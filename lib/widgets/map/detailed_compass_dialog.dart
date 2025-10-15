import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import '../../models/contact.dart';
import '../../models/sar_marker.dart';
import 'compass/compass_header.dart';
import 'compass/compass_filters.dart';
import 'compass/compass_sar_list.dart';
import 'compass/compass_contact_list.dart';

class DetailedCompassDialog extends StatefulWidget {
  final Position? initialPosition;
  final double? initialHeading;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final Contact? preSelectedContact;
  final SarMarker? preSelectedSarMarker;

  const DetailedCompassDialog({
    super.key,
    required this.initialPosition,
    required this.initialHeading,
    required this.contacts,
    required this.sarMarkers,
    this.preSelectedContact,
    this.preSelectedSarMarker,
  });

  @override
  State<DetailedCompassDialog> createState() => _DetailedCompassDialogState();
}

class _DetailedCompassDialogState extends State<DetailedCompassDialog> {
  double? _currentHeading;
  Position? _currentPosition;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;
  double _zoomLevel = 1.0; // 1.0 = default, 0.5 = zoomed out 2x, 2.0 = zoomed in 2x
  double _previousScale = 1.0; // Track previous scale for smoother zooming
  static const double _minZoom = 0.25;
  static const double _maxZoom = 4.0;
  static const double _zoomSensitivity = 0.5; // Lower = less sensitive (0.5 = half speed)

  // Visibility toggles
  bool _showContacts = true;
  bool _showFoundPerson = true;
  bool _showFire = true;
  bool _showStagingArea = true;

  // Selected item for isolation
  Contact? _selectedContact;
  SarMarker? _selectedSarMarker;

  @override
  void initState() {
    super.initState();
    _currentHeading = widget.initialHeading;
    _currentPosition = widget.initialPosition;
    _selectedContact = widget.preSelectedContact;
    _selectedSarMarker = widget.preSelectedSarMarker;

    // Subscribe to compass updates
    final compassStream = FlutterCompass.events;
    if (compassStream != null) {
      _compassSubscription = compassStream.listen((event) {
        if (mounted && event.heading != null) {
          setState(() {
            _currentHeading = event.heading;
          });
        }
      });
    }

    // Subscribe to position updates
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  // Get current heading (prefer compass over GPS)
  double? get currentHeading {
    if (_currentHeading != null) return _currentHeading;
    if (_currentPosition?.heading != null && _currentPosition!.heading >= 0) {
      return _currentPosition!.heading;
    }
    return null;
  }

  // Filter SAR markers based on visibility settings
  List<SarMarker> _getFilteredSarMarkers() {
    return widget.sarMarkers.where((marker) {
      switch (marker.type) {
        case SarMarkerType.foundPerson:
          return _showFoundPerson;
        case SarMarkerType.fire:
          return _showFire;
        case SarMarkerType.stagingArea:
          return _showStagingArea;
        case SarMarkerType.object:
          return true; // Always show object markers (add filter if needed)
        case SarMarkerType.unknown:
          return true; // Always show unknown markers
      }
    }).toList();
  }

  void _handleZoomUpdate(double scale) {
    setState(() {
      // Calculate scale delta from previous scale
      final scaleDelta = scale - _previousScale;

      // Apply sensitivity factor to make it more coarse
      final adjustedDelta = scaleDelta * _zoomSensitivity;

      // Apply the delta to current zoom level
      _zoomLevel = (_zoomLevel * (1.0 + adjustedDelta)).clamp(_minZoom, _maxZoom);

      // Update previous scale
      _previousScale = scale;
    });
  }

  void _handleScaleStart() {
    _previousScale = 1.0;
  }

  void _handleScaleEnd() {
    _previousScale = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final heading = currentHeading;
    final position = _currentPosition;
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Column(
                  children: [
                    Text(
                      'Compass',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Navigation & Contacts',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              CompassFilters(
                showContacts: _showContacts,
                showFoundPerson: _showFoundPerson,
                showFire: _showFire,
                showStagingArea: _showStagingArea,
                onShowContactsChanged: (value) {
                  setState(() {
                    _showContacts = value;
                  });
                },
                onShowFoundPersonChanged: (value) {
                  setState(() {
                    _showFoundPerson = value;
                  });
                },
                onShowFireChanged: (value) {
                  setState(() {
                    _showFire = value;
                  });
                },
                onShowStagingAreaChanged: (value) {
                  setState(() {
                    _showStagingArea = value;
                  });
                },
                onShowAll: () {
                  setState(() {
                    _showContacts = true;
                    _showFoundPerson = true;
                    _showFire = true;
                    _showStagingArea = true;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Compass header with info and location formats
                  CompassHeader(
                    heading: heading,
                    position: position,
                    hasHeading: heading != null,
                    currentPosition: position,
                    contacts: _selectedContact != null
                        ? [_selectedContact!]
                        : (_selectedSarMarker != null
                            ? []
                            : (_showContacts ? widget.contacts : [])),
                    sarMarkers: _selectedSarMarker != null
                        ? [_selectedSarMarker!]
                        : (_selectedContact != null
                            ? []
                            : _getFilteredSarMarkers()),
                    zoomLevel: _zoomLevel,
                    previousScale: _previousScale,
                    onZoomUpdate: _handleZoomUpdate,
                    onScaleStart: _handleScaleStart,
                    onScaleEnd: _handleScaleEnd,
                  ),
                  const SizedBox(height: 12),
                  // Selected item detail view
                  if (_selectedContact != null || _selectedSarMarker != null)
                    _buildSelectedItemDetail(context, heading, position),
                  const SizedBox(height: 12),
                  // Contacts list
                  if (_showContacts && widget.contacts.isNotEmpty)
                    CompassContactList(
                      contacts: widget.contacts,
                      position: position,
                      selectedContact: _selectedContact,
                      onContactTap: (contact) {
                        setState(() {
                          _selectedContact = contact;
                          if (contact != null) {
                            _selectedSarMarker = null;
                          }
                        });
                      },
                    ),
                  // SAR Markers list
                  if (_getFilteredSarMarkers().isNotEmpty)
                    CompassSarList(
                      sarMarkers: _getFilteredSarMarkers(),
                      position: position,
                      selectedSarMarker: _selectedSarMarker,
                      onSarMarkerTap: (marker) {
                        setState(() {
                          _selectedSarMarker = marker;
                          if (marker != null) {
                            _selectedContact = null;
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemDetail(BuildContext context, double? heading, Position? position) {
    if (position == null) {
      return const SizedBox.shrink();
    }

    String title;
    IconData icon;
    Color color;
    double? bearing;
    double? distance;
    LatLng? targetLocation;
    String? additionalInfo;

    if (_selectedContact != null) {
      title = _selectedContact!.displayName;
      icon = Icons.person;
      color = Theme.of(context).colorScheme.primary;
      targetLocation = _selectedContact!.displayLocation;

      if (targetLocation != null) {
        bearing = _calculateBearing(
          position.latitude,
          position.longitude,
          targetLocation.latitude,
          targetLocation.longitude,
        );
        distance = _calculateDistance(
          position.latitude,
          position.longitude,
          targetLocation.latitude,
          targetLocation.longitude,
        );
      }

      // Show voltage/battery if available
      if (_selectedContact!.telemetry?.batteryMilliVolts != null) {
        final volts = (_selectedContact!.telemetry!.batteryMilliVolts! / 1000).toStringAsFixed(3);
        final percent = _selectedContact!.telemetry!.batteryPercentage != null
            ? ' (${_selectedContact!.telemetry!.batteryPercentage!.round()}%)'
            : '';
        additionalInfo = 'Voltage: ${volts}V$percent';
      } else if (_selectedContact!.telemetry?.batteryPercentage != null) {
        additionalInfo = 'Battery: ${_selectedContact!.telemetry!.batteryPercentage!.round()}%';
      }
    } else if (_selectedSarMarker != null) {
      title = _selectedSarMarker!.type.displayName;
      targetLocation = _selectedSarMarker!.location;
      additionalInfo = _selectedSarMarker!.timeAgo;

      switch (_selectedSarMarker!.type) {
        case SarMarkerType.foundPerson:
          icon = Icons.person_pin;
          color = Colors.green;
          break;
        case SarMarkerType.fire:
          icon = Icons.local_fire_department;
          color = Colors.red;
          break;
        case SarMarkerType.stagingArea:
          icon = Icons.home_work;
          color = Colors.orange;
          break;
        case SarMarkerType.object:
          icon = Icons.inventory_2;
          color = Colors.purple;
          break;
        case SarMarkerType.unknown:
          icon = Icons.help_outline;
          color = Colors.grey;
          break;
      }

      bearing = _calculateBearing(
        position.latitude,
        position.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );
      distance = _calculateDistance(
        position.latitude,
        position.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: _selectedContact != null && _selectedContact!.roleEmoji != null
                      ? Text(
                          _selectedContact!.roleEmoji!,
                          style: const TextStyle(fontSize: 32),
                        )
                      : Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (additionalInfo != null)
                        Text(
                          additionalInfo,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedContact = null;
                      _selectedSarMarker = null;
                    });
                  },
                ),
              ],
            ),
            if (bearing != null && distance != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Distance and bearing info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLargeInfoCard(
                    context,
                    'Distance',
                    _formatDistance(distance),
                    Icons.straighten,
                    color,
                  ),
                  _buildLargeInfoCard(
                    context,
                    'Bearing',
                    '${bearing.round()}°',
                    Icons.navigation,
                    color,
                  ),
                  _buildLargeInfoCard(
                    context,
                    'Direction',
                    _bearingToCardinal(bearing),
                    Icons.explore,
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Coordinates
              if (targetLocation != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${targetLocation.latitude.toStringAsFixed(5)}, ${targetLocation.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLargeInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Calculate bearing between two points (in degrees)
  double _calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  // Calculate distance between two points (in meters)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String _bearingToCardinal(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}
