import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';

void main() {
  testWidgets('Custom text button calls onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Click',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Click'), findsOneWidget);
    await tester.tap(find.text('Click'));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });
}
