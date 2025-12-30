import 'package:flutter/material.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/components/ui/common/icon_container.dart';

/// A reusable tile for displaying transaction items
class TransactionItemTile extends StatelessWidget {
  final TransactionItem item;
  final String currency;
  final bool isOthers;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TransactionItemTile({
    super.key,
    required this.item,
    required this.currency,
    this.isOthers = false,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOthers
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOthers
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            IconContainer(
              icon: isOthers
                  ? Icons.more_horiz_rounded
                  : Icons.shopping_bag_outlined,
              color: Theme.of(context).primaryColor,
              iconSize: 20,
              padding: 10,
              borderRadius: 12,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (item.quantity != null || item.price != null)
                    const SizedBox(height: 4),
                  if (item.quantity != null || item.price != null)
                    Text(
                      [
                        if (item.quantity != null) 'Qty: ${item.quantity}',
                        if (item.price != null)
                          '@ ${CurrencyFormatter.format(item.price!, currency)}',
                      ].join('  •  '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(
                    (item.price ?? 0) * (item.quantity ?? 1),
                    currency,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (showActions) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                          color: Theme.of(context).primaryColor,
                        ),
                      if (onEdit != null && onDelete != null)
                        const SizedBox(width: 8),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onDelete,
                          color: Colors.red,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact version of the transaction item tile for forms
class CompactTransactionItemTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CompactTransactionItemTile({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (item.quantity != null || item.price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (item.quantity != null) 'Qty: ${item.quantity}',
                        if (item.price != null) 'Price: ${item.price}',
                      ].join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
          if (onEdit != null && onDelete != null) const SizedBox(width: 4),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red,
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withAlpha(25),
              ),
            ),
        ],
      ),
    );
  }
}
