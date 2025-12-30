import 'package:ledger/models/tag.dart';
import 'package:ledger/services/database/tag_db_service.dart';

abstract class AbstractTagService {
  Future<List<Tag>> fetchTagsForUser(String userId);
  Future<Tag?> getTagById(String tagId);
  Future<void> createTag(Tag tag);
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String tagId);
}

class TagService implements AbstractTagService {
  TagService._internal(this._dbService);

  static TagService? _instance;
  factory TagService({AbstractTagDBService? dbService}) {
    if (dbService != null) return TagService._internal(dbService);
    _instance ??= TagService._internal(TagDBService());
    return _instance!;
  }

  final AbstractTagDBService _dbService;

  @override
  Future<List<Tag>> fetchTagsForUser(String userId) async {
    final rows = await _dbService.fetchAllByUserId(userId);
    return rows.map((r) => Tag.fromMap(r)).toList();
  }

  @override
  Future<Tag?> getTagById(String tagId) async {
    final row = await _dbService.getTagById(tagId);
    if (row == null) return null;
    return Tag.fromMap(row);
  }

  @override
  Future<void> createTag(Tag tag) async {
    await _dbService.createTag(tag);
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await _dbService.updateTag(tag);
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await _dbService.delete(tagId);
  }
}
