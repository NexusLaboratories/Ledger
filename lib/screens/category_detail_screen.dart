import 'package:flutter/material.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/category_summary.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/models/category_node.dart';
import 'package:ledger/components/categories/category_card.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/modals/category_form_modal.dart';
import 'package:ledger/constants/tag_icons.dart';
import 'package:ledger/components/ui/common/glass_container.dart';
import 'package:ledger/screens/transaction_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final AbstractCategoryService? categoryService;
  final AbstractTransactionService? transactionService;
  const CategoryDetailScreen({
    super.key,
    required this.category,
    this.categoryService,
    this.transactionService,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late final AbstractCategoryService _categoryService;
  late final AbstractTransactionService _transactionService;
  final AccountService _accountService = AccountService();

  late Future<void> _loadFuture;
  List<model_transaction.Transaction> _transactions = [];
  Map<String, List<CategorySummary>> _categorySummaries = {};
  Map<String, String> _accountNames = {};
  String _dateFormatKey = DateFormats.defaultKey;
  String _currency = 'INR';
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _totalTransactions = 0;
  bool _descriptionExpanded = false;

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
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _categoryService = widget.categoryService ?? CategoryService();
    _transactionService = widget.transactionService ?? TransactionService();
    _loadDateFormat();
    _loadCurrency();
    DateFormatService.notifier.addListener(_onDateFormatChanged);
    _loadFuture = _loadData();
  }

  Future<void> _loadCurrency() async {
    final c = await UserPreferenceService.getDefaultCurrency();
    if (mounted) setState(() => _currency = c);
  }

  Future<void> _loadData() async {
    LoggerService.i('CategoryDetail: loading categories');
    final allCats = await _categoryService.fetchCategoriesForUser('local');
    LoggerService.i('CategoryDetail: fetched ${allCats.length} categories');

    final allSummaries = await _categoryService.getCategorySummaries('local');
    LoggerService.i('CategoryDetail: fetched ${allSummaries.length} summaries');

    final txs = await _transactionService.getAllTransactions();
    LoggerService.i('CategoryDetail: fetched ${txs.length} transactions');

    final accounts = await _accountService.fetchAccounts();
    LoggerService.i('CategoryDetail: fetched ${accounts.length} accounts');

    _accountNames = {
      for (final acc in accounts)
        if (acc != null) acc.id: acc.name,
    };

    final summaryMap = <String, List<CategorySummary>>{};
    for (final summary in allSummaries) {
      summaryMap.putIfAbsent(summary.id, () => []).add(summary);
    }

    final Map<String, List<String>> parentToChildren = {};
    for (final c in allCats) {
      if (c.parentCategoryId != null) {
        parentToChildren.putIfAbsent(c.parentCategoryId!, () => []).add(c.id);
      }
    }
    Set<String> getDescendants(String id) {
      final descendants = <String>{};
      final children = parentToChildren[id] ?? [];
      for (final child in children) {
        descendants.add(child);
        descendants.addAll(getDescendants(child));
      }
      return descendants;
    }

    final Set<String> ids = {widget.category.id}
      ..addAll(getDescendants(widget.category.id));
    final relevant = txs.where(
      (t) => t.categoryId != null && ids.contains(t.categoryId),
    );

    final nodes = buildCategoryNodeMap(allCats);

    // Calculate income and expense totals
    double incomeTotal = 0.0;
    double expenseTotal = 0.0;
    for (final tx in relevant) {
      if (tx.type == model_transaction.TransactionType.income) {
        incomeTotal += tx.amount;
      } else {
        expenseTotal += tx.amount;
      }
    }

    setState(() {
      _transactions = relevant.toList();
      _categorySummaries = summaryMap;
      _currentNode = nodes[widget.category.id];
      _totalIncome = incomeTotal;
      _totalExpense = expenseTotal;
      _totalTransactions = relevant.length;
    });
  }

  CategoryNode? _currentNode;

  Future<void> _showCategoryActions() async {
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
              title: const Text('Edit Category'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: CustomColors.negative),
              title: const Text('Delete Category'),
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
      await _editCategory();
    } else if (action == 'delete') {
      await _showDeleteConfirmation();
    }
  }

  Future<void> _editCategory() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormModal(existing: widget.category),
    );
    if (result == true && mounted) {
      // Refresh data after edit
      setState(() {
        _loadFuture = _loadData();
      });
    }
  }

  Future<void> _deleteCategory() async {
    await _categoryService.deleteCategory(widget.category.id);
    if (mounted) {
      Navigator.of(context).pop(true); // Return to categories screen
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${widget.category.name}"? This will remove the category from all transactions.',
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
      await _deleteCategory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showCategoryActions,
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
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Category Info Card
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF43A047,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.category.iconId != null
                                    ? (TagIcons.getIconById(
                                                widget.category.iconId!,
                                              ) ??
                                              TagIcons.defaultIcon)
                                          .icon
                                    : Icons.category,
                                color: const Color(0xFF43A047),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.category.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.category.description != null &&
                                      widget
                                          .category
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
                                        widget.category.description!,
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
                                    _totalTransactions.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
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
                if (_currentNode?.parent != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'PARENT',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CategoryCard(
                      key: Key(
                        'category-parent-${_currentNode!.parent!.category.id}',
                      ),
                      category: _currentNode!.parent!.category,
                      summaries:
                          _categorySummaries[_currentNode!
                              .parent!
                              .category
                              .id] ??
                          [],
                      hideAmount: true,
                      showChevron: false,
                      subtitle: null,
                      onTapCard: () async {
                        final parentNode = _currentNode!.parent!;
                        final result = await Navigator.of(context).push<bool?>(
                          MaterialPageRoute(
                            builder: (_) => CategoryDetailScreen(
                              category: parentNode.category,
                              categoryService: _categoryService,
                              transactionService: _transactionService,
                            ),
                          ),
                        );
                        if (result == true) _loadData();
                      },
                    ),
                  ),
                ],
                if (_currentNode != null &&
                    _currentNode!.children.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'CHILDREN (${_currentNode!.children.length})',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ..._currentNode!.children.map((childNode) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CategoryCard(
                        key: Key('category-node-${childNode.category.id}'),
                        category: childNode.category,
                        summaries:
                            _categorySummaries[childNode.category.id] ?? [],
                        amountKey: Key(
                          'category-amount-${childNode.category.id}',
                        ),
                        subtitle: childNode.category.description,
                        showChevron: false,
                        onTapCard: () async {
                          final result = await Navigator.of(context)
                              .push<bool?>(
                                MaterialPageRoute(
                                  builder: (_) => CategoryDetailScreen(
                                    category: childNode.category,
                                    categoryService: _categoryService,
                                    transactionService: _transactionService,
                                  ),
                                ),
                              );
                          if (result == true) _loadData();
                        },
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Text(
                    'TRANSACTIONS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'No transactions found for this category',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: _transactions.map((t) {
                          final accountName =
                              _accountNames[t.accountId] ?? 'Unknown';
                          return TransactionListItem(
                            transaction: t,
                            subtitle:
                                '$accountName • ${DateFormatter.formatWithKeyOrPattern(t.date, _dateFormatKey)}',
                            onTap: () async {
                              final result = await Navigator.of(context)
                                  .push<bool?>(
                                    MaterialPageRoute(
                                      builder: (_) => TransactionDetailScreen(
                                        transaction: t,
                                      ),
                                    ),
                                  );
                              if (result == true && mounted) {
                                await _loadData();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
