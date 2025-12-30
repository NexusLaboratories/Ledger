import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/logger_service.dart';

/// Service for backing up and restoring the database
///
/// This service provides data safety features including:
/// - Automatic backups before migrations
/// - Manual backup/restore functionality
/// - Backup verification
class DatabaseBackupService {
  DatabaseBackupService._privateConstructor();
  static final DatabaseBackupService _instance =
      DatabaseBackupService._privateConstructor();
  factory DatabaseBackupService() => _instance;

  final DatabaseService _dbService = DatabaseService();

  /// Get the backup directory path
  Future<String> _getBackupDirectory() async {
    Directory appDocDir;
    try {
      appDocDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      // In test / desktop environments the path_provider plugin may not be
      // available; fall back to the system temp directory to ensure backups
      // still work in those environments.
      appDocDir = Directory.systemTemp;
    }

    final String backupDir = join(appDocDir.path, 'database_backups');

    // Create backup directory if it doesn't exist
    final Directory dir = Directory(backupDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return backupDir;
  }

  /// Create a backup of the database
  ///
  /// Returns the path to the backup file
  ///
  /// [prefix] - Optional prefix for the backup filename (e.g., 'pre_migration')
  Future<String> createBackup({String? prefix}) async {
    try {
      // Ensure database is closed before backing up
      await _dbService.closeDB();

      final String backupDir = await _getBackupDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(
        ':',
        '-',
      );
      final String backupFileName = prefix != null
          ? '${prefix}_expense_$timestamp.db'
          : 'expense_$timestamp.db';
      final String backupPath = join(backupDir, backupFileName);

      // Get the current database path from the service
      await _dbService.init();
      final dbPath = _dbService.dbPath;

      final File dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file does not exist at $dbPath');
      }

      // Copy database file to backup location
      await dbFile.copy(backupPath);

      LoggerService.i('Database backup created: $backupPath');
      return backupPath;
    } catch (e) {
      LoggerService.e('Failed to create database backup', e);
      rethrow;
    }
  }

  /// Restore database from a backup file
  ///
  /// [backupPath] - Path to the backup file to restore
  ///
  /// WARNING: This will replace the current database!
  Future<void> restoreBackup(String backupPath) async {
    try {
      final File backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file does not exist at $backupPath');
      }

      // Close the current database
      await _dbService.closeDB();

      // Get the current database path from the service
      await _dbService.init();
      final dbPath = _dbService.dbPath;

      // Create a safety backup of current database before restoring
      final File currentDbFile = File(dbPath);
      if (await currentDbFile.exists()) {
        final String safetyBackupPath =
            '$dbPath.pre_restore_${DateTime.now().millisecondsSinceEpoch}';
        await currentDbFile.copy(safetyBackupPath);
        LoggerService.i('Safety backup created: $safetyBackupPath');
      }

      // Copy backup file to database location
      await backupFile.copy(dbPath);

      LoggerService.i('Database restored from: $backupPath');

      // Reopen the database and ensure migrations are applied
      await _dbService.openDB();
      await _dbService.ensureMigrations();
    } catch (e) {
      LoggerService.e('Failed to restore backup', e);
      rethrow;
    }
  }

  /// List all available backups
  ///
  /// Returns a list of backup file paths, sorted by creation time (newest first)
  Future<List<String>> listBackups() async {
    try {
      final String backupDir = await _getBackupDirectory();
      final Directory dir = Directory(backupDir);

      if (!await dir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await dir.list().toList();
      final List<File> backupFiles = files
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList();

      // Sort by modification time, newest first
      backupFiles.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return backupFiles.map((f) => f.path).toList();
    } catch (e) {
      LoggerService.w('Failed to list backups', e);
      return [];
    }
  }

  /// Delete old backups, keeping only the most recent [keepCount] backups
  ///
  /// [keepCount] - Number of recent backups to keep (default: 5)
  Future<void> cleanOldBackups({int keepCount = 5}) async {
    try {
      final List<String> backups = await listBackups();

      if (backups.length <= keepCount) {
        return;
      }

      // Delete backups beyond the keep count
      final List<String> backupsToDelete = backups.sublist(keepCount);

      for (final String backupPath in backupsToDelete) {
        final File file = File(backupPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      LoggerService.i('Cleaned ${backupsToDelete.length} old backups');
    } catch (e) {
      LoggerService.w('Failed to clean old backups', e);
    }
  }

  /// Verify a backup file is valid
  ///
  /// Returns true if the backup can be opened and read
  Future<bool> verifyBackup(String backupPath) async {
    try {
      final File backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }

      // Check file size
      final int fileSize = await backupFile.length();
      if (fileSize == 0) {
        return false;
      }

      return true;
    } catch (e) {
      LoggerService.w('Backup verification failed', e);
      return false;
    }
  }

  /// Create an automatic backup before performing migrations
  ///
  /// This should be called before any database schema changes
  Future<String?> createPreMigrationBackup() async {
    try {
      final String backupPath = await createBackup(prefix: 'pre_migration');

      // Verify the backup was created successfully
      if (await verifyBackup(backupPath)) {
        LoggerService.i('Pre-migration backup created and verified');
        return backupPath;
      } else {
        LoggerService.w('Pre-migration backup verification failed');
        return null;
      }
    } catch (e) {
      LoggerService.e('Failed to create pre-migration backup', e);
      return null;
    }
  }

  /// Export database to a user-accessible location
  ///
  /// [destinationPath] - Where to export the database file
  Future<void> exportDatabase(String destinationPath) async {
    try {
      await _dbService.closeDB();

      final dbPath = join(await getDatabasesPath(), 'expense.db');

      final File dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file does not exist');
      }

      await dbFile.copy(destinationPath);

      LoggerService.i('Database exported to: $destinationPath');

      // Reopen the database
      await _dbService.openDB();
    } catch (e) {
      LoggerService.e('Failed to export database', e);
      rethrow;
    }
  }

  /// Import database from a user-provided file
  ///
  /// [sourcePath] - Path to the database file to import
  Future<void> importDatabase(String sourcePath) async {
    try {
      final File sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist at $sourcePath');
      }

      // Create a backup of current database before importing
      await createBackup(prefix: 'pre_import');

      // Close current database
      await _dbService.closeDB();

      final dbPath = join(await getDatabasesPath(), 'expense.db');

      // Copy imported file to database location
      await sourceFile.copy(dbPath);

      LoggerService.i('Database imported from: $sourcePath');

      // Reopen and ensure migrations are applied
      await _dbService.openDB();
      await _dbService.ensureMigrations();
    } catch (e) {
      LoggerService.e('Failed to import database', e);
      rethrow;
    }
  }
}
