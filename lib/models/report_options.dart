class ReportOptions {
  final String
  period; // 'current_month' | 'current_year' | 'all_time' | 'custom'
  final bool includeOverview;
  final bool includeTopCategories;
  final bool includeBudgets;
  final bool includeTransactions;
  final int maxTransactions;
  final List<String> accountIds; // Empty list means all accounts
  final List<String> categoryIds; // Categories to include/exclude
  final bool
  categoryIncludeMode; // true = include only these, false = exclude these
  final List<String> tagIds; // Tags to include/exclude
  final bool tagIncludeMode; // true = include only these, false = exclude these
  final DateTime? customStartDate; // For custom date range
  final DateTime? customEndDate; // For custom date range

  const ReportOptions({
    this.period = 'current_month',
    this.includeOverview = true,
    this.includeTopCategories = true,
    this.includeBudgets = false,
    this.includeTransactions = true,
    this.maxTransactions = 50,
    this.accountIds = const [],
    this.categoryIds = const [],
    this.categoryIncludeMode = false,
    this.tagIds = const [],
    this.tagIncludeMode = false,
    this.customStartDate,
    this.customEndDate,
  });

  ReportOptions copyWith({
    String? period,
    bool? includeOverview,
    bool? includeTopCategories,
    bool? includeBudgets,
    bool? includeTransactions,
    int? maxTransactions,
    List<String>? accountIds,
    List<String>? categoryIds,
    bool? categoryIncludeMode,
    List<String>? tagIds,
    bool? tagIncludeMode,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return ReportOptions(
      period: period ?? this.period,
      includeOverview: includeOverview ?? this.includeOverview,
      includeTopCategories: includeTopCategories ?? this.includeTopCategories,
      includeBudgets: includeBudgets ?? this.includeBudgets,
      includeTransactions: includeTransactions ?? this.includeTransactions,
      maxTransactions: maxTransactions ?? this.maxTransactions,
      accountIds: accountIds ?? this.accountIds,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryIncludeMode: categoryIncludeMode ?? this.categoryIncludeMode,
      tagIds: tagIds ?? this.tagIds,
      tagIncludeMode: tagIncludeMode ?? this.tagIncludeMode,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}
