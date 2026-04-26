import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meshcore_client/meshcore_client.dart';
import 'profiles_feature_service.dart';

/// Background location tracking service for SAR operations
/// Tracks user location and sends periodic updates via MeshCore BLE
@pragma('vm:entry-point')
class BackgroundLocationService {
  static const String _prefKeyEnabled = 'background_tracking_enabled';
  static const String _prefKeyDistance = 'background_tracking_distance';
  static const String _prefKeyLastLat = 'background_last_lat';
  static const String _prefKeyLastLon = 'background_last_lon';
  static const String _notificationChannelId =
      'meshcore_sar_background_tracking';
  static const int _notificationId = 9101;

  MeshCoreBleService? _bleService;
  final FlutterBackgroundService _service = FlutterBackgroundService();
  bool _serviceConfigured = false;

  String _scopedKey(String baseKey) {
    return ProfileStorageScope.scopedKey(baseKey);
  }

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
  Future<bool> startTracking({double distanceThreshold = 10.0}) async {
    if (!_isInitialized || _bleService == null) {
      debugPrint(
        '⚠️ [BackgroundLocation] Service not initialized or BLE service null',
      );
      return false;
    }

    if (!_bleService!.isConnected) {
      debugPrint('⚠️ [BackgroundLocation] BLE not connected');
      return false;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ [BackgroundLocation] Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        '⚠️ [BackgroundLocation] Location permission permanently denied',
      );
      return false;
    }

    if (Platform.isIOS && permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        debugPrint(
          '⚠️ [BackgroundLocation] iOS background tracking requires Always permission',
        );
        return false;
      }
    }

    // Save settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scopedKey(_prefKeyEnabled), true);
    await prefs.setDouble(_scopedKey(_prefKeyDistance), distanceThreshold);

    await _startForegroundService(distanceThreshold);

    // Start listening to position updates
    Position? lastPosition;
    try {
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: _buildLocationSettings(
              distanceFilter: distanceThreshold.toInt(),
            ),
          ).listen((Position position) async {
            debugPrint(
              '📍 [BackgroundLocation] New position: ${position.latitude}, ${position.longitude}',
            );

            // Calculate distance from last position
            if (lastPosition != null) {
              final distance = Geolocator.distanceBetween(
                lastPosition!.latitude,
                lastPosition!.longitude,
                position.latitude,
                position.longitude,
              );

              debugPrint(
                '   Distance moved: ${distance.toStringAsFixed(1)}m (threshold: ${distanceThreshold}m)',
              );

              // Skip if haven't moved enough
              if (distance < distanceThreshold) {
                return;
              }
            }

            // Update last position
            lastPosition = position;

            // Save to preferences
            await prefs.setDouble(
              _scopedKey(_prefKeyLastLat),
              position.latitude,
            );
            await prefs.setDouble(
              _scopedKey(_prefKeyLastLon),
              position.longitude,
            );

            // Update device's advertised location
            if (_bleService != null && _bleService!.isConnected) {
              try {
                debugPrint(
                  '📤 [BackgroundLocation] Updating device location...',
                );
                await _bleService!.setAdvertLatLon(
                  latitude: position.latitude,
                  longitude: position.longitude,
                );

                // Send advertisement to mesh network
                debugPrint(
                  '📡 [BackgroundLocation] Broadcasting self advertisement...',
                );
                await _bleService!.sendSelfAdvert(floodMode: true);
                debugPrint(
                  '✅ [BackgroundLocation] Location update sent successfully',
                );
              } catch (e) {
                debugPrint(
                  '❌ [BackgroundLocation] Failed to send location update: $e',
                );
              }
            } else {
              debugPrint(
                '⚠️ [BackgroundLocation] BLE disconnected, cannot send update',
              );
            }
          });

      debugPrint(
        '✅ [BackgroundLocation] Tracking started with ${distanceThreshold}m threshold',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [BackgroundLocation] Failed to start tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    debugPrint('🛑 [BackgroundLocation] Stopping tracking');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _stopForegroundService();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scopedKey(_prefKeyEnabled), false);
    debugPrint('✅ [BackgroundLocation] Tracking stopped');
  }

  Future<void> _startForegroundService(double distanceThreshold) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      if (!_serviceConfigured) {
        await _configureForegroundService();
      }

      final running = await _service.isRunning();
      if (!running) {
        await _service.startService();
      }

      _service.invoke('trackingUpdate', {
        'distanceThreshold': distanceThreshold,
      });
    } catch (e) {
      debugPrint('⚠️ [BackgroundLocation] Foreground service start failed: $e');
    }
  }

  Future<void> _stopForegroundService() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    try {
      if (await _service.isRunning()) {
        _service.invoke('stopService');
      }
    } catch (e) {
      debugPrint('⚠️ [BackgroundLocation] Foreground service stop failed: $e');
    }
  }

  Future<void> _configureForegroundService() async {
    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Background tracking',
      description:
          'Keeps MeshCore SAR location sharing active while the app is in the background.',
      importance: Importance.low,
    );

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: meshCoreSarBackgroundServiceStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'MeshCore SAR',
        initialNotificationContent: 'Maintaining background tracking',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: meshCoreSarBackgroundServiceStart,
        onBackground: meshCoreSarBackgroundServiceIos,
      ),
    );
    _serviceConfigured = true;
  }

  /// Update the distance threshold for location updates
  /// Note: This will restart tracking with the new threshold
  Future<void> updateDistanceThreshold(double distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scopedKey(_prefKeyDistance), distance);
    debugPrint(
      '📏 [BackgroundLocation] Distance threshold updated to ${distance}m',
    );

    // Restart tracking if currently enabled
    final isEnabled = prefs.getBool(_scopedKey(_prefKeyEnabled)) ?? false;
    if (isEnabled && _bleService != null) {
      await stopTracking();
      await startTracking(distanceThreshold: distance);
    }
  }

  LocationSettings _buildLocationSettings({int distanceFilter = 10}) {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: distanceFilter,
    );
  }
}

@pragma('vm:entry-point')
Future<bool> meshCoreSarBackgroundServiceIos(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void meshCoreSarBackgroundServiceStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'MeshCore SAR',
      content: 'Maintaining background tracking',
    );
  }

  service.on('trackingUpdate').listen((event) {
    if (service is AndroidServiceInstance) {
      final threshold = event?['distanceThreshold'];
      final suffix = threshold is num
          ? ' (${threshold.toStringAsFixed(0)} m updates)'
          : '';
      service.setForegroundNotificationInfo(
        title: 'MeshCore SAR',
        content: 'Maintaining background tracking$suffix',
      );
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
