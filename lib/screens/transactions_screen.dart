// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/components/ui/dialogs/export_spreadsheet_dialog.dart';
import 'package:ledger/models/report_options.dart';
import 'package:ledger/modals/transaction_form_modal.dart';
import 'package:ledger/components/ui/dialogs/custom_dialog.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/modals/account_form_modal.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/utilities/transaction_grouping.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/screens/transaction_detail_screen.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/data_refresh_service.dart';

class TransactionsScreen extends StatefulWidget {
  final AbstractAccountService? accountService;
  final AbstractTransactionService? transactionService;
  const TransactionsScreen({
    super.key,
    this.accountService,
    this.transactionService,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final AbstractTransactionService _transactionService;
  late final AbstractAccountService _accountService;
  late Future<List<model_transaction.Transaction>> _transactionsFuture;
  Map<String, String> _accountNames = {};
  late final ScrollController _scrollController;
  String _currentTitle = 'Today';
  List<double> _sectionOffsets = [];
  List<MapEntry<String, List<model_transaction.Transaction>>> _sections = [];

  String _dateFormatKey = DateFormats.defaultKey;

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
    _accountService = widget.accountService ?? AccountService();
    _transactionService = widget.transactionService ?? TransactionService();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateCurrentTitle);
    _loadDateFormat();
    DateFormatService.notifier.addListener(_onDateFormatChanged);
    DataRefreshService().transactionsNotifier.addListener(_refresh);
    DataRefreshService().accountsNotifier.addListener(_refresh);
    _fetchData();
  }

  @override
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    DataRefreshService().transactionsNotifier.removeListener(_refresh);
    DataRefreshService().accountsNotifier.removeListener(_refresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchData() {
    _transactionsFuture = _transactionService.getAllTransactions();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await _accountService.fetchAccounts();
    setState(() {
      _accountNames = {
        for (final acc in accounts)
          if (acc != null) acc.id: acc.name,
      };
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _fetchData();
    });
    await _transactionsFuture;
  }

  void _updateCurrentTitle() {
    final offset = _scrollController.offset;
    int index = 0;
    for (int i = 0; i < _sectionOffsets.length; i++) {
      if (offset >= _sectionOffsets[i]) {
        index = i;
      } else {
        break;
      }
    }
    if (_sections.isNotEmpty && index < _sections.length) {
      final newTitle = _sections[index].key;
      if (newTitle != _currentTitle) {
        setState(() => _currentTitle = newTitle);
      }
    }
  }

  Future<void> _openSpreadsheetExport() async {
    // Open export dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ExportSpreadsheetDialog(initialOptions: ReportOptions()),
    );
    if (result == true) {
      // Optionally refresh after export
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomAppDrawer(),
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Export spreadsheet',
            icon: const Icon(Icons.grid_on),
            onPressed: _openSpreadsheetExport,
          ),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        icon: Icons.add,
        tooltip: 'Actions',
        menuOptions: [
          {
            'title': 'Create Transaction',
            'onTap': () async {
              // Ensure at least one account exists before creating a transaction
              final accounts = await _accountService.fetchAccounts();
              if (!mounted) return; // prevent use of context across async gap
              if (accounts.isEmpty) {
                final createAccount = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dc) => CustomDialog(
                    title: 'No Accounts',
                    content:
                        'You must create an account before creating a transaction.',
                    actions: [
                      CustomButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(dc).pop(false),
                      ),
                      CustomButton(
                        text: 'Create Account',
                        onPressed: () => Navigator.of(dc).pop(true),
                      ),
                    ],
                  ),
                );
                if (createAccount == true) {
                  if (!mounted) return;
                  final accountData =
                      await showModalBottomSheet<Map<String, String?>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext bc) =>
                            AccountFormModal(accountService: _accountService),
                      );
                  if (accountData == null) {
                    return; // user cancelled account creation
                  }
                  await _accountService.createAccount(
                    accountData['name']!,
                    accountData['description'],
                    currency: accountData['currency'],
                  );
                } else {
                  return; // user cancelled the No Accounts dialog
                }
              }
              if (!mounted) return;
              await showModalBottomSheet<Map<String, String?>>(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return TransactionFormModal();
                },
              );
              await _refresh();
            },
          },
        ],
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

            // Define the desired order of sections
            final sectionOrder = ['Today', 'This Week', 'This Month'];
            final sections =
                <MapEntry<String, List<model_transaction.Transaction>>>[];

            // Add ordered sections first (if they have content)
            for (final sectionName in sectionOrder) {
              if (grouped.containsKey(sectionName) &&
                  grouped[sectionName]!.isNotEmpty) {
                sections.add(MapEntry(sectionName, grouped[sectionName]!));
              }
            }

            // Add remaining sections (month/year sections)
            for (final entry in grouped.entries) {
              if (!sectionOrder.contains(entry.key) && entry.value.isNotEmpty) {
                sections.add(entry);
              }
            }

            _sections = sections;
            _sectionOffsets = [];
            double currentOffset = 0;
            const double headerHeight = 48.0;
            const double itemHeight = 80.0; // approximate
            for (final section in _sections) {
              _sectionOffsets.add(currentOffset);
              currentOffset += headerHeight + section.value.length * itemHeight;
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                for (final section in sections) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 2.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, idx) {
                        if (idx == 0) {
                          return Container(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              right: 12.0,
                            ),
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Text(
                                section.key,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        }
                        final t = section.value[idx - 1];
                        final accountName =
                            _accountNames[t.accountId] ?? 'Unknown';
                        return TransactionListItem(
                          transaction: t,
                          subtitle:
                              '$accountName • ${DateFormatter.formatWithKeyOrPattern(t.date, _dateFormatKey)}',
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    TransactionDetailScreen(transaction: t),
                              ),
                            );
                            if (result == true) {
                              await _refresh();
                            }
                          },
                        );
                      }, childCount: section.value.length + 1),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
