import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/transaction_item.dart';

void main() {
  group('TransactionItem model', () {
    test('toMap and fromMap round trip', () {
      final item = TransactionItem(
        id: 'i1',
        transactionId: 'tx1',
        name: 'Item',
        quantity: 2.0,
        price: 5.5,
      );
      final map = item.toMap();
      final restored = TransactionItem.fromMap(map);

      expect(restored.id, equals('i1'));
      expect(restored.transactionId, equals('tx1'));
      expect(restored.name, equals('Item'));
      expect(restored.quantity, equals(2.0));
      expect(restored.price, equals(5.5));
    });

    test('handles null quantity and price', () {
      final item = TransactionItem(
        id: 'i2',
        transactionId: 'tx2',
        name: 'Item2',
      );
      final restored = TransactionItem.fromMap(item.toMap());

      expect(restored.quantity, isNull);
      expect(restored.price, isNull);
    });
  });
}
