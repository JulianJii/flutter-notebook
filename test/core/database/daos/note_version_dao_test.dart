import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_version_dao.dart';

void main() {
  late AppDatabase db;
  late NoteVersionDao dao;

  Future<void> seedNote(String id) async {
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: id,
            createdAt: DateTime(2026, 10, 13),
            updatedAt: DateTime(2026, 10, 13),
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.memory();
    dao = NoteVersionDao(db);
    await seedNote('n1');
  });

  tearDown(() => db.close());

  test('saveVersion 去重：与最近一版 title+content 全同 → 跳过', () async {
    await dao.saveVersion(
      'n1',
      versionId: 'v1',
      title: '标题',
      content: '正文',
      createdAt: DateTime(2026, 10, 13, 10),
      limit: 50,
    );
    await dao.saveVersion(
      'n1',
      versionId: 'v2',
      title: '标题',
      content: '正文',
      createdAt: DateTime(2026, 10, 13, 11),
      limit: 50,
    );

    expect((await dao.watchVersions('n1').first), hasLength(1));
  });

  test('saveVersion：改了内容 → 存新版；watchVersions 按 createdAt 倒序', () async {
    await dao.saveVersion(
      'n1',
      versionId: 'v1',
      title: '一',
      content: '旧',
      createdAt: DateTime(2026, 10, 13, 10),
      limit: 50,
    );
    await dao.saveVersion(
      'n1',
      versionId: 'v2',
      title: '二',
      content: '新',
      createdAt: DateTime(2026, 10, 13, 11),
      limit: 50,
    );

    final versions = await dao.watchVersions('n1').first;
    expect(versions.map((v) => v.id), ['v2', 'v1']);
  });

  test('超上限淘汰最旧（物理 DELETE）', () async {
    for (var i = 0; i < 5; i++) {
      await dao.saveVersion(
        'n1',
        versionId: 'v$i',
        title: '第$i版',
        content: '内容$i',
        createdAt: DateTime(2026, 10, 13, 10 + i),
        limit: 3,
      );
    }

    final versions = await dao.watchVersions('n1').first;
    expect(versions, hasLength(3));
    // 留下的是最新的三版（v4 / v3 / v2），最旧的 v0 / v1 被物理删。
    expect(versions.map((v) => v.id), ['v4', 'v3', 'v2']);
    expect(await dao.getById('v0'), isNull);
  });

  test('getById 不存在返回 null（不抛异常）', () async {
    expect(await dao.getById('nope'), isNull);
  });
}
