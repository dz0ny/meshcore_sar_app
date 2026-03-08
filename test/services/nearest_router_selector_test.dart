import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/services/nearest_router_selector.dart';

Contact _buildRepeater({
  required int seed,
  required String name,
  required double latitude,
  required double longitude,
  required int lastAdvert,
  int outPathLen = -1,
}) {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + seed)),
    type: ContactType.repeater,
    flags: 0,
    outPathLen: outPathLen,
    outPath: Uint8List(0),
    advName: name,
    lastAdvert: lastAdvert,
    advLat: (latitude * 1e6).round(),
    advLon: (longitude * 1e6).round(),
    lastMod: lastAdvert,
  );
}

Position _position(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selector chooses nearest eligible repeater', () {
    final selector = NearestRouterSelector();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final recipient = _buildRepeater(
      seed: 90,
      name: 'Recipient',
      latitude: 46.05,
      longitude: 14.50,
      lastAdvert: now,
    ).copyWith(type: ContactType.chat);

    final selected = selector.select(
      senderPosition: _position(46.0569, 14.5058),
      repeaters: [
        _buildRepeater(
          seed: 1,
          name: 'Far',
          latitude: 46.10,
          longitude: 14.60,
          lastAdvert: now,
          outPathLen: 1,
        ),
        _buildRepeater(
          seed: 2,
          name: 'Near',
          latitude: 46.0570,
          longitude: 14.5060,
          lastAdvert: now - 5,
          outPathLen: 1,
        ),
      ],
      recipient: recipient,
    );

    expect(selected?.advName, 'Near');
  });

  test('selector skips stale repeaters', () {
    final selector = NearestRouterSelector();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final staleAdvert = now - (11 * 60);
    final recipient = _buildRepeater(
      seed: 91,
      name: 'Recipient',
      latitude: 46.05,
      longitude: 14.50,
      lastAdvert: now,
    ).copyWith(type: ContactType.chat);

    final selected = selector.select(
      senderPosition: _position(46.0569, 14.5058),
      repeaters: [
        _buildRepeater(
          seed: 3,
          name: 'Stale',
          latitude: 46.0570,
          longitude: 14.5060,
          lastAdvert: staleAdvert,
          outPathLen: 1,
        ),
      ],
      recipient: recipient,
    );

    expect(selected, isNull);
  });
}
