import 'package:flutter/material.dart';
import 'package:ledger/components/ui/layout/custom_app_bar.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/theme_service.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/services/biometric_service.dart';
import 'package:ledger/components/settings/settings_card.dart';
import 'package:ledger/components/settings/section_header.dart';
import 'package:ledger/services/export_service.dart';
import 'package:ledger/services/import_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ledger/components/settings/password_settings_section.dart';
import 'package:ledger/components/settings/data_management_section.dart';
import 'package:ledger/components/ui/dialogs/password_dialog.dart';
import 'package:ledger/components/ui/dialogs/recover_password_dialog.dart';
import 'package:ledger/components/settings/appearance_settings_section.dart';
import 'package:ledger/components/settings/preferences_settings_section.dart';
import 'package:ledger/components/settings/notifications_settings_section.dart';
import 'package:ledger/components/settings/danger_zone_section.dart';
import 'package:ledger/constants/settings_constants.dart';
import 'package:ledger/utilities/dialog_utils.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ledger/services/notification_service.dart';
import 'package:ledger/components/settings/ai_settings_section.dart';
import 'package:ledger/components/ui/dialogs/ai_configuration_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _matchTheme = false;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _reportReminderEnabled = false;
  int _reportReminderFrequency = 1;
  bool _budgetNotificationsEnabled = false;
  bool _budgetNotify50 = true;
  bool _budgetNotify80 = true;
  bool _budgetNotify90 = true;
  bool _donationReminderEnabled = true;
  bool _useBiometric = false;
  String _defaultCurrency = SettingsConstants.defaultCurrency;
  bool _hasPassword = false;
  String _dateFormatKey = DateFormats.defaultKey;
  bool _biometricAvailable = false;
  String _biometricType = SettingsConstants.biometricNotAvailable;
  String _aiEndpoint = '';
  String _aiApiKey = '';
  String _aiModel = '';
  bool _fabDirectAction = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: SettingsConstants.screenTitle),
      drawer: const CustomAppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SettingsConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security Section
            SectionHeader.settings(title: SettingsConstants.securitySection),
            const SizedBox(height: SettingsConstants.cardSpacing),
            SettingsCard(
              child: PasswordSettingsSection(
                hasPassword: _hasPassword,
                useBiometric: _useBiometric,
                biometricAvailable: _biometricAvailable,
                biometricType: _biometricType,
                onChangePassword: _showPasswordDialog,
                onRecoverPassword: _showRecoverPasswordDialog,
                onBiometricChanged: (value) => setState(() {
                  _useBiometric = value;
                }),
              ),
            ),
            const SizedBox(height: SettingsConstants.sectionSpacing),

            // Appearance Section
            SectionHeader.settings(title: SettingsConstants.appearanceSection),
            const SizedBox(height: SettingsConstants.cardSpacing),
            SettingsCard(
              child: AppearanceSettingsSection(
                matchTheme: _matchTheme,
                darkMode: _darkMode,
                onMatchThemeChanged: (value) =>
                    setState(() => _matchTheme = value),
                onDarkModeChanged: (value) => setState(() => _darkMode = value),
              ),
            ),
            const SizedBox(height: SettingsConstants.sectionSpacing),

            // Notifications Section
            SectionHeader.settings(title: 'Notifications'),
            const SizedBox(height: SettingsConstants.cardSpacing),
            SettingsCard(
              child: NotificationsSettingsSection(
                notificationsEnabled: _notificationsEnabled,
                reportReminderEnabled: _reportReminderEnabled,
                reportReminderFrequency: _reportReminderFrequency,
                budgetNotificationsEnabled: _budgetNotificationsEnabled,
                budgetNotify50: _budgetNotify50,
                budgetNotify80: _budgetNotify80,
                budgetNotify90: _budgetNotify90,
                donationReminderEnabled: _donationReminderEnabled,
                onNotificationsChanged: (value) async {
                  setState(() => _notificationsEnabled = value);
                  if (!value) {
                    // Cancel all notifications when master toggle is turned off
                    final notificationService = getIt<NotificationService>();
                    await notificationService.cancelReportReminders();
                    await notificationService.cancelDonationReminders();
                  }
                },
                onReportReminderChanged: (value) async {
                  setState(() => _reportReminderEnabled = value);
                  final notificationService = getIt<NotificationService>();
                  if (value) {
                    await notificationService.scheduleReportReminders();
                  } else {
                    await notificationService.cancelReportReminders();
                  }
                },
                onReportReminderFrequencyChanged: (value) async {
                  setState(() => _reportReminderFrequency = value);
                  if (_reportReminderEnabled) {
                    final notificationService = getIt<NotificationService>();
                    await notificationService.scheduleReportReminders();
                  }
                },
                onBudgetNotificationsChanged: (value) =>
                    setState(() => _budgetNotificationsEnabled = value),
                onBudgetNotify50Changed: (value) =>
                    setState(() => _budgetNotify50 = value),
                onBudgetNotify80Changed: (value) =>
                    setState(() => _budgetNotify80 = value),
                onBudgetNotify90Changed: (value) =>
                    setState(() => _budgetNotify90 = value),
                onDonationReminderChanged: (value) async {
                  setState(() => _donationReminderEnabled = value);
                  final notificationService = getIt<NotificationService>();
                  if (value) {
                    await notificationService.scheduleDonationReminders();
                  } else {
                    await notificationService.cancelDonationReminders();
                  }
                },
              ),
            ),
            const SizedBox(height: SettingsConstants.sectionSpacing),

            // Preferences Section
            SectionHeader.settings(title: SettingsConstants.preferencesSection),
            const SizedBox(height: SettingsConstants.cardSpacing),
            SettingsCard(
              child: Column(
                children: [
                  PreferencesSettingsSection(
                    defaultCurrency: _defaultCurrency,
                    dateFormatKey: _dateFormatKey,
                    onCurrencyChanged: (value) =>
                        setState(() => _defaultCurrency = value),
                    onDateFormatChanged: (value) =>
                        setState(() => _dateFormatKey = value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Quick Add Transaction'),
                    subtitle: const Text('Tap FAB to directly add transaction'),
                    value: _fabDirectAction,
                    onChanged: (value) async {
                      setState(() => _fabDirectAction = value);
                      await UserPreferenceService.setFabDirectAction(
                        value: value,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: SettingsConstants.sectionSpacing),

            // AI Configuration Section
            SectionHeader.settings(title: 'AI Assistant'),
            const SizedBox(height: SettingsConstants.cardSpacing),
            SettingsCard(
              child: AiSettingsSection(
                apiEndpoint: _aiEndpoint,
                apiKey: _aiApiKey,
                modelName: _aiModel,
                onConfigureAi: _showAiConfigurationDialog,
              ),
            ),
            const SizedBox(height: SettingsConstants.sectionSpacing),

            // Data Management Section
            SectionHeader.settings(
              title: SettingsConstants.dataManagementSection,
            ),
            const SizedBox(height: SettingsConstants.cardSpacing),
            SettingsCard(
              child: DataManagementSection(
                onExport: _handleExportData,
                onImport: _handleImportData,
                onShareLogs: _handleShareLogs,
              ),
            ),
            const SizedBox(height: SettingsConstants.sectionSpacing),

            // Danger Zone Section
            SectionHeader.settings(
              title: SettingsConstants.dangerZoneSection,
              color: CustomColors.red400,
            ),
            const SizedBox(height: SettingsConstants.cardSpacing),
            DangerZoneSection(onResetDatabase: _showResetDatabaseDialog),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Use Future.wait to load preferences in parallel for better performance
    final results = await Future.wait([
      UserPreferenceService.isMatchTheme(),
      UserPreferenceService.isDarkMode(),
      UserPreferenceService.isNotificationsEnabled(),
      UserPreferenceService.isReportReminderEnabled(),
      UserPreferenceService.getReportReminderFrequency(),
      UserPreferenceService.isBudgetNotificationsEnabled(),
      UserPreferenceService.isBudgetNotification50Enabled(),
      UserPreferenceService.isBudgetNotification80Enabled(),
      UserPreferenceService.isBudgetNotification90Enabled(),
      UserPreferenceService.isDonationReminderEnabled(),
      UserPreferenceService.isUseBiometric(),
      UserPreferenceService.getDefaultCurrency(),
      UserPreferenceService.isDatabasePasswordSet(),
      UserPreferenceService.getDateFormat(),
      BiometricService.isDeviceSupported(),
      BiometricService.getAvailableBiometrics(),
      UserPreferenceService.getAiEndpoint(),
      UserPreferenceService.getAiApiKey(),
      UserPreferenceService.getAiModel(),
      UserPreferenceService.getFabDirectAction(),
    ]);

    final matchTheme = results[0] as bool;
    final darkMode = results[1] as bool;
    final notificationsEnabled = results[2] as bool;
    final reportReminderEnabled = results[3] as bool;
    final reportReminderFrequency = results[4] as int;
    final budgetNotificationsEnabled = results[5] as bool;
    final budgetNotify50 = results[6] as bool;
    final budgetNotify80 = results[7] as bool;
    final budgetNotify90 = results[8] as bool;
    final donationReminderEnabled = results[9] as bool;
    final useBiometric = results[10] as bool;
    final defaultCurrency = results[11] as String;
    final hasPassword = results[12] as bool;
    final dateFormatKey = results[13] as String;
    final biometricSupported = results[14] as bool;
    final availableBiometrics = results[15] as List<BiometricType>;
    final aiEndpoint = results[16] as String;
    final aiApiKey = results[17] as String;
    final aiModel = results[18] as String;
    final fabDirectAction = results[19] as bool;
    final biometricTypeDesc = BiometricService.getBiometricTypeDescription(
      availableBiometrics,
    );

    setState(() {
      _matchTheme = matchTheme;
      _darkMode = darkMode;
      _notificationsEnabled = notificationsEnabled;
      _reportReminderEnabled = reportReminderEnabled;
      _reportReminderFrequency = reportReminderFrequency;
      _budgetNotificationsEnabled = budgetNotificationsEnabled;
      _budgetNotify50 = budgetNotify50;
      _budgetNotify80 = budgetNotify80;
      _budgetNotify90 = budgetNotify90;
      _donationReminderEnabled = donationReminderEnabled;
      _useBiometric = useBiometric;
      _defaultCurrency = defaultCurrency;
      _hasPassword = hasPassword;
      _dateFormatKey = dateFormatKey;
      _biometricAvailable = biometricSupported;
      _biometricType = biometricTypeDesc;
      _aiEndpoint = aiEndpoint;
      _aiApiKey = aiApiKey;
      _aiModel = aiModel;
      _fabDirectAction = fabDirectAction;
    });
    _applyTheme();
  }

  void _applyTheme() {
    final themeService = getIt<ThemeService>();
    if (_matchTheme) {
      themeService.setThemeMode(ThemeMode.system);
    } else {
      themeService.setThemeMode(_darkMode ? ThemeMode.dark : ThemeMode.light);
    }
  }

  Future<void> _showPasswordDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PasswordDialog(hasPassword: _hasPassword),
    );

    if (result == true) {
      await _loadPreferences();
      if (mounted) {
        DialogUtils.showSuccessSnackBar(
          context: context,
          message: _hasPassword
              ? SettingsConstants.passwordRestoredMessage
              : SettingsConstants.passwordSetSuccessMessage,
        );
      }
    }
  }

  Future<void> _showAiConfigurationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AiConfigurationDialog(
        currentEndpoint: _aiEndpoint,
        currentApiKey: _aiApiKey,
        currentModel: _aiModel,
      ),
    );

    if (result == true) {
      await _loadPreferences();
    }
  }

  Future<void> _showResetDatabaseDialog() async {
    final passwordController = TextEditingController();
    String? errorMessage;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: CustomColors.red700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(SettingsConstants.resetDatabaseTitle),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SettingsConstants.resetDatabaseWarningTitle,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(SettingsConstants.resetDatabaseAccounts),
                  Text(SettingsConstants.resetDatabaseTransactions),
                  Text(SettingsConstants.resetDatabaseCategories),
                  Text(SettingsConstants.resetDatabasePassword),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CustomColors.red50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CustomColors.red200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: CustomColors.red700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            SettingsConstants.resetDatabaseIrreversibleWarning,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CustomColors.red400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasPassword) ...[
                    const SizedBox(height: 16),
                    Text(
                      SettingsConstants.resetDatabasePasswordPrompt,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText:
                            SettingsConstants.resetDatabaseCurrentPasswordLabel,
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      onSubmitted: (_) {
                        // Trigger reset on enter key
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Text(
                      SettingsConstants.resetDatabaseTextPrompt,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: SettingsConstants.resetDatabaseDeleteLabel,
                        border: const OutlineInputBorder(),
                        errorText: errorMessage,
                        prefixIcon: const Icon(Icons.warning),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(SettingsConstants.cancelButton),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomColors.red400,
                  ),
                  onPressed: () async {
                    setDialogState(() => errorMessage = null);

                    // Verify password or confirmation text
                    if (_hasPassword) {
                      try {
                        final currentPassword =
                            await UserPreferenceService.getDBPassword();
                        final enteredPassword = passwordController.text.trim();
                        final storedPassword = currentPassword.trim();

                        if (enteredPassword != storedPassword) {
                          setDialogState(() {
                            errorMessage = SettingsConstants
                                .resetDatabaseIncorrectPassword;
                          });
                          return;
                        }
                      } catch (e) {
                        setDialogState(() {
                          errorMessage = 'Error verifying password: $e';
                        });
                        return;
                      }
                    } else {
                      if (passwordController.text.trim() != 'DELETE') {
                        setDialogState(() {
                          errorMessage =
                              SettingsConstants.resetDatabaseTypeDeleteError;
                        });
                        return;
                      }
                    }

                    // Perform reset
                    try {
                      // Close dialog first
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }

                      // Show loading indicator
                      if (mounted) {
                        DialogUtils.showLoadingDialog(context: context);
                      }

                      // Delete database
                      await DatabaseService().deleteDB();

                      // Clear password from preferences
                      await UserPreferenceService.clearDBPassword();

                      // Close loading dialog
                      if (mounted) {
                        Navigator.pop(context);
                      }

                      // Show success and navigate to home
                      if (mounted) {
                        DialogUtils.showSuccessSnackBar(
                          context: context,
                          message:
                              SettingsConstants.resetDatabaseSuccessMessage,
                          duration: const Duration(seconds: 4),
                        );

                        // Navigate back to home and clear stack
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      }
                    } catch (e) {
                      // Close loading dialog if open
                      if (mounted) {
                        Navigator.pop(context);
                      }

                      // Show error
                      if (mounted) {
                        DialogUtils.showErrorSnackBar(
                          context: context,
                          message:
                              '${SettingsConstants.resetDatabaseErrorPrefix} $e',
                        );
                      }
                    }
                  },
                  child: Text(SettingsConstants.resetButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRecoverPasswordDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const RecoverPasswordDialog(),
    );

    if (result == true) {
      await _loadPreferences();
      if (mounted) {
        DialogUtils.showSuccessSnackBar(
          context: context,
          message: SettingsConstants.passwordRestoredMessage,
        );
      }
    }
  }

  Future<void> _handleExportData() async {
    try {
      // Show loading dialog
      if (!mounted) return;
      DialogUtils.showLoadingDialog(
        context: context,
        message: SettingsConstants.exportLoadingMessage,
      );

      // Export data
      await ExportService.exportAndShare();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        DialogUtils.showSuccessSnackBar(
          context: context,
          message: SettingsConstants.exportSuccessMessage,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        DialogUtils.showErrorSnackBar(
          context: context,
          message: '${SettingsConstants.exportErrorPrefix} ${e.toString()}',
        );
      }
    }
  }

  Future<void> _handleImportData() async {
    // Show confirmation dialog
    final confirmReplace = await DialogUtils.showChoiceDialog<bool>(
      context: context,
      title: SettingsConstants.importDialogTitle,
      content: SettingsConstants.importDialogContent,
      choices: [
        DialogChoice(label: SettingsConstants.cancelButton, value: null),
        DialogChoice(label: SettingsConstants.mergeButton, value: false),
        DialogChoice(
          label: SettingsConstants.replaceButton,
          value: true,
          isPrimary: true,
        ),
      ],
    );

    if (confirmReplace == null) return;

    try {
      // Show loading dialog
      if (!mounted) return;
      DialogUtils.showLoadingDialog(
        context: context,
        message: SettingsConstants.importLoadingMessage,
      );

      // Import data
      final result = await ImportService.importData(replaceAll: confirmReplace);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        if (result.success) {
          // Show success message with stats
          final stats = result.stats;
          final statsMessage = stats != null
              ? SettingsConstants.importStatsTemplate
                    .replaceAll('{accounts}', stats.accounts.toString())
                    .replaceAll('{transactions}', stats.transactions.toString())
                    .replaceAll('{categories}', stats.categories.toString())
                    .replaceAll('{tags}', stats.tags.toString())
                    .replaceAll('{budgets}', stats.budgets.toString())
              : '';

          DialogUtils.showSuccessDialog(
            context: context,
            title: SettingsConstants.importSuccessTitle,
            message: '${SettingsConstants.importSuccessMessage}$statsMessage',
          );
        } else {
          // Show error message
          DialogUtils.showErrorSnackBar(
            context: context,
            message: result.message,
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        DialogUtils.showErrorSnackBar(
          context: context,
          message: '${SettingsConstants.importErrorPrefix} ${e.toString()}',
        );
      }
    }
  }

  Future<void> _handleShareLogs() async {
    try {
      // Show loading dialog
      if (!mounted) return;
      DialogUtils.showLoadingDialog(
        context: context,
        message: 'Preparing log file...',
      );

      final logFile = await LoggerService.getLogFile();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (logFile != null && await logFile.exists()) {
        // Share the log file
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(logFile.path)],
            subject: 'Ledger App Error Logs',
            text:
                'Please find the app error logs attached. These logs help us identify and fix issues you may be experiencing.',
          ),
        );
      } else {
        if (mounted) {
          DialogUtils.showErrorSnackBar(
            context: context,
            message: 'No logs available to share',
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        DialogUtils.showErrorSnackBar(
          context: context,
          message: 'Failed to share logs: ${e.toString()}',
        );
      }
    }
  }
}
