import 'package:flutter/material.dart';
import 'package:ledger/models/budget.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/constants/tag_icons.dart';

class BudgetCard extends StatefulWidget {
  final Budget budget;
  final BudgetProgress? progress;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    this.progress,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await UserPreferenceService.getDefaultCurrency();
    if (mounted) {
      setState(() => _currency = currency);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spent = widget.progress?.spent ?? 0.0;
    final amount = widget.budget.amount;
    final percent =
        widget.progress?.percent ??
        ((amount > 0) ? (spent / amount) * 100.0 : 0.0);
    final percentClamped = percent.clamp(0.0, 200.0);

    // Budget status colors based on percentage thresholds
    final Color progressColor;
    if (percent >= 100) {
      progressColor = const Color(0xFFB71C1C); // Blood red
    } else if (percent >= 90) {
      progressColor = const Color(0xFFFF6F00); // Orange
    } else if (percent >= 80) {
      progressColor = const Color(0xFFFDD835); // Yellow
    } else {
      progressColor = CustomColors.budgetHealthy; // Green
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.budget.iconId != null
                          ? (TagIcons.getIconById(widget.budget.iconId!) ??
                                    TagIcons.defaultIcon)
                                .icon
                          : Icons.savings,
                      color: const Color(0xFF43A047),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.budget.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${CurrencyFormatter.format(spent, _currency)} of ${CurrencyFormatter.format(amount, _currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (percentClamped / 100.0),
                            color: progressColor,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withAlpha(40),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit?.call();
                      if (v == 'delete') widget.onDelete?.call();
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
