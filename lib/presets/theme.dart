import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';

/// Legacy color constants - kept for backwards compatibility.
/// Prefer using context.appColors for new code.
abstract class CustomColors {
  static const Color forestGreen = Color(0xFF0B7845);
  static const Color pineGreen = Color(0xFF3A4A40);
  static const Color veryDarkGreen = Color(0xFF052E24);
  static const Color persianBlue = Color(0xFF0075AC);
  static const Color skyBlue = Color(0xFF00A9E3);
  static const Color ashGrey = Color(0xFF9DB0A3);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color brickRed = red300;
  static const Color carmine = red400;

  static const Color budgetHealthy = Color(0xFF0B7845);
  static const Color budgetWarning = Color(0xFFFFB74D);
  static const Color budgetOverspent = Color(0xFFB0696B);

  static const Color positive = forestGreen;
  static const Color negative = red400;

  // Legacy aliases
  static const Color lightGreen = forestGreen;
  static const Color darkGreen = pineGreen;
  static const Color darkBlue = persianBlue;
  static const Color lightBlue = skyBlue;
  static const Color lightRed = brickRed;
  static const Color darkRed = carmine;
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red700 = Color(0xFFD32F2F);

  static const Color textGreyLight = Color(0xFF9DB0A3);
  static const Color textGreyDark = Color(0xFF6B7B6E);

  static const List<Color> categoryPalette = [
    forestGreen, // Green for primary category
    Color(0xFFF48FB1),
    Color(0xFF5C6BC0),
  ];

  static Color primary = forestGreen;
}

final ColorScheme _lightScheme =
    ColorScheme.fromSeed(
      seedColor: CustomColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFE3EEE8), // Custom light green background
      surfaceContainerLowest: const Color(0xFFE3EEE8),
      surfaceContainerLow: const Color(0xFFE3EEE8),
      surfaceContainer: const Color(0xFFE3EEE8),
      surfaceContainerHigh: const Color(0xFFE3EEE8),
      surfaceContainerHighest: const Color(0xFFE3EEE8),
    );

final ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: CustomColors.primary,
  brightness: Brightness.dark,
);

ThemeData _buildTheme(ColorScheme scheme, AppThemeExtension colors) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    primaryColor: CustomColors.primary,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: CustomColors.primary,
    ),
  );
}

final ThemeData lightTheme = _buildTheme(
  _lightScheme,
  AppThemeExtension.light(),
);
final ThemeData darkTheme = _buildTheme(_darkScheme, AppThemeExtension.dark());
