import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Extension to provide localized "time ago" formatting
extension TimeAgoExtension on Duration {
  /// Get localized time ago string
  String toLocalizedTimeAgo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (inMinutes < 1) return l10n.justNow;
    if (inMinutes < 60) return l10n.minutesAgo(inMinutes);
    if (inHours < 24) return l10n.hoursAgo(inHours);
    return l10n.daysAgo(inDays);
  }

  /// Get localized time ago string with seconds support
  String toLocalizedTimeAgoWithSeconds(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (inSeconds < 60) return l10n.secondsAgo(inSeconds);
    if (inMinutes < 60) return l10n.minutesAgo(inMinutes);
    if (inHours < 24) return l10n.hoursAgo(inHours);
    return l10n.daysAgo(inDays);
  }
}
