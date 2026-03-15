import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/device_info.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeContactsProvider extends ContactsProvider {
  _FakeContactsProvider(this._contacts);

  final List<Contact> _contacts;

  @override
  List<Contact> get contacts => _contacts;
}

class _FakeConnectionProvider extends ConnectionProvider {
  _FakeConnectionProvider({required bool isConnected})
    : _isConnected = isConnected;

  final bool _isConnected;

  int pingCalls = 0;

  @override
  DeviceInfo get deviceInfo => DeviceInfo(
    connectionState: _isConnected
        ? ConnectionState.connected
        : ConnectionState.disconnected,
  );

  @override
  Future<PingResult> smartPing({
    required Uint8List contactPublicKey,
    required bool hasPath,
    Function()? onRetryWithFlooding,
  }) async {
    pingCalls += 1;
    return const PingResult(
      success: true,
      usedFlooding: false,
      timedOut: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitUntilLoaded(SensorsProvider provider) async {
    for (var i = 0; i < 20 && !provider.isLoaded; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.isLoaded, isTrue);
  }

  Contact buildSensorContact() {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x44;

    return Contact(
      publicKey: publicKey,
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: 'WX Station',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  test('metric label overrides persist across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final contact = buildSensorContact();

    final provider = SensorsProvider();
    await waitUntilLoaded(provider);
    await provider.addSensor(contact);
    await provider.setMetricLabel(
      contact.publicKeyHex,
      'extra:illuminance_2',
      'Solar',
    );

    expect(
      provider.labelOverrideFor(contact.publicKeyHex, 'extra:illuminance_2'),
      'Solar',
    );

    final reloadedProvider = SensorsProvider();
    await waitUntilLoaded(reloadedProvider);

    expect(
      reloadedProvider.labelOverrideFor(
        contact.publicKeyHex,
        'extra:illuminance_2',
      ),
      'Solar',
    );
  });

  test('metric order persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final contact = buildSensorContact();

    final provider = SensorsProvider();
    await waitUntilLoaded(provider);
    await provider.addSensor(contact);
    await provider.moveMetric(
      contact.publicKeyHex,
      availableFieldKeys: const ['voltage', 'battery', 'temperature'],
      oldIndex: 2,
      newIndex: 0,
    );

    expect(
      provider.metricOrderFor(contact.publicKeyHex, const [
        'voltage',
        'battery',
        'temperature',
      ]),
      const ['temperature', 'voltage', 'battery'],
    );

    final reloadedProvider = SensorsProvider();
    await waitUntilLoaded(reloadedProvider);

    expect(
      reloadedProvider.metricOrderFor(contact.publicKeyHex, const [
        'voltage',
        'battery',
        'temperature',
      ]),
      const ['temperature', 'voltage', 'battery'],
    );
  });

  test('auto refresh minutes persist across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final contact = buildSensorContact();

    final provider = SensorsProvider();
    await waitUntilLoaded(provider);
    await provider.addSensor(contact);
    await provider.setAutoRefreshMinutes(contact.publicKeyHex, 5);

    expect(provider.autoRefreshMinutesFor(contact.publicKeyHex), 5);

    final reloadedProvider = SensorsProvider();
    await waitUntilLoaded(reloadedProvider);

    expect(reloadedProvider.autoRefreshMinutesFor(contact.publicKeyHex), 5);
  });

  test('refreshDueSensors respects per-contact interval', () async {
    SharedPreferences.setMockInitialValues({});
    final contact = buildSensorContact();
    final contactsProvider = _FakeContactsProvider(<Contact>[contact]);
    final connectionProvider = _FakeConnectionProvider(isConnected: true);
    final start = DateTime(2026, 3, 15, 9, 0);

    final provider = SensorsProvider();
    await waitUntilLoaded(provider);
    await provider.addSensor(contact);
    await provider.setAutoRefreshMinutes(contact.publicKeyHex, 5);

    await provider.refreshDueSensors(
      now: start,
      contactsProvider: contactsProvider,
      connectionProvider: connectionProvider,
    );
    expect(connectionProvider.pingCalls, 1);

    await provider.refreshDueSensors(
      now: start.add(const Duration(minutes: 4)),
      contactsProvider: contactsProvider,
      connectionProvider: connectionProvider,
    );
    expect(connectionProvider.pingCalls, 1);

    await provider.refreshDueSensors(
      now: start.add(const Duration(minutes: 5)),
      contactsProvider: contactsProvider,
      connectionProvider: connectionProvider,
    );
    expect(connectionProvider.pingCalls, 2);
  });
}
