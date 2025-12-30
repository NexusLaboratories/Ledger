import 'package:flutter/material.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/presets/theme.dart';

class CategoryChildTile extends StatelessWidget {
  final Category category;
  final double? amount;
  final VoidCallback? onTap;
  final String? currency;
  final Key? tileKey;

  const CategoryChildTile({
    super.key,
    required this.category,
    this.amount,
    this.onTap,
    this.currency,
    this.tileKey,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = amount != null
        ? CurrencyFormatter.format(amount!, currency ?? 'USD')
        : '-';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: tileKey ?? Key('category-child-${category.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.02),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(217),
                child: Text(
                  category.name.isNotEmpty ? category.name[0] : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amountText,
                key: Key('category-amount-${category.id}'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: CustomColors.negative,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: CustomColors.textGreyLight),
            ],
          ),
        ),
      ),
    );
  }
}
