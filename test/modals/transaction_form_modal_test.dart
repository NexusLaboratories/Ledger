import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/modals/transaction_form_modal.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/transaction_item_service.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/models/category.dart';
import '../test_helpers/test_app.dart';

class MockTransactionService extends Mock
    implements AbstractTransactionService {}

class MockTransactionItemService extends Mock
    implements AbstractTransactionItemService {}

class MockAccountService extends Mock implements AbstractAccountService {}

class MockCategoryService extends Mock implements AbstractCategoryService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Account(id: 'acc1', name: 'Wallet'));
    registerFallbackValue(
      model_transaction.Transaction(
        title: 'Dummy',
        amount: 1,
        accountId: 'acc1',
        date: DateTime.now(),
        type: model_transaction.TransactionType.expense,
      ),
    );
    registerFallbackValue(model_transaction.TransactionType.expense);
    registerFallbackValue(DateTime.now());
    registerFallbackValue(
      TransactionItem(id: 'i', transactionId: 't', name: 'n'),
    );
    registerFallbackValue(Category(id: 'c1', name: 'Food'));
  });

  testWidgets('TransactionFormModal creates transaction and items', (
    tester,
  ) async {
    final mockTxService = MockTransactionService();
    final mockItemService = MockTransactionItemService();
    final mockAccountService = MockAccountService();
    final mockCategoryService = MockCategoryService();

    when(
      () => mockAccountService.fetchAccounts(),
    ).thenAnswer((_) async => [Account(id: 'acc1', name: 'Wallet')]);
    when(
      () => mockCategoryService.fetchCategoriesForUser(any()),
    ).thenAnswer((_) async => [Category(id: 'c1', name: 'Food')]);
    when(
      () => mockTxService.createTransaction(
        id: any(named: 'id'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        amount: any(named: 'amount'),
        accountId: any(named: 'accountId'),
        categoryId: any(named: 'categoryId'),
        date: any(named: 'date'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((inv) async {
      // Debug: print when createTransaction is called to trace test behavior
      LoggerService.d(
        'DEBUG: mockTxService.createTransaction called with args: ${inv.positionalArguments}, named: ${inv.namedArguments}',
      );
    });
    when(() => mockItemService.createItem(any())).thenAnswer((_) async {});
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: TransactionFormModal(
            defaultAccountId: 'acc1',
            transactionService: mockTxService,
            itemsService: mockItemService,
            accountService: mockAccountService,
            categoryService: mockCategoryService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    debugDumpApp();

    // Enter title and amount (use labels to be more specific)
    // Fill the form fields by order (Title, Description, Amount)
    final titleField = find.byKey(const Key('transaction-title'));
    await tester.ensureVisible(titleField);
    await tester.tap(titleField);
    await tester.pump();
    await tester.enterText(titleField, 'Test Transaction');
    final descField = find.byKey(const Key('transaction-description'));
    await tester.ensureVisible(descField);
    await tester.tap(descField);
    await tester.pump();
    await tester.enterText(descField, 'Description');
    final amountField = find.byKey(const Key('transaction-amount'));
    expect(amountField, findsOneWidget);
    // Enter amount directly; avoid ensureVisible tap which can be flaky in CI.
    await tester.enterText(amountField, '7');

    // Category defaults to the first loaded category (Food) in the modal

    // Add an item — use the items add button key to avoid ambiguity
    final addItem = find.byKey(const Key('items-add-button'));
    expect(addItem, findsOneWidget);

    // Scroll the form to make the button visible and tappable
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(addItem);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Item A');
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '2');
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '3.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dismiss keyboard and create transaction
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    // Tap the Create button to submit the form
    final createBtnFinder = find.widgetWithText(ElevatedButton, 'Create');
    expect(createBtnFinder, findsOneWidget);
    await tester.ensureVisible(createBtnFinder);
    await tester.tap(createBtnFinder);
    await tester.pumpAndSettle();

    verify(
      () => mockTxService.createTransaction(
        id: any(named: 'id'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        categoryId: any(named: 'categoryId'),
        amount: any(named: 'amount'),
        accountId: any(named: 'accountId'),
        date: any(named: 'date'),
        type: any(named: 'type'),
      ),
    ).called(1);
    verify(() => mockItemService.createItem(any())).called(1);
  });

  testWidgets('TransactionFormModal blocks create when items total mismatch', (
    tester,
  ) async {
    final mockTxService = MockTransactionService();
    final mockItemService = MockTransactionItemService();
    final mockAccountService = MockAccountService();
    final mockCategoryService = MockCategoryService();

    when(
      () => mockAccountService.fetchAccounts(),
    ).thenAnswer((_) async => [Account(id: 'acc1', name: 'Wallet')]);
    when(
      () => mockCategoryService.fetchCategoriesForUser(any()),
    ).thenAnswer((_) async => <Category>[]);
    when(
      () => mockTxService.createTransaction(
        id: any(named: 'id'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        amount: any(named: 'amount'),
        accountId: any(named: 'accountId'),
        categoryId: any(named: 'categoryId'),
        date: any(named: 'date'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockItemService.createItem(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: TransactionFormModal(
            defaultAccountId: 'acc1',
            transactionService: mockTxService,
            itemsService: mockItemService,
            accountService: mockAccountService,
            categoryService: mockCategoryService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleField = find.byKey(const Key('transaction-title'));
    await tester.ensureVisible(titleField);
    await tester.tap(titleField);
    await tester.pump();
    await tester.enterText(titleField, 'Test Transaction');
    final descField = find.byKey(const Key('transaction-description'));
    await tester.ensureVisible(descField);
    await tester.tap(descField);
    await tester.pump();
    await tester.enterText(descField, 'Description');
    final amountField = find.byKey(const Key('transaction-amount'));
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '10');

    // Add an item — use the items add button key to avoid ambiguity
    final addItem = find.byKey(const Key('items-add-button'));
    expect(addItem, findsOneWidget);

    // Scroll the form to make the button visible and tappable
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(addItem);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Item A');
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '2');
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '3.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Attempt to create transaction
    // find Create button
    final createBtnFinder = find.widgetWithText(ElevatedButton, 'Create');
    await tester.ensureVisible(createBtnFinder);
    await tester.tap(createBtnFinder);
    await tester.pumpAndSettle();

    verifyNever(
      () => mockTxService.createTransaction(
        id: any(named: 'id'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        categoryId: any(named: 'categoryId'),
        amount: any(named: 'amount'),
        accountId: any(named: 'accountId'),
        date: any(named: 'date'),
        type: any(named: 'type'),
      ),
    );

    // inline error should be visible
    final errorFinder = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').contains('does not match'),
    );
    expect(errorFinder, findsOneWidget);
  });

  testWidgets('TransactionFormModal hides items when type is income', (
    tester,
  ) async {
    final mockTxService = MockTransactionService();
    final mockItemService = MockTransactionItemService();
    final mockAccountService = MockAccountService();
    final mockCategoryService = MockCategoryService();

    when(
      () => mockAccountService.fetchAccounts(),
    ).thenAnswer((_) async => [Account(id: 'acc1', name: 'Wallet')]);
    when(
      () => mockCategoryService.fetchCategoriesForUser(any()),
    ).thenAnswer((_) async => <Category>[]);
    when(
      () => mockTxService.createTransaction(
        id: any(named: 'id'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        amount: any(named: 'amount'),
        accountId: any(named: 'accountId'),
        categoryId: any(named: 'categoryId'),
        date: any(named: 'date'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockItemService.createItem(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: TransactionFormModal(
            defaultAccountId: 'acc1',
            transactionService: mockTxService,
            itemsService: mockItemService,
            accountService: mockAccountService,
            categoryService: mockCategoryService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select Income type
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    // Items row should not be shown for income
    expect(find.text('Items'), findsNothing);
    expect(find.text('Add item'), findsNothing);
  });
}
