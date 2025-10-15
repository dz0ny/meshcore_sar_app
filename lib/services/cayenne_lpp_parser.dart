import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import '../models/contact_telemetry.dart';
import 'buffer_reader.dart';
import 'meshcore_constants.dart';

/// Cayenne LPP (Low Power Payload) data parser
/// Used for decoding telemetry sensor data from MeshCore devices
class CayenneLppParser {
  /// Parse Cayenne LPP data into ContactTelemetry
  static ContactTelemetry parse(Uint8List data) {
    print('  [CayenneLPP] Parsing LPP data...');
    print('    Data length: ${data.length} bytes');
    print('    Data (hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

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
      try {
        fieldCount++;
        print('    [Field $fieldCount] Position: ${data.length - reader.remainingBytesCount}');

        final channel = reader.readByte();
        print('      Channel: $channel');

        final type = reader.readByte();
        print('      Type: $type (0x${type.toRadixString(16).padLeft(2, '0')})');

        switch (type) {
          case MeshCoreConstants.lppDigitalInput:
            final value = reader.readByte();
            print('      Digital Input: $value');
            extraSensorData['digital_input_$channel'] = value;
            break;

          case MeshCoreConstants.lppDigitalOutput:
            final value = reader.readByte();
            print('      Digital Output: $value');
            extraSensorData['digital_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppAnalogInput:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 100.0;
            print('      Analog Input (raw): $rawValue');
            print('      Analog Input (volts): ${value}V');
            extraSensorData['analog_input_$channel'] = value;
            // If this is a battery reading
            if (channel == 0 || channel == 1) {
              batteryMilliVolts = value * 1000;
              batteryPercentage = _calculateBatteryPercentage(value);
              print('      → Battery: ${batteryPercentage?.toStringAsFixed(1)}% (${batteryMilliVolts?.toStringAsFixed(0)}mV)');
            }
            break;

          case MeshCoreConstants.lppAnalogOutput:
            final rawValue = reader.readInt16BE();
            final value = rawValue / 100.0;
            print('      Analog Output (raw): $rawValue');
            print('      Analog Output (volts): ${value}V');
            extraSensorData['analog_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppIlluminanceSensor:
            final value = reader.readUInt16BE();
            print('      Illuminance: $value lux');
            extraSensorData['illuminance_$channel'] = value;
            break;

          case MeshCoreConstants.lppPresenceSensor:
            final value = reader.readByte();
            print('      Presence: $value');
            extraSensorData['presence_$channel'] = value;
            break;

          case MeshCoreConstants.lppTemperatureSensor:
            final rawValue = reader.readInt16BE();
            temperature = rawValue / 10.0;
            print('      Temperature (raw): $rawValue');
            print('      Temperature: ${temperature?.toStringAsFixed(1)}°C');
            break;

          case MeshCoreConstants.lppHumiditySensor:
            final rawValue = reader.readByte();
            humidity = rawValue / 2.0;
            print('      Humidity (raw): $rawValue');
            print('      Humidity: ${humidity?.toStringAsFixed(1)}%');
            break;

          case MeshCoreConstants.lppAccelerometer:
            final x = reader.readInt16BE() / 1000.0;
            final y = reader.readInt16BE() / 1000.0;
            final z = reader.readInt16BE() / 1000.0;
            print('      Accelerometer: x=$x, y=$y, z=$z');
            extraSensorData['accelerometer_$channel'] = {'x': x, 'y': y, 'z': z};
            break;

          case MeshCoreConstants.lppBarometer:
            final rawValue = reader.readUInt16BE();
            pressure = rawValue / 10.0;
            print('      Barometer (raw): $rawValue');
            print('      Barometer: ${pressure?.toStringAsFixed(1)} hPa');
            break;

          case MeshCoreConstants.lppVoltageSensor:
            final rawValue = reader.readUInt16BE();
            final value = rawValue / 100.0;
            print('      Voltage (raw): $rawValue');
            print('      Voltage: ${value}V');
            // Treat voltage sensor as battery reading
            batteryMilliVolts = value * 1000;
            batteryPercentage = _calculateBatteryPercentage(value);
            print('      → Battery: ${batteryPercentage?.toStringAsFixed(1)}% (${batteryMilliVolts?.toStringAsFixed(0)}mV)');
            break;

          case MeshCoreConstants.lppGyrometer:
            final x = reader.readInt16BE() / 100.0;
            final y = reader.readInt16BE() / 100.0;
            final z = reader.readInt16BE() / 100.0;
            print('      Gyrometer: x=$x, y=$y, z=$z');
            extraSensorData['gyrometer_$channel'] = {'x': x, 'y': y, 'z': z};
            break;

          case MeshCoreConstants.lppGps:
            final rawLat = reader.readInt32LE();
            final rawLon = reader.readInt32LE();
            final rawAlt = reader.readInt32LE();
            final lat = rawLat / 1000000.0;
            final lon = rawLon / 1000000.0;
            final alt = rawAlt / 100.0;
            print('      GPS Location (raw): lat=$rawLat, lon=$rawLon, alt=$rawAlt');
            print('      GPS Location: ${lat}°, ${lon}°, altitude=${alt}m');
            gpsLocation = LatLng(lat, lon);
            extraSensorData['altitude_$channel'] = alt;
            break;

          default:
            print('      ⚠️ Unknown type, skipping remaining ${reader.remainingBytesCount} bytes');
            // Unknown type, skip remaining to avoid parsing errors
            reader.skip(reader.remainingBytesCount);
            break;
        }
      } catch (e) {
        print('      ❌ Parsing error: $e');
        // If we encounter a parsing error, break and return what we have
        break;
      }
    }

    print('    Parsed $fieldCount fields');
    print('  ✅ [CayenneLPP] Parsing complete');
    print('    GPS: ${gpsLocation != null ? '${gpsLocation.latitude}°, ${gpsLocation.longitude}°' : 'none'}');
    print('    Battery: ${batteryPercentage != null ? '${batteryPercentage.toStringAsFixed(1)}%' : 'none'}');
    print('    Temperature: ${temperature != null ? '${temperature.toStringAsFixed(1)}°C' : 'none'}');

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
    print('    Timestamp: $parseTimestamp (parse time, NOT device collection time)');

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

  /// Create Cayenne LPP data for GPS location
  static Uint8List createGpsData({
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    int channel = 0,
  }) {
    final buffer = <int>[];

    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppGps);

    // Latitude (3 bytes, signed, 0.0001° precision)
    final lat = (latitude * 10000).round();
    buffer.add((lat >> 16) & 0xFF);
    buffer.add((lat >> 8) & 0xFF);
    buffer.add(lat & 0xFF);

    // Longitude (3 bytes, signed, 0.0001° precision)
    final lon = (longitude * 10000).round();
    buffer.add((lon >> 16) & 0xFF);
    buffer.add((lon >> 8) & 0xFF);
    buffer.add(lon & 0xFF);

    // Altitude (3 bytes, signed, 0.01m precision)
    final alt = (altitude * 100).round();
    buffer.add((alt >> 16) & 0xFF);
    buffer.add((alt >> 8) & 0xFF);
    buffer.add(alt & 0xFF);

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
