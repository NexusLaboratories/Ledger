import 'package:flutter/material.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/transaction_item_service.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/utilities.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/components/ui/common/glass_container.dart';
import 'package:ledger/modals/transaction_form_modal.dart';
import 'package:ledger/components/transactions/transaction_hero_card.dart';
import 'package:ledger/components/transactions/transaction_detail_row.dart';
import 'package:ledger/components/ui/common/tag_chip_display.dart';
import 'package:ledger/components/ui/common/info_card.dart';
import 'package:ledger/components/ui/common/icon_container.dart';
import 'package:ledger/components/transactions/transaction_item_tile.dart';
import 'package:ledger/components/ui/dialogs/item_form_dialog.dart';

class TransactionDetailScreen extends StatefulWidget {
  final model_transaction.Transaction transaction;
  final TransactionService? transactionService;
  final TransactionItemService? itemService;
  final AccountService? accountService;
  final CategoryService? categoryService;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.transactionService,
    this.itemService,
    this.accountService,
    this.categoryService,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  // Note: use injected services via _transactionServiceImpl, _accountServiceImpl, _categoryServiceImpl
  late final TransactionService _transactionServiceImpl;
  late final CategoryService _categoryServiceImpl;
  String _currency = 'USD';
  String _dateFormatKey = DateFormats.defaultKey;

  Future<void> _loadDateFormat() async {
    final key = await UserPreferenceService.getDateFormat();
    if (mounted) setState(() => _dateFormatKey = key);
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

  late final TransactionItemService _itemService;
  List<TransactionItem> _originalItems = [];
  List<TransactionItem> _editedItems = [];
  // We keep a synthetic 'others' id so we can track whether it's been edited
  static const _othersSyntheticIdPrefix = '__others__';
  bool _loadingItems = false;
  String? _categoryName;

  // Tag names for this transaction (fetched on init)
  List<String> _tagNames = [];

  late model_transaction.Transaction _transaction;
  bool _hasUnsavedChanges = false;

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _transactionServiceImpl.deleteTransaction(widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _showTransactionActions() async {
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
              title: const Text('Edit'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: CustomColors.negative),
              title: const Text('Delete'),
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
      // Open the transaction form in edit mode
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TransactionFormModal(
          existing: _transaction,
          transactionService: _transactionServiceImpl,
          itemsService: _itemService,
        ),
      );

      // Refresh transaction and items after edit
      final tx = await _transactionServiceImpl.getTransactionById(
        widget.transaction.id,
      );
      if (tx != null) {
        setState(() {
          _transaction = tx;
          _tagNames = List.from(tx.tagNames);
        });
        await _loadCategory();
      }
      await _loadItems();
    } else if (action == 'delete') {
      _confirmDelete();
    }
  }

  @override
  void initState() {
    super.initState();

    _transactionServiceImpl = widget.transactionService ?? TransactionService();

    _itemService = widget.itemService ?? TransactionItemService();

    _accountServiceInit();

    _transaction = widget.transaction;

    _loadCurrency();

    _loadDateFormat();

    // listen for date format changes
    DateFormatService.notifier.addListener(_onDateFormatChanged);

    _loadItems();

    _loadCategory();

    // initialize tags from the passed transaction immediately, then fetch
    // fresh tag names from the service so they always show up in the UI.
    _tagNames = List.from(widget.transaction.tagNames);
    _loadTags();
  }

  void _accountServiceInit() {
    _categoryServiceImpl = widget.categoryService ?? CategoryService();
  }

  Future<void> _loadCategory() async {
    final categoryId = _transaction.categoryId;

    if (categoryId == null) {
      setState(() => _categoryName = null);
      return;
    }

    final cat = await _categoryServiceImpl.getCategoryById(categoryId);

    if (cat != null) {
      setState(() => _categoryName = cat.name);
    }
  }

  Future<void> _loadTags() async {
    try {
      final tx = await _transactionServiceImpl.getTransactionById(
        _transaction.id,
      );
      if (tx != null) {
        setState(() => _tagNames = List.from(tx.tagNames));
      }
    } catch (e) {
      // ignore errors and keep existing tag names (if any)
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);

    try {
      final items = await _itemService.fetchItemsForTransaction(
        widget.transaction.id,
      );

      // Keep both original and edited copies separate; edits are staged until Save

      setState(() {
        _originalItems = List.from(items);

        _editedItems = items.map((it) => it).toList();

        // Ensure a synthetic "Others" item is present if needed

        _updateOthersInEditedItems();

        _hasUnsavedChanges = false;
      });
    } finally {
      setState(() => _loadingItems = false);
    }
  }

  void _updateOthersInEditedItems() {
    // compute remainder excluding any synthetic others that may be present

    final baseTotal = Utilities.calculateItemsTotal(
      _editedItems
          .where((it) => !it.id.startsWith(_othersSyntheticIdPrefix))
          .toList(),
    );

    final rem = (_transaction.amount - baseTotal).clamp(0.0, double.infinity);

    final idx = _editedItems.indexWhere(
      (it) => it.id.startsWith(_othersSyntheticIdPrefix),
    );

    // Only show a synthetic remainder when there is at least one user-entered item
    if (rem > 0.0 && baseTotal > 0.0) {
      final others = TransactionItem(
        id: idx >= 0
            ? _editedItems[idx].id
            : '$_othersSyntheticIdPrefix${Utilities.generateUuid()}',
        transactionId: widget.transaction.id,
        // make the synthetic item clearly labelled to avoid colliding with a real item named "Others"
        name: 'Remainder',
        quantity: 1,
        price: rem,
      );

      if (idx >= 0) {
        _editedItems[idx] = others;
      } else {
        _editedItems.add(others);
      }
    } else {
      if (idx >= 0) _editedItems.removeAt(idx);
    }
  }

  Future<void> _openItemForm({TransactionItem? existing}) async {
    final result = await showDialog<TransactionItem?>(
      context: context,
      builder: (context) => ItemFormDialog(existingItem: existing),
    );

    if (result != null) {
      // Regenerate ID if this was a synthetic "others" item
      final id =
          (existing != null && existing.id.startsWith(_othersSyntheticIdPrefix))
          ? Utilities.generateUuid()
          : (existing?.id ?? Utilities.generateUuid());

      final item = TransactionItem(
        id: id,
        transactionId: widget.transaction.id,
        name: result.name,
        quantity: result.quantity,
        price: result.price,
      );

      setState(() {
        // add or replace in edited items only
        final idx = _editedItems.indexWhere((it) => it.id == existing?.id);

        if (idx >= 0) {
          _editedItems[idx] = item;
        } else {
          _editedItems.add(item);
        }

        _hasUnsavedChanges = !_listsEqual(_originalItems, _editedItems);
      });
    }
  }

  bool _listsEqual(List<TransactionItem> a, List<TransactionItem> b) {
    final fa = a
        .where((it) => !it.id.startsWith(_othersSyntheticIdPrefix))
        .toList();

    final fb = b
        .where((it) => !it.id.startsWith(_othersSyntheticIdPrefix))
        .toList();

    if (fa.length != fb.length) return false;

    for (final it in fa) {
      final other = fb.firstWhere(
        (x) => x.id == it.id,

        orElse: () => TransactionItem(id: '', transactionId: '', name: ''),
      );

      if (other.id == '') return false;

      if (other.name != it.name) return false;

      if ((other.quantity ?? 0) != (it.quantity ?? 0)) return false;

      if ((other.price ?? 0) != (it.price ?? 0)) return false;
    }

    return true;
  }

  double _editedItemsTotal() => Utilities.calculateItemsTotal(
    _editedItems
        .where((it) => !it.id.startsWith(_othersSyntheticIdPrefix))
        .toList(),
  );

  double _remainder() =>
      (_transaction.amount - _editedItemsTotal()).clamp(0.0, double.infinity);

  Future<void> _saveEditedItems() async {
    // compute diffs: deletes, creates, updates

    final origIds = _originalItems.map((e) => e.id).toSet();

    final editIds = _editedItems.map((e) => e.id).toSet();

    final toDelete = _originalItems
        .where((it) => !editIds.contains(it.id))
        .toList();

    // Do not persist synthetic 'others' items that were auto-generated

    final toCreate = _editedItems
        .where(
          (it) =>
              !origIds.contains(it.id) &&
              !it.id.startsWith(_othersSyntheticIdPrefix),
        )
        .toList();

    final toMaybeUpdate = _editedItems
        .where((it) => origIds.contains(it.id))
        .toList();

    for (final d in toDelete) {
      await _itemService.deleteItem(d.id);
    }

    for (final c in toCreate) {
      await _itemService.createItem(c);
    }

    for (final up in toMaybeUpdate) {
      final orig = _originalItems.firstWhere((o) => o.id == up.id);

      if (orig.name != up.name ||
          (orig.quantity ?? 0) != (up.quantity ?? 0) ||
          (orig.price ?? 0) != (up.price ?? 0)) {
        await _itemService.updateItem(up);
      }
    }

    await _loadItems();
  }

  Future<void> _loadCurrency() async {
    // With multi-currency removed, simply use the user's selected default
    // currency for formatting amounts.
    final defaultCurrency = await UserPreferenceService.getDefaultCurrency();
    setState(() => _currency = defaultCurrency);
  }

  @override
  Widget build(BuildContext context) {
    final t = _transaction;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text('Transaction'),

        elevation: 0,

        backgroundColor: Colors.transparent,

        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),

            tooltip: 'More',

            onPressed: _showTransactionActions,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Hero Transaction Card
            TransactionHeroCard(
              transaction: t,
              currency: _currency,
              onLongPress: _showTransactionActions,
              dateFormatKey: _dateFormatKey,
            ),

            const SizedBox(height: 24),

            // Warning for zero amount
            if (_transaction.amount == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InfoCard.banner(
                  message:
                      'Transaction amount is 0 — edit the transaction amount to add items.',
                  variant: InfoCardVariant.warning,
                ),
              ),

            // Details Section
            Text(
              'DETAILS',

              style: TextStyle(
                fontSize: 12,

                fontWeight: FontWeight.w700,

                letterSpacing: 1.5,

                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            GlassContainer(
              padding: const EdgeInsets.all(0),
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              child: Container(
                width: double.infinity,

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
                      TransactionDetailRow(
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: _categoryName ?? 'None',
                      ),

                      const Divider(height: 24),

                      // Tags (always visible; show "None" when no tags)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconContainer(
                            icon: Icons.tag_rounded,
                            size: IconContainerSize.medium,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tags',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TagChipDisplay(tagNames: _tagNames),
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

            const SizedBox(height: 32),

            // Items Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.start,

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Text(
                  'ITEMS',

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: FontWeight.w700,

                    letterSpacing: 1.5,

                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Items List
            _loadingItems
                ? Container(
                    padding: const EdgeInsets.all(40),

                    alignment: Alignment.center,

                    child: const CircularProgressIndicator(),
                  )
                : _editedItems.isEmpty
                ? Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(32),

                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,

                      borderRadius: BorderRadius.circular(16),

                      border: Border.all(
                        color: isDark
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      ),
                    ),

                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,

                          size: 48,

                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'No items found.',

                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,

                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _editedItems.map((item) {
                      final isOthers = item.id.startsWith(
                        _othersSyntheticIdPrefix,
                      );

                      return TransactionItemTile(
                        item: item,
                        currency: _currency,
                        isOthers: isOthers,
                        onEdit: () => _openItemForm(existing: item),
                        onDelete: () async {
                          setState(() {
                            _editedItems.removeWhere((it) => it.id == item.id);

                            _updateOthersInEditedItems();

                            // If any original item was removed, that's an unsaved change
                            final anyOriginalMissing = _originalItems.any(
                              (o) => !_editedItems.any((e) => e.id == o.id),
                            );

                            _hasUnsavedChanges =
                                !_listsEqual(_originalItems, _editedItems) ||
                                anyOriginalMissing;
                          });
                        },
                      );
                    }).toList(),
                  ),

            // Remainder virtual item (shown only when user has added at least one item)
            if (!_loadingItems &&
                _remainder() > 0.0 &&
                _editedItems.any(
                  (it) => !it.id.startsWith(_othersSyntheticIdPrefix),
                )) ...[
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CustomColors.textGreyDark.withAlpha(127),

                      CustomColors.textGreyDark.withAlpha(200),
                    ],
                  ),

                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Icon(
                        Icons.more_horiz_rounded,

                        size: 20,

                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(178),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Remainder',
                            key: const Key('remainder-header'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            'Remainder of transaction',

                            style: TextStyle(
                              fontSize: 12,

                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      CurrencyFormatter.format(_remainder(), _currency),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),

                      onPressed: () {
                        final idx = _editedItems.indexWhere(
                          (it) => it.id.startsWith(_othersSyntheticIdPrefix),
                        );

                        if (idx >= 0) {
                          _openItemForm(existing: _editedItems[idx]);
                        }
                      },

                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(178),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Wrap(
              spacing: 12,

              runSpacing: 12,

              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,

                    foregroundColor: Theme.of(context).colorScheme.onPrimary,

                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,

                    disabledForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,

                      vertical: 14,
                    ),

                    elevation: 0,
                  ),

                  onPressed: _remainder() <= 0 ? null : () => _openItemForm(),

                  icon: const Icon(Icons.add_rounded, size: 20),

                  label: const Text(
                    'Add Item',

                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),

                if (_hasUnsavedChanges) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.positive,

                      foregroundColor: Theme.of(context).colorScheme.onPrimary,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,

                        vertical: 14,
                      ),

                      elevation: 0,
                    ),

                    onPressed: () async {
                      await _saveEditedItems();

                      setState(() => _hasUnsavedChanges = false);
                    },

                    icon: const Icon(Icons.save_outlined, size: 20),

                    label: const Text(
                      'Save Changes',

                      style: TextStyle(
                        fontSize: 15,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomColors.negative,

                      side: BorderSide(color: CustomColors.negative),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,

                        vertical: 14,
                      ),
                    ),

                    onPressed: () async {
                      await _loadItems();

                      setState(() => _hasUnsavedChanges = false);
                    },

                    icon: const Icon(Icons.close_rounded, size: 20),

                    label: const Text(
                      'Discard',

                      style: TextStyle(
                        fontSize: 15,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
