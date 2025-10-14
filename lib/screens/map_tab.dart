import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/map_provider.dart';
import '../providers/app_provider.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';
import '../models/map_layer.dart';
import '../services/tile_cache_service.dart';
import '../services/background_location_service.dart';
import '../widgets/map_markers.dart';
import '../widgets/map_debug_info.dart';
import 'map_management_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final TileCacheService _tileCache = TileCacheService();
  bool _isInitialized = false;
  bool _isMapReady = false; // Track when map widget is actually rendered
  MapLayer _currentLayer = MapLayer.openStreetMap;
  Position? _currentPosition;
  double? _compassHeading; // Compass sensor heading
  bool _rotateMarkerWithHeading = false; // Toggle for rotation
  bool _showLegend = false;
  bool _showMapDebugInfo = false; // Toggle for debug info
  double _gpsUpdateDistance = 3.0; // meters
  bool _backgroundTrackingEnabled = false; // Toggle for background tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassStreamSubscription;
  final BackgroundLocationService _backgroundLocationService = BackgroundLocationService();

  // Saved map position (loaded from SharedPreferences)
  LatLng? _savedMapCenter;
  double? _savedMapZoom;

  // Default center point (will be updated based on markers)
  static const LatLng _defaultCenter = LatLng(46.0569, 14.5058); // Ljubljana, Slovenia
  static const double _defaultZoom = 13.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeTileCache();
    _requestLocationPermission();
    _startCompassTracking();

    // Listen to map provider for navigation requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      mapProvider.addListener(_handleMapNavigation);

      // Initialize background location service with BLE service
      final appProvider = context.read<AppProvider>();
      _backgroundLocationService.initialize(appProvider.connectionProvider.bleService);

      // Restore background tracking state
      _restoreBackgroundTracking();
    });
  }

  void _startCompassTracking() {
    final compassStream = FlutterCompass.events;
    if (compassStream == null) {
      return;
    }

    // Start listening to compass events
    _compassStreamSubscription = compassStream.listen(
      (CompassEvent event) {
        if (mounted && event.heading != null) {
          setState(() {
            _compassHeading = event.heading;
          });

          // Rotate map if rotation mode is enabled and we have compass heading
          // Only rotate if map is ready
          if (_rotateMarkerWithHeading && event.heading != null && _isMapReady) {
            try {
              // Use moveAndRotate to set absolute rotation
              final camera = _mapController.camera;
              _mapController.moveAndRotate(
                camera.center,
                camera.zoom,
                -event.heading!,
              );
            } catch (e) {
              // Map not ready yet, ignore
            }
          }
        }
      },
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // Load last map position if available
      final lastLat = prefs.getDouble('map_last_latitude');
      final lastLon = prefs.getDouble('map_last_longitude');
      final lastZoom = prefs.getDouble('map_last_zoom');

      // Load last map layer if available
      final lastLayerIndex = prefs.getInt('map_last_layer');

      setState(() {
        _showLegend = prefs.getBool('map_show_legend') ?? false;
        _rotateMarkerWithHeading = prefs.getBool('map_rotate_with_heading') ?? false;
        _showMapDebugInfo = prefs.getBool('map_show_debug_info') ?? false;
        _gpsUpdateDistance = prefs.getDouble('map_gps_update_distance') ?? 3.0;
        _backgroundTrackingEnabled = prefs.getBool('background_tracking_enabled') ?? false;

        // Store saved position for use in build
        if (lastLat != null && lastLon != null && lastZoom != null) {
          _savedMapCenter = LatLng(lastLat, lastLon);
          _savedMapZoom = lastZoom;
        }

        // Restore last used map layer
        if (lastLayerIndex != null && lastLayerIndex >= 0 && lastLayerIndex < MapLayer.allLayers.length) {
          _currentLayer = MapLayer.allLayers[lastLayerIndex];
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_show_legend', _showLegend);
    await prefs.setBool('map_rotate_with_heading', _rotateMarkerWithHeading);
    await prefs.setBool('map_show_debug_info', _showMapDebugInfo);
    await prefs.setDouble('map_gps_update_distance', _gpsUpdateDistance);
    await prefs.setBool('background_tracking_enabled', _backgroundTrackingEnabled);
    await prefs.setInt('map_last_layer', MapLayer.allLayers.indexOf(_currentLayer));
  }

  Future<void> _saveMapPosition() async {
    if (!_isMapReady) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final camera = _mapController.camera;
      await prefs.setDouble('map_last_latitude', camera.center.latitude);
      await prefs.setDouble('map_last_longitude', camera.center.longitude);
      await prefs.setDouble('map_last_zoom', camera.zoom);
    } catch (e) {
      debugPrint('Error saving map position: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    // Start listening to location updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _gpsUpdateDistance.toInt(),
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Rotate map if rotation mode is enabled and heading is available
        // Heading of -1.0 means heading is unavailable
        if (_isMapReady && _rotateMarkerWithHeading && position.heading != null && position.heading >= 0) {
          try {
            final camera = _mapController.camera;
            _mapController.moveAndRotate(
              camera.center,
              camera.zoom,
              -position.heading,
            );
          } catch (e) {
            // Map not ready yet, ignore
          }
        }
      }
    });
  }

  void _handleMapNavigation() {
    final mapProvider = context.read<MapProvider>();
    if (mapProvider.targetLocation != null && _isMapReady) {
      try {
        _mapController.move(
          mapProvider.targetLocation!,
          mapProvider.targetZoom ?? _defaultZoom,
        );
        // Clear the navigation request after handling
        mapProvider.clearNavigation();
      } catch (e) {
        // Map not ready yet, ignore
        debugPrint('Map controller not ready for navigation: $e');
      }
    }
  }

  Future<void> _initializeTileCache() async {
    try {
      await _tileCache.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Wait for the map to render, then mark it as ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Give the map widget one more frame to fully initialize
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _isMapReady = true;
                });
                debugPrint('Map is now ready for controller operations');
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing tile cache: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Continue without caching
        });
        // Still mark map as ready after a delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _isMapReady = true;
                });
                debugPrint('Map is now ready for controller operations');
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // Save map position before disposing
    _saveMapPosition();

    final mapProvider = context.read<MapProvider>();
    mapProvider.removeListener(_handleMapNavigation);
    _positionStreamSubscription?.cancel();
    _compassStreamSubscription?.cancel();
    _mapController.dispose();
    _tileCache.dispose();
    super.dispose();
  }

  // Get the current heading from compass or GPS
  double? get _currentHeading {
    // Prefer compass heading as it works when stationary
    if (_compassHeading != null) {
      return _compassHeading;
    }
    // Fall back to GPS heading when moving
    if (_currentPosition?.heading != null && _currentPosition!.heading >= 0) {
      return _currentPosition!.heading;
    }
    return null;
  }

  // Safely get map rotation, returns 0.0 if map is not ready
  double _getMapRotation() {
    if (!_isMapReady) return 0.0;
    try {
      return _mapController.camera.rotation;
    } catch (e) {
      // Map controller not ready yet
      return 0.0;
    }
  }

  LatLng _calculateCenter(List<Contact> contacts, List<SarMarker> sarMarkers) {
    final allPoints = <LatLng>[];

    for (final contact in contacts) {
      if (contact.displayLocation != null) {
        allPoints.add(contact.displayLocation!);
      }
    }

    for (final marker in sarMarkers) {
      allPoints.add(marker.location);
    }

    if (allPoints.isEmpty) return _defaultCenter;

    double lat = 0, lng = 0;
    for (final point in allPoints) {
      lat += point.latitude;
      lng += point.longitude;
    }

    return LatLng(lat / allPoints.length, lng / allPoints.length);
  }

  void _showLayerSelector(BuildContext context) {
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
                  const Icon(Icons.layers),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Map Layer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Download visible area',
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToDownload(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ...MapLayer.allLayers.map((layer) => ListTile(
                  leading: _currentLayer.type == layer.type
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked),
                  title: Text(layer.name),
                  subtitle: Text(layer.attribution),
                  onTap: () {
                    setState(() {
                      _currentLayer = layer;
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _navigateToDownload(BuildContext context) {
    if (!_isMapReady) return;

    try {
      // Get current map bounds
      final bounds = _mapController.camera.visibleBounds;
      final currentZoom = _mapController.camera.zoom.round();

      // Navigate to Map Management screen with pre-populated data
      final appProvider = context.read<AppProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapManagementScreen(
            tileCacheService: appProvider.tileCacheService,
            initialLayer: _currentLayer,
            initialBounds: bounds,
            initialZoom: currentZoom,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error accessing map camera: $e');
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 12),
                    Text(
                      'Map Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Legend toggle
              SwitchListTile(
                secondary: const Icon(Icons.info_outline),
                title: const Text('Show Legend'),
                subtitle: const Text('Display marker type counts'),
                value: _showLegend,
                onChanged: (value) {
                  setState(() {
                    _showLegend = value;
                  });
                  setModalState(() {});
                  _saveSettings();
                },
              ),
              const Divider(),
              // Compass rotation toggle
              SwitchListTile(
                secondary: const Icon(Icons.explore),
                title: const Text('Rotate Map with Heading'),
                subtitle: const Text('Map follows your direction when moving'),
                value: _rotateMarkerWithHeading,
                onChanged: (value) {
                  setState(() {
                    _rotateMarkerWithHeading = value;
                    // Reset map rotation when disabling (only if map is ready)
                    if (_isMapReady) {
                      try {
                        final camera = _mapController.camera;
                        if (!_rotateMarkerWithHeading) {
                          _mapController.moveAndRotate(camera.center, camera.zoom, 0);
                        } else if (_currentHeading != null) {
                          // Apply current heading rotation when enabling (if heading is valid)
                          _mapController.moveAndRotate(
                            camera.center,
                            camera.zoom,
                            -_currentHeading!,
                          );
                        }
                      } catch (e) {
                        // Map not ready yet, ignore
                      }
                    }
                  });
                  setModalState(() {});
                  _saveSettings();
                },
              ),
              const Divider(),
              // Map Debug Info toggle
              SwitchListTile(
                secondary: const Icon(Icons.developer_mode),
                title: const Text('Show Map Debug Info'),
                subtitle: const Text('Display zoom level and bounds'),
                value: _showMapDebugInfo,
                onChanged: (value) {
                  setState(() {
                    _showMapDebugInfo = value;
                  });
                  setModalState(() {});
                  _saveSettings();
                },
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailedCompass(BuildContext context, List<Contact> contacts, List<SarMarker> sarMarkers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _DetailedCompassDialog(
          initialPosition: _currentPosition,
          initialHeading: _currentHeading,
          contacts: contacts,
          sarMarkers: sarMarkers,
        ),
      ),
    );
  }

  void _showDetailedCompassWithContact(
    BuildContext context,
    List<Contact> contacts,
    List<SarMarker> sarMarkers,
    Contact selectedContact,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _DetailedCompassDialog(
          initialPosition: _currentPosition,
          initialHeading: _currentHeading,
          contacts: contacts,
          sarMarkers: sarMarkers,
          preSelectedContact: selectedContact,
        ),
      ),
    );
  }

  void _showDetailedCompassWithSarMarker(
    BuildContext context,
    List<Contact> contacts,
    List<SarMarker> sarMarkers,
    SarMarker selectedMarker,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _DetailedCompassDialog(
          initialPosition: _currentPosition,
          initialHeading: _currentHeading,
          contacts: contacts,
          sarMarkers: sarMarkers,
          preSelectedSarMarker: selectedMarker,
        ),
      ),
    );
  }

  void _restartLocationStream() {
    // Cancel existing subscription
    _positionStreamSubscription?.cancel();

    // Start new stream with updated distance
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _gpsUpdateDistance.toInt(),
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Rotate map if rotation mode is enabled and heading is available
        // Heading of -1.0 means heading is unavailable
        if (_isMapReady && _rotateMarkerWithHeading && position.heading != null && position.heading >= 0) {
          try {
            final camera = _mapController.camera;
            _mapController.moveAndRotate(
              camera.center,
              camera.zoom,
              -position.heading,
            );
          } catch (e) {
            // Map not ready yet, ignore
          }
        }
      }
    });

    // Update background tracking distance if active
    if (_backgroundTrackingEnabled) {
      _backgroundLocationService.updateDistanceThreshold(_gpsUpdateDistance);
    }
  }

  /// Restore background tracking state on app start
  Future<void> _restoreBackgroundTracking() async {
    if (_backgroundTrackingEnabled) {
      await _startBackgroundTracking();
    }
  }

  /// Start background location tracking
  Future<void> _startBackgroundTracking() async {
    final success = await _backgroundLocationService.startTracking(
      distanceThreshold: _gpsUpdateDistance,
    );

    if (!success) {
      if (mounted) {
        setState(() {
          _backgroundTrackingEnabled = false;
        });
        _saveSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start background tracking. Check permissions and BLE connection.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Stop background location tracking
  Future<void> _stopBackgroundTracking() async {
    await _backgroundLocationService.stopTracking();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer2<ContactsProvider, MessagesProvider>(
      builder: (context, contactsProvider, messagesProvider, child) {
        final contactsWithLocation = contactsProvider.chatContactsWithLocation;
        final sarMarkers = messagesProvider.sarMarkers;
        final center = _calculateCenter(contactsWithLocation, sarMarkers);

        return Stack(
          children: [
            // Map widget
            _isInitialized
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Use saved position if available, otherwise use calculated center
                      initialCenter: _savedMapCenter ?? center,
                      initialZoom: _savedMapZoom ?? _defaultZoom,
                      minZoom: 0, // Allow full zoom out to see world view
                      maxZoom: _currentLayer.maxZoom, // Respect current layer's maximum
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onMapEvent: (event) {
                        // Save map position when user stops panning/zooming
                        if (event is MapEventMoveEnd || event is MapEventScrollWheelZoom) {
                          _saveMapPosition();
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _currentLayer.urlTemplate,
                        tileProvider: _tileCache.getTileProvider(_currentLayer),
                        userAgentPackageName: 'com.meshcore.sar',
                        maxZoom: _currentLayer.maxZoom,
                      ),
                      MarkerLayer(
                        markers: [
                          ...MapMarkers.createTeamMemberMarkers(
                            contactsWithLocation,
                            context,
                            mapRotation: _getMapRotation(),
                            onContactTap: (contact) {
                              _showDetailedCompassWithContact(
                                context,
                                contactsProvider.chatContactsWithLocation,
                                messagesProvider.sarMarkers,
                                contact,
                              );
                            },
                          ),
                          ...MapMarkers.createSarMarkers(
                            sarMarkers,
                            context,
                            mapRotation: _getMapRotation(),
                            onSarMarkerTap: (marker) {
                              _showDetailedCompassWithSarMarker(
                                context,
                                contactsProvider.chatContactsWithLocation,
                                messagesProvider.sarMarkers,
                                marker,
                              );
                            },
                          ),
                          // User location marker
                          if (_currentPosition != null)
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              rotate: false, // Don't rotate with map
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing map...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
            // Compass widget - top right (always visible)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _showDetailedCompass(
                  context,
                  contactsProvider.chatContactsWithLocation,
                  messagesProvider.sarMarkers,
                ),
                child: _CompassWidget(
                  heading: _currentHeading ?? 0,
                  hasHeading: _currentHeading != null,
                ),
              ),
            ),
            // Map legend overlay
            if (_showLegend)
              Positioned(
                top: 80, // Position below compass (which is always visible now)
                left: 16,
                child: _MapLegend(
                  teamMemberCount: contactsWithLocation.length,
                  foundPersonCount: messagesProvider.foundPersonMarkers.length,
                  fireCount: messagesProvider.fireMarkers.length,
                  stagingAreaCount: messagesProvider.stagingAreaMarkers.length,
                  objectCount: messagesProvider.objectMarkers.length,
                ),
              ),
            // Map controls - right side
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'center_map',
                    onPressed: !_isMapReady ? null : () async {
                      // Force update GPS location and jump to it
                      try {
                        final position = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(
                            accuracy: LocationAccuracy.best,
                            distanceFilter: 0,
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _currentPosition = position;
                          });
                          _mapController.move(
                            LatLng(position.latitude, position.longitude),
                            16,
                          );
                        }
                      } catch (e) {
                        debugPrint('Error getting location: $e');
                        // Fallback to cached position or default center
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            16,
                          );
                        } else {
                          _mapController.move(center, _defaultZoom);
                        }
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'layer_selector',
                    onPressed: () => _showLayerSelector(context),
                    child: const Icon(Icons.layers),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'options_menu',
                    onPressed: () => _showOptionsMenu(context),
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
            // Map debug info - bottom left
            if (_showMapDebugInfo && _isMapReady)
              Positioned(
                bottom: 16,
                left: 16,
                child: MapDebugInfo(mapController: _mapController),
              ),
          ],
        );
      },
    );
  }
}

class _MapLegend extends StatelessWidget {
  final int teamMemberCount;
  final int foundPersonCount;
  final int fireCount;
  final int stagingAreaCount;
  final int objectCount;

  const _MapLegend({
    required this.teamMemberCount,
    required this.foundPersonCount,
    required this.fireCount,
    required this.stagingAreaCount,
    required this.objectCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              icon: Icons.person,
              color: Colors.blue,
              label: 'Team',
              count: teamMemberCount,
            ),
            _LegendItem(
              icon: Icons.person_pin,
              color: Colors.green,
              label: 'Found',
              count: foundPersonCount,
            ),
            _LegendItem(
              icon: Icons.local_fire_department,
              color: Colors.red,
              label: 'Fire',
              count: fireCount,
            ),
            _LegendItem(
              icon: Icons.home_work,
              color: Colors.orange,
              label: 'Staging',
              count: stagingAreaCount,
            ),
            _LegendItem(
              icon: Icons.inventory_2,
              color: Colors.purple,
              label: 'Object',
              count: objectCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassWidget extends StatelessWidget {
  final double heading;
  final bool hasHeading;

  const _CompassWidget({
    required this.heading,
    required this.hasHeading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Compass rose background - rotates to show true north at top
            Transform.rotate(
              angle: heading * pi / 180,
              child: CustomPaint(
                size: const Size(40, 40),
                painter: _CompassRosePainter(),
              ),
            ),
            // Fixed needle pointing up (since map rotates)
            Icon(
              Icons.navigation,
              color: hasHeading ? Colors.red : Colors.grey,
              size: 28,
            ),
            // Heading text
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasHeading ? '${heading.round()}°' : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
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

class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    canvas.drawCircle(center, radius, paint);

    // Draw cardinal direction markers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2; // Start from North (top)
      final x = center.dx + radius * 0.7 * cos(angle);
      final y = center.dy + radius * 0.7 * sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Detailed Compass Dialog
class _DetailedCompassDialog extends StatefulWidget {
  final Position? initialPosition;
  final double? initialHeading;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final Contact? preSelectedContact;
  final SarMarker? preSelectedSarMarker;

  const _DetailedCompassDialog({
    required this.initialPosition,
    required this.initialHeading,
    required this.contacts,
    required this.sarMarkers,
    this.preSelectedContact,
    this.preSelectedSarMarker,
  });

  @override
  State<_DetailedCompassDialog> createState() => _DetailedCompassDialogState();
}

class _DetailedCompassDialogState extends State<_DetailedCompassDialog> {
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.filter_list, size: 20),
              SizedBox(width: 8),
              Text('Filter Markers'),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contacts filter
              _CompactFilterItem(
                icon: Icons.person,
                color: Colors.blue,
                label: 'Contacts',
                value: _showContacts,
                onChanged: (value) {
                  setState(() {
                    _showContacts = value;
                  });
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              const Divider(height: 8),
              const SizedBox(height: 4),
              // SAR Markers section
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
                child: Text(
                  'SAR Markers',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _CompactFilterItem(
                icon: Icons.person_pin,
                color: Colors.green,
                label: 'Found Person',
                value: _showFoundPerson,
                onChanged: (value) {
                  setState(() {
                    _showFoundPerson = value;
                  });
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              _CompactFilterItem(
                icon: Icons.local_fire_department,
                color: Colors.red,
                label: 'Fire',
                value: _showFire,
                onChanged: (value) {
                  setState(() {
                    _showFire = value;
                  });
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              _CompactFilterItem(
                icon: Icons.home_work,
                color: Colors.orange,
                label: 'Staging Area',
                value: _showStagingArea,
                onChanged: (value) {
                  setState(() {
                    _showStagingArea = value;
                  });
                  setDialogState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _showContacts = true;
                  _showFoundPerson = true;
                  _showFire = true;
                  _showStagingArea = true;
                });
                setDialogState(() {});
              },
              child: const Text('Show All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
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
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter markers',
                onPressed: () => _showFilterDialog(),
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
                  // Heading and Elevation info
                  _buildInfoRow(context, heading, position),
                  const SizedBox(height: 12),
                  // Current location in multiple formats
                  if (position != null) _buildLocationFormats(context, position),
                  const SizedBox(height: 12),
                  // Large compass with zoom controls
                  GestureDetector(
                    onScaleStart: (details) {
                      _previousScale = 1.0;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        // Calculate scale delta from previous scale
                        final scaleDelta = details.scale - _previousScale;

                        // Apply sensitivity factor to make it more coarse
                        final adjustedDelta = scaleDelta * _zoomSensitivity;

                        // Apply the delta to current zoom level
                        _zoomLevel = (_zoomLevel * (1.0 + adjustedDelta)).clamp(_minZoom, _maxZoom);

                        // Update previous scale
                        _previousScale = details.scale;
                      });
                    },
                    onScaleEnd: (details) {
                      _previousScale = 1.0;
                    },
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: _DetailedCompassPainter(
                        heading: heading ?? 0,
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Selected item detail view
                  if (_selectedContact != null || _selectedSarMarker != null)
                    _buildSelectedItemDetail(context, heading, position),
                  const SizedBox(height: 12),
                  // Contacts list
                  if (_showContacts && widget.contacts.isNotEmpty) _buildContactsList(context, heading, position),
                  // SAR Markers list
                  if (_getFilteredSarMarkers().isNotEmpty) _buildSarMarkersList(context, heading, position),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, double? heading, Position? position) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoCard(
          context,
          'Heading',
          heading != null ? '${heading.round()}°' : '--',
          Icons.explore,
        ),
        _buildInfoCard(
          context,
          'Elevation',
          position?.altitude != null
              ? '${position!.altitude.round()}m'
              : '--',
          Icons.terrain,
        ),
        _buildInfoCard(
          context,
          'Accuracy',
          position?.accuracy != null
              ? '±${position!.accuracy.round()}m'
              : '--',
          Icons.gps_fixed,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLocationFormats(BuildContext context, Position position) {
    return _LocationFormatToggle(position: position);
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
      color = Colors.blue;
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

      // Show battery if available
      if (_selectedContact!.telemetry?.batteryPercentage != null) {
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

  // Convert decimal degrees to DMS (Degrees, Minutes, Seconds)
  String _formatDMS(double degrees, bool isLatitude) {
    final direction = isLatitude
        ? (degrees >= 0 ? 'N' : 'S')
        : (degrees >= 0 ? 'E' : 'W');

    final absolute = degrees.abs();
    final deg = absolute.floor();
    final minDecimal = (absolute - deg) * 60;
    final min = minDecimal.floor();
    final sec = (minDecimal - min) * 60;

    return '$deg°${min.toString().padLeft(2, '0')}\'${sec.toStringAsFixed(2).padLeft(5, '0')}"$direction';
  }

  Widget _buildContactsList(BuildContext context, double? heading, Position? position) {
    if (position == null) {
      return const Text('Location unavailable');
    }

    // Calculate bearings and distances
    final contactsWithBearing = widget.contacts.map((contact) {
      if (contact.displayLocation == null) return null;

      final bearing = _calculateBearing(
        position.latitude,
        position.longitude,
        contact.displayLocation!.latitude,
        contact.displayLocation!.longitude,
      );

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        contact.displayLocation!.latitude,
        contact.displayLocation!.longitude,
      );

      return {
        'contact': contact,
        'bearing': bearing,
        'distance': distance,
      };
    }).whereType<Map<String, dynamic>>().toList();

    // Sort by distance
    contactsWithBearing.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Nearby Contacts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...contactsWithBearing.map((item) {
          final contact = item['contact'] as Contact;
          final bearing = item['bearing'] as double;
          final distance = item['distance'] as double;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedContact == contact
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: _selectedContact == contact
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: ListTile(
              dense: true,
              leading: contact.roleEmoji != null
                  ? Text(
                      contact.roleEmoji!,
                      style: const TextStyle(fontSize: 24),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 24,
                    ),
              title: Text(contact.displayName),
              subtitle: Text(
                '${_bearingToCardinal(bearing)} • ${_formatDistance(distance)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                '${bearing.round()}°',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              onTap: () {
                setState(() {
                  if (_selectedContact == contact) {
                    // Deselect if already selected
                    _selectedContact = null;
                  } else {
                    // Select this contact and deselect SAR marker
                    _selectedContact = contact;
                    _selectedSarMarker = null;
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSarMarkersList(BuildContext context, double? heading, Position? position) {
    if (position == null) {
      return const Text('Location unavailable');
    }

    // Use filtered SAR markers
    final filteredMarkers = _getFilteredSarMarkers();

    // Calculate bearings and distances for SAR markers
    final markersWithBearing = filteredMarkers.map((marker) {
      final bearing = _calculateBearing(
        position.latitude,
        position.longitude,
        marker.location.latitude,
        marker.location.longitude,
      );

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        marker.location.latitude,
        marker.location.longitude,
      );

      return {
        'marker': marker,
        'bearing': bearing,
        'distance': distance,
      };
    }).toList();

    // Sort by distance
    markersWithBearing.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'SAR Markers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...markersWithBearing.map((item) {
          final marker = item['marker'] as SarMarker;
          final bearing = item['bearing'] as double;
          final distance = item['distance'] as double;

          // Determine color and icon based on marker type
          Color markerColor;
          IconData markerIcon;
          switch (marker.type) {
            case SarMarkerType.foundPerson:
              markerColor = Colors.green;
              markerIcon = Icons.person_pin;
              break;
            case SarMarkerType.fire:
              markerColor = Colors.red;
              markerIcon = Icons.local_fire_department;
              break;
            case SarMarkerType.stagingArea:
              markerColor = Colors.orange;
              markerIcon = Icons.home_work;
              break;
            case SarMarkerType.object:
              markerColor = Colors.purple;
              markerIcon = Icons.inventory_2;
              break;
            case SarMarkerType.unknown:
              markerColor = Colors.grey;
              markerIcon = Icons.help_outline;
              break;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedSarMarker == marker
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: _selectedSarMarker == marker
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: ListTile(
              dense: true,
              leading: Icon(
                markerIcon,
                color: markerColor,
                size: 24,
              ),
              title: Text(marker.type.displayName),
              subtitle: Text(
                '${_bearingToCardinal(bearing)} • ${_formatDistance(distance)} • ${marker.timeAgo}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                '${bearing.round()}°',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              onTap: () {
                setState(() {
                  if (_selectedSarMarker == marker) {
                    // Deselect if already selected
                    _selectedSarMarker = null;
                  } else {
                    // Select this marker and deselect contact
                    _selectedSarMarker = marker;
                    _selectedContact = null;
                  }
                });
              },
            ),
          );
        }),
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

// Detailed Compass Painter with contacts
class _DetailedCompassPainter extends StatelessWidget {
  final double heading;
  final bool hasHeading;
  final Position? currentPosition;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final double zoomLevel;

  const _DetailedCompassPainter({
    required this.heading,
    required this.hasHeading,
    required this.currentPosition,
    required this.contacts,
    required this.sarMarkers,
    this.zoomLevel = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LargeCompassPainter(
        heading: heading,
        hasHeading: hasHeading,
        currentPosition: currentPosition,
        contacts: contacts,
        sarMarkers: sarMarkers,
        zoomLevel: zoomLevel,
      ),
      child: Container(),
    );
  }
}

class _LargeCompassPainter extends CustomPainter {
  final double heading;
  final bool hasHeading;
  final Position? currentPosition;
  final List<Contact> contacts;
  final List<SarMarker> sarMarkers;
  final double zoomLevel;

  _LargeCompassPainter({
    required this.heading,
    required this.hasHeading,
    required this.currentPosition,
    required this.contacts,
    required this.sarMarkers,
    this.zoomLevel = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final circlePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw degree markers
    for (int i = 0; i < 360; i += 10) {
      final angle = i * pi / 180 - pi / 2 + heading * pi / 180;
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;

      final startRadius = isCardinal ? radius - 25 : (isMajor ? radius - 15 : radius - 10);
      final start = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );
      final end = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final markerPaint = Paint()
        ..color = isCardinal ? Colors.red : Colors.grey
        ..strokeWidth = isCardinal ? 3 : (isMajor ? 2 : 1);

      canvas.drawLine(start, end, markerPaint);
    }

    // Draw cardinal directions
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2 + heading * pi / 180;
      final x = center.dx + (radius - 35) * cos(angle);
      final y = center.dy + (radius - 35) * sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: i == 0 ? Colors.red : Colors.grey.shade700,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw contacts as dots relative to distance, scaled by zoom level
    if (currentPosition != null && contacts.isNotEmpty) {
      // Calculate distances for all contacts
      final contactsWithDistance = contacts
          .where((c) => c.displayLocation != null)
          .map((contact) {
        final bearing = _calculateBearing(
          currentPosition!.latitude,
          currentPosition!.longitude,
          contact.displayLocation!.latitude,
          contact.displayLocation!.longitude,
        );
        final distance = _calculateDistance(
          currentPosition!.latitude,
          currentPosition!.longitude,
          contact.displayLocation!.latitude,
          contact.displayLocation!.longitude,
        );
        return {'contact': contact, 'bearing': bearing, 'distance': distance};
      }).toList();

      if (contactsWithDistance.isEmpty) return;

      // Find max distance for normalization
      final maxDistance = contactsWithDistance
          .map((c) => c['distance'] as double)
          .reduce((a, b) => a > b ? a : b);

      // Base distance for zoom level 1.0 (in meters)
      // At 1x zoom, contacts within 1km appear inside the compass
      final baseDistance = 1000.0 / zoomLevel;

      for (final item in contactsWithDistance) {
        final contact = item['contact'] as Contact;
        final bearing = item['bearing'] as double;
        final distance = item['distance'] as double;

        // Adjust bearing relative to current heading
        final relativeBearing = (bearing - heading + 360) % 360;
        final angle = relativeBearing * pi / 180 - pi / 2;

        // Calculate normalized distance (0 to 1, where 1 is at the rim)
        // Apply zoom level: higher zoom = contacts appear closer
        double normalizedDistance = (distance / baseDistance).clamp(0.0, 1.0);

        // Calculate contact position radius (from center to rim based on distance)
        final contactRadius = radius * normalizedDistance * 0.85; // 0.85 to keep inside rim

        // Position of contact dot
        final dotX = center.dx + contactRadius * cos(angle);
        final dotY = center.dy + contactRadius * sin(angle);

        // Draw line from center to contact
        final linePaint = Paint()
          ..color = Colors.blue.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(
          center,
          Offset(dotX, dotY),
          linePaint,
        );

        // Draw contact dot (size varies with zoom)
        final dotSize = (6.0 * (1.0 + zoomLevel * 0.3)).clamp(4.0, 12.0);
        final dotPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);

        // Draw white border
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, borderPaint);

        // Draw distance label near the contact (only if not too crowded)
        if (zoomLevel >= 0.75) {
          final distanceText = _formatDistance(distance);
          final labelOffset = dotSize + 12;
          final labelX = center.dx + (contactRadius + labelOffset) * cos(angle);
          final labelY = center.dy + (contactRadius + labelOffset) * sin(angle);

          textPainter.text = TextSpan(
            text: distanceText,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          // Draw background for readability
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(labelX, labelY),
              width: textPainter.width + 4,
              height: textPainter.height + 2,
            ),
            const Radius.circular(3),
          );
          final bgPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(bgRect, bgPaint);

          textPainter.paint(
            canvas,
            Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
          );
        }
      }
    }

    // Draw SAR markers as colored dots relative to distance, scaled by zoom level
    if (currentPosition != null && sarMarkers.isNotEmpty) {
      // Calculate distances for all SAR markers
      final markersWithDistance = sarMarkers.map((marker) {
        final bearing = _calculateBearing(
          currentPosition!.latitude,
          currentPosition!.longitude,
          marker.location.latitude,
          marker.location.longitude,
        );
        final distance = _calculateDistance(
          currentPosition!.latitude,
          currentPosition!.longitude,
          marker.location.latitude,
          marker.location.longitude,
        );
        return {'marker': marker, 'bearing': bearing, 'distance': distance};
      }).toList();

      // Base distance for zoom level 1.0 (in meters)
      final baseDistance = 1000.0 / zoomLevel;

      for (final item in markersWithDistance) {
        final marker = item['marker'] as SarMarker;
        final bearing = item['bearing'] as double;
        final distance = item['distance'] as double;

        // Adjust bearing relative to current heading
        final relativeBearing = (bearing - heading + 360) % 360;
        final angle = relativeBearing * pi / 180 - pi / 2;

        // Calculate normalized distance (0 to 1, where 1 is at the rim)
        double normalizedDistance = (distance / baseDistance).clamp(0.0, 1.0);

        // Calculate marker position radius (from center to rim based on distance)
        final markerRadius = radius * normalizedDistance * 0.85;

        // Position of marker dot
        final dotX = center.dx + markerRadius * cos(angle);
        final dotY = center.dy + markerRadius * sin(angle);

        // Determine color based on SAR marker type
        Color markerColor;
        switch (marker.type) {
          case SarMarkerType.foundPerson:
            markerColor = Colors.green;
            break;
          case SarMarkerType.fire:
            markerColor = Colors.red;
            break;
          case SarMarkerType.stagingArea:
            markerColor = Colors.orange;
            break;
          case SarMarkerType.object:
            markerColor = Colors.purple;
            break;
          case SarMarkerType.unknown:
            markerColor = Colors.grey;
            break;
        }

        // Draw line from center to SAR marker
        final linePaint = Paint()
          ..color = markerColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(
          center,
          Offset(dotX, dotY),
          linePaint,
        );

        // Draw SAR marker dot (slightly larger than contacts)
        final dotSize = (8.0 * (1.0 + zoomLevel * 0.3)).clamp(6.0, 14.0);
        final dotPaint = Paint()
          ..color = markerColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, dotPaint);

        // Draw white border
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(Offset(dotX, dotY), dotSize, borderPaint);

        // Draw distance label near the SAR marker
        if (zoomLevel >= 0.75) {
          final distanceText = _formatDistance(distance);
          final labelOffset = dotSize + 14;
          final labelX = center.dx + (markerRadius + labelOffset) * cos(angle);
          final labelY = center.dy + (markerRadius + labelOffset) * sin(angle);

          textPainter.text = TextSpan(
            text: distanceText,
            style: TextStyle(
              color: markerColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter.layout();

          // Draw background for readability
          final bgRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(labelX, labelY),
              width: textPainter.width + 4,
              height: textPainter.height + 2,
            ),
            const Radius.circular(3),
          );
          final bgPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(bgRect, bgPaint);

          textPainter.paint(
            canvas,
            Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
          );
        }
      }
    }

    // Draw center heading indicator (fixed pointing up)
    final indicatorPaint = Paint()
      ..color = hasHeading ? Colors.red : Colors.grey
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(center.dx, center.dy - 40)
      ..lineTo(center.dx - 10, center.dy + 10)
      ..lineTo(center.dx + 10, center.dy + 10)
      ..close();

    canvas.drawPath(path, indicatorPaint);
  }

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

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Compact filter item widget
class _CompactFilterItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactFilterItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (val) => onChanged(val ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// Location format toggle widget
class _LocationFormatToggle extends StatefulWidget {
  final Position position;

  const _LocationFormatToggle({required this.position});

  @override
  State<_LocationFormatToggle> createState() => _LocationFormatToggleState();
}

class _LocationFormatToggleState extends State<_LocationFormatToggle> {
  bool _showDMS = false;

  String _formatDMS(double degrees, bool isLatitude) {
    final direction = isLatitude
        ? (degrees >= 0 ? 'N' : 'S')
        : (degrees >= 0 ? 'E' : 'W');

    final absolute = degrees.abs();
    final deg = absolute.floor();
    final minDecimal = (absolute - deg) * 60;
    final min = minDecimal.floor();
    final sec = (minDecimal - min) * 60;

    return '$deg°${min.toString().padLeft(2, '0')}\'${sec.toStringAsFixed(2).padLeft(5, '0')}"$direction';
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;

    final String displayText;

    if (_showDMS) {
      displayText = '${_formatDMS(position.latitude, true)} ${_formatDMS(position.longitude, false)}';
    } else {
      displayText = 'Lat: ${position.latitude.toStringAsFixed(5)} Lon: ${position.longitude.toStringAsFixed(5)}';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showDMS = !_showDMS;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
          ),
        ),
      ),
    );
  }
}

