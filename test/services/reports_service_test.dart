import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/transaction.dart' as tx_model;
import 'package:ledger/services/reports_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/category_summary.dart';

class FakeTransactionService implements AbstractTransactionService {
  final List<tx_model.Transaction> _txs;
  FakeTransactionService(this._txs);

  @override
  Future<List<tx_model.Transaction>> getAllTransactions() async => _txs;

  // Unused methods for this test
  @override
  Future<void> createTransaction({
    String? id,
    required String title,
    String? description,
    String? categoryId,
    required double amount,
    required String accountId,
    required DateTime date,
    required tx_model.TransactionType type,
    List<String>? tagIds,
  }) async {}

  @override
  Future<void> deleteTransaction(String transactionId) async {}

  @override
  Future<tx_model.Transaction?> getTransactionById(
    String transactionId,
  ) async => null;

  @override
  Future<List<tx_model.Transaction>> getTransactionsForAccount(
    String accountId,
  ) async => [];

  @override
  Future<List<tx_model.Transaction>> getFilteredTransactions({
    tx_model.TransactionType? type,
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
  Future<void> updateTransaction(tx_model.Transaction transaction) async {}
}

class FakeCategoryService implements AbstractCategoryService {
  @override
  Future<List<Category>> fetchCategoriesForUser(String userId) async => [
    Category(id: 'c1', name: 'Food'),
  ];

  @override
  Future<Category?> getCategoryById(String categoryId) async =>
      Category(id: categoryId, name: 'Food');

  @override
  Future<List<CategorySummary>> getCategorySummaries(String userId) async => [];

  @override
  Future<void> createCategory(Category category) async {}

  @override
  Future<void> updateCategory(Category category) async {}

  @override
  Future<void> deleteCategory(String categoryId) async {}
}

void main() {
  test('getSpendingSummary calculates extra stats', () async {
    final txs = [
      tx_model.Transaction(
        id: 't1',
        title: 'Lunch',
        description: '',
        categoryId: 'c1',
        amount: 50,
        accountId: 'a1',
        date: DateTime(2025, 12, 1),
        type: tx_model.TransactionType.expense,
      ),
      tx_model.Transaction(
        id: 't2',
        title: 'Coffee',
        description: '',
        categoryId: 'c1',
        amount: 25,
        accountId: 'a1',
        date: DateTime(2025, 12, 2),
        type: tx_model.TransactionType.expense,
      ),
      tx_model.Transaction(
        id: 't3',
        title: 'Salary',
        description: '',
        categoryId: null,
        amount: 200,
        accountId: 'a1',
        date: DateTime(2025, 12, 3),
        type: tx_model.TransactionType.income,
      ),
      tx_model.Transaction(
        id: 't4',
        title: 'Groceries',
        description: '',
        categoryId: 'c1',
        amount: 100,
        accountId: 'a1',
        date: DateTime(2025, 12, 4),
        type: tx_model.TransactionType.expense,
      ),
    ];

    final reportsService = ReportsService(
      transactionService: FakeTransactionService(txs),
      categoryService: FakeCategoryService(),
    );

    final summary = await reportsService.getSpendingSummary();

    expect(summary.totalExpense, 175);
    expect(summary.totalIncome, 200);
    expect(summary.transactionCount, 4);

    // get all transactions
    final all = await reportsService.getAllTransactions();
    expect(all.length, 4);

    // get transactions in a date range (Dec 2 - Dec 3)
    final range = await reportsService.getTransactionsInRange(
      startDate: DateTime(2025, 12, 2),
      endDate: DateTime(2025, 12, 3),
    );
    expect(range.length, 2);
  });

  test(
    'uncategorised expense transactions appear as separate category',
    () async {
      final txs = [
        tx_model.Transaction(
          id: 't1',
          title: 'Lunch',
          categoryId: 'c1',
          amount: 50,
          accountId: 'a1',
          date: DateTime(2025, 12, 1),
          type: tx_model.TransactionType.expense,
        ),
        tx_model.Transaction(
          id: 't2',
          title: 'Random expense',
          categoryId: null, // uncategorised
          amount: 25,
          accountId: 'a1',
          date: DateTime(2025, 12, 2),
          type: tx_model.TransactionType.expense,
        ),
        tx_model.Transaction(
          id: 't3',
          title: 'Another uncategorised',
          categoryId: null, // uncategorised
          amount: 15,
          accountId: 'a1',
          date: DateTime(2025, 12, 3),
          type: tx_model.TransactionType.expense,
        ),
      ];

      final reportsService = ReportsService(
        transactionService: FakeTransactionService(txs),
        categoryService: FakeCategoryService(),
      );

      final summary = await reportsService.getSpendingSummary();

      // Total expense should include all transactions
      expect(summary.totalExpense, 90);

      // Should have 2 categories: Food (c1) and Uncategorised
      expect(summary.topCategories.length, 2);

      // Find the uncategorised category
      final uncategorised = summary.topCategories.firstWhere(
        (cat) => cat.categoryName == 'Uncategorised',
      );

      // Uncategorised should have 2 transactions totaling 40
      expect(uncategorised.amount, 40);
      expect(uncategorised.transactionCount, 2);

      // Check percentage (40/90 = 44.44%)
      expect(uncategorised.percentage, closeTo(44.44, 0.01));
    },
  );

  test('getDailySpendingForCurrentMonth returns day totals', () async {
    final txs = [
      tx_model.Transaction(
        id: 't1',
        title: 'Day1',
        categoryId: 'c1',
        amount: 10,
        accountId: 'a1',
        date: DateTime(2025, 12, 1),
        type: tx_model.TransactionType.expense,
      ),
      tx_model.Transaction(
        id: 't2',
        title: 'Day2',
        categoryId: 'c1',
        amount: 5,
        accountId: 'a1',
        date: DateTime(2025, 12, 2),
        type: tx_model.TransactionType.expense,
      ),
      tx_model.Transaction(
        id: 't3',
        title: 'Day2-extra',
        categoryId: 'c1',
        amount: 15,
        accountId: 'a1',
        date: DateTime(2025, 12, 2),
        type: tx_model.TransactionType.expense,
      ),
      // Outside cutoff (day 20) should be excluded when using referenceDate day=15
      tx_model.Transaction(
        id: 't4',
        title: 'Day20',
        categoryId: 'c1',
        amount: 100,
        accountId: 'a1',
        date: DateTime(2025, 12, 20),
        type: tx_model.TransactionType.expense,
      ),
    ];

    final reportsService = ReportsService(
      transactionService: FakeTransactionService(txs),
      categoryService: FakeCategoryService(),
    );

    final daily = await reportsService.getDailySpendingForCurrentMonth(
      referenceDate: DateTime(2025, 12, 15),
      upToTodayOnly: true,
    );

    // Should have 15 entries
    expect(daily.length, 15);

    // Day 1 = 10
    expect(daily[0], 10);

    // Day 2 = 5 + 15 = 20
    expect(daily[1], 20);

    // Day 20 should not be present (cutoff at 15)
    expect(daily.where((v) => v == 100).isEmpty, true);
  });

  test('getTotalsForMonth returns correct totals', () async {
    final txs = [
      tx_model.Transaction(
        id: 't1',
        title: 'Income Dec',
        categoryId: null,
        amount: 100,
        accountId: 'a1',
        date: DateTime(2025, 12, 5),
        type: tx_model.TransactionType.income,
      ),
      tx_model.Transaction(
        id: 't2',
        title: 'Expense Dec',
        categoryId: 'c1',
        amount: 40,
        accountId: 'a1',
        date: DateTime(2025, 12, 6),
        type: tx_model.TransactionType.expense,
      ),
      tx_model.Transaction(
        id: 't3',
        title: 'Expense Nov',
        categoryId: 'c1',
        amount: 20,
        accountId: 'a1',
        date: DateTime(2025, 11, 20),
        type: tx_model.TransactionType.expense,
      ),
    ];

    final reportsService = ReportsService(
      transactionService: FakeTransactionService(txs),
      categoryService: FakeCategoryService(),
    );

    final totals = await reportsService.getTotalsForMonth(2025, 12);
    expect(totals.income, 100);
    expect(totals.expense, 40);
    expect(totals.transactionCount, 2);
  });
}
