import '../utilities/utilities.dart';
import '../utilities/datetime_extension.dart';

class Account {
  final String id;
  final String? userId;
  final String name;
  final String currency;
  final String? description;
  final double balance;
  final String? iconId;
  final DateTime? latestTransaction;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    String? id,
    this.userId,
    required this.name,
    String? currency,
    this.description,
    double? balance,
    this.iconId,
    this.latestTransaction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = (id ?? Utilities.generateUuid()),
       currency = (currency ?? 'USD'),
       balance = (balance ?? 0.0),
       createdAt = (createdAt ?? DateTime.now()),
       updatedAt = (updatedAt ?? DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'account_id': id,
      'user_id': userId,
      'account_name': name,
      'currency': currency,
      'account_description': description,
      'balance': balance,
      'account_icon': iconId,
      'created_at': createdAt.toMillisecondsSinceEpoch(),
      'updated_at': updatedAt.toMillisecondsSinceEpoch(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['account_id'] as String?,
      userId: json['user_id'] as String?,
      name: json['account_name'] as String,
      currency: json['currency'] as String?,
      description: json['account_description'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      iconId: json['account_icon'] as String?,
      createdAt: DateTimeExtension.fromMillisecondsSinceEpoch(
        json['created_at'] as int?,
      ),
      updatedAt: DateTimeExtension.fromMillisecondsSinceEpoch(
        json['updated_at'] as int?,
      ),
    );
  }

  Account copyWith({
    String? id,
    String? name,
    String? currency,
    String? description,
    double? balance,
    String? iconId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      iconId: iconId ?? this.iconId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
