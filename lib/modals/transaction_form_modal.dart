import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/transaction_item_service.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/utilities/utilities.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/services/error_handler_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/presets/app_colors.dart';
import 'package:ledger/components/transactions/transaction_item_tile.dart';
import 'package:ledger/components/ui/dialogs/item_form_dialog.dart';
import 'package:ledger/constants/tag_icons.dart';

class TransactionFormModal extends StatefulWidget {
  final String? defaultAccountId;
  final AbstractTransactionService? transactionService;
  final AbstractTransactionItemService? itemsService;
  final AbstractAccountService? accountService;
  final AbstractCategoryService? categoryService;
  // Optional existing transaction to enable editing mode
  final Transaction? existing;
  const TransactionFormModal({
    super.key,
    this.defaultAccountId,
    this.transactionService,
    this.itemsService,
    this.accountService,
    this.categoryService,
    this.existing,
  });

  @override
  State<TransactionFormModal> createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends State<TransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late final AbstractTransactionService _transactionService =
      widget.transactionService ?? TransactionService();
  late final AbstractTransactionItemService _itemService =
      widget.itemsService ?? TransactionItemService();
  late final AbstractCategoryService _categoryService =
      widget.categoryService ?? CategoryService();
  late final AbstractTagService _tagService = TagService();
  bool _isSubmitting = false;
  String? _amountError;

  List<Account?> _accounts = [];
  String? _selectedAccountId;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<Tag> _tags = [];
  final List<String> _selectedTagIds = [];
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  final List<TransactionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadCategories();
    _loadTags();
    // If an existing transaction is provided, pre-fill fields for editing
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _amountController.text = e.amount.toString();
      _selectedAccountId = e.accountId;
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date;
      _selectedType = e.type;
      _selectedTagIds.clear();
      _selectedTagIds.addAll(e.tagIds);
      // Note: existing items are managed on the transaction detail screen
    }
  }

  Future<void> _loadAccounts() async {
    LoggerService.i('Loading accounts for transaction form...');
    try {
      final accountService = widget.accountService ?? AccountService();
      final accounts = await accountService.fetchAccounts();
      LoggerService.i('Accounts loaded: ${accounts.length}');
      setState(() {
        _accounts = accounts;
        if (_accounts.isNotEmpty) {
          _selectedAccountId = widget.defaultAccountId ?? _accounts.first!.id;
          LoggerService.i('Selected account: $_selectedAccountId');
        }
      });
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to load accounts for transaction form',
        e,
        stackTrace,
      );
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          'Failed to load accounts. Please try again.',
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    LoggerService.i('Loading categories for transaction form...');
    try {
      final cats = await _categoryService.fetchCategoriesForUser('local');
      LoggerService.i('Categories loaded: ${cats.length}');
      setState(() {
        _categories = cats;
        // Default category is null (no category selected)
        // _selectedCategoryId remains null unless editing existing transaction
      });
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to load categories for transaction form',
        e,
        stackTrace,
      );
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          'Failed to load categories. Please try again.',
        );
      }
    }
  }

  Future<void> _loadTags() async {
    LoggerService.i('Loading tags for transaction form...');
    try {
      final tags = await _tagService.fetchTagsForUser('local');
      LoggerService.i('Tags loaded: ${tags.length}');
      setState(() {
        _tags = tags;
      });
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to load tags for transaction form',
        e,
        stackTrace,
      );
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          'Failed to load tags. Please try again.',
        );
      }
    }
  }

  Color _getTagColor(Tag tag) {
    if (tag.color != null) {
      return Color(tag.color!);
    }
    // Generate a color based on tag name hash for consistency
    final hash = tag.name.hashCode;
    final colors = AppColors.tagPalette;
    return colors[hash.abs() % colors.length];
  }

  Future<void> _createNewTag(String tagName) async {
    if (tagName.trim().isEmpty) return;
    LoggerService.i('Creating new tag: "$tagName"');
    try {
      final newTag = Tag(
        id: Utilities.generateUuid(),
        userId: 'local',
        name: tagName.trim(),
      );
      await _tagService.createTag(newTag);
      LoggerService.i('Tag created successfully: ${newTag.id}');
      await _loadTags(); // Reload tags to get the new one
      if (mounted) {
        setState(() {
          _selectedTagIds.add(newTag.id);
          LoggerService.i('Tag selected: ${newTag.id}');
        });
      }
    } catch (e, stackTrace) {
      LoggerService.e('Failed to create tag: "$tagName"', e, stackTrace);
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          ErrorHandlerService.getErrorMessage(e),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _openItemForm({TransactionItem? existing}) async {
    final result = await showDialog<TransactionItem?>(
      context: context,
      builder: (context) => ItemFormDialog(existingItem: existing),
    );

    if (result != null) {
      final id = existing?.id ?? Utilities.generateUuid();
      final item = TransactionItem(
        id: id,
        transactionId: '',
        name: result.name,
        quantity: result.quantity,
        price: result.price,
      );

      if (existing == null) {
        setState(() {
          _items.add(item);
          _amountError = null;
        });
      } else {
        final idx = _items.indexWhere((i) => i.id == existing.id);
        if (idx >= 0) {
          setState(() {
            _items[idx] = item;
            _amountError = null;
          });
        }
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      LoggerService.i('Transaction form validation failed');
      return;
    }

    LoggerService.i(
      'Submitting transaction form | Mode: ${widget.existing == null ? "Create" : "Edit"} | Type: $_selectedType | Account: $_selectedAccountId',
    );

    setState(() {
      _isSubmitting = true;
    });

    // Clear previous amount error
    setState(() {
      _amountError = null;
    });

    // Additional validation: if there are items and the transaction is an expense,
    // ensure sum(item.quantity * price) equals the entered amount (within a small tolerance).
    try {
      final enteredAmount = double.parse(_amountController.text);
      LoggerService.i(
        'Transaction details | Amount: \$$enteredAmount | Items: ${_items.length} | Tags: ${_selectedTagIds.length}',
      );
      if (_items.isNotEmpty && _selectedType == TransactionType.expense) {
        final itemsTotal = Utilities.calculateItemsTotal(_items);
        if ((itemsTotal - enteredAmount).abs() > 0.01) {
          LoggerService.w(
            'Items total mismatch | Items: \$$itemsTotal | Entered: \$$enteredAmount',
          );
          setState(() {
            _amountError =
                'Sum of items (${itemsTotal.toStringAsFixed(2)}) does not match the total amount (${enteredAmount.toStringAsFixed(2)}).';
          });
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }
      if (widget.existing == null) {
        final txId = Utilities.generateUuid();
        LoggerService.i('Creating new transaction: $txId');
        await _transactionService.createTransaction(
          id: txId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          amount: double.parse(_amountController.text),
          accountId: _selectedAccountId!,
          tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds,
          date: _selectedDate,
          type: _selectedType,
        );

        // Persist each item with the created transaction id
        if (_items.isNotEmpty) {
          LoggerService.i('Persisting ${_items.length} transaction items...');
        }
        for (final item in _items) {
          final newItem = TransactionItem(
            id: item.id,
            transactionId: txId,
            name: item.name,
            quantity: item.quantity,
            price: item.price,
          );
          await _itemService.createItem(newItem);
        }

        LoggerService.i('Transaction created successfully: $txId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction created successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing transaction
        LoggerService.i(
          'Updating existing transaction: ${widget.existing!.id}',
        );
        final updated = widget.existing!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _selectedCategoryId,
          amount: double.parse(_amountController.text),
          accountId: _selectedAccountId!,
          tagIds: _selectedTagIds.isEmpty ? null : _selectedTagIds,
          date: _selectedDate,
          type: _selectedType,
        );

        await _transactionService.updateTransaction(updated);

        LoggerService.i(
          'Transaction updated successfully: ${widget.existing!.id}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to submit transaction form | Title: ${_titleController.text} | Amount: ${_amountController.text}',
        e,
        stackTrace,
      );
      LoggerService.e('Failed to save transaction', e, stackTrace);
      if (mounted) {
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(label: 'Retry', onPressed: _handleSubmit),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showTagSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Tags'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final newTagController = TextEditingController();
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: newTagController,
                              decoration: const InputDecoration(
                                labelText: 'New tag name',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final name = newTagController.text.trim();
                              if (name.isEmpty) return;
                              await _createNewTag(name);
                              newTagController.clear();
                              setDialogState(() {});
                            },
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        final selected = _selectedTagIds.contains(tag.id);
                        final tagColor = _getTagColor(tag);
                        final tagIcon = TagIcons.getIconById(tag.iconId);

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              setState(() {
                                if (selected) {
                                  _selectedTagIds.removeWhere(
                                    (id) => id == tag.id,
                                  );
                                } else {
                                  _selectedTagIds.add(tag.id);
                                }
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? tagColor.withAlpha(38)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? tagColor
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tagIcon != null) ...[
                                  Icon(
                                    tagIcon.icon,
                                    size: 16,
                                    color: selected
                                        ? tagColor
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (selected && tagIcon == null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: tagColor,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: tagColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                Text(
                                  tag.name,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14,
                                    color: selected ? tagColor : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 28,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal header with handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.existing == null
                              ? 'Create Transaction'
                              : 'Edit Transaction',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Transaction Type (moved to top)
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.remove_circle_outline, size: 18),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.add_circle_outline, size: 18),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                        _amountError = null;
                      });
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title Field (moved after type)
                  TextFormField(
                    key: const Key('transaction-title'),
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Grocery shopping',
                      prefixIcon: Icon(
                        Icons.title,
                        color: Theme.of(context).primaryColor,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Account Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      key: const Key('transaction-account-dropdown'),
                      initialValue: _selectedAccountId,
                      items: _accounts.map((account) {
                        return DropdownMenuItem<String>(
                          key: Key('account-item-${account!.name}'),
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Account',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker (moved above category)
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat.yMMMMd().format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field (move to after title to preserve field indexes used by tests)
                  TextFormField(
                    key: const Key('transaction-description'),
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Add notes about this transaction',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Icon(
                          Icons.notes,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Field (placed right after Date)
                  TextFormField(
                    key: const Key('transaction-amount'),
                    controller: _amountController,
                    onChanged: (s) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Theme.of(context).primaryColor,
                      ),
                      errorText: _amountError,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount.';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    child: DropdownButtonFormField<String?>(
                      key: const Key('transaction-category-dropdown'),
                      initialValue: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No category'),
                        ),
                        ..._categories.map((c) {
                          return DropdownMenuItem<String?>(
                            key: Key('category-item-${c.name}'),
                            value: c.id,
                            child: Text(c.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Category (optional)',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // moved Description above Amount earlier to keep tests stable
                  const SizedBox(height: 20),

                  // Tags Section (compact with popup)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tags',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                if (_selectedTagIds.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_selectedTagIds.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _showTagSelectionDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedTagIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedTagIds.map((tagId) {
                              final tag = _tags.firstWhere(
                                (t) => t.id == tagId,
                              );
                              final tagColor = _getTagColor(tag);
                              final tagIcon = TagIcons.getIconById(tag.iconId);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: tagColor.withAlpha(38),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: tagColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (tagIcon != null) ...[
                                      Icon(
                                        tagIcon.icon,
                                        size: 14,
                                        color: tagColor,
                                      ),
                                      const SizedBox(width: 6),
                                    ] else ...[
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: tagColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      tag.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: tagColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Items Section
                  if (_selectedType == TransactionType.expense) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Items',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (_items.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_items.length}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              TextButton.icon(
                                key: const Key('items-add-button'),
                                onPressed: () => _openItemForm(),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_items.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...(_items.map(
                              (it) => CompactTransactionItemTile(
                                item: it,
                                onEdit: () => _openItemForm(existing: it),
                                onDelete: () => setState(() {
                                  _items.removeWhere((i) => i.id == it.id);
                                  _amountError = null;
                                }),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          variant: ButtonVariant.destructive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: _isSubmitting
                              ? (widget.existing == null
                                    ? 'Creating...'
                                    : 'Updating...')
                              : (widget.existing == null ? 'Create' : 'Update'),
                          onPressed: _isSubmitting ? null : _handleSubmit,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
