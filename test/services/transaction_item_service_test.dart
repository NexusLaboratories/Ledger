import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/services/transaction_item_service.dart';
import 'package:ledger/models/transaction_item.dart';
import 'package:ledger/services/database/transaction_item_db_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockTransactionItemDBService extends Mock
    implements AbstractTransactionItemDBService {}

void main() {
  group('TransactionItemService with mock db', () {
    late MockTransactionItemDBService mockDb;
    late TransactionItemService service;

    setUpAll(() {
      registerCommonFallbacks();
    });

    setUp(() {
      mockDb = MockTransactionItemDBService();
      service = TransactionItemService(dbService: mockDb);

      when(
        () => mockDb.fetchAllByTransactionId(any()),
      ).thenAnswer((_) async => []);
      when(() => mockDb.createItem(any())).thenAnswer((_) async {});
      when(() => mockDb.updateItem(any())).thenAnswer((_) async {});
      when(() => mockDb.delete(any())).thenAnswer((_) async {});
      when(() => mockDb.getItemById(any())).thenAnswer((_) async => null);
    });

    test('create fetch update delete item', () async {
      final item = TransactionItem(id: 'i1', transactionId: 't1', name: 'Item');
      await service.createItem(item);
      var items = await service.fetchItemsForTransaction('t1');
      verify(() => mockDb.createItem(any())).called(1);

      expect(items.length, 0); // default mock returns empty

      final updated = TransactionItem(
        id: 'i1',
        transactionId: 't1',
        name: 'Updated',
      );
      await service.updateItem(updated);
      verify(() => mockDb.updateItem(any())).called(1);

      final fetched = await service.getItemById('i1');
      expect(fetched, isNull);

      await service.deleteItem('i1');
      verify(() => mockDb.delete('i1')).called(1);
    });
  });
}
