import 'package:flutter/material.dart';

/// Centralized theme colors that automatically adapt to light/dark mode.
/// Usage: `context.appColors.textSecondary`
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBackground;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color budgetHealthy;
  final Color budgetWarning;
  final Color budgetOverspent;
  final Color grey200;
  final Color grey400;
  final Color grey600;
  final Color iconSecondary;
  final List<Color> categoryPalette;

  // Text styles
  final TextStyle heading1;
  final TextStyle heading2;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle caption;

  const AppThemeExtension({
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBackground,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.budgetHealthy,
    required this.budgetWarning,
    required this.budgetOverspent,
    required this.grey200,
    required this.grey400,
    required this.grey600,
    required this.iconSecondary,
    required this.categoryPalette,
    required this.heading1,
    required this.heading2,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.caption,
  });

  factory AppThemeExtension.light() {
    return AppThemeExtension(
      textPrimary: Color(0xFF212121),
      textSecondary: Color(0xFF616161),
      textMuted: Color(0xFF9E9E9E),
      cardBackground: Color(0xFFFFFFFF),
      borderPrimary: Color(0xFFE0E0E0),
      borderSecondary: Color(0xFFEEEEEE),
      positive: Color(0xFF0B7845),
      negative: Color(0xFFEF5350),
      warning: Color(0xFFFFB74D),
      budgetHealthy: Color(0xFF0B7845),
      budgetWarning: Color(0xFFFFB74D),
      budgetOverspent: Color(0xFFB0696B),
      grey200: Color(0xFFEEEEEE),
      grey400: Color(0xFFBDBDBD),
      grey600: Color(0xFF757575),
      iconSecondary: Color(0xFF757575),
      categoryPalette: [
        Color(0xFF0075AC),
        Color(0xFFE57373),
        Color(0xFF0B7845),
        Color(0xFF00A9E3),
        Color(0xFF9DB0A3),
        Color(0xFF4DB6AC),
        Color(0xFFF48FB1),
        Color(0xFF5C6BC0),
      ],
      heading1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
      heading2: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF212121)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF616161)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
      caption: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
    );
  }

  factory AppThemeExtension.dark() {
    return AppThemeExtension(
      textPrimary: Color(0xFFE0E0E0),
      textSecondary: Color(0xFFB0B0B0),
      textMuted: Color(0xFF757575),
      cardBackground: Color(0xFF1E1E1E),
      borderPrimary: Color(0xFF373737),
      borderSecondary: Color(0xFF2C2C2C),
      positive: Color(0xFF66BB6A),
      negative: Color(0xFFEF5350),
      warning: Color(0xFFFFB74D),
      budgetHealthy: Color(0xFF66BB6A),
      budgetWarning: Color(0xFFFFB74D),
      budgetOverspent: Color(0xFFB0696B),
      grey200: Color(0xFF373737),
      grey400: Color(0xFF616161),
      grey600: Color(0xFF9E9E9E),
      iconSecondary: Color(0xFF9E9E9E),
      categoryPalette: [
        Color(0xFF29B6F6),
        Color(0xFFEF5350),
        Color(0xFF66BB6A),
        Color(0xFF4DD0E1),
        Color(0xFF9DB0A3),
        Color(0xFF4DB6AC),
        Color(0xFFF48FB1),
        Color(0xFF7986CB),
      ],
      heading1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE0E0E0)),
      heading2: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFE0E0E0)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFB0B0B0)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF757575)),
      caption: TextStyle(fontSize: 10, color: Color(0xFF757575)),
    );
  }

  @override
  ThemeExtension<AppThemeExtension> copyWith() => this;

  @override
  ThemeExtension<AppThemeExtension> lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension ThemeExtensions on BuildContext {
  AppThemeExtension get appColors =>
      Theme.of(this).extension<AppThemeExtension>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
