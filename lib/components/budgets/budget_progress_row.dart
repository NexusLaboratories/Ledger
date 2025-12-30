import 'package:flutter/material.dart';
import 'package:ledger/presets/app_theme_extension.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/budget_service.dart';

class BudgetProgressRow extends StatelessWidget {
  final BudgetProgress progress;
  final String currency;

  const BudgetProgressRow({
    super.key,
    required this.progress,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percent = progress.percent.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${progress.budget.name} • ${CurrencyFormatter.format(progress.budget.amount, currency)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
          minHeight: 8,
          backgroundColor: colors.grey200,
          valueColor: AlwaysStoppedAnimation<Color>(
            percent >= 100
                ? const Color(0xFFB71C1C) // Blood red
                : percent >= 90
                ? const Color(0xFFFF6F00) // Orange
                : percent >= 80
                ? const Color(0xFFFDD835) // Yellow
                : colors.budgetHealthy, // Green
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${percent.toStringAsFixed(1)}% used',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
