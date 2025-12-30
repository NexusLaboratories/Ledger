import 'package:flutter/material.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/app_colors.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';

import 'package:ledger/screens/transaction_detail_screen.dart';

/// A single transaction list row. Tapping the card navigates to the
/// transaction detail screen (unless `onTap` callback is provided).
class TransactionListItem extends StatefulWidget {
  final model_transaction.Transaction transaction;
  final VoidCallback? onTap;
  final String? currency;
  final String? subtitle;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.currency,
    this.subtitle,
    this.onTap,
  });

  @override
  State<TransactionListItem> createState() => _TransactionListItemState();
}

class _TransactionListItemState extends State<TransactionListItem> {
  String _currency = 'INR';
  String _dateFormatKey = DateFormats.defaultKey;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _loadDateFormat();
  }

  @override
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    super.dispose();
  }

  Future<void> _loadDateFormat() async {
    final key = await UserPreferenceService.getDateFormat();
    if (mounted) setState(() => _dateFormatKey = key);
    // Listen for changes
    DateFormatService.notifier.addListener(_onDateFormatChanged);
  }

  Future<void> _loadCurrency() async {
    final c =
        widget.currency ?? await UserPreferenceService.getDefaultCurrency();
    if (mounted) setState(() => _currency = c);
  }

  void _onDateFormatChanged() {
    if (mounted) {
      setState(() => _dateFormatKey = DateFormatService.notifier.value);
    }
  }

  void _defaultOnTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TransactionDetailScreen(transaction: widget.transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final amountText = CurrencyFormatter.format(t.amount, _currency);

    return ListTile(
      key: Key('transaction-${t.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.type == model_transaction.TransactionType.income
              ? AppColors.incomeBg
              : AppColors.expenseBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: t.type == model_transaction.TransactionType.income
                ? AppColors.success
                : AppColors.error,
            shape: BoxShape.circle,
          ),
          child: Icon(
            t.type == model_transaction.TransactionType.income
                ? Icons.add
                : Icons.remove,
            color: Colors.white,
            size: 10,
          ),
        ),
      ),
      title: Text(
        t.title,
        key: Key('transaction-title-${t.id}'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        widget.subtitle ??
            '${t.type.name[0].toUpperCase()}${t.type.name.substring(1)} • ${DateFormatter.formatWithKeyOrPattern(t.date, _dateFormatKey)}',
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Text(
        amountText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: t.type == model_transaction.TransactionType.income
              ? AppColors.success
              : AppColors.error,
        ),
      ),
      onTap: widget.onTap ?? () => _defaultOnTap(context),
    );
  }
}
