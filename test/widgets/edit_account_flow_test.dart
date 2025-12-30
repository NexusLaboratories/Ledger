import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/screens/accounts_screen.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/components/accounts/account_card.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/services/account_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockAccountService extends Mock implements AbstractAccountService {}

void main() {
  group('AccountsScreen edit flow', () {
    late MockAccountService mockService;
    late Account sampleAccount;

    setUpAll(() async {
      registerCommonFallbacks();
      registerSecureStorageMock();
      await UserPreferenceService.setDBPassword(password: 'test');
    });

    setUp(() {
      mockService = MockAccountService();
      sampleAccount = Account(
        id: 'a1',
        name: 'Test',
        description: 'Desc',
        balance: 1.0,
      );

      when(
        () =>
            mockService.fetchAccounts(forceRefetch: any(named: 'forceRefetch')),
      ).thenAnswer((_) async => [sampleAccount]);
      when(() => mockService.updateAccount(any())).thenAnswer((_) async {});
      when(() => mockService.deleteAccount(any())).thenAnswer((_) async {});
    });

    testWidgets('Edit account via modal calls updateAccount with new currency', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        TestApp(home: AccountsScreen(accountService: mockService)),
      );
      await tester.pumpAndSettle();

      // Long-press the account card to show edit/delete options
      await tester.longPress(find.byType(AccountCard).first);
      await tester.pumpAndSettle();
      final editOption = find.text('Edit').first;
      expect(editOption, findsOneWidget);
      await tester.tap(editOption);
      await tester.pumpAndSettle();

      // Tap Update (currency selection removed — account will use default currency)
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Verify that updateAccount was invoked and the account currency is the app default
      final verification = verify(
        () => mockService.updateAccount(captureAny()),
      );
      verification.called(1);
      final captured = verification.captured.single as Account;
      expect(captured.currency, equals('USD'));
    });
  });
}
