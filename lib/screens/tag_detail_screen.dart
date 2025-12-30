import 'package:flutter/material.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/transaction_tag_service.dart';
import 'package:ledger/models/transaction_tag.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/presets/app_colors.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/modals/tag_form_modal.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/constants/tag_icons.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/components/ui/common/glass_container.dart';

class TagDetailScreen extends StatefulWidget {
  final Tag tag;
  final AbstractTransactionService? transactionService;
  final AbstractTransactionTagService? transactionTagService;
  final AbstractAccountService? accountService;

  const TagDetailScreen({
    super.key,
    required this.tag,
    this.transactionService,
    this.transactionTagService,
    this.accountService,
  });

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  late final AbstractTransactionService _transactionService;
  late final AbstractTransactionTagService _transactionTagService;
  late final AbstractAccountService _accountService;
  final TagService _tagService = TagService();

  late Future<void> _loadFuture;
  List<model_transaction.Transaction> _transactions = [];
  Map<String, String> _accountNames = {};
  String _currency = 'INR';
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _transactionService = widget.transactionService ?? TransactionService();
    _transactionTagService =
        widget.transactionTagService ?? TransactionTagService();
    _accountService = widget.accountService ?? AccountService();
    _loadCurrency();
    _loadFuture = _loadData();
  }

  Future<void> _loadCurrency() async {
    final c = await UserPreferenceService.getDefaultCurrency();
    if (mounted) setState(() => _currency = c);
  }

  Color _getTagColor() {
    if (widget.tag.color != null) {
      return Color(widget.tag.color!);
    }
    // Generate a color based on tag name hash for consistency
    final hash = widget.tag.name.hashCode;
    final colors = AppColors.tagPalette;
    return colors[hash.abs() % colors.length];
  }

  Future<void> _loadData() async {
    // Load all transactions
    final allTransactions = await _transactionService.getAllTransactions();

    // Load all transaction tags
    final allTransactionTags = <TransactionTag>[];
    for (final tx in allTransactions) {
      final tags = await _transactionTagService.fetchTagsForTransaction(tx.id);
      allTransactionTags.addAll(tags);
    }

    // Filter transactions that have this tag
    final transactionIdsWithTag = allTransactionTags
        .where((tt) => tt.tagId == widget.tag.id)
        .map((tt) => tt.transactionId)
        .toSet();

    final filteredTransactions = allTransactions
        .where((tx) => transactionIdsWithTag.contains(tx.id))
        .toList();

    // Sort by date descending
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    double income = 0.0;
    double expense = 0.0;
    for (final tx in filteredTransactions) {
      if (tx.type == model_transaction.TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    // Load account names and currencies
    final accounts = await _accountService.fetchAccounts();
    final accountNamesMap = <String, String>{};
    for (final acc in accounts) {
      if (acc != null) {
        accountNamesMap[acc.id] = acc.name;
      }
    }

    setState(() {
      _transactions = filteredTransactions;
      _accountNames = accountNamesMap;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  Future<void> _showTagActions() async {
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
              title: const Text('Edit Tag'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: CustomColors.negative),
              title: const Text('Delete Tag'),
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
      await _editTag();
    } else if (action == 'delete') {
      await _showDeleteConfirmation();
    }
  }

  Future<void> _editTag() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagFormModal(existing: widget.tag),
    );
    if (result == true && mounted) {
      // Refresh data after edit
      setState(() {
        _loadFuture = _loadData();
      });
    }
  }

  Future<void> _deleteTag() async {
    await _tagService.deleteTag(widget.tag.id);
    if (mounted) {
      Navigator.of(context).pop(true); // Return to tags screen
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete "${widget.tag.name}"? This will remove the tag from all transactions.',
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
      await _deleteTag();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _getTagColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showTagActions,
            tooltip: 'More options',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: CustomColors.negative,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snap.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadFuture = _loadData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadFuture = _loadData();
              });
              await _loadFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tag Info Card
                Card(
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
                                color: tagColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.tag.iconId != null
                                    ? (TagIcons.getIconById(
                                                widget.tag.iconId!,
                                              ) ??
                                              TagIcons.defaultIcon)
                                          .icon
                                    : Icons.label,
                                color: tagColor,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.tag.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.tag.description != null &&
                                      widget.tag.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _descriptionExpanded =
                                              !_descriptionExpanded;
                                        });
                                      },
                                      child: Text(
                                        widget.tag.description!,
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
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Transactions',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _transactions.length.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Income',
                                    style: Theme.of(context).textTheme.bodySmall
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
                                      _currency,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expense',
                                    style: Theme.of(context).textTheme.bodySmall
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
                                      _currency,
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
                const SizedBox(height: 24),

                // Transactions List
                if (_transactions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.label_outline,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions with this tag',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: _transactions.map((transaction) {
                        final accountName =
                            _accountNames[transaction.accountId] ?? 'Unknown';
                        return TransactionListItem(
                          transaction: transaction,
                          subtitle: accountName,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
