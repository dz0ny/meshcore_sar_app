import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/app_provider.dart';
import '../services/location_tracking_service.dart';
import '../utils/sample_data_generator.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppThemeMode) onThemeChanged;
  final AppThemeMode currentTheme;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppThemeMode _selectedTheme;
  PackageInfo? _packageInfo;
  bool _isLoadingSampleData = false;
  final LocationTrackingService _locationService = LocationTrackingService();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _loadPackageInfo();
    _initializeLocationService();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
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
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.orange,
              ),
            );
          }
        };

        _locationService.onBroadcastSent = (position) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location broadcast: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
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
        final wasTracking = prefs.getBool('background_tracking_enabled') ?? false;

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
        objectCount: 1,
      );

      final channelMessages = SampleDataGenerator.generateChannelMessages(
        centerLocation: centerLocation,
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
    final success = await _locationService.startTracking(
      distanceThreshold: _locationService.gpsUpdateDistance,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to start background tracking. Check permissions and BLE connection.',
          ),
          duration: Duration(seconds: 3),
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
      const SnackBar(
        content: Text('All data cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // General Settings Section
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(AppTheme.getThemeDisplayName(_selectedTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(),
          ),
          const Divider(),

          // Location Settings Section
          _buildSectionHeader('Location Broadcasting'),

          // Automatic tracking settings
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('Auto Location Tracking'),
            subtitle: const Text('Automatically broadcast position updates'),
            value: _locationService.isTracking,
            onChanged: (value) {
              if (value) {
                _startBackgroundTracking();
              } else {
                _stopBackgroundTracking();
              }
            },
          ),

          if (_locationService.isTracking) ...[
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Configure Tracking'),
              subtitle: const Text('Distance and time thresholds'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTrackingConfigDialog(),
            ),
          ],

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

  void _showTrackingConfigDialog() {
    double tempMinDistance = _locationService.minDistanceMeters;
    double tempMaxDistance = _locationService.maxDistanceMeters;
    int tempTimeInterval = _locationService.minTimeIntervalSeconds;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Location Tracking Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  'Configure when location broadcasts are sent to the mesh network',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Minimum Distance
                Text(
                  'Minimum Distance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Broadcast only after moving ${tempMinDistance.toStringAsFixed(0)} meters',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                  ),
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
                  'Maximum Distance',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Always broadcast after moving ${tempMaxDistance.toStringAsFixed(0)} meters',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                  ),
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
                      Text('${tempMinDistance.toStringAsFixed(0)}m',
                        style: Theme.of(context).textTheme.bodySmall),
                      Text('500m', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Minimum Time Interval
                Text(
                  'Minimum Time Interval',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Always broadcast every ${_formatDuration(tempTimeInterval)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    showValueIndicator: ShowValueIndicator.always,
                  ),
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
                      Text('10min', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
                  await _locationService.updateDistanceThreshold(tempMinDistance);
                }

                // Close dialog before setState
                Navigator.pop(context);

                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Save'),
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
        title: const Text('Choose Theme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Blue light theme'),
                value: AppThemeMode.light,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Blue dark theme'),
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
                    const Text('SAR Red'),
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
                subtitle: const Text('Alert/Emergency mode'),
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
                    const Text('SAR Green'),
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
                subtitle: const Text('Safe/All Clear mode'),
                value: AppThemeMode.sarGreen,
                groupValue: _selectedTheme,
                onChanged: (value) {
                  _handleThemeChange(value);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              RadioListTile<AppThemeMode>(
                title: const Text('Auto (System)'),
                subtitle: const Text('Follow system theme'),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
