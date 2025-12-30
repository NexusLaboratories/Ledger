import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/modals/category_form_modal.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/category_summary.dart';
import 'package:ledger/components/categories/category_card.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/screens/category_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final AbstractCategoryService? categoryService;
  final AbstractTransactionService? transactionService;

  const CategoriesScreen({
    super.key,
    this.categoryService,
    this.transactionService,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final AbstractCategoryService _categoryService;
  late final AbstractTransactionService _transactionService;
  late Future<Map<Category, List<CategorySummary>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _categoryService = widget.categoryService ?? CategoryService();
    _transactionService = widget.transactionService ?? TransactionService();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<Map<Category, List<CategorySummary>>> _loadData() async {
    final allCategories = await _categoryService.fetchCategoriesForUser(
      'local',
    );
    final allSummaries = await _categoryService.getCategorySummaries('local');

    final summaryMap = <String, List<CategorySummary>>{};
    for (final summary in allSummaries) {
      summaryMap.putIfAbsent(summary.id, () => []).add(summary);
    }

    final categoryMap = <Category, List<CategorySummary>>{};
    for (final category in allCategories) {
      categoryMap[category] = summaryMap[category.id] ?? [];
    }
    return categoryMap;
  }

  Future<void> _refresh() async {
    _fetchData();
    await _dataFuture;
  }

  Future<void> _openCreateModal({Category? editing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryFormModal(existing: editing),
    );
    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _categoryService.deleteCategory(id);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      drawer: const CustomAppDrawer(),
      floatingActionButton: CustomFloatingActionButton(
        icon: Icons.add,
        tooltip: 'Add Category',
        onPressed: () => _openCreateModal(),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<Category, List<CategorySummary>>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final data = snapshot.data ?? {};
            if (data.isEmpty) {
              return const Center(child: Text('No categories found.'));
            }
            final categories = data.keys.toList();
            final idToName = {for (var c in categories) c.id: c.name};
            return ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final summaries = data[category]!;
                final parentName = idToName[category.parentCategoryId];
                final subtitle = parentName != null
                    ? (category.description != null
                          ? '$parentName • ${category.description!}'
                          : parentName)
                    : category.description;

                return CategoryCard(
                  key: Key('category-${category.id}'),
                  category: category,
                  summaries: summaries, // This is a new property
                  subtitle: subtitle,
                  showChevron: false,
                  onTapCard: () async {
                    // navigate to category detail screen
                    final result = await Navigator.of(context).push<bool?>(
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(
                          category: category,
                          categoryService: _categoryService,
                          transactionService: _transactionService,
                        ),
                      ),
                    );
                    if (result == true) await _refresh();
                  },
                  onEdit: () => _openCreateModal(editing: category),
                  onDelete: () => _deleteCategory(category.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
