class CategorySummary {
  final String id;
  final String name;
  final String? description;
  final double totalAmount;
  final double incomeAmount;
  final double expenseAmount;
  final String currency;

  CategorySummary({
    required this.id,
    required this.name,
    this.description,
    required this.totalAmount,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.currency,
  });

  factory CategorySummary.fromMap(Map<String, dynamic> map) {
    return CategorySummary(
      id: map['category_id'] as String,
      name: map['category_name'] as String,
      description: map['category_description'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      incomeAmount: ((map['income_amount'] ?? 0) as num).toDouble(),
      expenseAmount: ((map['expense_amount'] ?? 0) as num).toDouble(),
      currency: map['currency'] as String,
    );
  }
}
