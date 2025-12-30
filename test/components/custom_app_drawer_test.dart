import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';

void main() {
  testWidgets('Drawer contains navigation tiles', (tester) async {
    await tester.pumpWidget(TestApp(home: Scaffold(drawer: CustomAppDrawer())));

    // Open drawer
    ScaffoldState scaffoldState = tester.firstState(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Nexus'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
  });
}
