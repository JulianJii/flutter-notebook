// 只取 `Value` —— 整包导入 drift 会与 matcher 的 `isNull` 撞名。
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_tag_dao.dart';

void main() {
  late AppDatabase db;
  late NoteTagDao dao;

  Future<String> insertNote(String id) async {
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: id,
            createdAt: DateTime(2026, 10, 13),
            updatedAt: DateTime(2026, 10, 13),
          ),
        );
    return id;
  }

  Future<String> insertTag(String id, String name) async {
    await db
        .into(db.noteTags)
        .insert(
          NoteTagsCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime(2026, 10, 13),
            updatedAt: DateTime(2026, 10, 13),
          ),
        );
    return id;
  }

  setUp(() async {
    db = AppDatabase.memory();
    dao = NoteTagDao(db);
  });

  tearDown(() => db.close());

  test('setNoteTagLinks：补挂 → 摘除打墓碑 → 重挂复活同一行', () async {
    final noteId = await insertNote('n1');
    final tagId = await insertTag('t1', '工作');

    await dao.setNoteTagLinks(noteId, [tagId]);
    expect(await dao.tagNamesForNote(noteId), ['工作']);

    // 摘除：墓碑（不物理删），查询过滤。
    await dao.setNoteTagLinks(noteId, []);
    expect(await dao.tagNamesForNote(noteId), isEmpty);
    final links = await db.select(db.noteTagLinks).get();
    expect(links, hasLength(1), reason: '摘除是墓碑，行要留在同步链路里');
    expect(links.single.deletedAt, isNotNull);

    // 重挂：复合主键占着位，复活而不是插新行。
    await dao.setNoteTagLinks(noteId, [tagId]);
    expect(await dao.tagNamesForNote(noteId), ['工作']);
    expect((await db.select(db.noteTagLinks).get()), hasLength(1));
    expect(
      (await db.select(db.noteTagLinks).get()).single.deletedAt,
      isNull,
    );
  });

  test('softDeleteTag：标签墓碑 + 全部挂接级联墓碑，watchAll 不再返回', () async {
    final noteId = await insertNote('n1');
    final t1 = await insertTag('t1', '工作');
    final t2 = await insertTag('t2', '生活');
    await dao.setNoteTagLinks(noteId, [t1, t2]);

    await dao.softDeleteTag(t1, DateTime(2026, 10, 14));

    expect((await dao.watchAllWithCounts().first).map((r) => r.tag.name), [
      '生活',
    ], reason: '删除的标签从列表消失');
    expect(await dao.tagNamesForNote(noteId), ['生活'], reason: '挂接被级联摘掉');
    // 墓碑行仍在库里（同步链路）。
    expect((await dao.getByName('工作'))!.deletedAt, isNotNull);
  });

  test('watchAllWithCounts 只数挂着的存活笔记；getByName 含墓碑', () async {
    final live = await insertNote('n1');
    final trashed = await insertNote('n2');
    await (db.update(db.notes)..where((t) => t.id.equals(trashed))).write(
      NotesCompanion(deletedAt: Value(DateTime(2026, 10, 14))),
    );
    final tagId = await insertTag('t1', '工作');
    await dao.setNoteTagLinks(live, [tagId]);
    await dao.setNoteTagLinks(trashed, [tagId]);

    final counts = await dao.watchAllWithCounts().first;
    expect(counts, hasLength(1));
    expect(counts.single.noteCount, 1, reason: '回收站里的笔记不计入');

    // 摘掉唯一挂接后 count 归 0，但标签还在列表里。
    await dao.setNoteTagLinks(live, []);
    final zero = await dao.watchAllWithCounts().first;
    expect(zero.single.tag.id, tagId);
    expect(zero.single.noteCount, 0);
  });
}
