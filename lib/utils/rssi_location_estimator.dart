import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// An RSSI observation from a single repeater.
class RssiObservation {
  final LatLng repeaterLocation;
  final int rssiDbm;
  final DateTime observedAt;

  const RssiObservation({
    required this.repeaterLocation,
    required this.rssiDbm,
    required this.observedAt,
  });

  double? get estimatedDistanceMeters =>
      RssiLocationEstimator.estimateDistanceMeters(rssiDbm);
}

/// Estimate distance from RSSI using the log-distance path loss model.
///
/// For LoRa at ~900 MHz:
/// - Path loss exponent (n) ≈ 2.7-3.5 for outdoor environments
/// - Reference distance: 1m, reference RSSI: -30 dBm (typical LoRa at 1m)
///
/// Formula: distance = 10 ^ ((txPower - rssi) / (10 * n))
class RssiLocationEstimator {
  /// Estimate distance in meters from RSSI value.
  static double? estimateDistanceMeters(int rssiDbm) {
    if (rssiDbm > -20 || rssiDbm < -140) return null;

    const double referenceRssi = -30.0;
    const double pathLossExponent = 3.0;

    final distance = math.pow(
      10.0,
      (referenceRssi - rssiDbm) / (10.0 * pathLossExponent),
    ).toDouble();

    return distance.clamp(10.0, 50000.0);
  }

  /// Offset a point by distance and bearing (Haversine inverse).
  static LatLng offsetPoint(
    LatLng origin,
    double distanceMeters,
    double bearingDegrees,
  ) {
    const double earthRadius = 6371000.0;
    final lat1 = origin.latitude * math.pi / 180.0;
    final lon1 = origin.longitude * math.pi / 180.0;
    final bearing = bearingDegrees * math.pi / 180.0;
    final angDist = distanceMeters / earthRadius;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angDist) +
          math.cos(lat1) * math.sin(angDist) * math.cos(bearing),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(angDist) * math.cos(lat1),
          math.cos(angDist) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180.0 / math.pi, lon2 * 180.0 / math.pi);
  }

  /// Single-repeater estimate: offset from repeater by RSSI distance.
  static LatLng? estimateFromRepeater({
    required LatLng repeaterLocation,
    required int rssiDbm,
    required List<int> contactPublicKey,
  }) {
    final distance = estimateDistanceMeters(rssiDbm);
    if (distance == null) return null;

    final keyHash = contactPublicKey.fold<int>(0, (a, b) => a ^ b);
    final bearing = (keyHash % 360).toDouble();

    return offsetPoint(repeaterLocation, distance, bearing);
  }

  /// Trilateration from multiple RSSI observations.
  ///
  /// With 1 observation: offset from repeater (bearing from key hash).
  /// With 2 observations: weighted midpoint on the line between circles.
  /// With 3+ observations: weighted centroid of circle intersection region.
  ///
  /// Each observation is weighted by 1/distance² (closer = more accurate).
  static LatLng? trilaterate({
    required List<RssiObservation> observations,
    required List<int> contactPublicKey,
    Duration maxAge = const Duration(minutes: 30),
  }) {
    final now = DateTime.now();
    final recent = observations
        .where((o) =>
            now.difference(o.observedAt) <= maxAge &&
            o.estimatedDistanceMeters != null)
        .toList();

    if (recent.isEmpty) return null;

    if (recent.length == 1) {
      return estimateFromRepeater(
        repeaterLocation: recent.first.repeaterLocation,
        rssiDbm: recent.first.rssiDbm,
        contactPublicKey: contactPublicKey,
      );
    }

    // Weighted centroid: each repeater contributes a candidate point
    // on the circle towards the centroid of all repeaters.
    // Weight = 1/distance² (inverse square — closer observations dominate).

    // Step 1: compute raw centroid of all repeater locations
    double centroidLat = 0, centroidLon = 0;
    for (final obs in recent) {
      centroidLat += obs.repeaterLocation.latitude;
      centroidLon += obs.repeaterLocation.longitude;
    }
    centroidLat /= recent.length;
    centroidLon /= recent.length;
    final centroid = LatLng(centroidLat, centroidLon);

    // Step 2: for each observation, compute a candidate point on the
    // circle (at RSSI distance) in the direction of the centroid.
    double weightedLat = 0, weightedLon = 0, totalWeight = 0;

    for (final obs in recent) {
      final dist = obs.estimatedDistanceMeters!;
      final weight = 1.0 / (dist * dist);

      // Bearing from this repeater towards the centroid
      final bearing = _bearingDegrees(obs.repeaterLocation, centroid);
      final candidate = offsetPoint(obs.repeaterLocation, dist, bearing);

      weightedLat += candidate.latitude * weight;
      weightedLon += candidate.longitude * weight;
      totalWeight += weight;
    }

    if (totalWeight <= 0) return null;

    return LatLng(weightedLat / totalWeight, weightedLon / totalWeight);
  }

  /// Bearing in degrees from point A to point B.
  static double _bearingDegrees(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }
}
