import 'package:geolocator/geolocator.dart';

import '../models/contact.dart';

class NearestRouterSelector {
  const NearestRouterSelector();

  Contact? select({
    required Position? senderPosition,
    required List<Contact> repeaters,
    required Contact recipient,
  }) {
    if (senderPosition == null) {
      return null;
    }

    final eligible = repeaters.where((contact) {
      if (contact.publicKeyHex == recipient.publicKeyHex) {
        return false;
      }
      if (!contact.isRecentlySeen) {
        return false;
      }
      return contact.displayLocation != null;
    }).toList();
    if (eligible.isEmpty) {
      return null;
    }

    eligible.sort((a, b) {
      final locationA = a.displayLocation!;
      final locationB = b.displayLocation!;
      final distanceA = Geolocator.distanceBetween(
        senderPosition.latitude,
        senderPosition.longitude,
        locationA.latitude,
        locationA.longitude,
      );
      final distanceB = Geolocator.distanceBetween(
        senderPosition.latitude,
        senderPosition.longitude,
        locationB.latitude,
        locationB.longitude,
      );
      final distanceCompare = distanceA.compareTo(distanceB);
      if (distanceCompare != 0) {
        return distanceCompare;
      }

      final advertCompare = b.lastAdvert.compareTo(a.lastAdvert);
      if (advertCompare != 0) {
        return advertCompare;
      }

      final hopCompare = a.routeHopCount.compareTo(b.routeHopCount);
      if (hopCompare != 0) {
        return hopCompare;
      }

      final nameCompare = a.advName.compareTo(b.advName);
      if (nameCompare != 0) {
        return nameCompare;
      }
      return a.publicKeyHex.compareTo(b.publicKeyHex);
    });

    return eligible.first;
  }
}
