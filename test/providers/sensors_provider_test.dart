import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/device_info.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/services/cayenne_lpp_parser.dart';
import 'package:meshcore_sar_app/services/profiles_feature_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeContactsProvider extends ContactsProvider {
  _FakeContactsProvider(this._contacts);

  final List<Contact> _contacts;

  @override
  List<Contact> get contacts => _contacts;
}

class _FakeConnectionProvider extends ConnectionProvider {
  _FakeConnectionProvider({
    required bool isConnected,
    Uint8List? publicKey,
    String? selfName,
  }) : _isConnected = isConnected,
       _publicKey = publicKey,
       _selfName = selfName;

  final bool _isConnected;
  final Uint8List? _publicKey;
  final String? _selfName;

  int pingCalls = 0;

  @override
  DeviceInfo get deviceInfo => DeviceInfo(
    connectionState: _isConnected
        ? ConnectionState.connected
        : ConnectionState.disconnected,
    publicKey: _publicKey,
    selfName: _selfName,
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

  setUp(() {
    ProfileStorageScope.setScope(
      profilesEnabled: false,
      activeProfileId: 'default',
    );
  });

  Future<void> waitUntilLoaded(SensorsProvider provider) async {
    for (var i = 0; i < 20 && !provider.isLoaded; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.isLoaded, isTrue);
  }

  Contact buildSensorContact({
    int firstByte = 0x44,
    String name = 'WX Station',
  }) {
    final publicKey = Uint8List(32);
    publicKey[0] = firstByte;

    return Contact(
      publicKey: publicKey,
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Contact buildTelemetrySensorContact() {
    final publicKey = Uint8List(32);
    publicKey[0] = 0x55;

    return Contact(
      publicKey: publicKey,
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: 'Weather Station',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      telemetry: ContactTelemetry(
        temperature: 11.8,
        humidity: 51,
        pressure: 921.9,
        timestamp: DateTime.now(),
        extraSensorData: const {
          '__source_channel:temperature': 3,
          '__source_channel:humidity': 2,
          '__source_channel:pressure': 2,
          'illuminance_2': 19150.0,
          'temperature_2': 1.99,
          'voltage_2': 5.2,
          'switch_2': 0,
          'speed_2': 2.8,
          'speed_3': 3.7,
          'uv_2': 1.0,
        },
      ),
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
    await provider.setAutoRefreshMinutes(contact.publicKeyHex, 1440);

    expect(provider.autoRefreshMinutesFor(contact.publicKeyHex), 1440);

    final reloadedProvider = SensorsProvider();
    await waitUntilLoaded(reloadedProvider);

    expect(reloadedProvider.autoRefreshMinutesFor(contact.publicKeyHex), 1440);
  });

  test('watched sensors and preferences are isolated per profile', () async {
    SharedPreferences.setMockInitialValues({});
    final contact = buildSensorContact();

    ProfileStorageScope.setScope(
      profilesEnabled: false,
      activeProfileId: 'default',
    );
    final defaultProvider = SensorsProvider();
    await waitUntilLoaded(defaultProvider);
    await defaultProvider.addSensor(contact);
    await defaultProvider.setMetricLabel(
      contact.publicKeyHex,
      'voltage',
      'Default Voltage',
    );

    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'alpha',
    );
    final customProvider = SensorsProvider();
    await waitUntilLoaded(customProvider);

    expect(customProvider.watchedSensorKeys, isEmpty);
    expect(
      customProvider.labelOverrideFor(contact.publicKeyHex, 'voltage'),
      isNull,
    );

    await customProvider.addSensor(contact);
    await customProvider.setMetricLabel(
      contact.publicKeyHex,
      'voltage',
      'Alpha Voltage',
    );

    ProfileStorageScope.setScope(
      profilesEnabled: false,
      activeProfileId: 'default',
    );
    final reloadedDefaultProvider = SensorsProvider();
    await waitUntilLoaded(reloadedDefaultProvider);
    expect(reloadedDefaultProvider.watchedSensorKeys, [contact.publicKeyHex]);
    expect(
      reloadedDefaultProvider.labelOverrideFor(contact.publicKeyHex, 'voltage'),
      'Default Voltage',
    );

    ProfileStorageScope.setScope(
      profilesEnabled: true,
      activeProfileId: 'alpha',
    );
    final reloadedCustomProvider = SensorsProvider();
    await waitUntilLoaded(reloadedCustomProvider);
    expect(reloadedCustomProvider.watchedSensorKeys, [contact.publicKeyHex]);
    expect(
      reloadedCustomProvider.labelOverrideFor(contact.publicKeyHex, 'voltage'),
      'Alpha Voltage',
    );
  });

  test('watched sensor order persists across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    final first = buildSensorContact(firstByte: 0x44, name: 'First');
    final second = buildSensorContact(firstByte: 0x45, name: 'Second');
    final third = buildSensorContact(firstByte: 0x46, name: 'Third');

    final provider = SensorsProvider();
    await waitUntilLoaded(provider);
    await provider.addSensor(first);
    await provider.addSensor(second);
    await provider.addSensor(third);

    await provider.reorderSensors(2, 0);

    expect(provider.watchedSensorKeys, <String>[
      third.publicKeyHex,
      first.publicKeyHex,
      second.publicKeyHex,
    ]);

    final reloadedProvider = SensorsProvider();
    await waitUntilLoaded(reloadedProvider);

    expect(reloadedProvider.watchedSensorKeys, <String>[
      third.publicKeyHex,
      first.publicKeyHex,
      second.publicKeyHex,
    ]);
  });

  test(
    'unsupported auto refresh minutes normalize to nearest option',
    () async {
      SharedPreferences.setMockInitialValues({});
      final contact = buildSensorContact();

      final provider = SensorsProvider();
      await waitUntilLoaded(provider);
      await provider.addSensor(contact);
      await provider.setAutoRefreshMinutes(contact.publicKeyHex, 1);

      expect(provider.autoRefreshMinutesFor(contact.publicKeyHex), 5);
    },
  );

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

  test(
    'addSensor includes available extra telemetry fields by default',
    () async {
      SharedPreferences.setMockInitialValues({});
      final contact = buildTelemetrySensorContact();

      final provider = SensorsProvider();
      await waitUntilLoaded(provider);
      await provider.addSensor(contact);

      expect(
        provider.visibleFieldsFor(contact.publicKeyHex),
        containsAll(<String>{
          'temperature',
          'humidity',
          'pressure',
          'extra:illuminance_2',
          'extra:temperature_2',
          'extra:voltage_2',
          'extra:switch_2',
          'extra:speed_2',
          'extra:speed_3',
          'extra:uv_2',
        }),
      );
    },
  );

  test('selfContact includes stored self telemetry', () async {
    SharedPreferences.setMockInitialValues({});
    final selfKey = Uint8List(32)..[0] = 0x66;
    final contactsProvider = ContactsProvider();
    await contactsProvider.initialize(devicePublicKey: selfKey);
    contactsProvider.updateTelemetry(
      selfKey.sublist(0, 6),
      CayenneLppParser.createTemperatureData(19.5, channel: 1),
    );

    final connectionProvider = _FakeConnectionProvider(
      isConnected: true,
      publicKey: selfKey,
      selfName: 'My Device',
    );
    final provider = SensorsProvider();
    await waitUntilLoaded(provider);

    final selfContact = provider.selfContact(
      contactsProvider,
      connectionProvider,
    );

    expect(selfContact, isNotNull);
    expect(selfContact!.telemetry, isNotNull);
    expect(selfContact.telemetry!.temperature, closeTo(19.5, 0.1));
  });
}
