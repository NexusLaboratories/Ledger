import 'package:ledger/models/tag.dart';
import 'package:ledger/services/database/core_db_service.dart';

abstract class AbstractTagDBService {
  Future<List<Map<String, dynamic>>> fetchAll();
  Future<List<Map<String, dynamic>>> fetchAllByUserId(String userId);
  Future<Map<String, dynamic>?> getTagById(String tagId);
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> delete(String tagId);
}

class TagDBService implements AbstractTagDBService {
  TagDBService._privateConstructor();
  static final TagDBService _instance = TagDBService._privateConstructor();
  factory TagDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();
  static const String _tableName = 'tags';
  bool _tableInitialized = false;

  Map<String, dynamic> _toMap(Tag tag) => tag.toMap();

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
  Future<Map<String, dynamic>?> getTagById(String tagId) async {
    await _ensureTableExists();
    final results = await _dbService.query(
      _tableName,
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<void> createTag(Tag tag) async {
    await _ensureTableExists();
    await _dbService.insert(_tableName, _toMap(tag));
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await _ensureTableExists();
    await _dbService.update(
      _tableName,
      _toMap(tag),
      where: 'tag_id = ?',
      whereArgs: [tag.id],
    );
  }

  @override
  Future<void> delete(String tagId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );
  }
}
