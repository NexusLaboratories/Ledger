import 'package:ledger/models/category.dart';
import 'package:ledger/services/database/core_db_service.dart';

abstract class AbstractCategoryDBService {
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<List<Map<String, dynamic>>> fetchAllByUserId(String userId);
  Future<Map<String, dynamic>?> getCategoryById(String categoryId);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> delete(String categoryId);
  Future<List<Map<String, dynamic>>> getCategorySummaries(String userId);
}

class CategoryDBService implements AbstractCategoryDBService {
  CategoryDBService._privateConstructor();
  static final CategoryDBService _instance =
      CategoryDBService._privateConstructor();
  factory CategoryDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'categories';
  bool _tableInitialized = false;

  Map<String, dynamic> _toMap(Category category) => category.toMap();

  Future<void> _createTable() async {}
  Future<void> _ensureTableExists() async {
    if (_tableInitialized) return;
    await _dbService.openDB();
    await _createTable();
    _tableInitialized = true;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await _ensureTableExists();
    return await _dbService.query(_tableName);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllByUserId(String userId) async {
    await _ensureTableExists();
    return await _dbService.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    await _ensureTableExists();
    final results = await _dbService.query(
      _tableName,
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<void> createCategory(Category category) async {
    await _ensureTableExists();
    await _dbService.insert(_tableName, _toMap(category));
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _ensureTableExists();
    await _dbService.update(
      _tableName,
      _toMap(category),
      where: 'category_id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> delete(String categoryId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCategorySummaries(String userId) async {
    await _ensureTableExists();
    final String sql = """
      WITH RECURSIVE category_descendants(category_id, descendant_id) AS (
        SELECT category_id, category_id FROM categories
        UNION ALL
        SELECT cd.category_id, c.category_id
        FROM categories c, category_descendants cd
        WHERE c.parent_category_id = cd.descendant_id
      )
      SELECT
        cd.category_id,
        cat.category_name,
        cat.category_description,
        SUM(CASE WHEN t.type = 1 THEN t.amount ELSE 0 END) as expense_amount,
        SUM(CASE WHEN t.type = 0 THEN t.amount ELSE 0 END) as income_amount,
        SUM(CASE WHEN t.type = 1 THEN t.amount ELSE 0 END) as total_amount,
        a.currency
      FROM
        category_descendants cd
      JOIN
        transactions t ON t.category_id = cd.descendant_id AND t.type = 1
      JOIN
        accounts a ON t.account_id = a.account_id
      JOIN
        categories cat ON cat.category_id = cd.category_id
      WHERE
        cat.user_id = ?
      GROUP BY
        cd.category_id, cat.category_name, cat.category_description, a.currency
    """;
    return await _dbService.rawQuery(sql, [userId]);
  }
}
