import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/transaction_tag.dart';

void main() {
  group('TransactionTag model', () {
    test('toMap and fromMap round trip', () {
      final tag = TransactionTag(transactionId: 'tx1', tagId: 't1');
      final map = tag.toMap();
      final restored = TransactionTag.fromMap(map);

      expect(restored.transactionId, equals('tx1'));
      expect(restored.tagId, equals('t1'));
    });
  });
}
