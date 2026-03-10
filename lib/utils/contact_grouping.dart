import '../models/contact.dart';

class InferredContactGroup {
  final String key;
  final String label;
  final List<Contact> contacts;

  const InferredContactGroup({
    required this.key,
    required this.label,
    required this.contacts,
  });

  DateTime get latestSeen => contacts.first.lastSeenTime;
}

class ContactListItem {
  final Contact? contact;
  final InferredContactGroup? group;

  const ContactListItem._({this.contact, this.group});

  const ContactListItem.contact(Contact contact) : this._(contact: contact);

  const ContactListItem.group(InferredContactGroup group)
    : this._(group: group);

  bool get isGroup => group != null;

  DateTime get latestSeen => group?.latestSeen ?? contact!.lastSeenTime;
}

class ContactGrouping {
  static final RegExp _prefixedNamePattern = RegExp(
    r'^([A-Za-z0-9]{2,})([-_/:])',
  );

  static List<Contact> sortByLastSeen(List<Contact> contacts) {
    return List<Contact>.from(contacts)
      ..sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
  }

  static List<ContactListItem> buildItems(
    List<Contact> contacts, {
    int minGroupSize = 4,
  }) {
    final sortedContacts = sortByLastSeen(contacts);
    return buildItemsFromSorted(sortedContacts, minGroupSize: minGroupSize);
  }

  static List<ContactListItem> buildItemsFromSorted(
    List<Contact> sortedContacts, {
    int minGroupSize = 4,
  }) {
    final groupedContacts = <String, List<Contact>>{};
    final groupLabels = <String, String>{};

    for (final contact in sortedContacts) {
      final prefix = _extractPrefix(contact.displayName);
      if (prefix == null) continue;
      groupedContacts.putIfAbsent(prefix.key, () => <Contact>[]).add(contact);
      groupLabels.putIfAbsent(prefix.key, () => prefix.label);
    }

    final eligibleGroups = <String, InferredContactGroup>{};
    for (final entry in groupedContacts.entries) {
      if (entry.value.length < minGroupSize) continue;
      eligibleGroups[entry.key] = InferredContactGroup(
        key: entry.key,
        label: groupLabels[entry.key] ?? entry.key,
        contacts: entry.value,
      );
    }

    final emittedGroups = <String>{};
    final items = <ContactListItem>[];

    for (final contact in sortedContacts) {
      final prefix = _extractPrefix(contact.displayName);
      final group = prefix == null ? null : eligibleGroups[prefix.key];
      if (group == null) {
        items.add(ContactListItem.contact(contact));
        continue;
      }
      if (emittedGroups.add(group.key)) {
        items.add(ContactListItem.group(group));
      }
    }

    return items;
  }

  static _GroupPrefix? _extractPrefix(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final match = _prefixedNamePattern.firstMatch(trimmed);
    if (match == null) return null;

    final rawPrefix = match.group(1);
    final separator = match.group(2);
    if (rawPrefix == null || separator == null) return null;

    return _GroupPrefix(
      key: rawPrefix.toUpperCase(),
      label: '$rawPrefix$separator',
    );
  }
}

class _GroupPrefix {
  final String key;
  final String label;

  const _GroupPrefix({required this.key, required this.label});
}
