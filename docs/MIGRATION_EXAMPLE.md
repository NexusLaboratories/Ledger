# Database Migration Example

## Scenario: Adding a "Recurring Transactions" Feature

Let's walk through a complete example of adding a new feature that requires database changes.

### Step 1: Plan the Changes

We want to add:
- A new `recurring_transactions` table
- A new `is_recurring` column to the `transactions` table

### Step 2: Update core_db_service.dart

#### 2.1 Increment the Database Version

```dart
_db = await openDatabase(
  _dbPath,
  password: _password,
  version: 4,  // ← Changed from 3 to 4
  ...
);
```

#### 2.2 Add Table Creation Script

Add to `_tableCreationScripts` list (for clean installs):

```dart
'''
CREATE TABLE IF NOT EXISTS recurring_transactions (
  recurring_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  transaction_title TEXT NOT NULL,
  amount REAL NOT NULL,
  frequency TEXT NOT NULL,
  next_occurrence INTEGER NOT NULL,
  account_id TEXT NOT NULL,
  category_id TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
  FOREIGN KEY (account_id) REFERENCES accounts (account_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE SET NULL
);
'''
```

#### 2.3 Create Migration Functions

```dart
// Add new column to existing table
Future<void> _ensureTransactionRecurringColumnForDb(Database db) async {
  final res = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
    ['transactions'],
  );
  if (res.isEmpty) return;

  final info = await db.rawQuery("PRAGMA table_info('transactions');");
  final cols = info.map((r) => r['name'] as String).toList();

  if (!cols.contains('is_recurring')) {
    debugPrint('CoreDBService: Adding is_recurring column to transactions');
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN is_recurring INTEGER DEFAULT 0;',
    );
  }
}

// Add new table
Future<void> _ensureRecurringTransactionsTableForDb(Database db) async {
  final res = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
    ['recurring_transactions'],
  );
  
  if (res.isEmpty) {
    debugPrint('CoreDBService: Creating recurring_transactions table');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recurring_transactions (
        recurring_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        transaction_title TEXT NOT NULL,
        amount REAL NOT NULL,
        frequency TEXT NOT NULL,
        next_occurrence INTEGER NOT NULL,
        account_id TEXT NOT NULL,
        category_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts (account_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE SET NULL
      );
    ''');
  }
}
```

#### 2.4 Update onUpgrade Callback

```dart
onUpgrade: (db, oldVersion, newVersion) async {
  debugPrint(
    'CoreDBService: Upgrading database from v$oldVersion to v$newVersion',
  );

  // Existing migrations...
  if (oldVersion < 2 && newVersion >= 2) {
    debugPrint('CoreDBService: Migrating to v2 - adding transaction columns');
    await _ensureTransactionColumnsForDb(db);
  }

  await _ensureAccountCurrencyColumnForDb(db);
  await _ensureTagColorColumnForDb(db);

  if (oldVersion < 3 && newVersion >= 3) {
    debugPrint('CoreDBService: Migrating to v3 - adding budgets table');
    await _ensureBudgetsTableForDb(db);
  }

  // NEW: Add v4 migration
  if (oldVersion < 4 && newVersion >= 4) {
    debugPrint('CoreDBService: Migrating to v4 - adding recurring transactions');
    await _ensureTransactionRecurringColumnForDb(db);
    await _ensureRecurringTransactionsTableForDb(db);
  }

  debugPrint('CoreDBService: Migration completed successfully');
},
```

#### 2.5 Update onOpen Callback

```dart
onOpen: (db) async {
  // Existing ensures...
  await _ensureTransactionColumnsForDb(db);
  await _ensureAccountCurrencyColumnForDb(db);
  await _ensureTagColorColumnForDb(db);
  await _ensureBudgetsTableForDb(db);
  
  // NEW: Add v4 ensures
  await _ensureTransactionRecurringColumnForDb(db);
  await _ensureRecurringTransactionsTableForDb(db);
},
```

#### 2.6 Update ensureMigrations() Method

```dart
@override
Future<void> ensureMigrations() async {
  if (_db == null) return;
  
  // Existing migrations...
  await _ensureTransactionColumnsForDb(_db!);
  await _ensureAccountCurrencyColumnForDb(_db!);
  await _ensureTagColorColumnForDb(_db!);
  await _ensureBudgetsTableForDb(_db!);
  
  // NEW: Add v4 migrations
  await _ensureTransactionRecurringColumnForDb(_db!);
  await _ensureRecurringTransactionsTableForDb(_db!);
}
```

### Step 3: Write Integration Test

Create test in `integration_test/database_migration_test.dart`:

```dart
test('migration from v3 to v4 adds recurring transactions', () async {
  final dbPath = join(
    await getDatabasesPath(),
    'expense_v4_migration_test.db',
  );

  await deleteDatabase(dbPath);

  // Create v3 database
  var db = await openDatabase(
    dbPath,
    password: '',
    version: 3,
    onCreate: (db, version) async {
      // Create v3 schema (without is_recurring column)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          transaction_id TEXT PRIMARY KEY,
          transaction_title TEXT NOT NULL,
          amount REAL NOT NULL,
          account_id TEXT NOT NULL,
          date INTEGER NOT NULL,
          type INTEGER NOT NULL
        );
      ''');
    },
  );

  // Insert v3 data
  await db.insert('transactions', {
    'transaction_id': 'txn-v3',
    'transaction_title': 'V3 Transaction',
    'amount': 100.0,
    'account_id': 'acc-1',
    'date': DateTime.now().millisecondsSinceEpoch,
    'type': 0,
  });

  await db.close();

  // Trigger migration to v4 by using the service
  final service = TransactionService();
  await service.createTransaction(
    title: 'Post-migration transaction',
    description: 'Created after v4 migration',
    amount: 50.0,
    accountId: 'acc-1',
    date: DateTime.now(),
    type: model_transaction.TransactionType.expense,
    categoryId: null,
  );

  // Verify migration worked
  db = await openDatabase(dbPath, password: '');
  
  // Check is_recurring column exists
  final info = await db.rawQuery("PRAGMA table_info('transactions');");
  final cols = info.map((r) => r['name'] as String).toList();
  expect(
    cols.contains('is_recurring'),
    true,
    reason: 'is_recurring column should exist after v4 migration',
  );

  // Check recurring_transactions table exists
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='recurring_transactions';",
  );
  expect(
    tables.isNotEmpty,
    true,
    reason: 'recurring_transactions table should exist after v4 migration',
  );

  // Verify old data preserved
  final transactions = await db.query('transactions');
  expect(transactions.length, 2);
  
  final v3Transaction = transactions.firstWhere(
    (t) => t['transaction_id'] == 'txn-v3',
  );
  expect(v3Transaction['transaction_title'], 'V3 Transaction');
  expect(v3Transaction['is_recurring'], 0); // Default value

  await db.close();
  await deleteDatabase(dbPath);
});
```

### Step 4: Test Locally

```bash
# Run all tests
flutter test && flutter test integration_test/

# Or run specific migration test
flutter test integration_test/database_migration_test.dart
```

### Step 5: Update Documentation

1. Update [docs/DATA_SAFETY.md](docs/DATA_SAFETY.md) with v4 changes
2. Update [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) with new schema
3. Add entry to migration history table

## What Happens for Users?

### Clean Install (New User)
1. App installs with v4 database
2. All tables created with current schema
3. `is_recurring` column already exists
4. `recurring_transactions` table ready to use

### Upgrade from v3 (Existing User)
1. App detects current DB version = 3, target = 4
2. `onUpgrade` callback fires
3. Migrations run:
   - `is_recurring` column added to transactions (default 0)
   - `recurring_transactions` table created
4. **All existing data preserved**
5. User sees all old transactions + new feature available

### Upgrade from v1 (Old User)
1. App detects current DB version = 1, target = 4
2. Migrations run in sequence:
   - v1 → v2: Add transaction_title, transaction_note
   - v2 → v3: Add currency, tag_color, budgets table
   - v3 → v4: Add is_recurring, recurring_transactions table
3. **All existing data preserved through all migrations**
4. User gets all new features

## Key Principles

✅ **Never use DROP TABLE or DROP COLUMN** - Always additive  
✅ **Always provide DEFAULT values** - So existing rows work  
✅ **Use IF NOT EXISTS** - Migrations are idempotent  
✅ **Test upgrade paths** - Not just clean installs  
✅ **Check before altering** - Use PRAGMA to verify column/table existence  
✅ **Log everything** - Makes debugging easier  

## Emergency Rollback

If something goes wrong:

1. User's data is backed up automatically before migration
2. You can restore from backup using `DatabaseBackupService`
3. Rollback app to previous version
4. Fix migration logic
5. Release hotfix

See [lib/services/database_backup_service.dart](lib/services/database_backup_service.dart) for backup utilities.
