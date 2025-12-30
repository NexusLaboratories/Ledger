import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common/sqflite.dart' as sqflite;
import 'package:ledger/services/database/core_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'DatabaseService migration adds currency column to accounts table',
    () async {
      // Initialize ffi factory for tests
      ffi.sqfliteFfiInit();
      // Ensure the global databaseFactory is set so code using sqflite's
      // global helpers (e.g. getDatabasesPath) work during tests.
      sqflite.databaseFactory = ffi.databaseFactoryFfi;

      final dbName = 'expense.db';
      final dbPath = join(await ffi.getDatabasesPath(), dbName);
      // Ensure clean start
      try {
        await ffi.deleteDatabase(dbPath);
      } catch (_) {}

      // Create a legacy DB with accounts table WITHOUT currency column
      final db = await ffi.databaseFactoryFfi.openDatabase(
        dbPath,
        options: ffi.OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
          CREATE TABLE accounts (
            account_id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            account_name TEXT NOT NULL,
            account_description TEXT,
            balance REAL NOT NULL DEFAULT 0.0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
          },
        ),
      );
      await db.close();
      // Reopen and insert a legacy account without currency
      final db2 = await ffi.databaseFactoryFfi.openDatabase(dbPath);
      await db2.insert('accounts', {
        'account_id': 'legacy-1',
        'user_id': 'local',
        'account_name': 'Legacy',
        'account_description': 'Legacy desc',
        'balance': 10.0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      // Keep db2 open and inject directly into DatabaseService for tests
      // Open via DatabaseService and call ensureMigrations which should add 'currency'
      // Debug prints removed to keep test output clean.
      final service = DatabaseService();
      // Inject the directly opened DB (from ffi) into the service to avoid the
      // Sqflite plugin which isn't available in unit tests. Set the DB before
      // calling `init()` so the service doesn't attempt to open the same file
      // (which can cause a lock when the test-managed connection is already open).
      service.setDatabaseForTest(db2);
      try {
        await service.init();
      } catch (e) {
        // Rethrow the exception so the test fails and shows stack trace
        rethrow;
      }
      await service.ensureMigrations();

      await service.query('accounts');
      // Check that PRAGMA table_info has 'currency' column
      final res = await service.query(
        "sqlite_master",
        where: "name = ?",
        whereArgs: ['accounts'],
      );
      expect(res.isNotEmpty, true);

      await service.query('accounts');

      // To ensure column exists in schema, run PRAGMA
      final openedDb = await ffi.databaseFactoryFfi.openDatabase(dbPath);
      final pragma = await openedDb.rawQuery("PRAGMA table_info('accounts');");
      final cols = pragma.map((r) => r['name'] as String).toList();
      expect(cols.contains('currency'), true);

      // Ensure the legacy row has default 'USD' in the new column
      final rows = await openedDb.rawQuery(
        "SELECT currency FROM accounts WHERE account_name = ?;",
        ['Legacy'],
      );
      await openedDb.close();
      expect(rows, isNotEmpty);
      expect(rows.first['currency'], 'USD');

      // Clean up
      await service.closeDB();
      try {
        await ffi.deleteDatabase(dbPath);
      } catch (_) {}
    },
  );
}
