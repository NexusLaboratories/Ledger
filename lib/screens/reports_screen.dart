import 'package:flutter/material.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/services/reports_service.dart';
import 'package:ledger/models/spending_summary.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/models/budget.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/services/report_service.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/report_options.dart';
import 'package:ledger/components/reports/report_customization_modal.dart';
import 'package:printing/printing.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/components/reports/report_stat_card.dart';
import 'package:ledger/components/ui/common/period_selector.dart';
import 'package:ledger/components/budgets/budget_progress_row.dart';
import 'package:ledger/components/ui/common/glass_container.dart';

class _TagStat {
  final String name;
  final int count;
  final double amount;
  _TagStat({required this.name, required this.count, required this.amount});
}

class ReportsScreen extends StatefulWidget {
  final ReportsService? reportsService;
  final ReportService? reportService;

  const ReportsScreen({super.key, this.reportsService, this.reportService});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsService _reportsService;
  late Future<void> _loadFuture;

  SpendingSummary? _currentMonthSummary;
  SpendingSummary? _currentYearSummary;
  SpendingSummary? _allTimeSummary;

  String _currency = 'INR';
  String _dateFormatKey = DateFormats.defaultKey;

  Future<void> _loadDateFormat() async {
    final k = await UserPreferenceService.getDateFormat();
    if (mounted) setState(() => _dateFormatKey = k);
  }

  void _onDateFormatChanged() {
    if (mounted) {
      setState(() => _dateFormatKey = DateFormatService.notifier.value);
    }
  }

  @override
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    super.dispose();
  }

  List<MonthlyStats>? _weeklyStatsCurrentMonth;
  List<double>? _dailySpendingCurrentMonth;
  List<MonthlyStats>? _monthlyStatsThisYear;
  List<MonthlyStats>? _monthlyStatsAllTime;

  // Transactions filtered for the selected period
  // Top lists for the selected period (top 3 incomes & top 3 expenses)
  List<Transaction>? _transactionsForPeriod;
  List<Transaction>? _topIncomes;
  List<Transaction>? _topExpenses;

  // Account names for display (accountId => name)
  Map<String, String> _accountNameMap = {};
  late final AccountService _accountService;
  double? _averageDailySpendingMonth;
  double? _averageDailySpendingYear;
  double? _averageDailySpendingAllTime;
  late final BudgetService _budgetService;
  List<BudgetProgress>? _budgetProgresses;
  List<Transaction>? _allTransactions;
  List<_TagStat>? _topTagStats;
  Transaction? _topTransactionForTopTag;

  String _selectedPeriod = 'current_month';

  @override
  void initState() {
    super.initState();
    _reportsService = widget.reportsService ?? ReportsService();
    _budgetService = BudgetService();
    _accountService = AccountService();
    _loadDateFormat();
    DateFormatService.notifier.addListener(_onDateFormatChanged);
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Run independent async calls in parallel for better performance
      final results = await Future.wait([
        _reportsService.getCurrentMonthSummary(),
        _reportsService.getCurrentYearSummary(),
        _reportsService.getAllTimeSummary(),
        _reportsService.getWeeklyStatsForCurrentMonth(),
        _reportsService.getDailySpendingForCurrentMonth(),
        _reportsService.getMonthlyStatsForCurrentYear(),
        _reportsService.getYearlyStats(years: 5),
        _reportsService.getAverageDailySpendingForCurrentMonth(),
        _reportsService.getAverageDailySpendingForCurrentYear(),
        _reportsService.getAverageDailySpendingForAllTime(),
        _reportsService.getAllTransactions(),
        _accountService.fetchAccounts(),
        _budgetService.fetchBudgets('local'),
        UserPreferenceService.getDefaultCurrency(),
      ]);

      final currentMonth = results[0] as SpendingSummary;
      final currentYear = results[1] as SpendingSummary;
      final allTime = results[2] as SpendingSummary;
      final weeklyCurrentMonth = results[3] as List<MonthlyStats>;
      final dailyCurrentMonth = results[4] as List<double>;
      final monthlyThisYear = results[5] as List<MonthlyStats>;
      final monthlyAllTime = results[6] as List<MonthlyStats>;
      final avgDailyMonth = results[7] as double?;
      final avgDailyYear = results[8] as double?;
      final avgDailyAllTime = results[9] as double?;
      final allTransactions = results[10] as List<Transaction>;
      final accounts = results[11] as List<Account?>;
      final budgets = results[12] as List<Budget>;
      final defaultCurrency = results[13] as String;
      final progresses = <BudgetProgress>[];

      // Set currency from already loaded data
      setState(() => _currency = defaultCurrency);
      for (final b in budgets) {
        try {
          final p = await _budgetService.calculateProgress(b);
          progresses.add(p);
        } catch (e) {
          LoggerService.w(
            'Failed to calculate budget progress for ${b.name}',
            e,
          );
        }
      }

      // Build account name map for quick lookup when rendering transactions
      final accMap = <String, String>{};
      for (final a in accounts) {
        if (a == null) continue;
        accMap[a.id] = a.name;
      }

      LoggerService.d('=== REPORTS DEBUG ===');
      LoggerService.d(
        'Current Month: Income=${currentMonth.totalIncome}, Expense=${currentMonth.totalExpense}, Txns=${currentMonth.transactionCount}',
      );
      LoggerService.d(
        'Current Year: Income=${currentYear.totalIncome}, Expense=${currentYear.totalExpense}, Txns=${currentYear.transactionCount}',
      );
      LoggerService.d(
        'All Time: Income=${allTime.totalIncome}, Expense=${allTime.totalExpense}, Txns=${allTime.transactionCount}',
      );
      LoggerService.d(
        'Weekly Current Month: ${weeklyCurrentMonth.length} weeks',
      );
      LoggerService.d('Monthly This Year: ${monthlyThisYear.length} months');
      LoggerService.d('Monthly All Time: ${monthlyAllTime.length} months');

      setState(() {
        _currentMonthSummary = currentMonth;
        _currentYearSummary = currentYear;
        _allTimeSummary = allTime;
        _weeklyStatsCurrentMonth = weeklyCurrentMonth;
        _dailySpendingCurrentMonth = dailyCurrentMonth;
        _monthlyStatsThisYear = monthlyThisYear;
        _monthlyStatsAllTime = monthlyAllTime;
        _averageDailySpendingMonth = avgDailyMonth;
        _averageDailySpendingYear = avgDailyYear;
        _averageDailySpendingAllTime = avgDailyAllTime;
        _allTransactions = allTransactions;
        _accountNameMap = accMap;
        _budgetProgresses = progresses;
        _computePeriodStats();
      });
    } catch (e) {
      LoggerService.e('ERROR loading reports data: $e');
      rethrow;
    }
  }

  SpendingSummary? get _selectedSummary {
    switch (_selectedPeriod) {
      case 'current_month':
        return _currentMonthSummary;
      case 'current_year':
        return _currentYearSummary;
      case 'all_time':
        return _allTimeSummary;
      default:
        return _currentMonthSummary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ReportService reportService = widget.reportService ?? ReportService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Statistics'),
        actions: [
          IconButton(
            tooltip: 'Export report',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final opts = await showDialog<ReportOptions>(
                context: context,
                builder: (context) => const ReportCustomizationModal(),
              );
              if (opts == null) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating PDF...')),
              );
              try {
                final bytes = await reportService.generateReportPdf(
                  opts,
                  currency: _currency,
                );
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'ledger_report.pdf',
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate report: $e')),
                );
              }
            },
          ),
        ],
      ),
      drawer: const CustomAppDrawer(),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: CustomColors.negative,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadFuture = _loadData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadFuture = _loadData();
              });
              await _loadFuture;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period selector
                  _buildPeriodSelector(isDark),
                  const SizedBox(height: 20),

                  // Overview cards
                  _buildOverviewCards(isDark),
                  const SizedBox(height: 24),

                  // Monthly trend (Weekly Spending)
                  _buildMonthlyTrend(isDark),
                  const SizedBox(height: 16),

                  // Daily heatmap (only for 'This Month')
                  if (_selectedPeriod == 'current_month') ...[
                    _buildDailyHeatmap(isDark),
                    const SizedBox(height: 24),
                  ],

                  // Top categories
                  _buildTopCategories(isDark),
                  const SizedBox(height: 16),

                  // Top transactions (incomes & expenses for the selected period)
                  _buildTopTransactions(isDark),
                  const SizedBox(height: 24),

                  // Budgets & Tag stats (per selected period)
                  _buildBudgetTagStats(isDark),
                  const SizedBox(height: 24),

                  // Additional insights
                  _buildInsights(isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return PeriodSelector(
      selectedPeriod: _selectedPeriod,
      onPeriodChanged: (value) {
        setState(() {
          _selectedPeriod = value;
        });
        _computePeriodStats();
      },
      periods: const [
        PeriodOption(label: 'This Month', value: 'current_month'),
        PeriodOption(label: 'This Year', value: 'current_year'),
        PeriodOption(label: 'All Time', value: 'all_time'),
      ],
    );
  }

  Widget _buildOverviewCards(bool isDark) {
    final summary = _selectedSummary;
    if (summary == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Loading data...'),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Income',
                CurrencyFormatter.format(summary.totalIncome, _currency),
                Icons.trending_up,
                CustomColors.positive,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Expense',
                CurrencyFormatter.format(summary.totalExpense, _currency),
                Icons.trending_down,
                CustomColors.red400,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Net Balance',
                CurrencyFormatter.format(summary.netBalance, _currency),
                Icons.account_balance_wallet,
                summary.netBalance >= 0
                    ? CustomColors.positive
                    : CustomColors.negative,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Transactions',
                summary.transactionCount.toString(),
                Icons.receipt_long,
                Colors.blue,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return ReportStatCard(title: title, value: value, icon: icon, color: color);
  }

  Widget _buildTopCategories(bool isDark) {
    final summary = _selectedSummary;
    if (summary == null || summary.topCategories.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: isDark
                      ? CustomColors.lightGreen
                      : Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Top Spending Categories',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No category data available',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                color: isDark
                    ? CustomColors.lightGreen
                    : Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Top Spending Categories',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...summary.topCategories.take(5).map((category) {
            // Check if this is the uncategorised category
            final isUncategorised = category.categoryName == 'Uncategorised';
            final categoryColor = isUncategorised
                ? (isDark ? Colors.grey[600] : Colors.grey[500])
                : Theme.of(context).primaryColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          category.categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isUncategorised
                                ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(category.amount, _currency),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isUncategorised
                              ? (isDark ? Colors.grey[400] : Colors.grey[600])
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: category.percentage / 100,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              categoryColor!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${category.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.transactionCount} ${category.transactionCount == 1 ? 'transaction' : 'transactions'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend(bool isDark) {
    // Select data based on period
    List<MonthlyStats>? statsToShow;
    String chartTitle;

    switch (_selectedPeriod) {
      case 'current_month':
        // For current month, show weekly spending trend
        statsToShow = _weeklyStatsCurrentMonth;
        chartTitle = 'Weekly Spending (This Month)';
        break;
      case 'current_year':
        // For current year, show monthly spending trend
        statsToShow = _monthlyStatsThisYear;
        chartTitle = 'Monthly Spending (This Year)';
        break;
      case 'all_time':
        // For all time, show yearly spending trend (last 5 years)
        statsToShow = _monthlyStatsAllTime;
        chartTitle = 'Yearly Spending (Last 5 Years)';
        break;
      default:
        statsToShow = _weeklyStatsCurrentMonth;
        chartTitle = 'Weekly Spending (This Month)';
    }

    if (statsToShow == null || statsToShow.isEmpty) {
      // Show a message instead of hiding completely
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: isDark
                      ? CustomColors.lightGreen
                      : Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chartTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No data available for this period',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Find max value for scaling
    final maxValue = statsToShow.fold<double>(
      0,
      (max, stat) => stat.expense > max ? stat.expense : max,
    );

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: isDark
                    ? CustomColors.lightGreen
                    : Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chartTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: statsToShow.reversed.map((stat) {
                final height = maxValue > 0
                    ? (stat.expense / maxValue) * 140
                    : 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (stat.expense > 0)
                          Flexible(
                            child: Text(
                              CurrencyFormatter.format(stat.expense, _currency),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          width: double.infinity,
                          height: height.clamp(8.0, 140.0).toDouble(),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isDark
                                  ? [
                                      CustomColors.lightGreen,
                                      CustomColors.lightGreen.withAlpha(153),
                                    ]
                                  : [
                                      Theme.of(context).primaryColor,
                                      Theme.of(
                                        context,
                                      ).primaryColor.withAlpha(153),
                                    ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.month,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _computePeriodStats() {
    if (_allTransactions == null) return;

    DateTime? startDate;
    DateTime? endDate;
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'current_month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'current_year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'all_time':
        startDate = null;
        endDate = null;
        break;
    }

    final filtered = _allTransactions!.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    // Top incomes and expenses for the selected period (top 3 each)
    final incomes =
        filtered.where((t) => t.type == TransactionType.income).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    final expenses =
        filtered.where((t) => t.type == TransactionType.expense).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final topIncomes = incomes.take(3).toList();
    final topExpenses = expenses.take(3).toList();

    // Compute tag stats (expense tags only)
    final tagMap = <String, _TagStat>{};
    for (final t in filtered) {
      if (t.type != TransactionType.expense) continue;
      for (final tag in t.tagNames) {
        final existing = tagMap[tag];
        if (existing == null) {
          tagMap[tag] = _TagStat(name: tag, count: 1, amount: t.amount);
        } else {
          tagMap[tag] = _TagStat(
            name: tag,
            count: existing.count + 1,
            amount: existing.amount + t.amount,
          );
        }
      }
    }

    final tagList = tagMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    Transaction? topTx;
    if (tagList.isNotEmpty) {
      final topTag = tagList.first.name;
      final txsWithTopTag = filtered
          .where(
            (t) =>
                t.tagNames.contains(topTag) &&
                t.type == TransactionType.expense,
          )
          .toList();
      if (txsWithTopTag.isNotEmpty) {
        txsWithTopTag.sort((a, b) => b.amount.compareTo(a.amount));
        topTx = txsWithTopTag.first;
      }
    }

    // Determine budgets that intersect this period and corresponding progresses
    final bp = <BudgetProgress>[];
    if (_budgetProgresses != null) {
      for (final p in _budgetProgresses!) {
        final b = p.budget;
        if (startDate != null &&
            b.endDate != null &&
            b.endDate!.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && b.startDate.isAfter(endDate)) continue;
        bp.add(p);
      }
      bp.sort((a, b) => b.percent.compareTo(a.percent));
    }

    setState(() {
      _transactionsForPeriod = filtered;
      _topIncomes = topIncomes;
      _topExpenses = topExpenses;
      _topTagStats = tagList;
      _topTransactionForTopTag = topTx;
      _budgetProgresses = bp;
    });
  }

  Widget _buildTopTransactions(bool isDark) {
    final incomes = _topIncomes ?? [];
    final expenses = _topExpenses ?? [];

    if (incomes.isEmpty && expenses.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: isDark
                    ? CustomColors.lightGreen
                    : Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Top Transactions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top incomes (listed first)
              Text(
                'Top Incomes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              if (incomes.isEmpty)
                Text(
                  'No incomes',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                )
              else
                ...incomes.map(
                  (t) => TransactionListItem(
                    transaction: t,
                    currency: _currency,
                    subtitle:
                        '${_accountNameMap[t.accountId] ?? 'Unknown'} • ${DateFormatter.formatWithKeyOrPattern(t.date, _dateFormatKey)}',
                  ),
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Top expenses (listed after incomes)
              Text(
                'Top Expenses',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              if (expenses.isEmpty)
                Text(
                  'No expenses',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                )
              else
                ...expenses.map(
                  (t) => TransactionListItem(
                    transaction: t,
                    currency: _currency,
                    subtitle:
                        '${_accountNameMap[t.accountId] ?? 'Unknown'} • ${DateFormatter.formatWithKeyOrPattern(t.date, _dateFormatKey)}',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressRow(BudgetProgress p) {
    return BudgetProgressRow(progress: p, currency: _currency);
  }

  Widget _buildDailyHeatmap(bool isDark) {
    final data = _dailySpendingCurrentMonth;
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = data.fold<double>(0, (m, v) => v > m ? v : m);
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: isDark
                    ? CustomColors.lightGreen
                    : Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Daily Spending (This Month)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: List.generate(data.length, (index) {
              final amount = data[index];
              final day = index + 1;
              final normalized = maxValue > 0 ? (amount / maxValue) : 0.0;
              final color = Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.12 + (normalized * 0.88));

              return Tooltip(
                message:
                    'Day $day: ${CurrencyFormatter.format(amount, _currency)}',
                child: Container(
                  decoration: BoxDecoration(
                    color: amount > 0
                        ? color
                        : (isDark ? Colors.grey[850] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? Colors.black12 : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[200] : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Budget & Tag Stats (NOT part of Key Insights)
  Widget _buildBudgetTagStats(bool isDark) {
    final txs = _transactionsForPeriod;
    final budgets = _budgetProgresses;
    final tags = _topTagStats;

    if ((txs == null || txs.isEmpty) && (budgets == null || budgets.isEmpty)) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: isDark
                      ? CustomColors.lightGreen
                      : Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Budgets & Tags',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No budget or tag data available for this period',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: isDark
                    ? CustomColors.lightGreen
                    : Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Budgets & Tags',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budgets
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budgets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (budgets != null && budgets.isNotEmpty) ...[
                    Text(
                      '${budgets.length} monitored budgets',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBudgetProgressRow(budgets.first),
                  ] else ...[
                    Text(
                      'No active budgets',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Tags
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Tags',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tags != null && tags.isNotEmpty) ...[
                    Text(
                      tags.first.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${tags.first.count} transactions • ${CurrencyFormatter.format(tags.first.amount, _currency)}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_topTransactionForTopTag != null)
                      Text(
                        'Top tx: ${_topTransactionForTopTag!.title} • ${CurrencyFormatter.format(_topTransactionForTopTag!.amount, _currency)}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                  ] else ...[
                    Text(
                      'No tags used',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(bool isDark) {
    final summary = _selectedSummary;
    if (summary == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Loading insights...'),
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Key Metrics',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction Count
          _buildInsightRow(
            'Total Transactions',
            '${summary.transactionCount}',
            Icons.receipt_long,
            isDark,
          ),
          const SizedBox(height: 12),

          // Total Spent
          _buildInsightRow(
            'Total Spent',
            CurrencyFormatter.format(summary.totalExpense, _currency),
            Icons.payment,
            isDark,
          ),
          const SizedBox(height: 12),

          // Total Income
          _buildInsightRow(
            'Total Income',
            CurrencyFormatter.format(summary.totalIncome, _currency),
            Icons.attach_money,
            isDark,
          ),
          const SizedBox(height: 12),

          // (Net Balance and Savings Rate removed per request)

          // Average Daily Spending
          if (_selectedPeriod == 'current_month' &&
              _averageDailySpendingMonth != null)
            _buildInsightRow(
              'Avg Daily Spending',
              CurrencyFormatter.format(_averageDailySpendingMonth!, _currency),
              Icons.today,
              isDark,
            ),
          if (_selectedPeriod == 'current_year' &&
              _averageDailySpendingYear != null)
            _buildInsightRow(
              'Avg Daily Spending',
              CurrencyFormatter.format(_averageDailySpendingYear!, _currency),
              Icons.today,
              isDark,
            ),
          if (_selectedPeriod == 'all_time' &&
              _averageDailySpendingAllTime != null)
            _buildInsightRow(
              'Avg Daily Spending',
              CurrencyFormatter.format(
                _averageDailySpendingAllTime!,
                _currency,
              ),
              Icons.today,
              isDark,
            ),
          if ((_selectedPeriod == 'current_month' &&
                  _averageDailySpendingMonth != null) ||
              (_selectedPeriod == 'current_year' &&
                  _averageDailySpendingYear != null) ||
              (_selectedPeriod == 'all_time' &&
                  _averageDailySpendingAllTime != null))
            const SizedBox(height: 12),

          // (Spending vs Previous Period removed per request)

          // Top Category insight
          _buildInsightRow(
            'Top Spending Category',
            summary.topCategories.isNotEmpty
                ? '${summary.topCategories.first.categoryName} (${summary.topCategories.first.percentage.toStringAsFixed(1)}%)'
                : 'No data',
            Icons.category,
            isDark,
          ),
          const SizedBox(height: 12),

          // Number of categories
          _buildInsightRow(
            'Active Categories',
            '${summary.topCategories.length}',
            Icons.dashboard,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CustomColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: CustomColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
