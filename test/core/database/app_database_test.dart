// 只取 `Value` —— 整包导入 drift 会与 matcher 的 `isNull` 撞名。
// ignore: depend_on_referenced_packages
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());

  tearDown(() => db.close());

  // v10 = 标签 / 待办挂笔记 / 单篇版本历史（三张新表 + todos.linked_note_id）。
// ⚠️ 升版本**必须**同步改这条断言：老库靠 `onUpgrade` 的 `addColumn` 升级，
// 版本号不一致会直接走错分支。
test('schemaVersion == 10', () {
  expect(db.schemaVersion, 10);
});

  test('beforeOpen 已打开 PRAGMA foreign_keys', () async {
    await db.customSelect('SELECT 1').get();
    final rows = await db.customSelect('PRAGMA foreign_keys').get();
    expect(rows.single.data.values.single, 1);
  });

  test('三张表都已创建', () async {
    final names = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    expect(
      names.map((r) => r.read<String>('name')),
      containsAll(<String>[
        'note_folders',
        'notes',
        'todos',
        'todo_subtasks',
        'note_tags',
        'note_tag_links',
        'note_versions',
      ]),
    );
  });

  test('两个 notes 索引真实存在', () async {
    await db.customSelect('SELECT 1').get();
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'notes'",
        )
        .get();
    expect(
      rows.map((r) => r.read<String>('name')),
      containsAll(<String>['idx_notes_folder_id', 'idx_notes_updated_at']),
    );
  });

  test('notes.editor_font_id 存在且默认 null（= 系统默认字体）', () async {
    final now = DateTime(2026, 10, 12);
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(id: 'n1', createdAt: now, updatedAt: now),
        );

    final note = await (db.select(
      db.notes,
    )..where((t) => t.id.equals('n1'))).getSingle();
    expect(note.editorFontId, isNull);
  });

  test('note_folders.name 唯一约束存在', () async {
    final now = DateTime(2026, 10, 3);
    await db
        .into(db.noteFolders)
        .insert(
          NoteFoldersCompanion.insert(
            id: 'f1',
            name: '词声笔记',
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(
      () => db
          .into(db.noteFolders)
          .insert(
            NoteFoldersCompanion.insert(
              id: 'f2',
              name: '词声笔记',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('删文件夹后其下笔记落未分类（ON DELETE SET NULL）', () async {
    final now = DateTime(2026, 10, 3);
    await db
        .into(db.noteFolders)
        .insert(
          NoteFoldersCompanion.insert(
            id: 'f1',
            name: '词声笔记',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: 'n1',
            folderId: const Value('f1'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await (db.delete(db.noteFolders)..where((t) => t.id.equals('f1'))).go();

    final note = await (db.select(
      db.notes,
    )..where((t) => t.id.equals('n1'))).getSingle();
    expect(note.folderId, isNull);
  });
  test('notes.title / content 默认空串，todos.is_done 默认 false', () async {
    final now = DateTime(2026, 10, 3);
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(id: 'n1', createdAt: now, updatedAt: now),
        );
    await db
        .into(db.todos)
        .insert(
          TodosCompanion.insert(
            id: 't1',
            title: '买牛奶',
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(
      (await (db.select(
        db.notes,
      )..where((t) => t.id.equals('n1'))).getSingle()).title,
      '',
    );
    expect(
      (await (db.select(
        db.todos,
      )..where((t) => t.id.equals('t1'))).getSingle()).isDone,
      isFalse,
    );
  });

  test('todos.linked_note_id 存在且默认 null（= 未挂接笔记）', () async {
    final now = DateTime(2026, 10, 13);
    await db
        .into(db.todos)
        .insert(
          TodosCompanion.insert(
            id: 't1',
            title: '买牛奶',
            createdAt: now,
            updatedAt: now,
          ),
        );

    final todo = await (db.select(
      db.todos,
    )..where((t) => t.id.equals('t1'))).getSingle();
    expect(todo.linkedNoteId, isNull);
  });

  test('删笔记后其版本与标签链接连带删除，挂接它的待办置 null', () async {
    final now = DateTime(2026, 10, 13);
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(id: 'n1', createdAt: now, updatedAt: now),
        );
    await db
        .into(db.noteTags)
        .insert(
          NoteTagsCompanion.insert(
            id: 'tag1',
            name: '工作',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.noteTagLinks)
        .insert(
          NoteTagLinksCompanion.insert(
            noteId: 'n1',
            tagId: 'tag1',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.noteVersions)
        .insert(
          NoteVersionsCompanion.insert(
            id: 'v1',
            noteId: 'n1',
            createdAt: now,
          ),
        );
    await db
        .into(db.todos)
        .insert(
          TodosCompanion.insert(
            id: 't1',
            title: '买牛奶',
            linkedNoteId: const Value('n1'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 物理删除笔记（模拟保留期清扫后的状态）。
    await (db.delete(db.notes)..where((t) => t.id.equals('n1'))).go();

    expect(
      await db.select(db.noteTagLinks).get(),
      isEmpty,
    );
    expect(await db.select(db.noteVersions).get(), isEmpty);
    expect(
      (await (db.select(
        db.todos,
      )..where((t) => t.id.equals('t1'))).getSingle()).linkedNoteId,
      isNull,
    );
  });
}
