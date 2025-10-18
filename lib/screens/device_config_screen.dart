import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/connection_provider.dart';
import '../services/validation_service.dart';
import '../l10n/app_localizations.dart';

class DeviceConfigScreen extends StatefulWidget {
  const DeviceConfigScreen({super.key});

  @override
  State<DeviceConfigScreen> createState() => _DeviceConfigScreenState();
}

class _DeviceConfigScreenState extends State<DeviceConfigScreen> {
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _freqController;
  late TextEditingController _txPowerController;

  bool _telemetryEnabled = false;
  bool _isBroadcasting = false;
  String _selectedBandwidth = '62.5 kHz';
  int _selectedSpreadingFactor = 8;
  int _selectedCodingRate = 8;

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

    // Check if telemetry is enabled (check if lat/lon are set and not zero)
    _telemetryEnabled =
        (deviceInfo.advLat != null && deviceInfo.advLat! != 0) ||
        (deviceInfo.advLon != null && deviceInfo.advLon! != 0);
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

  Future<void> _savePublicInfo() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final deviceInfo = connectionProvider.deviceInfo;
    final validator = ValidationService();

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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(latResult.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final lonResult = validator.parseLongitude(_lonController.text);
        if (!lonResult.isSuccess) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lonResult.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.save),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRadioSettings() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final validator = ValidationService();
    final deviceInfo = connectionProvider.deviceInfo;

    try {
      // Parse and validate frequency
      final freqResult = validator.parseFrequency(_freqController.text);
      if (!freqResult.isSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(freqResult.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Parse and validate TX power
      final txPowerResult = validator.parseTxPower(
        _txPowerController.text,
        maxPower: deviceInfo.maxTxPower,
      );
      if (!txPowerResult.isSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(txPowerResult.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
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
      );

      // Save TX power
      await connectionProvider.setTxPower(txPowerResult.value!);

      // Refetch device info to update UI with new settings
      await connectionProvider.refreshDeviceInfo();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.save),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
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
          if (context.mounted) {
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
        if (context.mounted) {
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

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _telemetryEnabled = true;
      });

      if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  Future<void> _broadcastNow() async {
    final connectionProvider = context.read<ConnectionProvider>();

    if (!connectionProvider.deviceInfo.isConnected) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deviceNotConnected),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isBroadcasting = true);

    try {
      // Send self advertisement to mesh network
      await connectionProvider.sendSelfAdvert(floodMode: true);

      if (context.mounted) {
        final deviceInfo = connectionProvider.deviceInfo;
        final lat = deviceInfo.advLat != null
            ? (deviceInfo.advLat! / 1000000).toStringAsFixed(6)
            : '0.0';
        final lon = deviceInfo.advLon != null
            ? (deviceInfo.advLon! / 1000000).toStringAsFixed(6)
            : '0.0';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.advertisedAtLocation(lat, lon),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToAdvertise(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBroadcasting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow('BLE Name', deviceInfo.deviceName ?? 'Unknown'),
                  _InfoRow('Mesh Name', deviceInfo.selfName ?? 'Not set'),
                  _InfoRow('Type', _getDeviceTypeString(deviceInfo.deviceType)),
                  _InfoRow('Model', deviceInfo.manufacturerModel ?? 'Unknown'),
                  _InfoRow('Version', deviceInfo.semanticVersion ?? 'Unknown'),
                  _InfoRow(
                    'Build Date',
                    deviceInfo.firmwareBuildDate ?? 'Unknown',
                  ),
                  _InfoRow(
                    'Firmware',
                    'v${deviceInfo.firmwareVersion?.toString() ?? "?"}',
                  ),
                  _InfoRow(
                    'Max Contacts',
                    deviceInfo.maxContacts?.toString() ?? 'Unknown',
                  ),
                  _InfoRow(
                    'Max Channels',
                    deviceInfo.maxChannels?.toString() ?? 'Unknown',
                  ),
                  _CopyableInfoRow(
                    'Public Key',
                    _getPublicKeyHex(deviceInfo.publicKey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Public Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Public Info',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _savePublicInfo,
                            icon: const Icon(Icons.save),
                            tooltip: AppLocalizations.of(context)!.save,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mesh Network Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Mesh Network Name',
                      border: OutlineInputBorder(),
                      helperText: 'Name broadcast in mesh advertisements',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Telemetry Toggle - Compact version
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Telemetry & Location Sharing',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _telemetryEnabled,
                        onChanged: (value) {
                          setState(() {
                            _telemetryEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),

                  // GPS Coordinates (only show if telemetry enabled)
                  if (_telemetryEnabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Lat',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lonController,
                            decoration: const InputDecoration(
                              labelText: 'Lon',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Radio Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.radioSettings,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _saveRadioSettings,
                        icon: const Icon(Icons.save),
                        tooltip: AppLocalizations.of(context)!.save,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // LoRa Frequency
                  TextField(
                    controller: _freqController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.frequencyMHz,
                      border: const OutlineInputBorder(),
                      helperText: AppLocalizations.of(context)!.frequencyExample,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bandwidth
                  DropdownButtonFormField<String>(
                    value: _selectedBandwidth,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.bandwidth,
                      border: const OutlineInputBorder(),
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
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Spreading Factor
                  DropdownButtonFormField<int>(
                    value: _selectedSpreadingFactor,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.spreadingFactor,
                      border: const OutlineInputBorder(),
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
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Coding Rate
                  DropdownButtonFormField<int>(
                    value: _selectedCodingRate,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.codingRate,
                      border: const OutlineInputBorder(),
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
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // TX Power
                  TextField(
                    controller: _txPowerController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.txPowerDbm,
                      border: const OutlineInputBorder(),
                      helperText: AppLocalizations.of(context)!.maxPowerDbm(deviceInfo.maxTxPower ?? 22),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getDeviceTypeString(int? deviceType) {
    if (deviceType == null) return 'Unknown';
    switch (deviceType) {
      case 0:
        return 'None/Unknown';
      case 1:
        return 'Chat Node';
      case 2:
        return 'Repeater';
      case 3:
        return 'Room/Channel';
      default:
        return 'Type $deviceType';
    }
  }

  String _getPublicKeyHex(List<int>? publicKey) {
    if (publicKey == null || publicKey.isEmpty) return 'N/A';
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label to clipboard'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
