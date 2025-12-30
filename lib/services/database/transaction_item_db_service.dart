import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/services/database/core_db_service.dart';

abstract class AbstractTransactionItemDBService {
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<List<Map<String, dynamic>>> fetchAllByTransactionId(
    String transactionId,
  );
  Future<Map<String, dynamic>?> getItemById(String itemId);
  Future<void> createItem(TransactionItem item);
  Future<void> updateItem(TransactionItem item);
  Future<void> delete(String itemId);
}

class TransactionItemDBService implements AbstractTransactionItemDBService {
  TransactionItemDBService._privateConstructor();
  static final TransactionItemDBService _instance =
      TransactionItemDBService._privateConstructor();
  factory TransactionItemDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'transaction_items';
  bool _tableInitialized = false;

  Map<String, dynamic> _toMap(TransactionItem item) => item.toMap();

  Future<void> _createTable() async {}
  Future<void> _ensureTableExists() async {
    if (_tableInitialized) return;
    await _dbService.openDB();
    await _createTable();
    _tableInitialized = true;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await _ensureTableExists();
    return await _dbService.query(_tableName);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllByTransactionId(
    String transactionId,
  ) async {
    await _ensureTableExists();
    return await _dbService.query(
      _tableName,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  @override
  Future<Map<String, dynamic>?> getItemById(String itemId) async {
    await _ensureTableExists();
    final results = await _dbService.query(
      _tableName,
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<void> createItem(TransactionItem item) async {
    await _ensureTableExists();
    await _dbService.insert(_tableName, _toMap(item));
  }

  @override
  Future<void> updateItem(TransactionItem item) async {
    await _ensureTableExists();
    await _dbService.update(
      _tableName,
      _toMap(item),
      where: 'item_id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> delete(String itemId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }
}
