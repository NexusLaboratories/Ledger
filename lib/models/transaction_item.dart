class TransactionItem {
  final String id;
  final String transactionId;
  final String name;
  final double? quantity;
  final double? price;

  TransactionItem({
    required this.id,
    required this.transactionId,
    required this.name,
    this.quantity,
    this.price,
  });

  Map<String, dynamic> toMap() => {
    'item_id': id,
    'transaction_id': transactionId,
    'item_name': name,
    'quantity': quantity,
    'price': price,
  };

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['item_id'] as String,
      transactionId: map['transaction_id'] as String,
      name: map['item_name'] as String,
      quantity: (map['quantity'] as num?)?.toDouble(),
      price: (map['price'] as num?)?.toDouble(),
    );
  }
}
