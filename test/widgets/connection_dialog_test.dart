import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/services/network_scanner_service.dart';
import 'package:meshcore_sar_app/widgets/connection_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _ConnectableFakeConnectionProvider extends ConnectionProvider {
  int connectCalls = 0;

  @override
  List<ScannedDevice> get scannedDevices => [
    ScannedDevice(device: BluetoothDevice.fromId('test-device'), rssi: -55),
  ];

  @override
  String? get error => null;

  @override
  Future<bool> connect(BluetoothDevice device) async {
    connectCalls += 1;
    return true;
  }
}

class _TcpConnectableFakeConnectionProvider extends ConnectionProvider {
  int connectTcpCalls = 0;
  String? connectedHost;
  int? connectedPort;

  @override
  List<ScannedDevice> get scannedDevices => const [];

  @override
  String? get error => null;

  @override
  Future<bool> connectTcp(String host, int port) async {
    connectTcpCalls += 1;
    connectedHost = host;
    connectedPort = port;
    return true;
  }
}

class _FakeNetworkScannerService extends NetworkScannerService {
  _FakeNetworkScannerService({
    this.keepScanning = false,
    bool initiallyScanning = false,
  }) : _isScanning = initiallyScanning;

  final bool keepScanning;
  int scanCalls = 0;
  int stopScanCalls = 0;
  bool _isScanning;

  @override
  bool get isScanning => _isScanning;

  @override
  bool get hasCachedResults => false;

  @override
  List<DiscoveredServer> get cachedServers => const [];

  @override
  Future<List<DiscoveredServer>> scan({int? port}) async {
    scanCalls += 1;
    _isScanning = keepScanning;
    if (keepScanning) {
      onProgressUpdate?.call(1, 10);
    }
    return const [];
  }

  @override
  void clearCache() {}

  @override
  void stopScan() {
    stopScanCalls += 1;
    _isScanning = false;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('successful BLE connect closes the dialog immediately', (
    tester,
  ) async {
    final connectionProvider = _ConnectableFakeConnectionProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionProvider>.value(
        value: connectionProvider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showModalBottomSheet<Object?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const ConnectionDialog(),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(ConnectionDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(connectionProvider.connectCalls, 1);
    expect(find.byType(ConnectionDialog), findsNothing);
  });

  testWidgets('manual TCP connect can cancel discovery and use a custom port', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final connectionProvider = _TcpConnectableFakeConnectionProvider();
    final networkScanner = _FakeNetworkScannerService(
      initiallyScanning: true,
      keepScanning: true,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionProvider>.value(
        value: connectionProvider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showModalBottomSheet<Object?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ConnectionDialog(
                        networkScanner: networkScanner,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Network'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final manualEntryButton = find.widgetWithText(
      TextButton,
      'Cancel and enter manually',
    );
    final onPressed = tester.widget<TextButton>(manualEntryButton).onPressed;
    expect(onPressed, isNotNull);
    onPressed!();
    await tester.pumpAndSettle();

    expect(networkScanner.stopScanCalls, greaterThanOrEqualTo(1));

    await tester.enterText(find.widgetWithText(TextField, 'IP address'), '192.168.1.42');
    await tester.enterText(find.widgetWithText(TextField, 'TCP port'), '6001');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(connectionProvider.connectTcpCalls, 1);
    expect(connectionProvider.connectedHost, '192.168.1.42');
    expect(connectionProvider.connectedPort, 6001);
    expect(find.byType(ConnectionDialog), findsNothing);
  });

  testWidgets('recent servers show saved metadata and can reconnect', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'recent_tcp_connections_v1': [
        '{"name":"Mesh Node Alpha","host":"10.0.0.5","port":5001,"lastUsedAt":"2026-04-18T12:00:00.000Z"}',
      ],
    });

    final connectionProvider = _TcpConnectableFakeConnectionProvider();
    final networkScanner = _FakeNetworkScannerService();

    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionProvider>.value(
        value: connectionProvider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () {
                    showModalBottomSheet<Object?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ConnectionDialog(
                        networkScanner: networkScanner,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();

    expect(find.text('Recently used'), findsOneWidget);
    expect(find.text('Mesh Node Alpha'), findsOneWidget);
    expect(find.text('10.0.0.5:5001'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Connect').first);
    await tester.pumpAndSettle();

    expect(connectionProvider.connectTcpCalls, 1);
    expect(connectionProvider.connectedHost, '10.0.0.5');
    expect(connectionProvider.connectedPort, 5001);
  });
}
