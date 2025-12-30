import 'package:ledger/models/dashboard_widget.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/models/widget_layout.dart';
import 'package:ledger/services/user_preference_service.dart';

abstract class AbstractDashboardService {
  Future<List<DashboardWidget>> getDashboardWidgets();
  Future<List<WidgetLayout>> getDashboardLayouts();
  Future<void> saveDashboardWidgets(List<DashboardWidget> widgets);
  Future<void> saveDashboardLayouts(List<WidgetLayout> layouts);
  Future<void> updateWidgetLayout(String widgetId, WidgetLayout layout);
  Future<void> reorderWidgets(List<String> widgetIds);
  Future<void> initializeDefaultDashboard();
}

class DashboardService implements AbstractDashboardService {
  @override
  Future<List<DashboardWidget>> getDashboardWidgets() async {
    final widgets = await UserPreferenceService.getDashboardWidgets();
    if (widgets.isEmpty) {
      await initializeDefaultDashboard();
      return await UserPreferenceService.getDashboardWidgets();
    }

    // If budgets exist but dashboard doesn't include the budget widget, insert it
    final hasBudgetWidget = widgets.any(
      (w) => w.type == WidgetType.budgetProgress,
    );
    if (!hasBudgetWidget) {
      try {
        final budgetService = BudgetService();
        final budgets = await budgetService.fetchBudgets('local');
        if (budgets.isNotEmpty) {
          final insertIndex = widgets.indexWhere(
            (w) => w.type == WidgetType.accountBalances,
          );
          final newWidgets = List<DashboardWidget>.from(widgets);
          final budgetWidget = DashboardWidget(type: WidgetType.budgetProgress);
          if (insertIndex != -1) {
            newWidgets.insert(insertIndex, budgetWidget);
          } else {
            newWidgets.add(budgetWidget);
          }
          await saveDashboardWidgets(newWidgets);
          return newWidgets;
        }
      } catch (_) {
        // ignore failures and return existing widgets
      }
    }

    return widgets;
  }

  @override
  Future<List<WidgetLayout>> getDashboardLayouts() async {
    final layouts = await UserPreferenceService.getDashboardLayouts();
    if (layouts.isEmpty) {
      await initializeDefaultDashboard();
      return await UserPreferenceService.getDashboardLayouts();
    }
    return layouts;
  }

  @override
  Future<void> saveDashboardWidgets(List<DashboardWidget> widgets) async {
    await UserPreferenceService.setDashboardWidgets(widgets: widgets);
  }

  @override
  Future<void> saveDashboardLayouts(List<WidgetLayout> layouts) async {
    await UserPreferenceService.setDashboardLayouts(layouts: layouts);
  }

  @override
  Future<void> updateWidgetLayout(String widgetId, WidgetLayout layout) async {
    final layouts = await getDashboardLayouts();
    final index = layouts.indexWhere((l) => l.widgetId == widgetId);
    if (index != -1) {
      layouts[index] = layout;
    } else {
      layouts.add(layout);
    }
    await saveDashboardLayouts(layouts);
  }

  @override
  Future<void> reorderWidgets(List<String> widgetIds) async {
    final widgets = await getDashboardWidgets();
    final layouts = await getDashboardLayouts();

    // Reorder widgets based on the new order
    final reorderedWidgets = <DashboardWidget>[];
    final reorderedLayouts = <WidgetLayout>[];

    for (final widgetId in widgetIds) {
      final widget = widgets.firstWhere((w) => w.id == widgetId);
      final layout = layouts.firstWhere((l) => l.widgetId == widgetId);

      reorderedWidgets.add(widget);
      reorderedLayouts.add(layout);
    }

    // Update row/col positions for layouts
    for (int i = 0; i < reorderedLayouts.length; i++) {
      reorderedLayouts[i] = reorderedLayouts[i].copyWith(
        row: i ~/ 2,
        col: i % 2,
      );
    }

    await saveDashboardWidgets(reorderedWidgets);
    await saveDashboardLayouts(reorderedLayouts);
  }

  @override
  Future<void> initializeDefaultDashboard() async {
    final defaultWidgets = [
      DashboardWidget(type: WidgetType.recentTransactions),
      DashboardWidget(type: WidgetType.budgetProgress),
      DashboardWidget(type: WidgetType.accountBalances),
      DashboardWidget(type: WidgetType.spendingByCategory),
    ];

    final defaultLayouts = [
      WidgetLayout(widgetId: defaultWidgets[0].id, row: 0, col: 0),
      WidgetLayout(widgetId: defaultWidgets[1].id, row: 1, col: 0),
      WidgetLayout(widgetId: defaultWidgets[2].id, row: 2, col: 0),
      WidgetLayout(widgetId: defaultWidgets[3].id, row: 3, col: 0),
    ];

    await saveDashboardWidgets(defaultWidgets);
    await saveDashboardLayouts(defaultLayouts);
  }
}
