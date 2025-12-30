class SearchFilter {
  final String? query;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? accountId;
  final String? categoryId;
  final List<String>? tagIds;
  final int? transactionType; // 0 for income, 1 for expense

  const SearchFilter({
    this.query,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.accountId,
    this.categoryId,
    this.tagIds,
    this.transactionType,
  });

  SearchFilter copyWith({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? accountId,
    String? categoryId,
    List<String>? tagIds,
    int? transactionType,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      transactionType: transactionType ?? this.transactionType,
    );
  }

  bool get isEmpty =>
      query == null &&
      startDate == null &&
      endDate == null &&
      minAmount == null &&
      maxAmount == null &&
      accountId == null &&
      categoryId == null &&
      (tagIds == null || tagIds!.isEmpty) &&
      transactionType == null;

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'accountId': accountId,
      'categoryId': categoryId,
      'tagIds': tagIds,
      'transactionType': transactionType,
    };
  }
}
