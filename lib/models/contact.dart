export 'package:meshcore_client/meshcore_client.dart'
    show Contact, ContactType, ContactTelemetry, AdvertLocation;

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:meshcore_client/meshcore_client.dart';

class ParsedContactRoute {
  final String canonicalText;
  final int hashSize;
  final int hopCount;
  final int encodedPathLen;
  final int signedEncodedPathLen;
  final Uint8List pathBytes;
  final Uint8List paddedPathBytes;

  const ParsedContactRoute({
    required this.canonicalText,
    required this.hashSize,
    required this.hopCount,
    required this.encodedPathLen,
    required this.signedEncodedPathLen,
    required this.pathBytes,
    required this.paddedPathBytes,
  });

  int get byteLength => pathBytes.length;
  String get summary => hopCount == 0
      ? 'Direct'
      : '$hopCount hop${hopCount == 1 ? '' : 's'} via $hashSize-byte hashes';
}

class ContactRouteFormatException implements Exception {
  final String message;

  const ContactRouteFormatException(this.message);

  @override
  String toString() => message;
}

class ContactRouteCodec {
  static const int maxHashSize = 3;
  static const int maxPathBytes = 64;
  static const int _unknownDescriptor = 0xFF;

  static ParsedContactRoute parse(String input) {
    final normalized = input.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw const ContactRouteFormatException('Route cannot be empty.');
    }

    final hopTokens = normalized
        .split(',')
        .map((token) => token.trim())
        .toList();
    if (hopTokens.any((token) => token.isEmpty)) {
      throw const ContactRouteFormatException('Route contains an empty hop.');
    }

    final hopBytes = <List<int>>[];
    int? hashSize;
    for (final token in hopTokens) {
      final compact = token.replaceAll(':', '');
      if (compact.isEmpty || !RegExp(r'^[0-9A-F]+$').hasMatch(compact)) {
        throw ContactRouteFormatException('Invalid hop "$token".');
      }
      if (compact.length.isOdd) {
        throw ContactRouteFormatException(
          'Hop "$token" must contain full bytes.',
        );
      }

      final currentHashSize = compact.length ~/ 2;
      if (currentHashSize < 1 || currentHashSize > maxHashSize) {
        throw ContactRouteFormatException(
          'Hop "$token" must be 1, 2, or 3 bytes.',
        );
      }

      hashSize ??= currentHashSize;
      if (hashSize != currentHashSize) {
        throw const ContactRouteFormatException(
          'All hops in a route must use the same hash size.',
        );
      }

      final bytes = <int>[];
      for (var i = 0; i < compact.length; i += 2) {
        bytes.add(int.parse(compact.substring(i, i + 2), radix: 16));
      }
      hopBytes.add(bytes);
    }

    final resolvedHashSize = hashSize ?? 1;
    final flatBytes = Uint8List.fromList(
      hopBytes.expand((hop) => hop).toList(),
    );
    if (flatBytes.length > maxPathBytes) {
      throw const ContactRouteFormatException(
        'Route exceeds the 64-byte firmware limit.',
      );
    }

    final encodedPathLen =
        ((resolvedHashSize - 1) << 6) | (hopBytes.length & 0x3F);
    final padded = Uint8List(maxPathBytes);
    padded.setRange(0, flatBytes.length, flatBytes);

    return ParsedContactRoute(
      canonicalText: hopBytes
          .map(
            (hop) => hop
                .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase(),
          )
          .join(','),
      hashSize: resolvedHashSize,
      hopCount: hopBytes.length,
      encodedPathLen: encodedPathLen,
      signedEncodedPathLen: toSignedDescriptor(encodedPathLen),
      pathBytes: flatBytes,
      paddedPathBytes: padded,
    );
  }

  static ParsedContactRoute? fromContact(Contact contact) {
    if (!contact.routeHasPath || contact.routeHopCount == 0) {
      return null;
    }

    return ParsedContactRoute(
      canonicalText: contact.routeCanonicalText,
      hashSize: contact.routeHashSize,
      hopCount: contact.routeHopCount,
      encodedPathLen: contact.routeEncodedPathLen,
      signedEncodedPathLen: contact.routeSignedPathLen,
      pathBytes: contact.routePathBytes,
      paddedPathBytes: _padPath(contact.routePathBytes),
    );
  }

  static Uint8List _padPath(Uint8List bytes) {
    final padded = Uint8List(maxPathBytes);
    padded.setRange(0, math.min(bytes.length, maxPathBytes), bytes);
    return padded;
  }

  static int toSignedDescriptor(int encodedPathLen) =>
      encodedPathLen > 127 ? encodedPathLen - 256 : encodedPathLen;

  static int toUnsignedDescriptor(int signedPathLen) => signedPathLen & 0xFF;

  static bool isUnknownDescriptor(int signedPathLen) =>
      toUnsignedDescriptor(signedPathLen) == _unknownDescriptor;

  static bool isValidDescriptor(int signedPathLen) {
    final raw = toUnsignedDescriptor(signedPathLen);
    if (raw == _unknownDescriptor) return false;
    final hashSize = ((raw >> 6) + 1);
    if (hashSize > maxHashSize) return false;
    final hopCount = raw & 0x3F;
    return hopCount * hashSize <= maxPathBytes;
  }
}

extension ContactLocalization on Contact {
  /// Returns the localized display name for special contacts (e.g. Public Channel).
  /// For all other contacts, returns [displayName].
  String getLocalizedDisplayName(BuildContext context) {
    if (isPublicChannel) {
      return AppLocalizations.of(context)!.publicChannel;
    }
    return displayName;
  }

  int get routeEncodedPathLen =>
      ContactRouteCodec.toUnsignedDescriptor(outPathLen);

  int get routeSignedPathLen =>
      ContactRouteCodec.toSignedDescriptor(routeEncodedPathLen);

  bool get routeIsUnknown => ContactRouteCodec.isUnknownDescriptor(outPathLen);

  bool get routeHasPath =>
      !routeIsUnknown && ContactRouteCodec.isValidDescriptor(outPathLen);

  int get routeHashSize => routeHasPath ? ((routeEncodedPathLen >> 6) + 1) : 1;

  int get routeHopCount => routeHasPath ? (routeEncodedPathLen & 0x3F) : -1;

  int get routeByteLength => routeHasPath
      ? math.min(routeHopCount * routeHashSize, outPath.length)
      : 0;

  Uint8List get routePathBytes => routeByteLength <= 0
      ? Uint8List(0)
      : Uint8List.fromList(outPath.sublist(0, routeByteLength));

  String get routeCanonicalText {
    if (!routeHasPath || routeHopCount <= 0) return '';
    final bytes = routePathBytes;
    final hops = <String>[];
    for (var i = 0; i < bytes.length; i += routeHashSize) {
      hops.add(
        bytes
            .sublist(i, i + routeHashSize)
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase(),
      );
    }
    return hops.join(',');
  }

  String get routeSummary {
    if (routeIsUnknown || !routeHasPath) {
      return 'Flood/Unknown';
    }
    if (routeHopCount == 0) {
      return 'Direct';
    }
    return '$routeHopCount hop${routeHopCount == 1 ? '' : 's'} via $routeHashSize-byte hashes';
  }

  bool get routeSupportsLegacyRawTransport =>
      routeHasPath && routeSignedPathLen >= 0;
}
