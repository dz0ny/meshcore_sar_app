import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../services/location_tracking_service.dart';
import '../services/locale_preferences.dart';
import '../services/update_checker_service.dart';
import '../services/voice_codec_service.dart';
import '../services/voice_bitrate_preferences.dart';
import '../services/image_preferences.dart';
import '../services/route_hash_preferences.dart';
import '../services/image_codec_service.dart';
import '../services/developer_mode_service.dart';
import '../utils/sample_data_generator.dart';
import '../utils/image_message_parser.dart';
import '../utils/voice_message_parser.dart';
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
  int _voiceBitrate = VoiceBitratePreferences.defaultBitrate;
  int _routeHashSize = RouteHashPreferences.defaultHashSize;
  int _imageMaxSize = ImagePreferences.defaultMaxSize;
  int _imageCompression = ImagePreferences.defaultQuality;
  bool _imageGrayscale = ImagePreferences.defaultGrayscale;
  bool _imageUltraMode = ImagePreferences.defaultUltraMode;
  Uint8List? _previewSourceBytes;
  String? _previewSourceName;
  Uint8List? _previewCompressedBytes;
  bool _isPreviewLoading = false;
  bool _showCurrentImagePreview = true;
  bool _fastLocationUpdatesEnabled = false;
  double _fastLocationMovementThresholdMeters = 10.0;
  int _fastLocationActiveCadenceSeconds = 10;
  bool _isDeveloperModeEnabled = false;
  int _versionTapCount = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final LocationTrackingService _locationService = LocationTrackingService();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _selectedLocale = widget.currentLocale;
    _loadPackageInfo();
    _initializeLocationService();
    _loadRxTxPreference();
    _loadVoiceBitratePreference();
    _loadRouteHashSizePreference();
    _loadImagePreferences();
    _loadFastLocationSettings();
    _loadDeveloperMode();
  }

  @override
  void dispose() {
    // Clear location service callbacks to prevent memory leaks
    _locationService.onError = null;
    _locationService.onBroadcastSent = null;
    _locationService.onTrackingStateChanged = null;
    super.dispose();
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

  Future<void> _loadDeveloperMode() async {
    final isEnabled = await DeveloperModeService.isEnabled();
    if (!mounted) return;
    setState(() {
      _isDeveloperModeEnabled = isEnabled;
    });
  }

  Future<void> _handleVersionTap() async {
    if (_isDeveloperModeEnabled) {
      await DeveloperModeService.setEnabled(false);
      if (!mounted) return;
      setState(() {
        _isDeveloperModeEnabled = false;
        _versionTapCount = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Developer mode disabled')));
      return;
    }

    final nextTapCount = _versionTapCount + 1;
    if (nextTapCount >= 3) {
      await DeveloperModeService.setEnabled(true);
      if (!mounted) return;
      setState(() {
        _isDeveloperModeEnabled = true;
        _versionTapCount = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Developer mode enabled')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _versionTapCount = nextTapCount;
    });
  }

  Future<void> _saveRxTxPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_rx_tx_indicators', value);
  }

  Future<void> _loadVoiceBitratePreference() async {
    final value = await VoiceBitratePreferences.getBitrate();
    if (!mounted) return;
    setState(() {
      _voiceBitrate = value;
    });
  }

  Future<void> _saveVoiceBitratePreference(int value) async {
    await VoiceBitratePreferences.setBitrate(value);
    if (!mounted) return;
    setState(() {
      _voiceBitrate = value;
    });
  }

  String _voiceBitrateSubtitle(int bitrate) {
    return '$bitrate bps';
  }

  Future<void> _loadRouteHashSizePreference() async {
    final value = await RouteHashPreferences.getHashSize();
    if (!mounted) return;
    setState(() {
      _routeHashSize = value;
    });
  }

  Future<void> _saveRouteHashSizePreference(int value) async {
    await RouteHashPreferences.setHashSize(value);
    if (!mounted) return;
    setState(() {
      _routeHashSize = value;
    });
  }

  Future<void> _loadImagePreferences() async {
    final size = await ImagePreferences.getMaxSize();
    final compression = await ImagePreferences.getCompression();
    final grayscale = await ImagePreferences.getGrayscale();
    final ultraMode = await ImagePreferences.getUltraMode();
    if (!mounted) return;
    setState(() {
      _imageMaxSize = ImagePreferences.effectiveMaxSize(
        size,
        ultraMode: ultraMode,
      );
      _imageCompression = compression;
      _imageGrayscale = grayscale;
      _imageUltraMode = ultraMode;
    });
    await _refreshImageModePreview();
  }

  Future<void> _loadFastLocationSettings() async {
    await _locationService.loadSettings();
    if (!mounted) return;
    setState(() {
      _fastLocationUpdatesEnabled = _locationService.fastLocationUpdatesEnabled;
      _fastLocationMovementThresholdMeters =
          _locationService.fastLocationMovementThresholdMeters;
      _fastLocationActiveCadenceSeconds =
          _locationService.fastLocationActiveCadenceSeconds;
    });
  }

  Future<void> _setFastLocationUpdatesEnabled(bool enabled) async {
    await _locationService.setFastLocationUpdatesEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _fastLocationUpdatesEnabled = _locationService.fastLocationUpdatesEnabled;
    });
  }

  Future<void> _editFastLocationMovementThreshold() async {
    final controller = TextEditingController(
      text: _fastLocationMovementThresholdMeters.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fast GPS movement threshold'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Meters',
            helperText: 'Valid range: 1 to 1000 meters',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null) return;
              Navigator.pop(context, parsed.clamp(1.0, 1000.0));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    await _locationService.updateFastLocationMovementThreshold(value);
    if (!mounted) return;
    setState(() {
      _fastLocationMovementThresholdMeters =
          _locationService.fastLocationMovementThresholdMeters;
    });
  }

  Future<void> _editFastLocationActiveCadence() async {
    final controller = TextEditingController(
      text: _fastLocationActiveCadenceSeconds.toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fast GPS active-use interval'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Seconds',
            helperText: 'Valid range: 5 to 60 seconds',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null) return;
              Navigator.pop(context, parsed.clamp(5, 60));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    await _locationService.updateFastLocationActiveCadenceSeconds(value);
    if (!mounted) return;
    setState(() {
      _fastLocationActiveCadenceSeconds =
          _locationService.fastLocationActiveCadenceSeconds;
    });
  }

  Future<void> _saveImageMaxSize(int size) async {
    await ImagePreferences.setMaxSize(size);
    if (!mounted) return;
    setState(() => _imageMaxSize = size);
    await _refreshImageModePreview();
  }

  Future<void> _saveImageCompression(int compression) async {
    await ImagePreferences.setCompression(compression);
    if (!mounted) return;
    setState(() => _imageCompression = compression);
    await _refreshImageModePreview();
  }

  Future<void> _refreshImageModePreview() async {
    final sourceBytes = _previewSourceBytes;
    if (sourceBytes == null) {
      if (!mounted) return;
      setState(() => _previewCompressedBytes = null);
      return;
    }

    setState(() => _isPreviewLoading = true);
    try {
      final result = await ImageCodecService.compress(
        sourceBytes,
        maxDimension: ImagePreferences.effectiveMaxSize(
          _imageMaxSize,
          ultraMode: _imageUltraMode,
        ),
        compression: _imageCompression,
        grayscale: _imageGrayscale,
        ultraMode: _imageUltraMode,
      );
      if (!mounted) return;
      setState(() {
        _previewCompressedBytes = result?.bytes;
        _isPreviewLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewCompressedBytes = null;
        _isPreviewLoading = false;
      });
    }
  }

  Future<void> _selectPreviewImageFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _previewSourceBytes = bytes;
        _previewSourceName = picked.name;
      });
      await _refreshImageModePreview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load preview image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

      final sampleMessages = SampleDataGenerator.generateAllMessages(
        centerLocation: centerLocation,
        l10n: l10n,
        foundPersonCount: 2,
        fireCount: 1,
        stagingCount: 1,
        objectCount: 1,
        generalChannelMessages: 8,
        emergencyChannelMessages: 5,
      );

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
      for (final message in sampleMessages.messages) {
        messagesProvider.addMessage(
          message,
          contactLocationSnapshot: sampleMessages.contactLocations[message.id],
        );
      }

      if (!mounted) return;

      final teamCount = contacts.where((c) => c.isChat).length;
      final channelCount = contacts.where((c) => c.isRoom).length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.loadedSampleData(
              teamCount,
              channelCount,
              sampleMessages.messages.where((m) => m.isSarMarker).length,
              sampleMessages.messages.length,
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

  Future<void> _clearMessages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Messages'),
        content: const Text(
          'This will permanently delete all stored messages. Are you sure?',
        ),
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

    final messagesProvider = Provider.of<MessagesProvider>(
      context,
      listen: false,
    );
    messagesProvider.clearMessages();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All messages cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showRouteHashSizeDialog() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Route path byte size'),
        children: [
          for (final value in [1, 2, 3])
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(value),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$value byte${value == 1 ? '' : 's'}'),
                        Text(
                          'Use ${value * 2} hex characters per hop',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (_routeHashSize == value)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected == null) return;
    await _saveRouteHashSizePreference(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _buildSectionHeader('Appearance'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text(AppLocalizations.of(context)!.theme),
              subtitle: Text(AppTheme.getThemeDisplayName(_selectedTheme)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language),
              subtitle: Text(LocalePreferences.getDisplayName(_selectedLocale)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.radar),
              title: Text(AppLocalizations.of(context)!.showRxTxIndicators),
              subtitle: Text(
                AppLocalizations.of(context)!.displayPacketActivity,
              ),
              value: _showRxTxIndicators,
              onChanged: (value) async {
                setState(() {
                  _showRxTxIndicators = value;
                });
                await _saveRxTxPreference(value);
              },
            ),
          ]),

          _buildSectionHeader('Navigation'),
          _buildSettingsCard([
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
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.contacts_outlined),
                title: const Text('Disable Contacts'),
                subtitle: const Text(
                  'Hide the contacts tab to simplify navigation',
                ),
                value: !appProvider.isContactsEnabled,
                onChanged: (value) async {
                  await appProvider.toggleContactsEnabled(!value);
                },
              ),
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.sensors),
                title: const Text('Enable Sensors tab'),
                subtitle: const Text(
                  'Show a dedicated tab for watched relay and node telemetry',
                ),
                value: appProvider.isSensorsEnabled,
                onChanged: (value) async {
                  await appProvider.toggleSensorsEnabled(value);
                },
              ),
            ),
          ]),

          _buildSectionHeader('Messaging'),
          _buildSettingsCard([
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.person_add_alt_1),
                title: const Text('Auto-add discovered contacts'),
                subtitle: const Text(
                  'Automatically fetch and add new contacts when they are discovered',
                ),
                value: appProvider.autoAddDiscoveredContacts,
                onChanged: (value) async {
                  await appProvider.toggleAutoAddDiscoveredContacts(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text('Route path byte size'),
              subtitle: Text(
                '$_routeHashSize byte${_routeHashSize == 1 ? '' : 's'} for manual contact routes',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showRouteHashSizeDialog,
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.swap_horiz),
                title: const Text('Auto route rotation'),
                subtitle: const Text(
                  'Rotate between best known direct paths and flood mode for room/contact sends',
                ),
                value: appProvider.autoRouteRotationEnabled,
                onChanged: (value) async {
                  await appProvider.toggleAutoRouteRotationEnabled(value);
                },
              ),
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.route),
                title: const Text('Clear path on max retry'),
                subtitle: const Text(
                  'Clear the route only after all retries and final router fallback fail',
                ),
                value: appProvider.clearPathOnMaxRetry,
                onChanged: (value) async {
                  await appProvider.toggleClearPathOnMaxRetry(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text(
                'Clear Messages',
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text('Delete all stored message history'),
              onTap: _clearMessages,
            ),
          ]),

          _buildSectionHeader('Voice'),
          Consumer2<AppProvider, ConnectionProvider>(
            builder: (context, appProvider, connectionProvider, child) =>
                _buildVoiceStatsCard(
                  bitrate: _voiceBitrate,
                  connectionProvider: connectionProvider,
                  bandPassEnabled: appProvider.isVoiceBandPassFilterEnabled,
                  compressorEnabled: appProvider.isVoiceCompressorEnabled,
                  limiterEnabled: appProvider.isVoiceLimiterEnabled,
                  silenceTrimEnabled: appProvider.isVoiceSilenceTrimmingEnabled,
                ),
          ),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: const Text('Voice bitrate'),
              subtitle: Text(_voiceBitrateSubtitle(_voiceBitrate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showVoiceBitrateDialog,
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.tune),
                title: const Text('Band-pass filter voice'),
                subtitle: const Text(
                  'Keeps speech frequencies and cuts low/high noise',
                ),
                value: appProvider.isVoiceBandPassFilterEnabled,
                onChanged: (value) async {
                  await appProvider.toggleVoiceBandPassFilterEnabled(value);
                },
              ),
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.compress),
                title: const Text('Voice compressor'),
                subtitle: const Text('Balances quiet and loud speech levels'),
                value: appProvider.isVoiceCompressorEnabled,
                onChanged: (value) async {
                  await appProvider.toggleVoiceCompressorEnabled(value);
                },
              ),
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.speed),
                title: const Text('Voice limiter'),
                subtitle: const Text('Prevents clipping peaks before encoding'),
                value: appProvider.isVoiceLimiterEnabled,
                onChanged: (value) async {
                  await appProvider.toggleVoiceLimiterEnabled(value);
                },
              ),
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => SwitchListTile(
                secondary: const Icon(Icons.content_cut),
                title: const Text('Trim silence in voice messages'),
                subtitle: const Text(
                  'Removes long silent parts before sending voice',
                ),
                value: appProvider.isVoiceSilenceTrimmingEnabled,
                onChanged: (value) async {
                  await appProvider.toggleVoiceSilenceTrimmingEnabled(value);
                },
              ),
            ),
          ]),

          _buildSectionHeader('Images'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.photo_size_select_large),
              title: const Text('Max image size'),
              subtitle: Text('$_imageMaxSize×$_imageMaxSize px'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showImageMaxSizeDialog,
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Image compression'),
              subtitle: Text(
                '$_imageCompression / 90  (higher = smaller file)',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Slider(
                value: _imageCompression.toDouble(),
                min: 10,
                max: 90,
                divisions: 8,
                label: '$_imageCompression',
                onChanged: (v) => setState(() => _imageCompression = v.round()),
                onChangeEnd: (v) => _saveImageCompression(v.round()),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.invert_colors),
              title: const Text('Grayscale'),
              subtitle: const Text(
                'Converts image to grayscale for smaller file size',
              ),
              value: _imageGrayscale,
              onChanged: (value) async {
                await ImagePreferences.setGrayscale(value);
                setState(() => _imageGrayscale = value);
                await _refreshImageModePreview();
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.compress),
              title: const Text('Ultra mode'),
              subtitle: const Text(
                'Extra-aggressive compression with stronger AVIF settings',
              ),
              value: _imageUltraMode,
              onChanged: (value) async {
                await ImagePreferences.setUltraMode(value);
                setState(() {
                  _imageUltraMode = value;
                });
                await _refreshImageModePreview();
              },
            ),
          ]),
          Consumer<ConnectionProvider>(
            builder: (context, connectionProvider, child) =>
                _buildImageModePreviewCard(connectionProvider),
          ),
          _buildSectionHeader('Templates & Help'),
          _buildSettingsCard([
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WelcomeWizardScreen(
                      onCompleted: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
            ),
          ]),

          _buildSectionHeader('Network Sharing'),
          const ConnectionModeSelector(),

          _buildSectionHeader(AppLocalizations.of(context)!.permissionsSection),
          _buildSettingsCard([
            SwitchListTile(
              secondary: const Icon(Icons.gps_fixed),
              title: const Text('Fast private GPS updates'),
              subtitle: const Text(
                'Use private zero-hop updates while moving significantly or while actively using map/messages.',
              ),
              value: _fastLocationUpdatesEnabled,
              onChanged: _setFastLocationUpdatesEnabled,
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Movement threshold'),
              subtitle: Text(
                '${_fastLocationMovementThresholdMeters.toStringAsFixed(0)} m',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editFastLocationMovementThreshold,
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Active-use update interval'),
              subtitle: Text('$_fastLocationActiveCadenceSeconds s'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editFastLocationActiveCadence,
            ),
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
          ]),

          _buildSectionHeader(AppLocalizations.of(context)!.about),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.appVersion),
              subtitle: Text(
                _packageInfo != null
                    ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                    : 'Loading...',
              ),
              onTap: _handleVersionTap,
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
          ]),
          if (Platform.isAndroid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
          _buildSectionHeader('Developer & Data'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text(AppLocalizations.of(context)!.packageName),
              subtitle: Text(_packageInfo?.packageName ?? 'com.meshcore.sar'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                AppLocalizations.of(context)!.sampleData,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                AppLocalizations.of(context)!.sampleDataDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          tiles: children,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ).toList(),
      ),
    );
  }

  Widget _buildImageModePreviewCard(ConnectionProvider connectionProvider) {
    final sourceBytes = _previewSourceBytes;
    final fileName = _previewSourceName ?? 'No image selected';
    final radioBw = connectionProvider.deviceInfo.radioBw;
    final radioSf = connectionProvider.deviceInfo.radioSf;
    final radioCr = connectionProvider.deviceInfo.radioCr;
    final bwHz = _resolveBandwidthHz(radioBw);
    final previewSizeBytes = _previewCompressedBytes?.length ?? 0;
    final directChunk = safeImageDataBytesForPath(0);
    final twoHopChunk = safeImageDataBytesForPath(2);
    final directFragments = previewSizeBytes > 0
        ? (previewSizeBytes + directChunk - 1) ~/ directChunk
        : 0;
    final twoHopFragments = previewSizeBytes > 0
        ? (previewSizeBytes + twoHopChunk - 1) ~/ twoHopChunk
        : 0;
    final imageDirect = estimateImageTransmitDuration(
      fragmentCount: directFragments,
      sizeBytes: previewSizeBytes,
      pathLen: 0,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    final imageTwoHop = estimateImageTransmitDuration(
      fragmentCount: twoHopFragments,
      sizeBytes: previewSizeBytes,
      pathLen: 2,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.photo_library_outlined),
                SizedBox(width: 8),
                Text(
                  'Image mode preview',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Source image',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isPreviewLoading
                      ? null
                      : _selectPreviewImageFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Select from gallery'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fileName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (previewSizeBytes > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Preview tx (this image): Direct ${_formatEstimateDuration(imageDirect)} • 2-hop ${_formatEstimateDuration(imageTwoHop)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Radio BW ${_formatBandwidthLabel(bwHz)} · SF ${radioSf ?? 10} · CR ${radioCr ?? 5}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _showCurrentImagePreview
                        ? 'Showing: current image mode'
                        : 'Showing: source image',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Switch.adaptive(
                  value: _showCurrentImagePreview,
                  onChanged: (value) {
                    setState(() => _showCurrentImagePreview = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: _showCurrentImagePreview
                    ? (_isPreviewLoading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : (_previewCompressedBytes != null
                                ? AvifImage.memory(
                                    _previewCompressedBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.black12)))
                    : (sourceBytes != null
                          ? Image.memory(sourceBytes, fit: BoxFit.cover)
                          : Container(color: Colors.black12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEstimateDuration(Duration value) {
    if (value.inSeconds < 60) return '~${value.inSeconds}s';
    return '~${value.inMinutes}m ${value.inSeconds % 60}s';
  }

  static String _formatBandwidthLabel(int bwHz) {
    if (bwHz >= 1000000) return '${(bwHz / 1000000).toStringAsFixed(2)} MHz';
    if (bwHz >= 1000) return '${(bwHz / 1000).toStringAsFixed(1)} kHz';
    return '$bwHz Hz';
  }

  int _resolveBandwidthHz(int? rawBw) {
    if (rawBw == null) return 250000;
    if (rawBw > 1000) return rawBw;
    switch (rawBw) {
      case 0:
        return 7800;
      case 1:
        return 10400;
      case 2:
        return 15600;
      case 3:
        return 20800;
      case 4:
        return 31250;
      case 5:
        return 41700;
      case 6:
        return 62500;
      case 7:
        return 125000;
      case 8:
        return 250000;
      case 9:
        return 500000;
      default:
        return 250000;
    }
  }

  Widget _buildVoiceStatsCard({
    required int bitrate,
    required ConnectionProvider connectionProvider,
    required bool bandPassEnabled,
    required bool compressorEnabled,
    required bool limiterEnabled,
    required bool silenceTrimEnabled,
  }) {
    final supported = VoiceBitratePreferences.supportedBitrates;
    final minBitrate = supported.reduce((a, b) => a < b ? a : b).toDouble();
    final maxBitrate = supported.reduce((a, b) => a > b ? a : b).toDouble();
    final normalized = maxBitrate > minBitrate
        ? ((bitrate - minBitrate) / (maxBitrate - minBitrate)).clamp(0.0, 1.0)
        : 1.0;
    final enabledCount =
        (bandPassEnabled ? 1 : 0) +
        (compressorEnabled ? 1 : 0) +
        (limiterEnabled ? 1 : 0) +
        (silenceTrimEnabled ? 1 : 0);
    final radioBw = connectionProvider.deviceInfo.radioBw;
    final radioSf = connectionProvider.deviceInfo.radioSf;
    final radioCr = connectionProvider.deviceInfo.radioCr;
    final bwHz = _resolveBandwidthHz(radioBw);
    final voiceMode = VoiceBitratePreferences.toVoiceMode(bitrate);
    const voicePreviewMs = 10000; // 10-second reference clip
    final packetDurationMs = codec2ModeFor(voiceMode).packetDurationMs;
    final voicePacketCount =
        (voicePreviewMs + packetDurationMs - 1) ~/ packetDurationMs;
    final voiceDirect = estimateVoiceTransmitDuration(
      mode: voiceMode,
      packetCount: voicePacketCount,
      durationMs: voicePreviewMs,
      pathLen: 0,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
    final voiceTwoHop = estimateVoiceTransmitDuration(
      mode: voiceMode,
      packetCount: voicePacketCount,
      durationMs: voicePreviewMs,
      pathLen: 2,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Processing Stats',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Bitrate: $bitrate bps',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Preview tx (10s ${voiceMode.label}): Direct ${_formatEstimateDuration(voiceDirect)} • 2-hop ${_formatEstimateDuration(voiceTwoHop)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Radio BW ${_formatBandwidthLabel(bwHz)} · SF ${radioSf ?? 10} · CR ${radioCr ?? 5}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: normalized, minHeight: 8),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _voiceStatChip(
                    label: 'Band-pass',
                    enabled: bandPassEnabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _voiceStatChip(
                    label: 'Compressor',
                    enabled: compressorEnabled,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _voiceStatChip(
                    label: 'Limiter',
                    enabled: limiterEnabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _voiceStatChip(
                    label: 'Silence trim',
                    enabled: silenceTrimEnabled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Processing enabled: $enabledCount/4',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceStatChip({required String label, required bool enabled}) {
    final color = enabled ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseTheme),
        content: SingleChildScrollView(
          child: RadioGroup<AppThemeMode>(
            groupValue: _selectedTheme,
            onChanged: (value) {
              _handleThemeChange(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text(AppLocalizations.of(context)!.light),
                  subtitle: Text(AppLocalizations.of(context)!.blueLightTheme),
                  value: AppThemeMode.light,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(AppLocalizations.of(context)!.dark),
                  subtitle: Text(AppLocalizations.of(context)!.blueDarkTheme),
                  value: AppThemeMode.dark,
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
                  subtitle: Text(
                    AppLocalizations.of(context)!.safeAllClearMode,
                  ),
                  value: AppThemeMode.sarGreen,
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
                ),
                const Divider(),
                RadioListTile<AppThemeMode>(
                  title: Text(AppLocalizations.of(context)!.autoSystem),
                  subtitle: Text(
                    AppLocalizations.of(context)!.followSystemTheme,
                  ),
                  value: AppThemeMode.system,
                ),
              ],
            ),
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
          child: RadioGroup<Locale?>(
            groupValue: _selectedLocale,
            onChanged: (value) {
              _handleLocaleChange(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale?>(
                  title: Text(LocalePreferences.getDisplayName(null)),
                  subtitle: Text(LocalePreferences.getDisplayName(null)),
                  value: null,
                ),
                const Divider(),
                ...LocalePreferences.supportedLocales.map((locale) {
                  return RadioListTile<Locale?>(
                    title: Text(LocalePreferences.getNativeDisplayName(locale)),
                    value: locale,
                  );
                }),
              ],
            ),
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

  void _showImageMaxSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max image size'),
        content: SingleChildScrollView(
          child: RadioGroup<int>(
            groupValue: _imageMaxSize,
            onChanged: (value) {
              if (value != null) _saveImageMaxSize(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ImagePreferences.supportedSizes
                  .map(
                    (size) => RadioListTile<int>(
                      value: size,
                      title: Text('$size×$size px'),
                      subtitle: size == ImagePreferences.defaultMaxSize
                          ? const Text('Default')
                          : null,
                    ),
                  )
                  .toList(),
            ),
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

  void _showVoiceBitrateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice bitrate'),
        content: SingleChildScrollView(
          child: RadioGroup<int>(
            groupValue: _voiceBitrate,
            onChanged: (value) {
              if (value != null) {
                _saveVoiceBitratePreference(value);
              }
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: VoiceBitratePreferences.supportedBitrates
                  .map(
                    (bitrate) => RadioListTile<int>(
                      value: bitrate,
                      title: Text('$bitrate bps'),
                      subtitle:
                          bitrate == VoiceBitratePreferences.defaultBitrate
                          ? const Text('Default')
                          : null,
                    ),
                  )
                  .toList(),
            ),
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
