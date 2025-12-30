import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/models/budget.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/constants/tag_icons.dart';

class BudgetFormModal extends StatefulWidget {
  final Budget? budget;
  final AbstractBudgetService? budgetService;
  final AbstractCategoryService? categoryService;

  const BudgetFormModal({
    super.key,
    this.budget,
    this.budgetService,
    this.categoryService,
  });

  @override
  State<BudgetFormModal> createState() => _BudgetFormModalState();
}

class _BudgetFormModalState extends State<BudgetFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  late AbstractBudgetService _budgetService;
  late AbstractCategoryService _categoryService;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  BudgetPeriod _period = BudgetPeriod.monthly;
  String? _selectedCategoryId;
  String? _selectedIconId;
  List<Category> _categories = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _budgetService = widget.budgetService ?? BudgetService();
    _categoryService = widget.categoryService ?? CategoryService();
    _loadCategories();
    if (widget.budget != null) {
      _nameController.text = widget.budget!.name;
      _amountController.text = widget.budget!.amount.toString();
      _period = widget.budget!.period;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _selectedCategoryId = widget.budget!.categoryId;
      _selectedIconId = widget.budget!.iconId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryService.fetchCategoriesForUser('local');
    setState(() => _categories = cats);
  }

  double? _parseAmount(String input) {
    String clean = input.trim();
    if (clean.isEmpty) return null;
    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf('.') > clean.lastIndexOf(',')) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (clean.contains(',')) {
      if (clean.indexOf(',') != clean.lastIndexOf(',')) {
        clean = clean.replaceAll(',', '');
      } else {
        final parts = clean.split(',');
        if (parts.last.length == 3) {
          clean = clean.replaceAll(',', '');
        } else {
          clean = clean.replaceAll(',', '.');
        }
      }
    }
    return double.tryParse(clean);
  }

  String _formatPeriod(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budget != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Budget' : 'Create Budget',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            // Icon picker
            InkWell(
              onTap: _showIconPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _selectedIconId != null
                            ? (TagIcons.getIconById(_selectedIconId!) ??
                                      TagIcons.defaultIcon)
                                  .icon
                            : Icons.category,
                        color: const Color(0xFF43A047),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedIconId != null
                            ? (TagIcons.getIconById(_selectedIconId!)?.name ??
                                  'Select Icon')
                            : 'Select Icon (Optional)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a budget name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                if (_parseAmount(v) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedCategoryId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All categories'),
                ),
                ..._categories.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BudgetPeriod>(
              decoration: const InputDecoration(
                labelText: 'Period',
                border: OutlineInputBorder(),
              ),
              initialValue: _period,
              items: BudgetPeriod.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(_formatPeriod(p)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _period = val);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStart,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Start: ${DateFormat.yMMMd().format(_startDate)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate == null
                          ? 'End: Not set (optional)'
                          : 'End: ${DateFormat.yMMMd().format(_endDate!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  child: CustomButton(
                    text: _saving
                        ? 'Saving...'
                        : (isEditing ? 'Update' : 'Create'),
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _save() async {
    LoggerService.i('BudgetFormModal: _save called');
    if (!_formKey.currentState!.validate()) {
      LoggerService.w('BudgetFormModal: Form validation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please correct the errors in the form'),
          ),
        );
      }
      return;
    }
    LoggerService.i('BudgetFormModal: Form validation passed');
    FocusScope.of(context).unfocus();
    final amount = _parseAmount(_amountController.text);
    if (amount == null) {
      LoggerService.e(
        'BudgetFormModal: Failed to parse amount from: ${_amountController.text}',
      );
      return;
    }
    LoggerService.i('BudgetFormModal: Parsed amount: $amount');
    final newBudget = Budget(
      id: widget.budget?.id,
      userId: 'local',
      name: _nameController.text.trim(),
      amount: amount,
      period: _period,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
      iconId: _selectedIconId,
    );
    LoggerService.i(
      'BudgetFormModal: Created budget object: ${newBudget.toString()}',
    );

    setState(() => _saving = true);
    try {
      if (widget.budget != null) {
        LoggerService.i('BudgetFormModal: Updating budget');
        await _budgetService.updateBudget(newBudget);
      } else {
        LoggerService.i('BudgetFormModal: Creating budget');
        await _budgetService.createBudget(newBudget);
      }
      LoggerService.i('BudgetFormModal: Budget service call successful');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Budget saved')));
        Navigator.of(context).pop(true);
      }
    } catch (e, s) {
      LoggerService.e('BudgetFormModal: Exception during save', e, s);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save budget: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: TagIcons.allIcons.length,
            itemBuilder: (context, index) {
              final tagIcon = TagIcons.allIcons[index];
              final isSelected = _selectedIconId == tagIcon.id;
              return InkWell(
                onTap: () {
                  setState(() => _selectedIconId = tagIcon.id);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF43A047)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? const Color(0xFF43A047).withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tagIcon.icon,
                        size: 28,
                        color: isSelected
                            ? const Color(0xFF43A047)
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tagIcon.name,
                        style: TextStyle(
                          fontSize: 8,
                          color: isSelected
                              ? const Color(0xFF43A047)
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedIconId = null);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
