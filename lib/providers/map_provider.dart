import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MapProvider with ChangeNotifier {
  LatLng? _targetLocation;
  double? _targetZoom;
  bool _shouldAnimate = false;

  // Track which contact paths are currently visible
  final Set<String> _visibleContactPaths = {};

  LatLng? get targetLocation => _targetLocation;
  double? get targetZoom => _targetZoom;
  bool get shouldAnimate => _shouldAnimate;
  Set<String> get visibleContactPaths => Set.unmodifiable(_visibleContactPaths);

  void navigateToLocation({
    required LatLng location,
    double zoom = 15.0,
    bool animate = true,
  }) {
    _targetLocation = location;
    _targetZoom = zoom;
    _shouldAnimate = animate;
    notifyListeners();
  }

  void clearNavigation() {
    _targetLocation = null;
    _targetZoom = null;
    _shouldAnimate = false;
    // Don't notify listeners to avoid rebuilds
  }

  void updateZoom(double zoom) {
    _targetZoom = zoom;
    notifyListeners();
  }

  /// Toggle path visibility for a contact
  void toggleContactPath(String publicKeyHex) {
    if (_visibleContactPaths.contains(publicKeyHex)) {
      _visibleContactPaths.remove(publicKeyHex);
    } else {
      _visibleContactPaths.add(publicKeyHex);
    }
    notifyListeners();
  }

  /// Check if a contact's path is visible
  bool isContactPathVisible(String publicKeyHex) {
    return _visibleContactPaths.contains(publicKeyHex);
  }

  /// Hide all contact paths
  void hideAllPaths() {
    _visibleContactPaths.clear();
    notifyListeners();
  }

  /// Show path for specific contact (hide all others)
  void showOnlyPath(String publicKeyHex) {
    _visibleContactPaths.clear();
    _visibleContactPaths.add(publicKeyHex);
    notifyListeners();
  }
}
