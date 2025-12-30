import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/components/accounts/account_card.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/models/account.dart';

void main() {
  testWidgets('AccountCard hides description when null', (
    WidgetTester tester,
  ) async {
    final account = Account(name: 'Testing', description: null, balance: 1.0);

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: AccountCard(account: account, onDelete: () {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Testing'), findsOneWidget);
    final formattedAmount = CurrencyFormatter.format(1.0, 'USD');
    expect(find.text(formattedAmount), findsOneWidget);
    // Description is null - there should be 3 Text widgets (name + currency + balance)
    expect(find.byType(Text), findsNWidgets(3));
  });

  testWidgets('AccountCard shows description when non-empty', (
    WidgetTester tester,
  ) async {
    final account = Account(
      name: 'Testing',
      description: 'Main account',
      balance: 1.0,
    );

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: AccountCard(account: account, onDelete: () {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Testing'), findsOneWidget);
    final formattedAmount = CurrencyFormatter.format(1.0, 'USD');
    expect(find.text(formattedAmount), findsOneWidget);
    expect(find.text('Main account'), findsOneWidget);
    // avatar icon + name + description + currency + balance => 4 Text widgets
    expect(find.byType(Text), findsNWidgets(4));
  });

  testWidgets('AccountCard hides description when empty string', (
    WidgetTester tester,
  ) async {
    final account = Account(name: 'Testing', description: '', balance: 1.0);

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: AccountCard(account: account, onDelete: () {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Testing'), findsOneWidget);
    final formattedAmount = CurrencyFormatter.format(1.0, 'USD');
    expect(find.text(formattedAmount), findsOneWidget);
    // Empty string should not show a description; name + currency + balance => 3 Text widgets
    expect(find.byType(Text), findsNWidgets(3));
  });

  testWidgets('AccountCard long-press menu calls onEdit', (
    WidgetTester tester,
  ) async {
    bool editCalled = false;
    final account = Account(name: 'Testing', description: 'Main', balance: 1.0);

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: AccountCard(
            account: account,
            onDelete: () {},
            onEdit: () {
              editCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Trigger long-press to show the modal bottom sheet
    await tester.longPress(find.byType(AccountCard));
    await tester.pumpAndSettle();
    final editOption = find.text('Edit').first;
    expect(editOption, findsOneWidget);
    await tester.tap(editOption);
    await tester.pumpAndSettle();
    expect(editCalled, isTrue);
  });
}
