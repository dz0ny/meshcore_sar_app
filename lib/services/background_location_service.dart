import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meshcore_ble_service.dart';

/// Background location tracking service for SAR operations
/// Tracks user location and sends periodic updates via MeshCore BLE
@pragma('vm:entry-point')
class BackgroundLocationService {
  static const String _prefKeyEnabled = 'background_tracking_enabled';
  static const String _prefKeyDistance = 'background_tracking_distance';
  static const String _prefKeyLastLat = 'background_last_lat';
  static const String _prefKeyLastLon = 'background_last_lon';

  MeshCoreBleService? _bleService;
  bool _isInitialized = false;
  StreamSubscription<Position>? _positionSubscription;

  /// Initialize the service with BLE service reference
  void initialize(MeshCoreBleService bleService) {
    _bleService = bleService;
    _isInitialized = true;
  }

  /// Start location tracking and automatic advertisement
  /// Returns true if successful, false otherwise
  ///
  /// Note: This is foreground tracking. For true background operation,
  /// additional platform-specific configuration is required.
  Future<bool> startTracking({double distanceThreshold = 10.0}) async {
    if (!_isInitialized || _bleService == null) {
      print('⚠️ [BackgroundLocation] Service not initialized or BLE service null');
      return false;
    }

    if (!_bleService!.isConnected) {
      print('⚠️ [BackgroundLocation] BLE not connected');
      return false;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ [BackgroundLocation] Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('⚠️ [BackgroundLocation] Location permission permanently denied');
      return false;
    }

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, true);
    await prefs.setDouble(_prefKeyDistance, distanceThreshold);

    // Start listening to position updates
    Position? lastPosition;
    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: distanceThreshold.toInt(),
        ),
      ).listen((Position position) async {
        print('📍 [BackgroundLocation] New position: ${position.latitude}, ${position.longitude}');

        // Calculate distance from last position
        if (lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            lastPosition!.latitude,
            lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          print('   Distance moved: ${distance.toStringAsFixed(1)}m (threshold: ${distanceThreshold}m)');

          // Skip if haven't moved enough
          if (distance < distanceThreshold) {
            return;
          }
        }

        // Update last position
        lastPosition = position;

        // Save to preferences
        await prefs.setDouble(_prefKeyLastLat, position.latitude);
        await prefs.setDouble(_prefKeyLastLon, position.longitude);

        // Update device's advertised location
        if (_bleService != null && _bleService!.isConnected) {
          try {
            print('📤 [BackgroundLocation] Updating device location...');
            await _bleService!.setAdvertLatLon(
              latitude: position.latitude,
              longitude: position.longitude,
            );

            // Send advertisement to mesh network
            print('📡 [BackgroundLocation] Broadcasting self advertisement...');
            await _bleService!.sendSelfAdvert(floodMode: true);
            print('✅ [BackgroundLocation] Location update sent successfully');
          } catch (e) {
            print('❌ [BackgroundLocation] Failed to send location update: $e');
          }
        } else {
          print('⚠️ [BackgroundLocation] BLE disconnected, cannot send update');
        }
      });

      print('✅ [BackgroundLocation] Tracking started with ${distanceThreshold}m threshold');
      return true;
    } catch (e) {
      print('❌ [BackgroundLocation] Failed to start tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    print('🛑 [BackgroundLocation] Stopping tracking');
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, false);
    print('✅ [BackgroundLocation] Tracking stopped');
  }

  /// Update the distance threshold for location updates
  /// Note: This will restart tracking with the new threshold
  Future<void> updateDistanceThreshold(double distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKeyDistance, distance);
    print('📏 [BackgroundLocation] Distance threshold updated to ${distance}m');

    // Restart tracking if currently enabled
    final isEnabled = prefs.getBool(_prefKeyEnabled) ?? false;
    if (isEnabled && _bleService != null) {
      await stopTracking();
      await startTracking(distanceThreshold: distance);
    }
  }
}
