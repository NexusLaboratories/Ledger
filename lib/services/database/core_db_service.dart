import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:path/path.dart';

abstract class AbstractDatabaseService {
  Future<Database> openDB();
  Future<void> closeDB();
  Future<void> deleteDB();

  // Implement CRUD operations
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  });
  Future<int> insert(String table, Map<String, dynamic> values);
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  });
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action);

  // Execution support
  Future<void> execute(String sql, [List<dynamic>? arguments]);

  // Add optional raw queries if need to write your own SQL
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]);

  /// Ensure DB migrations that may be required across versions are applied.
  Future<void> ensureMigrations();
}

class DatabaseService implements AbstractDatabaseService {
  // Return a singleton instance upon creation of database service
  DatabaseService._privateConstructor();
  static final DatabaseService _instance =
      DatabaseService._privateConstructor();
  factory DatabaseService() => _instance;

  late final String _dbPath;
  final String _dbName = 'expense.db';
  String _password = '';
  Database? _db;
  bool _initialized = false;

  static final List<String> _tableCreationScripts = [
    '''
    CREATE TABLE IF NOT EXISTS users (
      user_id TEXT PRIMARY KEY,
      username TEXT UNIQUE,
      email TEXT UNIQUE,
      password_hash TEXT
    );
    ''',
    '''
    INSERT OR IGNORE INTO users (user_id, username, email, password_hash)
    VALUES ('local', 'local', 'local@local', '');
    ''',
    '''
    CREATE TABLE IF NOT EXISTS accounts (
      account_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      currency TEXT NOT NULL DEFAULT 'INR',
      account_name TEXT NOT NULL,
      account_description TEXT,
      balance REAL NOT NULL DEFAULT 0.0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
      UNIQUE (user_id, account_name)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS categories (
      category_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      parent_category_id TEXT,
      category_name TEXT NOT NULL,
      category_description TEXT,
      FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
      FOREIGN KEY (parent_category_id) REFERENCES categories (category_id) ON DELETE SET NULL,
      UNIQUE (user_id, category_name)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS tags (
      tag_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      parent_tag_id TEXT,
      tag_name TEXT NOT NULL,
      tag_description TEXT,
      tag_color INTEGER,
      tag_icon TEXT,
      FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
      FOREIGN KEY (parent_tag_id) REFERENCES tags (tag_id) ON DELETE SET NULL,
      UNIQUE (user_id, tag_name)
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transactions (
      transaction_id TEXT PRIMARY KEY,
      transaction_title TEXT NOT NULL,
      account_id TEXT NOT NULL,
      category_id TEXT,
      type INTEGER NOT NULL,
      amount REAL NOT NULL,
      date INTEGER NOT NULL,
      transaction_note TEXT,
      FOREIGN KEY (account_id) REFERENCES accounts (account_id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE SET NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transaction_items (
      item_id TEXT PRIMARY KEY,
      transaction_id TEXT NOT NULL,
      item_name TEXT NOT NULL,
      quantity REAL,
      price REAL,
      FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS transaction_tags (
      transaction_id TEXT NOT NULL,
      tag_id TEXT NOT NULL,
      PRIMARY KEY (transaction_id, tag_id),
      FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id) ON DELETE CASCADE,
      FOREIGN KEY (tag_id) REFERENCES tags (tag_id) ON DELETE CASCADE
    );
    ''',
    '''
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
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_budgets_user_category
    ON budgets(user_id, category_id);
    ''',
  ];

  // Name database and build database path
  @mustCallSuper
  Future<void> init() async {
    // Initialization is resilient: prefer to continue if non-critical
    // pieces (like user preference access) fail during tests.
    if (_initialized) return;
    try {
      // Guard user preference access and use default password if unavailable
      try {
        if (await UserPreferenceService.isDatabasePasswordSet()) {
          _password = await dbPassword;
        }
      } catch (e) {
        _password = '';
        LoggerService.w('Failed to retrieve database password', e);
      }

      String basePath;
      try {
        basePath = await getDatabasesPath();
      } catch (_) {
        // Fallback for tests/runtimes without plugin implementation
        basePath = Directory.systemTemp.path;
      }
      _dbPath = join(basePath, _dbName);
      _initialized = true;
    } catch (e) {
      // Initialization failed — throw a structured DatabaseInitializationException.
      throw DatabaseInitializationException();
    }
  }

  bool get isDBOpen => _isDBOpen();

  /// Get the current database path
  String get dbPath => _dbPath;

  @protected
  bool _isDBOpen() {
    // Returns 1 if DB is open and 0 if not
    return (_db != null);
  }

  @protected
  Future<void> _ensureDBOpen() async {
    if (!_isDBOpen()) {
      throw DatabaseNotOpenException();
    }
  }

  /// Ensure 'transaction_title' and 'transaction_note' columns exist on the
  /// transactions table and populate them from legacy columns if present.
  Future<void> _ensureTransactionColumns() async {
    if (!_isDBOpen()) throw DatabaseNotOpenException();
    await _ensureTransactionColumnsForDb(_db!);
  }

  Future<void> _ensureTransactionColumnsForDb(Database db) async {
    LoggerService.i('Checking transaction table columns...');
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['transactions'],
    );
    if (res.isEmpty) {
      LoggerService.i('Transactions table does not exist yet');
      return;
    }
    final info = await db.rawQuery("PRAGMA table_info('transactions');");
    final cols = info.map((r) => r['name'] as String).toList();
    LoggerService.i('Transaction table columns: ${cols.join(", ")}');
    if (!cols.contains('transaction_title')) {
      LoggerService.i('Adding transaction_title column...');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN transaction_title TEXT;',
      );
      if (cols.contains('title')) {
        LoggerService.i('Migrating data from legacy title column...');
        await db.execute(
          "UPDATE transactions SET transaction_title = title WHERE title IS NOT NULL;",
        );
      }
    }
    if (!cols.contains('transaction_note')) {
      LoggerService.i('Adding transaction_note column...');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN transaction_note TEXT;',
      );
    }
    LoggerService.i('Transaction table columns check complete');
  }

  Future<void> _ensureAccountCurrencyColumnForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['accounts'],
    );
    if (res.isEmpty) return;
    final info = await db.rawQuery("PRAGMA table_info('accounts');");
    final cols = info.map((r) => r['name'] as String).toList();
    if (!cols.contains('currency')) {
      await db.execute(
        'ALTER TABLE accounts ADD COLUMN currency TEXT NOT NULL DEFAULT "USD";',
      );
    }
  }

  Future<void> _ensureTagColorColumnForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['tags'],
    );
    if (res.isEmpty) return;
    final info = await db.rawQuery("PRAGMA table_info('tags');");
    final cols = info.map((r) => r['name'] as String).toList();
    if (!cols.contains('tag_color')) {
      await db.execute('ALTER TABLE tags ADD COLUMN tag_color INTEGER;');
    }
  }

  Future<void> _ensureTagIconColumnForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['tags'],
    );
    if (res.isEmpty) return;
    final info = await db.rawQuery("PRAGMA table_info('tags');");
    final cols = info.map((r) => r['name'] as String).toList();
    if (!cols.contains('tag_icon')) {
      await db.execute('ALTER TABLE tags ADD COLUMN tag_icon TEXT;');
    }
  }

  Future<void> _ensureBudgetsTableForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['budgets'],
    );
    if (res.isEmpty) {
      // Table doesn't exist, create it
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
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories (category_id) ON DELETE CASCADE
        );
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_budgets_user_category
        ON budgets(user_id, category_id);
      ''');
    }
  }

  Future<void> _ensureBudgetIconColumnForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['budgets'],
    );
    if (res.isEmpty) return;
    final info = await db.rawQuery("PRAGMA table_info('budgets');");
    final cols = info.map((r) => r['name'] as String).toList();
    if (!cols.contains('budget_icon')) {
      await db.execute('ALTER TABLE budgets ADD COLUMN budget_icon TEXT;');
    }
  }

  Future<void> _ensureCategoryIconColumnForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['categories'],
    );
    if (res.isEmpty) return;
    final info = await db.rawQuery("PRAGMA table_info('categories');");
    final cols = info.map((r) => r['name'] as String).toList();
    if (!cols.contains('category_icon')) {
      await db.execute('ALTER TABLE categories ADD COLUMN category_icon TEXT;');
    }
  }

  Future<void> _ensureAccountIconColumnForDb(Database db) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      ['accounts'],
    );
    if (res.isEmpty) return;
    final info = await db.rawQuery("PRAGMA table_info('accounts');");
    final cols = info.map((r) => r['name'] as String).toList();
    if (!cols.contains('account_icon')) {
      await db.execute('ALTER TABLE accounts ADD COLUMN account_icon TEXT;');
    }
  }

  @protected
  Future<String> get dbPassword => UserPreferenceService.getDBPassword();

  @override
  Future<void> ensureMigrations() async {
    // Ensure DB is open and apply any required migration checks
    if (!_isDBOpen()) await openDB();
    await _ensureTransactionColumns();
    // Ensure account currency column exists
    if (!_isDBOpen()) await openDB();
    await _ensureAccountCurrencyColumnForDb(_db!);
    // Ensure tag color column exists
    await _ensureTagColorColumnForDb(_db!);
    // Ensure tag icon column exists
    await _ensureTagIconColumnForDb(_db!);
    // Ensure budgets table exists
    await _ensureBudgetsTableForDb(_db!);
    // Ensure icon columns exist for budgets, categories, and accounts
    await _ensureBudgetIconColumnForDb(_db!);
    await _ensureCategoryIconColumnForDb(_db!);
    await _ensureAccountIconColumnForDb(_db!);
  }

  @override
  Future<Database> openDB() async {
    LoggerService.i('Opening database...');
    try {
      if (_isDBOpen()) {
        LoggerService.i('Database already open');
        return _db!;
      }

      // Ensure database is initialized first
      await init();

      // If running under Flutter's test environment, prefer the FFI database
      // factory to avoid platform plugin missing issues (e.g., on CI or dart VM).
      if (Platform.environment['FLUTTER_TEST'] == 'true') {
        LoggerService.i(
          'Running in test environment - using FFI database factory',
        );
        try {
          ffi.sqfliteFfiInit();
          final factory = ffi.databaseFactoryFfi;
          _db = await factory.openDatabase(
            _dbPath,
            options: ffi.OpenDatabaseOptions(
              version: 3,
              onCreate: (db, version) async {
                for (final script in _tableCreationScripts) {
                  await db.execute(script);
                }
              },
              onOpen: (db) async {
                await _ensureTransactionColumnsForDb(db);
                await _ensureAccountCurrencyColumnForDb(db);
                await _ensureTagColorColumnForDb(db);
                await _ensureBudgetsTableForDb(db);
              },
              onUpgrade: (db, oldVersion, newVersion) async {
                LoggerService.i(
                  'Database migration (FFI): v$oldVersion -> v$newVersion',
                );
                if (oldVersion < 2 && newVersion >= 2) {
                  await _ensureTransactionColumnsForDb(db);
                }
                await _ensureAccountCurrencyColumnForDb(db);
                await _ensureTagColorColumnForDb(db);
                if (oldVersion < 3 && newVersion >= 3) {
                  await _ensureBudgetsTableForDb(db);
                }
              },
            ),
          );

          return _db!;
        } catch (e) {
          LoggerService.e('FFI test database open failed', e);
          // Continue to try the normal plugin-based open path as a fallback.
        }
      }

      _db = await openDatabase(
        _dbPath,
        password: _password,
        version: 3,
        onCreate: (db, version) async {
          for (final script in _tableCreationScripts) {
            await db.execute(script);
          }
        },
        // When the DB opens, ensure any required columns exist across versions
        onOpen: (db) async {
          // Ensure that required columns exist in the transactions table, and
          // backfill from legacy columns if needed.
          // No-op: We rely on `_ensureTransactionColumnsForDb` to perform column
          // checks and migrations using the supplied `db` instance.

          await _ensureTransactionColumnsForDb(db);
          await _ensureAccountCurrencyColumnForDb(db);
          await _ensureTagColorColumnForDb(db);
          await _ensureBudgetsTableForDb(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Create automatic backup before migration
          LoggerService.i('Database migration: v$oldVersion -> v$newVersion');

          // Non-destructive migration path for version upgrades.
          // - For upgrade to v2, ensure `transaction_title` and `transaction_note` exist.
          if (oldVersion < 2 && newVersion >= 2) {
            await _ensureTransactionColumnsForDb(db);
          }

          // Ensure the account.currency column exists on upgrades
          await _ensureAccountCurrencyColumnForDb(db);

          // Ensure the tag.tag_color column exists on upgrades
          await _ensureTagColorColumnForDb(db);

          // - For upgrade to v3, ensure budgets table exists
          if (oldVersion < 3 && newVersion >= 3) {
            await _ensureBudgetsTableForDb(db);
          }

          LoggerService.i('Database migration completed successfully');

          // Future migrations should be added here. Keep onUpgrade non-destructive
          // to avoid losing user data.
        },
      );

      return _db!;
    } catch (e) {
      // Open DB failed — attempt FFI fallback when running in a test or desktop
      // environment where the platform plugin isn't available.
      LoggerService.e('Failed to open database', e);

      final message = e.toString();
      if (message.contains('MissingPluginException') ||
          message.contains('No implementation found for method')) {
        try {
          // Initialize ffi and open DB using the FFI factory
          ffi.sqfliteFfiInit();
          final factory = ffi.databaseFactoryFfi;
          _db = await factory.openDatabase(
            _dbPath,
            options: OpenDatabaseOptions(
              version: 3,
              onCreate: (db, version) async {
                for (final script in _tableCreationScripts) {
                  await db.execute(script);
                }
              },
              onOpen: (db) async {
                await _ensureTransactionColumnsForDb(db);
                await _ensureAccountCurrencyColumnForDb(db);
                await _ensureTagColorColumnForDb(db);
                await _ensureBudgetsTableForDb(db);
              },
              onUpgrade: (db, oldVersion, newVersion) async {
                LoggerService.i(
                  'Database migration (FFI): v$oldVersion -> v$newVersion',
                );
                if (oldVersion < 2 && newVersion >= 2) {
                  await _ensureTransactionColumnsForDb(db);
                }
                await _ensureAccountCurrencyColumnForDb(db);
                await _ensureTagColorColumnForDb(db);
                if (oldVersion < 3 && newVersion >= 3) {
                  await _ensureBudgetsTableForDb(db);
                }
              },
            ),
          );

          return _db!;
        } catch (e2) {
          LoggerService.e('FFI database fallback failed', e2);
        }
      }

      throw DatabaseInitializationException();
    }
  }

  /// Helper for tests: directly set the active DB instance and skip plugin
  /// initiated opening. This prevents platform plugin calls during unit tests
  /// and allows the FFI database factory to be used instead.
  @visibleForTesting
  void setDatabaseForTest(Database db) {
    _db = db;
    _initialized = true;
  }

  @visibleForTesting
  Future<void> setDatabasePathForTest(String path) async {
    _dbPath = path;
    _initialized = true;
  }

  /// Try to open DB with optional password. Returns true on success, false otherwise.
  Future<bool> tryOpenDBWithPassword({String? password}) async {
    final previousPassword = _password;
    final wasOpen = _isDBOpen();
    try {
      if (wasOpen) {
        await closeDB();
      }
      if (password != null) _password = password;
      await openDB();
      return _isDBOpen();
    } catch (e) {
      // revert to previous state on failure
      LoggerService.w('Failed to open database with password', e);
      try {
        if (_isDBOpen()) await closeDB();
      } catch (closeError) {
        LoggerService.w('Failed to close database during recovery', closeError);
      }
      _password = previousPassword;
      return false;
    }
  }

  @override
  Future<void> closeDB() async {
    if (_isDBOpen()) {
      await _db!.close();
      _db = null;
    }
  }

  @override
  Future<void> deleteDB() async {
    await closeDB();
    await deleteDatabase(_dbPath);
  }

  // Implement CRUD operations
  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Reduced logging verbosity
    if (!kReleaseMode) {
      LoggerService.d('DB Delete: $table');
    }
    try {
      await _ensureDBOpen();
      final count = await _db!.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      return count;
    } catch (e) {
      throw DatabaseDeleteException(e.toString());
    }
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    // Reduced logging verbosity
    if (!kReleaseMode) {
      LoggerService.d('DB Insert: $table');
    }
    try {
      await _ensureDBOpen();
      final result = await _db!.insert(table, values);
      return result;
    } catch (e) {
      // If the insert failed due to a missing column that we expect to exist
      // (e.g., `transaction_title`), attempt to add the columns and retry
      // once. This makes runtime migrations more robust when the app is
      // upgrading from older DB schemas.
      if (e.toString().contains('no column named transaction_title') ||
          e.toString().contains('no column named transaction_note')) {
        try {
          await _ensureDBOpen();
          await _ensureTransactionColumns();
          return await _db!.insert(table, values);
        } catch (_) {
          // If the retry fails, continue to throw a DatabaseInsertException
        }
      }
      throw DatabaseInsertException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Reduced logging verbosity - only log in debug mode
    if (!kReleaseMode) {
      LoggerService.d('DB Query: $table | Where: ${where ?? "all"}');
    }
    try {
      await _ensureDBOpen();
      final results = await _db!.query(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      return results;
    } catch (e) {
      throw DatabaseQueryException(e.toString());
    }
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    // Reduced logging verbosity
    if (!kReleaseMode) {
      LoggerService.d('DB Update: $table');
    }
    try {
      await _ensureDBOpen();
      final count = await _db!.update(
        table,
        values,
        where: where,
        whereArgs: whereArgs,
      );
      return count;
    } catch (e) {
      if (e.toString().contains('no column named transaction_title') ||
          e.toString().contains('no column named transaction_note')) {
        try {
          await _ensureDBOpen();
          await _ensureTransactionColumns();
          return await _db!.update(
            table,
            values,
            where: where,
            whereArgs: whereArgs,
          );
        } catch (_) {}
      }
      throw DatabaseUpdateException(e.toString());
    }
  }

  @override
  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    try {
      await _ensureDBOpen();
      await _db!.execute(sql, arguments);
    } catch (e) {
      throw DatabaseQueryException(e.toString());
    }
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    try {
      await _ensureDBOpen();
      return await _db!.transaction(action);
    } catch (e) {
      throw DatabaseQueryException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    try {
      await _ensureDBOpen();
      return await _db!.rawQuery(sql, arguments);
    } catch (e) {
      throw DatabaseQueryException(e.toString());
    }
  }
}
