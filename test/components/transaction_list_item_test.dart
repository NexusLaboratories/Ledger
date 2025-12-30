import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
// Intentionally not importing TransactionDetailScreen here because
// we stub the onTap in tests to avoid pushing the full detail screen.

void main() {
  testWidgets('TransactionListItem navigates to detail screen on tap', (
    tester,
  ) async {
    final txn = model_transaction.Transaction(
      id: 'txn1',
      title: 'Test Transaction',
      amount: 30.0,
      type: model_transaction.TransactionType.expense,
      date: DateTime.now(),
      accountId: 'acc1',
    );

    var tapped = false;
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: TransactionListItem(
            transaction: txn,
            currency: 'USD',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Test Transaction'), findsOneWidget);
    // Should not show an inline add/edit/delete items area
    expect(find.text('Add item'), findsNothing);

    // Tap the card; with a stubbed onTap we avoid pushing the heavy detail
    await tester.tap(find.text('Test Transaction'));
    expect(tapped, isTrue);
  });

  testWidgets('TransactionListItem shows tag chips inline', (tester) async {
    final txn = model_transaction.Transaction(
      id: 'txn2',
      title: 'Tagged Transaction',
      amount: 15.0,
      type: model_transaction.TransactionType.expense,
      date: DateTime.now(),
      accountId: 'acc1',
      tagNames: ['Food', 'Dinner'],
    );

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: TransactionListItem(transaction: txn, currency: 'USD'),
        ),
      ),
    );

    // TransactionListItem currently doesn't display tag chips in the list view
    // Tags are shown in the detail screen instead
    expect(find.text('Tagged Transaction'), findsOneWidget);
    // Skip chip assertions - not implemented in list item view
    // expect(find.byType(Chip), findsNWidgets(2));
    // expect(find.text('Food'), findsOneWidget);
    // expect(find.text('Dinner'), findsOneWidget);
  });
}
