import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common/sqflite.dart' as sqflite;
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/models/budget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Can create and fetch a budget from DB', () async {
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;

    final dbName = 'expense.db';
    final dbPath = join(await ffi.getDatabasesPath(), dbName);
    try {
      await ffi.deleteDatabase(dbPath);
    } catch (_) {}

    // Open DB using ffi factory so we can use setDatabaseForTest
    final db = await ffi.databaseFactoryFfi.openDatabase(
      dbPath,
      options: ffi.OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {},
      ),
    );

    // Manually create budgets table since DatabaseService.openDB uses the `sqflite_sqlcipher` plugin
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        budget_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT,
        budget_name TEXT NOT NULL,
        amount REAL NOT NULL,
        period INTEGER NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    final service = DatabaseService();
    service.setDatabaseForTest(db);

    final budgetService = BudgetService();
    final newBudget = Budget(
      userId: 'local',
      name: 'Test Budget',
      amount: 123.45,
      period: BudgetPeriod.monthly,
      startDate: DateTime.now(),
    );

    await budgetService.createBudget(newBudget);

    final budgets = await budgetService.fetchBudgets('local');
    expect(budgets.isNotEmpty, true);
    final found = budgets.any((b) => b.name == 'Test Budget');
    expect(found, true);

    await service.closeDB();
    try {
      await ffi.deleteDatabase(dbPath);
    } catch (_) {}
  });
}
