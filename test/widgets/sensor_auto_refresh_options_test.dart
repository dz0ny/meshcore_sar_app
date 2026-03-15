import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/screens/sensors_tab.dart';

void main() {
  testWidgets('renders expanded auto refresh intervals and selects value', (
    tester,
  ) async {
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SensorAutoRefreshOptions(
            selectedMinutes: selected,
            onSelected: (minutes) {
              selected = minutes;
            },
          ),
        ),
      ),
    );

    expect(find.text('Off'), findsOneWidget);
    expect(find.text('5m'), findsOneWidget);
    expect(find.text('15m'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);
    expect(find.text('60m'), findsOneWidget);
    expect(find.text('6h'), findsOneWidget);
    expect(find.text('12h'), findsOneWidget);
    expect(find.text('24h'), findsOneWidget);

    await tester.tap(find.text('24h'));
    await tester.pump();

    expect(selected, 1440);
  });
}
