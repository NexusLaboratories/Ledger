import 'package:ledger/models/budget.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/logger_service.dart';

abstract class AbstractBudgetDBService {
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<List<Map<String, dynamic>>> fetchByUserId(String userId);
  Future<Map<String, dynamic>?> getById(String budgetId);
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> delete(String budgetId);
}

class BudgetDBService implements AbstractBudgetDBService {
  BudgetDBService._privateConstructor();
  static final BudgetDBService _instance =
      BudgetDBService._privateConstructor();
  factory BudgetDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'budgets';
  bool _tableInitialized = false;

  Future<void> _ensureTableExists() async {
    if (_tableInitialized) return;
    LoggerService.d('BudgetDBService: Ensuring table exists, calling openDB');
    await _dbService.openDB();
    LoggerService.d(
      'BudgetDBService: openDB completed, running ensureMigrations',
    );
    await _dbService.ensureMigrations();
    LoggerService.d('BudgetDBService: ensureMigrations completed');
    _tableInitialized = true;
  }

  Map<String, dynamic> _toMap(Budget b) => b.toMap();

  @override
  Future<void> createBudget(Budget budget) async {
    await _ensureTableExists();
    try {
      LoggerService.d(
        'BudgetDBService: About to insert budget: ${budget.toMap()}',
      );
      final res = await _dbService.insert(_tableName, _toMap(budget));
      // Log for debugging: res is rowId or 0 for success
      LoggerService.d('BudgetDBService: inserted budget with raw result: $res');
    } catch (e, stackTrace) {
      // to preserve behavior, rethrow with context
      LoggerService.e('BudgetDBService: createBudget failed', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await _ensureTableExists();
    await _dbService.update(
      _tableName,
      _toMap(budget),
      where: 'budget_id = ?',
      whereArgs: [budget.id],
    );
  }

  @override
  Future<void> delete(String budgetId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await _ensureTableExists();
    return await _dbService.query(_tableName);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchByUserId(String userId) async {
    await _ensureTableExists();
    return await _dbService.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<Map<String, dynamic>?> getById(String budgetId) async {
    await _ensureTableExists();
    final r = await _dbService.query(
      _tableName,
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );
    return r.isNotEmpty ? r.first : null;
  }
}
