import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/screens/settings_screen.dart';
import '../test_helpers/test_app.dart';

void main() {
  testWidgets('Settings screen shows new settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(TestApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Match theme with device'), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Enable notifications'), findsOneWidget);
    expect(find.text('Report reminders'), findsOneWidget);
    expect(find.text('Use biometric to unlock'), findsOneWidget);
    expect(find.text('Default currency'), findsOneWidget);
  });
}
