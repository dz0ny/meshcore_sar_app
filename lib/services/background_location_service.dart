import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meshcore_ble_service.dart';

/// Background location tracking service for SAR operations
/// Tracks user location and sends periodic updates via MeshCore BLE
class BackgroundLocationService {
  static const String _prefKeyEnabled = 'background_tracking_enabled';
  static const String _prefKeyDistance = 'background_tracking_distance';

  MeshCoreBleService? _bleService;
  bool _isInitialized = false;

  /// Initialize the service with BLE service reference
  void initialize(MeshCoreBleService bleService) {
    _bleService = bleService;
    _isInitialized = true;
  }

  /// Start background location tracking
  /// Returns true if successful, false otherwise
  Future<bool> startTracking({double distanceThreshold = 10.0}) async {
    if (!_isInitialized || _bleService == null) {
      return false;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, true);
    await prefs.setDouble(_prefKeyDistance, distanceThreshold);

    // Initialize background service if not already running
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (!isRunning) {
      await _initializeBackgroundService();
    }

    // Start the service
    await service.startService();

    return true;
  }

  /// Stop background location tracking
  Future<void> stopTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, false);

    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  /// Update the distance threshold for location updates
  void updateDistanceThreshold(double distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKeyDistance, distance);

    final service = FlutterBackgroundService();
    service.invoke('updateDistance', {'distance': distance});
  }

  /// Initialize the background service
  Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: _onStart,
        isForegroundMode: true,
        autoStartOnBoot: false,
      ),
    );
  }

  /// iOS background entry point
  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Ensure Flutter binding is initialized
    DartPluginRegistrant.ensureInitialized();

    Position? lastPosition;
    StreamSubscription<Position>? positionSubscription;
    double distanceThreshold = 10.0;

    // Load settings
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKeyEnabled) ?? false;
    distanceThreshold = prefs.getDouble(_prefKeyDistance) ?? 10.0;

    if (!enabled) {
      service.stopSelf();
      return;
    }

    // Start location tracking
    try {
      positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: distanceThreshold.toInt(),
        ),
      ).listen((Position position) async {
        // Calculate distance from last position
        if (lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            lastPosition!.latitude,
            lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          // Only update if moved enough distance
          if (distance < distanceThreshold) {
            return;
          }
        }

        // Store last position
        lastPosition = position;

        // Note: In a real implementation, we would need to communicate with
        // the BLE service via isolate communication or shared storage.
        // For now, this is a placeholder for the background tracking logic.

        // Send location update via notification or data channel
        service.invoke('location', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': position.timestamp.millisecondsSinceEpoch,
        });
      });
    } catch (e) {
      service.stopSelf();
      return;
    }

    // Listen for service commands
    service.on('stop').listen((event) async {
      await positionSubscription?.cancel();
      service.stopSelf();
    });

    service.on('updateDistance').listen((event) {
      if (event != null && event['distance'] != null) {
        distanceThreshold = event['distance'] as double;
      }
    });
  }
}
