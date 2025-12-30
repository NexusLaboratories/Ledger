import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/category.dart';

void main() {
  group('Category model', () {
    test('toMap and fromMap round trip', () {
      final category = Category(id: 'c1', name: 'Food', description: 'Food');
      final map = category.toMap();
      final restored = Category.fromMap(map);

      expect(restored.id, equals('c1'));
      expect(restored.name, equals('Food'));
      expect(restored.description, equals('Food'));
    });

    test('handles nulls and parentCategory', () {
      final category = Category(id: 'c2', name: 'Misc');
      final map = category.toMap();
      final restored = Category.fromMap(map);

      expect(restored.parentCategoryId, isNull);
      expect(restored.userId, isNull);
    });
  });
}
