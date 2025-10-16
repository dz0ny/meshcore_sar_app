import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  sarRed,
  sarGreen,
  sarNavyBlue,
  system,
}

class AppTheme {
  // Light theme (Blue)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }

  // Dark theme (Blue)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }

  // SAR Red theme (Emergency/Alert tones)
  static ThemeData get sarRedTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: Color(0xFFFF5252), // Bright red
        onPrimary: Color(0xFF000000),
        primaryContainer: Color(0xFF8B0000), // Dark red
        onPrimaryContainer: Color(0xFFFFCDD2),
        secondary: Color(0xFFFF8A80),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFFB71C1C),
        onSecondaryContainer: Color(0xFFFFCDD2),
        tertiary: Color(0xFFFF6E40),
        onTertiary: Color(0xFF000000),
        error: Color(0xFFCF6679),
        onError: Color(0xFF000000),
        surface: Color(0xFF1A0000), // Very dark red-tinted
        onSurface: Color(0xFFFFEBEE),
        surfaceContainerHighest: Color(0xFF2D0000),
        onSurfaceVariant: Color(0xFFFFCDD2),
        outline: Color(0xFFFF5252),
      ),
      scaffoldBackgroundColor: const Color(0xFF1A0000),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF2D0000),
        foregroundColor: Color(0xFFFFEBEE),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF2D0000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFFF5252),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF5252)),
        ),
        filled: true,
        fillColor: const Color(0xFF2D0000),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5252),
          foregroundColor: const Color(0xFF000000),
        ),
      ),
    );
  }

  // SAR Green theme (All Clear/Safe tones)
  static ThemeData get sarGreenTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: Color(0xFF69F0AE), // Bright green
        onPrimary: Color(0xFF000000),
        primaryContainer: Color(0xFF00695C), // Dark teal-green
        onPrimaryContainer: Color(0xFFB9F6CA),
        secondary: Color(0xFF64FFDA),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF004D40),
        onSecondaryContainer: Color(0xFFB9F6CA),
        tertiary: Color(0xFF1DE9B6),
        onTertiary: Color(0xFF000000),
        error: Color(0xFFCF6679),
        onError: Color(0xFF000000),
        surface: Color(0xFF001A12), // Very dark green-tinted
        onSurface: Color(0xFFE8F5E9),
        surfaceContainerHighest: Color(0xFF002D1F),
        onSurfaceVariant: Color(0xFFB9F6CA),
        outline: Color(0xFF69F0AE),
      ),
      scaffoldBackgroundColor: const Color(0xFF001A12),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF002D1F),
        foregroundColor: Color(0xFFE8F5E9),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF002D1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF69F0AE),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF69F0AE)),
        ),
        filled: true,
        fillColor: const Color(0xFF002D1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF69F0AE),
          foregroundColor: const Color(0xFF000000),
        ),
      ),
    );
  }

  // SAR Navy Blue theme (Professional/Operations tones)
  static ThemeData get sarNavyBlueTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: Color(0xFF5C9FFF), // Bright navy blue
        onPrimary: Color(0xFF000000),
        primaryContainer: Color(0xFF003366), // Dark navy
        onPrimaryContainer: Color(0xFFBBDEFF),
        secondary: Color(0xFF80B3FF),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF002244),
        onSecondaryContainer: Color(0xFFBBDEFF),
        tertiary: Color(0xFF4DB8FF),
        onTertiary: Color(0xFF000000),
        error: Color(0xFFCF6679),
        onError: Color(0xFF000000),
        surface: Color(0xFF00111C), // Very dark blue-tinted
        onSurface: Color(0xFFE3F2FD),
        surfaceContainerHighest: Color(0xFF001A2D),
        onSurfaceVariant: Color(0xFFBBDEFF),
        outline: Color(0xFF5C9FFF),
      ),
      scaffoldBackgroundColor: const Color(0xFF00111C),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF001A2D),
        foregroundColor: Color(0xFFE3F2FD),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF001A2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF5C9FFF),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5C9FFF)),
        ),
        filled: true,
        fillColor: const Color(0xFF001A2D),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C9FFF),
          foregroundColor: const Color(0xFF000000),
        ),
      ),
    );
  }

  // Get theme by mode
  static ThemeData getTheme(AppThemeMode mode, Brightness systemBrightness) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.sarRed:
        return sarRedTheme;
      case AppThemeMode.sarGreen:
        return sarGreenTheme;
      case AppThemeMode.sarNavyBlue:
        return sarNavyBlueTheme;
      case AppThemeMode.system:
        return systemBrightness == Brightness.dark ? darkTheme : lightTheme;
    }
  }

  // Get display name for theme mode
  static String getThemeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.sarRed:
        return 'SAR Red (Alert)';
      case AppThemeMode.sarGreen:
        return 'SAR Green (Safe)';
      case AppThemeMode.sarNavyBlue:
        return 'SAR Navy Blue (Ops)';
      case AppThemeMode.system:
        return 'Auto (System)';
    }
  }

  // Get theme mode from string
  static AppThemeMode themeFromString(String themeName) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => AppThemeMode.system,
    );
  }
}
