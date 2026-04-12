import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/widgets/sensors/sensor_history_sheet.dart';

void main() {
  test('history sheet honors initial field key when available', () {
    final selectedFieldKey = resolveInitialSensorHistoryField(
      requestedFieldKey: 'extra:illuminance_2',
      availableFieldKeys: const <String>[
        'temperature',
        'extra:illuminance_2',
      ],
    );

    expect(selectedFieldKey, 'extra:illuminance_2');
  });

  test('history sheet falls back to first available field', () {
    final selectedFieldKey = resolveInitialSensorHistoryField(
      requestedFieldKey: 'extra:missing',
      availableFieldKeys: const <String>[
        'temperature',
        'extra:illuminance_2',
      ],
    );

    expect(selectedFieldKey, 'temperature');
  });

  test('history sheet returns null when no fields are available', () {
    final selectedFieldKey = resolveInitialSensorHistoryField(
      requestedFieldKey: 'temperature',
      availableFieldKeys: const <String>[],
    );

    expect(selectedFieldKey, isNull);
  });
}
