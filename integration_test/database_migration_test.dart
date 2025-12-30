import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/database/core_db_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Database Migration Tests', () {
    test('migration from v1 to v3 preserves all data', () async {
      final dbPath = join(
        await getDatabasesPath(),
        'expense_migration_test.db',
      );

      // Ensure starting clean
      await deleteDatabase(dbPath);

      // Create a legacy schema (v1) with `title` column instead of `transaction_title`
      final legacyDb = await openDatabase(
        dbPath,
        password: '',
        version: 1,
        onCreate: (db, version) async {
          // Create v1 schema - accounts table without currency column
          await db.execute('''
            CREATE TABLE IF NOT EXISTS accounts (
              account_id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              account_name TEXT NOT NULL,
              account_description TEXT,
              balance REAL NOT NULL DEFAULT 0.0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
              UNIQUE (user_id, account_name)
            );
          ''');

          // Create v1 schema - transactions table with old column names
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

          // Create v1 schema - tags table without tag_color
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tags (
              tag_id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              parent_tag_id TEXT,
              tag_name TEXT NOT NULL,
              tag_description TEXT,
              FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
              FOREIGN KEY (parent_tag_id) REFERENCES tags (tag_id) ON DELETE SET NULL,
              UNIQUE (user_id, tag_name)
            );
          ''');
        },
      );

      // Insert legacy data - create account first
      await legacyDb.insert('accounts', {
        'account_id': 'acc-1',
        'user_id': 'local',
        'account_name': 'Test Account',
        'balance': 0.0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      await legacyDb.insert('transactions', {
        'transaction_id': 'txn-1',
        'title': 'Legacy Transaction',
        'transaction_note': 'This is a legacy transaction',
        'amount': 100.50,
        'account_id': 'acc-1',
        'date': DateTime.now().millisecondsSinceEpoch,
        'type': 0,
      });

      await legacyDb.close();

      // Tell DatabaseService to use the test DB path so migrations are
      // performed on the legacy DB file we created above.
      await DatabaseService().setDatabasePathForTest(dbPath);

      // Now use TransactionService which will trigger migration to latest version
      final service = TransactionService();
      final transaction = model_transaction.Transaction(
        title: 'New Transaction After Migration',
        amount: 50.75,
        accountId: 'acc-1',
        date: DateTime.now(),
        type: model_transaction.TransactionType.expense,
      );

      // Should not throw - migration should handle the schema upgrade
      await service.createTransaction(
        title: transaction.title,
        description: transaction.description,
        amount: transaction.amount,
        accountId: transaction.accountId,
        date: transaction.date,
        type: transaction.type,
        categoryId: null,
      );

      // Verify the database has been migrated properly
      final db = await openDatabase(dbPath, password: '');

      // Check transactions table has new column names
      final transactionInfo = await db.rawQuery(
        "PRAGMA table_info('transactions');",
      );
      final transactionCols = transactionInfo
          .map((r) => r['name'] as String)
          .toList();
      expect(
        transactionCols.contains('transaction_title'),
        isTrue,
        reason: 'transaction_title column should exist after migration',
      );

      // Verify old data was preserved and migrated
      final allTransactions = await db.query('transactions');
      expect(
        allTransactions.length,
        2,
        reason: 'Both legacy and new transactions should exist',
      );

      final legacyTransaction = allTransactions.firstWhere(
        (t) => t['transaction_id'] == 'txn-1',
      );
      expect(
        legacyTransaction['transaction_title'],
        'Legacy Transaction',
        reason: 'Legacy data should be migrated to new column',
      );

      // Check accounts table has currency column
      final accountInfo = await db.rawQuery("PRAGMA table_info('accounts');");
      final accountCols = accountInfo.map((r) => r['name'] as String).toList();
      expect(
        accountCols.contains('currency'),
        isTrue,
        reason: 'currency column should exist after migration',
      );

      // Check tags table has tag_color column
      final tagInfo = await db.rawQuery("PRAGMA table_info('tags');");
      final tagCols = tagInfo.map((r) => r['name'] as String).toList();
      expect(
        tagCols.contains('tag_color'),
        isTrue,
        reason: 'tag_color column should exist after migration',
      );

      // Check budgets table exists (v3 feature)
      final budgetTableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='budgets';",
      );
      expect(
        budgetTableExists.isNotEmpty,
        isTrue,
        reason: 'budgets table should exist after migration to v3',
      );

      await db.close();
      await deleteDatabase(dbPath);
    });

    test('migration handles multiple version upgrades', () async {
      final dbPath = join(
        await getDatabasesPath(),
        'expense_multi_upgrade_test.db',
      );

      await deleteDatabase(dbPath);

      // Simulate upgrading from v1 -> v2 -> v3
      var db = await openDatabase(
        dbPath,
        password: '',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS accounts (
              account_id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              account_name TEXT NOT NULL,
              balance REAL NOT NULL DEFAULT 0.0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
              transaction_id TEXT PRIMARY KEY,
              title TEXT,
              amount REAL NOT NULL,
              account_id TEXT NOT NULL,
              date INTEGER NOT NULL,
              type INTEGER NOT NULL
            );
          ''');
        },
      );

      await db.insert('accounts', {
        'account_id': 'acc-1',
        'user_id': 'local',
        'account_name': 'Test Account',
        'balance': 0.0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      await db.insert('transactions', {
        'transaction_id': 'txn-v1',
        'title': 'V1 Transaction',
        'amount': 25.0,
        'account_id': 'acc-1',
        'date': DateTime.now().millisecondsSinceEpoch,
        'type': 0,
      });

      await db.close();

      // Point DatabaseService at the test DB and open with current version -
      // should trigger all migrations
      await DatabaseService().setDatabasePathForTest(dbPath);
      final service = TransactionService();
      await service.createTransaction(
        title: 'Post-migration transaction',
        description: 'Created after migration',
        amount: 75.0,
        accountId: 'acc-1',
        date: DateTime.now(),
        type: model_transaction.TransactionType.income,
        categoryId: null,
      );

      // Verify all data preserved
      db = await openDatabase(dbPath, password: '');
      final transactions = await db.query('transactions');
      expect(transactions.length, 2);

      final v1Transaction = transactions.firstWhere(
        (t) => t['transaction_id'] == 'txn-v1',
      );
      expect(v1Transaction['transaction_title'], 'V1 Transaction');

      await db.close();
      await deleteDatabase(dbPath);
    });

    test('migration preserves foreign key relationships', () async {
      final dbPath = join(await getDatabasesPath(), 'expense_fk_test.db');

      await deleteDatabase(dbPath);

      // Create legacy database with related data
      final legacyDb = await openDatabase(
        dbPath,
        password: '',
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              user_id TEXT PRIMARY KEY,
              username TEXT UNIQUE
            );
          ''');

          await db.execute('''
            INSERT INTO users (user_id, username) VALUES ('local', 'testuser');
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS accounts (
              account_id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              account_name TEXT NOT NULL,
              balance REAL NOT NULL DEFAULT 0.0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
            );
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS transactions (
              transaction_id TEXT PRIMARY KEY,
              title TEXT,
              amount REAL NOT NULL,
              account_id TEXT NOT NULL,
              date INTEGER NOT NULL,
              type INTEGER NOT NULL,
              FOREIGN KEY (account_id) REFERENCES accounts (account_id) ON DELETE CASCADE
            );
          ''');
        },
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      await legacyDb.insert('accounts', {
        'account_id': 'acc-1',
        'user_id': 'local',
        'account_name': 'Test Account',
        'balance': 100.0,
        'created_at': now,
        'updated_at': now,
      });

      await legacyDb.insert('transactions', {
        'transaction_id': 'txn-1',
        'title': 'Test Transaction',
        'amount': 50.0,
        'account_id': 'acc-1',
        'date': now,
        'type': 0,
      });

      await legacyDb.close();

      // Trigger migration
      final service = TransactionService();
      await service.createTransaction(
        title: 'New Transaction',
        description: null,
        amount: 25.0,
        accountId: 'acc-1',
        date: DateTime.now(),
        type: model_transaction.TransactionType.expense,
        categoryId: null,
      );

      // Verify foreign key relationships still work
      final db = await openDatabase(dbPath, password: '');

      final transactions = await db.query('transactions');
      expect(transactions.length, 2);

      // All transactions should still reference the account
      for (final txn in transactions) {
        expect(txn['account_id'], 'acc-1');
      }

      await db.close();
      await deleteDatabase(dbPath);
    });
  });
}
