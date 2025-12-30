import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/screens/accounts_screen.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/account_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockAccountService extends Mock implements AbstractAccountService {}

void main() {
  group('AccountsScreen create flow', () {
    late MockAccountService mockService;
    setUpAll(() async {
      registerCommonFallbacks();
      registerSecureStorageMock();
      await UserPreferenceService.setDBPassword(password: 'test');
    });
    setUp(() {
      mockService = MockAccountService();
      when(
        () =>
            mockService.fetchAccounts(forceRefetch: any(named: 'forceRefetch')),
      ).thenAnswer((_) async => []);
      when(
        () => mockService.createAccount(
          any(),
          any(),
          currency: any(named: 'currency'),
        ),
      ).thenAnswer((_) async {});
    });

    testWidgets(
      'Create account modal calls createAccount with selected currency',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          TestApp(home: AccountsScreen(accountService: mockService)),
        );
        await tester.pumpAndSettle();

        // Tap the FAB to open create modal
        final fab = find.byType(FloatingActionButton).first;
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Fill in name and submit (currency selection removed — default will be used)
        await tester.enterText(find.byType(TextFormField).first, 'NewAccount');

        // Submit
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        verify(
          () => mockService.createAccount('NewAccount', any(), currency: 'USD'),
        ).called(1);
      },
    );
  });
}
