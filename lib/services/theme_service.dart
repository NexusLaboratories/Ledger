import 'package:flutter/material.dart';

class ThemeService {
  final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.system);

  ThemeMode get themeMode => notifier.value;

  void setThemeMode(ThemeMode mode) {
    notifier.value = mode;
  }
}
