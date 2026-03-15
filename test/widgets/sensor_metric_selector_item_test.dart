import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/screens/sensors_tab.dart';
import 'package:meshcore_sar_app/widgets/sensors/sensor_telemetry_card.dart';

void main() {
  testWidgets('renders selector previews and channel badges', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorMetricSelectorItem(
            option: const SensorMetricOption(
              key: 'extra:illuminance_2',
              label: 'Illuminance (ch 2)',
              defaultLabel: 'Illuminance',
              channel: 2,
              valuePreview: '500 lx',
              previewCardData: SensorMetricCardData(
                fieldKey: 'extra:illuminance_2',
                icon: Icons.light_mode_outlined,
                label: 'Illuminance',
                value: '500 lx',
                accent: Color(0xFFC17B1D),
                channel: 2,
              ),
            ),
            visible: true,
            span: 1,
            canMoveUp: true,
            canMoveDown: true,
            onToggle: (_) {},
            onRename: () {},
            onMoveUp: () {},
            onMoveDown: () {},
            onSpanChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Show on sensor card'), findsOneWidget);
    expect(find.text('500 lx'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sensor_selector_channel_extra:illuminance_2')),
      findsOneWidget,
    );
    expect(find.text('Channel 2'), findsOneWidget);
  });

  testWidgets('omits duplicate channel chip for channel 1', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorMetricSelectorItem(
            option: const SensorMetricOption(
              key: 'battery',
              label: 'Battery',
              defaultLabel: 'Battery',
              channel: 1,
              valuePreview: '84%',
              previewCardData: SensorMetricCardData(
                fieldKey: 'battery',
                icon: Icons.battery_5_bar,
                label: 'Battery',
                value: '84%',
                accent: Color(0xFF4B8E2F),
                channel: 1,
              ),
            ),
            visible: true,
            span: 1,
            canMoveUp: true,
            canMoveDown: true,
            onToggle: (_) {},
            onRename: () {},
            onMoveUp: () {},
            onMoveDown: () {},
            onSpanChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Rename'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sensor_selector_channel_battery')),
      findsNothing,
    );
    expect(find.text('Channel 1'), findsNothing);
  });
}
