import '../models/contact.dart';

enum BTHomeMetMeasurement {
  temperature(1, 'Temperature', '°C'),
  humidity(2, 'Humidity', '%'),
  windSpeed(3, 'Wind speed', 'm/s'),
  gust(4, 'Wind gust', 'm/s'),
  rain(5, 'Rain', 'mm');

  const BTHomeMetMeasurement(this.id, this.label, this.unit);

  final int id;
  final String label;
  final String unit;

  static BTHomeMetMeasurement? fromId(int id) {
    for (final value in BTHomeMetMeasurement.values) {
      if (value.id == id) {
        return value;
      }
    }
    return null;
  }
}

class BTHomeMetHistoryPage {
  const BTHomeMetHistoryPage({
    required this.measurement,
    required this.page,
    required this.values,
  });

  final BTHomeMetMeasurement measurement;
  final int page;
  final List<double> values;

  double? get latest => values.isEmpty ? null : values.last;
  double? get minimum => values.isEmpty
      ? null
      : values.reduce((left, right) => left < right ? left : right);
  double? get maximum => values.isEmpty
      ? null
      : values.reduce((left, right) => left > right ? left : right);
}

class BTHomeMetHistoryFormatException implements Exception {
  const BTHomeMetHistoryFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BTHomeMetHistoryParser {
  static BTHomeMetHistoryPage parse(String text) {
    final parts = text
        .trim()
        .split(',')
        .map((part) => part.trim())
        .toList(growable: false);
    if (parts.length < 3) {
      throw const BTHomeMetHistoryFormatException(
        'MET history response is too short.',
      );
    }

    final measurementId = int.tryParse(parts[0]);
    final page = int.tryParse(parts[1]);
    final count = int.tryParse(parts[2]);
    if (measurementId == null || page == null || count == null) {
      throw const BTHomeMetHistoryFormatException(
        'MET history header is invalid.',
      );
    }

    final measurement = BTHomeMetMeasurement.fromId(measurementId);
    if (measurement == null) {
      throw BTHomeMetHistoryFormatException(
        'Unsupported MET history measurement id: $measurementId',
      );
    }
    if (count < 0) {
      throw const BTHomeMetHistoryFormatException(
        'MET history sample count is invalid.',
      );
    }
    if (parts.length != count + 3) {
      throw BTHomeMetHistoryFormatException(
        'MET history sample count mismatch: expected $count values, got ${parts.length - 3}.',
      );
    }

    final values = <double>[];
    for (final part in parts.skip(3)) {
      final value = double.tryParse(part);
      if (value == null) {
        throw BTHomeMetHistoryFormatException(
          'Invalid MET history sample value: $part',
        );
      }
      values.add(value);
    }

    return BTHomeMetHistoryPage(
      measurement: measurement,
      page: page,
      values: List<double>.unmodifiable(values),
    );
  }
}

bool _isTruthyCapabilityValue(Object? value) {
  if (value is num) {
    return value > 0;
  }
  if (value is bool) {
    return value;
  }
  return false;
}

bool _hasBTHomeMetCapability(Contact? contact) {
  final extraSensorData = contact?.telemetry?.extraSensorData;
  if (extraSensorData == null) {
    return false;
  }

  // MET history is only enabled when the node advertises an explicit
  // capability marker on channel 1. Accept a small set of channel-1 marker
  // keys so the app remains tolerant while firmware-side encoding settles.
  const capabilityKeys = <String>[
    'met_capability',
    'met_capability_1',
    'generic_sensor_1',
    'light_level_1',
  ];

  for (final key in capabilityKeys) {
    if (_isTruthyCapabilityValue(extraSensorData[key])) {
      return true;
    }
  }

  return false;
}

List<BTHomeMetMeasurement> bTHomeMetMeasurementsForContact(Contact? contact) {
  final telemetry = contact?.telemetry;
  if (telemetry == null || !_hasBTHomeMetCapability(contact)) {
    return const <BTHomeMetMeasurement>[];
  }

  final measurements = <BTHomeMetMeasurement>[
    if (telemetry.temperature != null) BTHomeMetMeasurement.temperature,
    if (telemetry.humidity != null) BTHomeMetMeasurement.humidity,
  ];

  final extraSensorData = telemetry.extraSensorData;
  if (extraSensorData != null) {
    if (extraSensorData.keys.any(
      (key) => key.startsWith('speed_') || key.startsWith('signed_speed_'),
    )) {
      measurements.add(BTHomeMetMeasurement.windSpeed);
    }
    if (extraSensorData.keys.any((key) => key.startsWith('gust_'))) {
      measurements.add(BTHomeMetMeasurement.gust);
    }
    if (extraSensorData.keys.any((key) => key.startsWith('rain_'))) {
      measurements.add(BTHomeMetMeasurement.rain);
    }
  }

  return List<BTHomeMetMeasurement>.unmodifiable(measurements);
}

bool supportsBTHomeMetHistory(Contact? contact) =>
    bTHomeMetMeasurementsForContact(contact).isNotEmpty;
