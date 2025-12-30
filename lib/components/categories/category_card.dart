import 'package:flutter/material.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/category_summary.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/constants/tag_icons.dart';

/// CategoryCard styled similarly to AccountCard but without delete option.
class CategoryCard extends StatelessWidget {
  final Category category;
  final List<CategorySummary> summaries;
  final String? subtitle;
  final VoidCallback? onTapCard;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Key? amountKey;
  final bool hideAmount;
  final bool showChevron;

  const CategoryCard({
    super.key,
    required this.category,
    this.summaries = const [],
    this.onTapCard,
    this.onEdit,
    this.onDelete,
    this.subtitle,
    this.amountKey,
    this.hideAmount = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTapCard,
          onLongPress: () async {
            await showModalBottomSheet(
              context: context,
              builder: (context) => SafeArea(
                child: Wrap(
                  children: [
                    if (onEdit != null)
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit'),
                        onTap: () {
                          Navigator.of(context).pop();
                          onEdit?.call();
                        },
                      ),
                    if (onDelete != null)
                      ListTile(
                        leading: const Icon(
                          Icons.delete,
                          color: CustomColors.negative,
                        ),
                        title: const Text('Delete'),
                        onTap: () {
                          Navigator.of(context).pop();
                          onDelete?.call();
                        },
                      ),
                  ],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.iconId != null
                        ? (TagIcons.getIconById(category.iconId!) ??
                                  TagIcons.defaultIcon)
                              .icon
                        : Icons.category,
                    color: const Color(0xFF43A047),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((subtitle ?? category.description) != null &&
                          (subtitle ?? category.description)!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle ?? category.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: CustomColors.textGreyDark),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!hideAmount) ...[
                      if (summaries.isEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '-',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: CustomColors.positive,
                                  ),
                            ),
                            Text(
                              '-',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: CustomColors.negative,
                                  ),
                            ),
                          ],
                        )
                      else
                        ...summaries.map(
                          (summary) => Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (summary.incomeAmount > 0)
                                Text(
                                  CurrencyFormatter.format(
                                    summary.incomeAmount,
                                    summary.currency,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: CustomColors.positive,
                                      ),
                                ),
                              Text(
                                CurrencyFormatter.format(
                                  summary.expenseAmount,
                                  summary.currency,
                                ),
                                key: amountKey,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: CustomColors.negative,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      const SizedBox(width: 0),
                    ],
                    if (showChevron) ...[
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right,
                        color: CustomColors.textGreyLight,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
