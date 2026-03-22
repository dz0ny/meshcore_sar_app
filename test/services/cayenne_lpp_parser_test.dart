import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/services/cayenne_lpp_parser.dart';
import 'package:meshcore_client/meshcore_client.dart';

void main() {
  group('CayenneLppParser - GPS Codec Tests', () {
    test('GPS encoding uses correct 3-byte signed BE format', () {
      // Test coordinates (Ljubljana, Slovenia)
      const double lat = 46.0569;
      const double lon = 14.5058;
      const double alt = 295.0;

      final encoded = CayenneLppParser.createGpsData(
        latitude: lat,
        longitude: lon,
        altitude: alt,
        channel: 0,
      );

      // Expected format (Standard Cayenne LPP):
      // [0] = channel (0)
      // [1] = type (136 = 0x88 = lppGps)
      // [2-4] = lat as 24-bit signed BE
      // [5-7] = lon as 24-bit signed BE
      // [8-10] = alt as 24-bit signed BE
      expect(encoded.length, equals(11));
      expect(encoded[0], equals(0)); // channel
      expect(encoded[1], equals(MeshCoreConstants.lppGps)); // type 0x88

      // Verify big-endian encoding (3 bytes each)
      final latEncoded = (encoded[2] << 16) | (encoded[3] << 8) | encoded[4];
      final lonEncoded = (encoded[5] << 16) | (encoded[6] << 8) | encoded[7];
      final altEncoded = (encoded[8] << 16) | (encoded[9] << 8) | encoded[10];

      expect(latEncoded, equals(460569)); // 46.0569 * 10000
      expect(lonEncoded, equals(145058)); // 14.5058 * 10000
      expect(altEncoded, equals(29500)); // 295.0 * 100
    });

    test('GPS decoding uses correct 3-byte BE format and divisor', () {
      // Create raw GPS telemetry packet (standard Cayenne LPP format)
      final buffer = <int>[];
      buffer.add(0); // channel
      buffer.add(MeshCoreConstants.lppGps); // type 0x88

      // Lat: 46.0569 * 10000 = 460569 = 0x070719
      buffer.add(0x07); // MSB
      buffer.add(0x07);
      buffer.add(0x19); // LSB

      // Lon: 14.5058 * 10000 = 145058 = 0x0236A2
      buffer.add(0x02);
      buffer.add(0x36);
      buffer.add(0xA2);

      // Alt: 295.0 * 100 = 29500 = 0x7 33C
      buffer.add(0x00);
      buffer.add(0x73);
      buffer.add(0x3C);

      final telemetry = CayenneLppParser.parse(Uint8List.fromList(buffer));

      expect(telemetry.gpsLocation, isNotNull);
      expect(telemetry.gpsLocation!.latitude, closeTo(46.0569, 0.0001));
      expect(telemetry.gpsLocation!.longitude, closeTo(14.5058, 0.0001));

      // Verify altitude is stored in extra data
      expect(telemetry.extraSensorData, isNotNull);
      expect(telemetry.extraSensorData!['altitude_0'], closeTo(295.0, 0.01));
    });

    test('GPS round-trip encoding/decoding maintains precision', () {
      // Test various coordinates
      final testCases = [
        LatLng(46.0569, 14.5058), // Ljubljana
        LatLng(37.7749, -122.4194), // San Francisco
        LatLng(-33.8688, 151.2093), // Sydney
        LatLng(0.0, 0.0), // Null Island
        LatLng(89.9999, 179.9999), // Near max
        LatLng(-89.9999, -179.9999), // Near min
      ];

      for (final coords in testCases) {
        final encoded = CayenneLppParser.createGpsData(
          latitude: coords.latitude,
          longitude: coords.longitude,
          altitude: 100.0,
        );

        final decoded = CayenneLppParser.parse(encoded);

        expect(
          decoded.gpsLocation,
          isNotNull,
          reason: 'Failed to decode: $coords',
        );
        expect(
          decoded.gpsLocation!.latitude,
          closeTo(coords.latitude, 0.0001),
          reason: 'Latitude mismatch for $coords',
        );
        expect(
          decoded.gpsLocation!.longitude,
          closeTo(coords.longitude, 0.0001),
          reason: 'Longitude mismatch for $coords',
        );
      }
    });

    test('GPS decoding validates coordinate ranges', () {
      // This test documents that coordinates are decoded correctly
      // and any validation warnings are logged (not enforced)

      // Valid coordinates should decode without issue
      final validBuffer = <int>[];
      validBuffer.add(0); // channel
      validBuffer.add(MeshCoreConstants.lppGps);

      // Lat: 45.0 * 10000 = 450000 = 0x06DDD0 (3 bytes BE)
      validBuffer.addAll([0x06, 0xDD, 0xD0]);
      // Lon: 10.0 * 10000 = 100000 = 0x0186A0 (3 bytes BE)
      validBuffer.addAll([0x01, 0x86, 0xA0]);
      // Alt: 0 (3 bytes BE)
      validBuffer.addAll([0x00, 0x00, 0x00]);

      final telemetry = CayenneLppParser.parse(Uint8List.fromList(validBuffer));

      expect(telemetry.gpsLocation, isNotNull);
      expect(telemetry.gpsLocation!.latitude, closeTo(45.0, 0.0001));
      expect(telemetry.gpsLocation!.longitude, closeTo(10.0, 0.0001));
    });

    test('GPS encoding handles negative coordinates correctly', () {
      const lat = -33.8688;
      const lon = -151.2093;

      final encoded = CayenneLppParser.createGpsData(
        latitude: lat,
        longitude: lon,
      );

      // Verify 3-byte signed encoding
      // Lat: -33.8688 * 10000 = -338688
      // In 24-bit two's complement: -338688 + 0x1000000 = 16438528 = 0xFAD500
      final latEncoded = (encoded[2] << 16) | (encoded[3] << 8) | encoded[4];
      // Lon: -151.2093 * 10000 = -1512093
      // In 24-bit two's complement: -1512093 + 0x1000000 = 15265123 = 0xE8ED63
      final lonEncoded = (encoded[5] << 16) | (encoded[6] << 8) | encoded[7];

      expect(latEncoded, equals(0xFAD500)); // Verify two's complement
      expect(lonEncoded, equals(0xE8ED63));

      // Verify decoding
      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.gpsLocation!.latitude, closeTo(lat, 0.0001));
      expect(decoded.gpsLocation!.longitude, closeTo(lon, 0.0001));
    });

    test('GPS encoding with altitude uses correct precision', () {
      final encoded = CayenneLppParser.createGpsData(
        latitude: 0.0,
        longitude: 0.0,
        altitude: 1234.56,
      );

      // Altitude is at bytes 8-10 (3 bytes BE)
      // Alt: 1234.56 * 100 = 123456 = 0x01E240
      final altEncoded = (encoded[8] << 16) | (encoded[9] << 8) | encoded[10];

      // Altitude precision is 0.01m (divide by 100)
      expect(altEncoded, equals(123456)); // 1234.56 * 100

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.extraSensorData!['altitude_0'], closeTo(1234.56, 0.01));
    });

    test('GPS encoding supports custom channel', () {
      final encoded = CayenneLppParser.createGpsData(
        latitude: 1.0,
        longitude: 2.0,
        channel: 5,
      );

      expect(encoded[0], equals(5)); // channel

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.extraSensorData!['altitude_5'], isNotNull);
    });

    test(
      'OLD BUG: Using 4-byte LE instead of 3-byte BE caused wrong coords',
      () {
        // This test documents the bug that was fixed
        // The old code used 4-byte int32 LE (MeshCore advertisement format)
        // instead of 3-byte signed BE (standard Cayenne LPP format)

        // Real data from device:
        // Hex: 06 f7 08 02 38 0e 01 2c 46
        final realData = <int>[
          0x00, 0x88, // channel 0, type GPS
          0x06, 0xf7, 0x08, // lat (3 bytes BE)
          0x02, 0x38, 0x0e, // lon (3 bytes BE)
          0x01, 0x2c, 0x46, // alt (3 bytes BE)
        ];

        // CORRECT decoding (3-byte BE):
        final correctLat =
            ((0x06 << 16) | (0xf7 << 8) | 0x08) / 10000.0; // 45.6456°
        final correctLon =
            ((0x02 << 16) | (0x38 << 8) | 0x0e) / 10000.0; // 14.5422°

        // OLD BUGGY decoding (4-byte LE - reads wrong bytes!):
        // Would read: lat=06f70802, lon=38010e2c (completely wrong)
        final buggyLatRaw = 0x02 | (0x08 << 8) | (0xf7 << 16) | (0x06 << 24);
        final buggyLat = buggyLatRaw / 10000.0; // 3414.1958° (out of range!)

        // Verify current implementation decodes correctly
        final telemetry = CayenneLppParser.parse(Uint8List.fromList(realData));
        expect(telemetry.gpsLocation, isNotNull);
        expect(telemetry.gpsLocation!.latitude, closeTo(correctLat, 0.0001));
        expect(telemetry.gpsLocation!.longitude, closeTo(correctLon, 0.0001));

        // Verify it doesn't produce the buggy values
        expect(telemetry.gpsLocation!.latitude, isNot(equals(buggyLat)));
        expect(telemetry.gpsLocation!.latitude, lessThan(90.0)); // Valid range
        expect(telemetry.gpsLocation!.latitude, greaterThan(-90.0));
      },
    );
  });

  group('CayenneLppParser - Other Sensor Tests', () {
    test('temperature encoding and decoding', () {
      const tempCelsius = 23.5;

      final encoded = CayenneLppParser.createTemperatureData(
        tempCelsius,
        channel: 1,
      );

      expect(encoded.length, equals(4)); // channel + type + 2 bytes
      expect(encoded[0], equals(1)); // channel
      expect(encoded[1], equals(MeshCoreConstants.lppTemperatureSensor));

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.temperature, closeTo(tempCelsius, 0.1));
    });

    test('temperature handles negative values', () {
      const tempCelsius = -15.3;

      final encoded = CayenneLppParser.createTemperatureData(tempCelsius);
      final decoded = CayenneLppParser.parse(encoded);

      expect(decoded.temperature, closeTo(tempCelsius, 0.1));
    });

    test('battery voltage encoding and decoding', () {
      const voltage = 3.85;

      final encoded = CayenneLppParser.createBatteryData(voltage);

      expect(encoded.length, equals(4));
      expect(encoded[1], equals(MeshCoreConstants.lppAnalogInput));

      final decoded = CayenneLppParser.parse(encoded);

      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
      expect(decoded.batteryPercentage, greaterThan(0));
      expect(decoded.batteryPercentage, lessThanOrEqualTo(100));
    });

    test('battery percentage calculation', () {
      // Test battery curve: 3.0V = 0%, 4.2V = 100%
      final testCases = {
        2.8: 0.0, // Below minimum
        3.0: 0.0, // Minimum
        3.6: 50.0, // Middle
        4.2: 100.0, // Maximum
        4.5: 100.0, // Above maximum
      };

      for (final entry in testCases.entries) {
        final voltage = entry.key;
        final expectedPercent = entry.value;

        final encoded = CayenneLppParser.createBatteryData(voltage);
        final decoded = CayenneLppParser.parse(encoded);

        expect(
          decoded.batteryPercentage,
          closeTo(expectedPercent, 1),
          reason: 'Battery ${voltage}V should be ~$expectedPercent%',
        );
      }
    });

    test('analog input is recognized as battery', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0); // channel 0
      buffer.setUint8(1, MeshCoreConstants.lppAnalogInput);
      buffer.setInt16(2, 385, Endian.big); // 3.85V * 100

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.batteryPercentage, isNotNull);
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('voltage sensor is recognized as battery', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppVoltageSensor);
      buffer.setUint16(2, 385, Endian.big); // 3.85V * 100

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.batteryPercentage, isNotNull);
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('humidity sensor decoding', () {
      final buffer = ByteData(3);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppHumiditySensor);
      buffer.setUint8(2, 130); // 65% humidity (130 / 2)

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.humidity, equals(65.0));
    });

    test('barometer sensor decoding', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppBarometer);
      buffer.setUint16(2, 10132, Endian.big); // 1013.2 hPa * 10

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.pressure, closeTo(1013.2, 0.1));
    });

    test('accelerometer sensor stores in extra data', () {
      final buffer = ByteData(8);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppAccelerometer);
      buffer.setInt16(2, 1000, Endian.big); // x: 1.0 g
      buffer.setInt16(4, -500, Endian.big); // y: -0.5 g
      buffer.setInt16(6, 2000, Endian.big); // z: 2.0 g

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.extraSensorData, isNotNull);
      final accel = decoded.extraSensorData!['accelerometer_0'];
      expect(accel['x'], closeTo(1.0, 0.001));
      expect(accel['y'], closeTo(-0.5, 0.001));
      expect(accel['z'], closeTo(2.0, 0.001));
    });

    test('extended MeshCore LPP types decode to structured extra data', () {
      const lppGenericSensor = 100;
      const lppCurrent = 117;
      const lppFrequency = 118;
      const lppAltitude = 121;
      const lppConcentration = 125;
      const lppPower = 128;
      const lppSpeed = 129;
      const lppDistance = 130;
      const lppEnergy = 131;
      const lppDirection = 132;
      const lppUnixTime = 133;
      const lppColour = 135;
      const lppGust = 137;
      const lppDewPoint = 138;
      const lppRain = 139;
      const lppSwitch = 142;

      final payload = Uint8List.fromList([
        2, lppGenericSensor, 0x00, 0x00, 0x01, 0x2C, // 300
        3, lppCurrent, 0x00, 0x0F, // 0.015 A
        4, lppFrequency, 0x00, 0x00, 0x03, 0xE8, // 1000 Hz
        5, lppAltitude, 0x01, 0xF4, // 500 m
        6, lppConcentration, 0x01, 0x9F, // 415 ppm
        7, lppPower, 0x00, 0xFA, // 250 W
        8, lppSpeed, 0x04, 0xD2, // 12.34 m/s
        9, lppDistance, 0x00, 0x00, 0x04, 0xD2, // 1.234 m
        10, lppEnergy, 0x00, 0x00, 0x04, 0xD2, // 1.234 kWh
        11, lppDirection, 0x01, 0x0E, // 270 deg
        12, lppUnixTime, 0x65, 0xF0, 0x00, 0x00, // 1710221312
        13, lppColour, 0xFF, 0x80, 0x40, // #FF8040
        15, lppGust, 0x01, 0x72, // 3.70 m/s
        16, lppDewPoint, 0x00, 0x14, // 2.0 C
        17, lppRain, 0x00, 0x7B, // 12.3 mm
        14, lppSwitch, 0x01, // on
      ]);

      final decoded = CayenneLppParser.parse(payload);

      expect(decoded.extraSensorData, isNotNull);
      expect(decoded.extraSensorData!['generic_sensor_2'], equals(300.0));
      expect(decoded.extraSensorData!['current_3'], closeTo(0.015, 0.0001));
      expect(decoded.extraSensorData!['frequency_4'], equals(1000.0));
      expect(decoded.extraSensorData!['altitude_5'], equals(500.0));
      expect(decoded.extraSensorData!['concentration_6'], equals(415.0));
      expect(decoded.extraSensorData!['power_7'], equals(250.0));
      expect(decoded.extraSensorData!['speed_8'], closeTo(12.34, 0.001));
      expect(decoded.extraSensorData!['distance_9'], closeTo(1.234, 0.0001));
      expect(decoded.extraSensorData!['energy_10'], closeTo(1.234, 0.0001));
      expect(decoded.extraSensorData!['direction_11'], equals(270.0));
      expect(decoded.extraSensorData!['unixtime_12'], equals(1710227456));
      expect(
        decoded.extraSensorData!['colour_13'],
        equals({'r': 255, 'g': 128, 'b': 64}),
      );
      expect(decoded.extraSensorData!['gust_15'], closeTo(3.7, 0.001));
      expect(decoded.extraSensorData!['dew_16'], closeTo(2.0, 0.001));
      expect(decoded.extraSensorData!['rain_17'], closeTo(12.3, 0.001));
      expect(decoded.extraSensorData!['switch_14'], equals(1));
    });

    test('new MeshCore custom telemetry types decode without truncation', () {
      const lppBinaryMoisture = 157;
      const lppButtonEvent = 171;
      const lppDimmer = 172;
      const lppUv = 173;
      const lppPm25 = 175;
      const lppConductivity = 180;
      const lppDuration = 182;
      const lppSignedSpeed = 191;
      const lppSignedPower = 192;
      const lppSignedCurrent = 193;

      final payload = Uint8List.fromList([
        2, lppBinaryMoisture, 0x01,
        3, lppButtonEvent, 0x04,
        4, lppDimmer, 0xFB, // -5
        5, lppUv, 0x0A, // 1.0
        6, lppPm25, 0x00, 0x0C, // 12
        7, lppConductivity, 0x01, 0xF4, // 500
        8, lppDuration, 0x00, 0x00, 0x13, 0x88, // 5.0 s
        9, lppSignedSpeed, 0xFF, 0xE1, 0x7B, 0x80, // -2.0 m/s
        10, lppSignedPower, 0xFF, 0xFF, 0xFC, 0x18, // -10.0 W
        11, lppSignedCurrent, 0xFF, 0xFF, 0xFC, 0x18, // -1.0 A
        12, MeshCoreConstants.lppTemperatureSensor, 0x00, 0x76, // 11.8 C
      ]);

      final decoded = CayenneLppParser.parse(payload);

      expect(decoded.extraSensorData!['binary_moisture_2'], equals(1));
      expect(decoded.extraSensorData!['button_event_3'], equals(4));
      expect(decoded.extraSensorData!['dimmer_4'], equals(-5));
      expect(decoded.extraSensorData!['uv_5'], closeTo(1.0, 0.001));
      expect(decoded.extraSensorData!['pm25_6'], equals(12.0));
      expect(decoded.extraSensorData!['conductivity_7'], equals(500.0));
      expect(decoded.extraSensorData!['duration_8'], closeTo(5.0, 0.001));
      expect(decoded.extraSensorData!['signed_speed_9'], closeTo(-2.0, 0.001));
      expect(
        decoded.extraSensorData!['signed_power_10'],
        closeTo(-10.0, 0.001),
      );
      expect(
        decoded.extraSensorData!['signed_current_11'],
        closeTo(-1.0, 0.001),
      );
      expect(decoded.temperature, closeTo(11.8, 0.1));
    });

    test(
      'percentage battery and non-battery voltage channels are preserved separately',
      () {
        const lppPercentage = 120;

        final payload = Uint8List.fromList([
          1, lppPercentage, 66, // battery %
          2, MeshCoreConstants.lppVoltageSensor, 0x01, 0x81, // 3.85 V
          2, MeshCoreConstants.lppTemperatureSensor, 0x00, 0xEB, // 23.5 C
        ]);

        final decoded = CayenneLppParser.parse(payload);

        expect(decoded.batteryPercentage, equals(66.0));
        expect(decoded.extraSensorData!['voltage_2'], closeTo(3.85, 0.001));
        expect(decoded.temperature, closeTo(23.5, 0.1));
        expect(decoded.extraSensorData!['temperature_2'], closeTo(23.5, 0.1));
      },
    );

    test('weather station payload keeps generic percentage and does not invent battery from ch1 voltage', () {
      final payload = Uint8List.fromList([
        0x01, 0x74, 0x00, 0x00,
        0x02, 0x78, 0x64,
        0x02, 0x73, 0x24, 0x32,
        0x02, 0x65, 0x5A, 0x50,
        0x02, 0x8A, 0xFF, 0xE4,
        0x02, 0x74, 0x01, 0xE0,
        0x02, 0x9D, 0x00,
        0x02, 0x68, 0x76,
        0x02, 0x81, 0x01, 0x4A,
        0x02, 0x89, 0x01, 0xB8,
        0x02, 0x67, 0x00, 0x2D,
        0x02, 0xAD, 0x0A,
        0x02, 0x84, 0x00, 0x56,
        0x02, 0x8B, 0x00, 0xB3,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00
      ]);

      final decoded = CayenneLppParser.parse(payload);

      expect(decoded.batteryPercentage, isNull);
      expect(decoded.batteryMilliVolts, isNull);
      expect(decoded.temperature, closeTo(4.5, 0.1));
      expect(decoded.humidity, closeTo(59.0, 0.1));
      expect(decoded.pressure, closeTo(926.6, 0.1));
      expect(decoded.extraSensorData!['voltage_1'], closeTo(0.0, 0.001));
      expect(decoded.extraSensorData!['percentage_2'], equals(100.0));
      expect(decoded.extraSensorData!['uv_2'], equals(1.0));
      expect(decoded.extraSensorData!['rain_2'], closeTo(17.9, 0.1));
      expect(decoded.extraSensorData!.containsKey('__source_channel:battery'), isFalse);
    });

    test('unknown sensor type is skipped gracefully', () {
      final buffer = ByteData(5);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, 255); // Unknown type
      buffer.setUint8(2, 1);
      buffer.setUint8(3, 2);
      buffer.setUint8(4, 3);

      // Should not throw, just skip unknown data
      expect(
        () => CayenneLppParser.parse(buffer.buffer.asUint8List()),
        returnsNormally,
      );
    });

    test('multiple sensors in single packet', () {
      // Create a combined packet with multiple sensors
      final buffer = <int>[];

      // GPS (channel 2) - use channel 2 to avoid battery auto-detection
      buffer.add(2); // channel
      buffer.add(MeshCoreConstants.lppGps);
      // Lat: 46.0569 * 10000 = 460569 = 0x070719 (3 bytes BE)
      buffer.addAll([0x07, 0x07, 0x19]);
      // Lon: 14.5058 * 10000 = 145058 = 0x0236A2 (3 bytes BE)
      buffer.addAll([0x02, 0x36, 0xA2]);
      // Alt: 0 (3 bytes BE)
      buffer.addAll([0x00, 0x00, 0x00]);

      // Temperature (channel 3)
      buffer.add(3); // channel
      buffer.add(MeshCoreConstants.lppTemperatureSensor);
      buffer.add(0x00); // 23.5°C * 10 = 235 (2 bytes BE)
      buffer.add(0xEB);

      // Battery (channel 0 - required for battery detection)
      buffer.add(0); // channel
      buffer.add(MeshCoreConstants.lppAnalogInput);
      buffer.add(0x01); // 3.85V * 100 = 385 (2 bytes BE)
      buffer.add(0x81);

      final decoded = CayenneLppParser.parse(Uint8List.fromList(buffer));

      // All sensors should be decoded
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.gpsLocation!.latitude, closeTo(46.0569, 0.0001));
      expect(decoded.temperature, closeTo(23.5, 0.1));
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('stops parsing at zero-padded telemetry tail', () {
      final payload = Uint8List.fromList([
        0x01, 0x74, 0x01, 0x5F, // voltage 3.51V
        0x01, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00,
      ]);

      final decoded = CayenneLppParser.parse(payload);

      expect(decoded.batteryMilliVolts, closeTo(3510, 1));
      expect(decoded.batteryPercentage, closeTo(42.5, 0.1));
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.gpsLocation!.latitude, 0.0);
      expect(decoded.gpsLocation!.longitude, 0.0);
      expect(decoded.extraSensorData?['digital_input_0'], isNull);
    });

    test('empty data returns empty telemetry', () {
      final empty = Uint8List(0);
      final decoded = CayenneLppParser.parse(empty);

      expect(decoded.gpsLocation, isNull);
      expect(decoded.batteryPercentage, isNull);
      expect(decoded.temperature, isNull);
      expect(decoded.extraSensorData, isNull);
      expect(decoded.timestamp, isNotNull); // Timestamp is always set
    });

    test('timestamp is set to parse time', () {
      final before = DateTime.now();
      final data = CayenneLppParser.createTemperatureData(20.0);
      final decoded = CayenneLppParser.parse(data);
      final after = DateTime.now();

      expect(
        decoded.timestamp.isAfter(before) ||
            decoded.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        decoded.timestamp.isBefore(after) ||
            decoded.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('CayenneLppParser - ContactTelemetry Properties', () {
    test('isRecent returns true for fresh telemetry', () {
      final data = CayenneLppParser.createTemperatureData(20.0);
      final telemetry = CayenneLppParser.parse(data);

      expect(telemetry.isRecent, isTrue);
    });

    test('battery status helpers work correctly', () {
      final lowBattery = ContactTelemetry(
        batteryPercentage: 15.0,
        timestamp: DateTime.now(),
      );
      expect(lowBattery.isLowBattery, isTrue);
      expect(lowBattery.batteryStatus, equals('low'));

      final criticalBattery = ContactTelemetry(
        batteryPercentage: 5.0,
        timestamp: DateTime.now(),
      );
      expect(criticalBattery.isCriticalBattery, isTrue);

      final goodBattery = ContactTelemetry(
        batteryPercentage: 75.0,
        timestamp: DateTime.now(),
      );
      expect(goodBattery.isLowBattery, isFalse);
      expect(goodBattery.batteryStatus, equals('good'));
    });

    test('copyWith creates modified copy', () {
      final original = ContactTelemetry(
        gpsLocation: LatLng(1, 2),
        batteryPercentage: 50.0,
        temperature: 20.0,
        timestamp: DateTime.now(),
      );

      final modified = original.copyWith(temperature: 25.0);

      expect(modified.temperature, equals(25.0));
      expect(modified.batteryPercentage, equals(50.0)); // Unchanged
      expect(modified.gpsLocation, equals(original.gpsLocation)); // Unchanged
    });

    test('toString provides readable output', () {
      final telemetry = ContactTelemetry(
        gpsLocation: LatLng(46.0569, 14.5058),
        batteryPercentage: 75.0,
        temperature: 23.5,
        timestamp: DateTime.now(),
      );

      final str = telemetry.toString();
      expect(str, contains('ContactTelemetry'));
      expect(str, contains('46.0569'));
      expect(str, contains('75'));
      expect(str, contains('23.5'));
    });
  });
}
