import 'path_selection.dart';

class MessageRouteMetadata {
  final PathSelectionMode mode;
  final bool routerFallbackAttempted;
  final String? relayName;
  final String? relayKey6;
  final String? canonicalPath;
  final int? hopCount;

  const MessageRouteMetadata({
    required this.mode,
    required this.routerFallbackAttempted,
    this.relayName,
    this.relayKey6,
    this.canonicalPath,
    this.hopCount,
  });

  factory MessageRouteMetadata.fromSelection(
    PathSelection selection, {
    required bool routerFallbackAttempted,
  }) {
    return MessageRouteMetadata(
      mode: selection.mode,
      routerFallbackAttempted: routerFallbackAttempted,
      relayName: selection.relayName,
      relayKey6: selection.relayKey6,
      canonicalPath: selection.canonicalPath.isEmpty
          ? null
          : selection.canonicalPath,
      hopCount: selection.hopCount > 0 ? selection.hopCount : null,
    );
  }

  String get modeLabel {
    switch (mode) {
      case PathSelectionMode.directCurrent:
        return 'Current direct path';
      case PathSelectionMode.directHistorical:
        return 'Rotated direct path';
      case PathSelectionMode.flood:
        return 'Flood route';
      case PathSelectionMode.nearestRouter:
        final suffix = relayName?.trim().isNotEmpty == true
            ? ' via $relayName'
            : relayKey6?.trim().isNotEmpty == true
            ? ' via $relayKey6'
            : '';
        return 'Nearest router$suffix';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'router_fallback_attempted': routerFallbackAttempted,
      'relay_name': relayName,
      'relay_key6': relayKey6,
      'canonical_path': canonicalPath,
      'hop_count': hopCount,
    };
  }

  factory MessageRouteMetadata.fromJson(Map<String, dynamic> json) {
    return MessageRouteMetadata(
      mode: PathSelectionMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => PathSelectionMode.directCurrent,
      ),
      routerFallbackAttempted:
          json['router_fallback_attempted'] as bool? ?? false,
      relayName: json['relay_name'] as String?,
      relayKey6: json['relay_key6'] as String?,
      canonicalPath: json['canonical_path'] as String?,
      hopCount: json['hop_count'] as int?,
    );
  }
}
