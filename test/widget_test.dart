// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/services/user_preference_service.dart';

import 'package:ledger/main.dart';
import 'package:ledger/constants/dashboard_constants.dart';

void main() {
  testWidgets('App starts and shows Dashboard', (WidgetTester tester) async {
    // Service locator and secure storage mock are already setup by global test config.
    // Set a database password so the DB password dialog is not shown at startup
    // (it blocks the UI and causes pumpAndSettle to time out).
    await UserPreferenceService.setDBPassword(password: 'test');

    // Build our app and trigger a frame. Use bounded pumps instead of
    // `pumpAndSettle` to avoid timing out due to ongoing animations in the
    // UI (e.g., progress indicators). A fixed short wait is sufficient for
    // startup work in tests.
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the Dashboard screen is visible.
    expect(find.text(DashboardConstants.netWorthSectionTitle), findsOneWidget);
  });
}
