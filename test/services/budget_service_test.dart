import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/budget.dart';
import 'package:ledger/models/transaction.dart' as model_tx;
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/transaction_service.dart';

class FakeTxService implements AbstractTransactionService {
  final List<model_tx.Transaction> _txs;
  FakeTxService(this._txs);
  @override
  Future<void> createTransaction({
    String? id,
    required String title,
    String? description,
    String? categoryId,
    List<String>? tagIds,
    required double amount,
    required String accountId,
    required DateTime date,
    required model_tx.TransactionType type,
  }) async {}
  @override
  Future<void> deleteTransaction(String transactionId) async {}
  @override
  Future<List<model_tx.Transaction>> getAllTransactions() async => _txs;
  @override
  Future<List<model_tx.Transaction>> getTransactionsForAccount(
    String accountId,
  ) async => _txs;
  @override
  Future<List<model_tx.Transaction>> getFilteredTransactions({
    model_tx.TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async => _txs.where((t) {
    if (type != null && t.type != type) return false;
    if (startDate != null && t.date.isBefore(startDate)) return false;
    if (endDate != null && t.date.isAfter(endDate)) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    return true;
  }).toList();
  @override
  Future<model_tx.Transaction?> getTransactionById(String transactionId) async {
    return _txs.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => model_tx.Transaction(
        title: '',
        amount: 0,
        accountId: '',
        date: DateTime.now(),
        type: model_tx.TransactionType.expense,
      ),
    );
  }

  @override
  Future<void> updateTransaction(model_tx.Transaction transaction) async {}
}

void main() {
  test('BudgetService calculates progress correctly', () async {
    final now = DateTime.now();
    final t1 = model_tx.Transaction(
      id: 'tx1',
      title: 'Groc',
      amount: 50.0,
      accountId: 'a1',
      date: now,
      type: model_tx.TransactionType.expense,
      categoryId: 'c1',
    );
    final t2 = model_tx.Transaction(
      id: 'tx2',
      title: 'Groc2',
      amount: 100.0,
      accountId: 'a1',
      date: now,
      type: model_tx.TransactionType.expense,
      categoryId: 'c1',
    );
    final fakeTx = FakeTxService([t1, t2]);
    final budget = Budget(
      id: 'b1',
      name: 'Groceries',
      amount: 200.0,
      period: BudgetPeriod.monthly,
      startDate: now.subtract(const Duration(days: 1)),
    );
    final svc = BudgetService(txService: fakeTx);
    final progress = await svc.calculateProgress(budget);
    expect(progress.spent, equals(150.0));
    expect(progress.remaining, equals(50.0));
  });
}
