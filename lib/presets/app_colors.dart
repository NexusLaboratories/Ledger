import 'package:flutter/material.dart';

/// Centralized app color definitions used across the app.
/// Add new semantic colors here instead of scattering hex literals.
class AppColors {
  // Income (positive) gradient
  static const Color incomeGradientStart = Color(0xFF1B5E20);
  static const Color incomeGradientMid = Color(0xFF2E7D32);
  static const Color incomeGradientEnd = Color(0xFF388E3C);
  static const List<Color> incomeGradient = [
    incomeGradientStart,
    incomeGradientMid,
    incomeGradientEnd,
  ];

  // Expense (negative) gradient
  static const Color expenseGradientStart = Color(0xFFB71C1C);
  static const Color expenseGradientMid = Color(0xFFC62828);
  static const Color expenseGradientEnd = Color(0xFFD32F2F);
  static const List<Color> expenseGradient = [
    expenseGradientStart,
    expenseGradientMid,
    expenseGradientEnd,
  ];

  // Surface variations
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);

  // Backgrounds for transaction items
  static const Color incomeBg = Color(0xFFE8F5E9);
  static const Color expenseBg = Color(0xFFFFEBEE);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFF44336);

  // Tag palette (kept in a single place for consistency)
  static const List<Color> tagPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFFEF4444), // Red
  ];

  // Utility: pick tag color by index
  static Color tagColorAt(int index) => tagPalette[index % tagPalette.length];
}
