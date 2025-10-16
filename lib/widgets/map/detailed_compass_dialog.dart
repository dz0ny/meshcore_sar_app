import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/sar_marker.dart';
import '../../providers/map_provider.dart';
import '../common/location_display.dart';
import 'compass/compass_header.dart';
import 'compass/compass_filters.dart';
import 'compass/compass_sar_list.dart';
import 'compass/compass_contact_list.dart';
import '../../l10n/app_localizations.dart';

enum HeadingAccuracySeverity { low, medium, high }

class HeadingAccuracyInfo {
  final bool isAccurate;
  final String? warning;
  final HeadingAccuracySeverity severity;

  HeadingAccuracyInfo({
    required this.isAccurate,
    this.warning,
    this.severity = HeadingAccuracySeverity.low,
  });
}

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
  double? _compassAccuracy; // Compass accuracy in degrees
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

    // Auto-zoom if item is preselected
    if (_selectedContact != null || _selectedSarMarker != null) {
      // Use post-frame callback to ensure position is set
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoZoomForSelection();
      });
    }

    // Subscribe to compass updates
    final compassStream = FlutterCompass.events;
    if (compassStream != null) {
      _compassSubscription = compassStream.listen((event) {
        if (mounted && event.heading != null) {
          setState(() {
            _currentHeading = event.heading;
            _compassAccuracy = event.accuracy;
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

  // Check heading accuracy and return warning information
  HeadingAccuracyInfo get headingAccuracyInfo {
    // Using compass
    if (_currentHeading != null) {
      if (_compassAccuracy == null) {
        return HeadingAccuracyInfo(
          isAccurate: false,
          warning: 'Compass accuracy unknown',
          severity: HeadingAccuracySeverity.low,
        );
      } else if (_compassAccuracy! > 30) {
        return HeadingAccuracyInfo(
          isAccurate: false,
          warning: 'Low compass accuracy (±${_compassAccuracy!.round()}°). Calibrate device.',
          severity: HeadingAccuracySeverity.high,
        );
      } else if (_compassAccuracy! > 15) {
        return HeadingAccuracyInfo(
          isAccurate: true,
          warning: 'Moderate compass accuracy (±${_compassAccuracy!.round()}°)',
          severity: HeadingAccuracySeverity.medium,
        );
      }
      return HeadingAccuracyInfo(isAccurate: true);
    }

    // Using GPS heading
    if (_currentPosition?.heading != null && _currentPosition!.heading >= 0) {
      final headingAccuracy = _currentPosition!.headingAccuracy;
      if (headingAccuracy > 0) {
        if (headingAccuracy > 30) {
          return HeadingAccuracyInfo(
            isAccurate: false,
            warning: 'Low GPS heading accuracy (±${headingAccuracy.round()}°). Move faster or use compass.',
            severity: HeadingAccuracySeverity.high,
          );
        } else if (headingAccuracy > 15) {
          return HeadingAccuracyInfo(
            isAccurate: true,
            warning: 'Moderate GPS heading accuracy (±${headingAccuracy.round()}°)',
            severity: HeadingAccuracySeverity.medium,
          );
        }
        return HeadingAccuracyInfo(isAccurate: true);
      }
      // GPS heading available but no accuracy info
      return HeadingAccuracyInfo(
        isAccurate: true,
        warning: 'Using GPS heading (accuracy unknown)',
        severity: HeadingAccuracySeverity.low,
      );
    }

    // No heading available
    return HeadingAccuracyInfo(
      isAccurate: false,
      warning: 'No heading available',
      severity: HeadingAccuracySeverity.high,
    );
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

  // Calculate appropriate zoom level for selected item
  void _autoZoomForSelection() {
    if (_currentPosition == null) return;

    double? targetDistance;

    if (_selectedContact != null && _selectedContact!.displayLocation != null) {
      targetDistance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _selectedContact!.displayLocation!.latitude,
        _selectedContact!.displayLocation!.longitude,
      );
    } else if (_selectedSarMarker != null) {
      targetDistance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _selectedSarMarker!.location.latitude,
        _selectedSarMarker!.location.longitude,
      );
    }

    if (targetDistance != null) {
      // Calculate zoom level to fit target within 70% of compass radius
      // Base distance at 1x zoom is 1000m
      // We want target at 70% of radius, so: targetDistance / zoomLevel = 700m
      final targetZoom = (targetDistance / 700.0).clamp(_minZoom, _maxZoom);
      setState(() {
        _zoomLevel = targetZoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = currentHeading;
    final position = _currentPosition;
    final accuracyInfo = headingAccuracyInfo;

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
              Expanded(
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.compass,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.navigationAndContacts,
                      style: const TextStyle(
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
        // Heading accuracy warning banner
        if (accuracyInfo.warning != null)
          _buildAccuracyWarning(context, accuracyInfo),
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
                      heading: heading,
                      selectedContact: _selectedContact,
                      onContactTap: (contact) {
                        setState(() {
                          _selectedContact = contact;
                          if (contact != null) {
                            _selectedSarMarker = null;
                          }
                        });
                        _autoZoomForSelection();
                      },
                    ),
                  // SAR Markers list
                  if (_getFilteredSarMarkers().isNotEmpty)
                    CompassSarList(
                      sarMarkers: _getFilteredSarMarkers(),
                      position: position,
                      heading: heading,
                      selectedSarMarker: _selectedSarMarker,
                      onSarMarkerTap: (marker) {
                        setState(() {
                          _selectedSarMarker = marker;
                          if (marker != null) {
                            _selectedContact = null;
                          }
                        });
                        _autoZoomForSelection();
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

  Widget _buildAccuracyWarning(BuildContext context, HeadingAccuracyInfo info) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (info.severity) {
      case HeadingAccuracySeverity.high:
        backgroundColor = Colors.red.shade100;
        iconColor = Colors.red.shade700;
        icon = Icons.error_outline;
        break;
      case HeadingAccuracySeverity.medium:
        backgroundColor = Colors.orange.shade100;
        iconColor = Colors.orange.shade700;
        icon = Icons.warning_amber_outlined;
        break;
      case HeadingAccuracySeverity.low:
        backgroundColor = Colors.blue.shade100;
        iconColor = Colors.blue.shade700;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info.warning!,
              style: TextStyle(
                color: iconColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: _selectedContact != null && _selectedContact!.roleEmoji != null
                      ? Text(
                          _selectedContact!.roleEmoji!,
                          style: const TextStyle(fontSize: 24),
                        )
                      : Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (additionalInfo != null)
                        Text(
                          additionalInfo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                    ],
                  ),
                ),
                // Show path toggle button for contacts with history
                if (_selectedContact != null && _selectedContact!.advertHistory.length >= 2)
                  Consumer<MapProvider>(
                    builder: (context, mapProvider, _) {
                      final isPathVisible = mapProvider.isContactPathVisible(_selectedContact!.publicKeyHex);
                      return IconButton(
                        icon: Icon(
                          isPathVisible ? Icons.route : Icons.route_outlined,
                          size: 20,
                          color: isPathVisible ? Theme.of(context).colorScheme.primary : null,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: isPathVisible ? 'Hide path' : 'Show path (${_selectedContact!.advertHistory.length} points)',
                        onPressed: () {
                          mapProvider.toggleContactPath(_selectedContact!.publicKeyHex);
                        },
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              // Coordinates with modal
              if (targetLocation != null)
                LocationDisplay(location: targetLocation),
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
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
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
