import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/screens/dashboard_screen.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/account_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockAccountService extends Mock implements AbstractAccountService {}

void main() {
  group('Dashboard Add Transaction without account', () {
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
    });

    testWidgets(
      'Tapping Add Transaction shows create-account dialog when no accounts exist',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          TestApp(home: DashboardScreen(accountService: mockService)),
        );
        // Avoid a long pumpAndSettle because DB init may schedule async work; do a couple of frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final fab = find.byType(FloatingActionButton).first;
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        // Let the FAB/overlay show without waiting indefinitely for background work
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Add Transaction'));
        // Allow the dialog/menu to appear without waiting indefinitely
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

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
