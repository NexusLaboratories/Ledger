import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/services/transaction_tag_service.dart';
import 'package:ledger/models/transaction_tag.dart';
import 'package:ledger/services/database/transaction_tag_db_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockTransactionTagDBService extends Mock
    implements AbstractTransactionTagDBService {}

void main() {
  group('TransactionTagService with mock db', () {
    late MockTransactionTagDBService mockDb;
    late TransactionTagService service;

    setUpAll(() {
      registerCommonFallbacks();
    });

    setUp(() {
      mockDb = MockTransactionTagDBService();
      service = TransactionTagService(dbService: mockDb);

      when(
        () => mockDb.fetchAllByTransactionId(any()),
      ).thenAnswer((_) async => []);
      when(() => mockDb.createTransactionTag(any())).thenAnswer((_) async {});
      when(
        () => mockDb.deleteTransactionTag(any(), any()),
      ).thenAnswer((_) async {});
    });

    test('create fetch delete tag mapping', () async {
      final tag = TransactionTag(transactionId: 't1', tagId: 'tg1');
      await service.createTransactionTag(tag);
      var mappings = await service.fetchTagsForTransaction('t1');
      verify(() => mockDb.createTransactionTag(any())).called(1);
      expect(mappings.length, 0);

      await service.deleteTransactionTag('t1', 'tg1');
      verify(() => mockDb.deleteTransactionTag('t1', 'tg1')).called(1);
    });
  });
}
