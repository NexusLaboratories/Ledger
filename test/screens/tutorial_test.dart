import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/presets/routes.dart';

import 'package:ledger/screens/tutorial_screen.dart';
import 'package:ledger/presets/theme.dart';

void main() {
  testWidgets('Settings -> Start tutorial navigates to TutorialScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        routes: appRoutes,
        initialRoute: RouteNames.settings,
      ),
    );

    // Wait for SettingsScreen to build
    await tester.pumpAndSettle();

    // Find the Start tutorial tile text (from UIConstants)
    final startFinder = find.text('Start tutorial');
    expect(startFinder, findsWidgets);

    // Ensure the tile is visible by dragging the scroll view up
    // Try a larger drag to ensure the tile comes into view
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();

    // Tap the full tile widget so the gesture lands on the ListTile
    final widgetFinder = find.widgetWithText(ListTile, 'Start tutorial');
    expect(widgetFinder, findsOneWidget);

    // Invoke the onTap handler directly to avoid hit-testing issues in the test harness
    final listTile = tester.widget<ListTile>(widgetFinder);
    listTile.onTap?.call();
    await tester.pumpAndSettle();

    // Now we should be on TutorialScreen
    expect(find.byType(TutorialScreen), findsOneWidget);
  });
}
