import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _prefMessagesEnabled = 'notifications_messages_enabled';
  static const String _prefSarEnabled = 'notifications_sar_enabled';
  static const String _prefDiscoveryEnabled = 'notifications_discovery_enabled';
  static const String _prefUpdatesEnabled = 'notifications_updates_enabled';
  static const String _prefMuteForeground = 'notifications_mute_foreground';

  bool _isInitialized = false;
  bool _permissionGranted = false;
  bool _messageNotificationsEnabled = true;
  bool _sarNotificationsEnabled = true;
  bool _discoveryNotificationsEnabled = true;
  bool _updateNotificationsEnabled = true;
  bool _muteForegroundNotifications = true;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  String? _launchPayload;

  // Notification IDs
  static const int _sarNotificationId = 1000;
  static const int _messageNotificationId = 2000;
  static const int _updateNotificationId = 3000;
  static const int _batteryNotificationId = 4000;
  static const int _discoveryNotificationId = 5000;

  // Notification channels
  static const String _urgentChannelId = 'sar_urgent';
  static const String _urgentChannelName = 'SAR Urgent Alerts';
  static const String _urgentChannelDescription =
      'Critical alerts for SAR markers (found persons, fires, staging areas)';

  static const String _messagesChannelId = 'messages';
  static const String _messagesChannelName = 'Messages';
  static const String _messagesChannelDescription =
      'Notifications for incoming messages from contacts and channels';

  static const String _updateChannelId = 'app_updates';
  static const String _updateChannelName = 'App Updates';
  static const String _updateChannelDescription =
      'Notifications for available app updates';

  static const String _batteryChannelId = 'battery_alerts';
  static const String _batteryChannelName = 'Battery Alerts';
  static const String _batteryChannelDescription =
      'Notifications when a device or contact battery is low';

  static const String _discoveryChannelId = 'discovery_alerts';
  static const String _discoveryChannelName = 'Discovery Alerts';
  static const String _discoveryChannelDescription =
      'Notifications when new contacts are discovered';

  bool get messageNotificationsEnabled => _messageNotificationsEnabled;
  bool get sarNotificationsEnabled => _sarNotificationsEnabled;
  bool get discoveryNotificationsEnabled => _discoveryNotificationsEnabled;
  bool get updateNotificationsEnabled => _updateNotificationsEnabled;
  bool get muteForegroundNotifications => _muteForegroundNotifications;
  bool get isAppInForeground => _lifecycleState == AppLifecycleState.resumed;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('📬 [NotificationService] Initializing...');
      WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
      _lifecycleState =
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      final darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      // Initialize plugin
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final launchDetails = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _launchPayload = launchDetails?.notificationResponse?.payload;
      }

      // Request permissions
      await _requestPermissions();
      await _loadPreferences();

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
  Future<void> _requestPermissions() async {
    try {
      // iOS permissions
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        _permissionGranted = granted ?? false;
        debugPrint(
          '📱 [NotificationService] iOS permissions granted: $_permissionGranted',
        );
        return; // Exit early if on iOS
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _messageNotificationsEnabled = prefs.getBool(_prefMessagesEnabled) ?? true;
    _sarNotificationsEnabled = prefs.getBool(_prefSarEnabled) ?? true;
    _discoveryNotificationsEnabled =
        prefs.getBool(_prefDiscoveryEnabled) ?? true;
    _updateNotificationsEnabled = prefs.getBool(_prefUpdatesEnabled) ?? true;
    _muteForegroundNotifications = prefs.getBool(_prefMuteForeground) ?? true;
  }

  Future<void> setMessageNotificationsEnabled(bool value) async {
    _messageNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefMessagesEnabled, value);
  }

  Future<void> setSarNotificationsEnabled(bool value) async {
    _sarNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSarEnabled, value);
  }

  Future<void> setDiscoveryNotificationsEnabled(bool value) async {
    _discoveryNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDiscoveryEnabled, value);
  }

  Future<void> setUpdateNotificationsEnabled(bool value) async {
    _updateNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefUpdatesEnabled, value);
  }

  Future<void> setMuteForegroundNotifications(bool value) async {
    _muteForegroundNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefMuteForeground, value);
  }

  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    _lifecycleState = state;
  }

  bool _shouldSuppressForegroundNotifications() {
    return _muteForegroundNotifications && isAppInForeground;
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

      // App updates channel with default priority
      const updateChannel = AndroidNotificationChannel(
        _updateChannelId,
        _updateChannelName,
        description: _updateChannelDescription,
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      );

      const batteryChannel = AndroidNotificationChannel(
        _batteryChannelId,
        _batteryChannelName,
        description: _batteryChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const discoveryChannel = AndroidNotificationChannel(
        _discoveryChannelId,
        _discoveryChannelName,
        description: _discoveryChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(urgentChannel);
      await androidPlugin.createNotificationChannel(messagesChannel);
      await androidPlugin.createNotificationChannel(updateChannel);
      await androidPlugin.createNotificationChannel(batteryChannel);
      await androidPlugin.createNotificationChannel(discoveryChannel);
      debugPrint('✅ [NotificationService] Created notification channels');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] Error creating channels: $e');
    }
  }

  /// Callback for handling notification taps (set by main.dart)
  void Function(String?)? onNotificationTapped;

  /// Handle notification tap (foreground)
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      '🔔 [NotificationService] Notification tapped: ${response.payload}',
    );

    // Call the registered callback if available
    if (onNotificationTapped != null) {
      onNotificationTapped!(response.payload);
    }
  }

  String? consumeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
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
    if (!_sarNotificationsEnabled) {
      debugPrint('ℹ️ [NotificationService] SAR notifications disabled');
      return;
    }
    if (_shouldSuppressForegroundNotifications()) {
      debugPrint(
        'ℹ️ [NotificationService] App in foreground, skipping SAR notification',
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
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Show notification
      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
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
      return '${type.emoji} ${type.displayName} Detected';
    }

    switch (type) {
      case SarMarkerType.foundPerson:
        return '${type.emoji} ${localizations.sarMarkerFoundPerson}';
      case SarMarkerType.fire:
        return '${type.emoji} ${localizations.sarMarkerFire}';
      case SarMarkerType.stagingArea:
        return '${type.emoji} ${localizations.sarMarkerStagingArea}';
      case SarMarkerType.object:
        return '${type.emoji} ${localizations.sarMarkerObject}';
      case SarMarkerType.unknown:
        return '${type.emoji} ${localizations.sarAlert}';
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
    if (!_messageNotificationsEnabled) {
      debugPrint('ℹ️ [NotificationService] Message notifications disabled');
      return;
    }
    if (_shouldSuppressForegroundNotifications()) {
      debugPrint(
        'ℹ️ [NotificationService] App in foreground, skipping message notification',
      );
      return;
    }

    try {
      // Generate unique notification ID based on timestamp
      final notificationId =
          _messageNotificationId +
          (DateTime.now().millisecondsSinceEpoch % 1000);

      // Build notification title and body
      final resolvedChannelName = channelName?.trim().isNotEmpty == true
          ? channelName!.trim()
          : (localizations?.publicChannel ?? 'Public');
      final title = isChannelMessage
          ? (localizations != null
                ? '${localizations.channel}: $resolvedChannelName'
                : 'Channel: $resolvedChannelName')
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
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
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
      await _notificationsPlugin.cancel(id: id);
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

  /// Show notification for available app update
  Future<void> showUpdateNotification({
    required String currentVersion,
    required String latestVersion,
    required String downloadUrl,
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
    if (!_updateNotificationsEnabled) {
      debugPrint('ℹ️ [NotificationService] Update notifications disabled');
      return;
    }
    if (_shouldSuppressForegroundNotifications()) {
      debugPrint(
        'ℹ️ [NotificationService] App in foreground, skipping update notification',
      );
      return;
    }

    try {
      // Build notification title and body
      final title = localizations?.updateAvailable ?? 'App Update Available';
      final body = localizations != null
          ? '${localizations.currentVersion}: $currentVersion\n'
                '${localizations.latestVersion}: $latestVersion'
          : 'Current: $currentVersion\nLatest: $latestVersion';

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        _updateChannelId,
        _updateChannelName,
        channelDescription: _updateChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ticker: title,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2196F3), // Blue
        colorized: true,
        category: AndroidNotificationCategory.recommendation,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: localizations?.downloadUpdate ?? 'Tap to download',
        ),
        // Make notification ongoing so it doesn't get dismissed easily
        ongoing: false,
        autoCancel: true,
      );

      // iOS notification details
      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        threadIdentifier: 'app_updates',
        categoryIdentifier: 'APP_UPDATE',
        subtitle: localizations?.newVersionAvailable(latestVersion) ?? 'New version: $latestVersion',
      );

      // Combined notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Show notification
      await _notificationsPlugin.show(
        id: _updateNotificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'update:$downloadUrl',
      );

      debugPrint('✅ [NotificationService] Showed update notification');
      debugPrint('   Current: $currentVersion');
      debugPrint('   Latest: $latestVersion');
      debugPrint('   Download URL: $downloadUrl');
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error showing update notification: $e',
      );
    }
  }

  Future<bool> showLowBatteryNotification({
    required String nodeId,
    required String nodeName,
    required double batteryPercent,
    required bool isCurrentDevice,
  }) async {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ [NotificationService] Not initialized, skipping notification',
      );
      return false;
    }

    if (!_permissionGranted) {
      debugPrint(
        '⚠️ [NotificationService] Permission not granted, skipping notification',
      );
      return false;
    }
    if (!_messageNotificationsEnabled) {
      debugPrint('ℹ️ [NotificationService] Message notifications disabled');
      return false;
    }
    if (_shouldSuppressForegroundNotifications()) {
      debugPrint(
        'ℹ️ [NotificationService] App in foreground, skipping low battery notification',
      );
      return false;
    }

    final roundedPercent = batteryPercent.round().clamp(0, 100);
    final title = isCurrentDevice
        ? 'Device battery low'
        : 'Contact battery low';
    final body = isCurrentDevice
        ? '$nodeName battery is at $roundedPercent%.'
        : '$nodeName is at $roundedPercent% battery.';
    final notificationId =
        _batteryNotificationId + ((nodeId.hashCode & 0x7fffffff) % 1000);

    try {
      final androidDetails = AndroidNotificationDetails(
        _batteryChannelId,
        _batteryChannelName,
        channelDescription: _batteryChannelDescription,
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
          summaryText: '$roundedPercent%',
        ),
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        threadIdentifier: 'battery_alerts',
        subtitle: '$roundedPercent%',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'battery:$nodeId',
      );

      debugPrint(
        '✅ [NotificationService] Showed low battery notification for $nodeName ($roundedPercent%)',
      );
      return true;
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error showing low battery notification: $e',
      );
      return false;
    }
  }

  Future<bool> showContactDiscoveredNotification({
    required String contactKey,
    String? contactName,
  }) async {
    if (!_isInitialized) return false;
    if (!_permissionGranted) return false;
    if (!_discoveryNotificationsEnabled) return false;
    if (_shouldSuppressForegroundNotifications()) return false;

    final shortKey = contactKey.length > 12
        ? contactKey.substring(0, 12).toUpperCase()
        : contactKey.toUpperCase();
    final title = 'New contact discovered';
    final resolvedName = contactName?.trim();
    final body = resolvedName != null && resolvedName.isNotEmpty
        ? '$resolvedName is available in Discovery.'
        : 'New contact $shortKey is available in Discovery.';
    final notificationId =
        _discoveryNotificationId + ((contactKey.hashCode & 0x7fffffff) % 1000);

    try {
      final androidDetails = AndroidNotificationDetails(
        _discoveryChannelId,
        _discoveryChannelName,
        channelDescription: _discoveryChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ticker: title,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        threadIdentifier: 'discovery_alerts',
      );

      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
        payload: 'discovery:$contactKey',
      );
      return true;
    } catch (e) {
      debugPrint(
        '❌ [NotificationService] Error showing discovery notification: $e',
      );
      return false;
    }
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this._service);

  final NotificationService _service;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _service.handleAppLifecycleStateChanged(state);
  }
}
