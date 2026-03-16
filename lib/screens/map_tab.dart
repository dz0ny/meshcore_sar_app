import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/slovenian_crs.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/map_provider.dart';
import '../providers/drawing_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../models/contact.dart';
import '../models/custom_map_config.dart';
import '../models/map_coordinate_space.dart';
import '../models/sar_marker.dart';
import '../models/map_layer.dart';
import '../models/message.dart';
import '../services/background_location_service.dart';
import '../services/location_tracking_service.dart';
import '../services/map_marker_service.dart';
import '../services/message_destination_preferences.dart';
import '../services/trail_color_service.dart';
import '../widgets/map_debug_info.dart';
import '../widgets/map/compass_widget.dart';
import '../widgets/map/detailed_compass_dialog.dart';
import '../widgets/map/drawing_layer.dart';
import '../widgets/map/drawing_toolbar.dart';
import '../widgets/map/location_trail_layer.dart';
import '../widgets/map/trail_controls.dart';
import '../widgets/map/map_message_overlay.dart';
import '../widgets/messages/custom_map_sar_update_sheet.dart';
import '../widgets/messages/sar_update_sheet.dart';
import '../utils/key_comparison.dart';
import '../utils/sar_message_parser.dart';
import '../l10n/app_localizations.dart';

class MapTab extends StatefulWidget {
  final Function(bool)? onFullscreenChanged;
  final VoidCallback? onNavigateToMessages;

  const MapTab({
    super.key,
    this.onFullscreenChanged,
    this.onNavigateToMessages,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  static final TileProvider _tileProvider = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 10_000_000_000,
      overrideFreshAge: const Duration(days: 365),
    ),
  );
  // DO NOT create a new LocationTrackingService instance here
  // Use the singleton from AppProvider instead via _locationService getter
  final MapMarkerService _markerService = MapMarkerService();
  bool _isMapReady = false; // Track when map widget is actually rendered
  MapLayer _currentLayer = MapLayer.openStreetMap;
  double? _compassHeading; // Compass sensor heading
  bool _rotateMarkerWithHeading = false; // Toggle for rotation
  bool _showMapDebugInfo = false; // Toggle for debug info
  bool _isFullscreen = false; // Toggle for fullscreen mode
  double _gpsUpdateDistance = 3.0; // meters
  bool _backgroundTrackingEnabled = false; // Toggle for background tracking
  StreamSubscription<CompassEvent>? _compassStreamSubscription;
  final BackgroundLocationService _backgroundLocationService =
      BackgroundLocationService();
  bool _isDisposing = false; // Flag to prevent updates during disposal
  MapProvider? _mapProvider;

  // Store original location callback to restore in dispose
  void Function(Position)? _originalLocationCallback;

  // WMS layers (Slovenian)
  late final MapLayer _slovenianAerialLayer;
  late final MapLayer _dtk25Layer;

  // Dropped pin state
  LatLng? _droppedPinLocation;
  bool _isDraggingPin = false;
  final GlobalKey _pinMarkerKey = GlobalKey();

  // Saved map position (loaded from SharedPreferences)
  LatLng? _savedMapCenter;
  double? _savedMapZoom;
  bool _isCalibratingCustomMap = false;
  LatLng? _customMapCalibrationPointA;
  LatLng? _customMapCalibrationPointB;
  String _lastCustomMapViewportKey = '';

  // Default center point (will be updated based on markers)
  static const LatLng _defaultCenter = LatLng(
    46.0569,
    14.5058,
  ); // Ljubljana, Slovenia
  static const double _defaultZoom = 13.0;

  @override
  bool get wantKeepAlive => true;

  // Access the singleton LocationTrackingService from AppProvider
  LocationTrackingService get _locationService => LocationTrackingService();

  @override
  void initState() {
    super.initState();
    // Initialize Slovenian WMS layers with CRS
    _slovenianAerialLayer = MapLayer.getSlovenianAerial2024(slovenianCrs);
    _dtk25Layer = MapLayer.getDTK25(slovenianCrs);
    _loadSettings();
    _markMapReadyWhenMounted();
    _setupLocationCallbacks();
    _startCompassTracking();

    // Listen to map provider for navigation requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Check if widget is still mounted
      final mapProvider = context.read<MapProvider>();
      _mapProvider = mapProvider;
      mapProvider.addListener(_handleMapNavigation);
      // Load WMS overlay state
      mapProvider.loadOverlayState();

      // Initialize background location service with BLE service
      final appProvider = context.read<AppProvider>();
      _backgroundLocationService.initialize(
        appProvider.connectionProvider.bleService,
      );

      // Restore background tracking state
      _restoreBackgroundTracking();
    });
  }

  /// Setup location tracking callbacks for map-specific features
  /// Note: LocationTrackingService is initialized and started by AppProvider
  /// This method only adds map-specific callbacks for rotation and UI updates
  void _setupLocationCallbacks() {
    // Store the original callback from AppProvider to restore in dispose
    _originalLocationCallback = _locationService.onPositionUpdate;

    // Add map-specific callback that chains with the original
    _locationService.onPositionUpdate = (position) {
      // Call original callback first (AppProvider's logging)
      _originalLocationCallback?.call(position);

      // Then handle map-specific logic - early exit if not mounted or disposing
      if (!mounted || _isDisposing) {
        return;
      }

      setState(() {
        // Position updates trigger UI rebuild for markers
      });

      // Add location point to trail when tracking is active
      if (_locationService.isTracking) {
        try {
          final mapProvider = context.read<MapProvider>();
          mapProvider.addTrailPoint(
            LatLng(position.latitude, position.longitude),
            accuracy: position.accuracy,
            speed: position.speed,
          );
        } catch (e) {
          // Context might be invalid during disposal, ignore
          debugPrint('Failed to add trail point: $e');
        }
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
          // Map not ready yet or controller disposed, ignore
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
    _compassStreamSubscription = compassStream.listen((CompassEvent event) {
      // Check if widget is disposing, mounted, and event has valid heading
      if (_isDisposing || !mounted || event.heading == null) return;

      try {
        setState(() {
          _compassHeading = event.heading;
        });

        // Rotate map if rotation mode is enabled and we have compass heading
        // Only rotate if map is ready
        if (_rotateMarkerWithHeading &&
            event.heading != null &&
            _isMapReady &&
            !_isDisposing) {
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
      } catch (e) {
        // Widget disposed during setState, ignore
        if (!_isDisposing) {
          debugPrint('Compass tracking error: $e');
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // Load last map position if available
      final lastLat = prefs.getDouble('map_last_latitude');
      final lastLon = prefs.getDouble('map_last_longitude');
      final lastZoom = prefs.getDouble('map_last_zoom');

      // Load last map layer
      final lastLayerType = prefs.getInt('map_last_layer_type');
      setState(() {
        _rotateMarkerWithHeading =
            prefs.getBool('map_rotate_with_heading') ?? false;
        _showMapDebugInfo = prefs.getBool('map_show_debug_info') ?? false;
        _isFullscreen = prefs.getBool('map_fullscreen') ?? false;

        // Notify parent about initial fullscreen state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFullscreenChanged?.call(_isFullscreen);
        });
        _gpsUpdateDistance = prefs.getDouble('map_gps_update_distance') ?? 3.0;
        _backgroundTrackingEnabled =
            prefs.getBool('background_tracking_enabled') ?? false;

        // Store saved position for use in build
        if (lastLat != null && lastLon != null && lastZoom != null) {
          _savedMapCenter = LatLng(lastLat, lastLon);
          _savedMapZoom = lastZoom;
        }

        // Restore last used map layer.
        if (lastLayerType != null) {
          final layerType = MapLayerType.values[lastLayerType];
          if (layerType == MapLayerType.vectorMbtiles) {
            _currentLayer = MapLayer.openStreetMap;
          } else if (layerType == MapLayerType.wmsBase) {
            // Use Slovenian aerial layer if that's what was saved
            _currentLayer = _slovenianAerialLayer;
          } else {
            // Use default layer
            _currentLayer = MapLayer.allLayers.firstWhere(
              (layer) => layer.type == layerType,
              orElse: () => MapLayer.openStreetMap,
            );
          }
        }

        // Clamp saved zoom if it exceeds the current layer's maximum
        // For WMS layers, use a middle zoom (11) instead of max zoom to avoid extreme close-up
        if (_savedMapZoom != null && _savedMapZoom! > _currentLayer.maxZoom) {
          _savedMapZoom = _currentLayer.isWms ? 11.0 : _currentLayer.maxZoom;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_rotate_with_heading', _rotateMarkerWithHeading);
    await prefs.setBool('map_show_debug_info', _showMapDebugInfo);
    await prefs.setBool('map_fullscreen', _isFullscreen);
    await prefs.setDouble('map_gps_update_distance', _gpsUpdateDistance);
    await prefs.setBool(
      'background_tracking_enabled',
      _backgroundTrackingEnabled,
    );

    // Save layer type.
    await prefs.setInt('map_last_layer_type', _currentLayer.type.index);
    await prefs.remove('map_last_layer_name');
  }

  Future<void> _saveMapPosition() async {
    if (!_isMapReady) return;
    if (_mapProvider?.isUsingCustomMap == true) return;
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
    if (!_isMapReady) return;

    try {
      final customMapConfig = mapProvider.customMapConfig;

      if (mapProvider.targetBounds != null) {
        final bounds =
            mapProvider.targetCoordinateSpace == MapCoordinateSpace.customMap &&
                customMapConfig != null
            ? _toDisplayBounds(customMapConfig, mapProvider.targetBounds!)
            : mapProvider.targetBounds!;

        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
        );
        mapProvider.clearNavigation();
        return;
      }

      if (mapProvider.targetLocation != null) {
        final location =
            mapProvider.targetCoordinateSpace == MapCoordinateSpace.customMap &&
                customMapConfig != null
            ? _toDisplayMapPoint(customMapConfig, mapProvider.targetLocation!)
            : mapProvider.targetLocation!;
        final zoom =
            mapProvider.targetCoordinateSpace == MapCoordinateSpace.customMap
            ? (mapProvider.targetZoom ?? 2.0).clamp(-4.0, 8.0).toDouble()
            : mapProvider.targetZoom ?? _defaultZoom;

        _mapController.move(location, zoom);
        mapProvider.clearNavigation();
      }
    } catch (e) {
      debugPrint('Map controller not ready for navigation: $e');
    }
  }

  void _markMapReadyWhenMounted() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        setState(() {
          _isMapReady = true;
        });
        debugPrint('Map is now ready for controller operations');
      });
    });
  }

  @override
  void dispose() {
    // Set flag immediately to prevent any async callbacks from firing
    _isDisposing = true;

    // Cancel compass subscription first to stop new events
    _compassStreamSubscription?.cancel();
    _compassStreamSubscription = null;

    // Save map position before disposing
    _saveMapPosition();

    _mapProvider?.removeListener(_handleMapNavigation);

    // DO NOT stop location tracking - it's managed by AppProvider
    // Restore the original callback instead of setting to null
    _locationService.onPositionUpdate = _originalLocationCallback;
    _mapController.dispose();
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

  void _showLayerSelector(BuildContext context) {
    final rootContext = this.context;
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.onlineLayers,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                  ...MapLayer.allLayers.map(
                    (layer) => ListTile(
                      leading: _currentLayer == layer
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                      title: Text(layer.getLocalizedName(context)),
                      subtitle: Text(layer.attribution),
                      onTap: () async {
                        setState(() {
                          _currentLayer = layer;
                          // Clamp zoom level if current zoom exceeds new layer's max
                          if (_isMapReady &&
                              _mapController.camera.zoom > layer.maxZoom) {
                            _mapController.move(
                              _mapController.camera.center,
                              layer.maxZoom,
                            );
                          }
                        });
                        _saveSettings();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  // Slovenian WMS base layers (only for Slovenian/Croatian regions)
                  if (AppLocalizations.of(context)!.localeName == 'sl' ||
                      AppLocalizations.of(context)!.localeName == 'hr') ...[
                    ListTile(
                      leading: _currentLayer == _slovenianAerialLayer
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                      title: Text(_slovenianAerialLayer.name),
                      subtitle: Text(_slovenianAerialLayer.attribution),
                      onTap: () async {
                        setState(() {
                          _currentLayer = _slovenianAerialLayer;
                          // Clamp zoom level if current zoom exceeds new layer's max
                          // For WMS layers, use a middle zoom (11) instead of max zoom to avoid extreme close-up
                          if (_isMapReady &&
                              _mapController.camera.zoom >
                                  _slovenianAerialLayer.maxZoom) {
                            _mapController.move(
                              _mapController.camera.center,
                              11.0, // Middle zoom for WMS
                            );
                          }
                        });
                        _saveSettings();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: _currentLayer == _dtk25Layer
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                      title: Text(AppLocalizations.of(context)!.topographicMap),
                      subtitle: Text(_dtk25Layer.attribution),
                      onTap: () async {
                        setState(() {
                          _currentLayer = _dtk25Layer;
                          // Clamp zoom level if current zoom exceeds new layer's max
                          // For WMS layers, use a middle zoom (11) instead of max zoom to avoid extreme close-up
                          if (_isMapReady &&
                              _mapController.camera.zoom >
                                  _dtk25Layer.maxZoom) {
                            _mapController.move(
                              _mapController.camera.center,
                              11.0, // Middle zoom for WMS
                            );
                          }
                        });
                        _saveSettings();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  // WMS Overlays section (only for Slovenian/Croatian regions and when WMS base layer is selected)
                  if ((AppLocalizations.of(context)!.localeName == 'sl' ||
                          AppLocalizations.of(context)!.localeName == 'hr') &&
                      _currentLayer.isWms) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.wmsOverlays,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        return Column(
                          children: [
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.grid_on,
                                color: Colors.blue,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.cadastralParcels,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showCadastralOverlay,
                              onChanged: (value) {
                                mapProvider.toggleCadastralOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.route,
                                color: Colors.green,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.forestRoads,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showForestRoadsOverlay,
                              onChanged: (value) {
                                mapProvider.toggleForestRoadsOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.hiking,
                                color: Colors.brown,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.hikingTrails,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showHikingTrailsOverlay,
                              onChanged: (value) {
                                mapProvider.toggleHikingTrailsOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.alt_route,
                                color: Colors.grey,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.mainRoads,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showMainRoadsOverlay,
                              onChanged: (value) {
                                mapProvider.toggleMainRoadsOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.numbers,
                                color: Colors.purple,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.houseNumbers,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showHouseNumbersOverlay,
                              onChanged: (value) {
                                mapProvider.toggleHouseNumbersOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.warning_amber,
                                color: Colors.orange,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.fireHazardZones,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showFireHazardZonesOverlay,
                              onChanged: (value) {
                                mapProvider.toggleFireHazardZonesOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.local_fire_department,
                                color: Colors.red,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.historicalFires,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showHistoricalFiresOverlay,
                              onChanged: (value) {
                                mapProvider.toggleHistoricalFiresOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.forest,
                                color: Colors.teal,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.firebreaks,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showFirebreaksOverlay,
                              onChanged: (value) {
                                mapProvider.toggleFirebreaksOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.warning,
                                color: Colors.deepOrange,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.krasFireZones,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showKrasFireZonesOverlay,
                              onChanged: (value) {
                                mapProvider.toggleKrasFireZonesOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.place,
                                color: Colors.indigo,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.placeNames,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showPlaceNamesOverlay,
                              onChanged: (value) {
                                mapProvider.togglePlaceNamesOverlay();
                              },
                            ),
                            CheckboxListTile(
                              secondary: const Icon(
                                Icons.border_outer,
                                color: Colors.cyan,
                              ),
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.municipalityBorders,
                              ),
                              subtitle: const Text('© GURS'),
                              value: mapProvider.showMunicipalityBordersOverlay,
                              onChanged: (value) {
                                mapProvider.toggleMunicipalityBordersOverlay();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const Divider(),
                  Consumer<MapProvider>(
                    builder: (context, mapProvider, _) {
                      final customMapConfig = mapProvider.customMapConfig;
                      final hasCustomMap = customMapConfig != null;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.photo_library_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Custom picture map',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!hasCustomMap)
                            ListTile(
                              leading: const Icon(Icons.add_photo_alternate),
                              title: const Text('Load from gallery'),
                              subtitle: const Text(
                                'Use a cave map image instead of GPS tiles',
                              ),
                              onTap: () async {
                                final loaded = await mapProvider
                                    .loadCustomMapFromGallery();
                                if (!context.mounted || !rootContext.mounted) {
                                  return;
                                }
                                Navigator.pop(context);
                                if (!loaded) {
                                  return;
                                }
                                final drawingProvider = rootContext
                                    .read<DrawingProvider>();
                                _syncDrawingContext(
                                  drawingProvider,
                                  mapProvider,
                                );
                              },
                            )
                          else ...[
                            ListTile(
                              leading: const Icon(Icons.image_outlined),
                              title: Text(customMapConfig.displayName),
                              subtitle: Text(
                                'Map ID ${customMapConfig.mapId}${customMapConfig.isCalibrated ? ' • Scale set' : ' • Not calibrated'}',
                              ),
                            ),
                            SwitchListTile(
                              secondary: const Icon(Icons.map_outlined),
                              title: const Text('Use custom map'),
                              subtitle: const Text(
                                'Hide GPS-based layers and work in image space',
                              ),
                              value: mapProvider.isUsingCustomMap,
                              onChanged: (value) async {
                                if (value) {
                                  await mapProvider.enterCustomMapMode();
                                } else {
                                  await mapProvider.exitCustomMapMode();
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.swap_horizontal_circle),
                              title: const Text('Replace image'),
                              subtitle: const Text(
                                'Pick a different map from the gallery',
                              ),
                              onTap: () async {
                                await mapProvider.replaceCustomMap();
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.straighten),
                              title: Text(
                                customMapConfig.isCalibrated
                                    ? 'Update scale'
                                    : 'Set scale',
                              ),
                              subtitle: const Text(
                                'Tap two points on the image and enter meters',
                              ),
                              onTap: () async {
                                if (!mapProvider.isUsingCustomMap) {
                                  await mapProvider.enterCustomMapMode();
                                }
                                if (!context.mounted || !rootContext.mounted) {
                                  return;
                                }
                                Navigator.pop(context);
                                _startCustomMapCalibration(
                                  rootContext.read<DrawingProvider>(),
                                );
                              },
                            ),
                            if (customMapConfig.isCalibrated)
                              ListTile(
                                leading: const Icon(Icons.clear),
                                title: const Text('Clear scale'),
                                onTap: () async {
                                  await mapProvider.clearCustomMapCalibration();
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                              ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: Text(
                                'Remove custom map',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              subtitle: const Text(
                                'Deletes the saved image from this device',
                              ),
                              onTap: () async {
                                await mapProvider.removeCustomMap();
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedCompass(
    BuildContext context,
    List<Contact> contacts,
    List<SarMarker> sarMarkers,
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
            content: Text(
              AppLocalizations.of(context)!.failedToStartBackgroundTracking,
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _markerService.calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  LatLng _toStoredMapPoint(CustomMapConfig config, LatLng point) {
    return config.fromDisplayPoint(point);
  }

  LatLng _toDisplayMapPoint(CustomMapConfig config, LatLng point) {
    return config.toDisplayPoint(point);
  }

  LatLngBounds _toDisplayBounds(CustomMapConfig config, LatLngBounds bounds) {
    return LatLngBounds.fromPoints([
      _toDisplayMapPoint(config, LatLng(bounds.north, bounds.west)),
      _toDisplayMapPoint(config, LatLng(bounds.north, bounds.east)),
      _toDisplayMapPoint(config, LatLng(bounds.south, bounds.west)),
      _toDisplayMapPoint(config, LatLng(bounds.south, bounds.east)),
    ]);
  }

  void _syncDrawingContext(
    DrawingProvider drawingProvider,
    MapProvider mapProvider,
  ) {
    final coordinateSpace = mapProvider.isUsingCustomMap
        ? MapCoordinateSpace.customMap
        : MapCoordinateSpace.geo;
    final mapId = mapProvider.isUsingCustomMap
        ? mapProvider.customMapConfig?.mapId
        : null;
    final metersPerPixel = mapProvider.isUsingCustomMap
        ? mapProvider.customMapConfig?.metersPerPixel
        : null;

    if (drawingProvider.activeCoordinateSpace == coordinateSpace &&
        drawingProvider.activeMapId == mapId &&
        drawingProvider.activeMetersPerPixel == metersPerPixel) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      drawingProvider.setMapContext(
        coordinateSpace: coordinateSpace,
        mapId: mapId,
        metersPerPixel: metersPerPixel,
      );
    });
  }

  void _ensureCustomMapViewport(
    MapProvider mapProvider,
    CustomMapConfig? customMapConfig,
  ) {
    final nextKey = mapProvider.isUsingCustomMap && customMapConfig != null
        ? customMapConfig.mapId
        : '';
    if (_lastCustomMapViewportKey == nextKey) {
      return;
    }
    _lastCustomMapViewportKey = nextKey;

    if (!_isMapReady ||
        customMapConfig == null ||
        !mapProvider.isUsingCustomMap) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMapReady || !mapProvider.isUsingCustomMap) {
        return;
      }
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: customMapConfig.displayBounds,
            padding: const EdgeInsets.all(24),
          ),
        );
      } catch (e) {
        debugPrint('Failed to fit custom map viewport: $e');
      }
    });
  }

  void _startCustomMapCalibration(DrawingProvider drawingProvider) {
    if (!mounted) return;
    drawingProvider.exitDrawingMode();
    setState(() {
      _droppedPinLocation = null;
      _isDraggingPin = false;
      _isCalibratingCustomMap = true;
      _customMapCalibrationPointA = null;
      _customMapCalibrationPointB = null;
    });
  }

  void _stopCustomMapCalibration() {
    if (!mounted) return;
    setState(() {
      _isCalibratingCustomMap = false;
      _customMapCalibrationPointA = null;
      _customMapCalibrationPointB = null;
    });
  }

  Future<void> _handleCustomMapCalibrationTap(
    MapProvider mapProvider,
    LatLng storedPoint,
  ) async {
    if (!_isCalibratingCustomMap) {
      return;
    }

    if (_customMapCalibrationPointA == null) {
      setState(() {
        _customMapCalibrationPointA = storedPoint;
      });
      return;
    }

    if (_customMapCalibrationPointB == null) {
      setState(() {
        _customMapCalibrationPointB = storedPoint;
      });

      final controller = TextEditingController();
      final meters = await showDialog<double>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Set map scale'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Distance in meters',
                hintText: '25',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(dialogContext)!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(controller.text.trim());
                  if (value == null || value <= 0) {
                    return;
                  }
                  Navigator.pop(dialogContext, value);
                },
                child: Text(AppLocalizations.of(dialogContext)!.save),
              ),
            ],
          );
        },
      );

      if (meters == null || meters <= 0) {
        if (mounted) {
          setState(() {
            _customMapCalibrationPointB = null;
          });
        }
        return;
      }

      final pointA = _customMapCalibrationPointA!;
      final pointB = _customMapCalibrationPointB!;
      final dy = pointB.latitude - pointA.latitude;
      final dx = pointB.longitude - pointA.longitude;
      final pixelDistance = math.sqrt((dx * dx) + (dy * dy));
      if (pixelDistance <= 0) {
        return;
      }

      await mapProvider.setCustomMapCalibration(
        pointA: pointA,
        pointB: pointB,
        metersPerPixel: meters / pixelDistance,
      );

      _stopCustomMapCalibration();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Custom map scale saved')));
    }
  }

  void _showCustomMapSarDialogWithPoint(
    CustomMapConfig customMapConfig,
    LatLng storedPoint,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomMapSarUpdateSheet(
        mapName: customMapConfig.displayName,
        mapId: customMapConfig.mapId,
        pointLabel:
            'Point: ${storedPoint.latitude.toStringAsFixed(0)}, ${storedPoint.longitude.toStringAsFixed(0)}',
        onSend:
            (
              emoji,
              name,
              roomPublicKey,
              sendToChannel,
              sendToAllContacts,
              colorIndex,
            ) async {
              await _sendCustomMapSarMessage(
                emoji,
                name,
                storedPoint,
                customMapConfig.mapId,
                roomPublicKey,
                sendToChannel,
                sendToAllContacts,
                colorIndex,
              );
            },
      ),
    );
  }

  Widget _buildTaggedPointMarker({
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.place, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Future<void> _showSarMarkerActions(
    SarMarker marker,
    MessagesProvider messagesProvider,
    ContactsProvider contactsProvider,
  ) async {
    final message = messagesProvider.getMessageById(marker.id);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(marker.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        marker.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  marker.coordinateSpace == MapCoordinateSpace.customMap
                      ? 'Point ${marker.location.latitude.toStringAsFixed(0)}, ${marker.location.longitude.toStringAsFixed(0)}'
                      : '${marker.location.latitude.toStringAsFixed(6)}, ${marker.location.longitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (marker.coordinateSpace == MapCoordinateSpace.customMap &&
                    marker.mapId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Map ID ${marker.mapId}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  marker.senderName != null
                      ? '${marker.timeAgo} • ${marker.senderName}'
                      : marker.timeAgo,
                  style: theme.textTheme.bodySmall,
                ),
                if (marker.notes != null && marker.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(marker.notes!),
                ],
                const SizedBox(height: 16),
                if (message != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('Open message'),
                    subtitle: const Text('Jump to the related SAR message'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _openSarMarkerMessage(
                        message,
                        messagesProvider,
                        contactsProvider,
                      );
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Remove marker',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: Text(
                    message != null
                        ? 'This also removes the linked SAR message.'
                        : 'Hide this marker from the map.',
                  ),
                  onTap: () async {
                    final confirmed = await _confirmSarMarkerRemoval(
                      hasMessage: message != null,
                    );
                    if (!mounted ||
                        !sheetContext.mounted ||
                        confirmed != true) {
                      return;
                    }
                    Navigator.pop(sheetContext);
                    await messagesProvider.removeSarMarkerPermanently(
                      marker.id,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmSarMarkerRemoval({required bool hasMessage}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove SAR marker'),
        content: Text(
          hasMessage
              ? 'This will remove the marker and its linked chat message.'
              : 'This will hide the marker from the map, even if it is not visible in chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(dialogContext)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _openSarMarkerMessage(
    Message message,
    MessagesProvider messagesProvider,
    ContactsProvider contactsProvider,
  ) async {
    if (message.isChannelMessage) {
      final channelContact = contactsProvider.channels.where((contact) {
        return contact.publicKey.length > 1 &&
            contact.publicKey[1] == (message.channelIdx ?? 0);
      }).firstOrNull;

      messagesProvider.navigateToDestination(
        MessageDestinationPreferences.destinationTypeChannel,
        recipientPublicKeyHex: channelContact?.publicKeyHex,
      );
    } else {
      Contact? destinationContact;

      if (message.recipientPublicKey != null) {
        destinationContact = contactsProvider.contacts.where((contact) {
          return contact.publicKey.length >=
                  message.recipientPublicKey!.length &&
              contact.publicKey.matches(message.recipientPublicKey!);
        }).firstOrNull;
      } else if (message.senderPublicKeyPrefix != null &&
          message.senderPublicKeyPrefix!.length >= 6) {
        destinationContact = contactsProvider.findContactByPrefix(
          message.senderPublicKeyPrefix!,
        );
      }

      if (destinationContact != null) {
        messagesProvider.navigateToDestination(
          destinationContact.isRoom
              ? MessageDestinationPreferences.destinationTypeRoom
              : MessageDestinationPreferences.destinationTypeContact,
          recipientPublicKeyHex: destinationContact.publicKeyHex,
        );
      }
    }

    messagesProvider.navigateToMessage(message.id);
    widget.onNavigateToMessages?.call();
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
        onSend:
            (
              emoji,
              name,
              position,
              roomPublicKey,
              sendToChannel,
              sendToAllContacts,
              colorIndex,
            ) async {
              await _sendSarMessage(
                emoji,
                name,
                position,
                roomPublicKey,
                sendToChannel,
                sendToAllContacts,
                colorIndex,
              );
            },
      ),
    );
  }

  Future<void> _sendSarMessage(
    String emoji,
    String name,
    Position position,
    Uint8List? roomPublicKey,
    bool sendToChannel,
    bool sendToAllContacts,
    int colorIndex,
  ) async {
    final sarMessage = SarMessageParser.createSarMessage(
      type: SarMarkerType.fromEmoji(emoji),
      location: LatLng(position.latitude, position.longitude),
      notes: name,
      colorIndex: colorIndex,
    );

    await _sendSarPayload(
      sarMessage: sarMessage,
      roomPublicKey: roomPublicKey,
      sendToChannel: sendToChannel,
      sendToAllContacts: sendToAllContacts,
    );
  }

  Future<void> _sendCustomMapSarMessage(
    String emoji,
    String name,
    LatLng storedPoint,
    String mapId,
    Uint8List? roomPublicKey,
    bool sendToChannel,
    bool sendToAllContacts,
    int colorIndex,
  ) async {
    final sarMessage = SarMessageParser.createCustomMapSarMessage(
      emoji: emoji,
      mapId: mapId,
      point: storedPoint,
      notes: name,
      colorIndex: colorIndex,
    );

    await _sendSarPayload(
      sarMessage: sarMessage,
      roomPublicKey: roomPublicKey,
      sendToChannel: sendToChannel,
      sendToAllContacts: sendToAllContacts,
    );
  }

  Future<void> _sendSarPayload({
    required String sarMessage,
    required Uint8List? roomPublicKey,
    required bool sendToChannel,
    required bool sendToAllContacts,
  }) async {
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

    if (!sendToChannel && !sendToAllContacts && roomPublicKey == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination to send SAR marker'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (sendToAllContacts) {
        final contactsProvider = context.read<ContactsProvider>();
        final chatContacts = contactsProvider.chatContacts;

        if (chatContacts.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noContactsAvailable),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final groupId = '${DateTime.now().millisecondsSinceEpoch}_group';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        final recipients = chatContacts.map((contact) {
          return MessageRecipient(
            publicKey: contact.publicKey,
            displayName: contact.displayName,
            deliveryStatus: MessageDeliveryStatus.sending,
            sentAt: DateTime.now(),
          );
        }).toList();

        final groupedMessage = Message(
          id: groupId,
          messageType: MessageType.contact,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          groupId: groupId,
          recipients: recipients,
        );

        messagesProvider.addSentMessage(groupedMessage);

        int successCount = 0;
        for (final contact in chatContacts) {
          final individualMessageId = '${groupId}_${contact.publicKeyShort}';
          messagesProvider.registerGroupedMessageSend(
            individualMessageId,
            groupId,
            contact.publicKey,
          );

          final sentSuccessfully = await connectionProvider.sendTextMessage(
            contactPublicKey: contact.publicKey,
            text: sarMessage,
            messageId: individualMessageId,
            contact: contact,
          );

          if (sentSuccessfully) {
            successCount++;
          } else {
            messagesProvider.updateGroupedMessageRecipientStatus(
              groupId,
              contact.publicKey,
              MessageDeliveryStatus.failed,
            );
          }

          if (contact != chatContacts.last) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.sarMarkerSentToContacts(successCount),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      if (sendToChannel) {
        final messageId =
            '${DateTime.now().millisecondsSinceEpoch}_channel_sent';
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final devicePublicKey = connectionProvider.deviceInfo.publicKey;
        final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

        final sentMessage = Message(
          id: messageId,
          messageType: MessageType.channel,
          senderPublicKeyPrefix: senderPublicKeyPrefix,
          pathLen: 0,
          textType: MessageTextType.plain,
          senderTimestamp: timestamp,
          text: sarMessage,
          receivedAt: DateTime.now(),
          deliveryStatus: MessageDeliveryStatus.sending,
          channelIdx: 0,
        );

        messagesProvider.addSentMessage(sentMessage);

        await connectionProvider.sendChannelMessage(
          channelIdx: 0,
          text: sarMessage,
          messageId: messageId,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SAR marker broadcast to public channel'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final messageId = '${DateTime.now().millisecondsSinceEpoch}_sent';
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final devicePublicKey = connectionProvider.deviceInfo.publicKey;
      final senderPublicKeyPrefix = devicePublicKey?.sublist(0, 6);

      final sentMessage = Message(
        id: messageId,
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderPublicKeyPrefix,
        pathLen: 0,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp,
        text: sarMessage,
        receivedAt: DateTime.now(),
        deliveryStatus: MessageDeliveryStatus.sending,
        recipientPublicKey: roomPublicKey,
      );

      final contactsProvider = context.read<ContactsProvider>();
      final roomContact = contactsProvider.contacts.where((c) {
        return c.publicKey.length >= roomPublicKey!.length &&
            c.publicKey.matches(roomPublicKey);
      }).firstOrNull;

      messagesProvider.addSentMessage(sentMessage, contact: roomContact);

      final sentSuccessfully = await connectionProvider.sendTextMessage(
        contactPublicKey: roomPublicKey!,
        text: sarMessage,
        messageId: messageId,
        contact: roomContact,
      );

      if (!sentSuccessfully) {
        messagesProvider.markMessageFailed(messageId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SAR marker sent to room'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
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

    return Consumer4<
      ContactsProvider,
      MessagesProvider,
      DrawingProvider,
      MapProvider
    >(
      builder: (context, contactsProvider, messagesProvider, drawingProvider, mapProvider, child) {
        final customMapConfig = mapProvider.customMapConfig;
        final isCustomMapMode =
            mapProvider.isUsingCustomMap && customMapConfig != null;
        if (!isCustomMapMode && _isCalibratingCustomMap) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _stopCustomMapCalibration();
            }
          });
        }
        _syncDrawingContext(drawingProvider, mapProvider);
        _ensureCustomMapViewport(mapProvider, customMapConfig);

        final allContactsWithLocation = contactsProvider.contactsWithLocation;
        final contactsWithLocation = mapProvider.hideRepeatersOnMap
            ? allContactsWithLocation
                  .where((contact) => !contact.isRepeater)
                  .toList()
            : allContactsWithLocation;
        // Filter SAR markers based on visibility toggle
        final allSarMarkers = messagesProvider.sarMarkers;
        final sarMarkers = !drawingProvider.showSarMarkers
            ? <SarMarker>[]
            : isCustomMapMode
            ? allSarMarkers
                  .where(
                    (marker) =>
                        marker.coordinateSpace ==
                            MapCoordinateSpace.customMap &&
                        marker.mapId == customMapConfig.mapId,
                  )
                  .toList()
            : allSarMarkers
                  .where(
                    (marker) =>
                        marker.coordinateSpace == MapCoordinateSpace.geo,
                  )
                  .toList();
        final center = isCustomMapMode
            ? customMapConfig.displayBounds.center
            : _calculateCenter(contactsWithLocation, sarMarkers);
        final pointTransformer = isCustomMapMode
            ? (LatLng point) => _toDisplayMapPoint(customMapConfig, point)
            : null;
        final measurementPoint1 =
            isCustomMapMode && drawingProvider.measurementPoint1 != null
            ? _toDisplayMapPoint(
                customMapConfig,
                drawingProvider.measurementPoint1!,
              )
            : drawingProvider.measurementPoint1;
        final measurementPoint2 =
            isCustomMapMode && drawingProvider.measurementPoint2 != null
            ? _toDisplayMapPoint(
                customMapConfig,
                drawingProvider.measurementPoint2!,
              )
            : drawingProvider.measurementPoint2;
        final calibrationPointA =
            isCustomMapMode && _customMapCalibrationPointA != null
            ? _toDisplayMapPoint(customMapConfig, _customMapCalibrationPointA!)
            : null;
        final calibrationPointB =
            isCustomMapMode && _customMapCalibrationPointB != null
            ? _toDisplayMapPoint(customMapConfig, _customMapCalibrationPointB!)
            : null;

        return Stack(
          children: [
            // Map widget
            Listener(
              onPointerMove: (PointerMoveEvent event) {
                // Track pointer movement for mobile drag (onPointerHover doesn't work on mobile)
                if (_isDraggingPin && !isCustomMapMode) {
                  final latLng = _mapController.camera.screenOffsetToLatLng(
                    event.localPosition,
                  );
                  setState(() {
                    _droppedPinLocation = latLng;
                  });
                }
              },
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  crs: isCustomMapMode
                      ? const CrsSimple()
                      : _currentLayer.crs ?? const Epsg3857(),
                  initialCenter: isCustomMapMode
                      ? center
                      : (_savedMapCenter ?? center),
                  initialZoom: isCustomMapMode
                      ? 0.0
                      : (_savedMapZoom ?? _defaultZoom),
                  initialCameraFit: isCustomMapMode
                      ? CameraFit.bounds(
                          bounds: customMapConfig.displayBounds,
                          padding: const EdgeInsets.all(24),
                        )
                      : null,
                  minZoom: isCustomMapMode ? -4 : 0,
                  maxZoom: isCustomMapMode ? 8 : _currentLayer.maxZoom,
                  cameraConstraint: isCustomMapMode
                      ? CameraConstraint.contain(
                          bounds: customMapConfig.displayBounds,
                        )
                      : const CameraConstraint.unconstrained(),
                  interactionOptions: InteractionOptions(
                    flags: _isDraggingPin && !isCustomMapMode
                        ? InteractiveFlag
                              .none // Disable map interaction while dragging pin
                        : InteractiveFlag.all,
                  ),
                  onMapEvent: (event) {
                    // Save map position when user stops panning/zooming
                    if (event is MapEventMoveEnd ||
                        event is MapEventScrollWheelZoom) {
                      _saveMapPosition();
                    }
                    // Trigger rebuild on rotation change to show/hide reset button
                    if (event is MapEventRotateEnd ||
                        event is MapEventRotateStart) {
                      setState(() {});
                    }
                  },
                  onLongPress: (tapPosition, point) {
                    if (_isCalibratingCustomMap) {
                      return;
                    }

                    final mapPoint = isCustomMapMode
                        ? _toStoredMapPoint(customMapConfig, point)
                        : point;

                    // Handle measurement mode - set measurement points only, no SAR marker
                    if (drawingProvider.drawingMode == DrawingMode.measure) {
                      if (drawingProvider.measurementPoint1 == null) {
                        // Set first measurement point
                        drawingProvider.setMeasurementPoint1(mapPoint);
                      } else if (drawingProvider.measurementPoint2 == null) {
                        // Set second measurement point
                        drawingProvider.setMeasurementPoint2(mapPoint);
                      } else {
                        // Clear and start new measurement
                        drawingProvider.clearMeasurement();
                        drawingProvider.setMeasurementPoint1(mapPoint);
                      }
                      // Don't drop SAR marker pin in measurement mode
                      return;
                    }

                    // Skip if in other drawing modes
                    if (drawingProvider.isDrawing) return;

                    if (isCustomMapMode) {
                      _showCustomMapSarDialogWithPoint(
                        customMapConfig,
                        mapPoint,
                      );
                      return;
                    }

                    // Drop a pin at long press location for SAR marker creation
                    if (_droppedPinLocation == null) {
                      setState(() {
                        _droppedPinLocation = point;
                      });
                    }
                  },
                  onPointerDown: (event, point) {
                    if (isCustomMapMode) {
                      return;
                    }
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
                    final mapPoint = isCustomMapMode
                        ? _toStoredMapPoint(customMapConfig, point)
                        : point;

                    // Update rectangle preview while dragging
                    if (drawingProvider.drawingMode == DrawingMode.rectangle &&
                        drawingProvider.rectangleStartPoint != null) {
                      drawingProvider.updateRectangleEndPoint(mapPoint);
                      return;
                    }

                    // Update pin location while dragging
                    if (_isDraggingPin && !isCustomMapMode) {
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
                    final mapPoint = isCustomMapMode
                        ? _toStoredMapPoint(customMapConfig, point)
                        : point;

                    if (_isCalibratingCustomMap && isCustomMapMode) {
                      _handleCustomMapCalibrationTap(mapProvider, mapPoint);
                      return;
                    }

                    // Handle drawing mode taps
                    if (drawingProvider.drawingMode == DrawingMode.line) {
                      if (drawingProvider.currentLinePoints.isEmpty) {
                        // Start new line
                        drawingProvider.startLine(mapPoint);
                      } else {
                        // Add point to current line
                        drawingProvider.addLinePoint(mapPoint);
                      }
                      return;
                    } else if (drawingProvider.drawingMode ==
                        DrawingMode.rectangle) {
                      if (drawingProvider.rectangleStartPoint == null) {
                        // Start rectangle
                        drawingProvider.startRectangle(mapPoint);
                      } else {
                        // Complete rectangle
                        drawingProvider.completeRectangle(mapPoint);
                      }
                      return;
                    }

                    if (isCustomMapMode) {
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
                  // Render raster or WMS tile layer based on layer type
                  if (isCustomMapMode)
                    OverlayImageLayer(
                      overlayImages: [
                        OverlayImage(
                          bounds: customMapConfig.displayBounds,
                          imageProvider: FileImage(
                            File(customMapConfig.filePath),
                          ),
                        ),
                      ],
                    )
                  else if (_currentLayer.isWms &&
                      _currentLayer.wmsBaseUrl != null &&
                      _currentLayer.crs != null)
                    // WMS Base Layer (e.g., Slovenian Aerial Imagery)
                    flutter_map.TileLayer(
                      wmsOptions: WMSTileLayerOptions(
                        baseUrl: _currentLayer.wmsBaseUrl!,
                        layers: _currentLayer.wmsLayers ?? [],
                        styles: _currentLayer.wmsStyles ?? [],
                        format: _currentLayer.wmsFormat ?? 'image/jpeg',
                        transparent: _currentLayer.wmsTransparent ?? false,
                        crs: _currentLayer.crs!,
                      ),
                      // Use cached tile provider for offline support
                      tileProvider: _tileProvider,
                      userAgentPackageName: 'com.meshcore.sar',
                      maxZoom: _currentLayer.maxZoom,
                      errorTileCallback: (tile, error, stackTrace) {
                        debugPrint(
                          '🔴 WMS Base Layer tile error at ${tile.coordinates}: $error',
                        );
                      },
                    )
                  else if (!_currentLayer.isWms)
                    flutter_map.TileLayer(
                      urlTemplate: _currentLayer.urlTemplate,
                      tileProvider: _tileProvider,
                      userAgentPackageName: 'com.meshcore.sar',
                      maxZoom: _currentLayer.maxZoom,
                    ),
                  if (!isCustomMapMode) ...[
                    // WMS Overlays (rendered after base layer, before polylines)
                    // Note: These overlays only work with EPSG:3794 CRS (Slovenian coordinate system)
                    // Cadastral parcels overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        // Only show if enabled and map is using Slovenian CRS
                        if (!mapProvider.showCadastralOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geowebcache/service/wms?',
                            layers: const ['pregledovalnik:kn_parcele'],
                            styles: const ['parcele'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Cadastral overlay tile error at ${tile.coordinates}: $error',
                            );
                            if (stackTrace != null) {
                              debugPrint('   StackTrace: $stackTrace');
                            }
                          },
                        );
                      },
                    ),
                    // Forest roads overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        // Only show if enabled and map is using Slovenian CRS
                        if (!mapProvider.showForestRoadsOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:gozdne_ceste'],
                            styles: const ['gozdne_ceste'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Forest roads overlay tile error at ${tile.coordinates}: $error',
                            );
                            if (stackTrace != null) {
                              debugPrint('   StackTrace: $stackTrace');
                            }
                          },
                        );
                      },
                    ),
                    // Hiking trails overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showHikingTrailsOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const [
                              'pregledovalnik:KGI_LINIJE_PLANINSKE_POTI_G',
                            ],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Hiking trails overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Main roads overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showMainRoadsOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:KGI_LINIJE_CESTE_G'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Main roads overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // House numbers overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showHouseNumbersOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:NEP_HISNE_STEVILKE'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 House numbers overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Fire hazard zones overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showFireHazardZonesOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:pozarna_ogrozenost'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Fire hazard zones overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Historical fires overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showHistoricalFiresOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:gozdni_pozari'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Historical fires overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Firebreaks overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showFirebreaksOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const [
                              'pregledovalnik:protipozarne_preseke',
                            ],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Firebreaks overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Kras fire zones overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showKrasFireZonesOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:pozarisce_kras'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Kras fire zones overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Place names overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showPlaceNamesOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:zemljepisna_imena'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Place names overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Municipality borders overlay
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (!mapProvider.showMunicipalityBordersOverlay ||
                            _currentLayer.crs == null) {
                          return const SizedBox.shrink();
                        }
                        return flutter_map.TileLayer(
                          wmsOptions: WMSTileLayerOptions(
                            baseUrl:
                                'https://prostor.zgs.gov.si/geoserver/wms?',
                            layers: const ['pregledovalnik:NEP_RPE_OBCINE'],
                            styles: const ['obcine'],
                            format: 'image/png',
                            transparent: true,
                            crs: slovenianCrs,
                          ),
                          tileProvider: _tileProvider,
                          userAgentPackageName: 'com.meshcore.sar',
                          maxZoom: 19,
                          errorTileCallback: (tile, error, stackTrace) {
                            debugPrint(
                              '🔴 Municipality borders overlay tile error at ${tile.coordinates}: $error',
                            );
                          },
                        );
                      },
                    ),
                    // Imported trail layer (rendered at bottom for reference)
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        if (mapProvider.importedTrail == null ||
                            mapProvider.importedTrail!.points.length < 2) {
                          return const SizedBox.shrink();
                        }

                        return PolylineLayer(
                          polylines: [
                            Polyline(
                              points: mapProvider.importedTrail!.latLngPoints,
                              color: Colors.green.withValues(alpha: 0.7),
                              strokeWidth: 3.0,
                              borderColor: Colors.white.withValues(alpha: 0.4),
                              borderStrokeWidth: 1.0,
                              // DOTTED pattern to distinguish from other trails
                              pattern: StrokePattern.dotted(spacingFactor: 2),
                            ),
                          ],
                        );
                      },
                    ),
                    // Contact trail polylines (rendered before user trail and markers)
                    Consumer<MapProvider>(
                      builder: (context, mapProvider, _) {
                        // Determine which contacts to show trails for
                        final contactsToShow = mapProvider.showAllContactTrails
                            ? contactsWithLocation // Show all when master toggle is ON
                            : contactsWithLocation.where(
                                (contact) => mapProvider.isContactPathVisible(
                                  contact.publicKeyHex,
                                ),
                              ); // Individual toggles

                        return PolylineLayer(
                          polylines: contactsToShow
                              .where(
                                (contact) => contact.advertHistory.length >= 2,
                              )
                              .map((contact) {
                                // Use TrailColorService for consistent, emoji-based colors
                                final color = TrailColorService.getTrailColor(
                                  contact,
                                );

                                return Polyline(
                                  points: contact.advertHistory
                                      .map((advert) => advert.location)
                                      .toList(),
                                  color: color.withValues(
                                    alpha: 0.95,
                                  ), // More opaque for better visibility
                                  strokeWidth:
                                      4.5, // Thicker for better visibility on all map backgrounds
                                  borderColor: Colors.white.withValues(
                                    alpha: 0.6,
                                  ), // Stronger border contrast
                                  borderStrokeWidth: 2.0, // Wider border
                                  // DASHED pattern to distinguish from solid user trail
                                  pattern: StrokePattern.dashed(
                                    segments: [8, 4],
                                  ),
                                );
                              })
                              .toList(),
                        );
                      },
                    ),
                    // Location trail layer (rendered after paths, before drawings)
                    const LocationTrailLayer(),
                  ],
                  // Measurement line layer (rendered before drawings)
                  if (measurementPoint1 != null && measurementPoint2 != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [measurementPoint1, measurementPoint2],
                          color: Colors.yellow.withValues(alpha: 0.8),
                          strokeWidth: 3.0,
                          borderColor: Colors.black.withValues(alpha: 0.5),
                          borderStrokeWidth: 1.0,
                          pattern: StrokePattern.dashed(segments: [10, 5]),
                        ),
                      ],
                    ),
                  if (calibrationPointA != null && calibrationPointB != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [calibrationPointA, calibrationPointB],
                          color: Colors.lightBlueAccent.withValues(alpha: 0.9),
                          strokeWidth: 3.0,
                          borderColor: Colors.black.withValues(alpha: 0.35),
                          borderStrokeWidth: 1.0,
                        ),
                      ],
                    ),
                  // Drawing layer (rendered after paths, before markers)
                  DrawingLayer(
                    drawings: drawingProvider.drawings,
                    previewDrawing: drawingProvider.getPreviewDrawing(),
                    pointTransformer: pointTransformer,
                  ),
                  MarkerLayer(
                    markers: [
                      // Contact markers
                      if (!isCustomMapMode)
                        ..._markerService.generateContactMarkers(
                          contacts: contactsWithLocation,
                          context: context,
                          mapRotation: _getMapRotation(),
                          userPosition: _locationService.currentPosition,
                          onTap: (contact) {
                            _showDetailedCompassWithContact(
                              context,
                              contactsWithLocation,
                              sarMarkers,
                              contact,
                            );
                          },
                        ),
                      // SAR markers
                      ..._markerService.generateSarMarkers(
                        sarMarkers: sarMarkers,
                        context: context,
                        mapRotation: _getMapRotation(),
                        pointTransformer: pointTransformer,
                        onTap: (marker) {
                          _showSarMarkerActions(
                            marker,
                            messagesProvider,
                            contactsProvider,
                          );
                        },
                      ),
                      // User location marker with directional pointer
                      if (!isCustomMapMode &&
                          _markerService.generateUserLocationMarker(
                                position: _locationService.currentPosition,
                                heading: _currentHeading,
                                context: context,
                              ) !=
                              null)
                        _markerService.generateUserLocationMarker(
                          position: _locationService.currentPosition,
                          heading: _currentHeading,
                          context: context,
                        )!,
                      // Measurement point 1 marker
                      if (measurementPoint1 != null)
                        Marker(
                          point: measurementPoint1,
                          width: 60,
                          height: 80,
                          rotate: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Start',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Measurement point 2 marker
                      if (measurementPoint2 != null)
                        Marker(
                          point: measurementPoint2,
                          width: 60,
                          height: 80,
                          rotate: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'End',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (calibrationPointA != null)
                        Marker(
                          point: calibrationPointA,
                          width: 60,
                          height: 70,
                          rotate: false,
                          child: _buildTaggedPointMarker(
                            label: 'A',
                            color: Colors.lightBlue,
                          ),
                        ),
                      if (calibrationPointB != null)
                        Marker(
                          point: calibrationPointB,
                          width: 60,
                          height: 70,
                          rotate: false,
                          child: _buildTaggedPointMarker(
                            label: 'B',
                            color: Colors.lightBlue,
                          ),
                        ),
                      // Dropped pin marker with label
                      if (!isCustomMapMode && _droppedPinLocation != null)
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
                                _showSarDialogWithLocation(
                                  _droppedPinLocation!,
                                );
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
                                      color: _isDraggingPin
                                          ? Colors.orange
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _isDraggingPin
                                          ? AppLocalizations.of(
                                              context,
                                            )!.dragToPosition
                                          : AppLocalizations.of(
                                              context,
                                            )!.createSarMarker,
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
                                    color: _isDraggingPin
                                        ? Colors.orange
                                        : Colors.red,
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
                    pointTransformer: pointTransformer,
                    onDeleteDrawing: (drawingId) {
                      drawingProvider.removeDrawing(drawingId);
                    },
                    onTapDrawing: (drawing) {
                      // Navigate to the corresponding message in Messages tab
                      if (drawing.messageId != null) {
                        messagesProvider.navigateToMessage(drawing.messageId!);
                        widget.onNavigateToMessages?.call();
                      }
                    },
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  child: const Icon(Icons.fullscreen_exit),
                ),
              ),
            // Message overlay - right side (only shown in fullscreen mode on large screens)
            if (_isFullscreen && MediaQuery.of(context).size.width >= 800)
              Positioned(
                top: 60,
                bottom: 60,
                right: 16,
                width: 300,
                child: Consumer<MessagesProvider>(
                  builder: (context, messagesProvider, _) {
                    // Get last 20 non-system and non-drawing messages, sorted chronologically
                    final recentMessages =
                        messagesProvider.messages
                            .where((m) => !m.isSystemMessage && !m.isDrawing)
                            .toList()
                          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
                    final displayMessages = recentMessages.length > 20
                        ? recentMessages.sublist(recentMessages.length - 20)
                        : recentMessages;

                    return MapMessageOverlay(
                      messages: displayMessages,
                      onNavigateToMessages: widget.onNavigateToMessages,
                      onMessageTap: (messageId) {
                        messagesProvider.navigateToMessage(messageId);
                        widget.onNavigateToMessages?.call();
                      },
                    );
                  },
                ),
              ),
            // Compass widget - top right (hidden in fullscreen mode)
            if (!_isFullscreen && !isCustomMapMode)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _showDetailedCompass(
                    context,
                    contactsWithLocation,
                    sarMarkers,
                  ),
                  child: CompassWidget(
                    heading: _currentHeading ?? 0,
                    hasHeading: _currentHeading != null,
                  ),
                ),
              ),
            if (isCustomMapMode &&
                !_isFullscreen &&
                drawingProvider.drawingMode != DrawingMode.measure)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.96),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customMapConfig.isCalibrated
                            ? 'Scale set'
                            : 'Not calibrated',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_isCalibratingCustomMap) ...[
                        const SizedBox(height: 4),
                        Text(
                          _customMapCalibrationPointA == null
                              ? 'Tap point A'
                              : _customMapCalibrationPointB == null
                              ? 'Tap point B'
                              : 'Enter distance',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            // Measurement distance overlay
            if (drawingProvider.drawingMode == DrawingMode.measure)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700.withValues(alpha: 0.95),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.straighten,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.measureDistance,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isCustomMapMode) ...[
                        Text(
                          customMapConfig.isCalibrated
                              ? 'Scale set'
                              : 'Set scale in Layers to enable distance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (drawingProvider.measuredDistance != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.distanceLabel(
                                _formatDistance(
                                  drawingProvider.measuredDistance!,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.longPressToStartNewMeasurement,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      else if (drawingProvider.measurementPoint1 != null)
                        Text(
                          AppLocalizations.of(context)!.longPressForSecondPoint,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.longPressToStartMeasurement,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            // Map controls - right side (hidden in fullscreen mode)
            if (!_isFullscreen)
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    const DrawingToolbar(),
                    const SizedBox(height: 8),
                    // Hide other buttons when in drawing mode
                    if (!drawingProvider.isDrawing && !isCustomMapMode) ...[
                      // Current Location - always center to GPS
                      FloatingActionButton.small(
                        heroTag: 'center_map',
                        onPressed: !_isMapReady
                            ? null
                            : () async {
                                // Get current zoom to retain it
                                final currentZoom = _mapController.camera.zoom;

                                // Force update GPS location and jump to it
                                final position = await _locationService
                                    .getCurrentPosition();
                                if (position != null && mounted) {
                                  setState(() {
                                    // Position updated in service
                                  });
                                  _mapController.move(
                                    LatLng(
                                      position.latitude,
                                      position.longitude,
                                    ),
                                    currentZoom,
                                  );
                                } else {
                                  // Fallback to cached position or default center
                                  final currentPosition =
                                      _locationService.currentPosition;
                                  if (currentPosition != null) {
                                    _mapController.move(
                                      LatLng(
                                        currentPosition.latitude,
                                        currentPosition.longitude,
                                      ),
                                      currentZoom,
                                    );
                                  } else {
                                    _mapController.move(center, currentZoom);
                                  }
                                }
                              },
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      // Map Rotation Lock - toggle rotate with heading
                      FloatingActionButton.small(
                        heroTag: 'rotation_lock',
                        backgroundColor: _rotateMarkerWithHeading
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        onPressed: !_isMapReady
                            ? null
                            : () {
                                setState(() {
                                  _rotateMarkerWithHeading =
                                      !_rotateMarkerWithHeading;
                                  // Reset map rotation when disabling
                                  if (_isMapReady) {
                                    try {
                                      final camera = _mapController.camera;
                                      if (!_rotateMarkerWithHeading) {
                                        // Disable: reset to north
                                        _mapController.moveAndRotate(
                                          camera.center,
                                          camera.zoom,
                                          0,
                                        );
                                      } else if (_currentHeading != null) {
                                        // Enable: apply current heading rotation
                                        _mapController.moveAndRotate(
                                          camera.center,
                                          camera.zoom,
                                          -_currentHeading!,
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint(
                                        'Failed to toggle rotation lock: $e',
                                      );
                                    }
                                  }
                                });
                                _saveSettings();
                              },
                        child: Icon(
                          Icons.screen_lock_rotation,
                          color: _rotateMarkerWithHeading ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FloatingActionButton.small(
                      heroTag: 'ruler_tool',
                      backgroundColor:
                          drawingProvider.drawingMode == DrawingMode.measure
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      onPressed: () {
                        if (drawingProvider.drawingMode ==
                            DrawingMode.measure) {
                          drawingProvider.exitDrawingMode();
                        } else {
                          drawingProvider.setDrawingMode(DrawingMode.measure);
                        }
                      },
                      child: Icon(
                        Icons.straighten,
                        color:
                            drawingProvider.drawingMode == DrawingMode.measure
                            ? Colors.white
                            : null,
                      ),
                    ),
                    if (!drawingProvider.isDrawing) const SizedBox(height: 8),
                    // Continue with other buttons when not in drawing mode
                    if (!drawingProvider.isDrawing) ...[
                      // Trail controls button
                      if (!isCustomMapMode) ...[
                        const TrailControls(),
                        const SizedBox(height: 8),
                      ],
                      FloatingActionButton.small(
                        heroTag: 'layer_selector',
                        onPressed: () => _showLayerSelector(context),
                        child: const Icon(Icons.layers),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'fullscreen_toggle',
                        onPressed: () {
                          setState(() {
                            _isFullscreen = !_isFullscreen;
                          });
                          _saveSettings();
                          widget.onFullscreenChanged?.call(_isFullscreen);
                        },
                        child: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
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
