import 'package:flutter/material.dart';
import 'package:ledger/models/activity.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/components/ui/common/glass_container.dart';
import 'package:ledger/components/activities/activity_item.dart';

class RecentActivitiesWidget extends StatefulWidget {
  const RecentActivitiesWidget({super.key});

  @override
  State<RecentActivitiesWidget> createState() => _RecentActivitiesWidgetState();
}

class _RecentActivitiesWidgetState extends State<RecentActivitiesWidget> {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  List<Activity> _recentActivities = [];
  bool _isLoading = true;
  String _currency = 'USD';
  Map<String, String> _accountNames = {};

  String _dateFormatKey = '';

  Future<void> _loadDateFormat() async {
    final k = await UserPreferenceService.getDateFormat();
    if (mounted) setState(() => _dateFormatKey = k);
  }

  void _onDateFormatChanged() {
    if (mounted) {
      setState(() => _dateFormatKey = DateFormatService.notifier.value);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDateFormat();
    DateFormatService.notifier.addListener(_onDateFormatChanged);
    _loadData();
  }

  @override
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      _currency = await UserPreferenceService.getDefaultCurrency();
      final accounts = await _accountService.fetchAccounts();
      _accountNames = {
        for (final acc in accounts)
          if (acc != null) acc.id: acc.name,
      };

      final transactions = await _transactionService.getAllTransactions();

      // Convert transactions to activities
      final transactionActivities = transactions.map((transaction) {
        final amount = CurrencyFormatter.format(
          transaction.amount.abs(),
          _currency,
        );
        final accountName =
            _accountNames[transaction.accountId] ?? 'Unknown Account';
        final isExpense = transaction.type == TransactionType.expense;
        return Activity(
          type: ActivityType.transaction,
          title: transaction.title,
          description: accountName,
          timestamp: transaction.date,
          metadata: {
            'transactionId': transaction.id,
            'isExpense': isExpense.toString(),
            'amount': amount,
          },
        );
      }).toList();

      // Sort activities by timestamp descending
      transactionActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _recentActivities = transactionActivities.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
            'Recent Activities',
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
          else if (_recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No activities yet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._recentActivities.map(
              (activity) => ActivityItem(
                activity: activity,
                dateFormatKey: _dateFormatKey,
              ),
            ),
        ],
      ),
    );
  }
}
