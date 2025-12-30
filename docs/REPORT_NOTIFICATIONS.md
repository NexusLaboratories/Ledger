# Monthly Report Notification Feature

## Overview

This feature allows users to receive periodic reminders to check their financial reports. Users can enable/disable these reminders and customize the frequency at which they receive them.

Additionally, users can enable budget notifications to be alerted when they reach specific thresholds (50%, 80%, or 90%) of their budget limits.

## Features

### Report Reminders Settings Configuration

Users can configure report notifications through the Settings screen under the Preferences section:

1. **Report Reminders Toggle**: Enable or disable report reminder notifications
2. **Reminder Frequency**: Choose how often to receive reminders:
   - Every month (default)
   - Every 2 months
   - Every 3 months
   - Every 6 months
   - Every year

### Budget Notifications Settings Configuration

Users can configure budget notifications through the Settings screen under the Preferences section:

1. **Budget Notifications Toggle**: Enable or disable budget threshold notifications
2. **Threshold Options** (when budget notifications are enabled):
   - **Notify at 50%**: Receive a notification when reaching 50% of any budget
   - **Notify at 80%**: Receive a notification when reaching 80% of any budget
   - **Notify at 90%**: Receive a notification when reaching 90% of any budget

All three thresholds are enabled by default when budget notifications are turned on.

### Notification Scheduling

When enabled, notifications are scheduled to appear on the first day of the applicable month at 9:00 AM local time. The notifications use the device's local timezone for accurate scheduling.

## Implementation Details

### User Preferences

Report reminder preference keys added to `UserPreferenceService`:

- `report_reminder_enabled`: Boolean - Whether report reminders are enabled
- `report_reminder_frequency`: Integer - Frequency in months (1, 2, 3, 6, or 12)

Budget notification preference keys added to `UserPreferenceService`:

- `budget_notifications_enabled`: Boolean - Whether budget notifications are enabled
- `budget_notification_50`: Boolean - Whether to notify at 50% threshold (default: true)
**Report Reminders:**
- `scheduleReportReminders()`: Schedules recurring notifications based on user preferences
- `cancelReportReminders()`: Cancels all scheduled report reminder notifications
- Uses `flutter_local_notifications` with timezone support for reliable scheduling
- Notifications persist across app restarts

**Budget Notifications:**
- `checkBudgetThresholds()`: Checks all active budgets and sends notifications when thresholds are crossed
- Integrates with `BudgetService` to calculate budget progress
- Respects user preferences for which thresholds to monitor (50%, 80%, 90%)
- Sends notifications with appropriate priority levels:
  - 50% threshold: Normal priority
  - 80% threshold: High priority
  - 90% threshold: Urgent priority

Enhanced `NotificationService` with:

  - Added toggle switch for report reminders and dropdown for frequency selection
  - Added toggle switch for budget notifications with sub-options for 50%, 80%, and 90% thresholds
- **SettingsScreen**: Added state management and callbacks to schedule/cancel notifications when settings change
- **UIConstants**: Added new constants for UI labels (`budgetNotifications`, `budgetNotify50`, `budgetNotify80`, `budgetNotify90`)eport reminder notifications
- Uses `flutter_local_notifications` with timezone support for reliable scheduling
- Notifications persist across app restarts

### UI Components

Updated components:

- **PreferencesSettingsSection**: Added toggle switch for report reminders and dropdown for frequency selection
- **SettingsScreen**: Added state management and callbacks to schedule/cancel notifications when settings change
- **UIConstants**: Added new constants for UI labels

### Dependencies

New packages added:

- `timezone: ^0.9.4` - For timezone calculations
- `flutter_timezone: ^5.0.1` - For getting device timezone

### Notification Type

Added new notification type to `NotificationType` enum:

- `reportReminder` - For monthly report reminder notifications

## Usage

**Report Reminders:**
1. Open the app and navigate to Settings
2. Scroll to the Preferences section
3. Toggle "Report reminders" to enable notifications
4. Select your preferred frequency from the dropdown (appears when enabled)
5. Notifications will be scheduled automatically

**Budget Notifications:**
1. Open the app and navigate to Settings
2. Scroll to the Preferences section
**Report Reminders:**

To manually trigger notification scheduling:

```dart
final notificationService = getIt<NotificationService>();
await notificationService.scheduleReportReminders();
```

To cancel report reminders:

```dart
final notificationService = getIt<NotificationService>();
await notificationService.cancelReportReminders();
```

**Report Reminders:**

The feature can be tested by:

1. Enabling report reminders in settings
2. Selecting a frequency
3. Verifying that the notification is scheduled (check system notification settings)
4. Testing that disabling removes the scheduled notification

**Budget Notifications:**

The feature can be tested by:

1. Creating a budget (e.g., $1000 for a category or overall)
2. Enabling budget notifications in settings
3. Selecting which thresholds to monitor (50%, 80%, 90%)
4. Adding expense transactions that push spending toward the thresholds
5. Calling `checkBudgetThresholds()` or waiting for the automatic check
6. Verifying that notifications appear at the appropriate thresholds
await notificationService.checkBudgetThresholds();
```

This method:
- Checks if budget notifications are enabled
- Retrieves all active budgets
- Calculates progress for each budget
- Sends notifications for budgets that have crossed enabled thresholdsit notificationService.scheduleReportReminders();
```

To cancel report reminders:

```dart
final notificationService = getIt<NotificationService>();
await notificationService.cancelReportReminders();
```

## Testing

The feature can be tested by:

1. Enabling report reminders in settings
2. Selecting a frequency
3. Verifying that the notification is scheduled (check system notification settings)
4. Testing that disabling removes the scheduled notification

## Future Enhancements

Possible improvements:

- Allow users to customize notification time (not just 9:00 AM)
- Add different notification messages based on spending patterns
- Include quick actions in notifications to directly view reports
- Add customizable notification day of month
- Support for multiple reminder schedules
