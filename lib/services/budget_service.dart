import 'package:ledger/models/budget.dart';
import 'package:ledger/services/database/budget_db_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/models/transaction.dart' as model_tx;
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/utilities/singleton_service_mixin.dart';
import 'package:ledger/services/data_refresh_service.dart';

class BudgetProgress {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percent;

  BudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percent,
  });
}

abstract class AbstractBudgetService {
  Future<List<Budget>> fetchBudgets(String userId);
  Future<Budget?> getBudgetById(String budgetId);
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String budgetId);
  Future<BudgetProgress> calculateProgress(Budget budget);
}

class BudgetService implements AbstractBudgetService {
  BudgetService._internal(this._dbService, this._txService);

  factory BudgetService({
    AbstractBudgetDBService? dbService,
    AbstractTransactionService? txService,
  }) {
    final hasDeps = dbService != null || txService != null;

    return SingletonFactory.getInstance(
      () => BudgetService._internal(BudgetDBService(), TransactionService()),
      () => BudgetService._internal(
        dbService ?? BudgetDBService(),
        txService ?? TransactionService(),
      ),
      hasDeps,
    );
  }

  final AbstractBudgetDBService _dbService;
  final AbstractTransactionService _txService;

  @override
  Future<void> createBudget(Budget budget) async {
    try {
      await _dbService.createBudget(budget);
      DataRefreshService().notifyBudgetsChanged();
    } catch (e) {
      LoggerService.e('Failed to create budget', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    await _dbService.delete(budgetId);
    DataRefreshService().notifyBudgetsChanged();
  }

  @override
  Future<Budget?> getBudgetById(String budgetId) async {
    final row = await _dbService.getById(budgetId);
    if (row == null) return null;
    return Budget.fromMap(row);
  }

  @override
  Future<List<Budget>> fetchBudgets(String userId) async {
    final rows = await _dbService.fetchByUserId(userId);
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await _dbService.updateBudget(budget);
    DataRefreshService().notifyBudgetsChanged();
  }

  @override
  Future<BudgetProgress> calculateProgress(Budget budget) async {
    // Determine period boundaries. If `startDate` is set, use it; else default
    final periodStart = budget.startDate;
    final periodEnd = budget.endDate ?? DateTime.now();

    final txsInPeriod = await _txService.getFilteredTransactions(
      type: model_tx.TransactionType.expense,
      startDate: periodStart,
      endDate: periodEnd,
      categoryId: budget.categoryId,
    );

    final spent = txsInPeriod.fold<double>(0.0, (sum, tx) => sum + tx.amount);
    final remaining = budget.amount - spent;
    final percent = budget.amount > 0 ? (spent / budget.amount) * 100.0 : 0.0;
    return BudgetProgress(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percent: percent,
    );
  }
}
