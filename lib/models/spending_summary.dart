class SpendingSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> monthlyTrend;
  final List<CategorySpending> topCategories;
  final int transactionCount;

  SpendingSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.categoryBreakdown,
    required this.monthlyTrend,
    required this.topCategories,
    required this.transactionCount,
  });
}

class CategorySpending {
  final String categoryId;
  final String categoryName;
  final double amount;
  final int transactionCount;
  final double percentage;

  CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.transactionCount,
    required this.percentage,
  });
}

class MonthlyStats {
  final String month;
  final int year;
  final double income;
  final double expense;
  final double net;
  final int transactionCount;

  MonthlyStats({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.net,
    required this.transactionCount,
  });
}
