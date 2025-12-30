import 'package:ledger/models/category.dart';
import 'package:ledger/models/category_summary.dart';
import 'package:ledger/services/database/category_db_service.dart';
import 'package:ledger/services/data_refresh_service.dart';

abstract class AbstractCategoryService {
  Future<List<Category>> fetchCategoriesForUser(String userId);
  Future<Category?> getCategoryById(String categoryId);
  Future<List<CategorySummary>> getCategorySummaries(String userId);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String categoryId);
}

class CategoryService implements AbstractCategoryService {
  CategoryService._internal(this._dbService);

  static CategoryService? _instance;
  factory CategoryService({AbstractCategoryDBService? dbService}) {
    if (dbService != null) return CategoryService._internal(dbService);
    _instance ??= CategoryService._internal(CategoryDBService());
    return _instance!;
  }

  final AbstractCategoryDBService _dbService;

  @override
  Future<List<Category>> fetchCategoriesForUser(String userId) async {
    final rows = await _dbService.fetchAllByUserId(userId);
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  @override
  Future<Category?> getCategoryById(String categoryId) async {
    final row = await _dbService.getCategoryById(categoryId);
    if (row == null) return null;
    return Category.fromMap(row);
  }

  @override
  Future<List<CategorySummary>> getCategorySummaries(String userId) async {
    final rows = await _dbService.getCategorySummaries(userId);
    return rows.map((r) => CategorySummary.fromMap(r)).toList();
  }

  @override
  Future<void> createCategory(Category category) async {
    await _dbService.createCategory(category);
    DataRefreshService().notifyCategoriesChanged();
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _dbService.updateCategory(category);
    DataRefreshService().notifyCategoriesChanged();
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _dbService.delete(categoryId);
    DataRefreshService().notifyCategoriesChanged();
  }
}
