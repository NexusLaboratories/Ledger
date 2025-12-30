import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/models/budget.dart';
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/database/category_db_service.dart';
import 'package:ledger/services/database/tag_db_service.dart';
import 'package:ledger/services/database/budget_db_service.dart';
import 'package:ledger/services/logger_service.dart';

class ImportService {
  static const int maxSupportedFormatVersion = 1;

  /// Picks a file and imports data
  static Future<ImportResult> importData({bool replaceAll = false}) async {
    try {
      LoggerService.i('Starting data import...');

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        LoggerService.i('Import cancelled by user');
        return ImportResult(success: false, message: 'Import cancelled');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Failed to get file path');
      }

      final file = File(filePath);
      return await importFromFile(file, replaceAll: replaceAll);
    } catch (e, stackTrace) {
      LoggerService.e('Import failed', e, stackTrace);
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

  /// Imports data from a file
  static Future<ImportResult> importFromFile(
    File file, {
    bool replaceAll = false,
  }) async {
    try {
      // Read and parse file
      final content = await file.readAsString();
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(content);
      } catch (e) {
        throw ParseException('Invalid JSON format in import file', e);
      }

      // Validate format
      final validation = _validateFormat(json);
      if (!validation.isValid) {
        return ImportResult(
          success: false,
          message: validation.errorMessage ?? 'Invalid file format',
        );
      }

      // Migrate data if needed
      final migratedData = _migrateData(json);

      // Extract data
      final data = migratedData['data'] as Map<String, dynamic>;

      // Count items
      final stats = ImportStats(
        accounts: (data['accounts'] as List?)?.length ?? 0,
        transactions: (data['transactions'] as List?)?.length ?? 0,
        categories: (data['categories'] as List?)?.length ?? 0,
        tags: (data['tags'] as List?)?.length ?? 0,
        budgets: (data['budgets'] as List?)?.length ?? 0,
      );

      // Import data
      LoggerService.i(
        'Importing data | Accounts: ${stats.accounts} | Transactions: ${stats.transactions} | Categories: ${stats.categories} | Tags: ${stats.tags} | Budgets: ${stats.budgets} | Mode: ${replaceAll ? "Replace" : "Merge"}',
      );
      await _importToDatabase(data, replaceAll: replaceAll);

      LoggerService.i(
        'Import completed successfully | Total items: ${stats.accounts + stats.transactions + stats.categories + stats.tags + stats.budgets}',
      );

      return ImportResult(
        success: true,
        message: 'Import successful',
        stats: stats,
      );
    } catch (e, stackTrace) {
      LoggerService.e('Import from file failed', e, stackTrace);
      return ImportResult(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

  /// Validates the export file format
  static ValidationResult _validateFormat(Map<String, dynamic> json) {
    // Check format version
    final version = json['formatVersion'] as int?;
    if (version == null) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Missing format version',
      );
    }

    if (version > maxSupportedFormatVersion) {
      return ValidationResult(
        isValid: false,
        errorMessage:
            'Unsupported format version: $version. '
            'Please update the app.',
      );
    }

    // Check data structure
    final data = json['data'];
    if (data == null || data is! Map<String, dynamic>) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Invalid data structure',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Migrates data from older formats if needed
  static Map<String, dynamic> _migrateData(Map<String, dynamic> json) {
    final version = json['formatVersion'] as int;

    // Currently only version 1 exists, but this is where migration logic
    // would go for future versions
    switch (version) {
      case 1:
        return json; // No migration needed
      default:
        return json;
    }
  }

  /// Imports data to the database
  static Future<void> _importToDatabase(
    Map<String, dynamic> data, {
    required bool replaceAll,
  }) async {
    try {
      final accountService = getIt<AccountDBService>();
      final transactionService = getIt<TransactionDBService>();
      final categoryService = getIt<CategoryDBService>();
      final tagService = getIt<TagDBService>();
      final budgetService = getIt<BudgetDBService>();

      // If replace mode, clear existing data
      if (replaceAll) {
        LoggerService.w('Clearing all existing data for replacement...');

        // Get all existing items and delete them
        // Delete in order to respect foreign key constraints
        final existingTransactionsData = await transactionService.fetchAll();
        for (final txData in existingTransactionsData) {
          final tx = Transaction.fromMap(txData);
          await transactionService.deleteTransaction(tx.id);
        }

        final existingBudgetsData = await budgetService.fetchAll();
        for (final budgetData in existingBudgetsData) {
          final budget = Budget.fromMap(budgetData);
          await budgetService.delete(budget.id);
        }

        final existingAccountsData = await accountService.fetchAll();
        for (final accountData in existingAccountsData) {
          final account = Account.fromJson(accountData);
          await accountService.delete(account.id);
        }

        final existingCategoriesData = await categoryService.fetchAll();
        for (final categoryData in existingCategoriesData) {
          final category = Category.fromMap(categoryData);
          await categoryService.delete(category.id);
        }

        final existingTagsData = await tagService.fetchAll();
        for (final tagData in existingTagsData) {
          final tag = Tag.fromMap(tagData);
          await tagService.delete(tag.id);
        }
      }

      // Import categories first (they're referenced by transactions)
      final categoriesData = data['categories'] as List?;
      if (categoriesData != null) {
        for (final categoryJson in categoriesData) {
          final category = Category.fromMap(
            categoryJson as Map<String, dynamic>,
          );
          await categoryService.createCategory(category);
        }
      }

      // Import tags
      final tagsData = data['tags'] as List?;
      if (tagsData != null) {
        for (final tagJson in tagsData) {
          final tag = Tag.fromMap(tagJson as Map<String, dynamic>);
          await tagService.createTag(tag);
        }
      }

      // Import accounts
      final accountsData = data['accounts'] as List?;
      if (accountsData != null) {
        for (final accountJson in accountsData) {
          final account = Account.fromJson(accountJson as Map<String, dynamic>);
          await accountService.createAccount(account);
        }
      }

      // Import transactions
      final transactionsData = data['transactions'] as List?;
      if (transactionsData != null) {
        for (final transactionJson in transactionsData) {
          final transaction = Transaction.fromMap(
            transactionJson as Map<String, dynamic>,
          );
          await transactionService.createTransaction(transaction);
        }
      }

      // Import budgets
      final budgetsData = data['budgets'] as List?;
      if (budgetsData != null) {
        for (final budgetJson in budgetsData) {
          final budget = Budget.fromMap(budgetJson as Map<String, dynamic>);
          await budgetService.createBudget(budget);
        }
      }
    } catch (e, stackTrace) {
      LoggerService.e('Failed to import data to database', e, stackTrace);
      throw ImportException('Failed to import data: ${e.toString()}', e);
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final ImportStats? stats;

  ImportResult({required this.success, required this.message, this.stats});
}

class ImportStats {
  final int accounts;
  final int transactions;
  final int categories;
  final int tags;
  final int budgets;

  ImportStats({
    required this.accounts,
    required this.transactions,
    required this.categories,
    required this.tags,
    required this.budgets,
  });

  @override
  String toString() {
    return 'Accounts: $accounts, Transactions: $transactions, '
        'Categories: $categories, Tags: $tags, Budgets: $budgets';
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorMessage});
}
