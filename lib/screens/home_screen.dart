import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
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
import '../utils/toast_logger.dart';
import '../l10n/app_localizations.dart';
import '../widgets/permission_request_dialog.dart';

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isMapFullscreen = false;
  bool _showRxTxIndicators = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
        // Exit fullscreen when switching away from map tab
        if (_currentIndex != 2) {
          _isMapFullscreen = false;
        }
      });
    });
    _loadRxTxPreference();

    // Show permission dialog after the first frame if needed
    if (widget.shouldShowPermissionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }
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

      if (context.mounted) {
        ToastLogger.success(
          context,
          AppLocalizations.of(context)!.advertisedAtLocation(
            position.latitude.toStringAsFixed(6),
            position.longitude.toStringAsFixed(6),
          ),
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
    final connectionProvider = context.read<ConnectionProvider>();

    // Start scanning immediately
    connectionProvider.startScan();

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
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      connectionProvider.stopScan();
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.scanningForDevices,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      connectionProvider.stopScan();
                      connectionProvider.startScan();
                    },
                  ),
                ],
              ),
            ),

            // Info banner
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.defaultPinInfo,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Device list
            Expanded(
              child: Consumer<ConnectionProvider>(
                builder: (context, provider, child) {
                  if (provider.isScanning && provider.scannedDevices.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.scannedDevices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noDevicesFound,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              connectionProvider.stopScan();
                              connectionProvider.startScan();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              AppLocalizations.of(context)!.scanAgain,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.scannedDevices.length,
                    itemBuilder: (context, index) {
                      final scannedDevice = provider.scannedDevices[index];
                      final device = scannedDevice.device;
                      final rssi = scannedDevice.rssi;
                      final signalColor = _getSignalColor(rssi);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(
                            Icons.bluetooth,
                            color: signalColor,
                            size: 32,
                          ),
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'Unknown Device',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                AppLocalizations.of(context)!.tapToConnect,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${rssi} dBm',
                                style: TextStyle(
                                  color: signalColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onTap: () async {
                            debugPrint(
                              '🔵 [UI] User tapped device: ${device.platformName}',
                            );

                            // Get app provider reference before popping dialog
                            final appProvider = context.read<AppProvider>();

                            debugPrint('🔵 [UI] Closing dialog...');
                            Navigator.pop(context);

                            debugPrint('🔵 [UI] Calling provider.connect()...');
                            final success = await provider.connect(device);
                            debugPrint(
                              success
                                  ? '✅ [UI] provider.connect() returned success'
                                  : '❌ [UI] provider.connect() returned failure',
                            );

                            if (success && provider.deviceInfo.isConnected) {
                              debugPrint(
                                '✅ [UI] Device is connected, initializing app provider...',
                              );
                              await appProvider.initialize();
                              debugPrint('✅ [UI] App provider initialized');
                            } else {
                              debugPrint(
                                '❌ [UI] Device not connected after connect() call',
                              );
                              debugPrint(
                                '  Connection state: ${provider.deviceInfo.connectionState}',
                              );
                              debugPrint('  Error: ${provider.error}');
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

    // Determine if we should hide the UI (only in fullscreen on map tab)
    final shouldHideUI = _isMapFullscreen && _currentIndex == 2;

    return Scaffold(
      appBar: shouldHideUI
          ? null
          : AppBar(
              title: _buildCompactStatusBar(),
              actions: [
                Consumer<ConnectionProvider>(
                  builder: (context, provider, child) {
                    if (provider.deviceInfo.isConnected) {
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
                        Future.delayed(Duration.zero, () {
                          final appProvider = context.read<AppProvider>();
                          Navigator.push(
                            context,
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
                          const Icon(Icons.settings),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.settings),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, () async {
                          await Navigator.push(
                            context,
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
        children: [
          MessagesTab(onNavigateToMap: () => _tabController.animateTo(2)),
          const ContactsTab(),
          MapTab(
            onFullscreenChanged: (isFullscreen) {
              setState(() {
                _isMapFullscreen = isFullscreen;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: shouldHideUI
          ? null
          : Consumer2<MessagesProvider, ContactsProvider>(
              builder: (context, messagesProvider, contactsProvider, child) {
                final unreadCount = messagesProvider.unreadCount;
                final newContactsCount = contactsProvider.newContactsCount;

                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        icon: _buildTabIconWithBadge(
                          Icons.message,
                          unreadCount,
                        ),
                        text: AppLocalizations.of(context)!.messages,
                      ),
                      Tab(
                        icon: _buildTabIconWithBadge(
                          Icons.contacts,
                          newContactsCount,
                        ),
                        text: AppLocalizations.of(context)!.contacts,
                      ),
                      Tab(
                        icon: const Icon(Icons.map),
                        text: AppLocalizations.of(context)!.map,
                      ),
                    ],
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
                              Icons.bluetooth_connected,
                              color: deviceInfo.signalRssi != null
                                  ? _getSignalColor(deviceInfo.signalRssi!)
                                  : Colors.grey,
                              size: 13,
                            ),
                            if (deviceInfo.signalRssi != null) ...[
                              const SizedBox(width: 3),
                              Text(
                                '${deviceInfo.signalRssi}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getSignalColor(
                                    deviceInfo.signalRssi!,
                                  ),
                                ),
                              ),
                            ],
                            if (deviceInfo.batteryPercent != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _getBatteryIcon(deviceInfo.batteryPercent!),
                                color: _getBatteryColor(
                                  deviceInfo.batteryPercent!,
                                ),
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${deviceInfo.batteryPercent!.round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getBatteryColor(
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
                          builder: (context) =>
                              PacketLogScreen(bleService: provider.bleService),
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
              ),
            ),

            // CENTER: Broadcast button
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                // iOS: Use haptic feedback (always works)
                // Android: Try vibration package for better control
                try {
                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                    // iOS: Try multiple haptic types for reliability
                    await HapticFeedback.lightImpact();
                    await Future.delayed(const Duration(milliseconds: 50));
                    await HapticFeedback.lightImpact();
                  } else {
                    // Android vibration
                    if (await Vibration.hasVibrator() ?? false) {
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
                                : Colors.grey.withOpacity(0.3),
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
                                : Colors.grey.withOpacity(0.3),
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

  Widget _buildStatusBar() {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, child) {
        final deviceInfo = provider.deviceInfo;
        final isConnected = deviceInfo.isConnected;

        return Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  // Connection status
                  Icon(
                    isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isConnected
                          ? deviceInfo.displayName ??
                                AppLocalizations.of(context)!.connect
                          : AppLocalizations.of(context)!.deviceNotConnected,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  // Battery indicator
                  if (deviceInfo.batteryPercent != null) ...[
                    Icon(
                      _getBatteryIcon(deviceInfo.batteryPercent!),
                      color: _getBatteryColor(deviceInfo.batteryPercent!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${deviceInfo.batteryPercent!.round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  // Signal strength
                  if (deviceInfo.signalRssi != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.signal_cellular_alt,
                      color: _getSignalColor(deviceInfo.signalRssi!),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${deviceInfo.signalRssi} dBm',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Connection buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConnected
                          ? null
                          : () => _showConnectionDialog(context),
                      icon: const Icon(Icons.bluetooth_searching, size: 18),
                      label: Text(AppLocalizations.of(context)!.connect),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !isConnected
                          ? null
                          : () async {
                              await provider.disconnect();
                            },
                      icon: const Icon(Icons.bluetooth_disabled, size: 18),
                      label: Text(AppLocalizations.of(context)!.disconnect),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final appProvider = context.read<AppProvider>();
                        await appProvider.refresh();
                        if (context.mounted) {
                          ToastLogger.success(context, 'Refreshed contacts');
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ],
              ),
              // Error message
              if (provider.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: provider.clearError,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getBatteryIcon(double percentage) {
    if (percentage > 80) return Icons.battery_full;
    if (percentage > 50) return Icons.battery_5_bar;
    if (percentage > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(double percentage) {
    if (percentage > 50) return Colors.green;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -70) return Colors.orange;
    return Colors.red;
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
