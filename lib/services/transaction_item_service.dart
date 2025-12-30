import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/services/database/transaction_item_db_service.dart';

abstract class AbstractTransactionItemService {
  Future<List<TransactionItem>> fetchItemsForTransaction(String transactionId);
  Future<TransactionItem?> getItemById(String itemId);
  Future<void> createItem(TransactionItem item);
  Future<void> updateItem(TransactionItem item);
  Future<void> deleteItem(String itemId);
}

class TransactionItemService implements AbstractTransactionItemService {
  TransactionItemService._internal(this._dbService);

  static TransactionItemService? _instance;
  factory TransactionItemService({
    AbstractTransactionItemDBService? dbService,
  }) {
    if (dbService != null) return TransactionItemService._internal(dbService);
    _instance ??= TransactionItemService._internal(TransactionItemDBService());
    return _instance!;
  }

  final AbstractTransactionItemDBService _dbService;

  @override
  Future<List<TransactionItem>> fetchItemsForTransaction(
    String transactionId,
  ) async {
    final rows = await _dbService.fetchAllByTransactionId(transactionId);
    return rows.map((r) => TransactionItem.fromMap(r)).toList();
  }

  @override
  Future<TransactionItem?> getItemById(String itemId) async {
    final row = await _dbService.getItemById(itemId);
    if (row == null) return null;
    return TransactionItem.fromMap(row);
  }

  @override
  Future<void> createItem(TransactionItem item) async {
    await _dbService.createItem(item);
  }

  @override
  Future<void> updateItem(TransactionItem item) async {
    await _dbService.updateItem(item);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _dbService.delete(itemId);
  }
}
