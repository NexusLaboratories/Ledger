import 'package:flutter/material.dart';
import 'package:ledger/presets/theme.dart';

class DashboardConstants {
  // Text Labels
  static const String screenTitle = 'Dashboard';
  static const String netWorthSectionTitle = 'YOUR NET WORTH';
  static const String dashboardSectionTitle = 'YOUR STATS';
  static const String searchResultsTitle = 'SEARCH RESULTS';
  static const String totalBalanceLabel = 'Total Balance';
  static const String noDataFoundLabel = 'No data found';
  static const String setPasswordPrompt =
      'Set database password to see your net worth';
  static const String noWidgetsVisibleLabel = 'No widgets visible';
  static const String enableWidgetsPrompt =
      'Enable widgets in dashboard settings';
  static const String goToSettingsLabel = 'Go to Settings';
  static const String noResultsFoundLabel = 'No results found';
  static const String adjustSearchCriteriaPrompt =
      'Try adjusting your search criteria';
  static const String clearSearchLabel = 'Clear';
  static const String addTooltip = 'Add';

  // Dialog Labels
  static const String secureYourDataTitle = 'Secure Your Data';
  static const String databasePasswordLabel = 'Database Password';
  static const String databasePasswordDescription =
      'Set a password to encrypt your database. Your data may be lost if you forget it.';
  static const String minimumCharactersHint = 'Minimum 4 characters';
  static const String setPasswordAndContinueLabel = 'Set Password & Continue';
  static const String passwordCannotBeEmptyError = 'Password cannot be empty';
  static const String passwordMinLengthError =
      'Password must be at least 4 characters';
  static const String failedToSetPasswordError = 'Failed to set password';
  static const String failedToOpenDatabaseError =
      'Failed to open database. Please check your password in Settings.';
  static const String settingsLabel = 'Settings';

  // Transaction/Account Dialog Labels
  static const String addTransactionTitle = 'Add Transaction';
  static const String addAccountTitle = 'Add Account';
  static const String noAccountsTitle = 'No Accounts';
  static const String noAccountsMessage =
      'You must create an account before creating a transaction.';
  static const String cancelLabel = 'Cancel';
  static const String createAccountLabel = 'Create Account';
  static const String searchFailedError = 'Search failed';

  // Routes
  static const String settingsRoute = '/settings';
  static const String transactionDetailRoute = '/transaction-detail';
  static const String accountTransactionsRoute = '/account-transactions';

  // Default Values
  static const String defaultCurrency = 'INR';
  static const int minimumPasswordLength = 4;

  // Colors (theme-aware)
  static Color getCardBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getSectionTitleColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getSubtitleColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getEmptyStateIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getPositiveBalanceColor(BuildContext context) {
    return CustomColors.positive;
  }

  static Color getNegativeBalanceColor(BuildContext context) {
    return CustomColors.negative;
  }

  // Sizes
  static const double sectionTitleFontSize = 12;
  static const double cardBorderRadius = 16;
  static const double iconContainerBorderRadius = 12;
  static const double iconSize = 28;
  static const double emptyStateIconSize = 48;
  static const double cardPaddingHorizontal = 20;
  static const double cardPaddingVertical = 24;
  static const double sectionSpacing = 32;
  static const double cardMargin = 16;

  // Text Styles
  static TextStyle getSectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: sectionTitleFontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: getSectionTitleColor(context),
    );
  }

  static TextStyle getBalanceLabelStyle(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle getBalanceAmountStyle(
    BuildContext context,
    bool isPositive,
  ) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: isPositive
          ? getPositiveBalanceColor(context)
          : getNegativeBalanceColor(context),
    );
  }

  static TextStyle getEmptyStateTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle getEmptyStateSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  // Shadows
  static List<BoxShadow> getCardShadow() {
    return const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.05),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ];
  }
}
