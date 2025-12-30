import 'package:ledger/models/transaction_tag.dart';
import 'package:ledger/services/database/core_db_service.dart';

abstract class AbstractTransactionTagDBService {
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<List<Map<String, dynamic>>> fetchAllByTransactionId(
    String transactionId,
  );
  Future<void> createTransactionTag(TransactionTag tag);
  Future<void> deleteTransactionTag(String transactionId, String tagId);
}

class TransactionTagDBService implements AbstractTransactionTagDBService {
  TransactionTagDBService._privateConstructor();
  static final TransactionTagDBService _instance =
      TransactionTagDBService._privateConstructor();
  factory TransactionTagDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'transaction_tags';
  bool _tableInitialized = false;

  Map<String, dynamic> _toMap(TransactionTag tag) => tag.toMap();

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
  Future<void> createTransactionTag(TransactionTag tag) async {
    await _ensureTableExists();
    await _dbService.insert(_tableName, _toMap(tag));
  }

  @override
  Future<void> deleteTransactionTag(String transactionId, String tagId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'transaction_id = ? AND tag_id = ?',
      whereArgs: [transactionId, tagId],
    );
  }
}
