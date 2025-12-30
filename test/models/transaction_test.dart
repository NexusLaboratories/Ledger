import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/transaction.dart';

void main() {
  group('Transaction model', () {
    test('toMap and fromMap rounds trip', () {
      final tx = Transaction(
        title: 'Salary',
        description: 'Monthly salary',
        amount: 1000.5,
        accountId: 'acc1',
        date: DateTime.fromMillisecondsSinceEpoch(1632163200000),
        type: TransactionType.income,
      );

      final map = tx.toMap();
      final restored = Transaction.fromMap(map);

      expect(restored.title, equals('Salary'));
      expect(restored.description, equals('Monthly salary'));
      expect(restored.amount, equals(1000.5));
      expect(restored.accountId, equals('acc1'));
      expect(restored.type, equals(TransactionType.income));
      expect(restored.date.millisecondsSinceEpoch, equals(1632163200000));
    });

    test('fromMap uses fallback title when transaction_title is null', () {
      final map = {
        'transaction_id': '1',
        'transaction_title': null,
        'transaction_note': 'Only note',
        'amount': 10.0,
        'account_id': 'acc',
        'date': DateTime.now().millisecondsSinceEpoch,
        'type': TransactionType.expense.index,
      };

      final tx = Transaction.fromMap(map);
      // title fallback to description
      expect(tx.title, equals('Only note'));
    });

    test(
      'fromMap fallback to Untitled Transaction when title AND description are null',
      () {
        final map = {
          'transaction_id': '1',
          'transaction_title': null,
          'transaction_note': null,
          'amount': 5.5,
          'account_id': 'acc',
          'date': DateTime.now().millisecondsSinceEpoch,
          'type': TransactionType.expense.index,
        };

        final tx = Transaction.fromMap(map);
        expect(tx.title, equals('Untitled Transaction'));
      },
    );

    test('copyWith can set categoryId to null', () {
      final tx = Transaction(
        title: 'Groceries',
        categoryId: 'cat123',
        amount: 50.0,
        accountId: 'acc1',
        date: DateTime.now(),
        type: TransactionType.expense,
      );

      expect(tx.categoryId, equals('cat123'));

      // This should actually set categoryId to null, not keep the old value
      final updated = tx.copyWith(categoryId: null);

      expect(updated.categoryId, isNull);
    });

    test('copyWith can set description to null', () {
      final tx = Transaction(
        title: 'Test',
        description: 'Some description',
        amount: 100.0,
        accountId: 'acc1',
        date: DateTime.now(),
        type: TransactionType.income,
      );

      expect(tx.description, equals('Some description'));

      // This should actually set description to null, not keep the old value
      final updated = tx.copyWith(description: null);

      expect(updated.description, isNull);
    });
  });
}
