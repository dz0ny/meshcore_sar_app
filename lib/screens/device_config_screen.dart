import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/device_info.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../providers/channels_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../services/validation_service.dart';
import '../l10n/app_localizations.dart';

class DeviceConfigScreen extends StatefulWidget {
  const DeviceConfigScreen({super.key});

  @override
  State<DeviceConfigScreen> createState() => _DeviceConfigScreenState();
}

class _DeviceConfigScreenState extends State<DeviceConfigScreen> {
  static const int _bulkDeleteBatchSize = 8;
  static const Duration _bulkDeleteInterItemDelay = Duration(milliseconds: 120);
  static const Duration _bulkDeleteBatchDelay = Duration(milliseconds: 700);
  static const Duration _bulkDeleteFinalSyncDelay = Duration(milliseconds: 900);
  static const int _autoAddFilterModeFlag = 1;
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
  late TextEditingController _gpsIntervalController;
  late TextEditingController _autoAddMaxHopsController;
  late final ConnectionProvider _connectionProvider;

  int _baseTelemetryMode = 0;
  int _locationTelemetryMode = 0;
  int _environmentTelemetryMode = 0;
  int _advertLocationPolicy = 0;
  bool _multiAcksEnabled = false;
  bool _repeatEnabled = false;
  bool? _gpsEnabled; // null = not supported by hardware
  bool _gpsLoading = false;
  bool _isSyncingDeviceTime = false;
  int? _selectedPathHashMode;
  bool _autoAddDiscoveredContactsEnabled = true;
  bool _autoAddUsersEnabled = true;
  bool _autoAddRepeatersEnabled = true;
  bool _autoAddRoomServersEnabled = true;
  bool _autoAddSensorsEnabled = true;
  bool _overwriteOldestAutoAddEnabled = false;
  bool _showCustomRadioSettings = false;
  bool _isSavingPublicInfo = false;
  bool _isSavingRadioSettings = false;
  bool _isSavingAutoDiscoverySettings = false;
  bool _isClearingContacts = false;
  bool _isClearingChannels = false;
  bool _publicInfoSaved = false;
  bool _radioSettingsSaved = false;
  bool _autoDiscoverySettingsSaved = false;
  bool _autoDiscoverySettingsDirty = false;
  String? _lastAutoDiscoverySignature;
  String? _publicInfoError;
  String? _radioSettingsError;
  String? _autoDiscoverySettingsError;
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
    _connectionProvider = context.read<ConnectionProvider>();
    _connectionProvider.addListener(_handleConnectionProviderChanged);
    final deviceInfo = _connectionProvider.deviceInfo;

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
    _gpsIntervalController = TextEditingController();
    _autoAddMaxHopsController = TextEditingController(
      text: (deviceInfo.autoAddMaxHops ?? 0).toString(),
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

    final telemetryModes = deviceInfo.telemetryModes;
    _baseTelemetryMode = telemetryModes != null ? telemetryModes & 0x03 : 0;
    _locationTelemetryMode = telemetryModes != null
        ? (telemetryModes >> 2) & 0x03
        : 0;
    _environmentTelemetryMode = telemetryModes != null
        ? (telemetryModes >> 4) & 0x03
        : 0;
    _advertLocationPolicy = deviceInfo.advertLocPolicy ?? 0;
    _multiAcksEnabled = (deviceInfo.multiAcks ?? 0) != 0;
    _selectedPathHashMode = deviceInfo.pathHashMode;

    // Initialize repeat mode from device info (firmware v9+)
    _repeatEnabled = deviceInfo.clientRepeat ?? false;
    _syncAutoDiscoveryState(deviceInfo);
    _lastAutoDiscoverySignature = _autoDiscoverySignature(deviceInfo);

    // Fetch allowed repeat frequencies on open if device supports repeat mode
    if (deviceInfo.clientRepeat != null &&
        deviceInfo.allowedRepeatFreqRanges == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ConnectionProvider>().getAllowedRepeatFreq();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectionProvider.getBatteryAndStorage();
      unawaited(_connectionProvider.getAutoaddConfig());
      unawaited(_loadGpsMode());
    });
  }

  @override
  void dispose() {
    _connectionProvider.removeListener(_handleConnectionProviderChanged);
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _freqController.dispose();
    _txPowerController.dispose();
    _gpsIntervalController.dispose();
    _autoAddMaxHopsController.dispose();
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

  void _markAutoDiscoverySettingsDirty() {
    _autoDiscoverySettingsDirty = true;
    if (_autoDiscoverySettingsSaved || _autoDiscoverySettingsError != null) {
      setState(() {
        _autoDiscoverySettingsSaved = false;
        _autoDiscoverySettingsError = null;
      });
    }
  }

  String _autoDiscoverySignature(DeviceInfo deviceInfo) {
    return [
      deviceInfo.manualAddContacts,
      deviceInfo.autoAddUsers,
      deviceInfo.autoAddRepeaters,
      deviceInfo.autoAddRoomServers,
      deviceInfo.autoAddSensors,
      deviceInfo.autoAddOverwriteOldest,
      deviceInfo.autoAddMaxHops,
    ].join('|');
  }

  void _handleConnectionProviderChanged() {
    if (!mounted || _autoDiscoverySettingsDirty) return;

    final deviceInfo = _connectionProvider.deviceInfo;
    final nextSignature = _autoDiscoverySignature(deviceInfo);
    if (nextSignature == _lastAutoDiscoverySignature) return;

    _lastAutoDiscoverySignature = nextSignature;
    setState(() {
      _syncAutoDiscoveryState(deviceInfo);
    });
  }

  bool _hasAutoAddTargetsEnabled(DeviceInfo deviceInfo) {
    return (deviceInfo.autoAddUsers ?? false) ||
        (deviceInfo.autoAddRepeaters ?? false) ||
        (deviceInfo.autoAddRoomServers ?? false) ||
        (deviceInfo.autoAddSensors ?? false);
  }

  void _syncAutoDiscoveryState(DeviceInfo deviceInfo) {
    final hasFetchedAutoAddConfig =
        deviceInfo.autoAddUsers != null ||
        deviceInfo.autoAddRepeaters != null ||
        deviceInfo.autoAddRoomServers != null ||
        deviceInfo.autoAddSensors != null ||
        deviceInfo.autoAddOverwriteOldest != null;

    _autoAddDiscoveredContactsEnabled = hasFetchedAutoAddConfig
        ? _hasAutoAddTargetsEnabled(deviceInfo)
        : !(deviceInfo.manualAddContacts ?? false);
    _autoAddUsersEnabled = deviceInfo.autoAddUsers ?? true;
    _autoAddRepeatersEnabled = deviceInfo.autoAddRepeaters ?? true;
    _autoAddRoomServersEnabled = deviceInfo.autoAddRoomServers ?? true;
    _autoAddSensorsEnabled = deviceInfo.autoAddSensors ?? true;
    _overwriteOldestAutoAddEnabled = deviceInfo.autoAddOverwriteOldest ?? false;
    _autoAddMaxHopsController.text = (deviceInfo.autoAddMaxHops ?? 0)
        .toString();
  }

  int _telemetryModesForSave() {
    return (_environmentTelemetryMode << 4) |
        (_locationTelemetryMode << 2) |
        _baseTelemetryMode;
  }

  int _advertLocationPolicyForSave() {
    return _advertLocationPolicy;
  }

  int _multiAcksForSave() {
    return _multiAcksEnabled ? 1 : 0;
  }

  Future<void> _savePublicInfo() async {
    final connectionProvider = context.read<ConnectionProvider>();
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

      final gpsIntervalText = _gpsIntervalController.text.trim();
      if (gpsIntervalText.isNotEmpty) {
        final gpsInterval = int.tryParse(gpsIntervalText);
        if (gpsInterval == null || gpsInterval < 0 || gpsInterval > 86400) {
          if (mounted) {
            setState(() {
              _publicInfoError =
                  'GPS interval must be a whole number between 0 and 86400 seconds.';
              _isSavingPublicInfo = false;
            });
          }
          return;
        }
        await connectionProvider.setCustomVar('gps_interval', gpsIntervalText);
      }

      // Save stored coordinates only when the firmware advert policy uses prefs.
      if (_advertLocationPolicy == 2) {
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
      }

      await connectionProvider.setOtherParams(
        manualAddContacts: _autoAddFilterModeFlag,
        telemetryModes: _telemetryModesForSave(),
        advertLocationPolicy: _advertLocationPolicyForSave(),
        multiAcks: _multiAcksForSave(),
      );

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

      if (_selectedPathHashMode != null) {
        await connectionProvider.setPathHashMode(_selectedPathHashMode!);
      }

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

  Future<void> _saveAutoDiscoverySettings() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final autoAddUsers =
        _autoAddDiscoveredContactsEnabled && _autoAddUsersEnabled;
    final autoAddRepeaters =
        _autoAddDiscoveredContactsEnabled && _autoAddRepeatersEnabled;
    final autoAddRoomServers =
        _autoAddDiscoveredContactsEnabled && _autoAddRoomServersEnabled;
    final autoAddSensors =
        _autoAddDiscoveredContactsEnabled && _autoAddSensorsEnabled;
    final overwriteOldest =
        _autoAddDiscoveredContactsEnabled && _overwriteOldestAutoAddEnabled;
    final maxHopsText = _autoAddMaxHopsController.text.trim();
    final maxHops = int.tryParse(maxHopsText);

    setState(() {
      _isSavingAutoDiscoverySettings = true;
      _autoDiscoverySettingsSaved = false;
      _autoDiscoverySettingsError = null;
    });

    try {
      if (maxHops == null || maxHops < 0 || maxHops > 64) {
        throw Exception('Auto-add max hops must be between 0 and 64.');
      }
      await connectionProvider.setAutoaddConfig(
        autoAddUsers: autoAddUsers,
        autoAddRepeaters: autoAddRepeaters,
        autoAddRoomServers: autoAddRoomServers,
        autoAddSensors: autoAddSensors,
        overwriteOldest: overwriteOldest,
        maxHops: maxHops,
      );
      await connectionProvider.setOtherParams(
        manualAddContacts: _autoAddFilterModeFlag,
        telemetryModes: _telemetryModesForSave(),
        advertLocationPolicy: _advertLocationPolicyForSave(),
        multiAcks: _multiAcksForSave(),
      );
      await connectionProvider.getAutoaddConfig();

      if (mounted) {
        setState(() {
          _syncAutoDiscoveryState(connectionProvider.deviceInfo);
          _lastAutoDiscoverySignature = _autoDiscoverySignature(
            connectionProvider.deviceInfo,
          );
          _isSavingAutoDiscoverySettings = false;
          _autoDiscoverySettingsSaved = true;
          _autoDiscoverySettingsDirty = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingAutoDiscoverySettings = false;
          _autoDiscoverySettingsError = AppLocalizations.of(
            context,
          )!.failedToSave(e.toString());
        });
      }
    }
  }

  Future<void> _loadGpsMode() async {
    try {
      final vars = await _connectionProvider.getCustomVars();
      if (!mounted) return;
      final gpsValue = vars['gps'];
      final gpsIntervalValue = vars['gps_interval'];
      setState(() {
        _gpsEnabled = gpsValue != null ? gpsValue == '1' : null;
        if (gpsIntervalValue != null) {
          _gpsIntervalController.text = gpsIntervalValue;
        }
      });
    } catch (_) {
      // Device may not support custom vars (old firmware / no GPS hardware)
    }
  }

  Future<void> _setGpsMode(bool enabled) async {
    setState(() => _gpsLoading = true);
    try {
      await _connectionProvider.setCustomVar('gps', enabled ? '1' : '0');
      if (!mounted) return;
      setState(() {
        _gpsEnabled = enabled;
        _gpsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _gpsLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to set GPS mode: $e')));
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
        _advertLocationPolicy = 2;
        if (_locationTelemetryMode == 0) {
          _locationTelemetryMode = 2;
        }
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

  Future<void> _syncDeviceTime() async {
    setState(() => _isSyncingDeviceTime = true);
    try {
      _connectionProvider.clearError();
      await _connectionProvider.syncDeviceTime();
      final syncError = _connectionProvider.error;
      if (syncError != null) {
        throw Exception(syncError);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device time synced to this phone.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync device time: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncingDeviceTime = false);
      }
    }
  }

  Future<void> _confirmFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.wipeDeviceData),
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
            child: Text(AppLocalizations.of(context)!.wipeDevice),
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

  Future<void> _confirmClearAllContacts() async {
    final contacts = context
        .read<ContactsProvider>()
        .contacts
        .where((contact) => !contact.isChannel)
        .toList();
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noDeviceContactsToClear),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearAllContacts),
        content: Text(
          'This will remove ${contacts.length} contact${contacts.length == 1 ? '' : 's'} from the connected device. Channels and radio settings will not be changed.',
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
            child: Text(AppLocalizations.of(context)!.clearContacts),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    connectionProvider.clearError();

    setState(() {
      _isClearingContacts = true;
    });

    try {
      var processed = 0;
      for (final contact in List<Contact>.from(contacts)) {
        await contactsProvider.removeContact(
          contact.publicKeyHex,
          onRemoveFromDevice: connectionProvider.removeContact,
        );
        processed++;
        await Future.delayed(_bulkDeleteInterItemDelay);
        if (processed % _bulkDeleteBatchSize == 0) {
          await Future.delayed(_bulkDeleteBatchDelay);
        }
      }

      // Flush the updated local contact set to storage immediately.
      await contactsProvider.persistNow();
      await Future.delayed(_bulkDeleteFinalSyncDelay);
      await connectionProvider.getContacts();
      if (connectionProvider.error != null) {
        throw Exception(connectionProvider.error!);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cleared ${contacts.length} contact${contacts.length == 1 ? '' : 's'} from the device.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to clear contacts: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClearingContacts = false;
        });
      }
    }
  }

  Future<void> _confirmClearAllChannels() async {
    final channels = context
        .read<ChannelsProvider>()
        .channels
        .where((channel) => !channel.isPublicChannel && channel.name.isNotEmpty)
        .toList();
    if (channels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noCustomChannelsToClear),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.clearAllChannels),
        content: Text(
          'This will remove ${channels.length} custom channel${channels.length == 1 ? '' : 's'} from the connected device. Contacts and radio settings will not be changed.',
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
            child: Text(AppLocalizations.of(context)!.clearChannels),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final connectionProvider = context.read<ConnectionProvider>();
    final channelsProvider = context.read<ChannelsProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    connectionProvider.clearError();

    setState(() {
      _isClearingChannels = true;
    });

    try {
      var processed = 0;
      for (final channel in List<Channel>.from(channels)) {
        await connectionProvider.deleteChannel(channel.index);
        processed++;
        await Future.delayed(_bulkDeleteInterItemDelay);
        if (processed % _bulkDeleteBatchSize == 0) {
          await Future.delayed(_bulkDeleteBatchDelay);
        }
      }

      // Force local channel/contact cache cleanup before the device resync.
      for (final channel in channels) {
        channelsProvider.removeChannel(channel.index);
        final publicKeyBytes = Uint8List(32);
        publicKeyBytes[0] = 0xFF;
        publicKeyBytes[1] = channel.index;
        final publicKeyHex = publicKeyBytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join('');
        await contactsProvider.removeContact(publicKeyHex);
      }

      await contactsProvider.persistNow();
      await Future.delayed(_bulkDeleteFinalSyncDelay);
      await connectionProvider.syncChannels();
      if (connectionProvider.error != null) {
        throw Exception(connectionProvider.error!);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Cleared ${channels.length} custom channel${channels.length == 1 ? '' : 's'} from the device.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to clear channels: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClearingChannels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationSet = _advertLocationPolicy != 0;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ColoredBox(
        color: colorScheme.surface,
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
                    label: AppLocalizations.of(context)!.location,
                    value: locationSet ? 'Shared' : 'Hidden',
                    icon: Icons.my_location_rounded,
                    emphasized: locationSet,
                  ),
                  _HeroStatData(
                    label: AppLocalizations.of(context)!.frequency,
                    value: '${_freqController.text} MHz',
                    icon: Icons.settings_input_antenna_rounded,
                  ),
                  _HeroStatData(
                    label: AppLocalizations.of(context)!.bandwidth,
                    value: _selectedBandwidth,
                    icon: Icons.width_normal_rounded,
                  ),
                  _HeroStatData(
                    label: AppLocalizations.of(context)!.model,
                    value:
                        deviceInfo.manufacturerModel ??
                        AppLocalizations.of(context)!.unknown,
                    icon: Icons.memory_rounded,
                  ),
                ],
              ),
              SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.storage,
                subtitle: AppLocalizations.of(
                  context,
                )!.availableSpaceOnThisDevice,
                icon: Icons.storage_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StorageStat(
                            label: AppLocalizations.of(context)!.used,
                            value: _formatStorage(
                              deviceInfo.storageUsedKb ?? 0,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _StorageStat(
                            label: AppLocalizations.of(context)!.total,
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
              SizedBox(height: 20),
              _ConfigSectionCard(
                title: 'Device info',
                subtitle:
                    'Capabilities reported by the connected radio and maintenance tools.',
                icon: Icons.info_outline_rounded,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 420
                        ? (constraints.maxWidth - 24) / 3
                        : (constraints.maxWidth - 12) / 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _StorageStat(
                                label: 'BLE PIN',
                                value: _formatBlePin(deviceInfo.blePin),
                                compact: true,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _StorageStat(
                                label: AppLocalizations.of(
                                  context,
                                )!.maxContacts,
                                value:
                                    deviceInfo.maxContacts?.toString() ??
                                    AppLocalizations.of(context)!.unknown,
                                compact: true,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _StorageStat(
                                label: AppLocalizations.of(
                                  context,
                                )!.maxChannels,
                                value:
                                    deviceInfo.maxChannels?.toString() ??
                                    AppLocalizations.of(context)!.unknown,
                                compact: true,
                              ),
                            ),
                            if (deviceInfo.pathHashMode != null)
                              SizedBox(
                                width: cardWidth,
                                child: _StorageStat(
                                  label: 'Path hash',
                                  value: _pathHashModeLabel(
                                    deviceInfo.pathHashMode!,
                                  ),
                                  compact: true,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clock maintenance',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Refresh the radio clock if room logins or message timestamps look off.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isSyncingDeviceTime
                                      ? null
                                      : _syncDeviceTime,
                                  icon: _isSyncingDeviceTime
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.schedule_rounded),
                                  label: Text(
                                    _isSyncingDeviceTime
                                        ? 'Syncing time...'
                                        : 'Sync device time',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.autoDiscovery,
                subtitle:
                    'Control how the radio auto-adds discovered nodes to its contacts table.',
                icon: Icons.person_search_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingHighlightCard(
                      icon: _autoAddDiscoveredContactsEnabled
                          ? Icons.person_add_alt_1
                          : Icons.person_add_disabled,
                      title: AppLocalizations.of(
                        context,
                      )!.enableAutomaticAdding,
                      description:
                          'Turn this off to keep discoveries manual-only on the radio.',
                      accentColor: _autoAddDiscoveredContactsEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _autoAddDiscoveredContactsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _autoAddDiscoveredContactsEnabled = value;
                            _markAutoDiscoverySettingsDirty();
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 18),
                    _SettingHighlightCard(
                      icon: Icons.person_outline_rounded,
                      title: AppLocalizations.of(context)!.autoaddUsers,
                      description:
                          'Automatically store discovered user/chat nodes.',
                      accentColor: _autoAddUsersEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _autoAddUsersEnabled,
                        onChanged: _autoAddDiscoveredContactsEnabled
                            ? (value) {
                                setState(() {
                                  _autoAddUsersEnabled = value;
                                  _markAutoDiscoverySettingsDirty();
                                });
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 14),
                    _SettingHighlightCard(
                      icon: Icons.router_outlined,
                      title: AppLocalizations.of(context)!.autoaddRepeaters,
                      description:
                          'Automatically store discovered repeater nodes.',
                      accentColor: _autoAddRepeatersEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _autoAddRepeatersEnabled,
                        onChanged: _autoAddDiscoveredContactsEnabled
                            ? (value) {
                                setState(() {
                                  _autoAddRepeatersEnabled = value;
                                  _markAutoDiscoverySettingsDirty();
                                });
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 14),
                    _SettingHighlightCard(
                      icon: Icons.meeting_room_outlined,
                      title: AppLocalizations.of(context)!.autoaddRoomServers,
                      description:
                          'Automatically store discovered room/server nodes.',
                      accentColor: _autoAddRoomServersEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _autoAddRoomServersEnabled,
                        onChanged: _autoAddDiscoveredContactsEnabled
                            ? (value) {
                                setState(() {
                                  _autoAddRoomServersEnabled = value;
                                  _markAutoDiscoverySettingsDirty();
                                });
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 14),
                    _SettingHighlightCard(
                      icon: Icons.sensors_outlined,
                      title: AppLocalizations.of(context)!.autoaddSensors,
                      description:
                          'Automatically store discovered sensor nodes.',
                      accentColor: _autoAddSensorsEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _autoAddSensorsEnabled,
                        onChanged: _autoAddDiscoveredContactsEnabled
                            ? (value) {
                                setState(() {
                                  _autoAddSensorsEnabled = value;
                                  _markAutoDiscoverySettingsDirty();
                                });
                              }
                            : null,
                      ),
                    ),
                    SizedBox(height: 14),
                    _SettingHighlightCard(
                      icon: Icons.history_toggle_off_rounded,
                      title: AppLocalizations.of(
                        context,
                      )!.overwriteOldestWhenFull,
                      description:
                          'Allow the radio to replace the oldest contact when storage is full.',
                      accentColor: _overwriteOldestAutoAddEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _overwriteOldestAutoAddEnabled,
                        onChanged: _autoAddDiscoveredContactsEnabled
                            ? (value) {
                                setState(() {
                                  _overwriteOldestAutoAddEnabled = value;
                                  _markAutoDiscoverySettingsDirty();
                                });
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _autoAddMaxHopsController,
                      onChanged: (_) => _markAutoDiscoverySettingsDirty(),
                      decoration: InputDecoration(
                        labelText: 'Auto-add max hops',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        helperText:
                            '0 means no limit. 1 keeps auto-add to direct neighbors only.',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 18),
                    if (_autoDiscoverySettingsError != null) ...[
                      Text(
                        _autoDiscoverySettingsError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: _SaveActionButton(
                        onPressed: _isSavingAutoDiscoverySettings
                            ? null
                            : _saveAutoDiscoverySettings,
                        isSaving: _isSavingAutoDiscoverySettings,
                        isSaved: _autoDiscoverySettingsSaved,
                        label: AppLocalizations.of(
                          context,
                        )!.saveDiscoverySettings,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.publicInfo,
                subtitle: AppLocalizations.of(
                  context,
                )!.chooseTheNameAndLocationThisDeviceShares,
                icon: Icons.public_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConfigDropdownField(
                      label: 'Base telemetry',
                      value: _baseTelemetryMode,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Deny')),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Use contact flags'),
                        ),
                        DropdownMenuItem(value: 2, child: Text('Allow all')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _baseTelemetryMode = value;
                          _markPublicInfoDirty();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _ConfigDropdownField(
                      label: 'Location telemetry',
                      value: _locationTelemetryMode,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Deny')),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Use contact flags'),
                        ),
                        DropdownMenuItem(value: 2, child: Text('Allow all')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _locationTelemetryMode = value;
                          _markPublicInfoDirty();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _ConfigDropdownField(
                      label: 'Environmental telemetry',
                      value: _environmentTelemetryMode,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Deny')),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Use contact flags'),
                        ),
                        DropdownMenuItem(value: 2, child: Text('Allow all')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _environmentTelemetryMode = value;
                          _markPublicInfoDirty();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _ConfigDropdownField(
                      label: 'GPS advert policy',
                      value: _advertLocationPolicy,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Hidden')),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Share live GPS'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Use saved coordinates'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _advertLocationPolicy = value;
                          _markPublicInfoDirty();
                        });
                      },
                    ),
                    if (_gpsEnabled != null) ...[
                      const SizedBox(height: 12),
                      _SettingHighlightCard(
                        icon: _gpsEnabled! ? Icons.gps_fixed : Icons.gps_off,
                        title: AppLocalizations.of(context)!.gpsModule,
                        description:
                            'Enable or disable the onboard GPS hardware.',
                        accentColor: _gpsEnabled!
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        trailing: _gpsLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: _gpsEnabled!,
                                onChanged: _setGpsMode,
                              ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _gpsIntervalController,
                      onChanged: (_) => _markPublicInfoDirty(),
                      decoration: InputDecoration(
                        labelText: 'GPS interval (seconds)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        helperText:
                            'Firmware supports 0-86400 seconds. Older builds may not report the current value back.',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _SettingHighlightCard(
                      icon: _multiAcksEnabled
                          ? Icons.mark_email_read_outlined
                          : Icons.mark_email_unread_outlined,
                      title: 'Multi-ACK mode',
                      description:
                          'Ask the radio to request extra acknowledgements when the firmware supports it.',
                      accentColor: _multiAcksEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      trailing: Switch(
                        value: _multiAcksEnabled,
                        onChanged: (value) {
                          setState(() {
                            _multiAcksEnabled = value;
                            _markPublicInfoDirty();
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
                    if (_advertLocationPolicy == 2) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved coordinates',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'These coordinates are used when advert policy is set to saved coordinates.',
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
                    ] else if (_advertLocationPolicy == 1) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          'The firmware will advertise the live GPS fix from the onboard sensor manager when available.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
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
                        label: AppLocalizations.of(context)!.savePublicInfo,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.radioSettings,
                subtitle: AppLocalizations.of(
                  context,
                )!.chooseAPresetOrFinetuneCustomRadioSettings,
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
                        DropdownMenuItem<_RadioPreset?>(
                          value: null,
                          child: Text(AppLocalizations.of(context)!.custom),
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
                          if (_selectedPathHashMode != null) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              key: ValueKey('path-hash-$_selectedPathHashMode'),
                              initialValue: _selectedPathHashMode,
                              decoration: InputDecoration(
                                labelText: 'Advert path hash size',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerLowest,
                                helperText:
                                    'Controls the low-level hash size used in adverts and flood paths.',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text('1 byte (mode 0)'),
                                ),
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('2 bytes (mode 1)'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('3 bytes (mode 2)'),
                                ),
                              ],
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedPathHashMode = newValue;
                                  });
                                  _markRadioSettingsDirty();
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (deviceInfo.clientRepeat != null) ...[
                      SizedBox(height: 16),
                      _SettingHighlightCard(
                        icon: Icons.repeat_rounded,
                        title: AppLocalizations.of(
                          context,
                        )!.repeatNearbyTraffic,
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
                        label: AppLocalizations.of(context)!.saveRadioSettings,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _ConfigSectionCard(
                title: AppLocalizations.of(context)!.dangerZone,
                subtitle: AppLocalizations.of(
                  context,
                )!.destructiveDeviceActions,
                icon: Icons.warning_amber_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: colorScheme.error),
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
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Erase contacts, keys, and radio settings from the connected MeshCore device and return it to factory defaults.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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
                      child: OutlinedButton.icon(
                        onPressed: _isClearingContacts || _isClearingChannels
                            ? null
                            : _confirmClearAllContacts,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: _isClearingContacts
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.people_alt_outlined),
                        label: Text(
                          AppLocalizations.of(context)!.clearAllContacts,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isClearingContacts || _isClearingChannels
                            ? null
                            : _confirmClearAllChannels,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: _isClearingChannels
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.forum_outlined),
                        label: Text(
                          AppLocalizations.of(context)!.clearAllChannels,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isClearingContacts || _isClearingChannels
                            ? null
                            : _confirmFactoryReset,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: Icon(Icons.delete_forever_rounded),
                        label: Text(
                          AppLocalizations.of(context)!.wipeDeviceData,
                        ),
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

  String _formatBlePin(int? blePin) {
    if (blePin == null) {
      return AppLocalizations.of(context)!.unknown;
    }
    return blePin.toString().padLeft(6, '0');
  }

  String _pathHashModeLabel(int mode) {
    switch (mode) {
      case 0:
        return '1 byte';
      case 1:
        return '2 bytes';
      case 2:
        return '3 bytes';
      default:
        return 'Mode $mode';
    }
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.tune_rounded, color: colorScheme.primary),
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
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Device settings',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
    final iconColor = data.emphasized
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final borderColor = data.emphasized
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
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
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
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
                    color: colorScheme.surfaceContainerHighest,
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

class _ConfigDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _ConfigDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _StorageStat({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
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
              fontSize: compact ? 13 : null,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              fontSize: compact ? 17 : null,
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
        color: colorScheme.surfaceContainerLow,
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
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
