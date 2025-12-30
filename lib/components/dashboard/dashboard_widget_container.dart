import 'package:flutter/material.dart';
import 'package:ledger/components/accounts/account_balances_widget.dart';
import 'package:ledger/components/activities/recent_activities_widget.dart';
import 'package:ledger/components/reports/spending_by_category_widget.dart';
import 'package:ledger/components/budgets/budget_progress_widget.dart';
import 'package:ledger/models/dashboard_widget.dart';

class DashboardWidgetContainer extends StatelessWidget {
  final DashboardWidget widget;
  final VoidCallback? onTap;
  final bool isDragging;

  const DashboardWidgetContainer({
    super.key,
    required this.widget,
    this.onTap,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return const SizedBox.shrink();
    }

    Widget child;
    switch (widget.type) {
      case WidgetType.recentTransactions:
        child = const RecentActivitiesWidget();
        break;
      case WidgetType.spendingByCategory:
        child = const SpendingByCategoryWidget();
        break;
      case WidgetType.accountBalances:
        child = const AccountBalancesWidget();
        break;
      case WidgetType.budgetProgress:
        child = BudgetProgressWidget(widget: widget);
        break;
    }

    return AnimatedOpacity(
      opacity: isDragging ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
