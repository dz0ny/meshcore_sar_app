import 'package:flutter/foundation.dart';

/// Debug print that only outputs in debug builds
void debugPrint(Object? message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
