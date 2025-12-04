import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/app_provider.dart';
import '../services/location_tracking_service.dart';
import '../services/locale_preferences.dart';
import '../services/update_checker_service.dart';
import '../utils/sample_data_generator.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/connection_mode_selector.dart';
import '../widgets/update_dialog.dart';
import 'sar_template_management_screen.dart';
import 'welcome_wizard_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppThemeMode) onThemeChanged;
  final Function(Locale?) onLocaleChanged;
  final AppThemeMode currentTheme;
  final Locale? currentLocale;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.currentLocale,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppThemeMode _selectedTheme;
  late Locale? _selectedLocale;
  PackageInfo? _packageInfo;
  bool _isLoadingSampleData = false;
  bool _showRxTxIndicators = true;
  bool _isCheckingForUpdates = false;
  final LocationTrackingService _locationService = LocationTrackingService();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _selectedLocale = widget.currentLocale;
    _loadPackageInfo();
    _initializeLocationService();
    _loadRxTxPreference();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
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

  Future<void> _saveRxTxPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_rx_tx_indicators', value);
  }

  Future<void> _initializeLocationService() async {
    // Initialize location service with BLE service
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final appProvider = context.read<AppProvider>();
        await _locationService.initialize(
          appProvider.connectionProvider.bleService,
        );

        // Set up callbacks for UI feedback
        _locationService.onError = (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.orange),
            );
          }
        };

        _locationService.onBroadcastSent = (position) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.locationBroadcast(
                    position.latitude.toStringAsFixed(5),
                    position.longitude.toStringAsFixed(5),
                  ),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        };

        _locationService.onTrackingStateChanged = (isTracking) {
          if (mounted) {
            setState(() {});
          }
        };

        // Load settings and restore tracking state
        final prefs = await SharedPreferences.getInstance();
        final wasTracking =
            prefs.getBool('background_tracking_enabled') ?? false;

        if (wasTracking) {
          await _startBackgroundTracking();
        }

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _saveThemePreference(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme.name);
  }

  void _handleThemeChange(AppThemeMode? theme) {
    if (theme != null) {
      setState(() {
        _selectedTheme = theme;
      });
      _saveThemePreference(theme);
      widget.onThemeChanged(theme);
    }
  }

  Future<void> _saveLocalePreference(Locale? locale) async {
    await LocalePreferences.setLocale(locale);
  }

  /// Check for app updates and show notification or dialog
  Future<void> _checkForUpdates() async {
    // Only on Android
    if (!Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update check is only available on Android'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      debugPrint('[Settings] Checking for updates...');
      final updateInfo = await UpdateCheckerService().checkForUpdate();

      if (!mounted) return;

      setState(() {
        _isCheckingForUpdates = false;
      });

      if (!updateInfo.isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are running the latest version'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      if (updateInfo.downloadUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update available but download URL not found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show dialog with update details
      UpdateDialog.show(context, updateInfo);
    } catch (e) {
      debugPrint('[Settings] Error checking for updates: $e');
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking for updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLocaleChange(Locale? locale) {
    setState(() {
      _selectedLocale = locale;
    });
    _saveLocalePreference(locale);
    widget.onLocaleChanged(locale);
  }

  Future<void> _loadSampleData() async {
    setState(() => _isLoadingSampleData = true);

    try {
      // Get current location or use default
      LatLng centerLocation;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 5),
          ),
        );
        centerLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        // Default to Ljubljana, Slovenia if location unavailable
        centerLocation = const LatLng(46.0569, 14.5058);
      }

      if (!mounted) return;

      // Get localization
      final l10n = AppLocalizations.of(context)!;

      // Generate sample data
      final contacts = SampleDataGenerator.generateContacts(
        centerLocation: centerLocation,
        l10n: l10n,
        teamMemberCount: 5,
        channelCount: 2,
      );

      final sarMessages = SampleDataGenerator.generateSarMarkerMessages(
        centerLocation: centerLocation,
        l10n: l10n,
        foundPersonCount: 2,
        fireCount: 1,
        stagingCount: 1,
        objectCount: 1,
      );

      final channelMessages = SampleDataGenerator.generateChannelMessages(
        centerLocation: centerLocation,
        l10n: l10n,
        generalChannelMessages: 8,
        emergencyChannelMessages: 5,
      );

      // Combine all messages
      final allMessages = [...sarMessages, ...channelMessages];

      // Add to providers
      final contactsProvider = Provider.of<ContactsProvider>(
        context,
        listen: false,
      );
      final messagesProvider = Provider.of<MessagesProvider>(
        context,
        listen: false,
      );

      contactsProvider.addContacts(contacts);
      messagesProvider.addMessages(allMessages);

      if (!mounted) return;

      final teamCount = contacts.where((c) => c.isChat).length;
      final channelCount = contacts.where((c) => c.isRoom).length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.loadedSampleData(
              teamCount,
              channelCount,
              sarMessages.length,
              channelMessages.length,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToLoadSampleData(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingSampleData = false);
      }
    }
  }

  Future<void> _handleLocationPermissionTap() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        // Show dialog to open app settings
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.settings, size: 24),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.locationPermission),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)!.locationPermissionDialogContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openAppSettings();
                },
                child: Text(AppLocalizations.of(context)!.openSettings),
              ),
            ],
          ),
        );
      } else if (permission == LocationPermission.denied) {
        // Request permission
        final newPermission = await Geolocator.requestPermission();

        if (!mounted) return;

        if (newPermission == LocationPermission.whileInUse ||
            newPermission == LocationPermission.always) {
          // Permission granted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.locationPermissionGranted,
              ),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh UI to show new status
        } else {
          // Permission denied
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.locationPermissionRequiredForGps,
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Already granted - show info
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationPermissionAlreadyGranted,
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling location permission: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startBackgroundTracking() async {
    final success = await _locationService.startTracking(
      distanceThreshold: _locationService.gpsUpdateDistance,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToStartBackgroundTracking,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopBackgroundTracking() async {
    await _locationService.stopTracking();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _clearSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearAllDataConfirmTitle),
        content: Text(AppLocalizations.of(context)!.clearAllDataConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.clear),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final contactsProvider = Provider.of<ContactsProvider>(
      context,
      listen: false,
    );
    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );

    contactsProvider.clearContacts();
    messagesProvider.clearAll();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.allDataCleared),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView(
        children: [
          // General Settings Section
          _buildSectionHeader(AppLocalizations.of(context)!.general),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(AppLocalizations.of(context)!.theme),
            subtitle: Text(AppTheme.getThemeDisplayName(_selectedTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.radar),
            title: Text(AppLocalizations.of(context)!.showRxTxIndicators),
            subtitle: Text(AppLocalizations.of(context)!.displayPacketActivity),
            value: _showRxTxIndicators,
            onChanged: (value) async {
              setState(() {
                _showRxTxIndicators = value;
              });
              await _saveRxTxPreference(value);
            },
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) => SwitchListTile(
              secondary: const Icon(Icons.visibility_off),
              title: Text(AppLocalizations.of(context)!.simpleMode),
              subtitle: Text(
                AppLocalizations.of(context)!.simpleModeDescription,
              ),
              value: appProvider.isSimpleMode,
              onChanged: (value) async {
                await appProvider.toggleSimpleMode(value);
              },
            ),
          ),
          Consumer<AppProvider>(
            builder: (context, appProvider, child) => SwitchListTile(
              secondary: const Icon(Icons.map_outlined),
              title: Text(AppLocalizations.of(context)!.disableMap),
              subtitle: Text(
                AppLocalizations.of(context)!.disableMapDescription,
              ),
              value: !appProvider.isMapEnabled,
              onChanged: (value) async {
                await appProvider.toggleMapEnabled(!value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.language),
            subtitle: Text(LocalePreferences.getDisplayName(_selectedLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.location_searching),
            title: Text(AppLocalizations.of(context)!.sarTemplates),
            subtitle: Text(AppLocalizations.of(context)!.manageSarTemplates),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SarTemplateManagementScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: Text(AppLocalizations.of(context)!.viewWelcomeTutorial),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Show wizard without resetting state - just as a modal
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WelcomeWizardScreen(
                    onCompleted: () {
                      // Just pop back to settings when done
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // Network Sharing Section
          const ConnectionModeSelector(),
          const Divider(),

          // Permissions Section
          _buildSectionHeader(AppLocalizations.of(context)!.permissionsSection),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(AppLocalizations.of(context)!.locationPermission),
            subtitle: FutureBuilder<LocationPermission>(
              future: Geolocator.checkPermission(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(AppLocalizations.of(context)!.checking);
                }
                final permission = snapshot.data!;
                String statusText;
                Color statusColor;

                switch (permission) {
                  case LocationPermission.always:
                    statusText = AppLocalizations.of(
                      context,
                    )!.locationPermissionGrantedAlways;
                    statusColor = Colors.green;
                    break;
                  case LocationPermission.whileInUse:
                    statusText = AppLocalizations.of(
                      context,
                    )!.locationPermissionGrantedWhileInUse;
                    statusColor = Colors.green;
                    break;
                  case LocationPermission.denied:
                    statusText = AppLocalizations.of(
                      context,
                    )!.locationPermissionDeniedTapToRequest;
                    statusColor = Colors.orange;
                    break;
                  case LocationPermission.deniedForever:
                    statusText = AppLocalizations.of(
                      context,
                    )!.locationPermissionPermanentlyDeniedOpenSettings;
                    statusColor = Colors.red;
                    break;
                  default:
                    statusText = AppLocalizations.of(context)!.unknown;
                    statusColor = Colors.grey;
                }

                return Text(statusText, style: TextStyle(color: statusColor));
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handleLocationPermissionTap(),
          ),
          const Divider(),

          // About Section
          _buildSectionHeader(AppLocalizations.of(context)!.about),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.of(context)!.appVersion),
            subtitle: Text(
              _packageInfo != null
                  ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                  : 'Loading...',
            ),
          ),
          // Check for Updates button (Android only)
          if (Platform.isAndroid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                onPressed: _isCheckingForUpdates ? null : _checkForUpdates,
                icon: _isCheckingForUpdates
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.system_update),
                label: Text(
                  _isCheckingForUpdates ? 'Checking...' : 'Check for Updates',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: Text(AppLocalizations.of(context)!.appName),
            subtitle: Text(_packageInfo?.appName ?? 'MeshCore SAR'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(AppLocalizations.of(context)!.aboutMeshCoreSar),
            subtitle: Text(
              AppLocalizations.of(context)!.aboutDescription.split('\n\n')[0],
            ),
            onTap: () => _showAboutDialog(),
          ),
          const Divider(),

          // Developer Section
          _buildSectionHeader(AppLocalizations.of(context)!.developer),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(AppLocalizations.of(context)!.packageName),
            subtitle: Text(_packageInfo?.packageName ?? 'com.meshcore.sar'),
          ),
          const Divider(),

          // Sample Data Section
          _buildSectionHeader(AppLocalizations.of(context)!.sampleData),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.sampleDataDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingSampleData ? null : _loadSampleData,
                    icon: _isLoadingSampleData
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_outline),
                    label: Text(AppLocalizations.of(context)!.loadSampleData),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingSampleData ? null : _clearSampleData,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(AppLocalizations.of(context)!.clearAllData),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTrackingConfigDialog() {
    double tempMinDistance = _locationService.minDistanceMeters;
    double tempMaxDistance = _locationService.maxDistanceMeters;
    int tempTimeInterval = _locationService.minTimeIntervalSeconds;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.locationTrackingConfiguration,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  AppLocalizations.of(context)!.configureWhenLocationBroadcasts,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Minimum Distance
                Text(
                  AppLocalizations.of(context)!.minimumDistance,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.broadcastAfterMoving(tempMinDistance.toStringAsFixed(0)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(
                    context,
                  ).copyWith(showValueIndicator: ShowValueIndicator.onDrag),
                  child: Slider(
                    value: tempMinDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${tempMinDistance.toStringAsFixed(0)}m',
                    onChanged: (value) {
                      setDialogState(() {
                        tempMinDistance = value;
                        // Ensure max is always >= min
                        if (tempMaxDistance < value) {
                          tempMaxDistance = value;
                        }
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1m', style: Theme.of(context).textTheme.bodySmall),
                      Text('50m', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Maximum Distance
                Text(
                  AppLocalizations.of(context)!.maximumDistance,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.alwaysBroadcastAfterMoving(
                    tempMaxDistance.toStringAsFixed(0),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(
                    context,
                  ).copyWith(showValueIndicator: ShowValueIndicator.onDrag),
                  child: Slider(
                    value: tempMaxDistance,
                    min: tempMinDistance,
                    max: 500,
                    divisions: (500 - tempMinDistance).toInt(),
                    label: '${tempMaxDistance.toStringAsFixed(0)}m',
                    onChanged: (value) {
                      setDialogState(() {
                        tempMaxDistance = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tempMinDistance.toStringAsFixed(0)}m',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '500m',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Minimum Time Interval
                Text(
                  AppLocalizations.of(context)!.minimumTimeInterval,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.alwaysBroadcastEvery(_formatDuration(tempTimeInterval)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(
                    context,
                  ).copyWith(showValueIndicator: ShowValueIndicator.onDrag),
                  child: Slider(
                    value: tempTimeInterval.toDouble(),
                    min: 10,
                    max: 600, // 10 minutes
                    divisions: 59,
                    label: _formatDuration(tempTimeInterval),
                    onChanged: (value) {
                      setDialogState(() {
                        tempTimeInterval = value.toInt();
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10s', style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        '10min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () async {
                // Update location service configuration
                _locationService.minDistanceMeters = tempMinDistance;
                _locationService.maxDistanceMeters = tempMaxDistance;
                _locationService.minTimeIntervalSeconds = tempTimeInterval;
                _locationService.gpsUpdateDistance = tempMinDistance;

                // Save settings
                await _locationService.saveSettings();

                // Update tracking if active
                if (_locationService.isTracking) {
                  await _locationService.updateDistanceThreshold(
                    tempMinDistance,
                  );
                }

                // Close dialog before setState
                Navigator.pop(context);

                if (mounted) {
                  setState(() {});
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}min ${remainingSeconds}s';
      }
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseTheme),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                title: Text(AppLocalizations.of(context)!.light),
                subtitle: Text(AppLocalizations.of(context)!.blueLightTheme),
                value: AppThemeMode.light,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: Text(AppLocalizations.of(context)!.dark),
                subtitle: Text(AppLocalizations.of(context)!.blueDarkTheme),
                value: AppThemeMode.dark,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.sarRed),
                    const SizedBox(width: 8),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.alertEmergencyMode,
                ),
                value: AppThemeMode.sarRed,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.sarGreen),
                    const SizedBox(width: 8),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(AppLocalizations.of(context)!.safeAllClearMode),
                value: AppThemeMode.sarGreen,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.sarNavyBlue),
                    const SizedBox(width: 8),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C9FFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  AppLocalizations.of(context)!.sarNavyBlueDescription,
                ),
                value: AppThemeMode.sarNavyBlue,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              RadioListTile<AppThemeMode>(
                title: Text(AppLocalizations.of(context)!.autoSystem),
                subtitle: Text(AppLocalizations.of(context)!.followSystemTheme),
                value: AppThemeMode.system,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseLanguage),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale?>(
                title: Text(LocalePreferences.getDisplayName(null)),
                subtitle: Text(LocalePreferences.getDisplayName(null)),
                value: null,
                groupValue: _selectedLocale,
                onChanged: (value) {
                  _handleLocaleChange(value);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...LocalePreferences.supportedLocales.map((locale) {
                return RadioListTile<Locale?>(
                  title: Text(LocalePreferences.getNativeDisplayName(locale)),
                  value: locale,
                  groupValue: _selectedLocale,
                  onChanged: (value) {
                    _handleLocaleChange(value);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.aboutMeshCoreSar),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MeshCore SAR',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${_packageInfo?.version ?? '1.0.0'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.aboutDescription),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.technologiesUsed,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.technologiesList),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://dz0ny.dev/posts/meshcore-sar/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(AppLocalizations.of(context)!.moreInfo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}
