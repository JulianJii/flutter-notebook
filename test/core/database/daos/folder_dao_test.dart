import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/database/app_database.dart';
import 'package:init/core/database/daos/folder_dao.dart';

void main() {
  late AppDatabase db;
  late FolderDao dao;

  final t = DateTime(2026, 10, 3);

  setUp(() async {
    db = AppDatabase.memory();
    dao = FolderDao(db);
    // D4 实测口径：词声笔记 1 条 + 未分类 154 条 = 全部 155 条。
    // 这里用小数字复现同一关系：f1 有 1 条，f0 有 0 条，2 条未分类。
    await dao.insert(
      NoteFoldersCompanion.insert(
        id: 'f1',
        name: '词声笔记',
        createdAt: t,
        updatedAt: t,
      ),
    );
    await dao.insert(
      NoteFoldersCompanion.insert(
        id: 'f0',
        name: '空文件夹',
        createdAt: t,
        updatedAt: t,
      ),
    );
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?,?,?,?,?,?)',
      ['n1', '在文件夹里', '正文', 'f1', 0, 0],
    );
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?,?,?,?,?,?)',
      ['n2', '未分类一', '正文', null, 0, 0],
    );
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?,?,?,?,?,?)',
      ['n3', '未分类二', '正文', null, 0, 0],
    );
  });

  tearDown(() async => db.close());

  test('watchWithCounts 给出每个文件夹的笔记数（0 也出现）', () async {
    final rows = await dao.watchWithCounts().first;
    expect(rows.length, 2, reason: 'f0 不能消失');
    expect(rows.firstWhere((r) => r.folder.id == 'f1').count, 1);
    expect(rows.firstWhere((r) => r.folder.id == 'f0').count, 0);
  });

  test('watchUncategorizedCount 数 folder_id IS NULL', () async {
    expect(await dao.watchUncategorizedCount().first, 2);
  });

  Future<List<String>> ids() async =>
      (await dao.watchWithCounts().first).map((r) => r.folder.id).toList();

  test('updateSortIndexes 决定顺序（同 createdAt 时靠它分先后）', () async {
    // setUp 的两次插入 createdAt 相同 → 顺序只看 sort_index（0 在前）。
    expect(await ids(), <String>['f1', 'f0']);

    await dao.updateSortIndexes(<String>['f0', 'f1']);

    expect(await ids(), <String>['f0', 'f1']);
  });

  test('insert 把新文件夹排到末尾（sort_index = MAX+1）', () async {
    await dao.updateSortIndexes(<String>['f0', 'f1']);
    await dao.insert(
      NoteFoldersCompanion.insert(
        id: 'f3',
        name: '新来的',
        createdAt: DateTime(2026, 10, 2),
        updatedAt: t,
      ),
    );

    // 即使 createdAt 比谁都早，也排在末尾 —— 顺序由 sort_index 说了算。
    expect(await ids(), <String>['f0', 'f1', 'f3']);
  });

  test('笔记的增删改会推动计数变化（watch 自动重算，无需手动失效）', () async {
    final before = await dao.watchWithCounts().first;
    expect(before.firstWhere((r) => r.folder.id == 'f1').count, 1);

    // ⚠️ 必须走 drift 的 update（而不是 customStatement 裸 SQL）——
    // 裸 SQL 不触发 drift 的更新通知，watch 不会重算。
    await (db.update(db.notes)..where((t) => t.id.equals('n1'))).write(
      const NotesCompanion(folderId: Value(null)),
    );

    final after = await dao.watchWithCounts().first;
    expect(after.firstWhere((r) => r.folder.id == 'f1').count, 0);
    expect(await dao.watchUncategorizedCount().first, 3);
  });

  test('deleteById + nullOutFolder 同事务 → 笔记落未分类（Q37）', () async {
    // 真实编排在 TASK-021 的 datasource（db.transaction）；这里只验两个原子操作各自可用。
    await db.transaction(() async {
      await dao.nullOutFolder('f1');
      await dao.deleteById('f1');
    });

    final rows = await db
        .customSelect(
          'SELECT folder_id FROM notes WHERE id = ?',
          variables: [Variable('n1')],
        )
        .get();
    expect(rows.single.data['folder_id'], isNull);
    expect((await dao.watchWithCounts().first).length, 1);
  });

  test('只 deleteById（靠外键 ON DELETE SET NULL）也落未分类', () async {
    expect(await dao.deleteById('f1'), 1);

    final rows = await db
        .customSelect(
          'SELECT folder_id FROM notes WHERE id = ?',
          variables: [Variable('n1')],
        )
        .get();
    expect(rows.single.data['folder_id'], isNull);
  });

  test('rename 撞 UNIQUE 时抛异常（不静默失败）', () async {
    await dao.insert(
      NoteFoldersCompanion.insert(
        id: 'f2',
        name: '速记',
        createdAt: t,
        updatedAt: t,
      ),
    );

    await expectLater(
      dao.rename('f2', NoteFoldersCompanion(name: const Value('词声笔记'))),
      throwsA(anything),
    );
  });

  test('rename 命中行返回 true，不存在返回 false', () async {
    expect(
      await dao.rename('f0', NoteFoldersCompanion(name: const Value('改名了'))),
      isTrue,
    );
    expect(
      await dao.rename('nope', NoteFoldersCompanion(name: const Value('随便'))),
      isFalse,
    );
    expect(
      (await dao.watchWithCounts().first)
          .firstWhere((r) => r.folder.id == 'f0')
          .folder
          .name,
      '改名了',
    );
  });
}
