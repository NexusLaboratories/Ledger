import 'package:ledger/models/transaction.dart';

import 'package:ledger/services/database/core_db_service.dart';

abstract class AbstractTransactionDBService {
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<List<Map<String, dynamic>>> fetchAllByAccountId(String accountId);
  Future<List<Map<String, dynamic>>> fetchFiltered({
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });
  Future<Map<String, dynamic>?> getTransactionById(String transactionId);
  Future<void> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String transactionId);
}

class TransactionDBService implements AbstractTransactionDBService {
  TransactionDBService._privateConstructor();
  static final TransactionDBService _instance =
      TransactionDBService._privateConstructor();
  factory TransactionDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();

  static const String _tableName = 'transactions';
  bool _tableInitialized = false;

  Map<String, dynamic> _toMap(Transaction transaction) {
    return transaction.toMap();
  }

  Future<void> _createTable() async {
    // Table creation is now handled by CoreDBService
  }
  Future<void> _ensureTableExists() async {
    if (!_tableInitialized) {
      // Ensure DB is open so table creation scripts run when necessary
      await _dbService.openDB();
      // Ensure any migrations are applied (e.g., added columns)
      await _dbService.ensureMigrations();
      await _createTable();
      _tableInitialized = true;
    }
  }

  @override
  Future<void> createTransaction(Transaction transaction) async {
    await _ensureTableExists();
    await _dbService.insert(_tableName, _toMap(transaction));
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await _ensureTableExists();
    return await _dbService.query(_tableName);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllByAccountId(
    String accountId,
  ) async {
    await _ensureTableExists();
    return await _dbService.query(
      _tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFiltered({
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    await _ensureTableExists();
    final conditions = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      conditions.add('type = ?');
      args.add(type.index);
    }
    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate.millisecondsSinceEpoch);
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    return await _dbService.query(
      _tableName,
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
    );
  }

  @override
  Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    await _ensureTableExists();
    final results = await _dbService.query(
      _tableName,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await _ensureTableExists();
    await _dbService.update(
      _tableName,
      _toMap(transaction),
      where: 'transaction_id = ?',
      whereArgs: [transaction.id],
    );
  }
}
