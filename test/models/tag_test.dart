import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/models/tag.dart';

void main() {
  group('Tag model', () {
    test('toMap and fromMap round trip', () {
      final tag = Tag(id: 't1', name: 'Urgent', description: 'High priority');
      final map = tag.toMap();
      final restored = Tag.fromMap(map);

      expect(restored.id, equals('t1'));
      expect(restored.name, equals('Urgent'));
      expect(restored.description, equals('High priority'));
    });

    test('handles nulls and parentTag', () {
      final tag = Tag(id: 't2', name: 'Optional');
      final restored = Tag.fromMap(tag.toMap());

      expect(restored.parentTagId, isNull);
      expect(restored.userId, isNull);
      expect(restored.color, isNull);
      expect(restored.iconId, isNull);
    });

    test('toMap and fromMap with color and icon', () {
      final tag = Tag(
        id: 't3',
        name: 'Travel',
        description: 'Travel expenses',
        color: 0xFF1E88E5,
        iconId: 'flight',
      );
      final map = tag.toMap();
      final restored = Tag.fromMap(map);

      expect(restored.id, equals('t3'));
      expect(restored.name, equals('Travel'));
      expect(restored.description, equals('Travel expenses'));
      expect(restored.color, equals(0xFF1E88E5));
      expect(restored.iconId, equals('flight'));
    });
  });
}
