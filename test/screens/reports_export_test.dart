import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/test_app.dart';
import 'package:ledger/screens/reports_screen.dart';
import 'package:ledger/services/report_service.dart';
import 'package:ledger/models/report_options.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:flutter/services.dart';

class FakeReportService extends ReportService {
  @override
  Future<Uint8List> generateReportPdf(
    ReportOptions options, {
    String currency = 'USD',
  }) async {
    // return small dummy pdf bytes
    return Uint8List.fromList([0, 1, 2, 3]);
  }
}

void main() {
  testWidgets('Reports export flow shows dialog and generates PDF', (
    tester,
  ) async {
    final fake = FakeReportService();

    await UserPreferenceService.setDBPassword(password: 'test');

    await tester.pumpWidget(TestApp(home: ReportsScreen(reportService: fake)));

    // Stub printing platform channel so sharePdf doesn't block tests
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/printing'),
      (call) async {
        return null;
      },
    );

    // Tap the export button in AppBar
    final exportFinder = find.byTooltip('Export report');
    expect(exportFinder, findsOneWidget);
    await tester.tap(exportFinder);
    // Use pump instead of pumpAndSettle to avoid timeout from RefreshIndicator animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Modal should show
    expect(find.text('Export Report'), findsOneWidget);

    // Press Export in modal
    await tester.tap(find.text('Export'));
    await tester.pump();

    // Should show generating snackbar
    expect(find.text('Generating PDF...'), findsOneWidget);

    // Let async operations start (avoid pumpAndSettle due to RefreshIndicator)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    // Clean up
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/printing'),
      null,
    );
  });
}
