import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';

/// drift 存 `DateTime` 用 unix **秒**，毫秒级的值会全部塌成 0。
final DateTime _t1 = DateTime.fromMillisecondsSinceEpoch(100 * 1000);

void main() {
  late AppDatabase db;
  late FolderLocalDataSourceImpl source;

  setUp(() async {
    db = AppDatabase.memory();
    source = FolderLocalDataSourceImpl(db);
    await db.customStatement(
      'INSERT INTO note_folders (id, name, created_at, updated_at) VALUES (?,?,?,?)',
      ['f1', '词声笔记', 100, 100],
    );
    await db.customStatement(
      'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
      'VALUES (?,?,?,?,?,?)',
      ['n1', '在文件夹里', '正文', 'f1', 100, 100],
    );
  });

  tearDown(() => db.close());

  Future<String?> folderIdOf(String noteId) async {
    final rows = await db
        .customSelect(
          'SELECT folder_id FROM notes WHERE id = ?',
          variables: [Variable(noteId)],
        )
        .get();
    return rows.single.data['folder_id'] as String?;
  }

  test('delete 是原子的：文件夹进回收站 + 其下笔记落入未分类', () async {
    await source.delete('f1');

    expect(
      await source.watchTrashed().first,
      hasLength(1),
      reason: '软删除 = 行还在，标了 deleted_at —— 硬删除不留痕，跨设备传不过去',
    );
    expect((await source.watchTrashed().first).single.name, '词声笔记',
        reason: '领域实体这一侧剥掉让出后缀，用户看到的是原名');
    expect(await folderIdOf('n1'), isNull, reason: '笔记应落入未分类');
    // ⚠️ 软删除下外键 ON DELETE SET NULL **不触发**（行还在），笔记落未分类
    // 靠的是 nullOutFolder 的显式 UPDATE —— 漏了它这里就会是 'f1'。
    expect(
      (await db.customSelect('SELECT name, deleted_at FROM note_folders').get())
          .single,
      isNotNull,
    );
  });

  /// `name` 是 UNIQUE，软删除若不让出原名，用户删了「词声笔记」就再也建不了同名
  /// 文件夹（撞约束报错，看起来像 bug）。让出版形如 `词声笔记#f1`，靠 id 保证
  /// 必然不与任何行撞名。
  test('delete 让出原名，原名可以被重新占用', () async {
    await source.delete('f1');
    await db.customStatement(
      'INSERT INTO note_folders (id, name, created_at, updated_at) VALUES (?,?,?,?)',
      ['f2', '词声笔记', 200, 200],
    );

    final stored = (await db.customSelect('SELECT name FROM note_folders')
        .get()).map((r) => r.data['name']);
    expect(stored, containsAll(<String>['词声笔记', '词声笔记#f1']));
  });

  test('restore 改回原名 + 刷 updated_at', () async {
    final before = (await db.customSelect('SELECT updated_at FROM note_folders')
        .get()).single.data['updated_at'];
    await source.delete('f1');
    await source.restore('f1');

    final rows = await db.customSelect('SELECT name, deleted_at, updated_at FROM note_folders').get();
    expect(rows.single.data['name'], '词声笔记', reason: '让出的名字还回去了');
    expect(rows.single.data['deleted_at'], isNull);
    expect(
      rows.single.data['updated_at'],
      isNot(before),
      reason: '恢复必须刷 updated_at，否则同步时 version 退回旧值、恢复传不过去',
    );
    expect(await source.watchTrashed().first, isEmpty);
  });

  test('restore 时原名已被占用 -> CacheException，保留让出版', () async {
    await source.delete('f1');
    await db.customStatement(
      'INSERT INTO note_folders (id, name, created_at, updated_at) VALUES (?,?,?,?)',
      ['f2', '词声笔记', 200, 200],
    );

    await expectLater(source.restore('f1'), throwsA(isA<CacheException>()));

    final stored = (await db.customSelect('SELECT name, deleted_at FROM note_folders').get())
        .map((r) => r.data['name']);
    expect(stored, contains('词声笔记#f1'),
        reason: '不悄悄改名：用户要恢复的是原文件夹，不是一个同名的空壳');
  });

  test('delete 不存在的文件夹 -> CacheException，且事务整体回滚', () async {
    await expectLater(source.delete('nope'), throwsA(isA<CacheException>()));

    // 事务里先跑的 nullOutFolder 必须被回滚，否则「删不存在的文件夹」会
    // 静默把别人的笔记踢进未分类。
    expect(await folderIdOf('n1'), 'f1');
  });

  test('rename 撞 UNIQUE -> CacheException 带 kUniqueConstraintPrefix', () async {
    await db.customStatement(
      'INSERT INTO note_folders (id, name, created_at, updated_at) VALUES (?,?,?,?)',
      ['f2', '速记', 100, 100],
    );

    await expectLater(
      source.rename('f2', '词声笔记'),
      throwsA(
        isA<CacheException>().having(
          (e) => e.message,
          'message',
          startsWith(kUniqueConstraintPrefix),
        ),
      ),
    );
    // 名字没被改掉
    final rows = await db
        .customSelect(
          'SELECT name FROM note_folders WHERE id = ?',
          variables: [Variable('f2')],
        )
        .get();
    expect(rows.single.data['name'], '速记');
  });

  test('rename 正常 -> 回读实体，名字变了、createdAt 保留', () async {
    // ⛔ 数据层不 trim：trim 是 `CreateFolderUseCase` / `RenameFolderUseCase`
    // 的职责（「不擅自改用户输入」）。
    final renamed = await source.rename('f1', '词声笔记2');
    expect(renamed.id, 'f1');
    expect(renamed.name, '词声笔记2');
    expect(renamed.createdAt, _t1, reason: 'createdAt 不该被 rename 改掉');
    expect(
      renamed.updatedAt.isAfter(_t1),
      isTrue,
      reason: 'updatedAt 由 datasource 刷新（DAO 不取时钟）',
    );
  });

  test('rename 不存在的文件夹 -> CacheException', () async {
    await expectLater(
      source.rename('nope', '随便'),
      throwsA(isA<CacheException>()),
    );
  });

  test('insert 撞 UNIQUE 同样带前缀（Repository 靠它判 InputFailure）', () async {
    await expectLater(
      source.insert(
        NoteFolder(id: 'f9', name: '词声笔记', createdAt: _t1, updatedAt: _t1),
      ),
      throwsA(
        isA<CacheException>().having(
          (e) => e.message,
          'message',
          startsWith(kUniqueConstraintPrefix),
        ),
      ),
    );
  });

  test('watchWithCounts 返回 FolderWithCount：字段不丢、计数为 1', () async {
    final rows = await source.watchWithCounts().first;
    expect(rows.single.folder.id, 'f1');
    expect(rows.single.folder.name, '词声笔记');
    expect(rows.single.folder.createdAt, isA<DateTime>());
    expect(rows.single.count, 1);
  });

  test('watchWithCounts 结果里没有「全部」「未分类」两行（§5.3）', () async {
    await source.delete('f1');
    expect(await source.watchWithCounts().first, isEmpty);
  });
}
