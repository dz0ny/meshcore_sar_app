import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../providers/sensors_provider.dart';
import '../../services/bthome_met_history.dart';
import '../../utils/location_formats.dart';

class SensorMetricOption {
  final String key;
  final String label;
  final String defaultLabel;
  final int? channel;
  final String? valuePreview;
  final SensorMetricCardData? previewCardData;

  const SensorMetricOption({
    required this.key,
    required this.label,
    required this.defaultLabel,
    this.channel,
    this.valuePreview,
    this.previewCardData,
  });
}

List<SensorMetricOption> sensorMetricOptionsFor(
  Contact? contact, {
  Map<String, String> labelOverrides = const <String, String>{},
}) {
  final telemetry = contact?.telemetry;
  final extraSensorData = telemetry?.extraSensorData;
  final batteryMilliVolts = telemetry?.batteryMilliVolts;
  final batteryPercentage = telemetry?.batteryPercentage;
  final temperature = telemetry?.temperature;
  final humidity = telemetry?.humidity;
  final pressure = telemetry?.pressure;
  final gpsLocation = telemetry?.gpsLocation;
  final options = <SensorMetricOption>[
    if (batteryMilliVolts != null)
      SensorMetricOption(
        key: 'voltage',
        label: _selectorMetricLabel(
          _resolvedMetricLabel(
            'voltage',
            'Voltage',
            labelOverrides: labelOverrides,
          ),
          _sourceChannelForField(extraSensorData, 'voltage'),
        ),
        defaultLabel: 'Voltage',
        channel: _sourceChannelForField(extraSensorData, 'voltage'),
        valuePreview: '${(batteryMilliVolts / 1000).toStringAsFixed(3)}V',
        previewCardData: SensorMetricCardData(
          fieldKey: 'voltage',
          icon: Icons.bolt,
          label: _resolvedMetricLabel(
            'voltage',
            'Voltage',
            labelOverrides: labelOverrides,
          ),
          value: '${(batteryMilliVolts / 1000).toStringAsFixed(3)}V',
          accent: const Color(0xFF0A7D61),
          channel: _sourceChannelForField(extraSensorData, 'voltage'),
        ),
      ),
    if (batteryPercentage != null)
      SensorMetricOption(
        key: 'battery',
        label: _selectorMetricLabel(
          _resolvedMetricLabel(
            'battery',
            'Battery',
            labelOverrides: labelOverrides,
          ),
          _sourceChannelForField(extraSensorData, 'battery'),
        ),
        defaultLabel: 'Battery',
        channel: _sourceChannelForField(extraSensorData, 'battery'),
        valuePreview: '${batteryPercentage.toStringAsFixed(0)}%',
        previewCardData: SensorMetricCardData(
          fieldKey: 'battery',
          icon: Icons.battery_5_bar,
          label: _resolvedMetricLabel(
            'battery',
            'Battery',
            labelOverrides: labelOverrides,
          ),
          value: '${batteryPercentage.toStringAsFixed(0)}%',
          accent: const Color(0xFF4B8E2F),
          channel: _sourceChannelForField(extraSensorData, 'battery'),
        ),
      ),
    if (temperature != null)
      SensorMetricOption(
        key: 'temperature',
        label: _selectorMetricLabel(
          _resolvedMetricLabel(
            'temperature',
            'Temperature',
            labelOverrides: labelOverrides,
          ),
          _sourceChannelForField(extraSensorData, 'temperature'),
        ),
        defaultLabel: 'Temperature',
        channel: _sourceChannelForField(extraSensorData, 'temperature'),
        valuePreview: '${temperature.toStringAsFixed(1)}°C',
        previewCardData: SensorMetricCardData(
          fieldKey: 'temperature',
          icon: Icons.thermostat,
          label: _resolvedMetricLabel(
            'temperature',
            'Temperature',
            labelOverrides: labelOverrides,
          ),
          value: '${temperature.toStringAsFixed(1)}°C',
          accent: const Color(0xFFC76821),
          channel: _sourceChannelForField(extraSensorData, 'temperature'),
        ),
      ),
    if (humidity != null)
      SensorMetricOption(
        key: 'humidity',
        label: _selectorMetricLabel(
          _resolvedMetricLabel(
            'humidity',
            'Humidity',
            labelOverrides: labelOverrides,
          ),
          _sourceChannelForField(extraSensorData, 'humidity'),
        ),
        defaultLabel: 'Humidity',
        channel: _sourceChannelForField(extraSensorData, 'humidity'),
        valuePreview: '${humidity.toStringAsFixed(1)}%',
        previewCardData: SensorMetricCardData(
          fieldKey: 'humidity',
          icon: Icons.water_drop,
          label: _resolvedMetricLabel(
            'humidity',
            'Humidity',
            labelOverrides: labelOverrides,
          ),
          value: '${humidity.toStringAsFixed(1)}%',
          accent: const Color(0xFF246BB2),
          channel: _sourceChannelForField(extraSensorData, 'humidity'),
        ),
      ),
    if (pressure != null)
      SensorMetricOption(
        key: 'pressure',
        label: _selectorMetricLabel(
          _resolvedMetricLabel(
            'pressure',
            'Pressure',
            labelOverrides: labelOverrides,
          ),
          _sourceChannelForField(extraSensorData, 'pressure'),
        ),
        defaultLabel: 'Pressure',
        channel: _sourceChannelForField(extraSensorData, 'pressure'),
        valuePreview: '${pressure.toStringAsFixed(1)} hPa',
        previewCardData: SensorMetricCardData(
          fieldKey: 'pressure',
          icon: Icons.compress,
          label: _resolvedMetricLabel(
            'pressure',
            'Pressure',
            labelOverrides: labelOverrides,
          ),
          value: '${pressure.toStringAsFixed(1)} hPa',
          accent: const Color(0xFF6B4BAE),
          channel: _sourceChannelForField(extraSensorData, 'pressure'),
        ),
      ),
    if (gpsLocation != null)
      SensorMetricOption(
        key: 'gps',
        label: _selectorMetricLabel(
          _resolvedMetricLabel('gps', 'GPS', labelOverrides: labelOverrides),
          _sourceChannelForField(extraSensorData, 'gps'),
        ),
        defaultLabel: 'GPS',
        channel: _sourceChannelForField(extraSensorData, 'gps'),
        valuePreview:
            '${gpsLocation.latitude.toStringAsFixed(5)}, ${gpsLocation.longitude.toStringAsFixed(5)}',
        previewCardData: SensorMetricCardData(
          fieldKey: 'gps',
          icon: Icons.place,
          label: _resolvedMetricLabel(
            'gps',
            'GPS',
            labelOverrides: labelOverrides,
          ),
          value:
              '${gpsLocation.latitude.toStringAsFixed(5)}, ${gpsLocation.longitude.toStringAsFixed(5)}',
          secondaryValue: formatPlusCode(
            gpsLocation.latitude,
            gpsLocation.longitude,
          ),
          accent: const Color(0xFFAA3F57),
          wide: true,
          channel: _sourceChannelForField(extraSensorData, 'gps'),
        ),
      ),
  ];

  // Keys that are already shown as core telemetry fields above.
  // Skip them from extraSensorData to avoid duplicates.
  final coreFieldKeys = <String>{
    if (batteryMilliVolts != null || batteryPercentage != null)
      ...extraSensorData?.keys.where(
            (k) => k.startsWith('voltage_') || k.startsWith('analog_input_'),
          ) ??
          [],
    if (temperature != null)
      ...extraSensorData?.keys.where((k) => k.startsWith('temperature_')) ?? [],
    if (humidity != null)
      ...extraSensorData?.keys.where((k) => k.startsWith('humidity_')) ?? [],
    if (pressure != null)
      ...extraSensorData?.keys.where((k) => k.startsWith('pressure_')) ?? [],
  };

  if (extraSensorData != null) {
    for (final key in extraSensorData.keys) {
      if (_isTelemetryMetadataKey(key) || coreFieldKeys.contains(key)) {
        continue;
      }
      final metricKey = _parseMetricKey(key);
      final fieldKey = _extraFieldKey(key);
      final defaultLabel = _formatExtraFieldLabel(key);
      final resolvedLabel = _resolvedMetricLabel(
        fieldKey,
        defaultLabel,
        labelOverrides: labelOverrides,
      );
      options.add(
        SensorMetricOption(
          key: fieldKey,
          label: _selectorMetricLabel(resolvedLabel, metricKey.channel),
          defaultLabel: defaultLabel,
          channel: metricKey.channel,
          valuePreview: _sensorMetricPreviewValue(key, extraSensorData[key]),
          previewCardData: _buildOptionPreviewCardData(
            key,
            extraSensorData[key],
            fieldKey: fieldKey,
            label: resolvedLabel,
          ),
        ),
      );
    }
  }

  return options;
}

SensorMetricCardData? _buildOptionPreviewCardData(
  String rawKey,
  dynamic value, {
  required String fieldKey,
  required String label,
}) {
  final metricKey = _parseMetricKey(rawKey);
  final previewValue = _sensorMetricPreviewValue(rawKey, value);
  if (previewValue == null) {
    return null;
  }

  if (_isBinaryMetricBaseKey(metricKey.baseKey)) {
    return SensorMetricCardData(
      fieldKey: fieldKey,
      icon: previewValue == 'On' ? Icons.toggle_on : Icons.toggle_off,
      label: label,
      value: previewValue,
      accent: const Color(0xFF4B7B5A),
      channel: metricKey.channel,
    );
  }

  switch (metricKey.baseKey) {
    case 'altitude':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.terrain_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF7A5C3E),
        channel: metricKey.channel,
      );
    case 'illuminance':
      final lux = _previewAsDouble(value);
      final irradiance = lux == null
          ? null
          : _previewFormatDaylightIrradiance(lux);
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.light_mode_outlined,
        label: label,
        value: irradiance ?? previewValue,
        accent: const Color(0xFFC17B1D),
        channel: metricKey.channel,
      );
    case 'presence':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.sensor_occupied_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFFAA3F57),
        channel: metricKey.channel,
      );
    case 'digital_input':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.input_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF3A6D8C),
        channel: metricKey.channel,
      );
    case 'digital_output':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.output_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF4B7B5A),
        channel: metricKey.channel,
      );
    case 'analog_input':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.tune,
        label: label,
        value: previewValue,
        accent: const Color(0xFF5A6C84),
        channel: metricKey.channel,
      );
    case 'analog_output':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.tune,
        label: label,
        value: previewValue,
        accent: const Color(0xFF4B7785),
        channel: metricKey.channel,
      );
    case 'accelerometer':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.vibration_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF5A4C99),
        wide: true,
        channel: metricKey.channel,
      );
    case 'gyrometer':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.threed_rotation,
        label: label,
        value: previewValue,
        accent: const Color(0xFF6C4F96),
        wide: true,
        channel: metricKey.channel,
      );
    case 'generic_sensor':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.sensors,
        label: label,
        value: previewValue,
        accent: const Color(0xFF3E657C),
        channel: metricKey.channel,
      );
    case 'button_event':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.touch_app_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF6C4F96),
        channel: metricKey.channel,
      );
    case 'dimmer':
    case 'light_level':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.tune,
        label: label,
        value: previewValue,
        accent: const Color(0xFF5A6C84),
        channel: metricKey.channel,
      );
    case 'current':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.electric_bolt,
        label: label,
        value: previewValue,
        accent: const Color(0xFF1C7C54),
        channel: metricKey.channel,
      );
    case 'signed_current':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.electric_bolt,
        label: label,
        value: previewValue,
        accent: const Color(0xFF1C7C54),
        channel: metricKey.channel,
      );
    case 'frequency':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.graphic_eq,
        label: label,
        value: previewValue,
        accent: const Color(0xFF2C6BA0),
        channel: metricKey.channel,
      );
    case 'percentage':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.percent,
        label: label,
        value: previewValue,
        accent: const Color(0xFF4B8E2F),
        channel: metricKey.channel,
      );
    case 'concentration':
    case 'co2':
    case 'tvoc':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.bubble_chart_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF4D6D9A),
        channel: metricKey.channel,
      );
    case 'power':
    case 'signed_power':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.flash_on_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFFB5622E),
        channel: metricKey.channel,
      );
    case 'speed':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.air,
        label: label,
        value: previewValue,
        accent: const Color(0xFF2B78A0),
        channel: metricKey.channel,
      );
    case 'signed_speed':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.air,
        label: label,
        value: previewValue,
        accent: const Color(0xFF2B78A0),
        channel: metricKey.channel,
      );
    case 'gust':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.air,
        label: label,
        value: previewValue,
        accent: const Color(0xFF1E88A8),
        channel: metricKey.channel,
      );
    case 'dew':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.device_thermostat,
        label: label,
        value: previewValue,
        accent: const Color(0xFF2F7AA1),
        channel: metricKey.channel,
      );
    case 'rain':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.grain,
        label: label,
        value: previewValue,
        accent: const Color(0xFF2C6BA0),
        channel: metricKey.channel,
      );
    case 'distance':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.straighten,
        label: label,
        value: previewValue,
        accent: const Color(0xFF577590),
        channel: metricKey.channel,
      );
    case 'duration':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.timer_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF577590),
        channel: metricKey.channel,
      );
    case 'energy':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.battery_charging_full,
        label: label,
        value: previewValue,
        accent: const Color(0xFF9C6644),
        channel: metricKey.channel,
      );
    case 'volume':
    case 'flow_rate':
    case 'volume_storage':
    case 'water':
    case 'gas_volume':
    case 'mass':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.inventory_2_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF5F7C8A),
        channel: metricKey.channel,
      );
    case 'direction':
    case 'rotation':
      final degrees = _previewAsDouble(value);
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.explore_outlined,
        label: label,
        value: previewValue,
        secondaryValue: degrees == null
            ? null
            : _previewFormatCardinalDirection(degrees),
        accent: const Color(0xFF8A5A44),
        channel: metricKey.channel,
      );
    case 'unixtime':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.schedule,
        label: label,
        value: previewValue,
        accent: const Color(0xFF6B7280),
        wide: true,
        channel: metricKey.channel,
      );
    case 'colour':
      final color = _previewAsRgb(value);
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.palette_outlined,
        label: label,
        value: previewValue,
        secondaryValue: color == null
            ? null
            : 'R ${color.r} • G ${color.g} • B ${color.b}',
        accent: color == null
            ? const Color(0xFF3E657C)
            : Color.fromARGB(255, color.r, color.g, color.b),
        wide: true,
        channel: metricKey.channel,
      );
    case 'switch':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: previewValue == 'On' ? Icons.toggle_on : Icons.toggle_off,
        label: label,
        value: previewValue,
        accent: const Color(0xFF4B7B5A),
        channel: metricKey.channel,
      );
    case 'voltage':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.bolt,
        label: label,
        value: previewValue,
        accent: const Color(0xFF0A7D61),
        channel: metricKey.channel,
      );
    case 'conductivity':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.science_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF4D6D9A),
        channel: metricKey.channel,
      );
    case 'acceleration':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.speed_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFF5A4C99),
        channel: metricKey.channel,
      );
    case 'gyro_rate':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.sync,
        label: label,
        value: previewValue,
        accent: const Color(0xFF6C4F96),
        channel: metricKey.channel,
      );
    case 'pm25':
    case 'pm10':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.grain,
        label: label,
        value: previewValue,
        accent: const Color(0xFF7A6C5D),
        channel: metricKey.channel,
      );
    case 'uv':
      return SensorMetricCardData(
        fieldKey: fieldKey,
        icon: Icons.wb_sunny_outlined,
        label: label,
        value: previewValue,
        accent: const Color(0xFFC17B1D),
        channel: metricKey.channel,
      );
  }

  return SensorMetricCardData(
    fieldKey: fieldKey,
    icon: Icons.sensors,
    label: label,
    value: previewValue,
    accent: const Color(0xFF3E657C),
    wide: value is Map,
    channel: metricKey.channel,
  );
}

Set<String> sensorMetricKeysFor(Contact? contact) {
  return sensorMetricOptionsFor(contact).map((option) => option.key).toSet();
}

Map<String, int> sensorDefaultFieldSpans(Iterable<String> fieldKeys) {
  final spans = <String, int>{};
  if (fieldKeys.contains('gps')) {
    spans['gps'] = 2;
  }
  return spans;
}

Map<String, int> sensorFullWidthFieldSpans(Iterable<String> fieldKeys) {
  return {for (final fieldKey in fieldKeys) fieldKey: 2};
}

double _previewApproxDaylightIrradiance(double lux) {
  return lux / 120.0;
}

String _previewFormatDaylightIrradiance(double lux) {
  return '~${_formatPreviewNumber(_previewApproxDaylightIrradiance(lux), maxFractionDigits: 1)} W/m2';
}

String _previewFormatCardinalDirection(double degrees) {
  const points = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final normalized = ((degrees % 360) + 360) % 360;
  final index = ((normalized + 22.5) ~/ 45) % points.length;
  return points[index];
}

String? _sensorMetricPreviewValue(String rawKey, dynamic value) {
  final metricKey = _parseMetricKey(rawKey);

  if (_isBinaryMetricBaseKey(metricKey.baseKey)) {
    final isOn = _previewAsBool(value);
    if (isOn == null) return null;
    return isOn ? 'On' : 'Off';
  }

  switch (metricKey.baseKey) {
    case 'altitude':
      final meters = _previewAsDouble(value);
      if (meters == null) return null;
      return '${_formatPreviewNumber(meters, maxFractionDigits: 1)} m';

    case 'illuminance':
      final lux = _previewAsDouble(value);
      if (lux == null) return null;
      return _previewFormatDaylightIrradiance(lux);

    case 'presence':
      final isPresent = _previewAsBool(value);
      if (isPresent == null) return null;
      return isPresent ? 'Detected' : 'Clear';

    case 'digital_input':
    case 'digital_output':
      final isHigh = _previewAsBool(value);
      if (isHigh == null) return null;
      return isHigh ? 'High' : 'Low';

    case 'analog_input':
    case 'analog_output':
    case 'generic_sensor':
    case 'light_level':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return _formatPreviewNumber(reading, maxFractionDigits: 3);

    case 'button_event':
      final eventCode = _previewAsInt(value);
      if (eventCode == null) return null;
      return _formatButtonEvent(eventCode);

    case 'dimmer':
      final reading = _previewAsInt(value);
      if (reading == null) return null;
      return reading.toString();

    case 'accelerometer':
      final vector = _previewAsVector3(value);
      if (vector == null) return null;
      return 'X ${_formatPreviewNumber(vector.x)} • '
          'Y ${_formatPreviewNumber(vector.y)} • '
          'Z ${_formatPreviewNumber(vector.z)} g';

    case 'gyrometer':
      final vector = _previewAsVector3(value);
      if (vector == null) return null;
      return 'X ${_formatPreviewNumber(vector.x)} • '
          'Y ${_formatPreviewNumber(vector.y)} • '
          'Z ${_formatPreviewNumber(vector.z)} deg/s';

    case 'current':
      final amps = _previewAsDouble(value);
      if (amps == null) return null;
      return _formatPreviewCurrent(amps);

    case 'signed_current':
      final amps = _previewAsDouble(value);
      if (amps == null) return null;
      return _formatPreviewCurrent(amps);

    case 'frequency':
      final hertz = _previewAsDouble(value);
      if (hertz == null) return null;
      return _formatPreviewFrequency(hertz);

    case 'percentage':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return '${_formatPreviewNumber(reading, maxFractionDigits: 1)}%';

    case 'concentration':
    case 'co2':
    case 'tvoc':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return '${_formatPreviewNumber(reading, maxFractionDigits: 0)} ppm';

    case 'power':
      final watts = _previewAsDouble(value);
      if (watts == null) return null;
      return _formatPreviewPower(watts);

    case 'signed_power':
      final watts = _previewAsDouble(value);
      if (watts == null) return null;
      return _formatPreviewPower(watts);

    case 'speed':
      final metersPerSecond = _previewAsDouble(value);
      if (metersPerSecond == null) return null;
      return '${_formatPreviewNumber(metersPerSecond, maxFractionDigits: 2)} m/s';

    case 'signed_speed':
      final metersPerSecond = _previewAsDouble(value);
      if (metersPerSecond == null) return null;
      return '${_formatPreviewNumber(metersPerSecond, maxFractionDigits: 2)} m/s';

    case 'gust':
      final metersPerSecond = _previewAsDouble(value);
      if (metersPerSecond == null) return null;
      return '${_formatPreviewNumber(metersPerSecond, maxFractionDigits: 2)} m/s';

    case 'dew':
      final degreesCelsius = _previewAsDouble(value);
      if (degreesCelsius == null) return null;
      return '${_formatPreviewNumber(degreesCelsius, maxFractionDigits: 1)}°C';

    case 'rain':
      final millimeters = _previewAsDouble(value);
      if (millimeters == null) return null;
      return '${_formatPreviewNumber(millimeters, maxFractionDigits: 1)} mm';

    case 'distance':
      final meters = _previewAsDouble(value);
      if (meters == null) return null;
      return _formatPreviewDistance(meters);

    case 'duration':
      final seconds = _previewAsDouble(value);
      if (seconds == null) return null;
      return '${_formatPreviewNumber(seconds, maxFractionDigits: 2)} s';

    case 'energy':
      final kilowattHours = _previewAsDouble(value);
      if (kilowattHours == null) return null;
      return _formatPreviewEnergy(kilowattHours);

    case 'volume':
    case 'flow_rate':
    case 'volume_storage':
    case 'water':
    case 'gas_volume':
      final liters = _previewAsDouble(value);
      if (liters == null) return null;
      return '${_formatPreviewNumber(liters, maxFractionDigits: 3)} L';

    case 'mass':
      final kilograms = _previewAsDouble(value);
      if (kilograms == null) return null;
      return '${_formatPreviewNumber(kilograms, maxFractionDigits: 3)} kg';

    case 'direction':
      final degrees = _previewAsDouble(value);
      if (degrees == null) return null;
      return '${_formatPreviewNumber(degrees, maxFractionDigits: 0)} deg';

    case 'rotation':
      final degrees = _previewAsDouble(value);
      if (degrees == null) return null;
      return '${_formatPreviewNumber(degrees, maxFractionDigits: 1)} deg';

    case 'unixtime':
      final seconds = _previewAsInt(value);
      if (seconds == null) return null;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      ).toLocal();
      return _formatPreviewTelemetryDateTime(timestamp);

    case 'colour':
      final color = _previewAsRgb(value);
      if (color == null) return null;
      return '#${color.r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${color.g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${color.b.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    case 'switch':
      final isOn = _previewAsBool(value);
      if (isOn == null) return null;
      return isOn ? 'On' : 'Off';

    case 'voltage':
      final volts = _previewAsDouble(value);
      if (volts == null) return null;
      return '${_formatPreviewNumber(volts, maxFractionDigits: 3)} V';

    case 'conductivity':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return _formatPreviewNumber(reading, maxFractionDigits: 0);

    case 'acceleration':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return '${_formatPreviewNumber(reading, maxFractionDigits: 3)} m/s2';

    case 'gyro_rate':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return '${_formatPreviewNumber(reading, maxFractionDigits: 3)} deg/s';

    case 'pm25':
    case 'pm10':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return '${_formatPreviewNumber(reading, maxFractionDigits: 1)} ug/m3';

    case 'uv':
      final reading = _previewAsDouble(value);
      if (reading == null) return null;
      return _formatPreviewNumber(reading, maxFractionDigits: 1);
  }

  if (value is num) {
    return _formatPreviewNumber(value, maxFractionDigits: 2);
  }

  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key} ${entry.value}')
        .join(' • ');
  }

  return value?.toString();
}

_Vector3? _previewAsVector3(dynamic value) {
  if (value is! Map) return null;
  final x = _previewAsDouble(value['x']);
  final y = _previewAsDouble(value['y']);
  final z = _previewAsDouble(value['z']);
  if (x == null || y == null || z == null) return null;
  return _Vector3(x: x, y: y, z: z);
}

_RgbColor? _previewAsRgb(dynamic value) {
  if (value is! Map) return null;
  final red = _previewAsInt(value['r']);
  final green = _previewAsInt(value['g']);
  final blue = _previewAsInt(value['b']);
  if (red == null || green == null || blue == null) return null;
  return _RgbColor(r: red, g: green, b: blue);
}

double? _previewAsDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return null;
}

int? _previewAsInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return null;
}

bool? _previewAsBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return null;
}

String _formatPreviewCurrent(double amps) {
  final absolute = amps.abs();
  if (absolute < 1.0) {
    return '${_formatPreviewNumber(amps * 1000, maxFractionDigits: 1)} mA';
  }
  return '${_formatPreviewNumber(amps, maxFractionDigits: 3)} A';
}

String _formatPreviewPower(double watts) {
  final absolute = watts.abs();
  if (absolute < 1.0) {
    return '${_formatPreviewNumber(watts * 1000, maxFractionDigits: 1)} mW';
  }
  return '${_formatPreviewNumber(watts, maxFractionDigits: 2)} W';
}

String _formatPreviewFrequency(double hertz) {
  final absolute = hertz.abs();
  if (absolute >= 1000000) {
    return '${_formatPreviewNumber(hertz / 1000000, maxFractionDigits: 2)} MHz';
  }
  if (absolute >= 1000) {
    return '${_formatPreviewNumber(hertz / 1000, maxFractionDigits: 2)} kHz';
  }
  return '${_formatPreviewNumber(hertz, maxFractionDigits: 0)} Hz';
}

String _formatPreviewDistance(double meters) {
  final absolute = meters.abs();
  if (absolute < 1.0) {
    return '${_formatPreviewNumber(meters * 1000, maxFractionDigits: 0)} mm';
  }
  if (absolute >= 1000.0) {
    return '${_formatPreviewNumber(meters / 1000, maxFractionDigits: 2)} km';
  }
  return '${_formatPreviewNumber(meters, maxFractionDigits: 2)} m';
}

String _formatPreviewEnergy(double kilowattHours) {
  final absolute = kilowattHours.abs();
  if (absolute < 1.0) {
    return '${_formatPreviewNumber(kilowattHours * 1000, maxFractionDigits: 1)} Wh';
  }
  return '${_formatPreviewNumber(kilowattHours, maxFractionDigits: 3)} kWh';
}

String _formatPreviewNumber(num value, {int maxFractionDigits = 2}) {
  final absolute = value.abs();
  final digits = absolute >= 100
      ? 0
      : absolute >= 10
      ? math.min(maxFractionDigits, 1)
      : maxFractionDigits;
  final text = value.toStringAsFixed(digits);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _formatPreviewTelemetryDateTime(DateTime timestamp) {
  final local = timestamp.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

class SensorTelemetryCard extends StatelessWidget {
  final Contact? contact;
  final SensorRefreshState state;
  final Set<String> visibleFields;
  final List<String>? fieldOrder;
  final Map<String, int> fieldSpans;
  final Future<void> Function()? onRemove;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onCustomize;
  final Future<void> Function(Contact contact)? onShowMetHistory;
  final EdgeInsetsGeometry margin;
  final String emptyMetricsMessage;
  final Map<String, String> labelOverrides;

  const SensorTelemetryCard({
    super.key,
    required this.contact,
    required this.state,
    required this.visibleFields,
    this.fieldOrder,
    required this.fieldSpans,
    this.onRemove,
    this.onRefresh,
    this.onCustomize,
    this.onShowMetHistory,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.emptyMetricsMessage =
        'All fields are hidden. Use Visible fields to choose what to show.',
    this.labelOverrides = const <String, String>{},
  });

  bool get _showsMenu =>
      onRefresh != null ||
      onCustomize != null ||
      onRemove != null ||
      (contact != null &&
          onShowMetHistory != null &&
          supportsBTHomeMetHistory(contact));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final telemetry = contact?.telemetry;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metrics = contact == null || telemetry == null
        ? const <SensorMetricCardData>[]
        : _sortMetricsByFieldOrder(
            _buildMetricCards(l10n, telemetry, contact!),
          );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            contact?.displayName ?? 'Unavailable node',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (state == SensorRefreshState.timeout)
                            _InlineAlertBadge(label: l10n.noResponse),
                        ],
                      ),
                      if (telemetry != null) ...[
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${_formatTelemetryDateTime(telemetry.timestamp)} • ${_formatTelemetryTime(telemetry.timestamp)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (state == SensorRefreshState.refreshing)
                              _InlineStateMeta(
                                label: l10n.refreshing,
                                color: Color(0xFF266AC2),
                                spinning: true,
                              ),
                            if (state == SensorRefreshState.success)
                              const _InlineStateMeta(
                                label: 'Updated',
                                color: Color(0xFF218B63),
                                icon: Icons.check_circle,
                              ),
                            if (state == SensorRefreshState.unavailable)
                              _InlineStateMeta(
                                label: l10n.unavailable,
                                color: Color(0xFFB13B55),
                                icon: Icons.error_outline,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (_showsMenu)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'refresh' && onRefresh != null) {
                        await onRefresh!();
                      } else if (value == 'remove' && onRemove != null) {
                        await onRemove!();
                      } else if (value == 'customize' && onCustomize != null) {
                        onCustomize!();
                      } else if (value == 'met_history' &&
                          contact != null &&
                          onShowMetHistory != null) {
                        await onShowMetHistory!(contact!);
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[];
                      if (onRefresh != null) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'refresh',
                            child: Text(l10n.refresh),
                          ),
                        );
                      }
                      if (onCustomize != null) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'customize',
                            child: Text(l10n.customizeFields),
                          ),
                        );
                      }
                      if (contact != null &&
                          onShowMetHistory != null &&
                          supportsBTHomeMetHistory(contact)) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'met_history',
                            child: Text('MET history'),
                          ),
                        );
                      }
                      if (onRemove != null) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'remove',
                            child: Text(l10n.remove),
                          ),
                        );
                      }
                      return items;
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (contact == null)
              const Text(
                'This node is no longer available in the contact list.',
              )
            else if (telemetry == null)
              const Text(
                'No telemetry received yet. Use Refresh from the menu or pull down to fetch it.',
              )
            else if (metrics.isEmpty)
              Text(emptyMetricsMessage)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final compactWidth = (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: metrics
                        .map(
                          (metric) => SensorMetricTile(
                            data: metric,
                            width:
                                (fieldSpans[metric.fieldKey] == 2 ||
                                    metric.wide)
                                ? constraints.maxWidth
                                : compactWidth,
                            onLongPress: onRefresh == null
                                ? null
                                : () async {
                                    await onRefresh!();
                                  },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<SensorMetricCardData> _buildMetricCards(
    AppLocalizations l10n,
    dynamic telemetry,
    Contact contact,
  ) {
    final items = <SensorMetricCardData>[];

    if (visibleFields.contains('voltage') &&
        telemetry.batteryMilliVolts != null) {
      items.add(
        SensorMetricCardData(
          fieldKey: 'voltage',
          icon: Icons.bolt,
          label: _resolvedMetricLabel(
            'voltage',
            l10n.voltage,
            labelOverrides: labelOverrides,
          ),
          value: '${(telemetry.batteryMilliVolts! / 1000).toStringAsFixed(3)}V',
          accent: const Color(0xFF0A7D61),
          channel: _sourceChannelForField(telemetry.extraSensorData, 'voltage'),
        ),
      );
    }
    if (visibleFields.contains('battery') &&
        telemetry.batteryPercentage != null) {
      items.add(
        SensorMetricCardData(
          fieldKey: 'battery',
          icon: Icons.battery_5_bar,
          label: _resolvedMetricLabel(
            'battery',
            l10n.battery,
            labelOverrides: labelOverrides,
          ),
          value: '${telemetry.batteryPercentage!.toStringAsFixed(0)}%',
          accent: const Color(0xFF4B8E2F),
          channel: _sourceChannelForField(telemetry.extraSensorData, 'battery'),
        ),
      );
    }
    if (visibleFields.contains('temperature') &&
        telemetry.temperature != null) {
      items.add(
        SensorMetricCardData(
          fieldKey: 'temperature',
          icon: Icons.thermostat,
          label: _resolvedMetricLabel(
            'temperature',
            l10n.temperature,
            labelOverrides: labelOverrides,
          ),
          value: '${telemetry.temperature!.toStringAsFixed(1)}°C',
          accent: const Color(0xFFC76821),
          channel: _sourceChannelForField(
            telemetry.extraSensorData,
            'temperature',
          ),
        ),
      );
    }
    if (visibleFields.contains('humidity') && telemetry.humidity != null) {
      items.add(
        SensorMetricCardData(
          fieldKey: 'humidity',
          icon: Icons.water_drop,
          label: _resolvedMetricLabel(
            'humidity',
            l10n.humidity,
            labelOverrides: labelOverrides,
          ),
          value: '${telemetry.humidity!.toStringAsFixed(1)}%',
          accent: const Color(0xFF246BB2),
          channel: _sourceChannelForField(
            telemetry.extraSensorData,
            'humidity',
          ),
        ),
      );
    }
    if (visibleFields.contains('pressure') && telemetry.pressure != null) {
      items.add(
        SensorMetricCardData(
          fieldKey: 'pressure',
          icon: Icons.compress,
          label: _resolvedMetricLabel(
            'pressure',
            l10n.pressure,
            labelOverrides: labelOverrides,
          ),
          value: '${telemetry.pressure!.toStringAsFixed(1)} hPa',
          accent: const Color(0xFF6B4BAE),
          channel: _sourceChannelForField(
            telemetry.extraSensorData,
            'pressure',
          ),
        ),
      );
    }
    if (visibleFields.contains('gps') && telemetry.gpsLocation != null) {
      items.add(
        SensorMetricCardData(
          fieldKey: 'gps',
          icon: Icons.place,
          label: _resolvedMetricLabel(
            'gps',
            l10n.gpsTelemetry,
            labelOverrides: labelOverrides,
          ),
          value:
              '${telemetry.gpsLocation!.latitude.toStringAsFixed(5)}, ${telemetry.gpsLocation!.longitude.toStringAsFixed(5)}',
          accent: const Color(0xFFAA3F57),
          wide: true,
          mapLocation: LatLng(
            telemetry.gpsLocation!.latitude,
            telemetry.gpsLocation!.longitude,
          ),
          secondaryValue: formatPlusCode(
            telemetry.gpsLocation!.latitude,
            telemetry.gpsLocation!.longitude,
          ),
          channel: _sourceChannelForField(telemetry.extraSensorData, 'gps'),
        ),
      );
    }
    if (telemetry.extraSensorData != null) {
      for (final entry in telemetry.extraSensorData!.entries) {
        if (_isTelemetryMetadataKey(entry.key)) {
          continue;
        }
        final fieldKey = _extraFieldKey(entry.key);
        if (!visibleFields.contains(fieldKey)) {
          continue;
        }
        final metric = _buildExtraMetricCardData(entry.key, entry.value);
        if (metric != null) {
          items.add(metric);
        }
      }
    }

    return items;
  }

  List<SensorMetricCardData> _sortMetricsByFieldOrder(
    List<SensorMetricCardData> metrics,
  ) {
    final order = fieldOrder;
    if (order == null || order.isEmpty || metrics.length < 2) {
      return metrics;
    }

    final orderIndex = <String, int>{
      for (var i = 0; i < order.length; i++) order[i]: i,
    };
    final indexedMetrics = metrics.asMap().entries.toList();
    indexedMetrics.sort((left, right) {
      final leftOrder = orderIndex[left.value.fieldKey] ?? order.length;
      final rightOrder = orderIndex[right.value.fieldKey] ?? order.length;
      if (leftOrder != rightOrder) {
        return leftOrder.compareTo(rightOrder);
      }
      return left.key.compareTo(right.key);
    });
    return indexedMetrics.map((entry) => entry.value).toList(growable: false);
  }

  SensorMetricCardData? _buildExtraMetricCardData(
    String rawKey,
    dynamic value,
  ) {
    final metricKey = _parseMetricKey(rawKey);
    final fieldKey = _extraFieldKey(rawKey);
    final label = _resolvedMetricLabel(
      fieldKey,
      _formatExtraFieldLabel(rawKey),
      labelOverrides: labelOverrides,
    );

    if (_isBinaryMetricBaseKey(metricKey.baseKey)) {
      final isOn = _asBool(value);
      if (isOn == null) return null;
      return SensorMetricCardData(
        fieldKey: _extraFieldKey(rawKey),
        icon: isOn ? Icons.toggle_on : Icons.toggle_off,
        label: label,
        value: isOn ? 'On' : 'Off',
        accent: const Color(0xFF4B7B5A),
        channel: metricKey.channel,
      );
    }

    switch (metricKey.baseKey) {
      case 'altitude':
        final meters = _asDouble(value);
        if (meters == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.terrain_outlined,
          label: label,
          value: '${_formatNumber(meters, maxFractionDigits: 1)} m',
          accent: const Color(0xFF7A5C3E),
          channel: metricKey.channel,
        );

      case 'illuminance':
        final lux = _asDouble(value);
        if (lux == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.light_mode_outlined,
          label: label,
          value: _formatDaylightIrradiance(lux),
          accent: const Color(0xFFC17B1D),
          channel: metricKey.channel,
        );

      case 'presence':
        final isPresent = _asBool(value);
        if (isPresent == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.sensor_occupied_outlined,
          label: label,
          value: isPresent ? 'Detected' : 'Clear',
          accent: const Color(0xFFAA3F57),
          channel: metricKey.channel,
        );

      case 'digital_input':
        final isHigh = _asBool(value);
        if (isHigh == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.input_outlined,
          label: label,
          value: isHigh ? 'High' : 'Low',
          accent: const Color(0xFF3A6D8C),
          channel: metricKey.channel,
        );

      case 'digital_output':
        final isHigh = _asBool(value);
        if (isHigh == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.output_outlined,
          label: label,
          value: isHigh ? 'High' : 'Low',
          accent: const Color(0xFF4B7B5A),
          channel: metricKey.channel,
        );

      case 'analog_input':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.tune,
          label: label,
          value: _formatNumber(reading, maxFractionDigits: 3),
          accent: const Color(0xFF5A6C84),
          channel: metricKey.channel,
        );

      case 'analog_output':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.tune,
          label: label,
          value: _formatNumber(reading, maxFractionDigits: 3),
          accent: const Color(0xFF4B7785),
          channel: metricKey.channel,
        );

      case 'accelerometer':
        final vector = _asVector3(value);
        if (vector == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.vibration_outlined,
          label: label,
          value:
              'X ${_formatNumber(vector.x)} • Y ${_formatNumber(vector.y)} • Z ${_formatNumber(vector.z)} g',
          secondaryValue:
              '|a| ${_formatNumber(_vectorMagnitude(vector), maxFractionDigits: 2)} g',
          accent: const Color(0xFF5A4C99),
          wide: true,
          channel: metricKey.channel,
        );

      case 'gyrometer':
        final vector = _asVector3(value);
        if (vector == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.threed_rotation,
          label: label,
          value:
              'X ${_formatNumber(vector.x)} • Y ${_formatNumber(vector.y)} • Z ${_formatNumber(vector.z)} deg/s',
          secondaryValue:
              '|w| ${_formatNumber(_vectorMagnitude(vector), maxFractionDigits: 2)} deg/s',
          accent: const Color(0xFF6C4F96),
          wide: true,
          channel: metricKey.channel,
        );

      case 'generic_sensor':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.sensors,
          label: label,
          value: _formatNumber(reading, maxFractionDigits: 2),
          accent: const Color(0xFF3E657C),
          channel: metricKey.channel,
        );

      case 'button_event':
        final reading = _asInt(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.touch_app_outlined,
          label: label,
          value: _formatButtonEvent(reading),
          accent: const Color(0xFF6C4F96),
          channel: metricKey.channel,
        );

      case 'dimmer':
      case 'light_level':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.tune,
          label: label,
          value: _formatNumber(reading, maxFractionDigits: 2),
          accent: const Color(0xFF5A6C84),
          channel: metricKey.channel,
        );

      case 'current':
        final amps = _asDouble(value);
        if (amps == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.electric_bolt,
          label: label,
          value: _formatCurrent(amps),
          accent: const Color(0xFF1C7C54),
          channel: metricKey.channel,
        );

      case 'signed_current':
        final amps = _asDouble(value);
        if (amps == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.electric_bolt,
          label: label,
          value: _formatCurrent(amps),
          accent: const Color(0xFF1C7C54),
          channel: metricKey.channel,
        );

      case 'frequency':
        final hz = _asDouble(value);
        if (hz == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.graphic_eq,
          label: label,
          value: _formatFrequency(hz),
          accent: const Color(0xFF2C6BA0),
          channel: metricKey.channel,
        );

      case 'percentage':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.percent,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 1)}%',
          accent: const Color(0xFF4B8E2F),
          channel: metricKey.channel,
        );

      case 'concentration':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.bubble_chart_outlined,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 0)} ppm',
          accent: const Color(0xFF4D6D9A),
          channel: metricKey.channel,
        );

      case 'power':
        final watts = _asDouble(value);
        if (watts == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.flash_on_outlined,
          label: label,
          value: _formatPower(watts),
          accent: const Color(0xFFB5622E),
          channel: metricKey.channel,
        );

      case 'signed_power':
        final watts = _asDouble(value);
        if (watts == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.flash_on_outlined,
          label: label,
          value: _formatPower(watts),
          accent: const Color(0xFFB5622E),
          channel: metricKey.channel,
        );

      case 'speed':
        final metersPerSecond = _asDouble(value);
        if (metersPerSecond == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.air,
          label: label,
          value: '${_formatNumber(metersPerSecond, maxFractionDigits: 2)} m/s',
          accent: const Color(0xFF2B78A0),
          channel: metricKey.channel,
        );

      case 'signed_speed':
        final metersPerSecond = _asDouble(value);
        if (metersPerSecond == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.air,
          label: label,
          value: '${_formatNumber(metersPerSecond, maxFractionDigits: 2)} m/s',
          accent: const Color(0xFF2B78A0),
          channel: metricKey.channel,
        );

      case 'gust':
        final metersPerSecond = _asDouble(value);
        if (metersPerSecond == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.air,
          label: label,
          value: '${_formatNumber(metersPerSecond, maxFractionDigits: 2)} m/s',
          accent: const Color(0xFF1E88A8),
          channel: metricKey.channel,
        );

      case 'dew':
        final degreesCelsius = _asDouble(value);
        if (degreesCelsius == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.device_thermostat,
          label: label,
          value: '${_formatNumber(degreesCelsius, maxFractionDigits: 1)}°C',
          accent: const Color(0xFF2F7AA1),
          channel: metricKey.channel,
        );

      case 'rain':
        final millimeters = _asDouble(value);
        if (millimeters == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.grain,
          label: label,
          value: '${_formatNumber(millimeters, maxFractionDigits: 1)} mm',
          accent: const Color(0xFF2C6BA0),
          channel: metricKey.channel,
        );

      case 'distance':
        final meters = _asDouble(value);
        if (meters == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.straighten,
          label: label,
          value: _formatDistance(meters),
          accent: const Color(0xFF577590),
          channel: metricKey.channel,
        );

      case 'duration':
        final seconds = _asDouble(value);
        if (seconds == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.timer_outlined,
          label: label,
          value: '${_formatNumber(seconds, maxFractionDigits: 2)} s',
          accent: const Color(0xFF577590),
          channel: metricKey.channel,
        );

      case 'energy':
        final kwh = _asDouble(value);
        if (kwh == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.battery_charging_full,
          label: label,
          value: _formatEnergy(kwh),
          accent: const Color(0xFF9C6644),
          channel: metricKey.channel,
        );

      case 'volume':
      case 'flow_rate':
      case 'volume_storage':
      case 'water':
      case 'gas_volume':
      case 'mass':
        final reading = _asDouble(value);
        if (reading == null) return null;
        final unit = metricKey.baseKey == 'mass' ? 'kg' : 'L';
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.inventory_2_outlined,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 3)} $unit',
          accent: const Color(0xFF5F7C8A),
          channel: metricKey.channel,
        );

      case 'direction':
        final degrees = _asDouble(value);
        if (degrees == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.explore_outlined,
          label: label,
          value: '${_formatNumber(degrees, maxFractionDigits: 0)} deg',
          secondaryValue: _formatCardinalDirection(degrees),
          accent: const Color(0xFF8A5A44),
          channel: metricKey.channel,
        );

      case 'rotation':
        final degrees = _asDouble(value);
        if (degrees == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.explore_outlined,
          label: label,
          value: '${_formatNumber(degrees, maxFractionDigits: 1)} deg',
          accent: const Color(0xFF8A5A44),
          channel: metricKey.channel,
        );

      case 'unixtime':
        final seconds = _asInt(value);
        if (seconds == null) return null;
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toLocal();
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.schedule,
          label: label,
          value: _formatTelemetryDateTime(timestamp),
          secondaryValue: _formatTelemetryTime(timestamp),
          accent: const Color(0xFF6B7280),
          wide: true,
          channel: metricKey.channel,
        );

      case 'colour':
        final color = _asRgb(value);
        if (color == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.palette_outlined,
          label: label,
          value:
              '#${color.r.toRadixString(16).padLeft(2, '0').toUpperCase()}${color.g.toRadixString(16).padLeft(2, '0').toUpperCase()}${color.b.toRadixString(16).padLeft(2, '0').toUpperCase()}',
          secondaryValue: 'R ${color.r} • G ${color.g} • B ${color.b}',
          accent: Color.fromARGB(255, color.r, color.g, color.b),
          wide: true,
          channel: metricKey.channel,
        );

      case 'switch':
        final isOn = _asBool(value);
        if (isOn == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: isOn ? Icons.toggle_on : Icons.toggle_off,
          label: label,
          value: isOn ? 'On' : 'Off',
          accent: const Color(0xFF4B7B5A),
          channel: metricKey.channel,
        );

      case 'voltage':
        final volts = _asDouble(value);
        if (volts == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.bolt,
          label: label,
          value: '${_formatNumber(volts, maxFractionDigits: 3)} V',
          accent: const Color(0xFF0A7D61),
          channel: metricKey.channel,
        );

      case 'conductivity':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.science_outlined,
          label: label,
          value: _formatNumber(reading, maxFractionDigits: 0),
          accent: const Color(0xFF4D6D9A),
          channel: metricKey.channel,
        );

      case 'acceleration':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.speed_outlined,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 3)} m/s2',
          accent: const Color(0xFF5A4C99),
          channel: metricKey.channel,
        );

      case 'gyro_rate':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.sync,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 3)} deg/s',
          accent: const Color(0xFF6C4F96),
          channel: metricKey.channel,
        );
    }

    switch (metricKey.baseKey) {
      case 'co2':
      case 'tvoc':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.bubble_chart_outlined,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 0)} ppm',
          accent: const Color(0xFF4D6D9A),
          channel: metricKey.channel,
        );

      case 'pm25':
      case 'pm10':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.grain,
          label: label,
          value: '${_formatNumber(reading, maxFractionDigits: 1)} ug/m3',
          accent: const Color(0xFF7A6C5D),
          channel: metricKey.channel,
        );

      case 'uv':
        final reading = _asDouble(value);
        if (reading == null) return null;
        return SensorMetricCardData(
          fieldKey: _extraFieldKey(rawKey),
          icon: Icons.wb_sunny_outlined,
          label: label,
          value: _formatNumber(reading, maxFractionDigits: 1),
          accent: const Color(0xFFC17B1D),
          channel: metricKey.channel,
        );
    }

    if (value is num) {
      return SensorMetricCardData(
        fieldKey: _extraFieldKey(rawKey),
        icon: Icons.sensors,
        label: label,
        value: _formatNumber(value, maxFractionDigits: 2),
        accent: const Color(0xFF3E657C),
        channel: metricKey.channel,
      );
    }

    return SensorMetricCardData(
      fieldKey: _extraFieldKey(rawKey),
      icon: Icons.sensors,
      label: label,
      value: '$value',
      accent: const Color(0xFF3E657C),
      wide: value is Map,
      channel: metricKey.channel,
    );
  }

  double _approxDaylightIrradiance(double lux) {
    return lux / 120.0;
  }

  String _formatDaylightIrradiance(double lux) {
    return '~${_formatNumber(_approxDaylightIrradiance(lux), maxFractionDigits: 1)} W/m2';
  }

  String _formatCurrent(double amps) {
    final absolute = amps.abs();
    if (absolute < 1.0) {
      return '${_formatNumber(amps * 1000, maxFractionDigits: 1)} mA';
    }
    return '${_formatNumber(amps, maxFractionDigits: 3)} A';
  }

  String _formatPower(double watts) {
    final absolute = watts.abs();
    if (absolute < 1.0) {
      return '${_formatNumber(watts * 1000, maxFractionDigits: 1)} mW';
    }
    return '${_formatNumber(watts, maxFractionDigits: 2)} W';
  }

  String _formatFrequency(double hertz) {
    final absolute = hertz.abs();
    if (absolute >= 1000000) {
      return '${_formatNumber(hertz / 1000000, maxFractionDigits: 2)} MHz';
    }
    if (absolute >= 1000) {
      return '${_formatNumber(hertz / 1000, maxFractionDigits: 2)} kHz';
    }
    return '${_formatNumber(hertz, maxFractionDigits: 0)} Hz';
  }

  String _formatDistance(double meters) {
    final absolute = meters.abs();
    if (absolute < 1.0) {
      return '${_formatNumber(meters * 1000, maxFractionDigits: 0)} mm';
    }
    if (absolute >= 1000.0) {
      return '${_formatNumber(meters / 1000, maxFractionDigits: 2)} km';
    }
    return '${_formatNumber(meters, maxFractionDigits: 2)} m';
  }

  String _formatEnergy(double kilowattHours) {
    final absolute = kilowattHours.abs();
    if (absolute < 1.0) {
      return '${_formatNumber(kilowattHours * 1000, maxFractionDigits: 1)} Wh';
    }
    return '${_formatNumber(kilowattHours, maxFractionDigits: 3)} kWh';
  }

  String _formatCardinalDirection(double degrees) {
    const points = <String>['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalized = ((degrees % 360) + 360) % 360;
    final index = ((normalized + 22.5) ~/ 45) % points.length;
    return points[index];
  }

  String _formatNumber(num value, {int maxFractionDigits = 2}) {
    final absolute = value.abs();
    final digits = absolute >= 100
        ? 0
        : absolute >= 10
        ? math.min(maxFractionDigits, 1)
        : maxFractionDigits;
    final text = value.toStringAsFixed(digits);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  _Vector3? _asVector3(dynamic value) {
    if (value is! Map) return null;
    final x = _asDouble(value['x']);
    final y = _asDouble(value['y']);
    final z = _asDouble(value['z']);
    if (x == null || y == null || z == null) return null;
    return _Vector3(x: x, y: y, z: z);
  }

  _RgbColor? _asRgb(dynamic value) {
    if (value is! Map) return null;
    final red = _asInt(value['r']);
    final green = _asInt(value['g']);
    final blue = _asInt(value['b']);
    if (red == null || green == null || blue == null) return null;
    return _RgbColor(r: red, g: green, b: blue);
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return null;
  }

  double _vectorMagnitude(_Vector3 vector) {
    return math.sqrt(
      vector.x * vector.x + vector.y * vector.y + vector.z * vector.z,
    );
  }

  String _formatTelemetryTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTelemetryDateTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _InlineStateMeta extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool spinning;

  const _InlineStateMeta({
    required this.label,
    required this.color,
    this.icon,
    this.spinning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinning)
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.7,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else if (icon != null)
            Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAlertBadge extends StatelessWidget {
  final String label;

  const _InlineAlertBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFC17B1D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFC17B1D),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SensorMetricTile extends StatelessWidget {
  final SensorMetricCardData data;
  final double width;
  final String keyPrefix;
  final bool allowMapPreview;
  final GestureLongPressCallback? onLongPress;

  const SensorMetricTile({
    super.key,
    required this.data,
    required this.width,
    this.keyPrefix = 'sensor_metric',
    this.allowMapPreview = true,
    this.onLongPress,
  });

  Future<void> _showExpandedMap(BuildContext context) async {
    final location = data.mapLocation;
    if (location == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (pageContext) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.label),
                  Text(
                    data.value,
                    style: Theme.of(pageContext).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.secondaryValue != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      data.secondaryValue!,
                      style: Theme.of(pageContext).textTheme.bodyMedium,
                    ),
                  ),
                Expanded(
                  child: flutter_map.FlutterMap(
                    options: flutter_map.MapOptions(
                      initialCenter: location,
                      initialZoom: 15,
                    ),
                    children: [
                      flutter_map.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.meshcore.sar.meshcore_sar_app',
                      ),
                      flutter_map.MarkerLayer(
                        markers: [
                          flutter_map.Marker(
                            point: location,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: data.accent,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('${keyPrefix}_${data.fieldKey}'),
        borderRadius: BorderRadius.circular(22),
        onLongPress: onLongPress,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: data.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: data.accent.withValues(alpha: 0.14)),
          ),
          child: data.mapLocation == null || !allowMapPreview
              ? Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricIcon(accent: data.accent, icon: data.icon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricText(data: data, keyPrefix: keyPrefix),
                        ),
                      ],
                    ),
                    if (data.channel != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Text(
                          'ch${data.channel}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: data.accent.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetricIcon(accent: data.accent, icon: data.icon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricText(data: data, keyPrefix: keyPrefix),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showExpandedMap(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 104,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                flutter_map.FlutterMap(
                                  options: flutter_map.MapOptions(
                                    initialCenter: data.mapLocation!,
                                    initialZoom: 14,
                                    interactionOptions:
                                        const flutter_map.InteractionOptions(
                                          flags:
                                              flutter_map.InteractiveFlag.none,
                                        ),
                                  ),
                                  children: [
                                    flutter_map.TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.meshcore.sar.meshcore_sar_app',
                                    ),
                                    flutter_map.MarkerLayer(
                                      markers: [
                                        flutter_map.Marker(
                                          point: data.mapLocation!,
                                          width: 32,
                                          height: 32,
                                          child: Icon(
                                            Icons.location_on,
                                            color: data.accent,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.open_in_full,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Open map',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  final Color accent;
  final IconData icon;

  const _MetricIcon({required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: accent, size: 18),
    );
  }
}

class _MetricText extends StatelessWidget {
  final SensorMetricCardData data;
  final String keyPrefix;

  const _MetricText({required this.data, required this.keyPrefix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: data.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        if (data.secondaryValue != null) ...[
          const SizedBox(height: 4),
          Text(
            data.secondaryValue!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class SensorMetricCardData {
  final String fieldKey;
  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;
  final Color accent;
  final bool wide;
  final LatLng? mapLocation;
  final int? channel;

  const SensorMetricCardData({
    required this.fieldKey,
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
    required this.accent,
    this.wide = false,
    this.mapLocation,
    this.channel,
  });
}

class _ParsedMetricKey {
  final String baseKey;
  final int? channel;

  const _ParsedMetricKey({required this.baseKey, this.channel});
}

class _Vector3 {
  final double x;
  final double y;
  final double z;

  const _Vector3({required this.x, required this.y, required this.z});
}

class _RgbColor {
  final int r;
  final int g;
  final int b;

  const _RgbColor({required this.r, required this.g, required this.b});
}

const String _telemetrySourceChannelPrefix = '__source_channel:';

String _extraFieldKey(String label) {
  return 'extra:$label';
}

bool _isTelemetryMetadataKey(String key) {
  return key.startsWith(_telemetrySourceChannelPrefix);
}

String _telemetrySourceChannelKey(String fieldKey) {
  return '$_telemetrySourceChannelPrefix$fieldKey';
}

int? _sourceChannelForField(
  Map<String, dynamic>? extraSensorData,
  String fieldKey,
) {
  final value = extraSensorData?[_telemetrySourceChannelKey(fieldKey)];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

String _resolvedMetricLabel(
  String fieldKey,
  String defaultLabel, {
  Map<String, String> labelOverrides = const <String, String>{},
}) {
  final override = labelOverrides[fieldKey]?.trim();
  if (override == null || override.isEmpty) {
    return defaultLabel;
  }
  return override;
}

String _selectorMetricLabel(String label, int? channel) {
  if (channel == null) {
    return label;
  }
  return '$label (ch $channel)';
}

bool _isBinaryMetricBaseKey(String baseKey) {
  return baseKey.startsWith('binary_');
}

String _formatButtonEvent(int value) {
  switch (value) {
    case 0:
      return 'None';
    case 1:
      return 'Press';
    case 2:
      return 'Double press';
    case 3:
      return 'Triple press';
    case 4:
      return 'Long press';
    case 5:
      return 'Long double';
    case 6:
      return 'Long triple';
    case 128:
      return 'Hold';
  }
  return value.toString();
}

String _formatExtraFieldLabel(String rawKey) {
  final metricKey = _parseMetricKey(rawKey);
  return _knownMetricLabels[metricKey.baseKey] ??
      _fallbackMetricLabel(metricKey.baseKey);
}

const List<String> _knownMetricBaseKeys = <String>[
  'generic_sensor',
  'digital_output',
  'digital_input',
  'analog_output',
  'analog_input',
  'accelerometer',
  'illuminance',
  'concentration',
  'percentage',
  'direction',
  'frequency',
  'distance',
  'altitude',
  'humidity',
  'pressure',
  'temperature',
  'gyrometer',
  'unixtime',
  'presence',
  'current',
  'voltage',
  'colour',
  'switch',
  'energy',
  'power',
  'speed',
  'gust',
  'dew',
  'rain',
  'pm25',
  'pm10',
  'tvoc',
  'co2',
  'rpm',
  'conductivity',
  'uv',
  'button_event',
  'dimmer',
  'light_level',
  'rotation',
  'duration',
  'acceleration',
  'gyro_rate',
  'volume',
  'flow_rate',
  'volume_storage',
  'water',
  'gas_volume',
  'mass',
  'signed_speed',
  'signed_power',
  'signed_current',
  'binary_bool',
  'binary_power_switch',
  'binary_open',
  'binary_battery_low',
  'binary_charging',
  'binary_carbon_monoxide',
  'binary_cold',
  'binary_connectivity',
  'binary_door',
  'binary_garage_door',
  'binary_gas',
  'binary_heat',
  'binary_light',
  'binary_lock',
  'binary_moisture',
  'binary_motion',
  'binary_moving',
  'binary_occupancy',
  'binary_plug',
  'binary_presence',
  'binary_problem',
  'binary_running',
  'binary_safety',
  'binary_smoke',
  'binary_sound',
  'binary_tamper',
  'binary_vibration',
  'binary_window',
];

const Map<String, String> _knownMetricLabels = <String, String>{
  'accelerometer': 'Accelerometer',
  'altitude': 'Altitude',
  'analog_input': 'Analog input',
  'analog_output': 'Analog output',
  'co2': 'CO2',
  'colour': 'Color',
  'concentration': 'Concentration',
  'conductivity': 'Conductivity',
  'current': 'Current',
  'button_event': 'Button',
  'dimmer': 'Dimmer',
  'digital_input': 'Digital input',
  'digital_output': 'Digital output',
  'direction': 'Direction',
  'distance': 'Distance',
  'duration': 'Duration',
  'energy': 'Energy',
  'frequency': 'Frequency',
  'flow_rate': 'Flow rate',
  'gas_volume': 'Gas volume',
  'generic_sensor': 'Generic sensor',
  'gyro_rate': 'Gyro rate',
  'gyrometer': 'Gyrometer',
  'humidity': 'Humidity',
  'illuminance': 'Illuminance',
  'light_level': 'Light level',
  'mass': 'Mass',
  'percentage': 'Percentage',
  'pm10': 'PM10',
  'pm25': 'PM2.5',
  'power': 'Power',
  'presence': 'Presence',
  'pressure': 'Pressure',
  'rain': 'Rain',
  'rotation': 'Rotation',
  'rpm': 'RPM',
  'gust': 'Wind gust',
  'signed_current': 'Signed current',
  'signed_power': 'Signed power',
  'signed_speed': 'Signed speed',
  'speed': 'Speed',
  'switch': 'Switch',
  'dew': 'Dew point',
  'temperature': 'Temperature',
  'tvoc': 'TVOC',
  'unixtime': 'Time',
  'uv': 'UV index',
  'volume': 'Volume',
  'volume_storage': 'Storage volume',
  'voltage': 'Voltage',
  'water': 'Water',
  'binary_battery_low': 'Battery low',
  'binary_bool': 'Binary',
  'binary_carbon_monoxide': 'Carbon monoxide',
  'binary_charging': 'Charging',
  'binary_cold': 'Cold',
  'binary_connectivity': 'Connectivity',
  'binary_door': 'Door',
  'binary_garage_door': 'Garage door',
  'binary_gas': 'Gas',
  'binary_heat': 'Heat',
  'binary_light': 'Light',
  'binary_lock': 'Lock',
  'binary_moisture': 'Moisture',
  'binary_motion': 'Motion',
  'binary_moving': 'Moving',
  'binary_occupancy': 'Occupancy',
  'binary_open': 'Open',
  'binary_plug': 'Plug',
  'binary_power_switch': 'Power switch',
  'binary_presence': 'Presence',
  'binary_problem': 'Problem',
  'binary_running': 'Running',
  'binary_safety': 'Safety',
  'binary_smoke': 'Smoke',
  'binary_sound': 'Sound',
  'binary_tamper': 'Tamper',
  'binary_vibration': 'Vibration',
  'binary_window': 'Window',
};

_ParsedMetricKey _parseMetricKey(String rawKey) {
  for (final baseKey in _knownMetricBaseKeys) {
    if (rawKey == baseKey) {
      return _ParsedMetricKey(baseKey: baseKey);
    }
    if (rawKey.startsWith('${baseKey}_')) {
      final channel = int.tryParse(rawKey.substring(baseKey.length + 1));
      if (channel != null) {
        return _ParsedMetricKey(baseKey: baseKey, channel: channel);
      }
    }
  }

  final parts = rawKey.split('_');
  if (parts.length > 1) {
    final channel = int.tryParse(parts.last);
    if (channel != null) {
      return _ParsedMetricKey(
        baseKey: parts.sublist(0, parts.length - 1).join('_'),
        channel: channel,
      );
    }
  }

  return _ParsedMetricKey(baseKey: rawKey);
}

String _fallbackMetricLabel(String rawKey) {
  return rawKey
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
