import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/services/export_service.dart';
import 'package:ledger/services/import_service.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/services/service_locator.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/database/category_db_service.dart';
import 'package:ledger/services/database/core_db_service.dart';

void main() {
  setUpAll(() async {
    setupServiceLocator();
    await DatabaseService().init();
  });

  tearDownAll(() async {
    try {
      await DatabaseService().closeDB();
      await DatabaseService().deleteDB();
    } catch (e) {
      // Ignore errors in teardown - database might not exist or plugin unavailable
    }
  });

  group('ExportService', () {
    setUp(() async {
      // Clean database before each test
      final db = DatabaseService();
      await db.openDB();
      await db.delete('transaction_items');
      await db.delete('transaction_tags');
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('categories');
      await db.delete('tags');
      await db.delete('accounts');
      // Don't delete users - we need the 'local' user
    });

    test('exports data to JSON with correct format version', () async {
      // Create test data
      final account = Account(name: 'Test Account', currency: 'USD');
      await getIt<AccountDBService>().createAccount(account);

      // Export
      final file = await ExportService.exportData();

      // Verify file exists
      expect(file.existsSync(), true);

      // Read and parse
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Verify structure
      expect(json['formatVersion'], ExportService.currentFormatVersion);
      expect(json['generatedAt'], isNotNull);
      expect(json['appVersion'], isNotNull);
      expect(json['data'], isNotNull);

      // Verify data
      final data = json['data'] as Map<String, dynamic>;
      expect(data['accounts'], isList);
      expect(data['transactions'], isList);
      expect(data['categories'], isList);
      expect(data['tags'], isList);
      expect(data['budgets'], isList);

      // Clean up
      await file.delete();
    });

    test('exports all entity types correctly', () async {
      // Create test data
      final category = Category(
        id: 'cat1',
        name: 'Test Category',
        userId: 'local',
      );
      await getIt<CategoryDBService>().createCategory(category);

      final account = Account(name: 'Test Account');
      await getIt<AccountDBService>().createAccount(account);

      final transaction = Transaction(
        title: 'Test Transaction',
        amount: 100.0,
        accountId: account.id,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: category.id,
      );
      await getIt<TransactionDBService>().createTransaction(transaction);

      // Export
      final file = await ExportService.exportData();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;

      // Verify counts
      expect((data['accounts'] as List).length, 1);
      expect((data['transactions'] as List).length, 1);
      expect((data['categories'] as List).length, 1);

      // Clean up
      await file.delete();
    });

    test('exported JSON is human-readable (pretty-printed)', () async {
      final file = await ExportService.exportData();
      final content = await file.readAsString();

      // Check for indentation (pretty-printed JSON)
      expect(content.contains('  '), true);
      expect(content.contains('\n'), true);

      // Clean up
      await file.delete();
    });
  });

  group('ImportService', () {
    setUp(() async {
      // Clean database before each test
      final db = DatabaseService();
      await db.openDB();
      await db.delete('transaction_items');
      await db.delete('transaction_tags');
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('categories');
      await db.delete('tags');
      await db.delete('accounts');
    });

    test('validates format version correctly', () async {
      // Create a file with unsupported version
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/test_import.json');

      final invalidData = {
        'formatVersion': 999,
        'generatedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'data': {},
      };

      await file.writeAsString(jsonEncode(invalidData));

      // Try to import
      final result = await ImportService.importFromFile(file);

      // Should fail
      expect(result.success, false);
      expect(result.message.contains('Unsupported'), true);

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('imports data successfully in merge mode', () async {
      // Create existing data
      final existingAccount = Account(name: 'Existing Account');
      await getIt<AccountDBService>().createAccount(existingAccount);

      // Create import file
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/test_import.json');

      final newAccount = Account(name: 'Imported Account');
      final importData = {
        'formatVersion': 1,
        'generatedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'data': {
          'accounts': [newAccount.toJson()],
          'transactions': [],
          'categories': [],
          'tags': [],
          'budgets': [],
        },
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(importData),
      );

      // Import in merge mode
      final result = await ImportService.importFromFile(
        file,
        replaceAll: false,
      );

      // Should succeed
      expect(result.success, true);
      expect(result.stats?.accounts, 1);

      // Verify both accounts exist
      final accountsData = await getIt<AccountDBService>().fetchAll();
      final accounts = accountsData.map((a) => Account.fromJson(a)).toList();
      expect(accounts.length, 2);

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('imports data successfully in replace mode', () async {
      // Create existing data
      final existingAccount = Account(name: 'Existing Account');
      await getIt<AccountDBService>().createAccount(existingAccount);

      // Create import file
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/test_import.json');

      final newAccount = Account(name: 'Imported Account');
      final importData = {
        'formatVersion': 1,
        'generatedAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'data': {
          'accounts': [newAccount.toJson()],
          'transactions': [],
          'categories': [],
          'tags': [],
          'budgets': [],
        },
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(importData),
      );

      // Import in replace mode
      final result = await ImportService.importFromFile(file, replaceAll: true);

      // Should succeed
      expect(result.success, true);

      // Verify only imported account exists
      final accountsData = await getIt<AccountDBService>().fetchAll();
      final accounts = accountsData.map((a) => Account.fromJson(a)).toList();
      expect(accounts.length, 1);
      expect(accounts.first.name, 'Imported Account');

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('handles invalid JSON gracefully', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final file = File('${tempDir.path}/test_import.json');

      await file.writeAsString('invalid json content');

      final result = await ImportService.importFromFile(file);

      expect(result.success, false);
      expect(result.message.contains('failed'), true);

      // Clean up
      await tempDir.delete(recursive: true);
    });

    test('round-trip: export then import produces same data', () async {
      // Create test data
      final category = Category(id: 'cat1', name: 'Food', userId: 'local');
      await getIt<CategoryDBService>().createCategory(category);

      final account = Account(name: 'Cash', balance: 1000.0);
      await getIt<AccountDBService>().createAccount(account);

      final transaction = Transaction(
        title: 'Groceries',
        amount: 50.0,
        accountId: account.id,
        categoryId: category.id,
        date: DateTime.now(),
        type: TransactionType.expense,
      );
      await getIt<TransactionDBService>().createTransaction(transaction);

      // Export
      final exportFile = await ExportService.exportData();

      // Note: In real app, would clear database here
      // For test simplicity, we'll import with replaceAll=true

      // Import
      final result = await ImportService.importFromFile(
        exportFile,
        replaceAll: true,
      );

      expect(result.success, true);

      // Verify data
      final accountsData = await getIt<AccountDBService>().fetchAll();
      final accounts = accountsData.map((a) => Account.fromJson(a)).toList();
      expect(accounts.length, greaterThanOrEqualTo(1));
      expect(accounts.any((a) => a.name == 'Cash'), true);

      final categoriesData = await getIt<CategoryDBService>().fetchAll();
      final categories = categoriesData
          .map((c) => Category.fromMap(c))
          .toList();
      expect(categories.length, greaterThanOrEqualTo(1));
      expect(categories.any((c) => c.name == 'Food'), true);

      final transactionsData = await getIt<TransactionDBService>().fetchAll();
      final transactions = transactionsData
          .map((t) => Transaction.fromMap(t))
          .toList();
      expect(transactions.length, greaterThanOrEqualTo(1));
      expect(transactions.any((t) => t.title == 'Groceries'), true);

      // Clean up
      await exportFile.delete();
    });
  });
}
