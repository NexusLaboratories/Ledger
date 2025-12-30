import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/spending_summary.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:intl/intl.dart';

class ReportsService {
  final AbstractTransactionService _transactionService;
  final AbstractCategoryService _categoryService;

  ReportsService({
    AbstractTransactionService? transactionService,
    AbstractCategoryService? categoryService,
  }) : _transactionService = transactionService ?? TransactionService(),
       _categoryService = categoryService ?? CategoryService();

  /// Get spending summary for a date range
  Future<SpendingSummary> getSpendingSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allTransactions = await _transactionService.getAllTransactions();
    final categories = await _categoryService.fetchCategoriesForUser('local');

    LoggerService.d(
      'ReportsService: getAllTransactions returned ${allTransactions.length} transactions',
    );
    LoggerService.d(
      'ReportsService: Date filter - start: $startDate, end: $endDate',
    );

    // Filter by date range
    var filteredTransactions = allTransactions;
    if (startDate != null) {
      filteredTransactions = filteredTransactions
          .where(
            (t) => t.date.isAfter(startDate.subtract(const Duration(days: 1))),
          )
          .toList();
    }
    if (endDate != null) {
      filteredTransactions = filteredTransactions
          .where((t) => t.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    LoggerService.d(
      'ReportsService: After filtering, ${filteredTransactions.length} transactions remain',
    );

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    final categoryMap = <String, double>{};
    final categoryCountMap = <String, int>{};
    const uncategorisedKey = '__uncategorised__';

    // Helper to find the top-level parent (root) category for a given category id.
    String getRootCategoryId(String id) {
      var current = id;
      final visited = <String>{};
      while (true) {
        if (visited.contains(current)) break; // circular guard
        visited.add(current);
        final cat = categories.firstWhere(
          (c) => c.id == current,
          orElse: () => Category(id: current, name: 'Unknown'),
        );
        if (cat.parentCategoryId == null) break;
        current = cat.parentCategoryId!;
      }
      return current;
    }

    for (final tx in filteredTransactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;

        // Category breakdown aggregated to top-level parents: a transaction
        // assigned to a child category will contribute to its top-level parent.
        // Only include expenses in spending breakdown
        if (tx.categoryId != null) {
          final rootId = getRootCategoryId(tx.categoryId!);
          categoryMap[rootId] = (categoryMap[rootId] ?? 0) + tx.amount;
          categoryCountMap[rootId] = (categoryCountMap[rootId] ?? 0) + 1;
        } else {
          // Track uncategorised expense transactions
          categoryMap[uncategorisedKey] =
              (categoryMap[uncategorisedKey] ?? 0) + tx.amount;
          categoryCountMap[uncategorisedKey] =
              (categoryCountMap[uncategorisedKey] ?? 0) + 1;
        }
      }
    }

    // Monthly trend
    final monthlyTrend = <String, double>{};
    for (final tx in filteredTransactions) {
      final monthKey = DateFormat('MMM yyyy').format(tx.date);
      if (tx.type == TransactionType.expense) {
        monthlyTrend[monthKey] = (monthlyTrend[monthKey] ?? 0) + tx.amount;
      }
    }

    // Top categories
    final topCategories = <CategorySpending>[];

    for (final entry in categoryMap.entries) {
      final id = entry.key;
      String categoryName;

      if (id == uncategorisedKey) {
        // Transactions without a category should be shown as 'Uncategorised'
        categoryName = 'Uncategorised';
      } else {
        final category = categories.firstWhere(
          (c) => c.id == id,
          orElse: () => Category(id: id, name: 'Unknown'),
        );

        // Only include top-level (parentless) categories in "Top Spending Categories"
        if (category.parentCategoryId != null) continue;

        categoryName = category.name;
      }

      final percentage = totalExpense > 0
          ? (entry.value / totalExpense) * 100
          : 0.0;

      topCategories.add(
        CategorySpending(
          categoryId: id,
          categoryName: categoryName,
          amount: entry.value,
          transactionCount: categoryCountMap[entry.key] ?? 0,
          percentage: percentage.toDouble(),
        ),
      );
    }
    topCategories.sort((a, b) => b.amount.compareTo(a.amount));

    return SpendingSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: totalIncome - totalExpense,
      categoryBreakdown: categoryMap,
      monthlyTrend: monthlyTrend,
      topCategories: topCategories.take(10).toList(),
      transactionCount: filteredTransactions.length,
      // (additional metrics removed per UI requirements)
    );
  }

  /// Return all transactions (pass-through to transaction service)
  Future<List<Transaction>> getAllTransactions() async {
    return _transactionService.getAllTransactions();
  }

  /// Get transactions between an optional date range. If start/end are null, return all transactions.
  Future<List<Transaction>> getTransactionsInRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final all = await _transactionService.getAllTransactions();
    var filtered = all;
    if (startDate != null) {
      filtered = filtered.where((t) => !t.date.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((t) => !t.date.isAfter(endDate)).toList();
    }
    return filtered;
  }

  /// Get monthly statistics for the last N months
  Future<List<MonthlyStats>> getMonthlyStats({int months = 6}) async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = DateTime.now();
    final monthlyData = <String, MonthlyStats>{};

    for (final tx in allTransactions) {
      // Only include transactions from the last N months
      final monthsDiff =
          (now.year - tx.date.year) * 12 + (now.month - tx.date.month);
      if (monthsDiff >= months) continue;

      final monthKey =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      final monthName = DateFormat('MMM').format(tx.date);

      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = MonthlyStats(
          month: monthName,
          year: tx.date.year,
          income: 0,
          expense: 0,
          net: 0,
          transactionCount: 0,
        );
      }

      final existing = monthlyData[monthKey]!;
      final newIncome = tx.type == TransactionType.income
          ? existing.income + tx.amount
          : existing.income;
      final newExpense = tx.type == TransactionType.expense
          ? existing.expense + tx.amount
          : existing.expense;

      monthlyData[monthKey] = MonthlyStats(
        month: existing.month,
        year: existing.year,
        income: newIncome,
        expense: newExpense,
        net: newIncome - newExpense,
        transactionCount: existing.transactionCount + 1,
      );
    }

    // Sort by year and month descending
    final sorted = monthlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return sorted.map((e) => e.value).toList();
  }

  /// Get monthly statistics for the current year only (Jan-Dec of current year)
  Future<List<MonthlyStats>> getMonthlyStatsForCurrentYear() async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = DateTime.now();
    final currentYear = now.year;
    final monthlyData = <int, MonthlyStats>{};

    // Initialize all 12 months of the current year
    for (int month = 1; month <= 12; month++) {
      monthlyData[month] = MonthlyStats(
        month: DateFormat('MMM').format(DateTime(currentYear, month)),
        year: currentYear,
        income: 0,
        expense: 0,
        net: 0,
        transactionCount: 0,
      );
    }

    // Aggregate transactions for each month
    for (final tx in allTransactions) {
      // Only include transactions from the current year
      if (tx.date.year != currentYear) continue;

      final month = tx.date.month;
      final existing = monthlyData[month]!;
      final newIncome = tx.type == TransactionType.income
          ? existing.income + tx.amount
          : existing.income;
      final newExpense = tx.type == TransactionType.expense
          ? existing.expense + tx.amount
          : existing.expense;

      monthlyData[month] = MonthlyStats(
        month: existing.month,
        year: currentYear,
        income: newIncome,
        expense: newExpense,
        net: newIncome - newExpense,
        transactionCount: existing.transactionCount + 1,
      );
    }

    // Return months in descending order (Dec to Jan)
    final sorted = monthlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return sorted.map((e) => e.value).toList();
  }

  /// Get current month summary
  Future<SpendingSummary> getCurrentMonthSummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getSpendingSummary(startDate: startOfMonth, endDate: endOfMonth);
  }

  /// Get current year summary
  Future<SpendingSummary> getCurrentYearSummary() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
    return getSpendingSummary(startDate: startOfYear, endDate: endOfYear);
  }

  /// Get all time summary
  Future<SpendingSummary> getAllTimeSummary() async {
    return getSpendingSummary();
  }

  /// Get average daily spending for current month
  Future<double> getAverageDailySpendingForCurrentMonth() async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysElapsed = now.day; // Use current day of month, not total days

    final monthExpenses = allTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              !t.date.isBefore(startOfMonth) &&
              !t.date.isAfter(endOfMonth),
        )
        .toList();

    if (monthExpenses.isEmpty) return 0;

    final total = monthExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    return total / daysElapsed;
  }

  /// Get daily expense totals for the current month
  /// Returns a list of length equal to days elapsed in month where index 0 => day 1
  Future<List<double>> getDailySpendingForCurrentMonth({
    DateTime? referenceDate,
    bool upToTodayOnly = true,
  }) async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = referenceDate ?? DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final daysInMonth = endOfMonth.day;
    final cutoffDay = upToTodayOnly ? now.day : daysInMonth;

    final daily = List<double>.filled(cutoffDay, 0.0);

    for (final tx in allTransactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.date.isBefore(startOfMonth) || tx.date.isAfter(endOfMonth)) {
        continue;
      }

      final day = tx.date.day; // 1-based
      if (day > cutoffDay) continue; // ignore future days when upToTodayOnly
      daily[day - 1] = daily[day - 1] + tx.amount;
    }

    return daily;
  }

  /// Get average daily spending for current year
  Future<double> getAverageDailySpendingForCurrentYear() async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
    final dayOfYear = now.difference(startOfYear).inDays + 1;

    final yearExpenses = allTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              !t.date.isBefore(startOfYear) &&
              !t.date.isAfter(endOfYear),
        )
        .toList();

    if (yearExpenses.isEmpty) return 0;

    final total = yearExpenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    return total / dayOfYear;
  }

  /// Get average daily spending for all time
  Future<double> getAverageDailySpendingForAllTime() async {
    final allTransactions = await _transactionService.getAllTransactions();
    final expenses = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (expenses.isEmpty) return 0;

    // Find the date range from first transaction to today
    final dates = expenses.map((t) => t.date).toList()..sort();
    final firstDate = dates.first;
    final now = DateTime.now();
    final totalDays = now.difference(firstDate).inDays + 1;

    if (totalDays == 0) return 0;

    final total = expenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    return total / totalDays;
  }

  /// Get weekly statistics for the current month
  Future<List<MonthlyStats>> getWeeklyStatsForCurrentMonth() async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final weeklyData = <String, MonthlyStats>{};

    // Calculate current week number within the month
    final currentDayOfMonth = now.day;
    final currentWeekNumber = ((currentDayOfMonth - 1) ~/ 7) + 1;

    // Initialize only weeks up to the current week
    for (int week = 1; week <= currentWeekNumber; week++) {
      weeklyData['Week $week'] = MonthlyStats(
        month: 'Week $week',
        year: now.year,
        income: 0,
        expense: 0,
        net: 0,
        transactionCount: 0,
      );
    }

    for (final tx in allTransactions) {
      // Only include transactions from current month
      if (tx.date.isBefore(startOfMonth) || tx.date.isAfter(endOfMonth)) {
        continue;
      }

      // Calculate week number within the month (Week 1, Week 2, etc.)
      final dayOfMonth = tx.date.day;
      final weekNumber = ((dayOfMonth - 1) ~/ 7) + 1;
      final weekKey = 'Week $weekNumber';

      if (!weeklyData.containsKey(weekKey)) {
        weeklyData[weekKey] = MonthlyStats(
          month: weekKey,
          year: now.year,
          income: 0,
          expense: 0,
          net: 0,
          transactionCount: 0,
        );
      }

      final existing = weeklyData[weekKey]!;
      final newIncome = tx.type == TransactionType.income
          ? existing.income + tx.amount
          : existing.income;
      final newExpense = tx.type == TransactionType.expense
          ? existing.expense + tx.amount
          : existing.expense;

      weeklyData[weekKey] = MonthlyStats(
        month: existing.month,
        year: existing.year,
        income: newIncome,
        expense: newExpense,
        net: newIncome - newExpense,
        transactionCount: existing.transactionCount + 1,
      );
    }

    // Sort by week number descending (newest first)
    final sorted = weeklyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return sorted.map((e) => e.value).toList();
  }

  /// Get totals for a specific month (year, month)
  Future<MonthlyStats> getTotalsForMonth(int year, int month) async {
    final allTransactions = await _transactionService.getAllTransactions();

    double income = 0.0;
    double expense = 0.0;
    int txCount = 0;

    for (final tx in allTransactions) {
      if (tx.date.year == year && tx.date.month == month) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
        txCount += 1;
      }
    }

    final monthName = DateFormat('MMM').format(DateTime(year, month));
    return MonthlyStats(
      month: monthName,
      year: year,
      income: income,
      expense: expense,
      net: income - expense,
      transactionCount: txCount,
    );
  }

  /// Get yearly statistics for the past N years
  Future<List<MonthlyStats>> getYearlyStats({int years = 5}) async {
    final allTransactions = await _transactionService.getAllTransactions();
    final now = DateTime.now();
    final yearlyData = <int, MonthlyStats>{};

    for (final tx in allTransactions) {
      final yearsDiff = now.year - tx.date.year;
      if (yearsDiff >= years) continue;

      final year = tx.date.year;

      if (!yearlyData.containsKey(year)) {
        yearlyData[year] = MonthlyStats(
          month: year.toString(),
          year: year,
          income: 0,
          expense: 0,
          net: 0,
          transactionCount: 0,
        );
      }

      final existing = yearlyData[year]!;
      final newIncome = tx.type == TransactionType.income
          ? existing.income + tx.amount
          : existing.income;
      final newExpense = tx.type == TransactionType.expense
          ? existing.expense + tx.amount
          : existing.expense;

      yearlyData[year] = MonthlyStats(
        month: existing.month,
        year: year,
        income: newIncome,
        expense: newExpense,
        net: newIncome - newExpense,
        transactionCount: existing.transactionCount + 1,
      );
    }

    // Sort by year descending (newest first)
    final sorted = yearlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return sorted.map((e) => e.value).toList();
  }
}
