import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/sar_marker.dart';
import '../l10n/app_localizations.dart';

/// Notification Service - manages urgent notifications for SAR messages
/// Provides critical alert functionality for SAR marker events
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _permissionGranted = false;

  // Notification IDs
  static const int _sarNotificationId = 1000;
  static const int _messageNotificationId = 2000;

  // Notification channels
  static const String _urgentChannelId = 'sar_urgent';
  static const String _urgentChannelName = 'SAR Urgent Alerts';
  static const String _urgentChannelDescription =
      'Critical alerts for SAR markers (found persons, fires, staging areas)';

  static const String _messagesChannelId = 'messages';
  static const String _messagesChannelName = 'Messages';
  static const String _messagesChannelDescription =
      'Notifications for incoming messages from contacts and channels';

  /// Initialize notification service
  /// Following best practices: set all permission requests to false during init,
  /// then request permissions explicitly via requestPermissions() method.
  /// This approach is recommended for iOS (all supported versions) and macOS 10.14+.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📬 [NotificationService] Initializing...');

      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings - set all permissions to false
      // Permissions will be requested later via requestPermissions()
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // macOS initialization settings - set all permissions to false
      // Permissions will be requested later via requestPermissions()
      const macOSSettings = MacOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Combined initialization settings
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: macOSSettings,
      );

      // Initialize plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Request permissions at the appropriate point (after initialization)
      await _requestPermissions();

      // Create notification channels (Android)
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('✅ [NotificationService] Initialized successfully');
      debugPrint('   Permission granted: $_permissionGranted');
    } catch (e) {
      debugPrint('❌ [NotificationService] Initialization error: $e');
    }
  }

  /// Request notification permissions
  /// Uses platform-specific implementations for iOS and macOS as recommended.
  /// For iOS: Uses IOSFlutterLocalNotificationsPlugin.requestPermissions()
  /// For macOS: Uses MacOSFlutterLocalNotificationsPlugin.requestPermissions()
  /// For Android: Uses AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()
  Future<void> _requestPermissions() async {
    try {
      // iOS permissions - request at appropriate point after initialization
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical:
              true, // Request critical alert permission for urgent SAR notifications
        );
        _permissionGranted = granted ?? false;
        debugPrint(
          '📱 [NotificationService] iOS permissions granted: $_permissionGranted',
        );
        return; // Exit early if on iOS
      }

      // macOS permissions - request at appropriate point after initialization
      final macOSPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macOSPlugin != null) {
        final granted = await macOSPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical:
              true, // Request critical alert permission for urgent SAR notifications
        );
        _permissionGranted = granted ?? false;
        debugPrint(
          '💻 [NotificationService] macOS permissions granted: $_permissionGranted',
        );
        return; // Exit early if on macOS
      }

      // Android 13+ permissions
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        _permissionGranted = granted ?? false;
        debugPrint(
          '🤖 [NotificationService] Android permissions granted: $_permissionGranted',
        );
        return; // Exit early if on Android
      }

      // If neither platform plugin is available, assume permissions are granted
      // This handles older Android versions that don't require runtime permissions
      _permissionGranted = true;
      debugPrint(
        '✅ [NotificationService] No platform plugin found, assuming permissions granted',
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error requesting permissions: $e');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin == null) return;

      // Urgent SAR channel with maximum priority
      const urgentChannel = AndroidNotificationChannel(
        _urgentChannelId,
        _urgentChannelName,
        description: _urgentChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      // Messages channel with high priority
      const messagesChannel = AndroidNotificationChannel(
        _messagesChannelId,
        _messagesChannelName,
        description: _messagesChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(urgentChannel);
      await androidPlugin.createNotificationChannel(messagesChannel);
      debugPrint('✅ [NotificationService] Created notification channels');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error creating channels: $e');
    }
  }

  /// Handle notification tap (foreground)
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '🔔 [NotificationService] Notification tapped: ${response.payload}',
    );
    // TODO: Navigate to map tab and show SAR marker
    // This would require a callback to the app layer
  }

  /// Show urgent notification for SAR marker
  Future<void> showSarNotification({
    required SarMarkerType type,
    required String senderName,
    required String coordinates,
    String? notes,
    AppLocalizations? localizations,
  }) async {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ [NotificationService] Not initialized, skipping notification',
      );
      return;
    }

    if (!_permissionGranted) {
      debugPrint(
        '⚠️ [NotificationService] Permission not granted, skipping notification',
      );
      return;
    }

    try {
      // Generate unique notification ID based on timestamp
      final notificationId =
          _sarNotificationId + (DateTime.now().millisecondsSinceEpoch % 1000);

      // Build notification title and body
      final title = _buildNotificationTitle(type, localizations);
      final body = _buildNotificationBody(
        type: type,
        senderName: senderName,
        coordinates: coordinates,
        notes: notes,
        localizations: localizations,
      );

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        _urgentChannelId,
        _urgentChannelName,
        channelDescription: _urgentChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: title,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: Color(_getNotificationColor(type)),
        colorized: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        category: AndroidNotificationCategory.alarm, // High priority category
        fullScreenIntent: true, // Show as full screen on some devices
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: _getSummaryText(type, localizations),
        ),
      );

      // iOS notification details
      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        threadIdentifier: 'sar_markers',
        categoryIdentifier: 'SAR_ALERT',
        interruptionLevel:
            InterruptionLevel.critical, // Critical alert (bypasses silent mode)
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Show notification
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'sar:${type.name}:$coordinates',
      );

      debugPrint('✅ [NotificationService] Showed SAR notification: $title');
      debugPrint('   Type: ${type.displayName}');
      debugPrint('   Sender: $senderName');
      debugPrint('   Coordinates: $coordinates');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error showing notification: $e');
    }
  }

  /// Build notification title based on SAR marker type
  String _buildNotificationTitle(
    SarMarkerType type,
    AppLocalizations? localizations,
  ) {
    if (localizations == null) {
      return '🚨 ${type.displayName} Detected';
    }

    switch (type) {
      case SarMarkerType.foundPerson:
        return '🚨 ${localizations.sarMarkerFoundPerson}';
      case SarMarkerType.fire:
        return '🚨 ${localizations.sarMarkerFire}';
      case SarMarkerType.stagingArea:
        return '🚨 ${localizations.sarMarkerStagingArea}';
      case SarMarkerType.object:
        return '🚨 ${localizations.sarMarkerObject}';
      case SarMarkerType.unknown:
        return '🚨 SAR Alert';
    }
  }

  /// Build notification body with all details
  String _buildNotificationBody({
    required SarMarkerType type,
    required String senderName,
    required String coordinates,
    String? notes,
    AppLocalizations? localizations,
  }) {
    final buffer = StringBuffer();

    // Sender
    if (localizations != null) {
      buffer.write('${localizations.from}: $senderName\n');
      buffer.write('${localizations.coordinates}: $coordinates');
    } else {
      buffer.write('From: $senderName\n');
      buffer.write('Coordinates: $coordinates');
    }

    // Optional notes
    if (notes != null && notes.isNotEmpty) {
      buffer.write('\n\n$notes');
    }

    return buffer.toString();
  }

  /// Get summary text for notification
  String _getSummaryText(SarMarkerType type, AppLocalizations? localizations) {
    if (localizations == null) {
      return 'Tap to view on map';
    }
    return localizations.tapToViewOnMap;
  }

  /// Get notification color based on SAR marker type
  int _getNotificationColor(SarMarkerType type) {
    // Return ARGB color codes
    switch (type) {
      case SarMarkerType.foundPerson:
        return 0xFF4CAF50; // Green
      case SarMarkerType.fire:
        return 0xFFF44336; // Red
      case SarMarkerType.stagingArea:
        return 0xFFFF9800; // Orange
      case SarMarkerType.object:
        return 0xFF2196F3; // Blue
      case SarMarkerType.unknown:
        return 0xFF9E9E9E; // Gray
    }
  }

  /// Show notification for regular message (contact or channel)
  Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    required bool isChannelMessage,
    String? channelName,
    AppLocalizations? localizations,
  }) async {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ [NotificationService] Not initialized, skipping notification',
      );
      return;
    }

    if (!_permissionGranted) {
      debugPrint(
        '⚠️ [NotificationService] Permission not granted, skipping notification',
      );
      return;
    }

    try {
      // Generate unique notification ID based on timestamp
      final notificationId =
          _messageNotificationId +
          (DateTime.now().millisecondsSinceEpoch % 1000);

      // Build notification title and body
      final title = isChannelMessage
          ? (localizations != null
                ? '${localizations.channel}: ${channelName ?? "Public"}'
                : 'Channel: ${channelName ?? "Public"}')
          : (localizations != null
                ? '${localizations.newMessage} ${localizations.from} $senderName'
                : 'New message from $senderName');

      final body = messageText.length > 200
          ? '${messageText.substring(0, 200)}...'
          : messageText;

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        _messagesChannelId,
        _messagesChannelName,
        channelDescription: _messagesChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: title,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: senderName,
        ),
      );

      // iOS notification details
      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        threadIdentifier: isChannelMessage
            ? 'channel_messages'
            : 'direct_messages',
        subtitle: senderName,
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Show notification
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: 'message:${isChannelMessage ? "channel" : "contact"}',
      );

      debugPrint('✅ [NotificationService] Showed message notification');
      debugPrint('   Sender: $senderName');
      debugPrint('   Type: ${isChannelMessage ? "Channel" : "Direct"}');
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error showing message notification: $e',
      );
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('✅ [NotificationService] Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error canceling notifications: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('✅ [NotificationService] Cancelled notification: $id');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error canceling notification: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }

      // For iOS, assume enabled if permission was granted
      return _permissionGranted;
    } catch (e) {
      debugPrint(
        '⚠️ [NotificationService] Error checking notification status: $e',
      );
      return false;
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint(
        '⚠️ [NotificationService] Error getting pending notifications: $e',
      );
      return [];
    }
  }
}
