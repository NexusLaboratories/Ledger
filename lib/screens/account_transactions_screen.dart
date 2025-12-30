// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/modals/transaction_form_modal.dart';
import 'package:ledger/utilities/transaction_grouping.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/components/settings/section_header_delegate.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/screens/transaction_detail_screen.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/modals/account_form_modal.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/constants/tag_icons.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/components/ui/common/glass_container.dart';

class AccountTransactionsScreen extends StatefulWidget {
  final Account account;

  const AccountTransactionsScreen({super.key, required this.account});

  @override
  State<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState extends State<AccountTransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  late Future<List<model_transaction.Transaction>> _transactionsFuture;
  bool _dataChanged = false;
  bool _descriptionExpanded = false;

  String _dateFormatKey = '';
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _currentBalance = 0.0;
  int _totalTransactions = 0;

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
    _fetchTransactions();
    _loadDateFormat();
    DateFormatService.notifier.addListener(_onDateFormatChanged);
  }

  @override
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    super.dispose();
  }

  void _fetchTransactions() {
    _transactionsFuture = _transactionService
        .getTransactionsForAccount(widget.account.id)
        .then((transactions) {
          double income = 0.0;
          double expense = 0.0;

          for (final tx in transactions) {
            if (tx.type == model_transaction.TransactionType.income) {
              income += tx.amount;
            } else {
              expense += tx.amount;
            }
          }

          setState(() {
            _totalIncome = income;
            _totalExpense = expense;
            _currentBalance = income - expense;
            _totalTransactions = transactions.length;
          });

          return transactions;
        });
  }

  Future<void> _refresh() async {
    setState(() {
      _fetchTransactions();
    });
    await _transactionsFuture;
  }

  Future<void> _showAccountActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Edit Account'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: CustomColors.negative),
              title: const Text('Delete Account'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );

    if (action == 'edit') {
      await _editAccount();
    } else if (action == 'delete') {
      await _showDeleteConfirmation();
    }
  }

  Future<void> _editAccount() async {
    final accountData = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AccountFormModal(
        account: widget.account,
        accountService: _accountService,
      ),
    );
    if (accountData != null) {
      final updated = widget.account.copyWith(
        name: accountData['name'],
        description: accountData['description'],
        currency: accountData['currency'],
        iconId: accountData['iconId'],
      );
      await _accountService.updateAccount(updated);
      setState(() {
        _dataChanged = true;
      });
    }
  }

  Future<void> _deleteAccount() async {
    await _accountService.deleteAccount(widget.account.id);
    if (mounted) {
      Navigator.of(context).pop(true); // Return to accounts screen
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${widget.account.name}"? This will also delete all associated transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: CustomColors.negative),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_dataChanged);
        return false; // we popped the screen ourselves
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 30.0),
            onPressed: () {
              Navigator.of(context).pop(_dataChanged);
            },
          ),
          title: Text(widget.account.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showAccountActions,
              tooltip: 'More options',
            ),
          ],
        ),
        floatingActionButton: CustomFloatingActionButton(
          icon: Icons.add,
          onPressed: () async {
            await showModalBottomSheet<Map<String, String?>>(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return TransactionFormModal(
                  defaultAccountId: widget.account.id,
                );
              },
            );
            // When modal closes, refresh the list and mark that data changed
            await _refresh();
            setState(() => _dataChanged = true);
          },
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<model_transaction.Transaction>>(
            future: _transactionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final transactions = snapshot.data ?? [];
              if (transactions.isEmpty) {
                return const Center(child: Text('No transactions found.'));
              }
              final grouped = TransactionGrouping.group(transactions);
              final sections = grouped.entries.toList();
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF43A047,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      widget.account.iconId != null
                                          ? (TagIcons.getIconById(
                                                      widget.account.iconId!,
                                                    ) ??
                                                    TagIcons.defaultIcon)
                                                .icon
                                          : Icons.account_balance_wallet,
                                      color: const Color(0xFF43A047),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.account.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (widget.account.description !=
                                                null &&
                                            widget
                                                .account
                                                .description!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _descriptionExpanded =
                                                    !_descriptionExpanded;
                                              });
                                            },
                                            child: Text(
                                              widget.account.description!,
                                              maxLines: _descriptionExpanded
                                                  ? null
                                                  : 2,
                                              overflow: _descriptionExpanded
                                                  ? null
                                                  : TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Balance',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(
                                            _currentBalance,
                                            widget.account.currency,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: _currentBalance >= 0
                                                    ? CustomColors.positive
                                                    : CustomColors.negative,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Transactions',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _totalTransactions.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Income',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(
                                            _totalIncome,
                                            widget.account.currency,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: CustomColors.positive,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expense',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          CurrencyFormatter.format(
                                            _totalExpense,
                                            widget.account.currency,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: CustomColors.negative,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final section in sections) ...[
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: SectionHeaderDelegate(title: section.key),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: section.value.map((t) {
                              return TransactionListItem(
                                transaction: t,
                                subtitle: DateFormatter.formatWithKeyOrPattern(
                                  t.date,
                                  _dateFormatKey,
                                ),
                                onTap: () async {
                                  final result = await Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TransactionDetailScreen(
                                                transaction: t,
                                              ),
                                        ),
                                      );
                                  if (result == true) {
                                    await _refresh();
                                    setState(() => _dataChanged = true);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
