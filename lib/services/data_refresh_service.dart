import 'package:flutter/foundation.dart';

/// Service to notify screens when data changes occur in the database.
/// This ensures UI updates instantaneously when data is inserted, updated, or deleted.
class DataRefreshService {
  DataRefreshService._privateConstructor();
  static final DataRefreshService _instance =
      DataRefreshService._privateConstructor();
  factory DataRefreshService() => _instance;

  // ValueNotifiers for different data types
  final ValueNotifier<int> accountsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> transactionsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> categoriesNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> tagsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> budgetsNotifier = ValueNotifier<int>(0);

  /// Notify that accounts data has changed
  void notifyAccountsChanged() {
    accountsNotifier.value++;
  }

  /// Notify that transactions data has changed
  void notifyTransactionsChanged() {
    transactionsNotifier.value++;
  }

  /// Notify that categories data has changed
  void notifyCategoriesChanged() {
    categoriesNotifier.value++;
  }

  /// Notify that tags data has changed
  void notifyTagsChanged() {
    tagsNotifier.value++;
  }

  /// Notify that budgets data has changed
  void notifyBudgetsChanged() {
    budgetsNotifier.value++;
  }

  /// Dispose all notifiers (call this only when shutting down the app)
  void dispose() {
    accountsNotifier.dispose();
    transactionsNotifier.dispose();
    categoriesNotifier.dispose();
    tagsNotifier.dispose();
    budgetsNotifier.dispose();
  }
}
