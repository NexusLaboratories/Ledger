import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/screens/categories_screen.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/screens/category_detail_screen.dart';
import 'package:ledger/components/categories/category_card.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/models/category_summary.dart';

class FakeCategoryService implements AbstractCategoryService {
  final List<Category> _cats;
  FakeCategoryService(this._cats);
  @override
  Future<void> createCategory(Category category) async {}

  @override
  Future<void> deleteCategory(String categoryId) async {}

  @override
  Future<Category?> getCategoryById(String categoryId) async {
    for (final c in _cats) {
      if (c.id == categoryId) return c;
    }
    return null;
  }

  @override
  Future<List<Category>> fetchCategoriesForUser(String userId) async {
    return _cats;
  }

  @override
  Future<void> updateCategory(Category category) async {}

  @override
  Future<List<CategorySummary>> getCategorySummaries(String userId) async {
    return [
      CategorySummary(
        id: 'c1',
        name: 'Food',
        totalAmount: 17.5,
        incomeAmount: 0,
        expenseAmount: 17.5,
        currency: 'USD',
      ),
      CategorySummary(
        id: 'c2',
        name: 'Groceries',
        totalAmount: 7.5,
        incomeAmount: 0,
        expenseAmount: 7.5,
        currency: 'USD',
      ),
      CategorySummary(
        id: 'c3',
        name: 'LocalSpends',
        totalAmount: 2.5,
        incomeAmount: 0,
        expenseAmount: 2.5,
        currency: 'USD',
      ),
    ];
  }
}

class FakeTransactionService implements AbstractTransactionService {
  final List<model_transaction.Transaction> _txs;
  FakeTransactionService(this._txs);

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
    required model_transaction.TransactionType type,
  }) async {}

  @override
  Future<void> deleteTransaction(String transactionId) async {}

  @override
  Future<List<model_transaction.Transaction>> getAllTransactions() async =>
      _txs;

  @override
  Future<List<model_transaction.Transaction>> getTransactionsForAccount(
    String accountId,
  ) async => _txs.where((t) => t.accountId == accountId).toList();

  @override
  Future<List<model_transaction.Transaction>> getFilteredTransactions({
    model_transaction.TransactionType? type,
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
  Future<model_transaction.Transaction?> getTransactionById(
    String transactionId,
  ) async {
    for (final t in _txs) {
      if (t.id == transactionId) return t;
    }
    return null;
  }

  @override
  Future<void> updateTransaction(
    model_transaction.Transaction transaction,
  ) async {}
}

void main() {
  testWidgets('Click category navigates to category detail and shows totals + txs', (
    tester,
  ) async {
    final cat1 = Category(id: 'c1', name: 'Food');
    final cat2 = Category(id: 'c2', name: 'Groceries', parentCategoryId: 'c1');

    final tx1 = model_transaction.Transaction(
      id: 't1',
      title: 'Dinner',
      amount: 10.0,
      accountId: 'acc1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.expense,
      categoryId: 'c1',
    );
    final cat3 = Category(
      id: 'c3',
      name: 'LocalSpends',
      parentCategoryId: 'c2',
    );

    final tx3 = model_transaction.Transaction(
      id: 't3',
      title: 'Local',
      amount: 2.5,
      accountId: 'acc1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.expense,
      categoryId: 'c3',
    );

    final tx2 = model_transaction.Transaction(
      id: 't2',
      title: 'Snacks',
      amount: 5.0,
      accountId: 'acc1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.expense,
      categoryId: 'c2',
    );

    final fakeCategoryService = FakeCategoryService([cat1, cat2, cat3]);
    final fakeTxService = FakeTransactionService([tx1, tx2, tx3]);

    await tester.pumpWidget(
      TestApp(
        home: CategoriesScreen(
          categoryService: fakeCategoryService,
          transactionService: fakeTxService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // debug info for testing diagnostics
    // ignore: avoid_print
    print(
      'TransactionListItem count: ${find.byType(TransactionListItem).evaluate().length}',
    );

    // Ensure category is displayed and has a title 'Food'
    final cardFinder = find.byKey(const Key('category-c1'));
    expect(cardFinder, findsOneWidget);
    expect(
      find.descendant(of: cardFinder, matching: find.text('Food')),
      findsOneWidget,
    );
    // Delete button should not be shown on categories screen
    expect(find.byIcon(Icons.delete), findsNothing);

    // Long press the category card and ensure Delete is in the options
    // cardFinder already defined above
    // long press at the center of first category card
    final center = tester.getCenter(cardFinder);
    await tester.longPressAt(center);
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    // Dismiss bottom sheet so subsequent taps hit the card
    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();

    // Tap the category card to open details. Tap its internal InkWell.
    final cardTitle = find.descendant(
      of: cardFinder,
      matching: find.text('Food'),
    );
    expect(cardTitle, findsOneWidget);
    await tester.ensureVisible(cardFinder);
    // Tap the card's center rather than the inner Text widget to avoid hit test issues
    final centerTap = tester.getCenter(cardFinder);
    await tester.tapAt(centerTap);
    // Use bounded pumps to wait for navigation and async work without
    // blocking on animations (e.g., RefreshIndicator). Give enough time for data to load.
    await tester.pump(); // Start navigation
    await tester.pump(); // Complete navigation
    await tester.pump(
      const Duration(seconds: 2),
    ); // Let async futures resolve - give plenty of time
    await tester.pump(); // Rebuild after futures complete
    await tester.pump(); // Final rebuild

    // Should navigate to details
    expect(find.byType(CategoryDetailScreen), findsOneWidget);
    // Verify transactions are displayed after async loading completes
    final tx1Card = find.byKey(const Key('transaction-t1'));
    final tx2Card = find.byKey(const Key('transaction-t2'));
    final tx3Card = find.byKey(const Key('transaction-t3'));
    expect(tx1Card, findsOneWidget);
    expect(tx2Card, findsOneWidget);
    expect(tx3Card, findsOneWidget);
    expect(
      find.descendant(
        of: tx1Card,
        matching: find.byKey(const Key('transaction-title-t1')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tx2Card,
        matching: find.byKey(const Key('transaction-title-t2')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tx3Card,
        matching: find.byKey(const Key('transaction-title-t3')),
      ),
      findsOneWidget,
    );

    // Ensure there's no "no transactions" message (i.e., transactions should be found)
    expect(find.text('No transactions found for this category'), findsNothing);
    // Should show transaction titles
    expect(tx1Card, findsOneWidget);
    expect(tx2Card, findsOneWidget);
    // Children hierarchy should be shown and nodes should be visible
    expect(find.textContaining('CHILDREN'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    // Only immediate children should appear on this detail screen
    expect(find.text('LocalSpends'), findsNothing);
    // The child totals (Groceries) should be visible next to the title
    final groceriesAmountFinder = find.descendant(
      of: find.byKey(const Key('category-node-c2')),
      matching: find.byKey(const Key('category-amount-c2')),
    );
    expect(groceriesAmountFinder, findsOneWidget);
    // ensure it shows 7.50 (use substring to avoid locale formatting differences)
    expect(
      find.descendant(
        of: find.byKey(const Key('category-node-c2')),
        matching: find.byWidgetPredicate(
          (w) => w is Text && (w.data?.contains('7.50') ?? false),
        ),
      ),
      findsOneWidget,
    );

    // NOTE: long-press verified on the categories screen earlier

    // Now tap child category and ensure parent is visible
    final detailFinder = find.byType(CategoryDetailScreen);
    expect(detailFinder, findsOneWidget);
    // Tap the node representing the child category
    final groceriesNode = find.byKey(const Key('category-node-c2'));
    expect(groceriesNode, findsOneWidget);
    await tester.tap(groceriesNode);
    await tester.pumpAndSettle();
    final newDetailFinder = find.byType(CategoryDetailScreen);
    expect(newDetailFinder, findsOneWidget);
    // Parent label and card should be visible and point to the Food parent
    expect(find.text('PARENT'), findsOneWidget);
    expect(find.byKey(const Key('category-parent-c1')), findsOneWidget);
    expect(find.widgetWithText(CategoryCard, 'Food'), findsOneWidget);
    // Parent card should NOT show amount
    expect(
      find.descendant(
        of: find.byKey(const Key('category-parent-c1')),
        matching: find.byKey(const Key('category-amount-c1')),
      ),
      findsNothing,
    );
    // Now in Groceries detail, LocalSpends (its immediate child) should be visible
    expect(find.text('LocalSpends'), findsOneWidget);
    // And the LocalSpends amount should be visible as $2.50
    final localAmountFinder = find.descendant(
      of: find.byKey(const Key('category-node-c3')),
      matching: find.byKey(const Key('category-amount-c3')),
    );
    expect(localAmountFinder, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('category-node-c3')),
        matching: find.byWidgetPredicate(
          (w) => w is Text && (w.data?.contains('2.50') ?? false),
        ),
      ),
      findsOneWidget,
    );

    // Ensure parent card is clickable; tapping should navigate to parent detail
    // Note: Parent cards don't show chevrons (showChevron: false)
    final parentCard = find.byKey(const Key('category-parent-c1'));
    expect(parentCard, findsOneWidget);
    await tester.tap(parentCard);
    await tester.pumpAndSettle();
    // Tapping the parent should navigate to its detail screen
    // Verify we're on Food's detail screen by checking for its child "Groceries"
    expect(find.text('Groceries'), findsOneWidget);
    // Children cards should not display a chevron icon anymore
    final childNode = find.byKey(const Key('category-node-c3'));
    expect(
      find.descendant(
        of: childNode,
        matching: find.byIcon(Icons.chevron_right),
      ),
      findsNothing,
    );
  });

  testWidgets('direct CategoryDetailScreen shows txs for provided services', (
    tester,
  ) async {
    final cat1 = Category(id: 'c1', name: 'Food');
    final cat2 = Category(id: 'c2', name: 'Groceries', parentCategoryId: 'c1');
    final cat3 = Category(
      id: 'c3',
      name: 'LocalSpends',
      parentCategoryId: 'c2',
    );

    final tx1 = model_transaction.Transaction(
      id: 't1',
      title: 'Dinner',
      amount: 10.0,
      accountId: 'acc1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.expense,
      categoryId: 'c1',
    );
    final tx2 = model_transaction.Transaction(
      id: 't2',
      title: 'Snacks',
      amount: 5.0,
      accountId: 'acc1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.expense,
      categoryId: 'c2',
    );
    final tx3 = model_transaction.Transaction(
      id: 't3',
      title: 'Local',
      amount: 2.5,
      accountId: 'acc1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.expense,
      categoryId: 'c3',
    );

    final fakeCategoryService = FakeCategoryService([cat1, cat2, cat3]);
    final fakeTxService = FakeTransactionService([tx1, tx2, tx3]);

    // verify fake services return expected data outside of widget tree
    expect(await fakeTxService.getAllTransactions(), hasLength(3));
    expect(
      await fakeCategoryService.fetchCategoriesForUser('local'),
      hasLength(3),
    );

    await tester.pumpWidget(
      TestApp(
        home: CategoryDetailScreen(
          category: cat1,
          categoryService: fakeCategoryService,
          transactionService: fakeTxService,
        ),
      ),
    );
    // Use bounded pumps to allow widget tree to render
    await tester.pump();
    await tester.pump();

    // Verify that the screen has rendered
    // Note: Async data loading is tested in integration tests
    expect(find.byType(CategoryDetailScreen), findsOneWidget);
    final dinnerFinder = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'Dinner',
    );
    final snacksFinder = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'Snacks',
    );
    final localFinder = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'Local',
    );
    expect(dinnerFinder, findsOneWidget);
    expect(snacksFinder, findsOneWidget);
    expect(localFinder, findsOneWidget);
  });
}
