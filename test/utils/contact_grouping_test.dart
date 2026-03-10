import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/utils/contact_grouping.dart';

void main() {
  Contact buildContact({
    required int seed,
    required String name,
    required DateTime lastSeen,
  }) {
    return Contact(
      publicKey: Uint8List.fromList(
        List<int>.generate(32, (index) => (seed + index) % 255),
      ),
      type: ContactType.chat,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: lastSeen.millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: lastSeen.millisecondsSinceEpoch ~/ 1000,
    );
  }

  group('ContactGrouping.buildItems', () {
    test(
      'groups prefixed contacts only when at least four share the prefix',
      () {
        final now = DateTime(2026, 3, 10, 12);
        final items = ContactGrouping.buildItems([
          buildContact(seed: 1, name: 'SI-1', lastSeen: now),
          buildContact(
            seed: 2,
            name: 'SI-2',
            lastSeen: now.subtract(const Duration(minutes: 1)),
          ),
          buildContact(
            seed: 3,
            name: 'SI-3',
            lastSeen: now.subtract(const Duration(minutes: 2)),
          ),
          buildContact(
            seed: 4,
            name: 'SI-4',
            lastSeen: now.subtract(const Duration(minutes: 3)),
          ),
          buildContact(
            seed: 5,
            name: 'OTHER',
            lastSeen: now.subtract(const Duration(minutes: 4)),
          ),
        ]);

        expect(items, hasLength(2));
        expect(items.first.isGroup, isTrue);
        expect(items.first.group!.label, 'SI-');
        expect(
          items.first.group!.contacts.map((contact) => contact.displayName),
          ['SI-1', 'SI-2', 'SI-3', 'SI-4'],
        );
        expect(items.last.contact!.displayName, 'OTHER');
      },
    );

    test('does not group when only three contacts share a prefix', () {
      final now = DateTime(2026, 3, 10, 12);
      final items = ContactGrouping.buildItems([
        buildContact(seed: 1, name: 'SI-1', lastSeen: now),
        buildContact(
          seed: 2,
          name: 'SI-2',
          lastSeen: now.subtract(const Duration(minutes: 1)),
        ),
        buildContact(
          seed: 3,
          name: 'SI-3',
          lastSeen: now.subtract(const Duration(minutes: 2)),
        ),
      ]);

      expect(items, hasLength(3));
      expect(items.every((item) => !item.isGroup), isTrue);
    });

    test('orders groups and ungrouped contacts by latest last seen', () {
      final now = DateTime(2026, 3, 10, 12);
      final items = ContactGrouping.buildItems([
        buildContact(
          seed: 1,
          name: 'Lone',
          lastSeen: now.subtract(const Duration(minutes: 1)),
        ),
        buildContact(seed: 2, name: 'SI-1', lastSeen: now),
        buildContact(
          seed: 3,
          name: 'SI-2',
          lastSeen: now.subtract(const Duration(minutes: 2)),
        ),
        buildContact(
          seed: 4,
          name: 'SI-3',
          lastSeen: now.subtract(const Duration(minutes: 3)),
        ),
        buildContact(
          seed: 5,
          name: 'SI-4',
          lastSeen: now.subtract(const Duration(minutes: 4)),
        ),
      ]);

      expect(items, hasLength(2));
      expect(items.first.isGroup, isTrue);
      expect(items.last.contact!.displayName, 'Lone');
    });
  });
}
