import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // NOTE: This test requires platform channels (sqflite_sqlcipher) which aren't
  // available in the standard Flutter test environment. It should be moved to
  // integration_test/ and run as a proper integration test.
  // TODO: Move to integration_test/database_migration_test.dart
  test('migration adds transaction_title column and allows inserts', () async {
    // Test skipped in unit environment - will enable in integration tests
    final dbPath = join(await getDatabasesPath(), 'expense.db');
    // Ensure starting clean
    await deleteDatabase(dbPath);

    // Create a legacy schema with `title` column instead of `transaction_title`.
    final legacyDb = await openDatabase(
      dbPath,
      password: '',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            transaction_id TEXT PRIMARY KEY,
            title TEXT,
            transaction_note TEXT,
            amount REAL NOT NULL,
            account_id TEXT NOT NULL,
            date INTEGER NOT NULL,
            type INTEGER NOT NULL
          );
        ''');
      },
    );
    await legacyDb.close();

    // Now use our database service to insert a Transaction which should trigger
    // the migration and insert successfully.
    final service = TransactionService();
    final title = 'Legacy Test';
    final transaction = model_transaction.Transaction(
      title: title,
      amount: 1.0,
      accountId: 'acc-1',
      date: DateTime.now(),
      type: model_transaction.TransactionType.income,
    );

    // Should not throw
    await service.createTransaction(
      title: transaction.title,
      description: transaction.description,
      amount: transaction.amount,
      accountId: transaction.accountId,
      date: transaction.date,
      type: transaction.type,
      categoryId: null,
    );

    // Query the transactions table directly and assert the column exists
    final db = await openDatabase(dbPath, password: '');
    final info = await db.rawQuery("PRAGMA table_info('transactions');");
    final cols = info.map((r) => r['name'] as String).toList();
    expect(cols.contains('transaction_title'), isTrue);
    await db.close();
  }, skip: true);
}
