import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/models/contact.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('auto rotation ranks best paths before flood', () async {
    final service = PathHistoryService();
    final contact = _buildContact(
      seed: 0,
      pathBytes: [0xAA, 0xBB],
      hopCount: 2,
      hashSize: 1,
    );
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

  test('no history falls back to flood', () async {
    final service = PathHistoryService();
    final contact = Contact(
      publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i)),
      type: ContactType.chat,
      flags: 0,
      outPathLen: -1,
      outPath: Uint8List(0),
      advName: 'No Route',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    final selection = await service.getSelectionForContact(
      contact,
      autoRouteRotationEnabled: true,
    );

    expect(selection.mode, PathSelectionMode.flood);
  });
}
