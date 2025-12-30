import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/database/account_db_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockAccountDBService extends Mock implements AbstractAccountDBService {}

void main() {
  group('AccountService (mockdb)', () {
    late MockAccountDBService mockDb;
    late AccountService service;

    setUpAll(() {
      registerCommonFallbacks();
    });

    setUp(() {
      mockDb = MockAccountDBService();
      service = AccountService(accountDBService: mockDb);

      when(() => mockDb.fetchAll()).thenAnswer((_) async => []);
      when(() => mockDb.createAccount(any())).thenAnswer((_) async {});
      when(() => mockDb.update(any())).thenAnswer((_) async {});
      when(() => mockDb.delete(any())).thenAnswer((_) async {});
    });

    test('createAccount calls DB and adds to in-memory list', () async {
      await service.createAccount('Checking', 'Main account');
      final accounts = await service.fetchAccounts();
      expect(accounts.length, equals(1));
      expect(accounts.first!.name, equals('Checking'));
      expect(accounts.first!.description, equals('Main account'));
      expect(accounts.first!.currency, equals('USD'));
      verify(() => mockDb.createAccount(any())).called(1);
    });

    test(
      'createAccount with specified currency stores currency on account',
      () async {
        await service.createAccount('Wallet', null, currency: 'INR');
        final accounts = await service.fetchAccounts();
        expect(accounts.any((acc) => acc!.currency == 'INR'), true);
      },
    );

    test('fetchNetWorth returns sum of balances', () async {
      await service.createAccount('A', null);
      await service.createAccount('B', null);
      var accounts = await service.fetchAccounts();

      final a = accounts[0]!;
      final b = accounts[1]!;

      await service.updateAccount(a.copyWith(balance: 100.0));
      await service.updateAccount(b.copyWith(balance: 50.0));

      final netWorth = await service.fetchNetWorth();
      expect(netWorth, equals(150.0));
      verify(() => mockDb.update(any())).called(2);
    });

    test('updateAccount updates currency successfully', () async {
      await service.createAccount('Savings', 'My savings');
      var accounts = await service.fetchAccounts();
      final a = accounts.first!;

      final updated = a.copyWith(currency: 'EUR');
      await service.updateAccount(updated);
      accounts = await service.fetchAccounts();
      expect(accounts.first!.currency, equals('EUR'));
    });
  });
}
