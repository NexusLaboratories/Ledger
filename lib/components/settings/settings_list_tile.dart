import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';
import 'package:ledger/components/ui/common/icon_container.dart';

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool showChevron;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effectiveIconColor = iconColor ?? colors.positive;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: IconContainer(
        icon: icon,
        color: effectiveIconColor,
        iconSize: 20,
        padding: 8,
        borderRadius: 8,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            )
          : null,
      trailing:
          trailing ??
          (showChevron && onTap != null
              ? Icon(Icons.chevron_right, color: colors.textMuted)
              : null),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;
  final bool enabled;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.iconColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effectiveIconColor = iconColor ?? colors.positive;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: IconContainer(
        icon: icon,
        color: effectiveIconColor,
        iconSize: 20,
        padding: 8,
        borderRadius: 8,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? colors.textPrimary : colors.textMuted,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? colors.textSecondary : colors.textMuted,
              ),
            )
          : null,
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}
