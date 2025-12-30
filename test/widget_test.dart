// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/dashboard_service.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/dashboard_widget.dart';
import 'package:ledger/models/widget_layout.dart';
import 'package:ledger/screens/dashboard_screen.dart';

import 'package:ledger/constants/dashboard_constants.dart';
import 'test_helpers/test_app.dart';

// Minimal fake services used to avoid DB/plugin initialization in widget tests
class FakeAccountService implements AbstractAccountService {
  @override
  Future<double> fetchNetWorth({String? inCurrency}) async => 0.0;

  @override
  Future<List<Account?>> fetchAccounts({bool forceRefetch = false}) async => [];

  @override
  Future<void> createAccount(
    String accountName,
    String? accountDescription, {
    String? currency,
    String? iconId,
  }) async {}

  @override
  Future<void> deleteAccount(String accountId) async {}

  @override
  Future<void> updateAccount(Account account) async {}

  @override
  dynamic init() {}
}

class FakeDashboardService implements AbstractDashboardService {
  @override
  Future<List<DashboardWidget>> getDashboardWidgets() async => [];

  @override
  Future<List<WidgetLayout>> getDashboardLayouts() async => [];

  @override
  Future<void> saveDashboardWidgets(List<DashboardWidget> widgets) async {}

  @override
  Future<void> saveDashboardLayouts(List<WidgetLayout> layouts) async {}

  @override
  Future<void> updateWidgetLayout(String widgetId, WidgetLayout layout) async {}

  @override
  Future<void> reorderWidgets(List<String> widgetIds) async {}

  @override
  Future<void> initializeDefaultDashboard() async {}
}

void main() {
  // Use a focused test that avoids the global app startup to be
  // more deterministic in unit tests. Pump the DashboardScreen directly
  // with simple fake services so it doesn't rely on global initialization.
  testWidgets('App starts and shows Dashboard', (WidgetTester tester) async {
    final fakeAccountService = FakeAccountService();
    final fakeDashboardService = FakeDashboardService();

    await tester.pumpWidget(
      TestApp(
        home: DashboardScreen(
          accountService: fakeAccountService,
          dashboardService: fakeDashboardService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the Dashboard screen is visible.
    expect(find.text(DashboardConstants.netWorthSectionTitle), findsOneWidget);
  });
}
