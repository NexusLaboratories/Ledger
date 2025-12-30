import 'package:ledger/models/transaction_tag.dart';
import 'package:ledger/services/database/transaction_tag_db_service.dart';

abstract class AbstractTransactionTagService {
  Future<List<TransactionTag>> fetchTagsForTransaction(String transactionId);
  Future<void> createTransactionTag(TransactionTag tag);
  Future<void> deleteTransactionTag(String transactionId, String tagId);
}

class TransactionTagService implements AbstractTransactionTagService {
  TransactionTagService._internal(this._dbService);

  static TransactionTagService? _instance;
  factory TransactionTagService({AbstractTransactionTagDBService? dbService}) {
    if (dbService != null) return TransactionTagService._internal(dbService);
    _instance ??= TransactionTagService._internal(TransactionTagDBService());
    return _instance!;
  }

  final AbstractTransactionTagDBService _dbService;

  @override
  Future<List<TransactionTag>> fetchTagsForTransaction(
    String transactionId,
  ) async {
    final rows = await _dbService.fetchAllByTransactionId(transactionId);
    return rows.map((r) => TransactionTag.fromMap(r)).toList();
  }

  @override
  Future<void> createTransactionTag(TransactionTag tag) async {
    await _dbService.createTransactionTag(tag);
  }

  @override
  Future<void> deleteTransactionTag(String transactionId, String tagId) async {
    await _dbService.deleteTransactionTag(transactionId, tagId);
  }
}
