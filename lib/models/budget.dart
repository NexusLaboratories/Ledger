import 'package:uuid/uuid.dart';

enum BudgetPeriod { monthly, quarterly, yearly, custom }

class Budget {
  final String id;
  final String? userId;
  final String? categoryId; // null => overall budget
  final String name;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? iconId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    String? id,
    this.userId,
    this.categoryId,
    required this.name,
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.iconId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'budget_id': id,
    'user_id': userId,
    'category_id': categoryId,
    'budget_name': name,
    'amount': amount,
    'period': period.index,
    'start_date': startDate.millisecondsSinceEpoch,
    'end_date': endDate?.millisecondsSinceEpoch,
    'is_active': isActive ? 1 : 0,
    'budget_icon': iconId,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['budget_id'] as String?,
    userId: map['user_id'] as String?,
    categoryId: map['category_id'] as String?,
    name: map['budget_name'] as String,
    amount: (map['amount'] as num).toDouble(),
    period: BudgetPeriod.values[map['period'] as int],
    startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
    endDate: map['end_date'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
        : null,
    isActive: (map['is_active'] as int) == 1,
    iconId: map['budget_icon'] as String?,
    createdAt: map['created_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
        : DateTime.now(),
    updatedAt: map['updated_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
        : DateTime.now(),
  );

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? iconId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      iconId: iconId ?? this.iconId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
