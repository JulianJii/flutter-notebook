// 只取 `Value` —— 整包导入 drift 会与 matcher 的 `isNull` 撞名。
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_dao.dart';

void main() {
  late AppDatabase db;
  late NoteDao dao;

  setUp(() async {
    db = AppDatabase.memory();
    dao = NoteDao(db);
    await db.customStatement(
      'INSERT INTO note_folders (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)',
      ['f1', '词声笔记', 0, 0],
    );
    // n1 有文件夹、n2 / n3 未分类；updatedAt 升序
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['n1', '带文件夹的笔记', '100% 完成', 'f1', 100, 300],
    );
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['n2', '未分类笔记一', '正文一', null, 200, 200],
    );
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['n3', '未分类笔记二', '正文二', null, 300, 100],
    );
  });

  tearDown(() async => db.close());

  test('无筛选 → 全部，按 updatedAt DESC', () async {
    final rows = await dao.watch().first;
    expect(rows.map((r) => r.id), ['n1', 'n2', 'n3']);
  });

  test('单文件夹 → folder_id = ?', () async {
    final rows = await dao.watch(folderId: 'f1').first;
    expect(rows.map((r) => r.id), ['n1']);
  });

  test('uncategorizedOnly → 只有 folder_id IS NULL', () async {
    final rows = await dao.watch(uncategorizedOnly: true).first;
    expect(rows.map((r) => r.id), ['n2', 'n3']);
  });

  test('4 种排序方向都正确', () async {
    expect(
      (await dao.watch(order: NoteDaoOrder.editedAsc).first).map((r) => r.id),
      ['n3', 'n2', 'n1'],
    );
    expect(
      (await dao.watch(order: NoteDaoOrder.createdDesc).first).map((r) => r.id),
      ['n3', 'n2', 'n1'],
    );
    // title ASC 走 SQLite 的 BINARY 排序（UTF-8 字节序），不是拼音：
    // '带'(U+5E26) < '未'(U+672A)，故 n1 在前。
    expect(
      (await dao.watch(order: NoteDaoOrder.titleAsc).first).map((r) => r.id),
      ['n1', 'n2', 'n3'],
    );
  });

  test('limit + offset 生效', () async {
    final rows = await dao.watch(limit: 2).first;
    expect(rows.map((r) => r.id), ['n1', 'n2']);

    final shifted = await dao.watch(limit: 2, offset: 1).first;
    expect(shifted.map((r) => r.id), ['n2', 'n3']);

    final offsetOnly = await dao.watch(offset: 2).first;
    expect(offsetOnly.map((r) => r.id), ['n3']);
  });

  test('searchTerm 转义 % → 不把通配符当模式', () async {
    final hits = await dao.watch(searchTerm: '100%').first;
    expect(hits.map((r) => r.id), ['n1']);

    // 不转义的话 '100%' 会匹配所有含 "100" 的行（% 是单字符通配符）
    expect(await dao.watch(searchTerm: '100x').first, isEmpty);
  });

  test('searchTerm 转义 _ → 下划线不当通配符', () async {
    expect(await dao.watch(searchTerm: '未分类_').first, isEmpty);
    expect((await dao.watch(searchTerm: '未分类').first).map((r) => r.id), [
      'n2',
      'n3',
    ]);
  });

  test('folderId 与 uncategorizedOnly 互斥', () {
    expect(
      () => dao.watch(folderId: 'f1', uncategorizedOnly: true),
      throwsArgumentError,
    );
  });

  test('getById 不存在返回 null（不抛异常）', () async {
    expect(await dao.getById('nope'), isNull);
    expect((await dao.getById('n1'))!.title, '带文件夹的笔记');
  });

  test('无结果返回空列表，不抛异常', () async {
    expect(await dao.watch(folderId: 'nope').first, isEmpty);
    expect(await dao.watch(searchTerm: '不存在的词').first, isEmpty);
    expect(await dao.watch(folderId: 'f1', searchTerm: '未分类笔记').first, isEmpty);
  });

  test('offset 越界返回空列表，不抛异常', () async {
    expect(await dao.watch(limit: 2, offset: 99).first, isEmpty);
    expect(await dao.watch(offset: 99).first, isEmpty);
  });

  test('insert 后 watch 流自动推送新列表（不靠手动失效）', () async {
    final emissions = <List<NoteRow>>[];
    final sub = dao.watch().listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(emissions.single.map((r) => r.id), ['n1', 'n2', 'n3']);

    await dao.insert(
      NotesCompanion.insert(
        id: 'n4',
        title: const Value('新来的'),
        createdAt: DateTime(2026, 10, 4),
        updatedAt: DateTime(2026, 10, 4),
      ),
    );
    await pumpEventQueue();

    expect(emissions.length, greaterThanOrEqualTo(2));
    expect(emissions.last.map((r) => r.id), contains('n4'));
    expect(emissions.last, hasLength(4));

    await sub.cancel();
  });

  test('insert / updateById / deleteById', () async {
    final inserted = await dao.insert(
      NotesCompanion.insert(
        id: 'n4',
        title: const Value('新笔记'),
        createdAt: DateTime(2026, 10, 4),
        updatedAt: DateTime(2026, 10, 4),
      ),
    );
    expect(inserted.id, 'n4');
    expect(inserted.title, '新笔记');

    expect(
      await dao.updateById(
        NotesCompanion(id: const Value('n4'), title: const Value('改过的标题')),
      ),
      isTrue,
      reason: '命中行',
    );
    expect((await dao.getById('n4'))!.title, '改过的标题');

    expect(
      await dao.updateById(NotesCompanion(id: const Value('nope'))),
      isFalse,
      reason: '未命中行',
    );

    expect(await dao.deleteById('n4'), 1);
    expect(await dao.deleteById('n4'), 0);
    expect(await dao.getById('n4'), isNull);
  });

  test('updateBackgroundById 只写 background 列，不刷 updated_at', () async {
    final before = (await dao.getById('n2'))!;
    expect(before.background, isNull, reason: '新行默认无背景');

    expect(await dao.updateBackgroundById('n2', 'mint'), isTrue);
    final after = (await dao.getById('n2'))!;
    expect(after.background, 'mint');
    expect(after.title, before.title);
    expect(
      after.updatedAt,
      before.updatedAt,
      reason: '换背景不是编辑：列表排序键与卡片日期都不该跳变',
    );

    expect(await dao.updateBackgroundById('n2', null), isTrue);
    expect((await dao.getById('n2'))!.background, isNull, reason: '可清回无背景');

    expect(await dao.updateBackgroundById('nope', 'paper'), isFalse);
  });
}
