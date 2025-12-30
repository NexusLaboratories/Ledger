# Data Safety & Migration Guide

## Overview

This document explains how the Ledger app ensures user data is **never lost during app updates**. The app uses a robust database migration system that preserves all existing data when upgrading between versions.

## Key Protection Mechanisms

### 1. Non-Destructive Schema Migrations

The database uses SQLite with version management. When the app is updated:

- **Current Version**: 3
- **Migration Path**: v1 → v2 → v3 (all migrations preserve data)

#### Migration History

| Version | Changes | Data Preservation |
|---------|---------|-------------------|
| v1 | Initial schema | N/A |
| v2 | Added `transaction_title` and `transaction_note` columns | Migrates data from legacy `title` column |
| v3 | Added `currency` to accounts, `tag_color` to tags, `budgets` table | All existing data preserved, new columns use defaults |

### 2. Automatic Column Migration

The app automatically detects and migrates schema changes:

```dart
// Example: transaction_title migration
// Old schema: 'title' column
// New schema: 'transaction_title' column
// Migration: Data is automatically copied from 'title' to 'transaction_title'
```

**Migration Points**:
- `_ensureTransactionColumnsForDb()` - Handles transaction schema changes
- `_ensureAccountCurrencyColumnForDb()` - Adds currency support to accounts
- `_ensureTagColorColumnForDb()` - Adds color customization to tags
- `_ensureBudgetsTableForDb()` - Creates budgets table if missing

### 3. Multiple Entry Points for Migrations

Migrations can be triggered at several points to ensure robustness:

1. **onUpgrade callback** - When database version number increases
2. **onOpen callback** - Every time database opens (ensures missed migrations are applied)
3. **ensureMigrations()** - Can be called explicitly by services
4. **Runtime error recovery** - If a column is missing during insert/update, migration is attempted

### 4. Database Backup Service

A dedicated backup service provides additional data protection:

#### Features

- **Automatic backups before migrations**
- **Manual backup creation**
- **Backup verification**
- **Restore functionality**
- **Import/Export capabilities**
- **Automatic cleanup of old backups**

#### Usage

```dart
final backupService = DatabaseBackupService();

// Create a backup before migration
await backupService.createPreMigrationBackup();

// List all backups
final backups = await backupService.listBackups();

// Restore from backup
await backupService.restoreBackup(backupPath);

// Export database for user backup
await backupService.exportDatabase('/path/to/save');

// Import database from backup
await backupService.importDatabase('/path/to/import');
```

## How Updates Work

### Scenario 1: Clean Install (No Existing Data)

1. User installs app
2. Database is created with latest schema (v3)
3. All tables created with current structure
4. No migration needed

### Scenario 2: Update from v1

1. User updates app from version with DB v1
2. App detects current DB version = 1, target version = 3
3. **onUpgrade** callback is triggered
4. Migrations applied: v1 → v2, v2 → v3
5. All existing data preserved and migrated
6. User sees all their old data with new features

### Scenario 3: Update from v2

1. User updates app from version with DB v2
2. App detects current DB version = 2, target version = 3
3. **onUpgrade** callback is triggered
4. Migration applied: v2 → v3
5. All existing data preserved
6. New features (budgets) become available

## Data Integrity Guarantees

### Foreign Key Relationships

Foreign key constraints ensure referential integrity:

```sql
-- Cascading deletes prevent orphaned records
FOREIGN KEY (account_id) REFERENCES accounts (account_id) ON DELETE CASCADE
FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
```

### Transaction Safety

Database operations use transactions to ensure atomicity:

```dart
await db.transaction((txn) async {
  // All operations succeed or all fail
  await txn.insert(...);
  await txn.update(...);
});
```

### Column Defaults

New columns have safe defaults to prevent data loss:

```sql
-- Currency defaults to USD if not specified
currency TEXT NOT NULL DEFAULT 'USD'

-- Balance defaults to 0.0
balance REAL NOT NULL DEFAULT 0.0

-- Active budgets by default
is_active INTEGER NOT NULL DEFAULT 1
```

## Testing Strategy

### Unit Tests

Located in `test/services/`:
- Test individual migration functions
- Verify column additions
- Check data preservation logic

### Integration Tests

Located in `integration_test/`:
- **database_migration_test.dart** - End-to-end migration testing
  - Test v1 → v3 upgrade path
  - Test multiple version upgrades
  - Test foreign key preservation
  - Test data integrity after migration

#### Running Integration Tests

```bash
# Run all integration tests
flutter test integration_test/

# Run specific test
flutter test integration_test/database_migration_test.dart
```

### Manual Testing Checklist

Before releasing updates:

- [ ] Test clean install
- [ ] Test upgrade from previous version
- [ ] Verify all old data is visible
- [ ] Verify new features work
- [ ] Test database backup/restore
- [ ] Verify foreign key relationships
- [ ] Check database encryption still works

## Best Practices for Future Updates

### When Adding New Tables

```dart
// In onUpgrade callback
if (oldVersion < 4 && newVersion >= 4) {
  await _ensureNewTableForDb(db);
}
```

### When Adding New Columns

```dart
Future<void> _ensureNewColumnForDb(Database db) async {
  final info = await db.rawQuery("PRAGMA table_info('table_name');");
  final cols = info.map((r) => r['name'] as String).toList();
  
  if (!cols.contains('new_column')) {
    await db.execute(
      'ALTER TABLE table_name ADD COLUMN new_column TEXT;',
    );
    // Optionally backfill data from old columns
  }
}
```

### When Renaming Columns

**Don't delete old columns immediately!** Instead:

1. Add new column
2. Copy data from old to new
3. Keep old column for several versions
4. Eventually mark as deprecated
5. Remove in future major version

```dart
// Good: Preserves data
await db.execute('ALTER TABLE t ADD COLUMN new_name TEXT;');
await db.execute('UPDATE t SET new_name = old_name WHERE old_name IS NOT NULL;');

// Bad: Loses data
// await db.execute('ALTER TABLE t DROP COLUMN old_name;'); // SQLite doesn't support this anyway
```

## Recovery Procedures

### If Migration Fails

1. **Automatic safety backup** is created before each migration
2. Check logs for specific error
3. Use backup service to restore previous working state:

```dart
final backups = await DatabaseBackupService().listBackups();
final latestBackup = backups.first;
await DatabaseBackupService().restoreBackup(latestBackup);
```

### If Database is Corrupted

1. Try to export data if possible
2. User can restore from automatic backup
3. As last resort, database can be recreated (data loss!)

### User-Initiated Recovery

Users can:
- Export their database for safekeeping
- Import a previously exported database
- View list of automatic backups
- Restore from any backup

## Database Encryption

The app uses SQLCipher for database encryption:

- Password stored securely using `flutter_secure_storage`
- Database encrypted at rest
- Migration preserves encryption

## Version Control

Current database version is managed in:
- **File**: `lib/services/database/core_db_service.dart`
- **Constant**: `version: 3` in `openDatabase()` call

When incrementing version:
1. Update version number
2. Add migration logic in `onUpgrade`
3. Update this documentation
4. Add integration tests
5. Create backup before rollout

## Monitoring & Logging

All database operations log to debug console:

```
CoreDBService: DB opened successfully
CoreDBService: Migration applied from v2 to v3
DatabaseBackupService: Backup created at /path/to/backup
```

Monitor logs for:
- Migration errors
- Schema mismatches
- Data integrity issues

## Emergency Contact

If data loss is reported:
1. Check app logs immediately
2. Identify which migration failed
3. Check if backup was created
4. Restore from backup if needed
5. Fix migration logic
6. Release hotfix

## Summary

**User data is protected through**:
1. ✅ Non-destructive schema migrations
2. ✅ Automatic column migration with data preservation
3. ✅ Multiple migration trigger points
4. ✅ Comprehensive backup system
5. ✅ Integration tests verifying migration paths
6. ✅ Foreign key constraints
7. ✅ Transaction safety
8. ✅ Safe defaults for new columns
9. ✅ Database encryption
10. ✅ Runtime error recovery

**Users will NEVER lose data during app updates** as long as migration best practices are followed.
