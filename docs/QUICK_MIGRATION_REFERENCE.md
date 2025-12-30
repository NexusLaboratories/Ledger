# Quick Migration Reference 🚀

## TL;DR: Your Data is Safe! ✅

**User data will NOT be lost when you make database changes.**

Your app has a robust migration system that:
- ✅ Automatically upgrades databases when users update the app
- ✅ Preserves all existing data during migrations
- ✅ Creates backups before migrations
- ✅ Has comprehensive tests to verify migrations work

## 30-Second Workflow

When you want to add new database features:

1. **Increment version** in [core_db_service.dart](../lib/services/database/core_db_service.dart):
   ```dart
   version: 4,  // Change from 3 to 4
   ```

2. **Add migration function**:
   ```dart
   Future<void> _ensureNewFeatureForDb(Database db) async {
     // Check if change already exists, if not, apply it
   }
   ```

3. **Update 3 callbacks**:
   - `onUpgrade` - for users upgrading from older versions
   - `onOpen` - for users already on current version
   - `ensureMigrations()` - for manual migration triggers

4. **Write integration test** in [integration_test/database_migration_test.dart](../integration_test/database_migration_test.dart)

5. **Run tests**:
   ```bash
   flutter test && flutter test integration_test/
   ```

That's it! ✨

## Golden Rules

| ✅ DO | ❌ DON'T |
|-------|----------|
| Use `ALTER TABLE ADD COLUMN` | Use `DROP TABLE` |
| Use `CREATE TABLE IF NOT EXISTS` | Use `DROP COLUMN` |
| Provide `DEFAULT` values for new columns | Delete user data |
| Copy data when renaming columns | Assume column exists without checking |
| Write integration tests | Skip testing migrations |
| Increment version number | Reuse version numbers |

## Migration Types Cheat Sheet

### Adding a Column
```dart
await db.execute(
  'ALTER TABLE my_table ADD COLUMN new_col TEXT DEFAULT "default";'
);
```

### Adding a Table
```dart
await db.execute('''
  CREATE TABLE IF NOT EXISTS new_table (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
  );
''');
```

### Renaming a Column (Copy Data)
```dart
// 1. Add new column
await db.execute('ALTER TABLE t ADD COLUMN new_name TEXT;');

// 2. Copy data from old column
await db.execute(
  'UPDATE t SET new_name = old_name WHERE old_name IS NOT NULL;'
);
```

## Real Example: v3 Migration

Here's how the app migrated from v2 → v3:

```dart
if (oldVersion < 3 && newVersion >= 3) {
  debugPrint('CoreDBService: Migrating to v3 - adding budgets table');
  await _ensureBudgetsTableForDb(db);
}
```

What happened for users:
- Users on v2: Automatically upgraded to v3, budgets table added, **all data preserved**
- Users on v1: Migrated v1 → v2 → v3, **all data preserved**
- New users: Start with v3, nothing to migrate

## Testing Your Migration

```bash
# Test a specific migration
flutter test integration_test/database_migration_test.dart

# Test all migrations
flutter test test/services/core_db_service_migration_test.dart

# Run everything
flutter test && flutter test integration_test/
```

## Backup & Restore

Your app has automatic backups! See [DatabaseBackupService](../lib/services/database_backup_service.dart):

```dart
// Create manual backup
final backupPath = await DatabaseBackupService().createBackup(
  prefix: 'before_big_change'
);

// List all backups
final backups = await DatabaseBackupService().listBackups();

// Restore from backup
await DatabaseBackupService().restoreBackup(backupPath);
```

## Common Scenarios

### Scenario: "I want to add a 'notes' field to accounts"

1. In `core_db_service.dart`:
   ```dart
   version: 4,  // Increment
   ```

2. Add function:
   ```dart
   Future<void> _ensureAccountNotesColumnForDb(Database db) async {
     final info = await db.rawQuery("PRAGMA table_info('accounts');");
     final cols = info.map((r) => r['name'] as String).toList();
     
     if (!cols.contains('notes')) {
       await db.execute(
         'ALTER TABLE accounts ADD COLUMN notes TEXT DEFAULT "";'
       );
     }
   }
   ```

3. Update `onUpgrade`:
   ```dart
   if (oldVersion < 4 && newVersion >= 4) {
     await _ensureAccountNotesColumnForDb(db);
   }
   ```

4. Update `onOpen` and `ensureMigrations()`:
   ```dart
   await _ensureAccountNotesColumnForDb(db);
   ```

5. Test it!

### Scenario: "I want to add a new 'goals' table"

Same process, but use `CREATE TABLE IF NOT EXISTS` in your ensure function.

## Help & Documentation

- 📖 **Full Guide**: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- 💡 **Complete Example**: [MIGRATION_EXAMPLE.md](MIGRATION_EXAMPLE.md)
- 🛡️ **Data Safety**: [DATA_SAFETY.md](DATA_SAFETY.md)
- 📝 **Implementation**: [../IMPLEMENTATION_SUMMARY.md](../IMPLEMENTATION_SUMMARY.md)

## Questions?

**Q: Will users lose data when I add a column?**  
A: No! The migration system adds columns with default values.

**Q: What if I need to rename a column?**  
A: Add new column, copy data from old column, use new column going forward. Old column can be ignored (SQLite doesn't allow DROP COLUMN easily).

**Q: Can I test migrations locally?**  
A: Yes! Integration tests simulate upgrade paths from older versions.

**Q: What if something goes wrong?**  
A: Backups are created automatically. You can restore from backup.

**Q: Do I need to handle multiple version upgrades (v1 → v4)?**  
A: No! The `onUpgrade` callback runs all intermediate migrations automatically.

## Summary

Your app has enterprise-grade database migration capabilities. Follow the workflow, write tests, and user data stays safe! 🎉
