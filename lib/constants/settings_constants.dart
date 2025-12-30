/// Constants for the Settings screen
class SettingsConstants {
  // Layout constants
  static const double defaultPadding = 16.0;
  static const double cardSpacing = 12.0;
  static const double sectionSpacing = 24.0;

  // Screen titles
  static const String screenTitle = 'Settings';

  // Section titles
  static const String securitySection = 'Security';
  static const String appearanceSection = 'Appearance';
  static const String preferencesSection = 'Preferences';
  static const String dataManagementSection = 'Data Management';
  static const String dangerZoneSection = 'Danger Zone';

  // Password messages
  static const String passwordSetSuccessMessage = 'Password set successfully!';
  static const String passwordRestoredMessage = 'Password restored successfully!';

  // Database reset dialog
  static const String resetDatabaseTitle = 'Reset Database';
  static const String resetDatabaseWarningTitle = 'This will permanently delete:';
  static const String resetDatabaseAccounts = '• All accounts';
  static const String resetDatabaseTransactions = '• All transactions';
  static const String resetDatabaseCategories = '• All categories';
  static const String resetDatabasePassword = '• Database password';
  static const String resetDatabaseIrreversibleWarning = 'This action cannot be undone!';
  static const String resetDatabasePasswordPrompt = 'Enter your password to confirm:';
  static const String resetDatabaseTextPrompt = 'Type "DELETE" to confirm:';
  static const String resetDatabaseCurrentPasswordLabel = 'Current Password';
  static const String resetDatabaseDeleteLabel = 'Type DELETE';
  static const String resetDatabaseIncorrectPassword = 'Incorrect password';
  static const String resetDatabaseTypeDeleteError = 'Please type DELETE to confirm';
  static const String resetDatabaseSuccessMessage = 'Database reset successfully. Please restart the app.';
  static const String resetDatabaseErrorPrefix = 'Error resetting database:';

  // Export messages
  static const String exportLoadingMessage = 'Exporting data...';
  static const String exportSuccessMessage = 'Data exported successfully!';
  static const String exportErrorPrefix = 'Export failed:';

  // Import messages
  static const String importDialogTitle = 'Import Data';
  static const String importDialogContent = 'Do you want to replace all existing data or merge with current data?\n\n'
      'Replace: Deletes all current data first.\n'
      'Merge: Keeps existing data and adds imported data.';
  static const String importLoadingMessage = 'Importing data...';
  static const String importSuccessTitle = 'Import Successful';
  static const String importSuccessMessage = 'Data imported successfully!';
  static const String importErrorPrefix = 'Import failed:';

  // Import stats template
  static const String importStatsTemplate = '\n\nImported:\n'
      '• {accounts} accounts\n'
      '• {transactions} transactions\n'
      '• {categories} categories\n'
      '• {tags} tags\n'
      '• {budgets} budgets';

  // Dialog buttons
  static const String cancelButton = 'Cancel';
  static const String confirmButton = 'Confirm';
  static const String saveButton = 'Save';
  static const String removeButton = 'Remove';
  static const String resetButton = 'Reset Database';
  static const String mergeButton = 'Merge';
  static const String replaceButton = 'Replace';
  static const String okButton = 'OK';

  // Default values
  static const String defaultCurrency = 'USD';
  static const String biometricNotAvailable = 'Not available';
}