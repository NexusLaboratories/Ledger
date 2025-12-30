import 'package:flutter_test/flutter_test.dart';
import 'test_helpers/mock_helpers.dart';
import 'package:ledger/services/service_locator.dart';

/// Global test configuration executed before tests.
///
/// The `testExecutable` function is invoked by the test runner and should
/// call `testMain` after registering any global setUp/tearDown handlers.
Future<void> testExecutable(Future<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Register the secure storage mock for all tests so platform channels
    // don't cause flaky behaviour across test files.
    registerSecureStorageMock();

    // Reset service locator and register default services so widgets that
    // rely on GetIt can access required services. Tests that inject services
    // explicitly will override these defaults.
    await getIt.reset();
    setupServiceLocator();
  });

  await testMain();
}
