import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/account.dart';

void main() {
  group('Account model', () {
    test('should default balance to 0 and dates to now when missing', () {
      final account = Account(name: 'Test Account');
      expect(account.balance, equals(0.0));
      expect(account.createdAt, isA<DateTime>());
      expect(account.updatedAt, isA<DateTime>());
      expect(account.name, equals('Test Account'));
    });

    test('toJson and fromJson round trip', () {
      final account = Account(
        id: 'acc-1',
        name: 'Wallet',
        description: 'Main wallet',
        balance: 250.75,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1610000000000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1620000000000),
      );

      final json = account.toJson();
      final restored = Account.fromJson(json);

      expect(restored.id, equals('acc-1'));
      expect(restored.name, equals('Wallet'));
      expect(restored.description, equals('Main wallet'));
      expect(restored.balance, equals(250.75));
      expect(restored.createdAt.millisecondsSinceEpoch, equals(1610000000000));
      expect(restored.updatedAt.millisecondsSinceEpoch, equals(1620000000000));
    });

    test('copyWith correctly updates fields', () {
      final account = Account(name: 'Original', description: 'Desc');
      final updated = account.copyWith(name: 'New Name', balance: 100.0);

      expect(updated.id, equals(account.id));
      expect(updated.name, equals('New Name'));
      expect(updated.description, equals('Desc'));
      expect(updated.balance, equals(100.0));
    });
  });
}
