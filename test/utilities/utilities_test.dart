import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/utilities/utilities.dart';
import 'package:ledger/models/transaction_item.dart';

void main() {
  group('Utilities', () {
    test('generateUuid should create a non-empty UUID', () {
      final uuid = Utilities.generateUuid();
      expect(uuid, isNotNull);
      expect(uuid, isA<String>());
      expect(uuid.length, greaterThan(0));

      final uuidReg = RegExp(
        r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
      );
      expect(uuidReg.hasMatch(uuid), isTrue);
    });

    test('calculateItemsTotal returns correct sum', () {
      final items = [
        TransactionItem(
          id: 'i1',
          transactionId: 't',
          name: 'A',
          quantity: 2,
          price: 3.5,
        ),
        TransactionItem(
          id: 'i2',
          transactionId: 't',
          name: 'B',
          quantity: 1,
          price: 2.0,
        ),
      ];

      final total = Utilities.calculateItemsTotal(items);
      expect(total, equals(2 * 3.5 + 1 * 2.0));
    });
  });
}
