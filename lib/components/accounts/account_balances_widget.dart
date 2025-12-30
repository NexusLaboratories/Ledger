import 'package:flutter/material.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/components/ui/common/glass_container.dart';

class AccountBalancesWidget extends StatefulWidget {
  const AccountBalancesWidget({super.key});

  @override
  State<AccountBalancesWidget> createState() => _AccountBalancesWidgetState();
}

class _AccountBalancesWidgetState extends State<AccountBalancesWidget> {
  final AccountService _accountService = AccountService();
  List<Account?> _accounts = [];
  bool _isLoading = true;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _accounts = await _accountService.fetchAccounts(forceRefetch: true);
      final defaultCurrency = await UserPreferenceService.getDefaultCurrency();
      _currency = defaultCurrency;
    } finally {
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
            'Account Balances',
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
          else if (_accounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No accounts yet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._accounts.whereType<Account>().map(
              (account) => _buildAccountItem(account),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountItem(Account account) {
    final amount = CurrencyFormatter.format(account.balance, _currency);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (account.description != null &&
                    account.description!.isNotEmpty)
                  Text(
                    account.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: account.balance >= 0
                  ? CustomColors.positive
                  : CustomColors.negative,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
