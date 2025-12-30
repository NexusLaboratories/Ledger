import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/models/tag.dart';
import 'package:ledger/services/database/tag_db_service.dart';
import '../test_helpers/mock_helpers.dart';

class MockTagDBService extends Mock implements AbstractTagDBService {}

class FakeTagDBService implements AbstractTagDBService {
  final List<Map<String, dynamic>> _data = [];
  @override
  Future<List<Map<String, dynamic>>> fetchAll() async => _data;

  // _createTable and _ensureTableExists are not part of AbstractTagDBService
  // and are not required for this fake - remove them to avoid analyzer warnings.

  @override
  Future<void> createTag(Tag tag) async {
    _data.add(tag.toMap());
  }

  @override
  Future<void> delete(String tagId) async {
    _data.removeWhere((m) => m['tag_id'] == tagId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllByUserId(String userId) async =>
      _data;

  @override
  Future<Map<String, dynamic>?> getTagById(String tagId) async {
    for (final m in _data) {
      if (m['tag_id'] == tagId) return m;
    }
    return null;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final idx = _data.indexWhere((m) => m['tag_id'] == tag.id);
    if (idx != -1) _data[idx] = tag.toMap();
  }
}

void main() {
  group('TagService with mock db', () {
    late MockTagDBService mockDb;
    late TagService service;

    setUpAll(() {
      registerCommonFallbacks();
    });

    setUp(() {
      mockDb = MockTagDBService();
      service = TagService(dbService: mockDb);

      when(() => mockDb.fetchAllByUserId(any())).thenAnswer((_) async => []);
      when(() => mockDb.createTag(any())).thenAnswer((_) async {});
      when(() => mockDb.updateTag(any())).thenAnswer((_) async {});
      when(() => mockDb.delete(any())).thenAnswer((_) async {});
      when(() => mockDb.getTagById(any())).thenAnswer((_) async => null);
    });

    test('create fetch update delete tag', () async {
      final tag = Tag(id: 't1', name: 'Test');
      await service.createTag(tag);
      var tags = await service.fetchTagsForUser('local');
      verify(() => mockDb.createTag(any())).called(1);

      expect(tags.length, 0); // fetchAll returns empty by default

      final updated = Tag(id: 't1', name: 'Updated');
      await service.updateTag(updated);
      verify(() => mockDb.updateTag(any())).called(1);

      final fetched = await service.getTagById('t1');
      expect(fetched, isNull);

      await service.deleteTag('t1');
      verify(() => mockDb.delete('t1')).called(1);
    });
  });

  group('TagService with fake db', () {
    late FakeTagDBService fakeDb;
    late TagService service;

    setUp(() {
      fakeDb = FakeTagDBService();
      service = TagService(dbService: fakeDb);
    });

    test('create fetch update delete tag', () async {
      final tag = Tag(id: 't1', name: 'Test');
      await service.createTag(tag);
      var tags = await service.fetchTagsForUser('local');
      expect(tags.length, 1);
      expect(tags.first.name, 'Test');

      final updated = Tag(id: 't1', name: 'Updated');
      await service.updateTag(updated);
      final fetched = await service.getTagById('t1');
      expect(fetched!.name, 'Updated');

      await service.deleteTag('t1');
      tags = await service.fetchTagsForUser('local');
      expect(tags.length, 0);
    });
  });
}
