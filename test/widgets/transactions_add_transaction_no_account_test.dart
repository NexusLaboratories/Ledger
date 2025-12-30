import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/screens/transactions_screen.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/transaction_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockAccountService extends Mock implements AbstractAccountService {}

class MockTransactionService extends Mock
    implements AbstractTransactionService {}

void main() {
  group('TransactionsScreen Create Transaction without account', () {
    late MockAccountService mockService;
    setUpAll(() {
      registerCommonFallbacks();
    });
    setUp(() {
      mockService = MockAccountService();
      when(() => mockService.fetchAccounts()).thenAnswer((_) async => []);
    });

    testWidgets(
      'Create transaction shows create-account dialog when no accounts exist',
      (WidgetTester tester) async {
        final mockTxService = MockTransactionService();
        when(
          () => mockTxService.getAllTransactions(),
        ).thenAnswer((_) async => []);
        await tester.pumpWidget(
          TestApp(
            home: TransactionsScreen(
              accountService: mockService,
              transactionService: mockTxService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton).first;
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        await tester.pumpAndSettle();
        expect(find.text('Create Transaction'), findsOneWidget);
        await tester.tap(find.text('Create Transaction'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('No Accounts'), findsOneWidget);
        expect(
          find.text(
            'You must create an account before creating a transaction.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
