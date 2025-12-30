class TransactionTag {
  final String transactionId;
  final String tagId;

  TransactionTag({required this.transactionId, required this.tagId});

  Map<String, dynamic> toMap() => {
    'transaction_id': transactionId,
    'tag_id': tagId,
  };

  factory TransactionTag.fromMap(Map<String, dynamic> map) {
    return TransactionTag(
      transactionId: map['transaction_id'] as String,
      tagId: map['tag_id'] as String,
    );
  }
}
