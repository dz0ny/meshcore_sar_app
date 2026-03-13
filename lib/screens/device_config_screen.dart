import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/device_info.dart';
import '../providers/connection_provider.dart';
import '../services/validation_service.dart';
import '../l10n/app_localizations.dart';

class DeviceConfigScreen extends StatefulWidget {
  const DeviceConfigScreen({super.key});

  @override
  State<DeviceConfigScreen> createState() => _DeviceConfigScreenState();
}

class _DeviceConfigScreenState extends State<DeviceConfigScreen> {
  static const List<_RadioPreset> _radioPresets = [
    _RadioPreset(
      id: 'australia',
      label: 'Australia',
      summary: '915.800 MHz, BW 250 kHz, SF10, CR5',
      frequencyKhz: 915800,
      bandwidth: 8,
      spreadingFactor: 10,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'australia_narrow',
      label: 'Australia (Narrow)',
      summary: '916.575 MHz, BW 62.5 kHz, SF7, CR8',
      frequencyKhz: 916575,
      bandwidth: 6,
      spreadingFactor: 7,
      codingRate: 8,
    ),
    _RadioPreset(
      id: 'australia_sa_wa',
      label: 'Australia: SA, WA',
      summary: '923.125 MHz, BW 62.5 kHz, SF8, CR8',
      frequencyKhz: 923125,
      bandwidth: 6,
      spreadingFactor: 8,
      codingRate: 8,
    ),
    _RadioPreset(
      id: 'australia_qld',
      label: 'Australia: QLD',
      summary: '923.125 MHz, BW 62.5 kHz, SF8, CR5',
      frequencyKhz: 923125,
      bandwidth: 6,
      spreadingFactor: 8,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'eu_uk_narrow',
      label: 'EU/UK (Narrow)',
      summary: '869.618 MHz, BW 62.5 kHz, SF8, CR8',
      frequencyKhz: 869618,
      bandwidth: 6,
      spreadingFactor: 8,
      codingRate: 8,
    ),
    _RadioPreset(
      id: 'eu_uk_deprecated',
      label: 'EU/UK (Deprecated)',
      summary: '869.525 MHz, BW 250 kHz, SF11, CR5',
      frequencyKhz: 869525,
      bandwidth: 8,
      spreadingFactor: 11,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'czech_republic_narrow',
      label: 'Czech Republic (Narrow)',
      summary: '869.432 MHz, BW 62.5 kHz, SF7, CR5',
      frequencyKhz: 869432,
      bandwidth: 6,
      spreadingFactor: 7,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'eu_433_long_range',
      label: 'EU 433MHz (Long Range)',
      summary: '433.650 MHz, BW 250 kHz, SF11, CR5',
      frequencyKhz: 433650,
      bandwidth: 8,
      spreadingFactor: 11,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'new_zealand',
      label: 'New Zealand',
      summary: '917.375 MHz, BW 250 kHz, SF11, CR5',
      frequencyKhz: 917375,
      bandwidth: 8,
      spreadingFactor: 11,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'new_zealand_narrow',
      label: 'New Zealand (Narrow)',
      summary: '917.375 MHz, BW 62.5 kHz, SF7, CR5',
      frequencyKhz: 917375,
      bandwidth: 6,
      spreadingFactor: 7,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'portugal_433',
      label: 'Portugal 433',
      summary: '433.375 MHz, BW 62.5 kHz, SF9, CR6',
      frequencyKhz: 433375,
      bandwidth: 6,
      spreadingFactor: 9,
      codingRate: 6,
    ),
    _RadioPreset(
      id: 'portugal_868',
      label: 'Portugal 868',
      summary: '869.618 MHz, BW 62.5 kHz, SF7, CR6',
      frequencyKhz: 869618,
      bandwidth: 6,
      spreadingFactor: 7,
      codingRate: 6,
    ),
    _RadioPreset(
      id: 'switzerland',
      label: 'Switzerland',
      summary: '869.618 MHz, BW 62.5 kHz, SF8, CR8',
      frequencyKhz: 869618,
      bandwidth: 6,
      spreadingFactor: 8,
      codingRate: 8,
    ),
    _RadioPreset(
      id: 'usa_canada_recommended',
      label: 'USA/Canada (Recommended)',
      summary: '910.525 MHz, BW 62.5 kHz, SF7, CR5',
      frequencyKhz: 910525,
      bandwidth: 6,
      spreadingFactor: 7,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'vietnam_narrow',
      label: 'Vietnam (Narrow)',
      summary: '920.250 MHz, BW 62.5 kHz, SF8, CR5',
      frequencyKhz: 920250,
      bandwidth: 6,
      spreadingFactor: 8,
      codingRate: 5,
    ),
    _RadioPreset(
      id: 'vietnam_deprecated',
      label: 'Vietnam (Deprecated)',
      summary: '920.250 MHz, BW 250 kHz, SF11, CR5',
      frequencyKhz: 920250,
      bandwidth: 8,
      spreadingFactor: 11,
      codingRate: 5,
    ),
  ];

  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _freqController;
  late TextEditingController _txPowerController;

  bool _telemetryEnabled = false;
  bool _repeatEnabled = false;
  bool _showCustomRadioSettings = false;
  bool _isSavingPublicInfo = false;
  bool _isSavingRadioSettings = false;
  bool _publicInfoSaved = false;
  bool _radioSettingsSaved = false;
  String? _publicInfoError;
  String? _radioSettingsError;
  String _selectedBandwidth = '62.5 kHz';
  int _selectedSpreadingFactor = 8;
  int _selectedCodingRate = 8;
  _RadioPreset? _selectedRadioPreset;

  final List<String> _bandwidthOptions = [
    '7.8 kHz',
    '10.4 kHz',
    '15.6 kHz',
    '20.8 kHz',
    '31.25 kHz',
    '41.7 kHz',
    '62.5 kHz',
    '125 kHz',
    '250 kHz',
    '500 kHz',
  ];

  @override
  void initState() {
    super.initState();
    final deviceInfo = context.read<ConnectionProvider>().deviceInfo;

    _nameController = TextEditingController(
      text: deviceInfo.selfName ?? deviceInfo.deviceName ?? '',
    );
    _latController = TextEditingController(
      text: deviceInfo.advLat != null
          ? (deviceInfo.advLat! / 1000000).toStringAsFixed(6)
          : '0.0',
    );
    _lonController = TextEditingController(
      text: deviceInfo.advLon != null
          ? (deviceInfo.advLon! / 1000000).toStringAsFixed(6)
          : '0.0',
    );
    _freqController = TextEditingController(
      text: deviceInfo.radioFreq != null
          ? (deviceInfo.radioFreq! / 1000).toStringAsFixed(3)
          : '869.618',
    );
    _txPowerController = TextEditingController(
      text: deviceInfo.txPower?.toString() ?? '20',
    );

    if (deviceInfo.radioBw != null &&
        deviceInfo.radioBw! >= 0 &&
        deviceInfo.radioBw! <= 9) {
      _selectedBandwidth = _bandwidthFromValue(deviceInfo.radioBw!);
    }
    if (deviceInfo.radioSf != null &&
        deviceInfo.radioSf! >= 7 &&
        deviceInfo.radioSf! <= 12) {
      _selectedSpreadingFactor = deviceInfo.radioSf!;
    }
    if (deviceInfo.radioCr != null &&
        deviceInfo.radioCr! >= 5 &&
        deviceInfo.radioCr! <= 8) {
      _selectedCodingRate = deviceInfo.radioCr!;
    }

    _selectedRadioPreset = _matchRadioPreset(
      frequencyKhz: deviceInfo.radioFreq,
      bandwidth: deviceInfo.radioBw,
      spreadingFactor: deviceInfo.radioSf,
      codingRate: deviceInfo.radioCr,
    );
    _showCustomRadioSettings = _selectedRadioPreset == null;

    // Check if telemetry is enabled (check if lat/lon are set and not zero)
    _telemetryEnabled =
        (deviceInfo.advLat != null && deviceInfo.advLat! != 0) ||
        (deviceInfo.advLon != null && deviceInfo.advLon! != 0);

    // Initialize repeat mode from device info (firmware v9+)
    _repeatEnabled = deviceInfo.clientRepeat ?? false;

    // Fetch allowed repeat frequencies on open if device supports repeat mode
    if (deviceInfo.clientRepeat != null &&
        deviceInfo.allowedRepeatFreqRanges == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ConnectionProvider>().getAllowedRepeatFreq();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().getBatteryAndStorage();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _freqController.dispose();
    _txPowerController.dispose();
    super.dispose();
  }

  String _bandwidthFromValue(int bw) {
    switch (bw) {
      case 0:
        return '7.8 kHz';
      case 1:
        return '10.4 kHz';
      case 2:
        return '15.6 kHz';
      case 3:
        return '20.8 kHz';
      case 4:
        return '31.25 kHz';
      case 5:
        return '41.7 kHz';
      case 6:
        return '62.5 kHz';
      case 7:
        return '125 kHz';
      case 8:
        return '250 kHz';
      case 9:
        return '500 kHz';
      default:
        return '62.5 kHz';
    }
  }

  int _bandwidthToValue(String bw) {
    return _bandwidthOptions.indexOf(bw);
  }

  _RadioPreset? _matchRadioPreset({
    int? frequencyKhz,
    int? bandwidth,
    int? spreadingFactor,
    int? codingRate,
  }) {
    if (frequencyKhz == null ||
        bandwidth == null ||
        spreadingFactor == null ||
        codingRate == null) {
      return null;
    }

    for (final preset in _radioPresets) {
      if (preset.frequencyKhz == frequencyKhz &&
          preset.bandwidth == bandwidth &&
          preset.spreadingFactor == spreadingFactor &&
          preset.codingRate == codingRate) {
        return preset;
      }
    }
    return null;
  }

  void _applyRadioPreset(_RadioPreset preset) {
    setState(() {
      _selectedRadioPreset = preset;
      _freqController.text = (preset.frequencyKhz / 1000).toStringAsFixed(3);
      _selectedBandwidth = _bandwidthFromValue(preset.bandwidth);
      _selectedSpreadingFactor = preset.spreadingFactor;
      _selectedCodingRate = preset.codingRate;
      _showCustomRadioSettings = false;
    });
  }

  void _syncRadioPresetSelection() {
    final freqResult = ValidationService().parseFrequency(_freqController.text);
    final matchedPreset = freqResult.isSuccess
        ? _matchRadioPreset(
            frequencyKhz: (freqResult.value! * 1000).round(),
            bandwidth: _bandwidthToValue(_selectedBandwidth),
            spreadingFactor: _selectedSpreadingFactor,
            codingRate: _selectedCodingRate,
          )
        : null;

    _selectedRadioPreset = matchedPreset;
    _showCustomRadioSettings = matchedPreset == null;
  }

  void _markPublicInfoDirty() {
    if (_publicInfoSaved || _publicInfoError != null) {
      setState(() {
        _publicInfoSaved = false;
        _publicInfoError = null;
      });
    }
  }

  void _markRadioSettingsDirty() {
    if (_radioSettingsSaved || _radioSettingsError != null) {
      setState(() {
        _radioSettingsSaved = false;
        _radioSettingsError = null;
      });
    }
  }

  Future<void> _savePublicInfo() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final deviceInfo = connectionProvider.deviceInfo;
    final validator = ValidationService();

    setState(() {
      _isSavingPublicInfo = true;
      _publicInfoSaved = false;
      _publicInfoError = null;
    });

    try {
      // Save name
      if (_nameController.text.isNotEmpty) {
        await connectionProvider.setAdvertName(_nameController.text);
      }

      // Save position and telemetry settings
      if (_telemetryEnabled) {
        // Parse and validate coordinates
        final latResult = validator.parseLatitude(_latController.text);
        if (!latResult.isSuccess) {
          if (mounted) {
            setState(() {
              _publicInfoError = latResult.errorMessage!;
              _isSavingPublicInfo = false;
            });
          }
          return;
        }

        final lonResult = validator.parseLongitude(_lonController.text);
        if (!lonResult.isSuccess) {
          if (mounted) {
            setState(() {
              _publicInfoError = lonResult.errorMessage!;
              _isSavingPublicInfo = false;
            });
          }
          return;
        }

        await connectionProvider.setAdvertLatLon(
          latitude: latResult.value!,
          longitude: lonResult.value!,
        );

        // Set telemetry modes to "Allow All" (mode 2 for both base and location)
        final telemetryModes = 0x0A; // binary: 00001010 (base=2, location=2)
        await connectionProvider.setOtherParams(
          manualAddContacts: deviceInfo.manualAddContacts == true ? 1 : 0,
          telemetryModes: telemetryModes,
          advertLocationPolicy: 1,
        );
      } else {
        // Clear position
        await connectionProvider.setAdvertLatLon(latitude: 0.0, longitude: 0.0);

        // Set telemetry modes to "Deny" (mode 0)
        final telemetryModes = 0x00;
        await connectionProvider.setOtherParams(
          manualAddContacts: deviceInfo.manualAddContacts == true ? 1 : 0,
          telemetryModes: telemetryModes,
          advertLocationPolicy: 0,
        );
      }

      // Refetch device info to update UI with new settings
      await connectionProvider.refreshDeviceInfo();

      if (mounted) {
        setState(() {
          _isSavingPublicInfo = false;
          _publicInfoSaved = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingPublicInfo = false;
          _publicInfoError = AppLocalizations.of(
            context,
          )!.failedToSave(e.toString());
        });
      }
    }
  }

  Future<void> _saveRadioSettings() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final validator = ValidationService();
    final deviceInfo = connectionProvider.deviceInfo;

    setState(() {
      _isSavingRadioSettings = true;
      _radioSettingsSaved = false;
      _radioSettingsError = null;
    });

    try {
      // Parse and validate frequency
      final freqResult = validator.parseFrequency(_freqController.text);
      if (!freqResult.isSuccess) {
        if (mounted) {
          setState(() {
            _radioSettingsError = freqResult.errorMessage!;
            _isSavingRadioSettings = false;
          });
        }
        return;
      }

      // Parse and validate TX power
      final txPowerResult = validator.parseTxPower(
        _txPowerController.text,
        maxPower: deviceInfo.maxTxPower,
      );
      if (!txPowerResult.isSuccess) {
        if (mounted) {
          setState(() {
            _radioSettingsError = txPowerResult.errorMessage!;
            _isSavingRadioSettings = false;
          });
        }
        return;
      }

      // Convert from MHz to kHz for protocol
      final freqKhz = (freqResult.value! * 1000).round();

      await connectionProvider.setRadioParams(
        frequency: freqKhz,
        bandwidth: _bandwidthToValue(_selectedBandwidth),
        spreadingFactor: _selectedSpreadingFactor,
        codingRate: _selectedCodingRate,
        repeat: deviceInfo.clientRepeat != null ? _repeatEnabled : null,
      );

      // Save TX power
      await connectionProvider.setTxPower(txPowerResult.value!);

      // Refetch device info to update UI with new settings
      await connectionProvider.refreshDeviceInfo();

      if (mounted) {
        setState(() {
          _isSavingRadioSettings = false;
          _radioSettingsSaved = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingRadioSettings = false;
          _radioSettingsError = AppLocalizations.of(
            context,
          )!.failedToSave(e.toString());
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.locationServicesDisabled,
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.locationPermissionDenied,
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.locationPermissionPermanentlyDenied,
              ),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _telemetryEnabled = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationBroadcast(
                position.latitude.toStringAsFixed(6),
                position.longitude.toStringAsFixed(6),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToGetLocation(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Wipe device data'),
        content: const Text(
          'This will erase all data on the connected device, including contacts, keys, and saved settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Wipe device'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      await connectionProvider.factoryResetDevice();
      if (!mounted) return;

      if (connectionProvider.error != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(connectionProvider.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Factory reset command sent. The device should reboot and disconnect shortly.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to wipe device data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationSet =
        (deviceInfo.advLat != null && deviceInfo.advLat != 0) ||
        (deviceInfo.advLon != null && deviceInfo.advLon != 0);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.55),
              colorScheme.surface,
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _ConfigHeroCard(
                title:
                    deviceInfo.selfName ?? deviceInfo.deviceName ?? 'MeshCore',
                subtitle:
                    '${_getDeviceTypeString(context, deviceInfo.deviceType)} • ${deviceInfo.semanticVersion ?? deviceInfo.manufacturerModel ?? AppLocalizations.of(context)!.unknown}',
                stats: [
                  _HeroStatData(
                    label: 'Location',
                    value: locationSet ? 'Shared' : 'Hidden',
                    icon: Icons.my_location_rounded,
                    emphasized: locationSet,
                  ),
                  _HeroStatData(
                    label: 'Frequency',
                    value: '${_freqController.text} MHz',
                    icon: Icons.settings_input_antenna_rounded,
                  ),
                  _HeroStatData(
                    label: 'Bandwidth',
                    value: _selectedBandwidth,
                    icon: Icons.width_normal_rounded,
                  ),
                  _HeroStatData(
                    label: 'Model',
                    value:
                        deviceInfo.manufacturerModel ??
                        AppLocalizations.of(context)!.unknown,
                    icon: Icons.memory_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ConfigSectionCard(
                title: 'Storage',
                subtitle: 'Available space on this device.',
                icon: Icons.storage_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StorageStat(
                            label: 'Used',
                            value: _formatStorage(
                              deviceInfo.storageUsedKb ?? 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StorageStat(
                            label: 'Total',
                            value: deviceInfo.storageTotalKb != null
                                ? _formatStorage(deviceInfo.storageTotalKb!)
                                : AppLocalizations.of(context)!.unknown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _StorageUsageMeter(deviceInfo: deviceInfo),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.publicInfo,
                subtitle: 'Choose the name and location this device shares.',
                icon: Icons.public_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingHighlightCard(
                      icon: _telemetryEnabled
                          ? Icons.travel_explore
                          : Icons.location_disabled,
                      title: AppLocalizations.of(
                        context,
                      )!.telemetryAndLocationSharing,
                      description: 'Share your location with nearby devices.',
                      accentColor: _telemetryEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _telemetryEnabled,
                        onChanged: (value) {
                          setState(() {
                            _telemetryEnabled = value;
                            _publicInfoSaved = false;
                            _publicInfoError = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => _markPublicInfoDirty(),
                      decoration: InputDecoration(
                        labelText: 'Device name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        helperText:
                            'This is the name other devices will see on the mesh.',
                      ),
                    ),
                    if (_telemetryEnabled) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shared location',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set coordinates manually or use your current location.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _CompactCoordinateField(
                                    controller: _latController,
                                    label: 'Latitude',
                                    onChanged: (_) => _markPublicInfoDirty(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _CompactCoordinateField(
                                    controller: _lonController,
                                    label: 'Longitude',
                                    onChanged: (_) => _markPublicInfoDirty(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: _useCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 20),
                                  tooltip: AppLocalizations.of(
                                    context,
                                  )!.useCurrentLocation,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_publicInfoError != null) ...[
                      Text(
                        _publicInfoError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: _SaveActionButton(
                        onPressed: _isSavingPublicInfo ? null : _savePublicInfo,
                        isSaving: _isSavingPublicInfo,
                        isSaved: _publicInfoSaved,
                        label: 'Save public info',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.radioSettings,
                subtitle: 'Choose a preset or fine-tune custom radio settings.',
                icon: Icons.settings_input_antenna_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<_RadioPreset?>(
                      key: ValueKey(_selectedRadioPreset?.id ?? 'custom'),
                      initialValue: _selectedRadioPreset,
                      decoration: InputDecoration(
                        labelText: 'Radio preset',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        helperText:
                            'Start with an official preset, or switch to custom settings below.',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<_RadioPreset?>(
                          value: null,
                          child: Text('Custom'),
                        ),
                        ..._radioPresets.map(
                          (preset) => DropdownMenuItem<_RadioPreset?>(
                            value: preset,
                            child: Text(
                              preset.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (preset) {
                        if (preset == null) {
                          setState(() {
                            _selectedRadioPreset = null;
                            _showCustomRadioSettings = true;
                            _radioSettingsSaved = false;
                            _radioSettingsError = null;
                          });
                          return;
                        }
                        _applyRadioPreset(preset);
                        _markRadioSettingsDirty();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedRadioPreset != null)
                      _SelectedPresetCard(preset: _selectedRadioPreset!),
                    const SizedBox(height: 8),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        initiallyExpanded: _showCustomRadioSettings,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _showCustomRadioSettings = expanded;
                            if (expanded) {
                              _selectedRadioPreset = null;
                            }
                          });
                        },
                        title: Text(
                          'Custom settings',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          'Adjust frequency, bandwidth, spreading factor, coding rate, and power.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          const SizedBox(height: 12),
                          TextField(
                            controller: _freqController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.frequencyMHz,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLowest,
                              helperText:
                                  'Enter the channel frequency, for example 869.618.',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) {
                              setState(_syncRadioPresetSelection);
                              _markRadioSettingsDirty();
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: ValueKey('bandwidth-$_selectedBandwidth'),
                            initialValue: _selectedBandwidth,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.bandwidth,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLowest,
                            ),
                            items: _bandwidthOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedBandwidth = newValue;
                                  _syncRadioPresetSelection();
                                });
                                _markRadioSettingsDirty();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              'spreading-factor-$_selectedSpreadingFactor',
                            ),
                            initialValue: _selectedSpreadingFactor,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.spreadingFactor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLowest,
                            ),
                            items: List.generate(6, (index) => index + 7).map((
                              int value,
                            ) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSpreadingFactor = newValue;
                                  _syncRadioPresetSelection();
                                });
                                _markRadioSettingsDirty();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            key: ValueKey('coding-rate-$_selectedCodingRate'),
                            initialValue: _selectedCodingRate,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.codingRate,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLowest,
                            ),
                            items: List.generate(4, (index) => index + 5).map((
                              int value,
                            ) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCodingRate = newValue;
                                  _syncRadioPresetSelection();
                                });
                                _markRadioSettingsDirty();
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _txPowerController,
                            onChanged: (_) => _markRadioSettingsDirty(),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.txPowerDbm,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLowest,
                              helperText: AppLocalizations.of(
                                context,
                              )!.maxPowerDbm(deviceInfo.maxTxPower ?? 22),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    if (deviceInfo.clientRepeat != null) ...[
                      const SizedBox(height: 16),
                      _SettingHighlightCard(
                        icon: Icons.repeat_rounded,
                        title: 'Repeat nearby traffic',
                        description:
                            deviceInfo.allowedRepeatFreqRanges != null &&
                                deviceInfo.allowedRepeatFreqRanges!.isNotEmpty
                            ? 'Available on: ${deviceInfo.allowedRepeatFreqRanges!.map((r) => r.lower == r.upper ? '${(r.lower / 1000).toStringAsFixed(3)} MHz' : '${(r.lower / 1000).toStringAsFixed(3)}–${(r.upper / 1000).toStringAsFixed(3)} MHz').join(', ')}'
                            : 'Help extend range by repeating packets for nearby devices.',
                        accentColor: colorScheme.secondary,
                        trailing: Switch(
                          value: _repeatEnabled,
                          onChanged: (value) {
                            setState(() {
                              _repeatEnabled = value;
                              _radioSettingsSaved = false;
                              _radioSettingsError = null;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_radioSettingsError != null) ...[
                      Text(
                        _radioSettingsError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: _SaveActionButton(
                        onPressed: _isSavingRadioSettings
                            ? null
                            : _saveRadioSettings,
                        isSaving: _isSavingRadioSettings,
                        isSaved: _radioSettingsSaved,
                        label: 'Save radio settings',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ConfigSectionCard(
                title: 'Danger zone',
                subtitle: 'Destructive device actions.',
                icon: Icons.warning_amber_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.delete_forever_rounded,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wipe data on device',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Erase contacts, keys, and radio settings from the connected MeshCore device and return it to factory defaults.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _confirmFactoryReset,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: const Text('Wipe device data'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDeviceTypeString(BuildContext context, int? deviceType) {
    if (deviceType == null) return AppLocalizations.of(context)!.unknown;
    switch (deviceType) {
      case 0:
        return AppLocalizations.of(context)!.noneUnknown;
      case 1:
        return AppLocalizations.of(context)!.chatNode;
      case 2:
        return AppLocalizations.of(context)!.repeater;
      case 3:
        return AppLocalizations.of(context)!.roomChannel;
      default:
        return AppLocalizations.of(context)!.typeNumber(deviceType);
    }
  }

  String _formatStorage(int storageKb) {
    if (storageKb >= 1024 * 1024) {
      return '${(storageKb / (1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (storageKb >= 1024) {
      return '${(storageKb / 1024).toStringAsFixed(1)} MB';
    }
    return '$storageKb KB';
  }
}

class _ConfigHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_HeroStatData> stats;

  const _ConfigHeroCard({
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Device settings',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.82,
                        ),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats.map(_HeroStat.new).toList(),
          ),
        ],
      ),
    );
  }
}

class _HeroStatData {
  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  const _HeroStatData({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });
}

class _HeroStat extends StatelessWidget {
  final _HeroStatData data;

  const _HeroStat(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = data.emphasized
        ? colorScheme.primary.withValues(alpha: 0.18)
        : colorScheme.onPrimaryContainer.withValues(alpha: 0.10);

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.76,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ConfigSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;

  const _StorageStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCoordinateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  const _CompactCoordinateField({
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
    );
  }
}

class _StorageUsageMeter extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const _StorageUsageMeter({required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = ((deviceInfo.storageUsedPercent ?? 0) / 100).clamp(
      0.0,
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
            colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Storage usage',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: colorScheme.surface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(deviceInfo.storageUsedPercent ?? 0).toStringAsFixed(0)}% of storage used',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPresetCard extends StatelessWidget {
  final _RadioPreset preset;

  const _SelectedPresetCard({required this.preset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            preset.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSaving;
  final bool isSaved;
  final String label;

  const _SaveActionButton({
    required this.onPressed,
    required this.isSaving,
    required this.isSaved,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isSaving
            ? Row(
                key: const ValueKey('saving'),
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  SizedBox(width: 10),
                  Text('Saving...'),
                ],
              )
            : Row(
                key: ValueKey(isSaved ? 'saved' : 'idle'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSaved ? Icons.check_rounded : Icons.save_outlined),
                  const SizedBox(width: 8),
                  Text(isSaved ? 'Saved' : label),
                ],
              ),
      ),
    );
  }
}

class _SettingHighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final Widget trailing;

  const _SettingHighlightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.14),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _RadioPreset {
  final String id;
  final String label;
  final String summary;
  final int frequencyKhz;
  final int bandwidth;
  final int spreadingFactor;
  final int codingRate;

  const _RadioPreset({
    required this.id,
    required this.label,
    required this.summary,
    required this.frequencyKhz,
    required this.bandwidth,
    required this.spreadingFactor,
    required this.codingRate,
  });
}
