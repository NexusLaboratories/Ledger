import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/balance_service.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/services/transaction_tag_service.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/models/transaction_tag.dart';

class MockTransactionDBService extends Mock
    implements AbstractTransactionDBService {}

class MockAccountService extends Mock implements AccountService {}

class MockTransactionTagService extends Mock
    implements AbstractTransactionTagService {}

class MockTagService extends Mock implements AbstractTagService {}

void main() {
  group('TransactionService with mocks', () {
    late MockTransactionDBService mockTxDb;
    late MockAccountService mockAccountService;
    late TransactionService txService;
    late MockTransactionTagService mockTxTagService;
    late MockTagService mockTagService;

    setUpAll(() {
      registerFallbackValue(
        model_transaction.Transaction(
          title: 'f',
          amount: 1,
          accountId: 'a',
          date: DateTime.now(),
          type: model_transaction.TransactionType.income,
        ),
      );
      registerFallbackValue(Account(id: 'a', name: 'a'));
      registerFallbackValue(TransactionTag(transactionId: 't', tagId: 'tag'));
    });

    setUp(() {
      mockTxDb = MockTransactionDBService();
      mockAccountService = MockAccountService();
      mockTxTagService = MockTransactionTagService();
      mockTagService = MockTagService();
      txService = TransactionService(
        dbService: mockTxDb,
        balanceService: BalanceService(accountService: mockAccountService),
        txTagService: mockTxTagService,
        tagService: mockTagService,
      );

      when(() => mockTxDb.createTransaction(any())).thenAnswer((_) async {});
      when(() => mockTxDb.deleteTransaction(any())).thenAnswer((_) async {});
      when(
        () => mockTxDb.getTransactionById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockTxDb.fetchAllByAccountId(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockTxTagService.fetchTagsForTransaction(any()),
      ).thenAnswer((_) async => <TransactionTag>[]);
      when(
        () => mockTxTagService.createTransactionTag(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTxTagService.deleteTransactionTag(any(), any()),
      ).thenAnswer((_) async {});
    });

    test(
      'createTransaction calls DB create and updates account (income)',
      () async {
        final account = Account(id: 'acc1', name: 'Wallet', balance: 100.0);
        when(
          () => mockAccountService.fetchAccounts(
            forceRefetch: any(named: "forceRefetch"),
          ),
        ).thenAnswer((_) async => [account]);
        when(
          () => mockAccountService.updateAccount(any()),
        ).thenAnswer((_) async {});

        await txService.createTransaction(
          title: 'Salary',
          description: 'Monthly',
          amount: 50,
          accountId: 'acc1',
          date: DateTime.now(),
          type: model_transaction.TransactionType.income,
          categoryId: null,
        );

        // Verify createTransaction was called on the DB
        verify(() => mockTxDb.createTransaction(any())).called(1);

        // Verify account update called with increased balance
        final captured1 = verify(
          () => mockAccountService.updateAccount(captureAny()),
        ).captured;
        expect((captured1.first as Account).balance, equals(150.0));
      },
    );

    test(
      'deleteTransaction calls DB delete and updates account (income)',
      () async {
        final account = Account(id: 'acc1', name: 'Wallet', balance: 100.0);
        final tx = model_transaction.Transaction(
          id: 'tx1',
          title: 'Salary',
          description: 'Monthly',
          amount: 50,
          accountId: 'acc1',
          date: DateTime.now(),
          type: model_transaction.TransactionType.income,
        );

        when(
          () => mockTxDb.getTransactionById('tx1'),
        ).thenAnswer((_) async => tx.toMap());
        when(
          () => mockAccountService.fetchAccounts(
            forceRefetch: any(named: "forceRefetch"),
          ),
        ).thenAnswer((_) async => [account]);
        when(
          () => mockAccountService.updateAccount(any()),
        ).thenAnswer((_) async {});

        await txService.deleteTransaction('tx1');

        verify(() => mockTxDb.deleteTransaction('tx1')).called(1);
        final captured2 = verify(
          () => mockAccountService.updateAccount(captureAny()),
        ).captured;
        expect((captured2.first as Account).balance, equals(50.0));
      },
    );
  });
}
