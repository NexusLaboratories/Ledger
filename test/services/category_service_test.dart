import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/models/category.dart';
import 'package:ledger/services/database/category_db_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockCategoryDBService extends Mock implements AbstractCategoryDBService {}

class FakeCategoryDBService implements AbstractCategoryDBService {
  final List<Map<String, dynamic>> _data = [];

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => _data;

  @override
  Future<void> createCategory(Category category) async {
    _data.add(category.toMap());
  }

  @override
  Future<void> delete(String categoryId) async {
    _data.removeWhere((m) => m['category_id'] == categoryId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllByUserId(String userId) async =>
      _data;

  @override
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    for (final m in _data) {
      if (m['category_id'] == categoryId) return m;
    }
    return null;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final idx = _data.indexWhere((m) => m['category_id'] == category.id);
    if (idx != -1) _data[idx] = category.toMap();
  }

  @override
  Future<List<Map<String, dynamic>>> getCategorySummaries(String userId) async {
    return [];
  }
}

void main() {
  group('CategoryService with mock db', () {
    late MockCategoryDBService mockDb;
    late CategoryService service;

    setUpAll(() {
      registerCommonFallbacks();
    });

    setUp(() {
      mockDb = MockCategoryDBService();
      service = CategoryService(dbService: mockDb);

      when(() => mockDb.fetchAllByUserId(any())).thenAnswer((_) async => []);
      when(() => mockDb.createCategory(any())).thenAnswer((_) async {});
      when(() => mockDb.updateCategory(any())).thenAnswer((_) async {});
      when(() => mockDb.delete(any())).thenAnswer((_) async {});
      when(() => mockDb.getCategoryById(any())).thenAnswer((_) async => null);
      when(
        () => mockDb.getCategorySummaries(any()),
      ).thenAnswer((_) async => []);
    });

    test('create fetch update delete category', () async {
      final category = Category(id: 'c1', name: 'Food');
      await service.createCategory(category);
      var categories = await service.fetchCategoriesForUser('local');
      verify(() => mockDb.createCategory(any())).called(1);

      expect(categories.length, 0);

      final updated = Category(id: 'c1', name: 'Groceries');
      await service.updateCategory(updated);
      verify(() => mockDb.updateCategory(any())).called(1);

      final fetched = await service.getCategoryById('c1');
      expect(fetched, isNull);

      await service.deleteCategory('c1');
      verify(() => mockDb.delete('c1')).called(1);
    });
  });

  group('CategoryService with fake db', () {
    late FakeCategoryDBService fakeDb;
    late CategoryService service;

    setUp(() {
      fakeDb = FakeCategoryDBService();
      service = CategoryService(dbService: fakeDb);
    });

    test('create fetch update delete category', () async {
      final category = Category(id: 'c1', name: 'Food');
      await service.createCategory(category);
      var categories = await service.fetchCategoriesForUser('local');
      expect(categories.length, 1);
      expect(categories.first.name, 'Food');

      final updated = Category(id: 'c1', name: 'Groceries');
      await service.updateCategory(updated);
      final fetched = await service.getCategoryById('c1');
      expect(fetched!.name, 'Groceries');

      await service.deleteCategory('c1');
      categories = await service.fetchCategoriesForUser('local');
      expect(categories.length, 0);
    });
  });
}
