import 'package:flutter/material.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/constants/tag_icons.dart';

/// Shared, canonical AccountCard component used across the app.
class AccountCard extends StatefulWidget {
  final Account account;
  final VoidCallback? onDelete;
  final VoidCallback? onTapCard;
  final VoidCallback? onEdit;

  const AccountCard({
    super.key,
    required this.account,
    this.onDelete,
    this.onTapCard,
    this.onEdit,
  });

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  String _currency = 'INR';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await UserPreferenceService.getDefaultCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = widget.account.balance >= 0
        ? CustomColors.positive
        : CustomColors.negative;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTapCard,
          onLongPress: () async {
            await showModalBottomSheet(
              context: context,
              builder: (context) => SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit'),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onEdit?.call();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete,
                        color: CustomColors.negative,
                      ),
                      title: const Text('Delete'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _confirmDelete(context);
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
                    widget.account.iconId != null
                        ? (TagIcons.getIconById(widget.account.iconId!) ??
                                  TagIcons.defaultIcon)
                              .icon
                        : Icons.account_balance_wallet,
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
                        widget.account.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.account.description != null &&
                          widget.account.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.account.description!,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currency,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(
                        widget.account.balance,
                        _currency,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: amountColor,
                      ),
                    ),
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
