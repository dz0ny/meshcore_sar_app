import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/device_info.dart' as device_info;
import 'package:meshcore_sar_app/providers/channels_provider.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/screens/device_config_screen.dart';
import 'package:provider/provider.dart';

class _FakeConnectionProvider extends ChangeNotifier
    implements ConnectionProvider {
  _FakeConnectionProvider(this._deviceInfo);

  device_info.DeviceInfo _deviceInfo;

  @override
  device_info.DeviceInfo get deviceInfo => _deviceInfo;

  void updateDeviceInfo(device_info.DeviceInfo nextDeviceInfo) {
    _deviceInfo = nextDeviceInfo;
    notifyListeners();
  }

  @override
  Future<Map<String, String>> getCustomVars() async => const {};

  @override
  Future<void> getBatteryAndStorage() async {}

  @override
  Future<void> getAutoaddConfig() async {}

  @override
  Future<void> getAllowedRepeatFreq() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpDeviceConfigScreen(
  WidgetTester tester, {
  required ConnectionProvider connectionProvider,
}) async {
  tester.view.physicalSize = const Size(1440, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectionProvider>.value(
          value: connectionProvider,
        ),
        ChangeNotifierProvider<ChannelsProvider>(
          create: (_) => ChannelsProvider()..initializePublicChannel(),
        ),
        ChangeNotifierProvider<ContactsProvider>(
          create: (_) => ContactsProvider(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeviceConfigScreen(),
      ),
    ),
  );

  await tester.pump();
}

void main() {
  testWidgets(
    'matches a preset when bandwidth arrives as raw Hz',
    (tester) async {
      final connectionProvider = _FakeConnectionProvider(
        device_info.DeviceInfo(
          connectionState: device_info.ConnectionState.connected,
          radioFreq: 869618,
          radioBw: 62500,
          radioSf: 8,
          radioCr: 8,
        ),
      );

      await _pumpDeviceConfigScreen(
        tester,
        connectionProvider: connectionProvider,
      );

      expect(find.byKey(const ValueKey('eu_uk_narrow')), findsOneWidget);
      expect(find.text('EU/UK (Narrow)'), findsWidgets);
    },
  );

  testWidgets(
    're-syncs the preset dropdown when device info changes',
    (tester) async {
      final connectionProvider = _FakeConnectionProvider(
        device_info.DeviceInfo(
          connectionState: device_info.ConnectionState.connected,
        ),
      );

      await _pumpDeviceConfigScreen(
        tester,
        connectionProvider: connectionProvider,
      );

      expect(find.byKey(const ValueKey('custom')), findsOneWidget);

      connectionProvider.updateDeviceInfo(
        device_info.DeviceInfo(
          connectionState: device_info.ConnectionState.connected,
          radioFreq: 869618,
          radioBw: 62500,
          radioSf: 8,
          radioCr: 8,
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('eu_uk_narrow')), findsOneWidget);
    },
  );
}
