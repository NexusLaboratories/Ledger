import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/budget.dart';

void main() {
  test('Budget toMap/fromMap round trip', () {
    final now = DateTime.now();
    final b1 = Budget(
      id: 'b1',
      name: 'Groceries',
      amount: 200.0,
      period: BudgetPeriod.monthly,
      startDate: now,
      categoryId: 'c1',
    );
    final map = b1.toMap();
    final b2 = Budget.fromMap(map);
    expect(b2.id, equals('b1'));
    expect(b2.name, equals('Groceries'));
    expect(b2.amount, equals(200.0));
    expect(b2.categoryId, equals('c1'));
  });
}
