import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_client/meshcore_client.dart';

/// Cayenne LPP (Low Power Payload) data parser
/// Used for decoding telemetry sensor data from MeshCore devices
class CayenneLppParser {
  static const int _selfTelemetryChannel = 1;
  static const int _lppGenericSensor = 100;
  static const int _lppCurrent = 117;
  static const int _lppFrequency = 118;
  static const int _lppPercentage = 120;
  static const int _lppAltitude = 121;
  static const int _lppConcentration = 125;
  static const int _lppPower = 128;
  static const int _lppSpeed = 129;
  static const int _lppDistance = 130;
  static const int _lppEnergy = 131;
  static const int _lppDirection = 132;
  static const int _lppUnixTime = 133;
  static const int _lppColour = 135;
  static const int _lppSwitch = 142;

  /// Parse Cayenne LPP data into ContactTelemetry
  static ContactTelemetry parse(Uint8List data) {
    debugPrint('  [CayenneLPP] Parsing LPP data...');
    debugPrint('    Data length: ${data.length} bytes');
    debugPrint(
      '    Data (hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );

    final reader = BufferReader(data);

    LatLng? gpsLocation;
    double? batteryPercentage;
    double? batteryMilliVolts;
    double? temperature;
    double? humidity;
    double? pressure;
    final extraSensorData = <String, dynamic>{};

    int fieldCount = 0;
    while (reader.hasRemaining) {
      if (fieldCount > 0 &&
          _isZeroPaddedTail(data, reader.remainingBytesCount)) {
        debugPrint(
          '    Detected zero-padded telemetry tail, stopping parse at position '
          '${data.length - reader.remainingBytesCount}',
        );
        break;
      }

      try {
        fieldCount++;
        debugPrint(
          '    [Field $fieldCount] Position: ${data.length - reader.remainingBytesCount}',
        );

        final channel = reader.readByte();
        debugPrint('      Channel: $channel');

        final type = reader.readByte();
        debugPrint(
          '      Type: $type (0x${type.toRadixString(16).padLeft(2, '0')})',
        );

        switch (type) {
          case MeshCoreConstants.lppDigitalInput:
            final value = reader.readByte();
            debugPrint('      Digital Input: $value');
            extraSensorData['digital_input_$channel'] = value;
            break;

          case MeshCoreConstants.lppDigitalOutput:
            final value = reader.readByte();
            debugPrint('      Digital Output: $value');
            extraSensorData['digital_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppAnalogInput:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Analog Input (raw): $rawValue');
            debugPrint('      Analog Input (volts): ${value}V');
            if (_isBatteryChannel(channel)) {
              batteryMilliVolts = value * 1000;
              batteryPercentage = _calculateBatteryPercentage(value);
              extraSensorData[_sourceChannelKey('battery')] = channel;
              extraSensorData[_sourceChannelKey('voltage')] = channel;
              debugPrint(
                '      → Battery: ${batteryPercentage.toStringAsFixed(1)}% (${batteryMilliVolts.toStringAsFixed(0)}mV)',
              );
            } else {
              extraSensorData['analog_input_$channel'] = value;
            }
            break;

          case MeshCoreConstants.lppAnalogOutput:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Analog Output (raw): $rawValue');
            debugPrint('      Analog Output (volts): ${value}V');
            extraSensorData['analog_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppIlluminanceSensor:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Illuminance: $value lux');
            extraSensorData['illuminance_$channel'] = value;
            break;

          case MeshCoreConstants.lppPresenceSensor:
            final value = reader.readByte();
            debugPrint('      Presence: $value');
            extraSensorData['presence_$channel'] = value;
            break;

          case MeshCoreConstants.lppTemperatureSensor:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Temperature (raw): $rawValue');
            debugPrint('      Temperature: ${value.toStringAsFixed(1)}°C');
            if (channel == _selfTelemetryChannel) {
              temperature = value;
              extraSensorData[_sourceChannelKey('temperature')] = channel;
            } else {
              extraSensorData['temperature_$channel'] = value;
              if (temperature == null) {
                temperature = value;
                extraSensorData[_sourceChannelKey('temperature')] = channel;
              }
            }
            break;

          case MeshCoreConstants.lppHumiditySensor:
            final rawValue = reader.readByte();
            final value = rawValue / 2.0;
            debugPrint('      Humidity (raw): $rawValue');
            debugPrint('      Humidity: ${value.toStringAsFixed(1)}%');
            if (channel == _selfTelemetryChannel) {
              humidity = value;
              extraSensorData[_sourceChannelKey('humidity')] = channel;
            } else {
              extraSensorData['humidity_$channel'] = value;
              if (humidity == null) {
                humidity = value;
                extraSensorData[_sourceChannelKey('humidity')] = channel;
              }
            }
            break;

          case MeshCoreConstants.lppAccelerometer:
            final x = reader.readInt16BE() / 1000.0;
            final y = reader.readInt16BE() / 1000.0;
            final z = reader.readInt16BE() / 1000.0;
            debugPrint('      Accelerometer: x=$x, y=$y, z=$z');
            extraSensorData['accelerometer_$channel'] = {
              'x': x,
              'y': y,
              'z': z,
            };
            break;

          case MeshCoreConstants.lppBarometer:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 10.0;
            debugPrint('      Barometer (raw): $rawValue');
            debugPrint('      Barometer: ${value.toStringAsFixed(1)} hPa');
            if (channel == _selfTelemetryChannel) {
              pressure = value;
              extraSensorData[_sourceChannelKey('pressure')] = channel;
            } else {
              extraSensorData['pressure_$channel'] = value;
              if (pressure == null) {
                pressure = value;
                extraSensorData[_sourceChannelKey('pressure')] = channel;
              }
            }
            break;

          case MeshCoreConstants.lppVoltageSensor:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Voltage (raw): $rawValue');
            debugPrint('      Voltage: ${value}V');
            if (_isBatteryChannel(channel)) {
              batteryMilliVolts = value * 1000;
              batteryPercentage = _calculateBatteryPercentage(value);
              extraSensorData[_sourceChannelKey('battery')] = channel;
              extraSensorData[_sourceChannelKey('voltage')] = channel;
              debugPrint(
                '      → Battery: ${batteryPercentage.toStringAsFixed(1)}% (${batteryMilliVolts.toStringAsFixed(0)}mV)',
              );
            } else {
              extraSensorData['voltage_$channel'] = value;
            }
            break;

          case MeshCoreConstants.lppGyrometer:
            final x = reader.readInt16BE() / 100.0;
            final y = reader.readInt16BE() / 100.0;
            final z = reader.readInt16BE() / 100.0;
            debugPrint('      Gyrometer: x=$x, y=$y, z=$z');
            extraSensorData['gyrometer_$channel'] = {'x': x, 'y': y, 'z': z};
            break;

          case MeshCoreConstants.lppGps:
            // Standard Cayenne LPP GPS format (type 0x88):
            // - Latitude: 3 bytes, signed 24-bit, big-endian, × 10000
            // - Longitude: 3 bytes, signed 24-bit, big-endian, × 10000
            // - Altitude: 3 bytes, signed 24-bit, big-endian, × 100
            // Total: 9 bytes (not the 12 bytes used in MeshCore advertisements!)

            // Read 3-byte signed big-endian integers
            final latBytes = reader.readBytes(3);
            int rawLat = (latBytes[0] << 16) | (latBytes[1] << 8) | latBytes[2];
            // Sign extend from 24-bit to 32-bit
            if (rawLat > 0x7FFFFF) rawLat = rawLat - 0x1000000;

            final lonBytes = reader.readBytes(3);
            int rawLon = (lonBytes[0] << 16) | (lonBytes[1] << 8) | lonBytes[2];
            if (rawLon > 0x7FFFFF) rawLon = rawLon - 0x1000000;

            final altBytes = reader.readBytes(3);
            int rawAlt = (altBytes[0] << 16) | (altBytes[1] << 8) | altBytes[2];
            if (rawAlt > 0x7FFFFF) rawAlt = rawAlt - 0x1000000;

            // Decode: divide by scaling factors
            final lat = rawLat / 10000.0;
            final lon = rawLon / 10000.0;
            final alt = rawAlt / 100.0;

            debugPrint(
              '      GPS Location (raw 24-bit BE): lat=$rawLat (0x${rawLat.toRadixString(16).padLeft(6, '0')}), lon=$rawLon (0x${rawLon.toRadixString(16).padLeft(6, '0')}), alt=$rawAlt (0x${rawAlt.toRadixString(16).padLeft(6, '0')})',
            );
            debugPrint(
              '      GPS Location (decoded): ${lat.toStringAsFixed(6)}°, ${lon.toStringAsFixed(6)}°, altitude=${alt.toStringAsFixed(2)}m',
            );

            // Validate coordinates are in valid range
            if (lat < -90.0 || lat > 90.0) {
              debugPrint('      ⚠️ WARNING: Latitude out of range: $lat°');
            }
            if (lon < -180.0 || lon > 180.0) {
              debugPrint('      ⚠️ WARNING: Longitude out of range: $lon°');
            }

            gpsLocation = LatLng(lat, lon);
            extraSensorData[_sourceChannelKey('gps')] = channel;
            extraSensorData['altitude_$channel'] = alt;
            break;

          case _lppGenericSensor:
            final value = _readUInt32BE(reader).toDouble();
            debugPrint('      Generic Sensor: $value');
            extraSensorData['generic_sensor_$channel'] = value;
            break;

          case _lppCurrent:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 1000.0;
            debugPrint('      Current (raw): $rawValue');
            debugPrint('      Current: ${value}A');
            extraSensorData['current_$channel'] = value;
            break;

          case _lppFrequency:
            final value = _readUInt32BE(reader).toDouble();
            debugPrint('      Frequency: ${value}Hz');
            extraSensorData['frequency_$channel'] = value;
            break;

          case _lppPercentage:
            final value = reader.readByte().toDouble();
            debugPrint('      Percentage: $value%');
            if (_isBatteryChannel(channel)) {
              batteryPercentage = value;
              extraSensorData[_sourceChannelKey('battery')] = channel;
            } else {
              extraSensorData['percentage_$channel'] = value;
            }
            break;

          case _lppAltitude:
            final rawValue = reader.readInt16BE();
            final value = rawValue.toDouble();
            debugPrint('      Altitude: ${value}m');
            extraSensorData['altitude_$channel'] = value;
            break;

          case _lppConcentration:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Concentration: ${value}ppm');
            extraSensorData['concentration_$channel'] = value;
            break;

          case _lppPower:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Power: ${value}W');
            extraSensorData['power_$channel'] = value;
            break;

          case _lppSpeed:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 100.0;
            debugPrint('      Speed: ${value}m/s');
            extraSensorData['speed_$channel'] = value;
            break;

          case _lppDistance:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Distance: ${value}m');
            extraSensorData['distance_$channel'] = value;
            break;

          case _lppEnergy:
            final rawValue = _readUInt32BE(reader);
            final value = rawValue / 1000.0;
            debugPrint('      Energy: ${value}kWh');
            extraSensorData['energy_$channel'] = value;
            break;

          case _lppDirection:
            final value = reader.readUInt16BE().toDouble();
            debugPrint('      Direction: $value°');
            extraSensorData['direction_$channel'] = value;
            break;

          case _lppUnixTime:
            final value = _readUInt32BE(reader);
            debugPrint('      Unix time: $value');
            extraSensorData['unixtime_$channel'] = value;
            break;

          case _lppColour:
            final red = reader.readByte();
            final green = reader.readByte();
            final blue = reader.readByte();
            debugPrint('      Colour: r=$red, g=$green, b=$blue');
            extraSensorData['colour_$channel'] = {
              'r': red,
              'g': green,
              'b': blue,
            };
            break;

          case _lppSwitch:
            final value = reader.readByte();
            debugPrint('      Switch: $value');
            extraSensorData['switch_$channel'] = value;
            break;

          default:
            debugPrint(
              '      ⚠️ Unknown type, skipping remaining ${reader.remainingBytesCount} bytes',
            );
            // Unknown type, skip remaining to avoid parsing errors
            reader.skip(reader.remainingBytesCount);
            break;
        }
      } catch (e) {
        debugPrint('      ❌ Parsing error: $e');
        // If we encounter a parsing error, break and return what we have
        break;
      }
    }

    debugPrint('    Parsed $fieldCount fields');
    debugPrint('  ✅ [CayenneLPP] Parsing complete');
    debugPrint(
      '    GPS: ${gpsLocation != null ? '${gpsLocation.latitude}°, ${gpsLocation.longitude}°' : 'none'}',
    );
    debugPrint(
      '    Battery: ${batteryPercentage != null ? '${batteryPercentage.toStringAsFixed(1)}%' : 'none'}',
    );
    debugPrint(
      '    Temperature: ${temperature != null ? '${temperature.toStringAsFixed(1)}°C' : 'none'}',
    );

    // IMPORTANT: Cayenne LPP format does NOT include a timestamp field.
    // We use DateTime.now() as the timestamp, which represents when the data
    // was RECEIVED/PARSED by the app, NOT when it was collected by the device.
    //
    // This means:
    // - If the device sends cached/old telemetry data, the timestamp will still
    //   show as "recent" (a few seconds ago) because it was just received
    // - The actual age of the telemetry data cannot be determined from the LPP format
    // - Devices may cache telemetry for hours and send it later when requested
    final parseTimestamp = DateTime.now();
    debugPrint(
      '    Timestamp: $parseTimestamp (parse time, NOT device collection time)',
    );

    return ContactTelemetry(
      gpsLocation: gpsLocation,
      batteryPercentage: batteryPercentage,
      batteryMilliVolts: batteryMilliVolts,
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      timestamp: parseTimestamp,
      extraSensorData: extraSensorData.isNotEmpty ? extraSensorData : null,
    );
  }

  /// Calculate battery percentage from voltage (V)
  static double _calculateBatteryPercentage(double voltage) {
    // Standard lithium battery curve: 3.0V = 0%, 4.2V = 100%
    if (voltage <= 3.0) return 0.0;
    if (voltage >= 4.2) return 100.0;
    return ((voltage - 3.0) / 1.2) * 100.0;
  }

  static bool _isBatteryChannel(int channel) =>
      channel == 0 || channel == _selfTelemetryChannel;

  static int _readUInt32BE(BufferReader reader) {
    final bytes = reader.readBytes(4);
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  static String _sourceChannelKey(String fieldKey) => '__source_channel:$fieldKey';

  static bool _isZeroPaddedTail(Uint8List data, int remainingBytes) {
    final start = data.length - remainingBytes;
    for (int i = start; i < data.length; i++) {
      if (data[i] != 0) return false;
    }
    return remainingBytes > 0;
  }

  /// Create Cayenne LPP data for GPS location
  /// Standard Cayenne LPP GPS format (type 0x88):
  /// - Latitude: 3 bytes, signed 24-bit, big-endian, × 10000
  /// - Longitude: 3 bytes, signed 24-bit, big-endian, × 10000
  /// - Altitude: 3 bytes, signed 24-bit, big-endian, × 100
  static Uint8List createGpsData({
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    int channel = 0,
  }) {
    final buffer = <int>[];

    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppGps);

    // Latitude (signed 24-bit BE, 3 bytes, 0.0001° precision)
    int lat = (latitude * 10000).round();
    // Handle negative values (two's complement for 24-bit)
    if (lat < 0) lat = lat + 0x1000000;
    buffer.add((lat >> 16) & 0xFF); // Byte 0 (MSB)
    buffer.add((lat >> 8) & 0xFF); // Byte 1
    buffer.add(lat & 0xFF); // Byte 2 (LSB)

    // Longitude (signed 24-bit BE, 3 bytes, 0.0001° precision)
    int lon = (longitude * 10000).round();
    if (lon < 0) lon = lon + 0x1000000;
    buffer.add((lon >> 16) & 0xFF); // Byte 0 (MSB)
    buffer.add((lon >> 8) & 0xFF); // Byte 1
    buffer.add(lon & 0xFF); // Byte 2 (LSB)

    // Altitude (signed 24-bit BE, 3 bytes, 0.01m precision)
    int alt = (altitude * 100).round();
    if (alt < 0) alt = alt + 0x1000000;
    buffer.add((alt >> 16) & 0xFF); // Byte 0 (MSB)
    buffer.add((alt >> 8) & 0xFF); // Byte 1
    buffer.add(alt & 0xFF); // Byte 2 (LSB)

    return Uint8List.fromList(buffer);
  }

  /// Create Cayenne LPP data for temperature
  static Uint8List createTemperatureData(double celsius, {int channel = 0}) {
    final buffer = <int>[];
    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppTemperatureSensor);

    final temp = (celsius * 10).round();
    buffer.add((temp >> 8) & 0xFF);
    buffer.add(temp & 0xFF);

    return Uint8List.fromList(buffer);
  }

  /// Create Cayenne LPP data for battery voltage
  static Uint8List createBatteryData(double voltage, {int channel = 0}) {
    final buffer = <int>[];
    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppAnalogInput);

    final volts = (voltage * 100).round();
    buffer.add((volts >> 8) & 0xFF);
    buffer.add(volts & 0xFF);

    return Uint8List.fromList(buffer);
  }
}
