import 'package:flutter/material.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/presets/theme.dart';
import 'package:ledger/presets/app_colors.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/presets/date_formats.dart';

class TransactionHeroCard extends StatelessWidget {
  final model_transaction.Transaction transaction;
  final String currency;
  final VoidCallback? onLongPress;
  final String dateFormatKey;

  const TransactionHeroCard({
    super.key,
    required this.transaction,
    required this.currency,
    this.onLongPress,
    this.dateFormatKey = DateFormats.defaultKey,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == model_transaction.TransactionType.income;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isIncome
                ? AppColors.incomeGradient
                : AppColors.expenseGradient,
          ),
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: (isIncome ? CustomColors.positive : CustomColors.negative)
                  .withAlpha(76),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t.type.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATE',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withAlpha(178),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatWithKeyOrPattern(
                          t.date,
                          dateFormatKey,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(t.amount, currency),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      color: Theme.of(context).colorScheme.onPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
