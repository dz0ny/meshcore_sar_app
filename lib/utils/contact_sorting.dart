import '../models/contact.dart';

int compareContactsByLastSeen(Contact a, Contact b) {
  return b.lastSeenTime.compareTo(a.lastSeenTime);
}

int compareContactsByFavouriteThenLastSeen(Contact a, Contact b) {
  if (a.isFavourite != b.isFavourite) {
    return a.isFavourite ? -1 : 1;
  }

  return compareContactsByLastSeen(a, b);
}

int compareContactsByDisplayName(Contact a, Contact b) {
  final nameCompare = a.displayName.toLowerCase().compareTo(
    b.displayName.toLowerCase(),
  );
  if (nameCompare != 0) {
    return nameCompare;
  }

  return a.publicKeyHex.compareTo(b.publicKeyHex);
}
