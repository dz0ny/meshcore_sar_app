import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/app_provider.dart';
import '../services/background_location_service.dart';
import '../utils/sample_data_generator.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selectedTheme;
  PackageInfo? _packageInfo;
  bool _isLoadingSampleData = false;
  double _gpsUpdateDistance = 10.0;
  bool _backgroundTrackingEnabled = false;
  final BackgroundLocationService _backgroundLocationService = BackgroundLocationService();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _loadPackageInfo();
    _loadLocationSettings();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _loadLocationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _gpsUpdateDistance = prefs.getDouble('map_gps_update_distance') ?? 10.0;
        _backgroundTrackingEnabled = prefs.getBool('background_tracking_enabled') ?? false;
      });

      // Initialize background location service
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final appProvider = context.read<AppProvider>();
          _backgroundLocationService.initialize(appProvider.connectionProvider.bleService);

          // Restore background tracking state
          if (_backgroundTrackingEnabled) {
            _startBackgroundTracking();
          }
        }
      });
    }
  }

  Future<void> _saveLocationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('map_gps_update_distance', _gpsUpdateDistance);
    await prefs.setBool('background_tracking_enabled', _backgroundTrackingEnabled);
  }

  Future<void> _saveThemePreference(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme.name);
  }

  void _handleThemeChange(ThemeMode? theme) {
    if (theme != null) {
      setState(() {
        _selectedTheme = theme;
      });
      _saveThemePreference(theme);
      widget.onThemeChanged(theme);
    }
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

      // Generate sample data
      final contacts = SampleDataGenerator.generateContacts(
        centerLocation: centerLocation,
        teamMemberCount: 5,
        channelCount: 2,
      );

      final sarMessages = SampleDataGenerator.generateSarMarkerMessages(
        centerLocation: centerLocation,
        foundPersonCount: 2,
        fireCount: 1,
        stagingCount: 1,
      );

      final channelMessages = SampleDataGenerator.generateChannelMessages(
        generalChannelMessages: 8,
        emergencyChannelMessages: 5,
      );

      // Combine all messages
      final allMessages = [...sarMessages, ...channelMessages];

      // Add to providers
      final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
      final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);

      contactsProvider.addContacts(contacts);
      messagesProvider.addMessages(allMessages);

      if (!mounted) return;

      final teamCount = contacts.where((c) => c.isChat).length;
      final channelCount = contacts.where((c) => c.isRoom).length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded $teamCount team members, $channelCount channels, ${sarMessages.length} SAR markers, ${channelMessages.length} messages',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sample data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingSampleData = false);
      }
    }
  }

  Future<void> _startBackgroundTracking() async {
    final success = await _backgroundLocationService.startTracking(
      distanceThreshold: _gpsUpdateDistance,
    );

    if (!success) {
      if (mounted) {
        setState(() {
          _backgroundTrackingEnabled = false;
        });
        _saveLocationSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start background tracking. Check permissions and BLE connection.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopBackgroundTracking() async {
    await _backgroundLocationService.stopTracking();
  }

  Future<void> _clearSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will clear all contacts and SAR markers. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);

    contactsProvider.clearContacts();
    messagesProvider.clearAll();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // General Settings Section
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_getThemeLabel(_selectedTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(),
          ),
          const Divider(),

          // Location Settings Section
          _buildSectionHeader('Location'),
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('GPS Update Distance'),
            subtitle: Text('${_gpsUpdateDistance.toStringAsFixed(0)} meters'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGpsDistanceDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('Background Location Tracking'),
            subtitle: const Text('Send position updates to mesh network'),
            value: _backgroundTrackingEnabled,
            onChanged: (value) {
              setState(() {
                _backgroundTrackingEnabled = value;
                if (value) {
                  _startBackgroundTracking();
                } else {
                  _stopBackgroundTracking();
                }
              });
              _saveLocationSettings();
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(
              _packageInfo != null
                  ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                  : 'Loading...',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('App Name'),
            subtitle: Text(_packageInfo?.appName ?? 'MeshCore SAR'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('About MeshCore SAR'),
            subtitle: const Text(
              'Search & Rescue application with BLE mesh networking and offline maps',
            ),
            onTap: () => _showAboutDialog(),
          ),
          const Divider(),

          // Developer Section
          _buildSectionHeader('Developer'),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Package Name'),
            subtitle: Text(_packageInfo?.packageName ?? 'com.meshcore.sar'),
          ),
          const Divider(),

          // Sample Data Section
          _buildSectionHeader('Sample Data'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Load or clear sample contacts, channel messages, and SAR markers for testing',
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
                    label: const Text('Load Sample Data'),
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
                    label: const Text('Clear All Data'),
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

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Auto (System)';
    }
  }

  void _showGpsDistanceDialog() {
    double tempDistance = _gpsUpdateDistance;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('GPS Update Distance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Position updates sent every ${tempDistance.toStringAsFixed(0)} meters',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempDistance,
                min: 1,
                max: 100,
                divisions: 99,
                label: '${tempDistance.toStringAsFixed(0)}m',
                onChanged: (value) {
                  setDialogState(() {
                    tempDistance = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '100m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _gpsUpdateDistance = tempDistance;
                });
                _saveLocationSettings();

                // Update background tracking if active
                if (_backgroundTrackingEnabled) {
                  _backgroundLocationService.updateDistanceThreshold(tempDistance);
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: _selectedTheme,
              onChanged: (value) {
                _handleThemeChange(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: _selectedTheme,
              onChanged: (value) {
                _handleThemeChange(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Auto (System)'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: _selectedTheme,
              onChanged: (value) {
                _handleThemeChange(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About MeshCore SAR'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MeshCore SAR',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${_packageInfo?.version ?? '1.0.0'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'A Search & Rescue application designed for emergency response teams. '
                'Features include:\n\n'
                '• BLE mesh networking for device-to-device communication\n'
                '• Offline maps with multiple layer options\n'
                '• Real-time team member tracking\n'
                '• SAR tactical markers (found person, fire, staging)\n'
                '• Contact management and messaging\n'
                '• GPS tracking with compass heading\n'
                '• Map tile caching for offline use',
              ),
              const SizedBox(height: 16),
              Text(
                'Technologies Used:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Flutter for cross-platform development\n'
                '• BLE (Bluetooth Low Energy) for mesh networking\n'
                '• OpenStreetMap for mapping\n'
                '• Provider for state management\n'
                '• SharedPreferences for local storage',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
