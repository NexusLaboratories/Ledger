import 'package:flutter/material.dart';
import 'package:ledger/components/settings/settings_list_tile.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/services/theme_service.dart';
import 'package:ledger/constants/ui_constants.dart';

class AppearanceSettingsSection extends StatelessWidget {
  final bool matchTheme;
  final bool darkMode;
  final ValueChanged<bool> onMatchThemeChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const AppearanceSettingsSection({
    super.key,
    required this.matchTheme,
    required this.darkMode,
    required this.onMatchThemeChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          icon: Icons.phone_android,
          title: UIConstants.matchThemeWithDevice,
          value: matchTheme,
          onChanged: (value) async {
            onMatchThemeChanged(value);
            await UserPreferenceService.setMatchTheme(value: value);
            _applyTheme(value, darkMode);
          },
        ),
        const Divider(height: 1),
        SettingsSwitchTile(
          icon: Icons.dark_mode_outlined,
          title: UIConstants.darkMode,
          value: darkMode,
          onChanged: matchTheme
              ? null
              : (value) async {
                  onDarkModeChanged(value);
                  await UserPreferenceService.setDarkMode(value: value);
                  _applyTheme(matchTheme, value);
                },
        ),
      ],
    );
  }

  void _applyTheme(bool matchTheme, bool darkMode) {
    final themeService = getIt<ThemeService>();
    if (matchTheme) {
      themeService.setThemeMode(ThemeMode.system);
    } else {
      themeService.setThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
    }
  }
}
