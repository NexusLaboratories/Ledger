import 'package:flutter/material.dart';
import 'package:ledger/components/budgets/budget_card.dart';
import 'package:ledger/components/ui/layout/custom_app_bar.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/modals/budget_form_modal.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/data_refresh_service.dart';

class BudgetsScreen extends StatefulWidget {
  final AbstractBudgetService? budgetService;
  const BudgetsScreen({super.key, this.budgetService});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final AbstractBudgetService _budgetService;
  late Future<List<dynamic>> _loadFuture;
  List<dynamic> _budgetsWithProgress = [];

  @override
  void initState() {
    super.initState();
    _budgetService = widget.budgetService ?? BudgetService();
    DataRefreshService().budgetsNotifier.addListener(_onBudgetsChanged);
    DataRefreshService().transactionsNotifier.addListener(_onBudgetsChanged);
    _loadFuture = _load();
  }

  @override
  void dispose() {
    DataRefreshService().budgetsNotifier.removeListener(_onBudgetsChanged);
    DataRefreshService().transactionsNotifier.removeListener(_onBudgetsChanged);
    super.dispose();
  }

  void _onBudgetsChanged() {
    if (mounted) {
      setState(() {
        _loadFuture = _load();
      });
    }
  }

  Future<List<dynamic>> _load() async {
    final budgets = await _budgetService.fetchBudgets('local');
    final List<Map<String, dynamic>> withProgress = [];
    for (final b in budgets) {
      final p = await _budgetService.calculateProgress(b);
      withProgress.add({'budget': b, 'progress': p});
    }
    setState(() => _budgetsWithProgress = withProgress);
    return withProgress;
  }

  Future<void> _openForm([dynamic initialBudget]) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          BudgetFormModal(budget: initialBudget, budgetService: _budgetService),
    );
    if (res == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Budgets'),
      drawer: const CustomAppDrawer(),
      body: FutureBuilder<List<dynamic>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_budgetsWithProgress.isEmpty) {
            return Center(child: Text('No budgets found. Tap + to create.'));
          }
          return ListView.builder(
            itemCount: _budgetsWithProgress.length,
            itemBuilder: (context, index) {
              final item = _budgetsWithProgress[index];
              final budget = item['budget'];
              final progress = item['progress'];
              return BudgetCard(
                budget: budget,
                progress: progress,
                onTap: () {},
                onEdit: () => _openForm(budget),
                onDelete: () async {
                  await _budgetService.deleteBudget(budget.id);
                  await _load();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: () => _openForm(),
      ),
    );
  }
}
