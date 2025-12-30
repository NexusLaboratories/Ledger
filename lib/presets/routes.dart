import 'package:flutter/material.dart';
import 'package:ledger/screens/accounts_screen.dart';
import 'package:ledger/screens/transactions_screen.dart';
import 'package:ledger/screens/categories_screen.dart';
import 'package:ledger/screens/tags_screen.dart';
import 'package:ledger/screens/reports_screen.dart';
import 'package:ledger/screens/budgets_screen.dart';
import 'package:ledger/screens/ai_chat_screen.dart';

import 'package:ledger/screens/dashboard_screen.dart';
import 'package:ledger/screens/settings_screen.dart';
import 'package:ledger/screens/tutorial_screen.dart';

Map<String, WidgetBuilder> get appRoutes => {
  RouteNames.dashboard: (context) => const DashboardScreen(),
  RouteNames.settings: (context) => const SettingsScreen(),
  RouteNames.accounts: (context) => const AccountsScreen(),
  RouteNames.transactions: (context) => const TransactionsScreen(),
  RouteNames.categories: (context) => const CategoriesScreen(),
  RouteNames.tags: (context) => const TagsScreen(),
  RouteNames.budgets: (context) => const BudgetsScreen(),
  RouteNames.reports: (context) => const ReportsScreen(),
  RouteNames.aiChat: (context) => const AiChatScreen(),
  RouteNames.tutorial: (context) => const TutorialScreen(),
};

String get initialRoute => RouteNames.dashboard;

abstract class RouteNames {
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String tags = '/tags';
  static const String budgets = '/budgets';
  static const String reports = '/reports';
  static const String aiChat = '/ai-chat';
  static const String tutorial = '/tutorial';
}
