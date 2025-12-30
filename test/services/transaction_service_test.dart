import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/models/transaction.dart' as model_transaction;
import 'package:ledger/models/account.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/balance_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/transaction_tag_service.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/models/transaction_tag.dart';
import '../test_helpers/mock_helpers.dart';

class FakeTransactionDBService implements AbstractTransactionDBService {
  final List<Map<String, dynamic>> _data = [];

  @override
  Future<void> createTransaction(
    model_transaction.Transaction transaction,
  ) async {
    _data.add(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    _data.removeWhere((m) => m['transaction_id'] == transactionId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => _data;

  @override
  Future<List<Map<String, dynamic>>> fetchAllByAccountId(
    String accountId,
  ) async => _data.where((m) => m['account_id'] == accountId).toList();

  @override
  Future<List<Map<String, dynamic>>> fetchFiltered({
    model_transaction.TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    return _data.where((m) {
      if (type != null && m['transaction_type'] != type.name) {
        return false;
      }
      if (startDate != null &&
          (m['transaction_date'] as int) < startDate.millisecondsSinceEpoch) {
        return false;
      }
      if (endDate != null &&
          (m['transaction_date'] as int) > endDate.millisecondsSinceEpoch) {
        return false;
      }
      if (categoryId != null && m['category_id'] != categoryId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getTransactionById(String transactionId) async {
    for (final m in _data) {
      if (m['transaction_id'] == transactionId) return m;
    }
    return null;
  }

  @override
  Future<void> updateTransaction(
    model_transaction.Transaction transaction,
  ) async {
    final idx = _data.indexWhere((m) => m['transaction_id'] == transaction.id);
    if (idx != -1) {
      _data[idx] = transaction.toMap();
    }
  }
}

class FakeAccountDBService implements AbstractAccountDBService {
  final List<Map<String, dynamic>> _data = [];

  @override
  Future<void> createAccount(Account account) async {
    _data.add(account.toJson());
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => _data;

  @override
  Future<void> delete(String accountId) async {
    _data.removeWhere((m) => m['account_id'] == accountId);
  }

  @override
  Future<void> update(Account account) async {
    final idx = _data.indexWhere((m) => m['account_id'] == account.id);
    if (idx != -1) {
      _data[idx] = account.toJson();
    }
  }

  // _createTable and _ensureTableExists are not part of AbstractAccountDBService
  // and are not required for this fake - remove them to avoid analyzer warnings.
}

class MockTransactionTagService extends Mock
    implements AbstractTransactionTagService {}

class MockTagService extends Mock implements AbstractTagService {}

void main() {
  setUpAll(() {
    registerCommonFallbacks();
  });

  group('TransactionService (with fake DBs)', () {
    late FakeTransactionDBService txDB;
    late FakeAccountDBService accDB;
    late AccountService accountService;
    late TransactionService txService;
    late MockTransactionTagService mockTxTagService;
    late MockTagService mockTagService;

    setUp(() async {
      txDB = FakeTransactionDBService();
      accDB = FakeAccountDBService();
      accountService = AccountService(accountDBService: accDB);
      // Provide mock tag services to avoid DB open by default services
      mockTxTagService = MockTransactionTagService();
      mockTagService = MockTagService();
      // setup default behavior for tag services used by TransactionService
      when(
        () => mockTxTagService.fetchTagsForTransaction(any()),
      ).thenAnswer((_) async => <TransactionTag>[]);
      when(
        () => mockTxTagService.createTransactionTag(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTxTagService.deleteTransactionTag(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockTagService.getTagById(any()),
      ).thenAnswer((_) async => null);
      txService = TransactionService(
        dbService: txDB,
        balanceService: BalanceService(accountService: accountService),
        txTagService: mockTxTagService,
        tagService: mockTagService,
      );
      // Create an account
      await accountService.createAccount('Wallet', null);
      final accounts = await accountService.fetchAccounts(forceRefetch: true);
      await accountService.updateAccount(
        accounts.first!.copyWith(balance: 100.0),
      );
    });

    test('createTransaction updates account balance for income', () async {
      final accounts = await accountService.fetchAccounts(forceRefetch: true);
      final acc = accounts.first!;
      await txService.createTransaction(
        title: 'Salary',
        description: 'Monthly',
        amount: 50.0,
        accountId: acc.id,
        date: DateTime.now(),
        type: model_transaction.TransactionType.income,
        categoryId: 'c1',
      );

      expect(txDB._data.length, equals(1));
      expect(txDB._data.first['category_id'], equals('c1'));
      final updatedAccounts = await accountService.fetchAccounts(
        forceRefetch: true,
      );
      expect(updatedAccounts.first!.balance, equals(150.0));
    });

    test('deleteTransaction removes transaction and updates balance', () async {
      final accounts = await accountService.fetchAccounts(forceRefetch: true);
      final acc = accounts.first!;
      await txService.createTransaction(
        title: 'Salary',
        description: 'Monthly',
        amount: 50.0,
        accountId: acc.id,
        date: DateTime.now(),
        type: model_transaction.TransactionType.income,
        categoryId: null,
      );
      final txId = txDB._data.first['transaction_id'] as String;

      await txService.deleteTransaction(txId);
      expect(txDB._data.length, equals(0));
      final updatedAccounts = await accountService.fetchAccounts(
        forceRefetch: true,
      );
      expect(updatedAccounts.first!.balance, equals(100.0));
    });

    test(
      'updateTransaction adjusts account balance when amount changes',
      () async {
        final accounts = await accountService.fetchAccounts(forceRefetch: true);
        final acc = accounts.first!;
        // Create an expense of 12 -> balance should be 88
        await txService.createTransaction(
          title: 'Buy',
          description: null,
          amount: 12.0,
          accountId: acc.id,
          date: DateTime.now(),
          type: model_transaction.TransactionType.expense,
          categoryId: null,
        );
        expect(txDB._data.length, equals(1));
        var updatedAccounts = await accountService.fetchAccounts(
          forceRefetch: true,
        );
        expect(updatedAccounts.first!.balance, equals(88.0));

        // Update transaction to 13 -> balance should become 87
        final txMap = txDB._data.first;
        final tx = model_transaction.Transaction.fromMap(txMap);
        final updated = tx.copyWith(amount: 13.0);
        await txService.updateTransaction(updated);

        updatedAccounts = await accountService.fetchAccounts(
          forceRefetch: true,
        );
        expect(updatedAccounts.first!.balance, equals(87.0));
      },
    );
  });
}
