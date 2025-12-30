import 'package:flutter/material.dart';
import 'settings_list_tile.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/theme.dart';

/// Password and biometric settings section
class PasswordSettingsSection extends StatelessWidget {
  final bool hasPassword;
  final bool useBiometric;
  final bool biometricAvailable;
  final String biometricType;
  final VoidCallback onChangePassword;
  final VoidCallback onRecoverPassword;
  final Function(bool) onBiometricChanged;

  const PasswordSettingsSection({
    super.key,
    required this.hasPassword,
    required this.useBiometric,
    required this.biometricAvailable,
    required this.biometricType,
    required this.onChangePassword,
    required this.onRecoverPassword,
    required this.onBiometricChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsListTile(
          icon: Icons.lock_outline,
          title: 'Database Password',
          subtitle: hasPassword ? 'Password is set' : 'No password set',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPassword)
                TextButton(
                  onPressed: onRecoverPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: CustomColors.budgetWarning,
                  ),
                  child: const Text('Recover'),
                ),
              TextButton(
                onPressed: onChangePassword,
                child: Text(hasPassword ? 'Change' : 'Set'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        SettingsSwitchTile(
          icon: Icons.fingerprint,
          title: 'Use biometric to unlock',
          subtitle: biometricAvailable
              ? 'Available: $biometricType'
              : 'Not available on this device',
          value: useBiometric,
          onChanged: biometricAvailable && hasPassword
              ? (value) {
                  onBiometricChanged(value);
                  UserPreferenceService.setUseBiometric(value: value);
                }
              : null,
        ),
      ],
    );
  }
}
