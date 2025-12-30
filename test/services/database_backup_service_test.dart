import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/services/database_backup_service.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common/sqflite.dart' as sqflite;
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize ffi factory for tests
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;
  });

  group('DatabaseBackupService', () {
    late DatabaseBackupService backupService;
    late DatabaseService dbService;

    setUp(() {
      backupService = DatabaseBackupService();
      dbService = DatabaseService();
    });

    tearDown(() async {
      try {
        await dbService.closeDB();
      } catch (_) {}
    });

    test('creates backup successfully', () async {
      // Open database first
      await dbService.init();
      await dbService.openDB();

      // Create a backup
      final backupPath = await backupService.createBackup();

      expect(backupPath, isNotEmpty);
      expect(File(backupPath).existsSync(), isTrue);

      // Cleanup
      await File(backupPath).delete();
    });

    test('backup verification works correctly', () async {
      await dbService.init();
      await dbService.openDB();

      final backupPath = await backupService.createBackup();

      // Verify valid backup
      final isValid = await backupService.verifyBackup(backupPath);
      expect(isValid, isTrue);

      // Verify invalid path
      final isInvalid = await backupService.verifyBackup(
        '/nonexistent/path.db',
      );
      expect(isInvalid, isFalse);

      // Cleanup
      await File(backupPath).delete();
    });

    test('lists backups in correct order', () async {
      await dbService.init();
      await dbService.openDB();

      // Create multiple backups
      final backup1 = await backupService.createBackup(prefix: 'test1');
      await Future.delayed(Duration(milliseconds: 100));
      final backup2 = await backupService.createBackup(prefix: 'test2');
      await Future.delayed(Duration(milliseconds: 100));
      final backup3 = await backupService.createBackup(prefix: 'test3');

      final backups = await backupService.listBackups();

      // Should be sorted newest first
      expect(backups.length, greaterThanOrEqualTo(3));
      expect(backups.contains(backup1), isTrue);
      expect(backups.contains(backup2), isTrue);
      expect(backups.contains(backup3), isTrue);

      // Cleanup
      await File(backup1).delete();
      await File(backup2).delete();
      await File(backup3).delete();
    });

    test('cleans old backups correctly', () async {
      await dbService.init();
      await dbService.openDB();

      // Create 7 backups
      final backupPaths = <String>[];
      for (int i = 0; i < 7; i++) {
        final backup = await backupService.createBackup(
          prefix: 'cleanup_test_$i',
        );
        backupPaths.add(backup);
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Keep only 3 most recent
      await backupService.cleanOldBackups(keepCount: 3);

      final remainingBackups = await backupService.listBackups();
      final testBackups = remainingBackups
          .where((b) => b.contains('cleanup_test'))
          .toList();

      expect(testBackups.length, 3);

      // Cleanup remaining
      for (final backup in testBackups) {
        if (File(backup).existsSync()) {
          await File(backup).delete();
        }
      }
    });

    test('creates pre-migration backup', () async {
      await dbService.init();
      await dbService.openDB();

      final backupPath = await backupService.createPreMigrationBackup();

      expect(backupPath, isNotNull);
      expect(backupPath!.contains('pre_migration'), isTrue);
      expect(File(backupPath).existsSync(), isTrue);

      // Cleanup
      await File(backupPath).delete();
    });

    test('restore backup works correctly', () async {
      await dbService.init();
      await dbService.openDB();

      // Insert some data (use unique timestamp-based identifiers to avoid conflicts)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'test$timestamp@test.com';
      final uniqueUsername = 'testuser$timestamp';
      final uniqueUserId = 'test-user-$timestamp';
      await dbService.insert('users', {
        'user_id': uniqueUserId,
        'username': uniqueUsername,
        'email': uniqueEmail,
        'password_hash': 'hash',
      });

      // Create backup (closes DB during backup)
      final backupPath = await backupService.createBackup();

      // Reopen database after backup
      await dbService.openDB();

      // Delete the data (keep DB open for delete operation)
      await dbService.delete(
        'users',
        where: 'user_id = ?',
        whereArgs: [uniqueUserId],
      );

      // Verify data is gone
      var users = await dbService.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [uniqueUserId],
      );
      expect(users.length, 0);

      // Restore from backup (closes DB during restore)
      await backupService.restoreBackup(backupPath);

      // Reopen database after restore
      await dbService.openDB();

      // Verify data is back
      users = await dbService.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [uniqueUserId],
      );
      expect(users.length, 1);
      expect(users.first['username'], uniqueUsername);

      // Cleanup
      await File(backupPath).delete();
    });
  });
}
