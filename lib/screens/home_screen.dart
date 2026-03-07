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
import 'map_tab.dart';
import 'map_management_screen.dart';
import 'settings_screen.dart';
import 'device_config_screen.dart';
import 'packet_log_screen.dart';
import 'spectrum_scan_screen.dart';
import '../utils/toast_logger.dart';
import '../l10n/app_localizations.dart';
import '../widgets/permission_request_dialog.dart';
import '../widgets/connection_dialog.dart';
import '../utils/battery_display_helper.dart';

enum _HomeTab { messages, contacts, map }

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late final AppProvider _appProvider;
  int _currentIndex = 0;
  bool _isMapFullscreen = false;
  bool _showRxTxIndicators = true;
  bool _isMapEnabled = true;
  bool _isContactsEnabled = true;

  List<_HomeTab> get _enabledTabs {
    return [
      _HomeTab.messages,
      if (_isContactsEnabled) _HomeTab.contacts,
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
    _appProvider = context.read<AppProvider>();
    _isMapEnabled = _appProvider.isMapEnabled;
    _isContactsEnabled = _appProvider.isContactsEnabled;
    _appProvider.addListener(_handleAppProviderChanged);

    // Initialize synchronously so first build always has a valid controller.
    _initTabController();
    _loadRxTxPreference();

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
  }) {
    if (_isMapEnabled == mapEnabled && _isContactsEnabled == contactsEnabled) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (tab) {
        case _HomeTab.messages:
          context.read<MessagesProvider>().markAllAsRead();
          break;
        case _HomeTab.contacts:
          context.read<ContactsProvider>().markAllAsViewed();
          break;
        case _HomeTab.map:
          break;
      }
    });
  }

  Future<void> _loadRxTxPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showRxTxIndicators = prefs.getBool('show_rx_tx_indicators') ?? true;
      });
    }
  }

  @override
  void dispose() {
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

  Future<void> _advertiseDevice(BuildContext context) async {
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

      // Send flood advertisement
      await connectionProvider.sendSelfAdvert(floodMode: true);
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
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.map),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.mapManagement),
                        ],
                      ),
                      onTap: () {
                        // Capture context-dependent objects before async gap
                        final navigator = Navigator.of(context);
                        final appProvider = context.read<AppProvider>();
                        Future.delayed(Duration.zero, () {
                          if (!mounted) return;
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => MapManagementScreen(
                                tileCacheService: appProvider.tileCacheService,
                              ),
                            ),
                          );
                        });
                      },
                    ),
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
                              builder: (context) => const SpectrumScanScreen(),
                            ),
                          );
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          const Icon(Icons.settings),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.settings),
                        ],
                      ),
                      onTap: () {
                        // Capture context-dependent objects before async gap
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
                          // Reload preference when returning from settings
                          _loadRxTxPreference();
                        });
                      },
                    ),
                  ],
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
        final isBleConnected = isConnected && !isTcpConnected;

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

        // Connected state: LEFT | CENTER | RIGHT layout
        return Row(
          children: [
            // LEFT: Name + BT/Battery + Cog
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          deviceInfo.selfName ??
                              AppLocalizations.of(context)!.appTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTcpConnected
                                  ? Icons.wifi
                                  : Icons.bluetooth_connected,
                              color: isTcpConnected
                                  ? Colors.green
                                  : (deviceInfo.signalRssi != null
                                        ? BatteryDisplayHelper.getSignalColor(
                                            deviceInfo.signalRssi!,
                                          )
                                        : Colors.grey),
                              size: 13,
                            ),
                            if (isBleConnected &&
                                deviceInfo.signalRssi != null) ...[
                              const SizedBox(width: 3),
                              Text(
                                '${deviceInfo.signalRssi}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BatteryDisplayHelper.getSignalColor(
                                    deviceInfo.signalRssi!,
                                  ),
                                ),
                              ),
                            ],
                            if (isTcpConnected) ...[
                              const SizedBox(width: 3),
                              Text(
                                'WiFi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                            if (deviceInfo.batteryPercent != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                BatteryDisplayHelper.getBatteryIcon(
                                  deviceInfo.batteryPercent!,
                                ),
                                color: BatteryDisplayHelper.getBatteryColor(
                                  deviceInfo.batteryPercent!,
                                ),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${deviceInfo.batteryPercent!.round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BatteryDisplayHelper.getBatteryColor(
                                    deviceInfo.batteryPercent!,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Settings cog - hidden in simple mode
                  if (!context.watch<AppProvider>().isSimpleMode) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DeviceConfigScreen(),
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
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const Icon(Icons.settings, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // CENTER: Broadcast button
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                // Capture platform before async operations
                final platform = Theme.of(context).platform;
                // iOS: Use haptic feedback (always works)
                // Android: Try vibration package for better control
                try {
                  if (platform == TargetPlatform.iOS) {
                    // iOS: Try multiple haptic types for reliability
                    await HapticFeedback.lightImpact();
                    await Future.delayed(const Duration(milliseconds: 50));
                    await HapticFeedback.lightImpact();
                  } else {
                    // Android vibration
                    if (await Vibration.hasVibrator()) {
                      await Vibration.vibrate(duration: 50);
                    } else {
                      await HapticFeedback.mediumImpact();
                    }
                  }
                } catch (e) {
                  // Fallback if anything fails
                  debugPrint('Haptic feedback error: $e');
                  await HapticFeedback.vibrate();
                }
                if (!mounted) return;
                if (!context.mounted) return;
                _advertiseDevice(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(10),
                minimumSize: const Size(40, 40),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.campaign, size: 20),
            ),
            const SizedBox(width: 8),

            // RIGHT: RX/TX indicators
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.rxActivity
                                ? Colors.green
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'RX:${provider.rxPacketCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.txActivity
                                ? Colors.blue
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'TX:${provider.txPacketCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              const SizedBox(
                width: 52,
              ), // Placeholder to maintain layout balance
          ],
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
