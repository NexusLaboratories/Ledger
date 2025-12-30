import 'package:flutter/material.dart';
import 'package:ledger/components/accounts/account_card.dart';
import 'package:ledger/components/ui/layout/custom_app_bar.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/modals/account_form_modal.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/screens/account_transactions_screen.dart';
import 'package:ledger/services/data_refresh_service.dart';

class AccountsScreen extends StatefulWidget {
  final AbstractAccountService? accountService;
  const AccountsScreen({super.key, this.accountService});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final AbstractAccountService _accountService;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _accountService = widget.accountService ?? AccountService();

    // Listen to accounts changes
    DataRefreshService().accountsNotifier.addListener(_onAccountsChanged);
  }

  @override
  void dispose() {
    DataRefreshService().accountsNotifier.removeListener(_onAccountsChanged);
    super.dispose();
  }

  void _onAccountsChanged() {
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  void _showCreateAccountModal() {
    showModalBottomSheet<Map<String, String?>>(
      context: context,
      builder: (context) => AccountFormModal(accountService: _accountService),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(20)),
      ),
    ).then((accountData) {
      if (accountData != null) {
        _accountService
            .createAccount(
              accountData['name']!,
              accountData['description'],
              currency: accountData['currency'],
              iconId: accountData['iconId'],
            )
            .then((_) {
              setState(() {});
            });
      }
    });
  }

  void _deleteAccount(String accountId) {
    _accountService.deleteAccount(accountId).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Accounts'),
      drawer: const CustomAppDrawer(),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: _showCreateAccountModal,
      ),
      body: FutureBuilder(
        key: ValueKey(_refreshKey),
        future: _accountService.fetchAccounts(forceRefetch: true),
        builder:
            (BuildContext context, AsyncSnapshot<List<Account?>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final accounts = snapshot.data ?? [];
              final validAccounts = accounts.where((a) => a != null).toList();

              if (validAccounts.isEmpty) {
                return const Center(child: Text('No accounts found.'));
              }

              // No per-card keys required, keep simple

              return ListView.builder(
                itemCount: validAccounts.length,
                itemBuilder: (context, index) {
                  return AccountCard(
                    account: validAccounts[index]!,
                    onDelete: () => _deleteAccount(validAccounts[index]!.id),
                    // onDeactivate no longer used; longPress handles popup
                    onTapCard: () async {
                      final changed = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AccountTransactionsScreen(
                            account: validAccounts[index]!,
                          ),
                        ),
                      );
                      if (changed == true) setState(() {});
                    },
                    onEdit: () async {
                      final account = validAccounts[index]!;
                      final accountData =
                          await showModalBottomSheet<Map<String, String?>>(
                            context: context,
                            builder: (context) => AccountFormModal(
                              account: account,
                              accountService: _accountService,
                            ),
                            isScrollControlled: true,
                          );
                      if (accountData != null) {
                        final updated = account.copyWith(
                          name: accountData['name'],
                          description: accountData['description'],
                          currency: accountData['currency'],
                          iconId: accountData['iconId'],
                        );
                        await _accountService.updateAccount(updated);
                        setState(() {});
                      }
                    },
                  );
                },
              );
            },
      ),
    );
  }
}
