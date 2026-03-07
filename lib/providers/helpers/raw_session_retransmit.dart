import 'package:flutter/foundation.dart';

import '../../models/contact.dart';

typedef RawPacketSender =
    Future<void> Function({
      required Uint8List contactPath,
      required int contactPathLen,
      required Uint8List payload,
    });

Future<bool> serveCachedSessionFragments<T>({
  required String providerLabel,
  required String sessionId,
  required Contact requester,
  required List<T> fragments,
  required int maxDirectPayloadHops,
  required int Function(T fragment) indexOf,
  required Uint8List Function(T fragment) encodeBinary,
  required RawPacketSender? sendRawPacket,
  Set<int>? requestedIndices,
}) async {
  if (fragments.isEmpty) {
    debugPrint('⚠️ [$providerLabel] No cached fragments for $sessionId');
    return false;
  }
  if (sendRawPacket == null) {
    debugPrint('⚠️ [$providerLabel] sendRawPacketCallback not set');
    return false;
  }
  if (!requester.routeHasPath) {
    debugPrint('⚠️ [$providerLabel] ${requester.advName} has no direct path');
    return false;
  }
  if (requester.routeHopCount > maxDirectPayloadHops) {
    debugPrint(
      '⚠️ [$providerLabel] ${requester.advName} is too far: ${requester.routeHopCount} hops (max $maxDirectPayloadHops)',
    );
    return false;
  }
  if (!requester.routeSupportsLegacyRawTransport) {
    debugPrint(
      '⚠️ [$providerLabel] ${requester.advName} route uses unsupported 3-byte raw transport on current client',
    );
    return false;
  }
  if (requester.outPath.isEmpty) {
    debugPrint(
      '⚠️ [$providerLabel] ${requester.advName} has empty outPath payload',
    );
    return false;
  }

  var servedCount = 0;
  for (final fragment in fragments) {
    final index = indexOf(fragment);
    if (index < 0) {
      debugPrint('⚠️ [$providerLabel] Invalid fragment index $index');
      continue;
    }
    if (requestedIndices != null && !requestedIndices.contains(index)) {
      continue;
    }
    try {
      await sendRawPacket(
        contactPath: requester.outPath,
        contactPathLen: requester.routeSignedPathLen,
        payload: encodeBinary(fragment),
      );
      servedCount++;
    } catch (e, st) {
      debugPrint(
        '❌ [$providerLabel] Serve error for $sessionId#$index: $e\n$st',
      );
      return false;
    }
  }

  if (servedCount == 0) {
    debugPrint(
      '⚠️ [$providerLabel] No fragments matched request for $sessionId',
    );
    return false;
  }
  debugPrint('✅ [$providerLabel] Served $servedCount fragments for $sessionId');
  return true;
}
