import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/connection_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/map_provider.dart';
import 'providers/drawing_provider.dart';
import 'providers/channels_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/image_provider.dart' as ip;
import 'providers/app_provider.dart';
import 'providers/offline_tiles_provider.dart';
import 'providers/sensors_provider.dart';
import 'services/voice_codec_service.dart';
import 'services/voice_player_service.dart';
import 'services/notification_service.dart';
import 'services/locale_preferences.dart';
import 'services/mesh_map_nodes_service.dart';
import 'services/profile_manager.dart';
import 'services/profile_workspace_coordinator.dart';
import 'services/profiles_feature_service.dart';
import 'services/update_checker_service.dart';
import 'services/wizard_preferences.dart';
import 'screens/discovery_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_wizard_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  runApp(const MeshCoreSarApp());
}

class MeshCoreSarApp extends StatefulWidget {
  const MeshCoreSarApp({super.key});

  @override
  State<MeshCoreSarApp> createState() => _MeshCoreSarAppState();
}

class _MeshCoreSarAppState extends State<MeshCoreSarApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppThemeMode _themeMode = AppThemeMode.system;
  Locale? _locale;
  bool _isInitialized = false;
  bool _shouldShowPermissionDialog = false;
  bool _wizardCompleted = true; // Will be updated in _initializeApp()
  String? _pendingNotificationPayload;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesEnabled = await ProfilesFeatureService.isEnabled();
    final activeProfileId =
        prefs.getString(ProfileManager.activeProfileIdKey) ?? 'default';
    await ProfileStorageScope.bootstrap(
      profilesEnabled: profilesEnabled,
      activeProfileId: activeProfileId,
    );
    await _loadThemePreference();
    await _loadLocalePreference();

    // Check if welcome wizard has been completed
    final wizardCompleted = await WizardPreferences.isWizardCompleted();

    // Initialize notification service
    await NotificationService().initialize();

    // Set up notification tap handler for update notifications
    NotificationService().onNotificationTapped = _handleNotificationTap;
    _pendingNotificationPayload = NotificationService().consumeLaunchPayload();

    // Check if we need to request location permissions
    await _checkLocationPermissions();

    // Check for app updates (Android only) - runs in background
    // Shows notification if update is available
    _checkForUpdates();

    // Refresh remote mesh node cache in background when the app starts.
    unawaited(MeshMapNodesService.syncInBackgroundIfStale());

    setState(() {
      _wizardCompleted = wizardCompleted;
      _isInitialized = true;
    });

    if (_pendingNotificationPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final payload = _pendingNotificationPayload;
        _pendingNotificationPayload = null;
        _handleNotificationTap(payload);
      });
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    debugPrint('[Main] Notification tapped: $payload');

    if (!_wizardCompleted) {
      _pendingNotificationPayload = payload;
      return;
    }

    // Handle update notification tap
    if (payload.startsWith('update:')) {
      final downloadUrl = payload.substring(7); // Remove 'update:' prefix
      _launchUpdateDownload(downloadUrl);
      return;
    }

    if (payload.startsWith('discovery:')) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _pendingNotificationPayload = payload;
        return;
      }
      navigator.push(
        MaterialPageRoute(builder: (context) => const DiscoveryScreen()),
      );
    }
    // SAR and message notifications handled by their respective providers
  }

  /// Launch update download URL
  Future<void> _launchUpdateDownload(String downloadUrl) async {
    try {
      final url = Uri.parse(downloadUrl);
      final canLaunch = await canLaunchUrl(url);

      if (!canLaunch) {
        debugPrint('[Main] Cannot open download URL: $downloadUrl');
        return;
      }

      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Main] Error launching download URL: $e');
    }
  }

  Future<void> _checkLocationPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();

      // Show dialog if permission is denied or not determined
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _shouldShowPermissionDialog = true;
      }
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = AppTheme.themeFromString(themeName);
    });
  }

  Future<void> _loadLocalePreference() async {
    final locale = await LocalePreferences.getLocale();
    setState(() {
      _locale = locale;
    });
  }

  void _handleThemeChanged(AppThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _handleLocaleChanged(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _handleWizardCompleted() {
    setState(() {
      _wizardCompleted = true;
    });
  }

  /// Check for app updates on Android only
  /// Shows notification if update is available
  Future<void> _checkForUpdates() async {
    // Only check for updates on Android
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[UpdateChecker] Skipping update check (not Android)');
      return;
    }

    try {
      debugPrint('[UpdateChecker] Starting update check...');
      final updateInfo = await UpdateCheckerService().checkForUpdate();

      if (!updateInfo.isAvailable) {
        debugPrint('[UpdateChecker] No update available');
        return;
      }

      if (updateInfo.downloadUrl == null) {
        debugPrint('[UpdateChecker] Update available but no download URL');
        return;
      }

      debugPrint('[UpdateChecker] Update available! Showing notification...');

      // Show notification (will be visible after app is initialized)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await NotificationService().showUpdateNotification(
            currentVersion: updateInfo.currentCommitHash,
            latestVersion: updateInfo.latestCommitHash ?? 'unknown',
            downloadUrl: updateInfo.downloadUrl!,
            localizations: null, // Will use English fallback
          );
        }
      });
    } catch (e) {
      debugPrint('[UpdateChecker] Error checking for updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(
          create: (_) {
            // Initialize early to load persisted contacts for offline viewing
            // Self-contact filtering will happen later when BLE connects
            final provider = ContactsProvider();
            provider.initializeEarly();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = MessagesProvider();
            // Initialize messages provider asynchronously
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = DrawingProvider();
            // Initialize drawing provider asynchronously
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ChannelsProvider()),
        ChangeNotifierProvider(create: (_) => SensorsProvider()),
        ChangeNotifierProvider(create: (_) => OfflineTilesProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final manager = ProfileManager();
            manager.initialize();
            return manager;
          },
        ),

        // Voice provider (packet reassembly + playback)
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(
            codec: VoiceCodecService(),
            player: VoicePlayerService(),
          ),
        ),

        // Image provider (fragment reassembly + outgoing session cache)
        ChangeNotifierProvider(create: (_) => ip.ImageProvider()),

        // App provider that coordinates everything
        // VoiceProvider is read via context.read inside create since it's already registered above
        ChangeNotifierProxyProvider5<
          ConnectionProvider,
          ContactsProvider,
          MessagesProvider,
          DrawingProvider,
          ChannelsProvider,
          AppProvider
        >(
          create: (context) => AppProvider(
            connectionProvider: context.read<ConnectionProvider>(),
            contactsProvider: context.read<ContactsProvider>(),
            messagesProvider: context.read<MessagesProvider>(),
            drawingProvider: context.read<DrawingProvider>(),
            channelsProvider: context.read<ChannelsProvider>(),
            voiceProvider: context.read<VoiceProvider>(),
            imageProvider: context.read<ip.ImageProvider>(),
          ),
          update:
              (
                context,
                conn,
                contacts,
                messages,
                drawings,
                channels,
                previous,
              ) =>
                  previous ??
                  AppProvider(
                    connectionProvider: conn,
                    contactsProvider: contacts,
                    messagesProvider: messages,
                    drawingProvider: drawings,
                    channelsProvider: channels,
                    voiceProvider: context.read<VoiceProvider>(),
                    imageProvider: context.read<ip.ImageProvider>(),
                  ),
        ),
        ProxyProvider6<
          ProfileManager,
          AppProvider,
          ConnectionProvider,
          ContactsProvider,
          MessagesProvider,
          MapProvider,
          ProfileWorkspaceCoordinator
        >(
          update:
              (
                context,
                profileManager,
                appProvider,
                connectionProvider,
                contactsProvider,
                messagesProvider,
                mapProvider,
                previous,
              ) => ProfileWorkspaceCoordinator(
                profileManager: profileManager,
                connectionProvider: connectionProvider,
                contactsProvider: contactsProvider,
                messagesProvider: messagesProvider,
                sensorsProvider: context.read<SensorsProvider>(),
                mapProvider: mapProvider,
                drawingProvider: context.read<DrawingProvider>(),
                channelsProvider: context.read<ChannelsProvider>(),
                voiceProvider: context.read<VoiceProvider>(),
                imageProvider: context.read<ip.ImageProvider>(),
                appProvider: appProvider,
              ),
        ),
      ],
      child: _buildMaterialApp(),
    );
  }

  Widget _buildMaterialApp() {
    return Builder(
      builder: (context) {
        final systemBrightness = MediaQuery.platformBrightnessOf(context);
        final materialApp = MaterialApp(
          navigatorKey: _navigatorKey,
          key: ValueKey<String?>(
            '${_locale?.languageCode ?? 'system'}_${_themeMode.name}',
          ),
          onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'MeshCore SAR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(_themeMode, systemBrightness),
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocalePreferences.supportedLocales,
          home: _wizardCompleted
              ? HomeScreen(
                  onThemeChanged: _handleThemeChanged,
                  onLocaleChanged: _handleLocaleChanged,
                  currentTheme: _themeMode,
                  currentLocale: _locale,
                  shouldShowPermissionDialog: _shouldShowPermissionDialog,
                )
              : WelcomeWizardScreen(onCompleted: _handleWizardCompleted),
        );

        // Wrap in SafeArea for Android only to fix navigation bar overlap (API ≥36)
        // iOS doesn't need SafeArea wrapping (causes extra black space at bottom)
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return SafeArea(
            left: false,
            right: false,
            top: false, // prevents black status bar background
            child: materialApp,
          );
        }

        return materialApp;
      },
    );
  }
}
