import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing locale preferences
class LocalePreferences {
  static const String _localeKey = 'app_locale';

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('sl'), // Slovenian
    Locale('hr'), // Croatian
    Locale('de'), // German
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('it'), // Italian
    Locale('el'), // Greek
    Locale('zh'), // Chinese
  ];

  /// Get the saved locale or return null to use system locale
  static Future<Locale?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);

    if (localeCode == null) {
      return null; // Use system locale
    }

    return Locale(localeCode);
  }

  /// Save the selected locale
  static Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();

    if (locale == null) {
      // Remove preference to use system locale
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }

  /// Get display name for a locale
  static String getDisplayName(Locale? locale) {
    if (locale == null) {
      return 'System Default';
    }

    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'sl':
        return 'Slovenščina';
      case 'hr':
        return 'Hrvatski';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'el':
        return 'Greek';
      case 'zh':
        return '简体中文';
      default:
        return locale.languageCode;
    }
  }

  /// Get native display name for a locale (shown in selection dialog)
  static String getNativeDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'sl':
        return 'Slovenščina';
      case 'hr':
        return 'Hrvatski';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'el':
        return 'Ελληνικά';
      case 'zh':
        return '简体中文';
      default:
        return locale.languageCode;
    }
  }
}
