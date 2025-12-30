import 'package:flutter/material.dart';
import 'package:ledger/models/report_options.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/components/ui/dialogs/filter_selection_dialog.dart';

class ReportCustomizationModal extends StatefulWidget {
  final ReportOptions initial;
  const ReportCustomizationModal({
    super.key,
    this.initial = const ReportOptions(),
  });

  @override
  State<ReportCustomizationModal> createState() =>
      _ReportCustomizationModalState();
}

class _ReportCustomizationModalState extends State<ReportCustomizationModal> {
  late ReportOptions _opts;
  final AccountService _accountService = AccountService();
  final CategoryService _categoryService = CategoryService();
  final TagService _tagService = TagService();
  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<Tag> _tags = [];
  bool _loading = true;
  int _loadedCount = 0;
  Set<String> _selectedAccountIds = {};
  Set<String> _selectedCategoryIds = {};
  bool _categoryIncludeMode = false;
  Set<String> _selectedTagIds = {};
  bool _tagIncludeMode = false;

  @override
  void initState() {
    super.initState();
    _opts = widget.initial;
    _selectedAccountIds = Set.from(_opts.accountIds);
    _selectedCategoryIds = Set.from(_opts.categoryIds);
    _categoryIncludeMode = _opts.categoryIncludeMode;
    _selectedTagIds = Set.from(_opts.tagIds);
    _tagIncludeMode = _opts.tagIncludeMode;
    _loadAccounts();
    _loadCategories();
    _loadTags();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountService.fetchAccounts();
      setState(() {
        _accounts = accounts.whereType<Account>().toList();
        // If no accounts selected, select all by default
        if (_selectedAccountIds.isEmpty && _accounts.isNotEmpty) {
          _selectedAccountIds = _accounts.map((a) => a.id).toSet();
          _opts = _opts.copyWith(accountIds: _selectedAccountIds.toList());
        }
        _checkLoadingComplete();
      });
    } catch (e) {
      _checkLoadingComplete();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.fetchCategoriesForUser('local');
      setState(() {
        _categories = categories;
        // Select all categories by default if none selected
        if (_selectedCategoryIds.isEmpty && _categories.isNotEmpty) {
          _selectedCategoryIds = {
            'uncategorised',
            ..._categories.map((c) => c.id),
          }.toSet();
          _categoryIncludeMode = true;
          _opts = _opts.copyWith(
            categoryIds: _selectedCategoryIds.toList(),
            categoryIncludeMode: true,
          );
        }
        _checkLoadingComplete();
      });
    } catch (e) {
      _checkLoadingComplete();
    }
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _tagService.fetchTagsForUser('local');
      setState(() {
        _tags = tags;
        // Select all tags by default if none selected
        if (_selectedTagIds.isEmpty && _tags.isNotEmpty) {
          _selectedTagIds = {'untagged', ..._tags.map((t) => t.id)}.toSet();
          _tagIncludeMode = true;
          _opts = _opts.copyWith(
            tagIds: _selectedTagIds.toList(),
            tagIncludeMode: true,
          );
        }
        _checkLoadingComplete();
      });
    } catch (e) {
      _checkLoadingComplete();
    }
  }

  void _checkLoadingComplete() {
    _loadedCount++;
    // Mark loading as false when all three sources are loaded
    if (_loadedCount >= 3) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int _countTopLevelItems(Set<String> selectedIds, bool isCategory) {
    if (isCategory) {
      // Count only categories that are selected and don't have a selected parent
      return selectedIds.where((id) {
        final cat = _categories.where((c) => c.id == id).firstOrNull;
        if (cat == null) return false;
        // If this category has a parent that's also selected, don't count it
        if (cat.parentCategoryId != null &&
            selectedIds.contains(cat.parentCategoryId)) {
          return false;
        }
        return true;
      }).length;
    } else {
      // For tags, just count all (no hierarchy)
      return selectedIds.length;
    }
  }

  Set<String> _getAllDescendants(String categoryId) {
    final descendants = <String>{};
    final children = _categories.where((c) => c.parentCategoryId == categoryId);
    for (final child in children) {
      descendants.add(child.id);
      descendants.addAll(_getAllDescendants(child.id));
    }
    return descendants;
  }

  int _getCategoryDepth(Category category) {
    int depth = 0;
    var currentId = category.parentCategoryId;
    while (currentId != null) {
      depth++;
      final parent = _categories.where((c) => c.id == currentId).firstOrNull;
      if (parent == null) break;
      currentId = parent.parentCategoryId;
    }
    return depth;
  }

  List<Category> _sortCategoriesHierarchically() {
    final sorted = <Category>[];
    final processed = <String>{};

    void addCategoryAndChildren(Category category) {
      if (processed.contains(category.id)) return;
      processed.add(category.id);
      sorted.add(category);

      // Add children immediately after parent
      final children =
          _categories.where((c) => c.parentCategoryId == category.id).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      for (final child in children) {
        addCategoryAndChildren(child);
      }
    }

    // Start with root categories (no parent)
    final rootCategories =
        _categories.where((c) => c.parentCategoryId == null).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    for (final root in rootCategories) {
      addCategoryAndChildren(root);
    }

    return sorted;
  }

  Future<void> _openCategoryFilter() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => FilterSelectionDialog(
          title: 'Category Filter',
          items: [
            // Add Uncategorised option at the top
            FilterItem(
              id: 'uncategorised',
              name: 'Uncategorised',
              subtitle: 'Transactions without a category',
              depth: 0,
            ),
            // Add all actual categories
            ..._sortCategoriesHierarchically().map(
              (c) => FilterItem(
                id: c.id,
                name: c.name,
                subtitle: c.description,
                depth: _getCategoryDepth(c),
                parentId: c.parentCategoryId,
                childIds: _getAllDescendants(c.id),
              ),
            ),
          ],
          selectedIds: _selectedCategoryIds,
          includeMode: _categoryIncludeMode,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryIds = Set.from(result['selectedIds'] as List);
        _categoryIncludeMode = result['includeMode'] as bool;
        _opts = _opts.copyWith(
          categoryIds: _selectedCategoryIds.toList(),
          categoryIncludeMode: _categoryIncludeMode,
        );
      });
    }
  }

  Future<void> _openTagFilter() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => FilterSelectionDialog(
          title: 'Tag Filter',
          items: [
            // Add Untagged option at the top
            FilterItem(
              id: 'untagged',
              name: 'Untagged',
              subtitle: 'Transactions without any tags',
              depth: 0,
            ),
            // Add all actual tags
            ..._tags.map(
              (t) =>
                  FilterItem(id: t.id, name: t.name, subtitle: t.description),
            ),
          ],
          selectedIds: _selectedTagIds,
          includeMode: _tagIncludeMode,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTagIds = Set.from(result['selectedIds'] as List);
        _tagIncludeMode = result['includeMode'] as bool;
        _opts = _opts.copyWith(
          tagIds: _selectedTagIds.toList(),
          tagIncludeMode: _tagIncludeMode,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Report'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period
              const Text(
                'Period',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ListTile(
                title: const Text('Current Month'),
                // ignore: deprecated_member_use
                leading: Radio<String>(
                  value: 'current_month',
                  // ignore: deprecated_member_use
                  groupValue: _opts.period,
                  // ignore: deprecated_member_use
                  onChanged: (v) =>
                      setState(() => _opts = _opts.copyWith(period: v)),
                ),
              ),
              ListTile(
                title: const Text('Current Year'),
                // ignore: deprecated_member_use
                leading: Radio<String>(
                  value: 'current_year',
                  // ignore: deprecated_member_use
                  groupValue: _opts.period,
                  // ignore: deprecated_member_use
                  onChanged: (v) =>
                      setState(() => _opts = _opts.copyWith(period: v)),
                ),
              ),
              ListTile(
                title: const Text('All Time'),
                // ignore: deprecated_member_use
                leading: Radio<String>(
                  value: 'all_time',
                  // ignore: deprecated_member_use
                  groupValue: _opts.period,
                  // ignore: deprecated_member_use
                  onChanged: (v) =>
                      setState(() => _opts = _opts.copyWith(period: v)),
                ),
              ),
              ListTile(
                title: const Text('Custom Date Range'),
                // ignore: deprecated_member_use
                leading: Radio<String>(
                  value: 'custom',
                  // ignore: deprecated_member_use
                  groupValue: _opts.period,
                  // ignore: deprecated_member_use
                  onChanged: (v) =>
                      setState(() => _opts = _opts.copyWith(period: v)),
                ),
              ),
              if (_opts.period == 'custom') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _opts.customStartDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _opts = _opts.copyWith(customStartDate: picked);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _opts.customStartDate == null
                              ? 'Select Start Date'
                              : 'Start: ${_opts.customStartDate!.day}/${_opts.customStartDate!.month}/${_opts.customStartDate!.year}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _opts.customEndDate ?? DateTime.now(),
                            firstDate: _opts.customStartDate ?? DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _opts = _opts.copyWith(customEndDate: picked);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _opts.customEndDate == null
                              ? 'Select End Date'
                              : 'End: ${_opts.customEndDate!.day}/${_opts.customEndDate!.month}/${_opts.customEndDate!.year}',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
              const Divider(),
              // Accounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accounts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedAccountIds = _accounts
                                .map((a) => a.id)
                                .toSet();
                            _opts = _opts.copyWith(
                              accountIds: _selectedAccountIds.toList(),
                            );
                          });
                        },
                        child: const Text('All'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedAccountIds.clear();
                            _opts = _opts.copyWith(accountIds: []);
                          });
                        },
                        child: const Text('None'),
                      ),
                    ],
                  ),
                ],
              ),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No accounts found'),
                )
              else
                ..._accounts.map(
                  (account) => CheckboxListTile(
                    dense: true,
                    value: _selectedAccountIds.contains(account.id),
                    title: Text(account.name),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedAccountIds.add(account.id);
                        } else {
                          _selectedAccountIds.remove(account.id);
                        }
                        _opts = _opts.copyWith(
                          accountIds: _selectedAccountIds.toList(),
                        );
                      });
                    },
                  ),
                ),
              const Divider(),
              // Category Filter
              const Text(
                'Category Filter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                OutlinedButton.icon(
                  onPressed: _openCategoryFilter,
                  icon: const Icon(Icons.filter_alt),
                  label: Text(
                    _selectedCategoryIds.length == _categories.length
                        ? 'All categories'
                        : '${_countTopLevelItems(_selectedCategoryIds, true)} ${_countTopLevelItems(_selectedCategoryIds, true) == 1 ? "category" : "categories"} ${_categoryIncludeMode ? "included" : "excluded"}',
                  ),
                ),
              const Divider(),
              // Tag Filter
              const Text(
                'Tag Filter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                OutlinedButton.icon(
                  onPressed: _openTagFilter,
                  icon: const Icon(Icons.filter_alt),
                  label: Text(
                    _selectedTagIds.length == _tags.length
                        ? 'All tags'
                        : '${_countTopLevelItems(_selectedTagIds, false)} ${_countTopLevelItems(_selectedTagIds, false) == 1 ? "tag" : "tags"} ${_tagIncludeMode ? "included" : "excluded"}',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_opts),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
