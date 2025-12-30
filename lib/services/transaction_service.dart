import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/balance_service.dart';
import 'package:ledger/services/transaction_tag_service.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/models/transaction_tag.dart' as model_transaction_tag;
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/utilities/singleton_service_mixin.dart';

abstract class AbstractTransactionService {
  Future<List<Transaction>> getTransactionsForAccount(String accountId);
  Future<Transaction?> getTransactionById(String transactionId);
  Future<List<Transaction>> getFilteredTransactions({
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });
  Future<void> createTransaction({
    String? id,
    required String title,
    String? description,
    String? categoryId,
    required double amount,
    required String accountId,
    required DateTime date,
    required TransactionType type,
    List<String>? tagIds,
  });
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String transactionId);
  Future<List<Transaction>> getAllTransactions();
}

class TransactionService implements AbstractTransactionService {
  // Provide constructor injection for testability. When dependencies are
  // passed in, return a new instance. If not, return a singleton default one.
  TransactionService._internal(
    this._dbService,
    this._balanceService, {
    AbstractTransactionTagService? txTagService,
    AbstractTagService? tagService,
  }) : _txTagService = txTagService ?? TransactionTagService(),
       _tagService = tagService ?? TagService();

  factory TransactionService({
    AbstractTransactionDBService? dbService,
    BalanceService? balanceService,
    AbstractTransactionTagService? txTagService,
    AbstractTagService? tagService,
  }) {
    final hasDeps =
        dbService != null ||
        balanceService != null ||
        txTagService != null ||
        tagService != null;

    return SingletonFactory.getInstance(
      () => TransactionService._internal(
        TransactionDBService(),
        BalanceService(),
      ),
      () => TransactionService._internal(
        dbService ?? TransactionDBService(),

        balanceService ?? BalanceService(),
        txTagService: txTagService,
        tagService: tagService,
      ),
      hasDeps,
    );
  }

  final AbstractTransactionDBService _dbService;

  final BalanceService _balanceService;
  final AbstractTransactionTagService _txTagService;
  final AbstractTagService _tagService;

  @override
  Future<void> createTransaction({
    String? id,
    required String title,
    String? description,
    String? categoryId,
    required double amount,
    required String accountId,
    required DateTime date,
    required TransactionType type,
    List<String>? tagIds,
  }) async {
    LoggerService.i(
      'Creating transaction: "$title" | Amount: \$$amount | Type: $type | Account: $accountId',
    );
    try {
      // DatabaseService initialization is handled by DB services if required.
      final newTransaction = Transaction(
        id: id,
        title: title,
        description: description,
        categoryId: categoryId,
        amount: amount,
        accountId: accountId,
        date: date,
        type: type,
      );
      await _dbService.createTransaction(newTransaction);
      // Attachment of tags (many-to-many)
      if (tagIds != null && tagIds.isNotEmpty) {
        for (final tagId in tagIds) {
          await _txTagService.createTransactionTag(
            model_transaction_tag.TransactionTag(
              transactionId: newTransaction.id,
              tagId: tagId,
            ),
          );
        }
      }

      // Update account balance
      await _balanceService.applyTransactionToBalance(newTransaction);

      LoggerService.i(
        'Transaction created successfully: ${newTransaction.id} | Tags: ${tagIds?.length ?? 0}',
      );
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to create transaction: $title | Amount: \$$amount | Account: $accountId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    LoggerService.i('Deleting transaction: $transactionId');
    try {
      // rely on db service for table / db initialization
      final transaction = await getTransactionById(transactionId);
      if (transaction != null) {
        LoggerService.i(
          'Transaction found: "${transaction.title}" | Amount: \$${transaction.amount} | Type: ${transaction.type}',
        );
        await _dbService.deleteTransaction(transactionId);

        // Update account balance
        await _balanceService.revertTransactionFromBalance(transaction);
        LoggerService.i(
          'Transaction deleted and balance updated: $transactionId',
        );
      } else {
        LoggerService.w('Transaction not found for deletion: $transactionId');
      }
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to delete transaction: $transactionId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getTransactionsForAccount(String accountId) async {
    // rely on db service for table / db initialization
    final transactionsMap = await _dbService.fetchAllByAccountId(accountId);
    return (await Future.wait(
      transactionsMap.map((map) async {
        final tx = Transaction.fromMap(map);
        // populate tags
        final txTags = await _txTagService.fetchTagsForTransaction(tx.id);
        final tIds = txTags.map((t) => t.tagId).toList();
        final tNames = <String>[];
        for (final id in tIds) {
          final tag = await _tagService.getTagById(id);
          if (tag != null) tNames.add(tag.name);
        }
        return tx.copyWith(tagIds: tIds, tagNames: tNames);
      }),
    )).toList();
  }

  @override
  Future<List<Transaction>> getFilteredTransactions({
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    // rely on db service for table / db initialization
    final transactionsMap = await _dbService.fetchFiltered(
      type: type,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
    );
    return (await Future.wait(
      transactionsMap.map((map) async {
        final tx = Transaction.fromMap(map);
        // populate tags
        final txTags = await _txTagService.fetchTagsForTransaction(tx.id);
        final tIds = txTags.map((t) => t.tagId).toList();
        final tNames = <String>[];
        for (final id in tIds) {
          final tag = await _tagService.getTagById(id);
          if (tag != null) tNames.add(tag.name);
        }
        return tx.copyWith(tagIds: tIds, tagNames: tNames);
      }),
    )).toList();
  }

  @override
  Future<Transaction?> getTransactionById(String transactionId) async {
    // rely on db service for table / db initialization
    final transactionMap = await _dbService.getTransactionById(transactionId);
    if (transactionMap != null) {
      final tx = Transaction.fromMap(transactionMap);
      final txTags = await _txTagService.fetchTagsForTransaction(tx.id);
      final tIds = txTags.map((t) => t.tagId).toList();
      final tNames = <String>[];
      for (final id in tIds) {
        final tag = await _tagService.getTagById(id);
        if (tag != null) tNames.add(tag.name);
      }
      return tx.copyWith(tagIds: tIds, tagNames: tNames);
    }
    return null;
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    // rely on db service for table / db initialization
    final transactionsMap = await _dbService.fetchAll();
    return (await Future.wait(
      transactionsMap.map((map) async {
        final tx = Transaction.fromMap(map);
        final txTags = await _txTagService.fetchTagsForTransaction(tx.id);
        final tIds = txTags.map((t) => t.tagId).toList();
        final tNames = <String>[];
        for (final id in tIds) {
          final tag = await _tagService.getTagById(id);
          if (tag != null) tNames.add(tag.name);
        }
        return tx.copyWith(tagIds: tIds, tagNames: tNames);
      }),
    )).toList();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    // Keep a copy of the existing transaction so we can adjust account
    // balances correctly when the amount, type, or account changes.
    final existingTransaction = await getTransactionById(transaction.id);

    // Sync tags for the transaction
    final existingTxTags = await _txTagService.fetchTagsForTransaction(
      transaction.id,
    );
    final existingTagIds = existingTxTags.map((t) => t.tagId).toSet();
    final desiredTagIds = transaction.tagIds.toSet();
    final toAdd = desiredTagIds.difference(existingTagIds);
    final toRemove = existingTagIds.difference(desiredTagIds);
    for (final id in toAdd) {
      await _txTagService.createTransactionTag(
        model_transaction_tag.TransactionTag(
          transactionId: transaction.id,
          tagId: id,
        ),
      );
    }
    for (final id in toRemove) {
      await _txTagService.deleteTransactionTag(transaction.id, id);
    }

    // Update transaction row
    await _dbService.updateTransaction(transaction);

    // Reconcile account balances if the transaction changed
    if (existingTransaction != null) {
      try {
        // Revert effect of the old transaction on its account
        await _balanceService.revertTransactionFromBalance(existingTransaction);

        // Apply new transaction effect to (possibly different) account
        await _balanceService.applyTransactionToBalance(transaction);
      } catch (e, stackTrace) {
        // Do not fail the transaction update if balance reconciliation fails.
        LoggerService.e(
          'TransactionService: failed to reconcile account balances after transaction update',
          e,
          stackTrace,
        );
      }
    }
  }
}
