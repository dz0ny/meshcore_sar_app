import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meshcore_ble_service.dart';

/// Centralized location tracking service for MeshCore SAR
///
/// Handles GPS tracking, distance thresholds, background updates,
/// and location broadcasting to the mesh network.
///
/// Features:
/// - Singleton pattern for app-wide access
/// - Configurable distance thresholds (min/max)
/// - Configurable time intervals
/// - Permission handling
/// - SharedPreferences persistence
/// - MeshCore mesh network integration
/// - Real-time position updates via callbacks
class LocationTrackingService {
  // ============================================================================
  // Singleton Pattern
  // ============================================================================

  static final LocationTrackingService _instance =
      LocationTrackingService._internal();

  /// Get the singleton instance
  factory LocationTrackingService() => _instance;

  LocationTrackingService._internal();

  // ============================================================================
  // SharedPreferences Keys
  // ============================================================================

  static const String _prefKeyEnabled = 'background_tracking_enabled';
  static const String _prefKeyMinDistance = 'map_gps_min_distance';
  static const String _prefKeyMaxDistance = 'map_gps_max_distance';
  static const String _prefKeyMinTimeInterval = 'map_gps_min_time_interval';
  static const String _prefKeyGpsUpdateDistance = 'map_gps_update_distance';
  static const String _prefKeyLastLat = 'background_last_lat';
  static const String _prefKeyLastLon = 'background_last_lon';

  // ============================================================================
  // Configuration Properties
  // ============================================================================

  /// Minimum distance in meters before broadcasting update
  double minDistanceMeters = 5.0;

  /// Maximum distance in meters that forces a broadcast regardless of time
  double maxDistanceMeters = 100.0;

  /// Minimum time interval in seconds between broadcasts
  int minTimeIntervalSeconds = 30;

  /// GPS update distance filter for position stream
  double gpsUpdateDistance = 10.0;

  // ============================================================================
  // State Properties
  // ============================================================================

  /// Current GPS position
  Position? currentPosition;

  /// Last position that was broadcast to mesh network
  Position? _lastBroadcastPosition;

  /// Timestamp of last broadcast
  DateTime? _lastBroadcastTime;

  /// Whether tracking is currently active
  bool isTracking = false;

  /// Whether service has been initialized with BLE service
  bool _isInitialized = false;

  /// Whether the first stable position has been set (without broadcast)
  bool _firstPositionSet = false;

  // ============================================================================
  // Private Properties
  // ============================================================================

  /// Reference to MeshCore BLE service for broadcasting
  MeshCoreBleService? _bleService;

  /// Position stream subscription
  StreamSubscription<Position>? _positionSubscription;

  // ============================================================================
  // Callback Properties
  // ============================================================================

  /// Called when position is updated
  void Function(Position)? onPositionUpdate;

  /// Called when an error occurs
  void Function(String error)? onError;

  /// Called when a location broadcast is sent to mesh network
  void Function(Position)? onBroadcastSent;

  /// Called when tracking state changes
  void Function(bool isTracking)? onTrackingStateChanged;

  // ============================================================================
  // Initialization
  // ============================================================================

  /// Initialize the service with MeshCore BLE service reference
  ///
  /// Must be called before starting tracking.
  Future<bool> initialize(MeshCoreBleService bleService) async {
    _bleService = bleService;
    _isInitialized = true;

    // Load saved settings
    await loadSettings();

    debugPrint('✅ [LocationTracking] Service initialized');
    return true;
  }

  // ============================================================================
  // Permission Handling
  // ============================================================================

  /// Check if location permissions are granted
  Future<bool> checkPermissions() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permissions from user
  ///
  /// Returns true if granted, false otherwise.
  Future<bool> requestPermissions() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError?.call('Location services are disabled');
      return false;
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError?.call('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      onError?.call(
        'Location permission permanently denied. Please enable in settings.',
      );
      return false;
    }

    debugPrint('✅ [LocationTracking] Location permissions granted');
    return true;
  }

  // ============================================================================
  // GPS Position Methods
  // ============================================================================

  /// Get current GPS position
  ///
  /// Returns null if position unavailable or permissions denied.
  /// [timeLimit] - Maximum time to wait for position (default: 15 seconds)
  /// [retryCount] - Number of retry attempts (default: 2)
  Future<Position?> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 15),
    int retryCount = 2,
  }) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('🔄 [LocationTracking] Retry attempt $attempt/$retryCount');
          // Exponential backoff: wait 2^attempt seconds before retry
          await Future.delayed(Duration(seconds: 1 << attempt));
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: timeLimit,
          ),
        );

        currentPosition = position;
        if (attempt > 0) {
          debugPrint('✅ [LocationTracking] Position acquired after $attempt retries');
        }
        return position;
      } catch (e) {
        final isLastAttempt = attempt == retryCount;
        if (isLastAttempt) {
          debugPrint('❌ [LocationTracking] Failed to get position after $retryCount retries: $e');
          // Only call error callback on final failure, and make it user-friendly
          if (e.toString().contains('TimeoutException')) {
            onError?.call('GPS signal weak. Position stream will continue trying...');
          } else {
            onError?.call('Failed to get GPS position. Check device settings.');
          }
        } else {
          debugPrint('⚠️ [LocationTracking] Position attempt $attempt failed: $e');
        }

        if (isLastAttempt) {
          return null;
        }
      }
    }
    return null;
  }

  /// Get position stream with configurable distance filter
  ///
  /// [distanceFilter] - Minimum distance in meters between position updates
  Stream<Position> getPositionStream({double distanceFilter = 10.0}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilter.toInt(),
      ),
    );
  }

  // ============================================================================
  // Tracking Control
  // ============================================================================

  /// Start location tracking
  ///
  /// [distanceThreshold] - GPS update distance filter
  ///
  /// Returns true if successful, false otherwise.
  /// Note: This method returns immediately after starting the position stream.
  /// Initial position acquisition happens asynchronously in the background.
  ///
  /// GPS tracking works WITHOUT BLE connection - device broadcasts are simply skipped.
  Future<bool> startTracking({double? distanceThreshold}) async {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ [LocationTracking] Service not initialized',
      );
      onError?.call('Location tracking service not initialized');
      return false;
    }

    // Allow tracking without BLE connection - broadcasts will be skipped
    if (_bleService == null || !_bleService!.isConnected) {
      debugPrint('ℹ️ [LocationTracking] Starting GPS tracking without BLE connection (broadcasts disabled)');
    }

    // Check permissions
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      return false;
    }

    // Use provided threshold or current setting
    final threshold = distanceThreshold ?? gpsUpdateDistance;
    gpsUpdateDistance = threshold;

    // Save settings
    await saveSettings();

    // Try to get initial position in background (non-blocking)
    // This will populate currentPosition but won't block tracking startup
    getCurrentPosition(
      timeLimit: const Duration(seconds: 10),
      retryCount: 1,
    ).then((position) {
      if (position != null) {
        debugPrint('✅ [LocationTracking] Initial position acquired in background');
      }
    }).catchError((error) {
      debugPrint('⚠️ [LocationTracking] Background initial position failed: $error');
      // Not critical - position stream will eventually provide position
    });

    // Start position stream immediately (don't wait for initial position)
    try {
      _positionSubscription = getPositionStream(distanceFilter: threshold)
          .listen(
            _handlePositionUpdate,
            onError: (error) {
              debugPrint('❌ [LocationTracking] Position stream error: $error');
              onError?.call('GPS stream error. Retrying...');
            },
          );

      isTracking = true;
      onTrackingStateChanged?.call(true);

      debugPrint(
        '✅ [LocationTracking] Tracking started with ${threshold}m threshold',
      );
      debugPrint('📡 [LocationTracking] Waiting for GPS signal...');
      return true;
    } catch (e) {
      debugPrint('❌ [LocationTracking] Failed to start tracking: $e');
      onError?.call('Failed to start GPS tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    debugPrint('🛑 [LocationTracking] Stopping tracking');

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    isTracking = false;
    onTrackingStateChanged?.call(false);

    // Reset first position flag so next connection starts fresh
    _firstPositionSet = false;

    // Save disabled state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, false);

    debugPrint('✅ [LocationTracking] Tracking stopped');
  }

  /// Update the distance threshold and restart tracking if active
  Future<void> updateDistanceThreshold(double meters) async {
    gpsUpdateDistance = meters;
    await saveSettings();

    debugPrint(
      '📏 [LocationTracking] Distance threshold updated to ${meters}m',
    );

    // Restart tracking if currently active
    if (isTracking) {
      await stopTracking();
      await startTracking(distanceThreshold: meters);
    }
  }

  // ============================================================================
  // Position Update Handler
  // ============================================================================

  /// Handle incoming position updates from GPS stream
  void _handlePositionUpdate(Position position) {
    debugPrint(
      '📍 [LocationTracking] New position: ${position.latitude}, ${position.longitude}',
    );

    // Update current position
    currentPosition = position;

    // Notify listeners
    onPositionUpdate?.call(position);

    // SPECIAL CASE: First stable position after connection
    // Set lat/lon on device WITHOUT broadcasting to mesh network
    if (!_firstPositionSet) {
      _setInitialPosition(position);
      return;
    }

    // Check if we should broadcast to mesh network
    _checkAndBroadcast(position);
  }

  /// Set initial position on device without broadcasting
  ///
  /// Called only for the first stable GPS position after connection starts.
  /// Updates the device's advertised lat/lon but does NOT send an advertisement.
  void _setInitialPosition(Position position) async {
    if (_bleService == null || !_bleService!.isConnected) {
      debugPrint('⚠️ [LocationTracking] Cannot set initial position: BLE not connected');
      return;
    }

    try {
      debugPrint('📍 [LocationTracking] Setting initial position (no broadcast)');

      // Update device's advertised location WITHOUT sending advertisement
      await _bleService!.setAdvertLatLon(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Mark first position as set
      _firstPositionSet = true;

      // Update last broadcast position to prevent immediate broadcast on next update
      _lastBroadcastPosition = position;
      _lastBroadcastTime = DateTime.now();

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyLastLat, position.latitude);
      await prefs.setDouble(_prefKeyLastLon, position.longitude);

      debugPrint('✅ [LocationTracking] Initial position set without broadcast');
      debugPrint('   Next broadcast allowed in ${minTimeIntervalSeconds}s');
    } catch (e) {
      debugPrint('⚠️ [LocationTracking] Failed to set initial position: $e');
      debugPrint('   Will retry on next GPS update');
      // Don't mark as set on failure, so it will retry on next update
      // Don't call onError - this is not critical since it will retry automatically
    }
  }

  /// Check if position should be broadcast based on distance and time thresholds
  void _checkAndBroadcast(Position position) {
    // If never broadcast before, do it now
    if (_lastBroadcastPosition == null || _lastBroadcastTime == null) {
      _broadcastPosition(position);
      return;
    }

    // Calculate time since last broadcast
    final timeSinceLastBroadcast = DateTime.now().difference(
      _lastBroadcastTime!,
    );
    final secondsSinceLastBroadcast = timeSinceLastBroadcast.inSeconds;

    // Calculate distance from last broadcast position
    final distanceFromLastBroadcast = Geolocator.distanceBetween(
      _lastBroadcastPosition!.latitude,
      _lastBroadcastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    debugPrint(
      '   Distance from last broadcast: ${distanceFromLastBroadcast.toStringAsFixed(1)}m',
    );
    debugPrint('   Time since last broadcast: ${secondsSinceLastBroadcast}s');

    // Broadcast if moved beyond max distance threshold
    if (distanceFromLastBroadcast >= maxDistanceMeters) {
      debugPrint(
        '   📤 Triggering broadcast: exceeded max distance (${maxDistanceMeters}m)',
      );
      _broadcastPosition(position);
      return;
    }

    // Broadcast if minimum time interval passed AND moved beyond min distance
    if (secondsSinceLastBroadcast >= minTimeIntervalSeconds &&
        distanceFromLastBroadcast >= minDistanceMeters) {
      debugPrint(
        '   📤 Triggering broadcast: exceeded min time (${minTimeIntervalSeconds}s) and min distance (${minDistanceMeters}m)',
      );
      _broadcastPosition(position);
      return;
    }

    debugPrint('   ⏸️ Not broadcasting: thresholds not met');
  }

  // ============================================================================
  // Mesh Network Broadcasting
  // ============================================================================

  /// Broadcast position to mesh network via BLE
  void _broadcastPosition(Position position) async {
    if (_bleService == null || !_bleService!.isConnected) {
      debugPrint('⚠️ [LocationTracking] Cannot broadcast: BLE not connected');
      return;
    }

    // CRITICAL: Enforce minimum time between broadcasts to prevent mesh flooding
    // This protects the mesh network from being overwhelmed by position updates
    if (_lastBroadcastTime != null) {
      final timeSinceLastBroadcast = DateTime.now().difference(_lastBroadcastTime!);
      if (timeSinceLastBroadcast.inSeconds < minTimeIntervalSeconds) {
        debugPrint(
          '⏸️ [LocationTracking] Skipping broadcast: only ${timeSinceLastBroadcast.inSeconds}s since last broadcast (minimum: ${minTimeIntervalSeconds}s)',
        );
        return;
      }
    }

    try {
      debugPrint('📤 [LocationTracking] Broadcasting position to mesh network');

      // Update device's advertised location
      await _bleService!.setAdvertLatLon(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Send advertisement to mesh network (only ONE advert per position update)
      await _bleService!.sendSelfAdvert(floodMode: true);

      // Update broadcast tracking IMMEDIATELY to prevent duplicate broadcasts
      _lastBroadcastPosition = position;
      _lastBroadcastTime = DateTime.now();

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefKeyLastLat, position.latitude);
      await prefs.setDouble(_prefKeyLastLon, position.longitude);

      debugPrint('✅ [LocationTracking] Position broadcast successful');
      debugPrint('   Next broadcast allowed in ${minTimeIntervalSeconds}s');
      onBroadcastSent?.call(position);
    } catch (e) {
      debugPrint('❌ [LocationTracking] Failed to broadcast position: $e');
      onError?.call('Failed to broadcast position: $e');
    }
  }

  /// Manually broadcast current location immediately
  ///
  /// Useful for "Send Location Now" button functionality.
  /// Note: Manual broadcasts bypass automatic throttling and can be sent anytime.
  /// However, they still update the last broadcast time to maintain proper spacing
  /// for subsequent automatic broadcasts.
  Future<bool> broadcastLocationNow() async {
    if (!_isInitialized || _bleService == null) {
      onError?.call('Location tracking service not initialized');
      return false;
    }

    if (!_bleService!.isConnected) {
      onError?.call('Not connected to mesh device');
      return false;
    }

    try {
      // Get current position
      final position = await getCurrentPosition();
      if (position == null) {
        onError?.call('Failed to get current position');
        return false;
      }

      debugPrint('📤 [LocationTracking] Manual broadcast requested');

      // Broadcast regardless of automatic throttling thresholds
      await _bleService!.setAdvertLatLon(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _bleService!.sendSelfAdvert(floodMode: true);

      // Update broadcast tracking to maintain proper spacing for automatic broadcasts
      _lastBroadcastPosition = position;
      _lastBroadcastTime = DateTime.now();

      debugPrint('✅ [LocationTracking] Manual broadcast successful');
      debugPrint('   Automatic broadcasts will resume after ${minTimeIntervalSeconds}s');
      onBroadcastSent?.call(position);

      return true;
    } catch (e) {
      debugPrint('❌ [LocationTracking] Manual broadcast failed: $e');
      onError?.call('Failed to broadcast location: $e');
      return false;
    }
  }

  // ============================================================================
  // Settings Persistence
  // ============================================================================

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    minDistanceMeters = prefs.getDouble(_prefKeyMinDistance) ?? 5.0;
    maxDistanceMeters = prefs.getDouble(_prefKeyMaxDistance) ?? 100.0;
    minTimeIntervalSeconds = prefs.getInt(_prefKeyMinTimeInterval) ?? 30;
    gpsUpdateDistance = prefs.getDouble(_prefKeyGpsUpdateDistance) ?? 10.0;

    // Load last broadcast position if available
    final lastLat = prefs.getDouble(_prefKeyLastLat);
    final lastLon = prefs.getDouble(_prefKeyLastLon);
    if (lastLat != null && lastLon != null) {
      _lastBroadcastPosition = Position(
        latitude: lastLat,
        longitude: lastLon,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    debugPrint('✅ [LocationTracking] Settings loaded');
    debugPrint('    Min distance: ${minDistanceMeters}m');
    debugPrint('    Max distance: ${maxDistanceMeters}m');
    debugPrint('    Min time interval: ${minTimeIntervalSeconds}s');
    debugPrint('    GPS update distance: ${gpsUpdateDistance}m');
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_prefKeyMinDistance, minDistanceMeters);
    await prefs.setDouble(_prefKeyMaxDistance, maxDistanceMeters);
    await prefs.setInt(_prefKeyMinTimeInterval, minTimeIntervalSeconds);
    await prefs.setDouble(_prefKeyGpsUpdateDistance, gpsUpdateDistance);
    await prefs.setBool(_prefKeyEnabled, isTracking);

    debugPrint('✅ [LocationTracking] Settings saved');
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  /// Dispose resources and cleanup
  void dispose() {
    debugPrint('🗑️ [LocationTracking] Disposing service');
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _bleService = null;
    _isInitialized = false;
    isTracking = false;
  }
}
