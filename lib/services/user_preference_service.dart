import 'dart:convert';

import 'package:ledger/models/dashboard_widget.dart';
import 'package:ledger/models/widget_layout.dart';
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/secure_storage.dart';

class UserPreferenceService {
  static const String _dbPasswordKey = 'database_password';
  static const String _matchThemeKey = 'match_theme';
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _useBiometricKey = 'use_biometric';
  static const String _defaultCurrencyKey = 'default_currency';
  static const String _dashboardWidgetsKey = 'dashboard_widgets';
  static const String _dashboardLayoutsKey = 'dashboard_layouts';
  static const String _dashboardWidgetVisibilityKey =
      'dashboard_widget_visibility';
  static const String _dashboardBudgetAmountKey = 'dashboard_budget_amount';
  static const String _dashboardNotificationsEnabledKey =
      'dashboard_notifications_enabled';
  static const String _reportReminderEnabledKey = 'report_reminder_enabled';
  static const String _reportReminderFrequencyKey = 'report_reminder_frequency';

  // Budget notification preferences
  static const String _budgetNotificationsEnabledKey =
      'budget_notifications_enabled';
  static const String _budgetNotification50Key = 'budget_notification_50';
  static const String _budgetNotification80Key = 'budget_notification_80';
  static const String _budgetNotification90Key = 'budget_notification_90';

  // Date format preference
  static const String _dateFormatKey = 'date_format';

  // AI configuration
  static const String _aiEndpointKey = 'ai_endpoint';
  static const String _aiApiKeyKey = 'ai_api_key';
  static const String _aiModelKey = 'ai_model';

  static Future<void> setDateFormat({required String value}) async {
    await SecureStorage.setValue(key: _dateFormatKey, value: value);
  }

  static Future<String> getDateFormat() async {
    try {
      final value = await SecureStorage.getValue(key: _dateFormatKey);
      return (value as String?) ?? 'MMM_dd_yyyy';
    } catch (_) {
      return 'MMM_dd_yyyy';
    }
  }

  static Future<void> setDBPassword({required String password}) async {
    await SecureStorage.setValue(key: _dbPasswordKey, value: password);
  }

  static Future<String> getDBPassword() async {
    final password = await SecureStorage.getValue(key: _dbPasswordKey);
    if (password == null) throw PasswordNotFoundException();
    return password;
  }

  static Future<bool> isDatabasePasswordSet() async {
    final password = await SecureStorage.getValue(key: _dbPasswordKey);
    return password != null && password.isNotEmpty;
  }

  static Future<void> clearDBPassword() async {
    await SecureStorage.clearValue(key: _dbPasswordKey);
  }

  // Theme related preferences
  static Future<void> setMatchTheme({required bool value}) async {
    await SecureStorage.setValue(key: _matchThemeKey, value: value.toString());
  }

  static Future<bool> isMatchTheme() async {
    try {
      final value = await SecureStorage.getValue(key: _matchThemeKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setDarkMode({required bool value}) async {
    await SecureStorage.setValue(key: _darkModeKey, value: value.toString());
  }

  static Future<bool> isDarkMode() async {
    try {
      final value = await SecureStorage.getValue(key: _darkModeKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  // Notifications
  static Future<void> setNotificationsEnabled({required bool value}) async {
    await SecureStorage.setValue(
      key: _notificationsEnabledKey,
      value: value.toString(),
    );
  }

  static Future<bool> isNotificationsEnabled() async {
    try {
      final value = await SecureStorage.getValue(key: _notificationsEnabledKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  // Biometric unlock
  static Future<void> setUseBiometric({required bool value}) async {
    await SecureStorage.setValue(
      key: _useBiometricKey,
      value: value.toString(),
    );
  }

  static Future<bool> isUseBiometric() async {
    try {
      final value = await SecureStorage.getValue(key: _useBiometricKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  // Default currency
  static Future<void> setDefaultCurrency({required String value}) async {
    await SecureStorage.setValue(key: _defaultCurrencyKey, value: value);
  }

  static Future<String> getDefaultCurrency() async {
    try {
      final value = await SecureStorage.getValue(key: _defaultCurrencyKey);
      return (value as String?) ?? 'USD';
    } catch (_) {
      return 'USD';
    }
  }

  // Dashboard widgets
  static Future<void> setDashboardWidgets({
    required List<DashboardWidget> widgets,
  }) async {
    final jsonList = widgets.map((w) => w.toJson()).toList();
    await SecureStorage.setValue(
      key: _dashboardWidgetsKey,
      value: jsonEncode(jsonList),
    );
  }

  static Future<List<DashboardWidget>> getDashboardWidgets() async {
    try {
      final value = await SecureStorage.getValue(key: _dashboardWidgetsKey);
      if (value == null) return [];
      final jsonList = jsonDecode(value) as List<dynamic>;
      return jsonList
          .map((json) => DashboardWidget.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Dashboard layouts
  static Future<void> setDashboardLayouts({
    required List<WidgetLayout> layouts,
  }) async {
    final jsonList = layouts.map((l) => l.toJson()).toList();
    await SecureStorage.setValue(
      key: _dashboardLayoutsKey,
      value: jsonEncode(jsonList),
    );
  }

  static Future<List<WidgetLayout>> getDashboardLayouts() async {
    try {
      final value = await SecureStorage.getValue(key: _dashboardLayoutsKey);
      if (value == null) return [];
      final jsonList = jsonDecode(value) as List<dynamic>;
      return jsonList
          .map((json) => WidgetLayout.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Dashboard widget visibility
  static Future<void> setDashboardWidgetVisibility({
    required Map<String, bool> visibility,
  }) async {
    await SecureStorage.setValue(
      key: _dashboardWidgetVisibilityKey,
      value: jsonEncode(visibility),
    );
  }

  static Future<Map<String, bool>> getDashboardWidgetVisibility() async {
    try {
      final value = await SecureStorage.getValue(
        key: _dashboardWidgetVisibilityKey,
      );
      if (value == null) return {};
      return Map<String, bool>.from(jsonDecode(value) as Map);
    } catch (_) {
      return {};
    }
  }

  // Dashboard budget amount
  static Future<void> setDashboardBudgetAmount({required double amount}) async {
    await SecureStorage.setValue(
      key: _dashboardBudgetAmountKey,
      value: amount.toString(),
    );
  }

  static Future<double> getDashboardBudgetAmount() async {
    try {
      final value = await SecureStorage.getValue(
        key: _dashboardBudgetAmountKey,
      );
      return double.tryParse(value ?? '0') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // Dashboard notifications
  static Future<void> setDashboardNotificationsEnabled({
    required bool value,
  }) async {
    await SecureStorage.setValue(
      key: _dashboardNotificationsEnabledKey,
      value: value.toString(),
    );
  }

  static Future<bool> isDashboardNotificationsEnabled() async {
    try {
      final value = await SecureStorage.getValue(
        key: _dashboardNotificationsEnabledKey,
      );
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  // Report reminder notifications
  static Future<void> setReportReminderEnabled({required bool value}) async {
    await SecureStorage.setValue(
      key: _reportReminderEnabledKey,
      value: value.toString(),
    );
  }

  static Future<bool> isReportReminderEnabled() async {
    try {
      final value = await SecureStorage.getValue(
        key: _reportReminderEnabledKey,
      );
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  // Report reminder frequency (in months)
  static Future<void> setReportReminderFrequency({required int months}) async {
    await SecureStorage.setValue(
      key: _reportReminderFrequencyKey,
      value: months.toString(),
    );
  }

  static Future<int> getReportReminderFrequency() async {
    try {
      final value = await SecureStorage.getValue(
        key: _reportReminderFrequencyKey,
      );
      return int.tryParse(value ?? '1') ?? 1;
    } catch (_) {
      return 1; // Default to monthly
    }
  }

  // Budget notification settings
  static Future<void> setBudgetNotificationsEnabled({
    required bool value,
  }) async {
    await SecureStorage.setValue(
      key: _budgetNotificationsEnabledKey,
      value: value.toString(),
    );
  }

  static Future<bool> isBudgetNotificationsEnabled() async {
    try {
      final value = await SecureStorage.getValue(
        key: _budgetNotificationsEnabledKey,
      );
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBudgetNotification50Enabled({
    required bool value,
  }) async {
    await SecureStorage.setValue(
      key: _budgetNotification50Key,
      value: value.toString(),
    );
  }

  static Future<bool> isBudgetNotification50Enabled() async {
    try {
      final value = await SecureStorage.getValue(key: _budgetNotification50Key);
      return value == 'true';
    } catch (_) {
      return true; // Default enabled
    }
  }

  static Future<void> setBudgetNotification80Enabled({
    required bool value,
  }) async {
    await SecureStorage.setValue(
      key: _budgetNotification80Key,
      value: value.toString(),
    );
  }

  static Future<bool> isBudgetNotification80Enabled() async {
    try {
      final value = await SecureStorage.getValue(key: _budgetNotification80Key);
      return value == 'true';
    } catch (_) {
      return true; // Default enabled
    }
  }

  static Future<void> setBudgetNotification90Enabled({
    required bool value,
  }) async {
    await SecureStorage.setValue(
      key: _budgetNotification90Key,
      value: value.toString(),
    );
  }

  static Future<bool> isBudgetNotification90Enabled() async {
    try {
      final value = await SecureStorage.getValue(key: _budgetNotification90Key);
      return value == 'true';
    } catch (_) {
      return true; // Default enabled
    }
  }

  // AI Configuration
  static Future<void> setAiEndpoint({required String value}) async {
    await SecureStorage.setValue(key: _aiEndpointKey, value: value);
  }

  static Future<String> getAiEndpoint() async {
    try {
      final value = await SecureStorage.getValue(key: _aiEndpointKey);
      return (value as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> clearAiEndpoint() async {
    await SecureStorage.clearValue(key: _aiEndpointKey);
  }

  static Future<void> setAiApiKey({required String value}) async {
    await SecureStorage.setValue(key: _aiApiKeyKey, value: value);
  }

  static Future<String> getAiApiKey() async {
    try {
      final value = await SecureStorage.getValue(key: _aiApiKeyKey);
      return (value as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> clearAiApiKey() async {
    await SecureStorage.clearValue(key: _aiApiKeyKey);
  }

  static Future<void> setAiModel({required String value}) async {
    await SecureStorage.setValue(key: _aiModelKey, value: value);
  }

  static Future<String> getAiModel() async {
    try {
      final value = await SecureStorage.getValue(key: _aiModelKey);
      return (value as String?) ?? 'gpt-4-turbo-preview';
    } catch (_) {
      return 'gpt-4-turbo-preview';
    }
  }

  static Future<void> clearAiModel() async {
    await SecureStorage.clearValue(key: _aiModelKey);
  }

  // Tutorial flag - whether the user has seen the tutorial/onboarding
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';

  static Future<void> setHasSeenTutorial({required bool value}) async {
    await SecureStorage.setValue(
      key: _hasSeenTutorialKey,
      value: value.toString(),
    );
  }

  static Future<bool> hasSeenTutorial() async {
    try {
      final value = await SecureStorage.getValue(key: _hasSeenTutorialKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }
}
