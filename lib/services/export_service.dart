import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ledger/presets/exceptions.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/database/category_db_service.dart';
import 'package:ledger/services/database/tag_db_service.dart';
import 'package:ledger/services/database/budget_db_service.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/models/budget.dart';
import 'package:intl/intl.dart';

class ExportService {
  static const int currentFormatVersion = 1;
  static const String appVersion = '1.0.0';

  /// Exports all data to a JSON file and shares it
  static Future<File> exportData() async {
    LoggerService.i('Starting data export...');
    try {
      // Get all data from database services
      final accountService = getIt<AccountDBService>();
      final transactionService = getIt<TransactionDBService>();
      final categoryService = getIt<CategoryDBService>();
      final tagService = getIt<TagDBService>();
      final budgetService = getIt<BudgetDBService>();

      LoggerService.i('Fetching data from database...');
      // Fetch raw data and convert to models
      final accountsData = await accountService.fetchAll();
      final accounts = accountsData.map((a) => Account.fromJson(a)).toList();
      LoggerService.i('Accounts fetched: ${accounts.length}');

      final transactionsData = await transactionService.fetchAll();
      final transactions = transactionsData
          .map((t) => Transaction.fromMap(t))
          .toList();
      LoggerService.i('Transactions fetched: ${transactions.length}');

      final categoriesData = await categoryService.fetchAll();
      final categories = categoriesData
          .map((c) => Category.fromMap(c))
          .toList();
      LoggerService.i('Categories fetched: ${categories.length}');

      final tagsData = await tagService.fetchAll();
      final tags = tagsData.map((t) => Tag.fromMap(t)).toList();
      LoggerService.i('Tags fetched: ${tags.length}');

      final budgetsData = await budgetService.fetchAll();
      final budgets = budgetsData.map((b) => Budget.fromMap(b)).toList();
      LoggerService.i('Budgets fetched: ${budgets.length}');

      // Build export payload
      final payload = {
        'formatVersion': currentFormatVersion,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'appVersion': appVersion,
        'data': {
          'accounts': accounts.map((a) => a.toJson()).toList(),
          'transactions': transactions.map((t) => t.toMap()).toList(),
          'categories': categories.map((c) => c.toMap()).toList(),
          'tags': tags.map((t) => t.toMap()).toList(),
          'budgets': budgets.map((b) => b.toMap()).toList(),
        },
      };

      // Create export file
      final file = await _writeExportFile(payload);
      LoggerService.i('Export completed: ${file.path}');

      return file;
    } catch (e, stackTrace) {
      LoggerService.e('Export failed', e, stackTrace);
      throw ExportException('Failed to export data: ${e.toString()}', e);
    }
  }

  /// Writes the export payload to a file
  static Future<File> _writeExportFile(Map<String, dynamic> payload) async {
    try {
      late Directory dir;
      try {
        dir = await getApplicationDocumentsDirectory();
      } catch (e) {
        // Fallback for tests where path_provider isn't available
        dir = Directory.systemTemp;
      }
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'ledger_export_$timestamp.json';
      final file = File('${dir.path}/$fileName');

      // Pretty-print JSON for human readability
      final encoder = const JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(payload);

      await file.writeAsString(jsonString);
      return file;
    } catch (e, stackTrace) {
      LoggerService.e('Failed to write export file', e, stackTrace);
      throw FileOperationException('Failed to write export file', e);
    }
  }

  /// Shares the export file
  static Future<void> shareExportFile(File file) async {
    try {
      LoggerService.i('Sharing export file: ${file.path}');
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Ledger Data Export'),
      );
    } catch (e, stackTrace) {
      LoggerService.e('Failed to share export file', e, stackTrace);
      rethrow;
    }
  }

  /// Exports data and immediately shares it
  static Future<void> exportAndShare() async {
    final file = await exportData();
    await shareExportFile(file);
  }
}
