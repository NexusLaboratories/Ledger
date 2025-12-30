import 'package:flutter/material.dart';
import 'package:ledger/models/dashboard_widget.dart';
import 'package:ledger/components/ui/common/glass_container.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';

class BudgetProgressWidget extends StatefulWidget {
  final DashboardWidget widget;

  const BudgetProgressWidget({super.key, required this.widget});

  @override
  State<BudgetProgressWidget> createState() => _BudgetProgressWidgetState();
}

class _BudgetProgressWidgetState extends State<BudgetProgressWidget> {
  final BudgetService _budgetService = BudgetService();
  List<BudgetProgress> _progressList = [];
  bool _isLoading = true;
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currency = await UserPreferenceService.getDefaultCurrency();
      final budgets = await _budgetService.fetchBudgets('local');
      if (budgets.isEmpty) {
        setState(() {
          _isLoading = false;
          _progressList = [];
        });
        return;
      }

      final list = <BudgetProgress>[];
      for (final b in budgets) {
        final p = await _budgetService.calculateProgress(b);
        list.add(p);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _progressList = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_progressList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No budgets yet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._progressList.map((p) => _buildBudgetItem(p)),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(BudgetProgress p) {
    final percent = p.percent.clamp(0.0, 100.0);
    final Color progressColor;
    if (percent >= 100) {
      // Rustic deep red for budgets that are over 100%
      progressColor = const Color(0xFF7A2F1D);
    } else if (percent >= 90) {
      // Strong red for 90-99%
      progressColor = const Color(0xFFE53935);
    } else if (percent >= 80) {
      // Orange for 80-89%
      progressColor = const Color(0xFFFF6F00);
    } else {
      // Green for healthy budgets
      progressColor = const Color(0xFF43A047);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.budget.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(p.spent, _currency)} of ${CurrencyFormatter.format(p.budget.amount, _currency)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100.0).clamp(0.0, 1.0),
              color: progressColor,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
