# Database Migration Quick Reference

## For Developers: Adding New Database Changes

### Adding a New Column

1. **Create the migration function**:
```dart
Future<void> _ensureNewColumnForDb(Database db) async {
  final res = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
    ['table_name'],
  );
  if (res.isEmpty) return;
  
  final info = await db.rawQuery("PRAGMA table_info('table_name');");
  final cols = info.map((r) => r['name'] as String).toList();
  
  if (!cols.contains('new_column')) {
    await db.execute(
      'ALTER TABLE table_name ADD COLUMN new_column TEXT DEFAULT "default_value";',
    );
  }
}
```

2. **Add to version upgrade logic**:
```dart
onUpgrade: (db, oldVersion, newVersion) async {
  if (oldVersion < 4 && newVersion >= 4) {
    debugPrint('CoreDBService: Migrating to v4 - adding new_column');
    await _ensureNewColumnForDb(db);
  }
}
```

3. **Add to onOpen callback** (for existing v4 databases):
```dart
onOpen: (db) async {
  await _ensureNewColumnForDb(db);
}
```

4. **Increment database version**:
```dart
version: 4,  // Increment from 3 to 4
```

### Adding a New Table

1. **Add table creation script** to `_tableCreationScripts`:
```dart
'''
CREATE TABLE IF NOT EXISTS new_table (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);
'''
```

2. **Create ensure function**:
```dart
Future<void> _ensureNewTableForDb(Database db) async {
  final res = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
    ['new_table'],
  );
  if (res.isEmpty) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS new_table (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
      );
    ''');
  }
}
```

3. **Add to upgrade paths**.

### Migrating Data Between Columns

When renaming a column:

```dart
if (!cols.contains('new_name')) {
  // Add new column
  await db.execute('ALTER TABLE t ADD COLUMN new_name TEXT;');
  
  // Copy data if old column exists
  if (cols.contains('old_name')) {
    await db.execute(
      'UPDATE t SET new_name = old_name WHERE old_name IS NOT NULL;',
    );
  }
}
```

### Pre-Deployment Checklist

Before releasing a version with database changes:

- [ ] Increment database version number
- [ ] Add migration to `onUpgrade` with version check
- [ ] Add to `onOpen` callback
- [ ] Add to `ensureMigrations()` if needed
- [ ] Update `_tableCreationScripts` for clean installs
- [ ] Write integration test for the migration
- [ ] Test upgrade from previous version(s)
- [ ] Update DATA_SAFETY.md
- [ ] Test backup/restore functionality
- [ ] Run all tests: `flutter test && flutter test integration_test/`

### Testing Migrations

```bash
# Run unit tests
flutter test test/services/core_db_service_migration_test.dart

# Run integration tests
flutter test integration_test/database_migration_test.dart

# Run all tests
flutter test && flutter test integration_test/
```

### Common Pitfalls to Avoid

❌ **DON'T** delete columns (SQLite doesn't support this easily)
❌ **DON'T** use destructive migrations
❌ **DON'T** forget to update version number
❌ **DON'T** forget to add to both `onUpgrade` AND `onOpen`
❌ **DON'T** assume old data will be empty

✅ **DO** add columns with defaults
✅ **DO** preserve existing data
✅ **DO** test upgrade paths
✅ **DO** use transactions for complex migrations
✅ **DO** log migration steps

### Emergency Rollback

If a migration causes issues in production:

1. **Identify affected users**
2. **Instruct users to restore from backup**:
   ```dart
   final backups = await DatabaseBackupService().listBackups();
   await DatabaseBackupService().restoreBackup(backups.first);
   ```
3. **Release hotfix with corrected migration**
4. **Test thoroughly before re-release**

### Database Version History

| Version | Date | Changes | Migration Path |
|---------|------|---------|----------------|
| 1 | Initial | Base schema | N/A |
| 2 | 2024 | transaction_title, transaction_note | Data copied from `title` |
| 3 | 2024 | currency, tag_color, budgets table | Defaults applied |
| 4 | TBD | Future changes | TBD |

### Useful SQL Commands for Debugging

```sql
-- Check table structure
PRAGMA table_info('transactions');

-- List all tables
SELECT name FROM sqlite_master WHERE type='table';

-- Check foreign keys
PRAGMA foreign_key_list('transactions');

-- Check database version
PRAGMA user_version;

-- Count rows
SELECT COUNT(*) FROM transactions;
```

### Contact

For questions about database migrations, see:
- `docs/DATA_SAFETY.md` - Comprehensive safety guide
- `lib/services/database/core_db_service.dart` - Implementation
- `integration_test/database_migration_test.dart` - Test examples
