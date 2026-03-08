import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
import '../models/device_info.dart' show ConnectionMode;
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../theme/app_theme.dart';
import 'messages_tab.dart';
import 'contacts_tab.dart';
import 'sensors_tab.dart';
import 'map_tab.dart';
import 'settings_screen.dart';
import 'device_config_screen.dart';
import 'packet_log_screen.dart';
import 'spectrum_scan_screen.dart';
import '../utils/toast_logger.dart';
import '../l10n/app_localizations.dart';
import '../widgets/permission_request_dialog.dart';
import '../widgets/connection_dialog.dart';
import '../utils/battery_display_helper.dart';
import '../services/developer_mode_service.dart';

enum _HomeTab { messages, contacts, sensors, map }

enum _AdvertMode { flood, direct }

class HomeScreen extends StatefulWidget {
  final Function(AppThemeMode) onThemeChanged;
  final Function(Locale?) onLocaleChanged;
  final AppThemeMode currentTheme;
  final Locale? currentLocale;
  final bool shouldShowPermissionDialog;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.currentLocale,
    this.shouldShowPermissionDialog = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late final AppProvider _appProvider;
  int _currentIndex = 0;
  bool _isMapFullscreen = false;
  bool _showRxTxIndicators = true;
  bool _isDeveloperModeEnabled = false;
  bool _isMapEnabled = true;
  bool _isContactsEnabled = true;
  bool _isSensorsEnabled = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  List<_HomeTab> get _enabledTabs {
    return [
      _HomeTab.messages,
      if (_isContactsEnabled) _HomeTab.contacts,
      if (_isSensorsEnabled) _HomeTab.sensors,
      if (_isMapEnabled) _HomeTab.map,
    ];
  }

  _HomeTab get _currentTab {
    final tabs = _enabledTabs;
    final safeIndex = _currentIndex < tabs.length
        ? _currentIndex
        : tabs.length - 1;
    return tabs[safeIndex < 0 ? 0 : safeIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appProvider = context.read<AppProvider>();
    _isMapEnabled = _appProvider.isMapEnabled;
    _isContactsEnabled = _appProvider.isContactsEnabled;
    _isSensorsEnabled = _appProvider.isSensorsEnabled;
    _appProvider.addListener(_handleAppProviderChanged);

    // Initialize synchronously so first build always has a valid controller.
    _initTabController();
    _loadRxTxPreference();
    _loadDeveloperModePreference();

    // Show permission dialog after the first frame if needed
    if (widget.shouldShowPermissionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }
  }

  void _initTabController() {
    _tabController = TabController(length: _enabledTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleTabActivated(_currentTab);
    });
  }

  void _handleAppProviderChanged() {
    if (!mounted) return;
    _updateTabController(
      mapEnabled: _appProvider.isMapEnabled,
      contactsEnabled: _appProvider.isContactsEnabled,
      sensorsEnabled: _appProvider.isSensorsEnabled,
    );
  }

  void _onTabChanged() {
    final previousTab = _currentTab;
    final nextIndex = _tabController.index;

    setState(() {
      _currentIndex = nextIndex;
      if (_currentTab != _HomeTab.map) {
        _isMapFullscreen = false;
      }
    });

    final nextTab = _currentTab;
    if (previousTab != nextTab) {
      _handleTabActivated(nextTab);
    }
  }

  void _updateTabController({
    required bool mapEnabled,
    required bool contactsEnabled,
    required bool sensorsEnabled,
  }) {
    if (_isMapEnabled == mapEnabled &&
        _isContactsEnabled == contactsEnabled &&
        _isSensorsEnabled == sensorsEnabled) {
      return;
    }

    final oldTabs = _enabledTabs;
    final oldIndex = oldTabs.isEmpty
        ? 0
        : _tabController.index.clamp(0, oldTabs.length - 1);
    final oldTab = oldTabs[oldIndex];

    final oldController = _tabController;
    oldController.removeListener(_onTabChanged);
    oldController.dispose();

    // Update state
    _isMapEnabled = mapEnabled;
    _isContactsEnabled = contactsEnabled;
    _isSensorsEnabled = sensorsEnabled;
    if (!_isMapEnabled) {
      _isMapFullscreen = false;
    }

    final newTabs = _enabledTabs;
    final newIndex = newTabs.indexOf(oldTab);

    // Create new controller
    _tabController = TabController(length: newTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    _currentIndex = newIndex >= 0 ? newIndex : 0;
    _tabController.index = _currentIndex;

    setState(() {});
    _handleTabActivated(_currentTab);
  }

  void _navigateToTab(_HomeTab tab) {
    final targetIndex = _enabledTabs.indexOf(tab);
    if (targetIndex >= 0 && targetIndex != _tabController.index) {
      _tabController.animateTo(targetIndex);
    }
  }

  void _handleTabActivated(_HomeTab tab) {
    _syncFastLocationUiState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (tab) {
        case _HomeTab.messages:
          context.read<MessagesProvider>().markAllAsRead();
          break;
        case _HomeTab.contacts:
          context.read<ContactsProvider>().markAllAsViewed();
          break;
        case _HomeTab.sensors:
          break;
        case _HomeTab.map:
          break;
      }
    });
  }

  void _syncFastLocationUiState() {
    final isActiveTab =
        _currentTab == _HomeTab.map || _currentTab == _HomeTab.messages;
    _appProvider.setFastLocationUiActive(
      _lifecycleState == AppLifecycleState.resumed && isActiveTab,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncFastLocationUiState();
  }

  Future<void> _loadRxTxPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showRxTxIndicators = prefs.getBool('show_rx_tx_indicators') ?? true;
      });
    }
  }

  Future<void> _loadDeveloperModePreference() async {
    final isEnabled = await DeveloperModeService.isEnabled();
    if (!mounted) return;
    setState(() {
      _isDeveloperModeEnabled = isEnabled;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appProvider.setFastLocationUiActive(false);
    _appProvider.removeListener(_handleAppProviderChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        onPermissionsGranted: () {
          debugPrint('✅ Location permissions granted');
        },
        onPermissionsDenied: () {
          debugPrint('⚠️ Location permissions denied');
          // Show a snackbar to inform the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.locationPermissionRequired,
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _triggerAdvertFeedback() async {
    final platform = Theme.of(context).platform;

    try {
      if (platform == TargetPlatform.iOS) {
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.lightImpact();
      } else {
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate(duration: 50);
        } else {
          await HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
      await HapticFeedback.vibrate();
    }
  }

  Future<_AdvertMode?> _showAdvertModeSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return showModalBottomSheet<_AdvertMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advert mode',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how far this announcement should travel.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.hub_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(l10n.flood),
                subtitle: const Text('Relay through repeaters across the mesh'),
                trailing: const Icon(Icons.chevron_right_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onTap: () => Navigator.of(context).pop(_AdvertMode.flood),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.near_me_rounded,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(l10n.direct),
                subtitle: const Text('Nearby only, without repeater flooding'),
                trailing: const Icon(Icons.chevron_right_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onTap: () => Navigator.of(context).pop(_AdvertMode.direct),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityBadge({
    required String label,
    required int count,
    required bool isActive,
    required Color activeColor,
  }) {
    final color = isActive ? activeColor : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            '$label:$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActivityIndicator({
    required bool rxActive,
    required bool txActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rxActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: txActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _advertiseDevice(
    BuildContext context, {
    bool floodMode = true,
  }) async {
    final connectionProvider = context.read<ConnectionProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.deviceNotConnected,
        );
      }
      return;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.locationServicesDisabled,
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ToastLogger.error(
              context,
              AppLocalizations.of(context)!.locationPermissionDenied,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.locationPermissionPermanentlyDenied,
          );
        }
        return;
      }

      // Get current GPS position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0,
          ),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('❌ Failed to get GPS position: $e');
        if (context.mounted) {
          ToastLogger.error(
            context,
            AppLocalizations.of(context)!.failedToGetGpsLocation,
          );
        }
        return;
      }

      // Update lat/lon on device
      await connectionProvider.setAdvertLatLon(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Small delay to ensure the lat/lon is set
      await Future.delayed(const Duration(milliseconds: 100));

      await connectionProvider.sendSelfAdvert(floodMode: floodMode);

      if (context.mounted) {
        ToastLogger.success(
          context,
          floodMode ? 'Flood advert sent' : 'Direct advert sent',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to advertise device: $e');
      if (context.mounted) {
        ToastLogger.error(
          context,
          AppLocalizations.of(context)!.failedToAdvertise(e.toString()),
        );
      }
    }
  }

  void _showConnectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConnectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set localizations for notifications
    final messagesProvider = context.read<MessagesProvider>();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      messagesProvider.setLocalizations(localizations);
    }

    context.watch<AppProvider>();

    final enabledTabs = _enabledTabs;
    final isMapTabActive = _currentTab == _HomeTab.map;
    final shouldHideUI = _isMapEnabled && _isMapFullscreen && isMapTabActive;
    final shouldShowTabBar = enabledTabs.length > 1;

    return Scaffold(
      appBar: shouldHideUI
          ? null
          : AppBar(
              toolbarHeight: 64,
              titleSpacing: 8,
              title: _buildCompactStatusBar(),
              actions: [
                Consumer<ConnectionProvider>(
                  builder: (context, provider, child) {
                    final isConnected =
                        provider.deviceInfo.isConnected ||
                        provider.deviceInfo.isConnected;
                    if (isConnected) {
                      return IconButton(
                        onPressed: () async {
                          await provider.disconnect();
                        },
                        icon: const Icon(Icons.power_settings_new),
                        tooltip: AppLocalizations.of(context)!.disconnect,
                        color: Colors.red.shade700,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<void>>[];

                    if (_isDeveloperModeEnabled) {
                      items.add(
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.radar),
                              const SizedBox(width: 8),
                              const Text('Spectrum Scan'),
                            ],
                          ),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            Future.delayed(Duration.zero, () {
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SpectrumScanScreen(),
                                ),
                              );
                            });
                          },
                        ),
                      );
                    }

                    items.add(
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.settings),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.settings),
                          ],
                        ),
                        onTap: () {
                          final navigator = Navigator.of(context);
                          Future.delayed(Duration.zero, () async {
                            if (!mounted) return;
                            await navigator.push(
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  onThemeChanged: widget.onThemeChanged,
                                  onLocaleChanged: widget.onLocaleChanged,
                                  currentTheme: widget.currentTheme,
                                  currentLocale: widget.currentLocale,
                                ),
                              ),
                            );
                            _loadRxTxPreference();
                            _loadDeveloperModePreference();
                          });
                        },
                      ),
                    );

                    return items;
                  },
                ),
              ],
            ),
      body: TabBarView(
        controller: _tabController,
        children: enabledTabs.map((tab) {
          switch (tab) {
            case _HomeTab.messages:
              return MessagesTab(
                onNavigateToMap: _isMapEnabled
                    ? () => _navigateToTab(_HomeTab.map)
                    : null,
              );
            case _HomeTab.contacts:
              return ContactsTab(
                onNavigateToMap: _isMapEnabled
                    ? () => _navigateToTab(_HomeTab.map)
                    : null,
              );
            case _HomeTab.sensors:
              return const SensorsTab();
            case _HomeTab.map:
              return MapTab(
                onFullscreenChanged: (isFullscreen) {
                  setState(() {
                    _isMapFullscreen = isFullscreen;
                  });
                },
                onNavigateToMessages: () => _navigateToTab(_HomeTab.messages),
              );
          }
        }).toList(),
      ),
      bottomNavigationBar: shouldHideUI || !shouldShowTabBar
          ? null
          : Consumer2<MessagesProvider, ContactsProvider>(
              builder: (context, messagesProvider, contactsProvider, child) {
                final unreadCount = messagesProvider.unreadCount;
                final newContactsCount = contactsProvider.newContactsCount;

                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      final tabs = _enabledTabs;
                      if (index < 0 || index >= tabs.length) {
                        return;
                      }
                      _handleTabActivated(tabs[index]);
                    },
                    tabs: enabledTabs.map((tab) {
                      switch (tab) {
                        case _HomeTab.messages:
                          return Tab(
                            icon: _buildTabIconWithBadge(
                              Icons.message,
                              unreadCount,
                            ),
                            text: AppLocalizations.of(context)!.messages,
                          );
                        case _HomeTab.contacts:
                          return Tab(
                            icon: _buildTabIconWithBadge(
                              Icons.contacts,
                              newContactsCount,
                            ),
                            text: AppLocalizations.of(context)!.contacts,
                          );
                        case _HomeTab.map:
                          return Tab(
                            icon: const Icon(Icons.map),
                            text: AppLocalizations.of(context)!.map,
                          );
                        case _HomeTab.sensors:
                          return const Tab(
                            icon: Icon(Icons.sensors),
                            text: 'Sensors',
                          );
                      }
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCompactStatusBar() {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, child) {
        final deviceInfo = provider.deviceInfo;
        final isConnected = deviceInfo.isConnected;
        final isTcpConnected = provider.connectionMode == ConnectionMode.tcp;

        if (!isConnected) {
          // Disconnected state: show connect button
          return Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.appTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: provider.isReconnecting
                    ? null
                    : () => _showConnectionDialog(context),
                icon: provider.isReconnecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black54,
                          ),
                        ),
                      )
                    : const Icon(Icons.bluetooth, size: 18),
                label: Text(
                  provider.isReconnecting
                      ? '${provider.reconnectionAttempt}/${provider.maxReconnectionAttempts}'
                      : AppLocalizations.of(context)!.connect,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              if (provider.isReconnecting) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => provider.cancelReconnection(),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: AppLocalizations.of(context)!.cancelReconnection,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          );
        }

        final theme = Theme.of(context);
        final subtitleColor = theme.colorScheme.onSurfaceVariant;
        final signalColor = isTcpConnected
            ? Colors.green
            : (deviceInfo.signalRssi != null
                  ? BatteryDisplayHelper.getSignalColor(deviceInfo.signalRssi!)
                  : Colors.grey);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 360;

            return Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deviceInfo.selfName ??
                                    AppLocalizations.of(context)!.appTitle,
                                style:
                                    (isTight
                                            ? theme.textTheme.titleSmall
                                            : theme.textTheme.titleMedium)
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isTcpConnected
                                        ? Icons.wifi_rounded
                                        : Icons.bluetooth_connected_rounded,
                                    size: 13,
                                    color: signalColor,
                                  ),
                                  if (!isTcpConnected &&
                                      deviceInfo.signalRssi != null) ...[
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${deviceInfo.signalRssi}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: signalColor,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                  if (deviceInfo.batteryPercent != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      BatteryDisplayHelper.getBatteryIcon(
                                        deviceInfo.batteryPercent!,
                                      ),
                                      size: 13,
                                      color:
                                          BatteryDisplayHelper.getBatteryColor(
                                            deviceInfo.batteryPercent!,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '${deviceInfo.batteryPercent!.round()}%',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              BatteryDisplayHelper.getBatteryColor(
                                                deviceInfo.batteryPercent!,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DeviceConfigScreen(),
                              ),
                            );
                          },
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PacketLogScreen(
                                  bleService: provider.bleService,
                                ),
                              ),
                            );
                          },
                          tooltip: AppLocalizations.of(context)!.settings,
                          icon: const Icon(Icons.tune_rounded),
                          color: subtitleColor,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: subtitleColor,
                            minimumSize: Size.square(isTight ? 38 : 40),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () async {
                            await _triggerAdvertFeedback();
                            if (!mounted || !context.mounted) return;
                            await _advertiseDevice(context);
                          },
                          onLongPress: () async {
                            await _triggerAdvertFeedback();
                            if (!mounted || !context.mounted) return;

                            final mode = await _showAdvertModeSheet(context);
                            if (!mounted || !context.mounted || mode == null) {
                              return;
                            }

                            await _advertiseDevice(
                              context,
                              floodMode: mode == _AdvertMode.flood,
                            );
                          },
                          child: Container(
                            width: isTight ? 38 : 40,
                            height: isTight ? 38 : 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.78,
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: Colors.white,
                              size: isTight ? 18 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isTight ? 8 : 12),
                if (_showRxTxIndicators)
                  GestureDetector(
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PacketLogScreen(bleService: provider.bleService),
                        ),
                      );
                    },
                    child: isTight
                        ? _buildCompactActivityIndicator(
                            rxActive: provider.rxActivity,
                            txActive: provider.txActivity,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildActivityBadge(
                                  label: 'RX',
                                  count: provider.rxPacketCount,
                                  isActive: provider.rxActivity,
                                  activeColor: Colors.green,
                                ),
                                const SizedBox(height: 6),
                                _buildActivityBadge(
                                  label: 'TX',
                                  count: provider.txPacketCount,
                                  isActive: provider.txActivity,
                                  activeColor: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                  )
                else
                  SizedBox(width: isTight ? 24 : 74),
              ],
            );
          },
        );
      },
    );
  }

  /// Build tab icon with badge showing count
  Widget _buildTabIconWithBadge(IconData icon, int count) {
    if (count == 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
