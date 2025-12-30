import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';

void main() {
  testWidgets('FloatingActionButton shows PopupMenu and calls callback', (
    WidgetTester tester,
  ) async {
    bool addTransactionCalled = false;
    bool addAccountCalled = false;

    final menuOptions = [
      {
        'title': 'Add Transaction',
        'onTap': () {
          addTransactionCalled = true;
        },
      },
      {
        'title': 'Add Account',
        'onTap': () {
          addAccountCalled = true;
        },
      },
    ];

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          floatingActionButton: CustomFloatingActionButton(
            menuOptions: menuOptions,
          ),
        ),
      ),
    );

    // Should find a FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap the FAB to open the menu (PopupMenuButton child uses disabled FAB but gesture should open it)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify menu options are shown
    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('Add Account'), findsOneWidget);

    // Tap the menu options
    await tester.tap(find.text('Add Transaction'));
    await tester.pumpAndSettle();

    expect(addTransactionCalled, isTrue);

    // Tap Add Account menu option and assert callback (re-open popup first)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Account'));
    await tester.pumpAndSettle();
    expect(addAccountCalled, isTrue);
  });
}
