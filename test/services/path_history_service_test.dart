import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/path_history.dart';
import 'package:meshcore_sar_app/models/path_selection.dart';
import 'package:meshcore_sar_app/services/path_history_service.dart';

Contact _buildContact({
  required int seed,
  required List<int> pathBytes,
  required int hopCount,
  required int hashSize,
}) {
  final encoded = ((hashSize - 1) << 6) | (hopCount & 0x3F);
  final outPath = Uint8List(ContactRouteCodec.maxPathBytes)
    ..setRange(0, pathBytes.length, pathBytes);

  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + seed)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: ContactRouteCodec.toSignedDescriptor(encoded),
    outPath: outPath,
    advName: 'Contact $seed',
    lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    advLat: 0,
    advLon: 0,
    lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

Contact _buildContactWithoutRoute({required int seed}) {
  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + seed)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: -1,
    outPath: Uint8List(0),
    advName: 'Contact $seed',
    lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    advLat: 0,
    advLon: 0,
    lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('auto rotation ranks best paths before flood', () async {
    final service = PathHistoryService();
    final contact = _buildContactWithoutRoute(seed: 0);
    final best = PathSelection(
      mode: PathSelectionMode.directHistorical,
      pathBytes: Uint8List.fromList([0xAA, 0xBB]),
      hopCount: 2,
      hashSize: 1,
    );
    final second = PathSelection(
      mode: PathSelectionMode.directHistorical,
      pathBytes: Uint8List.fromList([0xCC, 0xDD]),
      hopCount: 2,
      hashSize: 1,
    );

    await service.initialize();
    await service.recordLearnedPath(contact);
    await service.recordPathResult(
      contact.publicKeyHex,
      best,
      success: true,
      roundTripTimeMs: 120,
    );
    await service.recordPathResult(
      contact.publicKeyHex,
      best,
      success: true,
      roundTripTimeMs: 110,
    );
    await service.recordPathResult(
      contact.publicKeyHex,
      second,
      success: true,
      roundTripTimeMs: 200,
    );
    await service.recordPathResult(
      contact.publicKeyHex,
      second,
      success: false,
    );

    final first = await service.getSelectionForContact(
      contact,
      autoRouteRotationEnabled: true,
    );
    final third = await service.getSelectionForContact(
      contact,
      autoRouteRotationEnabled: true,
    );
    final secondPick = await service.getSelectionForContact(
      contact,
      autoRouteRotationEnabled: true,
    );

    expect(first.mode, PathSelectionMode.directHistorical);
    expect(first.canonicalPath, 'AA,BB');
    expect(third.mode, PathSelectionMode.directHistorical);
    expect(third.canonicalPath, 'CC,DD');
    expect(secondPick.mode, PathSelectionMode.flood);
  });

  test(
    'current learned route is reused first even with rotation enabled',
    () async {
      final service = PathHistoryService();
      final contact = _buildContact(
        seed: 9,
        pathBytes: [0xAA, 0xBB, 0xCC],
        hopCount: 1,
        hashSize: 3,
      );

      await service.initialize();
      await service.recordPathResult(
        contact.publicKeyHex,
        PathSelection(
          mode: PathSelectionMode.directHistorical,
          pathBytes: Uint8List.fromList([0x11, 0x22, 0x33]),
          hopCount: 1,
          hashSize: 3,
        ),
        success: true,
        roundTripTimeMs: 90,
      );

      final selection = await service.getSelectionForContact(
        contact,
        autoRouteRotationEnabled: true,
      );

      expect(selection.mode, PathSelectionMode.directCurrent);
      expect(selection.canonicalPath, 'AABBCC');
    },
  );

  test('no history falls back to flood', () async {
    final service = PathHistoryService();
    final contact = _buildContactWithoutRoute(seed: 0);

    final selection = await service.getSelectionForContact(
      contact,
      autoRouteRotationEnabled: true,
    );

    expect(selection.mode, PathSelectionMode.flood);
  });

  test(
    'received public byte path is reversed before adding to history',
    () async {
      final service = PathHistoryService();
      await service.initialize();
      await service.recordReceivedBytePath('abc123', [
        0x01,
        0x02,
        0x03,
        0x04,
      ], 2);

      final history = service.historyFor('abc123');
      expect(history.directPaths, hasLength(1));
      expect(history.directPaths.single.pathBytes, [0x03, 0x04, 0x01, 0x02]);
      expect(history.directPaths.single.hashSize, 2);
      expect(history.directPaths.single.hopCount, 2);
      expect(history.directPaths.single.source, PathRecordSource.observed);
    },
  );

  test(
    'learned paths stay marked as observed after being seen on-air',
    () async {
      final service = PathHistoryService();
      final contact = _buildContact(
        seed: 3,
        pathBytes: [0xAA, 0xBB],
        hopCount: 2,
        hashSize: 1,
      );

      await service.initialize();
      await service.recordReceivedBytePath(contact.publicKeyHex, [
        0xBB,
        0xAA,
      ], 1);
      await service.recordLearnedPath(contact);

      final history = service.historyFor(contact.publicKeyHex);
      expect(history.directPaths, hasLength(1));
      expect(history.directPaths.single.source, PathRecordSource.observed);
    },
  );

  test('last successful direct path is chosen by location fit', () async {
    final service = PathHistoryService();
    final contact = _buildContact(
      seed: 7,
      pathBytes: [0xAA],
      hopCount: 1,
      hashSize: 1,
    );

    await service.initialize();
    await service.recordPathResult(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directHistorical,
        pathBytes: Uint8List.fromList([0x11]),
        hopCount: 1,
        hashSize: 1,
      ),
      success: true,
      roundTripTimeMs: 120,
      senderLatitude: 46.0,
      senderLongitude: 14.0,
      recipientLatitude: 46.1,
      recipientLongitude: 14.1,
    );
    await service.recordPathResult(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directHistorical,
        pathBytes: Uint8List.fromList([0x22]),
        hopCount: 1,
        hashSize: 1,
      ),
      success: true,
      roundTripTimeMs: 90,
      senderLatitude: 46.0001,
      senderLongitude: 14.0001,
      recipientLatitude: 46.1001,
      recipientLongitude: 14.1001,
    );

    final selection = await service.getLastSuccessfulDirectSelection(
      contact,
      excludeSignature: 'aa',
      senderLatitude: 46.0002,
      senderLongitude: 14.0002,
      recipientLatitude: 46.1002,
      recipientLongitude: 14.1002,
    );

    expect(selection, isNotNull);
    expect(selection!.mode, PathSelectionMode.directHistorical);
    expect(selection.canonicalPath, '22');
  });
}
