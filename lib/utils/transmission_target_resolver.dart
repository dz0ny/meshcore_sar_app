import 'dart:typed_data';

import '../models/contact.dart';
import '../providers/contacts_provider.dart';

enum TransmissionTargetFailure {
  unknownContact,
  unknownRoute,
  tooFar,
  unreachable,
}

class TransmissionTargetResolution {
  final Contact? target;
  final TransmissionTargetFailure? failure;
  final int maxHops;

  const TransmissionTargetResolution({
    required this.target,
    required this.failure,
    required this.maxHops,
  });

  int get hops => target?.routeHopCount ?? -1;
  bool get isValid => target != null && failure == null;
}

class TransmissionTargetResolver {
  const TransmissionTargetResolver._();

  static Contact? resolveLocalTarget({
    required ContactsProvider contactsProvider,
    required bool isSentByMe,
    Uint8List? recipientPublicKey,
    Uint8List? senderPublicKeyPrefix,
    String? senderKey6FromEnvelope,
    String? senderName,
  }) {
    if (isSentByMe) {
      final recipient = _findByRecipientKey(
        contactsProvider,
        recipientPublicKey,
      );
      if (recipient != null) return recipient;
    }

    final byEnvelope = _findByEnvelopeKey6(
      contactsProvider,
      senderKey6FromEnvelope,
    );
    if (byEnvelope != null) return byEnvelope;

    final byPrefix = _findByPrefix(contactsProvider, senderPublicKeyPrefix);
    if (byPrefix != null) return byPrefix;

    return _findByName(contactsProvider, senderName);
  }

  static Future<TransmissionTargetResolution> resolveFetchTarget({
    required ContactsProvider contactsProvider,
    required Future<void> Function() refreshContacts,
    required bool isSentByMe,
    Uint8List? recipientPublicKey,
    Uint8List? senderPublicKeyPrefix,
    String? senderKey6FromEnvelope,
    String? senderName,
    required int maxFetchHops,
  }) async {
    var target = resolveLocalTarget(
      contactsProvider: contactsProvider,
      isSentByMe: isSentByMe,
      recipientPublicKey: recipientPublicKey,
      senderPublicKeyPrefix: senderPublicKeyPrefix,
      senderKey6FromEnvelope: senderKey6FromEnvelope,
      senderName: senderName,
    );

    if (target == null ||
        !target.routeHasPath ||
        target.routeHopCount > maxFetchHops) {
      await refreshContacts();
      target = resolveLocalTarget(
        contactsProvider: contactsProvider,
        isSentByMe: isSentByMe,
        recipientPublicKey: recipientPublicKey,
        senderPublicKeyPrefix: senderPublicKeyPrefix,
        senderKey6FromEnvelope: senderKey6FromEnvelope,
        senderName: senderName,
      );
    }

    if (target == null) {
      return TransmissionTargetResolution(
        target: null,
        failure: TransmissionTargetFailure.unknownContact,
        maxHops: maxFetchHops,
      );
    }
    if (!target.routeHasPath) {
      return TransmissionTargetResolution(
        target: target,
        failure: TransmissionTargetFailure.unknownRoute,
        maxHops: maxFetchHops,
      );
    }
    if (target.routeHopCount > maxFetchHops) {
      return TransmissionTargetResolution(
        target: target,
        failure: TransmissionTargetFailure.tooFar,
        maxHops: maxFetchHops,
      );
    }
    return TransmissionTargetResolution(
      target: target,
      failure: null,
      maxHops: maxFetchHops,
    );
  }

  static Contact? _findByRecipientKey(
    ContactsProvider contactsProvider,
    Uint8List? recipientKey,
  ) {
    if (recipientKey == null || recipientKey.isEmpty) return null;
    final byKey = contactsProvider.findContactByKey(recipientKey);
    if (byKey != null) return byKey;
    if (recipientKey.length >= 6) {
      return contactsProvider.findContactByPrefix(
        Uint8List.fromList(recipientKey.sublist(0, 6)),
      );
    }
    return null;
  }

  static Contact? _findByEnvelopeKey6(
    ContactsProvider contactsProvider,
    String? senderKey6FromEnvelope,
  ) {
    if (senderKey6FromEnvelope == null || senderKey6FromEnvelope.isEmpty) {
      return null;
    }
    return contactsProvider.findContactByPrefixHex(senderKey6FromEnvelope);
  }

  static Contact? _findByPrefix(
    ContactsProvider contactsProvider,
    Uint8List? senderPublicKeyPrefix,
  ) {
    if (senderPublicKeyPrefix == null || senderPublicKeyPrefix.length < 6) {
      return null;
    }
    return contactsProvider.findContactByPrefix(
      Uint8List.fromList(senderPublicKeyPrefix.sublist(0, 6)),
    );
  }

  static Contact? _findByName(
    ContactsProvider contactsProvider,
    String? senderName,
  ) {
    final normalized = senderName?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final contact in contactsProvider.contacts) {
      if (contact.advName.trim().toLowerCase() == normalized.toLowerCase()) {
        return contact;
      }
    }
    return null;
  }
}
