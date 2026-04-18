import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/widgets/sensors/sensor_history_sheet.dart';

void main() {
  test('history screen honors initial field key when available', () {
    final selectedFieldKey = resolveInitialSensorHistoryField(
      requestedFieldKey: 'extra:illuminance_2',
      availableFieldKeys: const <String>[
        'temperature',
        'extra:illuminance_2',
      ],
    );

    expect(selectedFieldKey, 'extra:illuminance_2');
  });

  test('history screen falls back to first available field', () {
    final selectedFieldKey = resolveInitialSensorHistoryField(
      requestedFieldKey: 'extra:missing',
      availableFieldKeys: const <String>[
        'temperature',
        'extra:illuminance_2',
      ],
    );

    expect(selectedFieldKey, 'temperature');
  });

  test('history screen returns null when no fields are available', () {
    final selectedFieldKey = resolveInitialSensorHistoryField(
      requestedFieldKey: 'temperature',
      availableFieldKeys: const <String>[],
    );

    expect(selectedFieldKey, isNull);
  });

  test('history range filters to the latest 24 hours', () {
    final samples = <SensorHistorySample>[
      SensorHistorySample(
        timestamp: DateTime(2026, 4, 1, 8),
        values: const {'temperature': 10},
      ),
      SensorHistorySample(
        timestamp: DateTime(2026, 4, 2, 7),
        values: const {'temperature': 11},
      ),
      SensorHistorySample(
        timestamp: DateTime(2026, 4, 2, 8),
        values: const {'temperature': 12},
      ),
    ];

    final filtered = filterSensorHistorySamples(
      samples: samples,
      range: SensorHistoryRange.day,
    );

    expect(filtered.map((sample) => sample.values['temperature']), [10, 11, 12]);
  });

  test('history range all keeps every sample', () {
    final samples = <SensorHistorySample>[
      SensorHistorySample(
        timestamp: DateTime(2026, 4, 1, 8),
        values: const {'temperature': 10},
      ),
      SensorHistorySample(
        timestamp: DateTime(2026, 4, 2, 8),
        values: const {'temperature': 12},
      ),
    ];

    final filtered = filterSensorHistorySamples(
      samples: samples,
      range: SensorHistoryRange.all,
    );

    expect(filtered, hasLength(2));
  });
}
