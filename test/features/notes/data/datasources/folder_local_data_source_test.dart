import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/database/app_database.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';

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

  test('delete 是原子的：文件夹消失 + 其下笔记落入未分类（Q37）', () async {
    await source.delete('f1');

    expect(
      await db.customSelect('SELECT id FROM note_folders').get(),
      isEmpty,
      reason: '文件夹行应被删掉',
    );
    expect(await folderIdOf('n1'), isNull, reason: '笔记应落入未分类');
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
