import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pdf/widgets.dart' as pw;
import 'package:ledger/services/reports_service.dart';
import 'package:pdf/pdf.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/models/report_options.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ledger/models/spending_summary.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/database/transaction_item_db_service.dart';
import 'package:ledger/models/transaction_item.dart';

class _TagStat {
  final String name;
  final int count;
  final double amount;
  _TagStat({required this.name, required this.count, required this.amount});
}

class _CategoryData {
  final String id;
  final String name;
  final double amount;
  final int count;
  _CategoryData({
    required this.id,
    required this.name,
    required this.amount,
    required this.count,
  });
}

enum SheetLayout { single, byAccount, byCategory, byMonth }

class ReportService {
  final ReportsService _reportsService = ReportsService();
  final AccountService _accountService = AccountService();
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  final TransactionItemDBService _itemService = TransactionItemDBService();

  /// Generate an XLSX file of transactions using the applied filters.
  /// Returns the local file path to the created .xlsx file.
  Future<String> generateTransactionsXlsx(
    ReportOptions options, {
    SheetLayout layout = SheetLayout.byAccount,
    String transactionTypeFilter = 'both', // 'both' | 'income' | 'expense'
  }) async {
    // Load transactions using same filtering logic
    final txs = await _getTransactionsForPeriod(
      options.period,
      options.accountIds,
      categoryIds: options.categoryIds,
      categoryIncludeMode: options.categoryIncludeMode,
      tagIds: options.tagIds,
      tagIncludeMode: options.tagIncludeMode,
      customStartDate: options.customStartDate,
      customEndDate: options.customEndDate,
    );

    // Filter by transaction type if requested
    final filteredTxs = txs.where((t) {
      if (transactionTypeFilter == 'income') {
        return t.type == TransactionType.income;
      }
      if (transactionTypeFilter == 'expense') {
        return t.type == TransactionType.expense;
      }
      return true;
    }).toList();

    // Load accounts & categories for names
    final accounts = await _accountService.fetchAccounts();
    final accountNames = {
      for (final a in accounts)
        if (a != null) a.id: a.name,
    };
    final categories = await _categoryService.fetchCategoriesForUser('local');
    final categoryNames = {for (final c in categories) c.id: c.name};

    // Prepare Excel workbook
    final excel = Excel.createExcel();

    // Helper to sanitize sheet name
    String sanitizeSheetName(String name) {
      var n = name.replaceAll(RegExp(r'[\\:\/?\*\[\]]'), '_');
      if (n.length > 31) n = n.substring(0, 31);
      return n;
    }

    // Create sheets based on selected layout only
    if (layout == SheetLayout.single) {
      // Single sheet with all transactions
      final Sheet sheet = excel['Transactions'];
      sheet.appendRow([
        'Date',
        'Title',
        'Amount',
        'Category',
        'Description',
        'Expense Item',
        'Expense Quantity',
        'Expense Amount',
      ]);
      for (final t in filteredTxs) {
        final categoryName = t.categoryId != null
            ? (categoryNames[t.categoryId!] ?? t.categoryId!)
            : 'Uncategorised';

        // Fetch transaction items
        final items = await _itemService.fetchAllByTransactionId(t.id);

        if (items.isEmpty) {
          // Transaction has no items - add single row with empty item columns
          sheet.appendRow([
            '${t.date.day}/${t.date.month}/${t.date.year}',
            t.title,
            t.amount,
            categoryName,
            t.description ?? '',
            '',
            '',
            '',
          ]);
        } else {
          // Transaction has items - add one row per item
          for (final itemMap in items) {
            final item = TransactionItem.fromMap(itemMap);
            sheet.appendRow([
              '${t.date.day}/${t.date.month}/${t.date.year}',
              t.title,
              t.amount,
              categoryName,
              t.description ?? '',
              item.name,
              item.quantity,
              item.price,
            ]);
          }
        }
      }
    } else if (layout == SheetLayout.byAccount) {
      // Group by account
      final byAccount = <String, List<Transaction>>{};
      for (final t in filteredTxs) {
        byAccount.putIfAbsent(t.accountId, () => []).add(t);
      }
      for (final entry in byAccount.entries) {
        final name = accountNames[entry.key] ?? entry.key;
        final sheetName = sanitizeSheetName(name);
        final Sheet sheet = excel[sheetName];
        sheet.appendRow([
          'Date',
          'Title',
          'Amount',
          'Category',
          'Description',
          'Expense Item',
          'Expense Quantity',
          'Expense Amount',
        ]);
        for (final t in entry.value) {
          final categoryName = t.categoryId != null
              ? (categoryNames[t.categoryId!] ?? t.categoryId!)
              : 'Uncategorised';

          // Fetch transaction items
          final items = await _itemService.fetchAllByTransactionId(t.id);

          if (items.isEmpty) {
            sheet.appendRow([
              '${t.date.day}/${t.date.month}/${t.date.year}',
              t.title,
              t.amount,
              categoryName,
              t.description ?? '',
              '',
              '',
              '',
            ]);
          } else {
            for (final itemMap in items) {
              final item = TransactionItem.fromMap(itemMap);
              sheet.appendRow([
                '${t.date.day}/${t.date.month}/${t.date.year}',
                t.title,
                t.amount,
                categoryName,
                t.description ?? '',
                item.name,
                item.quantity,
                item.price,
              ]);
            }
          }
        }
      }
    } else if (layout == SheetLayout.byCategory) {
      final byCat = <String, List<Transaction>>{};
      for (final t in filteredTxs) {
        final cid = t.categoryId ?? 'uncategorised';
        byCat.putIfAbsent(cid, () => []).add(t);
      }
      for (final entry in byCat.entries) {
        final name = entry.key == 'uncategorised'
            ? 'Uncategorised'
            : (categoryNames[entry.key] ?? entry.key);
        final sheetName = sanitizeSheetName(name);
        final Sheet sheet = excel[sheetName];
        sheet.appendRow([
          'Date',
          'Title',
          'Amount',
          'Category',
          'Description',
          'Expense Item',
          'Expense Quantity',
          'Expense Amount',
        ]);
        for (final t in entry.value) {
          // Category is implicit from sheet name, but add for consistency
          final categoryName = name;

          // Fetch transaction items
          final items = await _itemService.fetchAllByTransactionId(t.id);

          if (items.isEmpty) {
            sheet.appendRow([
              '${t.date.day}/${t.date.month}/${t.date.year}',
              t.title,
              t.amount,
              categoryName,
              t.description ?? '',
              '',
              '',
              '',
            ]);
          } else {
            for (final itemMap in items) {
              final item = TransactionItem.fromMap(itemMap);
              sheet.appendRow([
                '${t.date.day}/${t.date.month}/${t.date.year}',
                t.title,
                t.amount,
                categoryName,
                t.description ?? '',
                item.name,
                item.quantity,
                item.price,
              ]);
            }
          }
        }
      }
    } else if (layout == SheetLayout.byMonth) {
      final byMonth = <String, List<Transaction>>{};
      for (final t in filteredTxs) {
        final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
        byMonth.putIfAbsent(key, () => []).add(t);
      }
      for (final entry in byMonth.entries) {
        final parts = entry.key.split('-');
        final yr = parts[0];
        final mo = int.parse(parts[1]);
        final sheetName = sanitizeSheetName('${_getMonthName(mo)} $yr');
        final Sheet sheet = excel[sheetName];
        sheet.appendRow([
          'Date',
          'Title',
          'Amount',
          'Category',
          'Description',
          'Expense Item',
          'Expense Quantity',
          'Expense Amount',
        ]);
        for (final t in entry.value) {
          final categoryName = t.categoryId != null
              ? (categoryNames[t.categoryId!] ?? t.categoryId!)
              : 'Uncategorised';

          // Fetch transaction items
          final items = await _itemService.fetchAllByTransactionId(t.id);

          if (items.isEmpty) {
            sheet.appendRow([
              '${t.date.day}/${t.date.month}/${t.date.year}',
              t.title,
              t.amount,
              categoryName,
              t.description ?? '',
              '',
              '',
              '',
            ]);
          } else {
            for (final itemMap in items) {
              final item = TransactionItem.fromMap(itemMap);
              sheet.appendRow([
                '${t.date.day}/${t.date.month}/${t.date.year}',
                t.title,
                t.amount,
                categoryName,
                t.description ?? '',
                item.name,
                item.quantity,
                item.price,
              ]);
            }
          }
        }
      }
    }

    // Remove default Sheet1 if it still exists (after creating our sheets)
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Encode and write to temp file
    final fileBytes = excel.encode();
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/ledger_transactions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes!, flush: true);

    return filePath;
  }

  Future<Uint8List> generateReportPdf(
    ReportOptions options, {
    String currency = 'INR',
  }) async {
    final pdf = pw.Document();

    // Load accounts for name mapping
    final accounts = await _accountService.fetchAccounts();
    final accountNames = {
      for (final acc in accounts)
        if (acc != null) acc.id: acc.name,
    };

    // Load categories for name mapping
    final categories = await _categoryService.fetchCategoriesForUser('local');
    final categoryNames = {for (final cat in categories) cat.id: cat.name};

    // Get summary and stats (filtered by accounts)
    final summary = await _getSummaryForPeriod(
      options.period,
      options.accountIds,
      categoryNames: categoryNames,
      categoryIds: options.categoryIds,
      categoryIncludeMode: options.categoryIncludeMode,
      tagIds: options.tagIds,
      tagIncludeMode: options.tagIncludeMode,
      customStartDate: options.customStartDate,
      customEndDate: options.customEndDate,
    );
    final avgDaily = await _getAvgDailyForPeriod(
      options.period,
      options.accountIds,
      categoryIds: options.categoryIds,
      categoryIncludeMode: options.categoryIncludeMode,
      tagIds: options.tagIds,
      tagIncludeMode: options.tagIncludeMode,
      customStartDate: options.customStartDate,
      customEndDate: options.customEndDate,
    );
    final weeklyStats = await _getWeeklyStatsForPeriod(
      options.period,
      options.accountIds,
      categoryIds: options.categoryIds,
      categoryIncludeMode: options.categoryIncludeMode,
      tagIds: options.tagIds,
      tagIncludeMode: options.tagIncludeMode,
      customStartDate: options.customStartDate,
      customEndDate: options.customEndDate,
    );
    final budgets = await _budgetService.fetchBudgets('local');

    // Get top transactions and tags for the period (filtered by accounts)
    final topTransactions = await _getTopTransactionsForPeriod(
      options.period,
      options.accountIds,
      categoryIds: options.categoryIds,
      categoryIncludeMode: options.categoryIncludeMode,
      tagIds: options.tagIds,
      tagIncludeMode: options.tagIncludeMode,
      customStartDate: options.customStartDate,
      customEndDate: options.customEndDate,
    );
    final topIncomes = topTransactions['incomes'] ?? [];
    final topExpenses = topTransactions['expenses'] ?? [];
    final topTags = await _getTopTagsForPeriod(
      options.period,
      options.accountIds,
      categoryIds: options.categoryIds,
      categoryIncludeMode: options.categoryIncludeMode,
      tagIds: options.tagIds,
      tagIncludeMode: options.tagIncludeMode,
      customStartDate: options.customStartDate,
      customEndDate: options.customEndDate,
    );

    // Get daily spending for heatmap (only for current_month)
    List<double>? dailySpending;
    if (options.period == 'current_month') {
      dailySpending = await _getDailySpendingForPeriod(
        options.period,
        options.accountIds,
        categoryIds: options.categoryIds,
        categoryIncludeMode: options.categoryIncludeMode,
        tagIds: options.tagIds,
        tagIncludeMode: options.tagIncludeMode,
        customStartDate: options.customStartDate,
        customEndDate: options.customEndDate,
      );
    }

    // Precompute month comparisons if needed (can't await inside PDF builder)
    MonthlyStats? comparisonCurrent;
    MonthlyStats? comparisonPrev;
    MonthlyStats? comparisonLastYear;
    if (options.period == 'current_month') {
      final now = DateTime.now();
      comparisonCurrent = await _getMonthTotals(
        now.year,
        now.month,
        options.accountIds,
        categoryIds: options.categoryIds,
        categoryIncludeMode: options.categoryIncludeMode,
        tagIds: options.tagIds,
        tagIncludeMode: options.tagIncludeMode,
      );
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      comparisonPrev = await _getMonthTotals(
        prevYear,
        prevMonth,
        options.accountIds,
        categoryIds: options.categoryIds,
        categoryIncludeMode: options.categoryIncludeMode,
        tagIds: options.tagIds,
        tagIncludeMode: options.tagIncludeMode,
      );
      comparisonLastYear = await _getMonthTotals(
        now.year - 1,
        now.month,
        options.accountIds,
        categoryIds: options.categoryIds,
        categoryIncludeMode: options.categoryIncludeMode,
        tagIds: options.tagIds,
        tagIncludeMode: options.tagIncludeMode,
      );
    }

    // Build budget progress
    final budgetProgresses = <BudgetProgress>[];
    for (final b in budgets) {
      try {
        final p = await _budgetService.calculateProgress(b);
        budgetProgresses.add(p);
      } catch (e) {
        // skip failed budgets
      }
    }

    // Main report page
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final children = <pw.Widget>[];

          // ====== TITLE & PERIOD ======
          children.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                'Ledger Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          children.add(pw.SizedBox(height: 10));

          final periodLabel = options.period == 'current_month'
              ? 'This Month'
              : options.period == 'current_year'
              ? 'This Year'
              : options.period == 'custom'
              ? 'Custom Range: ${options.customStartDate != null ? '${options.customStartDate!.day}/${options.customStartDate!.month}/${options.customStartDate!.year}' : ''} - ${options.customEndDate != null ? '${options.customEndDate!.day}/${options.customEndDate!.month}/${options.customEndDate!.year}' : ''}'
              : 'All Time';
          children.add(
            pw.Text('Period: $periodLabel', style: pw.TextStyle(fontSize: 14)),
          );
          children.add(
            pw.Text(
              'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 12),
            ),
          );
          children.add(pw.SizedBox(height: 20));

          // ====== FINANCIAL OVERVIEW ======
          if (summary != null) {
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Financial Overview',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            children.add(
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Metric', 'Value'],
                data: [
                  [
                    'Total Income',
                    '${summary.totalIncome.toStringAsFixed(2)} $currency',
                  ],
                  [
                    'Total Expense',
                    '${summary.totalExpense.toStringAsFixed(2)} $currency',
                  ],
                  [
                    'Net Balance',
                    '${summary.netBalance.toStringAsFixed(2)} $currency',
                  ],
                  ['Transaction Count', '${summary.transactionCount}'],
                  [
                    'Avg Daily Spending',
                    '${avgDaily?.toStringAsFixed(2) ?? '0.00'} $currency',
                  ],
                ],
              ),
            );
            children.add(pw.SizedBox(height: 20));
          }

          // ====== TOP SPENDING CATEGORIES (with bar chart) ======
          if (summary != null && summary.topCategories.isNotEmpty) {
            final top = summary.topCategories.take(10).toList();
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Top Spending Categories',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            // Bar chart visualization
            final maxCatAmount = top.fold<double>(
              0,
              (m, c) => math.max(m, c.amount),
            );
            for (final cat in top) {
              final barWidth = maxCatAmount > 0
                  ? (cat.amount / maxCatAmount) * 400
                  : 0.0;
              children.add(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          cat.categoryName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${cat.amount.toStringAsFixed(2)} $currency (${cat.percentage.toStringAsFixed(1)}%)',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      height: 16,
                      width: barWidth,
                      color: PdfColors.blue400,
                    ),
                    pw.SizedBox(height: 8),
                  ],
                ),
              );
            }
            children.add(pw.SizedBox(height: 12));
          }

          // ====== SPENDING TREND (with visual chart) ======
          if (weeklyStats != null && weeklyStats.isNotEmpty) {
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Spending Trend',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            final trendLabel = options.period == 'current_month'
                ? 'Week'
                : 'Month';

            // Visual chart
            final maxExpense = weeklyStats.fold<double>(
              0,
              (m, s) => math.max(m, s.expense.abs()),
            );
            children.add(
              pw.Container(
                height: 100,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: weeklyStats.map((s) {
                    final barHeight = maxExpense > 0
                        ? (s.expense.abs() / maxExpense) * 80
                        : 0.0;
                    return pw.Expanded(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Container(
                            height: barHeight,
                            width: 30,
                            color: PdfColors.red400,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            s.month,
                            style: pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );

            children.add(pw.SizedBox(height: 10));

            // Data table
            children.add(
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: [trendLabel, 'Income', 'Expense', 'Net'],
                data: weeklyStats
                    .map(
                      (s) => [
                        s.month,
                        '${s.income.toStringAsFixed(2)} $currency',
                        '${s.expense.toStringAsFixed(2)} $currency',
                        '${s.net.toStringAsFixed(2)} $currency',
                      ],
                    )
                    .toList(),
              ),
            );
            children.add(pw.SizedBox(height: 20));
          }

          // Comparison chart for current month
          if (options.period == 'current_month' &&
              comparisonCurrent != null &&
              comparisonPrev != null &&
              comparisonLastYear != null) {
            final current = comparisonCurrent;
            final prev = comparisonPrev;
            final lastYear = comparisonLastYear;

            final maxVal = [
              current.income,
              current.expense,
              prev.income,
              prev.expense,
              lastYear.income,
              lastYear.expense,
            ].fold<double>(0, (m, v) => v > m ? v : m);

            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'This Month vs Previous Periods',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            // Helper to build a period column with side-by-side bars
            pw.Widget buildPeriodColumn(String label, MonthlyStats stats) {
              final incomeHeight = maxVal > 0
                  ? (stats.income / maxVal) * 100
                  : 0.0;
              final expenseHeight = maxVal > 0
                  ? (stats.expense.abs() / maxVal) * 100
                  : 0.0;

              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text(
                    label,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 120,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Income bar
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              height: incomeHeight,
                              width: 25,
                              color: PdfColors.green,
                            ),
                          ],
                        ),
                        pw.SizedBox(width: 4),
                        // Expense bar
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Container(
                              height: expenseHeight,
                              width: 25,
                              color: PdfColors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Inc: ${stats.income.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.green700),
                  ),
                  pw.Text(
                    'Exp: ${stats.expense.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.red700),
                  ),
                ],
              );
            }

            children.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildPeriodColumn('${prev.month}\n${prev.year}', prev),
                  buildPeriodColumn(
                    '${current.month}\n${current.year}',
                    current,
                  ),
                  buildPeriodColumn(
                    '${lastYear.month}\n${lastYear.year}',
                    lastYear,
                  ),
                ],
              ),
            );

            // Percent changes
            String formatChange(double curr, double prior) {
              if (prior == 0) {
                if (curr == 0) return '0%';
                return 'N/A';
              }
              final change = ((curr - prior) / prior) * 100;
              return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
            }

            children.add(pw.SizedBox(height: 12));
            children.add(
              pw.Text(
                'Income: ${formatChange(current.income, prev.income)} vs prev month, '
                '${formatChange(current.income, lastYear.income)} vs same month last year',
                style: pw.TextStyle(fontSize: 10),
              ),
            );
            children.add(
              pw.Text(
                'Expense: ${formatChange(current.expense.abs(), prev.expense.abs())} vs prev month, '
                '${formatChange(current.expense.abs(), lastYear.expense.abs())} vs same month last year',
                style: pw.TextStyle(fontSize: 10),
              ),
            );
            children.add(pw.SizedBox(height: 20));
          }

          // ====== DAILY HEATMAP (for This Month only) ======
          if (options.period == 'current_month' &&
              dailySpending != null &&
              dailySpending.isNotEmpty) {
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Daily Spending Heatmap',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            final maxDaily = dailySpending.fold<double>(
              0,
              (m, v) => math.max(m, v),
            );
            final rows = <pw.Widget>[];
            for (int i = 0; i < dailySpending.length; i += 7) {
              final week = dailySpending.skip(i).take(7).toList();
              rows.add(
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: week.asMap().entries.map((entry) {
                    final day = i + entry.key + 1;
                    final amount = entry.value;
                    final intensity = maxDaily > 0 ? (amount / maxDaily) : 0.0;

                    // White to dark green color scheme (darker greens)
                    // Scale from white (255,255,255) to dark green (0,128,0)
                    final redValue = (255 * (1 - intensity))
                        .toInt(); // 255 to 0
                    final greenValue = (255 - 127 * intensity)
                        .toInt(); // 255 to 128
                    final blueValue = (255 * (1 - intensity))
                        .toInt(); // 255 to 0

                    final color = intensity == 0
                        ? PdfColors.white
                        : PdfColor.fromInt(
                            0xFF000000 +
                                redValue * 0x010000 + // Red channel
                                greenValue * 0x000100 + // Green channel
                                blueValue * 0x000001, // Blue channel
                          );

                    // Use white text when intensity is high (dark green background)
                    final textColor = intensity > 0.4
                        ? PdfColors.white
                        : PdfColors.black;

                    return pw.Container(
                      width: 60,
                      height: 40,
                      margin: pw.EdgeInsets.all(2),
                      decoration: pw.BoxDecoration(
                        color: color,
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              '$day',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            pw.Text(
                              amount.toStringAsFixed(0),
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            children.addAll(rows);
            children.add(pw.SizedBox(height: 20));
          }

          // Top Transactions
          if (topIncomes.isNotEmpty || topExpenses.isNotEmpty) {
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Top Transactions',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            // Top Incomes
            if (topIncomes.isNotEmpty) {
              children.add(
                pw.Text(
                  'Top Incomes',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              );
              children.add(pw.SizedBox(height: 6));
              children.add(
                // ignore: deprecated_member_use
                pw.Table.fromTextArray(
                  headers: ['Date', 'Account', 'Title', 'Amount'],
                  data: topIncomes
                      .map(
                        (t) => [
                          '${t.date.day}/${t.date.month}/${t.date.year}',
                          accountNames[t.accountId] ?? 'Unknown',
                          t.title,
                          '${t.amount.toStringAsFixed(2)} $currency',
                        ],
                      )
                      .toList(),
                ),
              );
              children.add(pw.SizedBox(height: 12));
            }

            // Top Expenses
            if (topExpenses.isNotEmpty) {
              children.add(
                pw.Text(
                  'Top Expenses',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
              );
              children.add(pw.SizedBox(height: 6));
              children.add(
                // ignore: deprecated_member_use
                pw.Table.fromTextArray(
                  headers: ['Date', 'Account', 'Title', 'Amount'],
                  data: topExpenses
                      .map(
                        (t) => [
                          '${t.date.day}/${t.date.month}/${t.date.year}',
                          accountNames[t.accountId] ?? 'Unknown',
                          t.title,
                          '${t.amount.toStringAsFixed(2)} $currency',
                        ],
                      )
                      .toList(),
                ),
              );
              children.add(pw.SizedBox(height: 20));
            }
          }

          // ====== TOP TAGS ======
          if (topTags.isNotEmpty) {
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Top Tags',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            children.add(
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Tag', 'Transactions', 'Total Amount'],
                data: topTags
                    .map(
                      (t) => [
                        t.name,
                        '${t.count}',
                        '${t.amount.toStringAsFixed(2)} $currency',
                      ],
                    )
                    .toList(),
              ),
            );
            children.add(pw.SizedBox(height: 20));
          }

          // ====== BUDGET PROGRESS ======
          if (budgetProgresses.isNotEmpty) {
            children.add(
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Budget Progress',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
            children.add(pw.SizedBox(height: 10));

            children.add(
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Budget', 'Spent', 'Limit', 'Remaining', 'Progress'],
                data: budgetProgresses
                    .map(
                      (p) => [
                        p.budget.name,
                        '${p.spent.toStringAsFixed(2)} $currency',
                        '${p.budget.amount.toStringAsFixed(2)} $currency',
                        '${p.remaining.toStringAsFixed(2)} $currency',
                        '${p.percent.toStringAsFixed(1)}%',
                      ],
                    )
                    .toList(),
              ),
            );
            children.add(pw.SizedBox(height: 20));
          }

          return children;
        },
      ),
    );

    final bytes = await pdf.save();
    return bytes;
  }

  Future<SpendingSummary?> _getSummaryForPeriod(
    String period,
    List<String> accountIds, {
    Map<String, String> categoryNames = const {},
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    // If no filters applied and not custom period, use original methods
    if (accountIds.isEmpty &&
        categoryIds.isEmpty &&
        tagIds.isEmpty &&
        period != 'custom') {
      switch (period) {
        case 'current_month':
          return await _reportsService.getCurrentMonthSummary();
        case 'current_year':
          return await _reportsService.getCurrentYearSummary();
        case 'all_time':
          return await _reportsService.getAllTimeSummary();
        default:
          return null;
      }
    }

    // Filter the summary by accounts - need to recalculate from transactions
    final txs = await _getTransactionsForPeriod(
      period,
      accountIds,
      categoryIds: categoryIds,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    double totalIncome = 0;
    double totalExpense = 0;
    final categoryMap = <String, _CategoryData>{};

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;

        // Build category summary for expenses
        final catId = tx.categoryId ?? 'uncategorised';
        final catName = tx.categoryId != null
            ? (categoryNames[tx.categoryId!] ?? tx.categoryId!)
            : 'Uncategorised';
        if (categoryMap.containsKey(catId)) {
          final existing = categoryMap[catId]!;
          categoryMap[catId] = _CategoryData(
            id: catId,
            name: catName,
            amount: existing.amount + tx.amount,
            count: existing.count + 1,
          );
        } else {
          categoryMap[catId] = _CategoryData(
            id: catId,
            name: catName,
            amount: tx.amount,
            count: 1,
          );
        }
      }
    }

    // Calculate percentages
    final categories = categoryMap.values.map((c) {
      return CategorySpending(
        categoryId: c.id,
        categoryName: c.name,
        amount: c.amount,
        transactionCount: c.count,
        percentage: totalExpense > 0 ? (c.amount / totalExpense) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return SpendingSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      categoryBreakdown: {},
      monthlyTrend: {},
      topCategories: categories,
      transactionCount: txs.length,
    );
  }

  Future<double?> _getAvgDailyForPeriod(
    String period,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    if (accountIds.isEmpty &&
        categoryIds.isEmpty &&
        tagIds.isEmpty &&
        period != 'custom') {
      switch (period) {
        case 'current_month':
          return await _reportsService.getAverageDailySpendingForCurrentMonth();
        case 'current_year':
          return await _reportsService.getAverageDailySpendingForCurrentYear();
        case 'all_time':
          return await _reportsService.getAverageDailySpendingForAllTime();
        default:
          return null;
      }
    }

    // Calculate from filtered transactions
    final txs = await _getTransactionsForPeriod(
      period,
      accountIds,
      categoryIds: categoryIds,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
    );
    final expenses = txs.where((t) => t.amount < 0).toList();
    if (expenses.isEmpty) return 0;

    final totalExpense = expenses.fold<double>(
      0,
      (sum, t) => sum + t.amount.abs(),
    );
    final now = DateTime.now();
    int days = 1;

    switch (period) {
      case 'current_month':
        days = now.day;
        break;
      case 'current_year':
        days = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
        break;
      case 'all_time':
        if (txs.isNotEmpty) {
          final sortedTxs = txs..sort((a, b) => a.date.compareTo(b.date));
          days = now.difference(sortedTxs.first.date).inDays + 1;
        }
        break;
    }

    return days > 0 ? totalExpense / days : 0;
  }

  Future<List<MonthlyStats>?> _getWeeklyStatsForPeriod(
    String period,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    // If no filters applied and not custom period, use original methods
    if (accountIds.isEmpty &&
        categoryIds.isEmpty &&
        tagIds.isEmpty &&
        period != 'custom') {
      switch (period) {
        case 'current_month':
          return await _reportsService.getWeeklyStatsForCurrentMonth();
        case 'current_year':
          return await _reportsService.getMonthlyStatsForCurrentYear();
        case 'all_time':
          return await _reportsService.getMonthlyStats(months: 12);
        default:
          return null;
      }
    }

    // Recalculate from filtered transactions
    final txs = await _getTransactionsForPeriod(
      period,
      accountIds,
      categoryIds: categoryIds,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    // Group by week for current_month, by month for others
    final isWeekly = period == 'current_month';
    final Map<String, MonthlyStats> statsMap = {};

    for (final tx in txs) {
      final key = isWeekly
          ? 'Week ${((tx.date.day - 1) ~/ 7) + 1}'
          : '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';

      if (!statsMap.containsKey(key)) {
        statsMap[key] = MonthlyStats(
          month: isWeekly ? key : _getMonthName(tx.date.month),
          year: tx.date.year,
          income: 0,
          expense: 0,
          net: 0,
          transactionCount: 0,
        );
      }

      final existing = statsMap[key]!;
      if (tx.type == TransactionType.income) {
        statsMap[key] = MonthlyStats(
          month: existing.month,
          year: existing.year,
          income: existing.income + tx.amount,
          expense: existing.expense,
          net: existing.net + tx.amount,
          transactionCount: existing.transactionCount + 1,
        );
      } else if (tx.type == TransactionType.expense) {
        statsMap[key] = MonthlyStats(
          month: existing.month,
          year: existing.year,
          income: existing.income,
          expense: existing.expense + tx.amount,
          net: existing.net - tx.amount,
          transactionCount: existing.transactionCount + 1,
        );
      }
    }

    return statsMap.values.toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Future<MonthlyStats> _getMonthTotals(
    int year,
    int month,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final txs = await _getTransactionsForPeriod(
      'custom',
      accountIds,
      categoryIds: categoryIds,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
      customStartDate: start,
      customEndDate: end,
    );

    double income = 0;
    double expense = 0;

    for (final tx in txs) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expense += tx.amount;
      }
    }

    return MonthlyStats(
      month: _getMonthName(month),
      year: year,
      income: income,
      expense: expense,
      net: income - expense,
      transactionCount: txs.length,
    );
  }

  Future<List<double>> _getDailySpendingForPeriod(
    String period,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final txs = await _getTransactionsForPeriod(
      period,
      accountIds,
      categoryIds: categoryIds,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailySpending = List<double>.filled(daysInMonth, 0.0);

    for (final tx in txs) {
      if (tx.type == TransactionType.expense &&
          tx.date.year == now.year &&
          tx.date.month == now.month) {
        final day = tx.date.day - 1; // 0-indexed
        if (day >= 0 && day < daysInMonth) {
          dailySpending[day] += tx.amount;
        }
      }
    }

    return dailySpending;
  }

  Future<Map<String, List<Transaction>>> _getTopTransactionsForPeriod(
    String period,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final all = await _getTransactionsForPeriod(
      period,
      accountIds,
      categoryIds: categoryIds,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    // Filter and sort incomes by transaction type
    final incomes = all.where((t) => t.type == TransactionType.income).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topIncomes = incomes.take(3).toList();

    // Filter and sort expenses by transaction type (by absolute value)
    final expenses =
        all.where((t) => t.type == TransactionType.expense).toList()..sort(
          (a, b) => b.amount.compareTo(a.amount),
        ); // Highest amount first
    final topExpenses = expenses.take(3).toList();

    return {'incomes': topIncomes, 'expenses': topExpenses};
  }

  Future<List<_TagStat>> _getTopTagsForPeriod(
    String period,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final all = await _getTransactionsForPeriod(
      period,
      accountIds,
      categoryIds: categoryIds,
      categoryIncludeMode: categoryIncludeMode,
      tagIds: tagIds,
      tagIncludeMode: tagIncludeMode,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );

    // Compute tag stats (expense tags only)
    final tagMap = <String, _TagStat>{};
    for (final t in all) {
      if (t.type != TransactionType.expense) continue;
      for (final tag in t.tagNames) {
        final existing = tagMap[tag];
        if (existing == null) {
          tagMap[tag] = _TagStat(name: tag, count: 1, amount: t.amount.abs());
        } else {
          tagMap[tag] = _TagStat(
            name: tag,
            count: existing.count + 1,
            amount: existing.amount + t.amount.abs(),
          );
        }
      }
    }

    final tagList = tagMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return tagList.take(10).toList();
  }

  Future<List<Transaction>> _getTransactionsForPeriod(
    String period,
    List<String> accountIds, {
    List<String> categoryIds = const [],
    bool categoryIncludeMode = false,
    List<String> tagIds = const [],
    bool tagIncludeMode = false,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (period) {
      case 'current_month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'current_year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'custom':
        start = customStartDate;
        end = customEndDate != null
            ? DateTime(
                customEndDate.year,
                customEndDate.month,
                customEndDate.day,
                23,
                59,
                59,
              )
            : null;
        break;
      case 'all_time':
        start = null;
        end = null;
        break;
    }

    final all = await _reportsService.getTransactionsInRange(
      startDate: start,
      endDate: end,
    );

    // Filter by account IDs if specified
    var filtered = accountIds.isEmpty
        ? all
        : all.where((t) => accountIds.contains(t.accountId)).toList();

    // Apply category filter (include or exclude mode)
    if (categoryIds.isNotEmpty) {
      if (categoryIncludeMode) {
        // Include only these categories
        final includeUncategorised = categoryIds.contains('uncategorised');
        filtered = filtered.where((t) {
          // Include if has category ID in the list
          if (t.categoryId != null && categoryIds.contains(t.categoryId)) {
            return true;
          }
          // Include if uncategorised and user selected uncategorised
          if (t.categoryId == null && includeUncategorised) {
            return true;
          }
          return false;
        }).toList();
      } else {
        // Exclude these categories
        final excludeUncategorised = categoryIds.contains('uncategorised');
        filtered = filtered.where((t) {
          // Exclude if has category ID in the exclude list
          if (t.categoryId != null && categoryIds.contains(t.categoryId)) {
            return false;
          }
          // Exclude if uncategorised and user excluded uncategorised
          if (t.categoryId == null && excludeUncategorised) {
            return false;
          }
          return true;
        }).toList();
      }
    }

    // Apply tag filter (include or exclude mode)
    if (tagIds.isNotEmpty) {
      if (tagIncludeMode) {
        // Include only transactions that have at least one of these tags
        final includeUntagged = tagIds.contains('untagged');
        filtered = filtered.where((t) {
          // Include if has tag ID in the list
          if (t.tagIds.any((tagId) => tagIds.contains(tagId))) {
            return true;
          }
          // Include if untagged and user selected untagged
          if (t.tagIds.isEmpty && includeUntagged) {
            return true;
          }
          return false;
        }).toList();
      } else {
        // Exclude transactions that have any of these tags
        final excludeUntagged = tagIds.contains('untagged');
        filtered = filtered.where((t) {
          // Exclude if has tag ID in the exclude list
          if (t.tagIds.any((tagId) => tagIds.contains(tagId))) {
            return false;
          }
          // Exclude if untagged and user excluded untagged
          if (t.tagIds.isEmpty && excludeUntagged) {
            return false;
          }
          return true;
        }).toList();
      }
    }

    return filtered;
  }
}
