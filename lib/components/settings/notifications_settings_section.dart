import 'package:flutter/material.dart';
import 'package:ledger/components/settings/settings_list_tile.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/constants/ui_constants.dart';

class NotificationsSettingsSection extends StatelessWidget {
  final bool notificationsEnabled;
  final bool reportReminderEnabled;
  final int reportReminderFrequency;
  final bool budgetNotificationsEnabled;
  final bool budgetNotify50;
  final bool budgetNotify80;
  final bool budgetNotify90;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onReportReminderChanged;
  final ValueChanged<int> onReportReminderFrequencyChanged;
  final ValueChanged<bool> onBudgetNotificationsChanged;
  final ValueChanged<bool> onBudgetNotify50Changed;
  final ValueChanged<bool> onBudgetNotify80Changed;
  final ValueChanged<bool> onBudgetNotify90Changed;

  const NotificationsSettingsSection({
    super.key,
    required this.notificationsEnabled,
    required this.reportReminderEnabled,
    required this.reportReminderFrequency,
    required this.budgetNotificationsEnabled,
    required this.budgetNotify50,
    required this.budgetNotify80,
    required this.budgetNotify90,
    required this.onNotificationsChanged,
    required this.onReportReminderChanged,
    required this.onReportReminderFrequencyChanged,
    required this.onBudgetNotificationsChanged,
    required this.onBudgetNotify50Changed,
    required this.onBudgetNotify80Changed,
    required this.onBudgetNotify90Changed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: UIConstants.enableNotifications,
          value: notificationsEnabled,
          onChanged: (value) async {
            onNotificationsChanged(value);
            await UserPreferenceService.setNotificationsEnabled(value: value);
          },
        ),
        const Divider(height: 1),
        SettingsSwitchTile(
          icon: Icons.calendar_month,
          title: UIConstants.reportReminders,
          value: reportReminderEnabled,
          enabled: notificationsEnabled,
          onChanged: notificationsEnabled
              ? (value) async {
                  onReportReminderChanged(value);
                  await UserPreferenceService.setReportReminderEnabled(
                    value: value,
                  );
                }
              : null,
        ),
        if (reportReminderEnabled && notificationsEnabled) ...[
          const Divider(height: 1),
          SettingsListTile(
            icon: Icons.access_time,
            title: UIConstants.reportReminderFrequency,
            trailing: DropdownButton<int>(
              value: reportReminderFrequency,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Every month')),
                DropdownMenuItem(value: 2, child: Text('Every 2 months')),
                DropdownMenuItem(value: 3, child: Text('Every 3 months')),
                DropdownMenuItem(value: 6, child: Text('Every 6 months')),
                DropdownMenuItem(value: 12, child: Text('Every year')),
              ],
              onChanged: notificationsEnabled
                  ? (value) async {
                      if (value != null) {
                        onReportReminderFrequencyChanged(value);
                        await UserPreferenceService.setReportReminderFrequency(
                          months: value,
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
        const Divider(height: 1),
        SettingsSwitchTile(
          icon: Icons.account_balance_wallet,
          title: UIConstants.budgetNotifications,
          value: budgetNotificationsEnabled,
          enabled: notificationsEnabled,
          onChanged: notificationsEnabled
              ? (value) async {
                  onBudgetNotificationsChanged(value);
                  await UserPreferenceService.setBudgetNotificationsEnabled(
                    value: value,
                  );
                }
              : null,
        ),
        if (budgetNotificationsEnabled && notificationsEnabled) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 56.0),
            child: SettingsSwitchTile(
              icon: Icons.warning_amber,
              title: UIConstants.budgetNotify50,
              value: budgetNotify50,
              enabled: notificationsEnabled,
              onChanged: notificationsEnabled
                  ? (value) async {
                      onBudgetNotify50Changed(value);
                      await UserPreferenceService.setBudgetNotification50Enabled(
                        value: value,
                      );
                    }
                  : null,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 56.0),
            child: SettingsSwitchTile(
              icon: Icons.warning,
              title: UIConstants.budgetNotify80,
              value: budgetNotify80,
              enabled: notificationsEnabled,
              onChanged: notificationsEnabled
                  ? (value) async {
                      onBudgetNotify80Changed(value);
                      await UserPreferenceService.setBudgetNotification80Enabled(
                        value: value,
                      );
                    }
                  : null,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 56.0),
            child: SettingsSwitchTile(
              icon: Icons.error,
              title: UIConstants.budgetNotify90,
              value: budgetNotify90,
              enabled: notificationsEnabled,
              onChanged: notificationsEnabled
                  ? (value) async {
                      onBudgetNotify90Changed(value);
                      await UserPreferenceService.setBudgetNotification90Enabled(
                        value: value,
                      );
                    }
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}
