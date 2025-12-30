import 'package:uuid/uuid.dart';
import '../utilities/datetime_extension.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final List<String> tagIds;
  final List<String> tagNames;
  final double amount;
  final String accountId;
  final DateTime date;
  final TransactionType type;

  Transaction({
    String? id,
    required this.title,
    this.description,
    this.categoryId,
    List<String>? tagIds,
    List<String>? tagNames,
    required this.amount,
    required this.accountId,
    required this.date,
    required this.type,
  }) : id = id ?? const Uuid().v4(),
       tagIds = tagIds ?? const [],
       tagNames = tagNames ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': id,
      'transaction_title': title,
      'transaction_note': description,
      'category_id': categoryId,
      'amount': amount,
      'account_id': accountId,
      'date': date.toMillisecondsSinceEpoch(),
      'type': type.index,
    };
  }

  factory Transaction.fromMap(
    Map<String, dynamic> map, {
    List<String>? tagIds,
    List<String>? tagNames,
  }) {
    final String? titleFromDb = map['transaction_title'] as String?;
    final String? descriptionFromDb = map['transaction_note'] as String?;
    final String titleValue =
        titleFromDb ?? descriptionFromDb ?? 'Untitled Transaction';
    return Transaction(
      id: map['transaction_id'] as String?,
      title: titleValue,
      description: descriptionFromDb,
      categoryId: map['category_id'] as String?,
      tagIds: tagIds,
      tagNames: tagNames,
      amount: map['amount'],
      accountId: map['account_id'],
      date: DateTimeExtension.fromMillisecondsSinceEpoch(map['date'])!,
      type: TransactionType.values[map['type']],
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    List<String>? tagIds,
    List<String>? tagNames,
    double? amount,
    String? accountId,
    DateTime? date,
    TransactionType? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      tagIds: tagIds ?? this.tagIds,
      tagNames: tagNames ?? this.tagNames,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }
}
