import 'dart:math';
import 'package:intl/intl.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/reports_service.dart';
import 'package:ledger/services/user_preference_service.dart';

class AiToolsService {
  final TransactionService _transactionService = TransactionService();
  final AccountService _accountService = AccountService();
  final BudgetService _budgetService = BudgetService();
  final ReportsService _reportsService = ReportsService();

  // Cache currency info to avoid multiple async calls
  String? _cachedCurrency;
  String? _cachedSymbol;

  /// Get currency symbol for the default currency
  Future<String> _getCurrencySymbol() async {
    if (_cachedSymbol != null) return _cachedSymbol!;

    final currency = await UserPreferenceService.getDefaultCurrency();
    _cachedCurrency = currency;

    switch (currency.toUpperCase()) {
      case 'USD':
        _cachedSymbol = '\$';
        break;
      case 'EUR':
        _cachedSymbol = '€';
        break;
      case 'GBP':
        _cachedSymbol = '£';
        break;
      case 'INR':
        _cachedSymbol = '₹';
        break;
      case 'JPY':
        _cachedSymbol = '¥';
        break;
      case 'AUD':
        _cachedSymbol = 'A\$';
        break;
      case 'CAD':
        _cachedSymbol = 'C\$';
        break;
      default:
        _cachedSymbol = currency;
    }
    return _cachedSymbol!;
  }

  Future<Map<String, dynamic>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final transactions = await _transactionService.getFilteredTransactions(
        startDate:
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
        categoryId: categoryId,
      );

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      return {
        'type': 'transactions',
        'count': transactions.length,
        'isEmpty': transactions.isEmpty,
        'currency': _cachedCurrency,
        'data': transactions
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'amount': t.amount,
                'formatted_amount': '$symbol${formatter.format(t.amount)}',
                'type': t.type.toString(),
                'date': t.date.toIso8601String(),
                'category': t.categoryId,
              },
            )
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSpendingByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final summary = await _reportsService.getSpendingSummary(
        startDate: start,
        endDate: end,
      );

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      final categoryData = summary.topCategories
          .map(
            (cat) => {
              'name': cat.categoryName,
              'amount': cat.amount,
              'formatted_amount': '$symbol${formatter.format(cat.amount)}',
              'percentage': cat.percentage,
            },
          )
          .toList();

      // Check if data is empty
      final hasData =
          categoryData.isNotEmpty &&
          categoryData.any((cat) => (cat['amount'] as double) > 0);

      return {
        'type': 'category_spending',
        'period': '${start.toIso8601String()} to ${end.toIso8601String()}',
        'currency': _cachedCurrency,
        'data': categoryData,
        'isEmpty': !hasData,
        'message': hasData ? null : 'No spending data found for this period',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSpendingByMonth({int monthsBack = 6}) async {
    try {
      final now = DateTime.now();
      final monthlyData = <Map<String, dynamic>>[];

      for (var i = monthsBack - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final endDate = DateTime(date.year, date.month + 1, 0);

        final summary = await _reportsService.getSpendingSummary(
          startDate: date,
          endDate: endDate,
        );

        final symbol = await _getCurrencySymbol();
        final formatter = NumberFormat('#,##0.00');

        monthlyData.add({
          'month': '${date.year}-${date.month.toString().padLeft(2, '0')}',
          'income': summary.totalIncome,
          'formatted_income': '$symbol${formatter.format(summary.totalIncome)}',
          'expense': summary.totalExpense,
          'formatted_expense':
              '$symbol${formatter.format(summary.totalExpense)}',
          'net': summary.netBalance,
          'formatted_net': '$symbol${formatter.format(summary.netBalance)}',
        });
      }

      final hasData = monthlyData.any(
        (m) => (m['income'] as double) > 0 || (m['expense'] as double) > 0,
      );

      return {
        'type': 'monthly_trend',
        'currency': _cachedCurrency,
        'data': monthlyData,
        'isEmpty': !hasData,
        'message': hasData ? null : 'No transaction history found',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAccountBalances() async {
    try {
      final accounts = await _accountService.fetchAccounts();
      final netWorth = await _accountService.fetchNetWorth();

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      final accountList = accounts
          .where((a) => a != null)
          .map(
            (a) => {
              'id': a!.id,
              'name': a.name,
              'balance': a.balance,
              'formatted_balance': '$symbol${formatter.format(a.balance)}',
              'currency': a.currency,
            },
          )
          .toList();

      return {
        'type': 'account_balances',
        'netWorth': netWorth,
        'formatted_netWorth': '$symbol${formatter.format(netWorth)}',
        'currency': _cachedCurrency,
        'accounts': accountList,
        'isEmpty': accountList.isEmpty,
        'message': accountList.isEmpty ? 'No accounts found' : null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBudgetStatus() async {
    try {
      final budgets = await _budgetService.fetchBudgets('local');

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      final budgetData = [];
      for (final budget in budgets) {
        final progress = await _budgetService.calculateProgress(budget);

        budgetData.add({
          'name': budget.name,
          'amount': budget.amount,
          'formatted_amount': '$symbol${formatter.format(budget.amount)}',
          'spent': progress.spent,
          'formatted_spent': '$symbol${formatter.format(progress.spent)}',
          'remaining': progress.remaining,
          'formatted_remaining':
              '$symbol${formatter.format(progress.remaining)}',
          'percentage': progress.percent,
        });
      }

      return {
        'type': 'budget_status',
        'currency': _cachedCurrency,
        'data': budgetData,
        'isEmpty': budgetData.isEmpty,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Calculate mathematical expressions
  Future<Map<String, dynamic>> calculate(String expression) async {
    try {
      // Simple calculator - can be enhanced with a proper expression parser
      final result = _evaluateExpression(expression);
      return {
        'type': 'calculation',
        'expression': expression,
        'result': result,
      };
    } catch (e) {
      return {'error': 'Invalid mathematical expression: ${e.toString()}'};
    }
  }

  /// Get statistical metrics for a list of amounts
  Future<Map<String, dynamic>> getStatistics(List<double> amounts) async {
    try {
      if (amounts.isEmpty) {
        return {
          'type': 'statistics',
          'error': 'No data provided for statistical analysis',
        };
      }

      amounts.sort();
      final sum = amounts.reduce((a, b) => a + b);
      final mean = sum / amounts.length;
      final median = amounts.length.isOdd
          ? amounts[amounts.length ~/ 2]
          : (amounts[amounts.length ~/ 2 - 1] + amounts[amounts.length ~/ 2]) /
                2;
      final min = amounts.first;
      final max = amounts.last;

      // Calculate standard deviation
      final variance =
          amounts.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          amounts.length;
      final stdDev = sqrt(variance);

      return {
        'type': 'statistics',
        'count': amounts.length,
        'sum': sum,
        'mean': mean,
        'median': median,
        'min': min,
        'max': max,
        'stdDev': stdDev,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Simple expression evaluator (basic arithmetic)
  double _evaluateExpression(String expr) {
    // Remove whitespace
    expr = expr.replaceAll(' ', '');

    // This is a very basic evaluator - for production, use a proper parser
    // Supports +, -, *, /, parentheses
    try {
      // For now, just handle simple cases
      // A full implementation would use the Shunting Yard algorithm
      if (expr.contains('+')) {
        final parts = expr.split('+');
        return parts.map(_evaluateExpression).reduce((a, b) => a + b);
      } else if (expr.contains('-') && !expr.startsWith('-')) {
        final parts = expr.split('-');
        return parts.map(_evaluateExpression).reduce((a, b) => a - b);
      } else if (expr.contains('*')) {
        final parts = expr.split('*');
        return parts.map(_evaluateExpression).reduce((a, b) => a * b);
      } else if (expr.contains('/')) {
        final parts = expr.split('/');
        return parts.map(_evaluateExpression).reduce((a, b) => a / b);
      } else {
        return double.parse(expr);
      }
    } catch (e) {
      throw Exception('Cannot evaluate expression: $expr');
    }
  }

  /// Get statistics from transaction amounts
  Future<Map<String, dynamic>> getStatisticsFromTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      if (transactions['isEmpty'] == true ||
          transactions['data'] == null ||
          (transactions['data'] as List).isEmpty) {
        return {
          'type': 'statistics',
          'error': 'No transactions found for statistical analysis',
        };
      }

      final amounts = (transactions['data'] as List)
          .map((t) => (t['amount'] as num).toDouble())
          .toList();

      return await getStatistics(amounts);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get the most recent N transactions
  Future<Map<String, dynamic>> getRecentTransactions({int limit = 10}) async {
    try {
      final transactions = await _transactionService.getAllTransactions();

      // Sort by date descending and take limit
      transactions.sort((a, b) => b.date.compareTo(a.date));
      final recentTransactions = transactions.take(limit).toList();

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      return {
        'type': 'recent_transactions',
        'count': recentTransactions.length,
        'currency': _cachedCurrency,
        'data': recentTransactions
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'amount': t.amount,
                'formatted_amount': '$symbol${formatter.format(t.amount)}',
                'type': t.type.toString(),
                'date': t.date.toIso8601String(),
                'category': t.categoryId,
              },
            )
            .toList(),
        'isEmpty': recentTransactions.isEmpty,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get top N expense transactions
  Future<Map<String, dynamic>> getTopExpenses({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await _transactionService.getFilteredTransactions(
        startDate:
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );

      // Filter expenses only and sort by amount descending
      final expenses = transactions
          .where((t) => t.type.toString().contains('expense'))
          .toList();

      expenses.sort((a, b) => b.amount.compareTo(a.amount));
      final topExpenses = expenses.take(limit).toList();

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      return {
        'type': 'top_expenses',
        'count': topExpenses.length,
        'currency': _cachedCurrency,
        'data': topExpenses
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'amount': t.amount,
                'formatted_amount': '$symbol${formatter.format(t.amount)}',
                'date': t.date.toIso8601String(),
                'category': t.categoryId,
              },
            )
            .toList(),
        'isEmpty': topExpenses.isEmpty,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Compare spending between two periods
  Future<Map<String, dynamic>> comparePeriods(String period) async {
    try {
      final now = DateTime.now();
      DateTime currentStart, currentEnd, previousStart, previousEnd;

      if (period == 'month') {
        // This month vs last month
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = now;
        previousStart = DateTime(now.year, now.month - 1, 1);
        previousEnd = DateTime(
          now.year,
          now.month,
          0,
        ); // Last day of previous month
      } else {
        // This week vs last week
        final weekday = now.weekday;
        currentStart = now.subtract(Duration(days: weekday - 1));
        currentEnd = now;
        previousStart = currentStart.subtract(const Duration(days: 7));
        previousEnd = currentStart.subtract(const Duration(days: 1));
      }

      final currentSummary = await _reportsService.getSpendingSummary(
        startDate: currentStart,
        endDate: currentEnd,
      );

      final previousSummary = await _reportsService.getSpendingSummary(
        startDate: previousStart,
        endDate: previousEnd,
      );

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      final difference =
          currentSummary.totalExpense - previousSummary.totalExpense;
      final percentageChange = previousSummary.totalExpense > 0
          ? (difference / previousSummary.totalExpense) * 100
          : 0.0;

      return {
        'type': 'period_comparison',
        'period': period,
        'currency': _cachedCurrency,
        'current': {
          'start': currentStart.toIso8601String(),
          'end': currentEnd.toIso8601String(),
          'income': currentSummary.totalIncome,
          'formatted_income':
              '$symbol${formatter.format(currentSummary.totalIncome)}',
          'expense': currentSummary.totalExpense,
          'formatted_expense':
              '$symbol${formatter.format(currentSummary.totalExpense)}',
          'net': currentSummary.netBalance,
          'formatted_net':
              '$symbol${formatter.format(currentSummary.netBalance)}',
        },
        'previous': {
          'start': previousStart.toIso8601String(),
          'end': previousEnd.toIso8601String(),
          'income': previousSummary.totalIncome,
          'formatted_income':
              '$symbol${formatter.format(previousSummary.totalIncome)}',
          'expense': previousSummary.totalExpense,
          'formatted_expense':
              '$symbol${formatter.format(previousSummary.totalExpense)}',
          'net': previousSummary.netBalance,
          'formatted_net':
              '$symbol${formatter.format(previousSummary.netBalance)}',
        },
        'difference': difference,
        'formatted_difference': '$symbol${formatter.format(difference.abs())}',
        'percentageChange': percentageChange,
        'isEmpty':
            currentSummary.totalExpense == 0 &&
            previousSummary.totalExpense == 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Search transactions by keyword
  Future<Map<String, dynamic>> searchTransactions(String keyword) async {
    try {
      if (keyword.isEmpty) {
        return {
          'type': 'search_results',
          'error': 'No keyword provided for search',
        };
      }

      final allTransactions = await _transactionService.getAllTransactions();

      final results = allTransactions
          .where(
            (t) =>
                t.title.toLowerCase().contains(keyword.toLowerCase()) ||
                (t.description?.toLowerCase().contains(keyword.toLowerCase()) ??
                    false),
          )
          .toList();

      final symbol = await _getCurrencySymbol();
      final formatter = NumberFormat('#,##0.00');

      return {
        'type': 'search_results',
        'keyword': keyword,
        'count': results.length,
        'currency': _cachedCurrency,
        'data': results
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'amount': t.amount,
                'formatted_amount': '$symbol${formatter.format(t.amount)}',
                'type': t.type.toString(),
                'date': t.date.toIso8601String(),
                'category': t.categoryId,
              },
            )
            .toList(),
        'isEmpty': results.isEmpty,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
