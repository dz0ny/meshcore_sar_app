import 'package:flutter/widgets.dart';
import '../models/sar_marker.dart';
import '../l10n/app_localizations.dart';

/// Extension for SarMarkerType to provide localized display names
extension SarMarkerTypeLocalization on SarMarkerType {
  /// Get localized display name for this SAR marker type
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (this) {
      case SarMarkerType.foundPerson:
        return l10n.foundPerson;
      case SarMarkerType.fire:
        return l10n.fire;
      case SarMarkerType.stagingArea:
        return l10n.stagingArea;
      case SarMarkerType.object:
        return 'Object'; // Not commonly used, keeping English for now
      case SarMarkerType.unknown:
        return 'Unknown'; // Not commonly used, keeping English for now
    }
  }
}
