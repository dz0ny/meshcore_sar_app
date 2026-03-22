import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/services/bthome_met_history.dart';

void main() {
  test('parses a valid BTHome MET history response', () {
    final parsed = BTHomeMetHistoryParser.parse('1,0,4,11.2,11.8,12.1,12.3');

    expect(parsed.measurement, BTHomeMetMeasurement.temperature);
    expect(parsed.page, 0);
    expect(parsed.values, <double>[11.2, 11.8, 12.1, 12.3]);
    expect(parsed.latest, 12.3);
    expect(parsed.minimum, 11.2);
    expect(parsed.maximum, 12.3);
  });

  test('rejects malformed BTHome MET history counts', () {
    expect(
      () => BTHomeMetHistoryParser.parse('2,0,3,41,42'),
      throwsA(isA<BTHomeMetHistoryFormatException>()),
    );
  });

  test('detects available BTHome MET measurements from telemetry', () {
    final contact = Contact(
      publicKey: Uint8List(32),
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: 'WX',
      lastAdvert: 0,
      advLat: 0,
      advLon: 0,
      lastMod: 0,
      telemetry: ContactTelemetry(
        temperature: 20.1,
        humidity: 52,
        extraSensorData: const {
          'generic_sensor_1': 1,
          'speed_2': 3.1,
          'gust_2': 4.8,
          'rain_2': 12.3,
        },
        timestamp: DateTime(2026, 3, 21, 12),
      ),
    );

    expect(bTHomeMetMeasurementsForContact(contact), <BTHomeMetMeasurement>[
      BTHomeMetMeasurement.temperature,
      BTHomeMetMeasurement.humidity,
      BTHomeMetMeasurement.windSpeed,
      BTHomeMetMeasurement.gust,
      BTHomeMetMeasurement.rain,
    ]);
    expect(supportsBTHomeMetHistory(contact), isTrue);
  });

  test('does not enable BTHome MET history without channel 1 capability', () {
    final contact = Contact(
      publicKey: Uint8List(32),
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: 'WX',
      lastAdvert: 0,
      advLat: 0,
      advLon: 0,
      lastMod: 0,
      telemetry: ContactTelemetry(
        temperature: 20.1,
        humidity: 52,
        extraSensorData: const {'speed_2': 3.1, 'gust_2': 4.8, 'rain_2': 12.3},
        timestamp: DateTime(2026, 3, 21, 12),
      ),
    );

    expect(bTHomeMetMeasurementsForContact(contact), isEmpty);
    expect(supportsBTHomeMetHistory(contact), isFalse);
  });
}
