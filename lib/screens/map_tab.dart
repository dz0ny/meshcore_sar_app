import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:http/http.dart' as http;
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/map_provider.dart';
import '../providers/drawing_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';
import '../models/map_layer.dart';
import '../models/message.dart';
import '../services/tile_cache_service.dart';
import '../services/background_location_service.dart';
import '../services/location_tracking_service.dart';
import '../services/map_marker_service.dart';
import '../services/mbtiles_service.dart';
import '../widgets/map_debug_info.dart';
import '../widgets/map/map_legend.dart';
import '../widgets/map/compass_widget.dart';
import '../widgets/map/detailed_compass_dialog.dart';
import '../widgets/map/drawing_layer.dart';
import '../widgets/map/drawing_toolbar.dart';
import '../widgets/map/location_trail_layer.dart';
import '../widgets/map/trail_controls.dart';
import '../widgets/messages/sar_update_sheet.dart';
import '../l10n/app_localizations.dart';
import 'map_management_screen.dart';

class MapTab extends StatefulWidget {
  final Function(bool)? onFullscreenChanged;

  const MapTab({
    super.key,
    this.onFullscreenChanged,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final TileCacheService _tileCache = TileCacheService();
  // DO NOT create a new LocationTrackingService instance here
  // Use the singleton from AppProvider instead via _locationService getter
  final MapMarkerService _markerService = MapMarkerService();
  bool _isInitialized = false;
  bool _isMapReady = false; // Track when map widget is actually rendered
  MapLayer _currentLayer = MapLayer.openStreetMap;
  double? _compassHeading; // Compass sensor heading
  bool _rotateMarkerWithHeading = false; // Toggle for rotation
  bool _showLegend = false;
  bool _showMapDebugInfo = false; // Toggle for debug info
  bool _isFullscreen = false; // Toggle for fullscreen mode
  double _gpsUpdateDistance = 3.0; // meters
  bool _backgroundTrackingEnabled = false; // Toggle for background tracking
  StreamSubscription<CompassEvent>? _compassStreamSubscription;
  final BackgroundLocationService _backgroundLocationService = BackgroundLocationService();

  // MBTiles layers
  List<MapLayer> _mbtilesLayers = [];

  // Vector tile theme
  vtr.Theme? _vectorTheme;
  bool _isLoadingTheme = false;

  // Dropped pin state
  LatLng? _droppedPinLocation;
  bool _isDraggingPin = false;
  final GlobalKey _pinMarkerKey = GlobalKey();

  // Saved map position (loaded from SharedPreferences)
  LatLng? _savedMapCenter;
  double? _savedMapZoom;

  // Default center point (will be updated based on markers)
  static const LatLng _defaultCenter = LatLng(46.0569, 14.5058); // Ljubljana, Slovenia
  static const double _defaultZoom = 13.0;

  @override
  bool get wantKeepAlive => true;

  // Access the singleton LocationTrackingService from AppProvider
  LocationTrackingService get _locationService => LocationTrackingService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadMbtilesLayers();
    _initializeTileCache();
    _setupLocationCallbacks();
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

  /// Setup location tracking callbacks for map-specific features
  /// Note: LocationTrackingService is initialized and started by AppProvider
  /// This method only adds map-specific callbacks for rotation and UI updates
  void _setupLocationCallbacks() {
    // Store the original callback from AppProvider
    final originalCallback = _locationService.onPositionUpdate;

    // Add map-specific callback that chains with the original
    _locationService.onPositionUpdate = (position) {
      // Call original callback first (AppProvider's logging)
      originalCallback?.call(position);

      // Then handle map-specific logic
      if (mounted) {
        setState(() {
          // Position updates trigger UI rebuild for markers
        });

        // Add location point to trail when tracking is active
        final mapProvider = context.read<MapProvider>();
        if (_locationService.isTracking) {
          mapProvider.addTrailPoint(
            LatLng(position.latitude, position.longitude),
            accuracy: position.accuracy,
            speed: position.speed,
          );
        }

        // Rotate map if rotation mode is enabled and heading is available
        if (_isMapReady && _rotateMarkerWithHeading && position.heading >= 0) {
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
    };
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

  /// Load MBTiles layers from file system
  Future<void> _loadMbtilesLayers() async {
    try {
      final mbtilesService = MbtilesService();
      final metadata = await mbtilesService.getAllMetadata();

      if (mounted) {
        setState(() {
          _mbtilesLayers = metadata.map((meta) {
            // Determine if data is gzipped (for Geofabrik files)
            final isGzipped = meta.format == 'pbf';

            return MapLayer.fromMbtilesFile(
              name: meta.name,
              mbtilesFile: meta.file,
              styleUrl: 'https://tiles.openfreemap.org/styles/bright',
              sourceName: 'openmaptiles',
              maxZoom: 20.0, // Override to 20 for overzooming
              isGzipped: isGzipped,
              attribution: meta.attribution,
            );
          }).toList();
        });
        debugPrint('Loaded ${_mbtilesLayers.length} MBTiles layers');
      }
    } catch (e) {
      debugPrint('Error loading MBTiles layers: $e');
    }
  }

  /// Get all available layers (default + MBTiles)
  List<MapLayer> get _allLayers => [...MapLayer.allLayers, ..._mbtilesLayers];

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // Load last map position if available
      final lastLat = prefs.getDouble('map_last_latitude');
      final lastLon = prefs.getDouble('map_last_longitude');
      final lastZoom = prefs.getDouble('map_last_zoom');

      // Load last map layer
      final lastLayerType = prefs.getInt('map_last_layer_type');
      final lastLayerName = prefs.getString('map_last_layer_name');

      setState(() {
        _showLegend = prefs.getBool('map_show_legend') ?? false;
        _rotateMarkerWithHeading = prefs.getBool('map_rotate_with_heading') ?? false;
        _showMapDebugInfo = prefs.getBool('map_show_debug_info') ?? false;
        _isFullscreen = prefs.getBool('map_fullscreen') ?? false;

        // Notify parent about initial fullscreen state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFullscreenChanged?.call(_isFullscreen);
        });
        _gpsUpdateDistance = prefs.getDouble('map_gps_update_distance') ?? 3.0;
        _backgroundTrackingEnabled = prefs.getBool('background_tracking_enabled') ?? false;

        // Store saved position for use in build
        if (lastLat != null && lastLon != null && lastZoom != null) {
          _savedMapCenter = LatLng(lastLat, lastLon);
          _savedMapZoom = lastZoom;
        }

        // Restore last used map layer (by type and name for MBTiles)
        if (lastLayerType != null) {
          final layerType = MapLayerType.values[lastLayerType];
          if (layerType == MapLayerType.vectorMbtiles && lastLayerName != null) {
            // Find MBTiles layer by name
            final mbtilesLayer = _mbtilesLayers.firstWhere(
              (layer) => layer.name == lastLayerName,
              orElse: () => MapLayer.openStreetMap,
            );
            _currentLayer = mbtilesLayer;
          } else {
            // Use default layer
            _currentLayer = MapLayer.allLayers.firstWhere(
              (layer) => layer.type == layerType,
              orElse: () => MapLayer.openStreetMap,
            );
          }
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_show_legend', _showLegend);
    await prefs.setBool('map_rotate_with_heading', _rotateMarkerWithHeading);
    await prefs.setBool('map_show_debug_info', _showMapDebugInfo);
    await prefs.setBool('map_fullscreen', _isFullscreen);
    await prefs.setDouble('map_gps_update_distance', _gpsUpdateDistance);
    await prefs.setBool('background_tracking_enabled', _backgroundTrackingEnabled);

    // Save layer type and name (for MBTiles layers)
    await prefs.setInt('map_last_layer_type', _currentLayer.type.index);
    if (_currentLayer.type == MapLayerType.vectorMbtiles) {
      await prefs.setString('map_last_layer_name', _currentLayer.name);
    }
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
    _compassStreamSubscription?.cancel();
    // DO NOT stop location tracking - it's managed by AppProvider
    // Just clear the map-specific callback
    _locationService.onPositionUpdate = null;
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
    final currentPosition = _locationService.currentPosition;
    if (currentPosition?.heading != null && currentPosition!.heading >= 0) {
      return currentPosition.heading;
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
    return _markerService.calculateCenter(
      contacts: contacts,
      sarMarkers: sarMarkers,
      defaultCenter: _defaultCenter,
    );
  }

  /// Load vector tile theme from URL
  Future<void> _loadVectorTheme(String styleUrl) async {
    if (_isLoadingTheme) return;

    setState(() {
      _isLoadingTheme = true;
    });

    try {
      final response = await http.get(Uri.parse(styleUrl));
      if (response.statusCode == 200) {
        final styleJson = jsonDecode(response.body) as Map<String, Object?>;
        final theme = vtr.ThemeReader().read(styleJson);

        if (mounted) {
          setState(() {
            _vectorTheme = theme;
            _isLoadingTheme = false;
          });
        }
      } else {
        throw Exception('Failed to load style: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading vector theme: $e');
      if (mounted) {
        setState(() {
          _isLoadingTheme = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load map style: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      AppLocalizations.of(context)!.selectMapLayer,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: AppLocalizations.of(context)!.downloadVisibleArea,
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToDownload(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Online layers section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      AppLocalizations.of(context)!.onlineLayers,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  ...MapLayer.allLayers.map((layer) => ListTile(
                        leading: _currentLayer == layer
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.radio_button_unchecked),
                        title: Text(layer.getLocalizedName(context)),
                        subtitle: Text(layer.attribution),
                        onTap: () async {
                          setState(() {
                            _currentLayer = layer;
                          });
                          _saveSettings();
                          Navigator.pop(context);
                        },
                      )),
                  // Offline MBTiles layers section
                  if (_mbtilesLayers.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.offlineLayers,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                    ..._mbtilesLayers.map((layer) => ListTile(
                          leading: _currentLayer == layer
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Icon(
                                  layer.isVector ? Icons.layers : Icons.image,
                                  color: layer.isVector ? Colors.blue : Colors.orange,
                                ),
                          title: Text(layer.name),
                          subtitle: Text(layer.attribution),
                          onTap: () async {
                            // Load vector theme if switching to vector layer
                            if (layer.isVector && layer.styleUrl != null) {
                              Navigator.pop(context);
                              await _loadVectorTheme(layer.styleUrl!);
                            }

                            setState(() {
                              _currentLayer = layer;
                            });
                            _saveSettings();

                            if (!layer.isVector) {
                              Navigator.pop(context);
                            }
                          },
                        )),
                  ],
                ],
              ),
            ),
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
                      AppLocalizations.of(context)!.mapOptions,
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
                title: Text(AppLocalizations.of(context)!.showLegend),
                subtitle: Text(AppLocalizations.of(context)!.displayMarkerTypeCounts),
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
                title: Text(AppLocalizations.of(context)!.rotateMapWithHeading),
                subtitle: Text(AppLocalizations.of(context)!.mapFollowsDirection),
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
                title: Text(AppLocalizations.of(context)!.showMapDebugInfo),
                subtitle: Text(AppLocalizations.of(context)!.displayZoomLevelBounds),
                value: _showMapDebugInfo,
                onChanged: (value) {
                  setState(() {
                    _showMapDebugInfo = value;
                  });
                  setModalState(() {});
                  _saveSettings();
                },
              ),
              const Divider(),
              // Fullscreen mode toggle
              SwitchListTile(
                secondary: const Icon(Icons.fullscreen),
                title: Text(AppLocalizations.of(context)!.fullscreenMode),
                subtitle: Text(AppLocalizations.of(context)!.hideUiFullMapView),
                value: _isFullscreen,
                onChanged: (value) {
                  setState(() {
                    _isFullscreen = value;
                  });
                  setModalState(() {});
                  _saveSettings();
                  // Notify parent about fullscreen change
                  widget.onFullscreenChanged?.call(value);
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
        child: DetailedCompassDialog(
          initialPosition: _locationService.currentPosition,
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
        child: DetailedCompassDialog(
          initialPosition: _locationService.currentPosition,
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
        child: DetailedCompassDialog(
          initialPosition: _locationService.currentPosition,
          initialHeading: _currentHeading,
          contacts: contacts,
          sarMarkers: sarMarkers,
          preSelectedSarMarker: selectedMarker,
        ),
      ),
    );
  }

  void _restartLocationStream() {
    // Update distance threshold in location service
    _locationService.updateDistanceThreshold(_gpsUpdateDistance);

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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToStartBackgroundTracking),
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

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    return _markerService.calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
  }

  /// Show SAR dialog with pre-populated location from map long press
  void _showSarDialogWithLocation(LatLng location) {
    // Create a Position object from the LatLng coordinates
    final position = Position(
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0, // Unknown accuracy for map-selected point
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SarUpdateSheet(
        prePopulatedPosition: position,
        allowLocationUpdate: false, // Don't allow changing to current location
        onSend: (sarType, position, notes, roomPublicKey, sendToChannel) async {
          await _sendSarMessage(sarType, position, notes, roomPublicKey, sendToChannel);
        },
      ),
    );
  }

  Future<void> _sendSarMessage(
    SarMarkerType sarType,
    Position position,
    String? notes,
    Uint8List? roomPublicKey,
    bool sendToChannel,
  ) async {
    final connectionProvider = context.read<ConnectionProvider>();
    final messagesProvider = context.read<MessagesProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deviceNotConnected),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!sendToChannel && roomPublicKey == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room to send SAR marker'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Format: S:<emoji>:<latitude>,<longitude>
      final sarMessage = 'S:${sarType.emoji}:${position.latitude},${position.longitude}';

      // Add notes if provided
      final fullMessage = notes != null && notes.isNotEmpty
          ? '$sarMessage $notes'
          : sarMessage;

      if (sendToChannel) {
        // Send to public channel (ephemeral, over-the-air only)
        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: fullMessage,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sarType.displayName} marker broadcast to public channel'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Create message ID
        final messageId = '${DateTime.now().millisecondsSinceEpoch}_sent';
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
          text: fullMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          // SAR marker data is automatically added by SarMessageParser.enhanceMessage in MessagesProvider
        );

        // Add to messages list with "sending" status
        messagesProvider.addSentMessage(sentMessage);

        // Send SAR message to selected room (persisted and immutable)
        final sentSuccessfully = await connectionProvider.sendTextMessage(
          contactPublicKey: roomPublicKey!,
          text: fullMessage,
          messageId: messageId, // Pass message ID so it can be tracked
        );

        if (!sentSuccessfully) {
          // Mark message as failed if sending failed
          messagesProvider.markMessageFailed(messageId);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${sarType.displayName} marker sent to room'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SAR marker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer3<ContactsProvider, MessagesProvider, DrawingProvider>(
      builder: (context, contactsProvider, messagesProvider, drawingProvider, child) {
        final contactsWithLocation = contactsProvider.contactsWithLocation;
        final sarMarkers = messagesProvider.sarMarkers;
        final center = _calculateCenter(contactsWithLocation, sarMarkers);

        return Stack(
          children: [
            // Map widget
            _isInitialized
                ? Listener(
                    onPointerMove: (PointerMoveEvent event) {
                      // Track pointer movement for mobile drag (onPointerHover doesn't work on mobile)
                      if (_isDraggingPin) {
                        final latLng = _mapController.camera.screenOffsetToLatLng(event.localPosition);
                        setState(() {
                          _droppedPinLocation = latLng;
                        });
                      }
                    },
                    child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      // Use saved position if available, otherwise use calculated center
                      initialCenter: _savedMapCenter ?? center,
                      initialZoom: _savedMapZoom ?? _defaultZoom,
                      minZoom: 0, // Allow full zoom out to see world view
                      maxZoom: _currentLayer.maxZoom, // Respect current layer's maximum
                      interactionOptions: InteractionOptions(
                        flags: _isDraggingPin
                            ? InteractiveFlag.none // Disable map interaction while dragging pin
                            : InteractiveFlag.all,
                      ),
                      onMapEvent: (event) {
                        // Save map position when user stops panning/zooming
                        if (event is MapEventMoveEnd || event is MapEventScrollWheelZoom) {
                          _saveMapPosition();
                        }
                      },
                      onLongPress: (tapPosition, point) {
                        // Skip if in drawing mode
                        if (drawingProvider.isDrawing) return;

                        // Drop a pin at long press location (if no pin exists)
                        if (_droppedPinLocation == null) {
                          setState(() {
                            _droppedPinLocation = point;
                          });
                        }
                      },
                      onPointerDown: (event, point) {
                        // Check if pointer is near the pin to start dragging
                        if (_droppedPinLocation != null) {
                          final distance = _calculateDistanceInMeters(
                            _droppedPinLocation!.latitude,
                            _droppedPinLocation!.longitude,
                            point.latitude,
                            point.longitude,
                          );
                          // If within ~50m of pin, start dragging
                          if (distance <= 50) {
                            setState(() {
                              _isDraggingPin = true;
                            });
                          }
                        }
                      },
                      onPointerHover: (event, point) {
                        // Update rectangle preview while dragging
                        if (drawingProvider.drawingMode == DrawingMode.rectangle &&
                            drawingProvider.rectangleStartPoint != null) {
                          drawingProvider.updateRectangleEndPoint(point);
                          return;
                        }

                        // Update pin location while dragging
                        if (_isDraggingPin) {
                          setState(() {
                            _droppedPinLocation = point;
                          });
                        }
                      },
                      onPointerUp: (event, point) {
                        // Stop dragging on pointer release
                        if (_isDraggingPin) {
                          setState(() {
                            _isDraggingPin = false;
                          });
                        }
                      },
                      onTap: (tapPosition, point) {
                        // Handle drawing mode taps
                        if (drawingProvider.drawingMode == DrawingMode.line) {
                          if (drawingProvider.currentLinePoints.isEmpty) {
                            // Start new line
                            drawingProvider.startLine(point);
                          } else {
                            // Add point to current line
                            drawingProvider.addLinePoint(point);
                          }
                          return;
                        } else if (drawingProvider.drawingMode == DrawingMode.rectangle) {
                          if (drawingProvider.rectangleStartPoint == null) {
                            // Start rectangle
                            drawingProvider.startRectangle(point);
                          } else {
                            // Complete rectangle
                            drawingProvider.completeRectangle(point);
                          }
                          return;
                        }

                        // Clear dropped pin if tapping elsewhere (not on the pin itself)
                        if (_droppedPinLocation != null && !_isDraggingPin) {
                          // Check if tap is far from the pin
                          final distance = _calculateDistanceInMeters(
                            _droppedPinLocation!.latitude,
                            _droppedPinLocation!.longitude,
                            point.latitude,
                            point.longitude,
                          );
                          // If tap is more than ~50m away, clear pin
                          if (distance > 50) {
                            setState(() {
                              _droppedPinLocation = null;
                            });
                          }
                        }
                      },
                    ),
                    children: [
                      // Render vector or raster tile layer based on layer type
                      if (_currentLayer.isVector && _vectorTheme != null)
                        VectorTileLayer(
                          theme: _vectorTheme!,
                          tileProviders: TileProviders({
                            _currentLayer.sourceName ?? 'default':
                              _tileCache.getVectorTileProvider(_currentLayer)!,
                          }),
                          maximumZoom: _currentLayer.maxZoom,
                        )
                      else if (!_currentLayer.isVector)
                        flutter_map.TileLayer(
                          urlTemplate: _currentLayer.urlTemplate,
                          tileProvider: _tileCache.getTileProvider(_currentLayer),
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: _currentLayer.maxZoom,
                        ),
                      // Advertisement path polylines (rendered before markers)
                      Consumer<MapProvider>(
                        builder: (context, mapProvider, _) {
                          return PolylineLayer(
                            polylines: contactsWithLocation
                                .where((contact) => mapProvider.isContactPathVisible(contact.publicKeyHex))
                                .where((contact) => contact.advertHistory.length >= 2)
                                .map((contact) {
                                  return Polyline(
                                    points: contact.advertHistory
                                        .map((advert) => advert.location)
                                        .toList(),
                                    color: Colors.blue.withValues(alpha: 0.7),
                                    strokeWidth: 3.0,
                                    borderColor: Colors.white.withValues(alpha: 0.5),
                                    borderStrokeWidth: 1.0,
                                  );
                                })
                                .toList(),
                          );
                        },
                      ),
                      // Location trail layer (rendered after paths, before drawings)
                      const LocationTrailLayer(),
                      // Drawing layer (rendered after paths, before markers)
                      DrawingLayer(
                        drawings: drawingProvider.drawings,
                        previewDrawing: drawingProvider.getPreviewDrawing(),
                      ),
                      MarkerLayer(
                        markers: [
                          // Contact markers
                          ..._markerService.generateContactMarkers(
                            contacts: contactsWithLocation,
                            context: context,
                            mapRotation: _getMapRotation(),
                            userPosition: _locationService.currentPosition,
                            onTap: (contact) {
                              _showDetailedCompassWithContact(
                                context,
                                contactsProvider.contactsWithLocation,
                                messagesProvider.sarMarkers,
                                contact,
                              );
                            },
                          ),
                          // SAR markers
                          ..._markerService.generateSarMarkers(
                            sarMarkers: sarMarkers,
                            context: context,
                            mapRotation: _getMapRotation(),
                            onTap: (marker) {
                              _showDetailedCompassWithSarMarker(
                                context,
                                contactsProvider.contactsWithLocation,
                                messagesProvider.sarMarkers,
                                marker,
                              );
                            },
                          ),
                          // User location marker
                          if (_markerService.generateUserLocationMarker(
                            position: _locationService.currentPosition,
                            context: context,
                          ) != null)
                            _markerService.generateUserLocationMarker(
                              position: _locationService.currentPosition,
                              context: context,
                            )!,
                          // Dropped pin marker with label
                          if (_droppedPinLocation != null)
                            Marker(
                              key: _pinMarkerKey,
                              point: _droppedPinLocation!,
                              width: 200,
                              height: 100,
                              rotate: false,
                              child: GestureDetector(
                                onTap: () {
                                  // Only open dialog if not dragging
                                  if (!_isDraggingPin) {
                                    _showSarDialogWithLocation(_droppedPinLocation!);
                                    // Clear the pin after opening dialog
                                    setState(() {
                                      _droppedPinLocation = null;
                                    });
                                  }
                                },
                                child: Opacity(
                                  // Make pin slightly transparent while dragging
                                  opacity: _isDraggingPin ? 0.7 : 1.0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Label
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isDraggingPin ? Colors.orange : Colors.red,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _isDraggingPin ? AppLocalizations.of(context)!.dragToPosition : AppLocalizations.of(context)!.createSarMarker,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Pin icon pointing down
                                      Icon(
                                        Icons.location_pin,
                                        color: _isDraggingPin ? Colors.orange : Colors.red,
                                        size: 48,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Drawing markers layer (delete buttons on drawings, only shown when in drawing mode)
                      DrawingMarkersLayer(
                        drawings: drawingProvider.drawings,
                        showDeleteButtons: drawingProvider.isDrawing,
                        onDeleteDrawing: (drawingId) {
                          drawingProvider.removeDrawing(drawingId);
                        },
                      ),
                    ],
                  ),
                )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.initializingMap,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
            // Exit fullscreen button - top left (only shown in fullscreen mode)
            if (_isFullscreen)
              Positioned(
                top: 60,
                left: 16,
                child: FloatingActionButton.small(
                  heroTag: 'exit_fullscreen',
                  onPressed: () {
                    setState(() {
                      _isFullscreen = false;
                    });
                    _saveSettings();
                    // Notify parent about fullscreen change
                    widget.onFullscreenChanged?.call(false);
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  child: const Icon(Icons.fullscreen_exit),
                ),
              ),
            // Compass widget - top right (hidden in fullscreen mode)
            if (!_isFullscreen)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _showDetailedCompass(
                    context,
                    contactsProvider.contactsWithLocation,
                    messagesProvider.sarMarkers,
                  ),
                  child: CompassWidget(
                    heading: _currentHeading ?? 0,
                    hasHeading: _currentHeading != null,
                  ),
                ),
              ),
            // Map legend overlay (hidden in fullscreen mode)
            if (_showLegend && !_isFullscreen)
              Positioned(
                top: 80, // Position below compass
                left: 16,
                child: MapLegend(
                  teamMemberCount: contactsWithLocation.length,
                  foundPersonCount: messagesProvider.foundPersonMarkers.length,
                  fireCount: messagesProvider.fireMarkers.length,
                  stagingAreaCount: messagesProvider.stagingAreaMarkers.length,
                  objectCount: messagesProvider.objectMarkers.length,
                ),
              ),
            // Map controls - right side (hidden in fullscreen mode)
            if (!_isFullscreen)
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    // Drawing toolbar
                    const DrawingToolbar(),
                    // Hide other buttons when in drawing mode
                    if (!drawingProvider.isDrawing) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                      heroTag: 'center_map',
                      onPressed: !_isMapReady ? null : () async {
                        // Force update GPS location and jump to it
                        final position = await _locationService.getCurrentPosition();
                        if (position != null && mounted) {
                          setState(() {
                            // Position updated in service
                          });
                          _mapController.move(
                            LatLng(position.latitude, position.longitude),
                            16,
                          );
                        } else {
                          // Fallback to cached position or default center
                          final currentPosition = _locationService.currentPosition;
                          if (currentPosition != null) {
                            _mapController.move(
                              LatLng(
                                currentPosition.latitude,
                                currentPosition.longitude,
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
                    // Trail controls button
                    const TrailControls(),
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
                  ],
                ),
              ),
            // Map debug info - bottom left (hidden in fullscreen mode)
            if (_showMapDebugInfo && _isMapReady && !_isFullscreen)
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

