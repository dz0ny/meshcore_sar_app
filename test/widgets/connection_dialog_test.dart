import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/widgets/connection_dialog.dart';
import 'package:provider/provider.dart';

class _FakeConnectionProvider extends ConnectionProvider {
  int startScanCalls = 0;
  int stopScanCalls = 0;
  bool _isScanning = false;

  @override
  bool get isScanning => _isScanning;

  @override
  List<ScannedDevice> get scannedDevices => const [];

  @override
  String? get error => null;

  @override
  Future<void> startScan() async {
    startScanCalls += 1;
    _isScanning = true;
    notifyListeners();
  }

  @override
  Future<void> stopScan() async {
    stopScanCalls += 1;
    _isScanning = false;
    notifyListeners();
  }
}

void main() {
  testWidgets('BLE scan waits for explicit user action', (tester) async {
    final connectionProvider = _FakeConnectionProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionProvider>.value(
        value: connectionProvider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ConnectionDialog()),
        ),
      ),
    );

    await tester.pump();

    expect(connectionProvider.startScanCalls, 0);
    expect(
      find.text('Press scan to search for nearby devices'),
      findsOneWidget,
    );
    expect(find.text('Scan'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Scan'));
    await tester.pump();

    expect(connectionProvider.stopScanCalls, 1);
    expect(connectionProvider.startScanCalls, 1);
  });
}
