import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_dao.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/notes/data/datasources/note_local_data_source.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteDao extends Mock implements NoteDao {}

/// drift 存 `DateTime` 用 unix **秒**，毫秒级的值会全部塌成 0
/// （排序键相同，测不出方向）。
final DateTime _t1 = DateTime.fromMillisecondsSinceEpoch(100 * 1000);
final DateTime _t2 = DateTime.fromMillisecondsSinceEpoch(200 * 1000);

/// 一条固定的 drift 行。`folderId` 刻意给非 null —— 未分类那一支另有用例，
/// 这里要盯的是「转换不丢字段」。
final NoteRow _row = NoteRow(
  id: 'n1',
  title: '标题',
  content: '正文',
  folderId: 'f1',
  createdAt: _t1,
  updatedAt: _t2,
);

/// 断言 DAO 收到的**全部 6 个参数**与期望逐字一致。
///
/// ⚠️ 不能用 `captureAny` + 下标取值：`Invocation.namedArguments` 的遍历顺序
/// 由 VM 的参数描述符决定（实测与源码顺序相反），按下标断言会得到
/// 「folderId 是 false」这种看似离谱实则顺序错位的结果。逐个具名断言同时也多锁了
/// 「没有多余的过滤条件」。
void _verifyWatch(
  _MockNoteDao dao, {
  String? folderId,
  bool uncategorizedOnly = false,
  String? searchTerm,
  NoteDaoOrder order = NoteDaoOrder.editedDesc,
  int? limit,
  int offset = 0,
}) {
  verify(
    () => dao.watch(
      folderId: folderId,
      uncategorizedOnly: uncategorizedOnly,
      searchTerm: searchTerm,
      order: order,
      limit: limit,
      offset: offset,
    ),
  ).called(1);
}

void main() {
  setUpAll(() {
    registerFallbackValue(NoteDaoOrder.editedDesc);
    registerFallbackValue(
      const NotesCompanion(id: Value('fallback'), title: Value('x')),
    );
  });

  group('NoteQuery -> DAO 参数（mock DAO，只验翻译）', () {
    late _MockNoteDao dao;
    late NoteLocalDataSourceImpl source;
    late AppDatabase unusedDb;

    setUp(() {
      dao = _MockNoteDao();
      // db 只在 dao 为 null 时被用来造 DAO；这里注入 mock，db 是纯占位。
      unusedDb = AppDatabase.memory();
      source = NoteLocalDataSourceImpl(unusedDb, dao: dao);
      when(
        () => dao.watch(
          folderId: any(named: 'folderId'),
          uncategorizedOnly: any(named: 'uncategorizedOnly'),
          searchTerm: any(named: 'searchTerm'),
          order: any(named: 'order'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) => Stream.value([_row]));
    });

    tearDown(() => unusedDb.close());

    test('AllFolders -> 完全不带 folder 过滤', () async {
      await source.watch(const NoteQuery()).first;
      _verifyWatch(dao);
    });

    test(
      'UncategorizedNotes -> uncategorizedOnly: true 且 folderId 为 null',
      () async {
        await source.watch(NoteQuery.uncategorized()).first;
        _verifyWatch(dao, uncategorizedOnly: true);
      },
    );

    test('SingleFolder -> folderId 透传且 uncategorizedOnly: false', () async {
      await source.watch(NoteQuery.of('f9')).first;
      _verifyWatch(dao, folderId: 'f9');
    });

    test('searchTerm \x27\x27 归一化为 null', () async {
      await source.watch(const NoteQuery(searchTerm: '')).first;
      _verifyWatch(dao, searchTerm: null);
    });

    test('searchTerm 非空串原样透传（含 LIKE 元字符，不在此处转义）', () async {
      await source.watch(const NoteQuery(searchTerm: '100%')).first;
      _verifyWatch(dao, searchTerm: '100%');
    });

    test('4 种 NoteSort 各自映射到同名 NoteDaoOrder（穷尽 4 分支）', () async {
      const pairs = <NoteSort, NoteDaoOrder>{
        NoteSort.editedDesc: NoteDaoOrder.editedDesc,
        NoteSort.editedAsc: NoteDaoOrder.editedAsc,
        NoteSort.createdDesc: NoteDaoOrder.createdDesc,
        NoteSort.titleAsc: NoteDaoOrder.titleAsc,
      };

      for (final entry in pairs.entries) {
        reset(dao);
        when(
          () => dao.watch(
            folderId: any(named: 'folderId'),
            uncategorizedOnly: any(named: 'uncategorizedOnly'),
            searchTerm: any(named: 'searchTerm'),
            order: any(named: 'order'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) => Stream.value([_row]));

        await source.watch(NoteQuery(sort: entry.key)).first;
        _verifyWatch(dao, order: entry.value);
      }
    });

    test('limit 原样透传：负数也不抛 ArgumentError（校验是 UseCase 的活）', () async {
      await source.watch(const NoteQuery(limit: -1, offset: 5)).first;
      _verifyWatch(dao, limit: -1, offset: 5);
    });

    test('NoteRow -> Note 逐字段直连：不截断 content、不算 wordCount', () async {
      final notes = await source.watch(const NoteQuery()).first;
      expect(
        notes.single,
        Note(
          id: 'n1',
          title: '标题',
          content: '正文',
          folderId: 'f1',
          createdAt: _t1,
          updatedAt: _t2,
        ),
      );
    });
  });

  group('异常映射（mock DAO）', () {
    late _MockNoteDao dao;
    late NoteLocalDataSourceImpl source;
    late AppDatabase unusedDb;

    setUp(() {
      dao = _MockNoteDao();
      unusedDb = AppDatabase.memory();
      source = NoteLocalDataSourceImpl(unusedDb, dao: dao);
    });

    tearDown(() => unusedDb.close());

    test('getById 未命中 -> CacheException（不是 Failure，也不是 null）', () async {
      when(() => dao.getById('nope')).thenAnswer((_) async => null);
      await expectLater(
        source.getById('nope'),
        throwsA(
          isA<CacheException>().having(
            (e) => e.message,
            'message',
            contains('nope'),
          ),
        ),
      );
    });

    test('update 未命中 -> CacheException', () async {
      when(() => dao.updateById(any())).thenAnswer((_) async => false);
      await expectLater(
        source.update(Note(id: 'nope', createdAt: _t1, updatedAt: _t2)),
        throwsA(isA<CacheException>()),
      );
    });

    test('updateBackground 未命中 -> CacheException（且枚举已译成 id 字符串）', () async {
      when(
        () => dao.updateBackgroundById('nope', 'mint'),
      ).thenAnswer((_) async => false);
      await expectLater(
        source.updateBackground('nope', NoteBackground.mint),
        throwsA(
          isA<CacheException>().having(
            (e) => e.message,
            'message',
            contains('nope'),
          ),
        ),
      );
    });

    test('delete（软删除）未命中 -> CacheException', () async {
      when(
        () => dao.softDeleteById('nope', any()),
      ).thenAnswer((_) async => false);
      await expectLater(source.delete('nope'), throwsA(isA<CacheException>()));
    });

    test('SqliteException -> CacheException，且原始异常不外泄', () async {
      when(() => dao.getById('n1')).thenThrow(
        SqliteException(
          extendedResultCode: 11,
          message: 'disk image is malformed',
        ),
      );
      await expectLater(
        source.getById('n1'),
        throwsA(
          isA<CacheException>()
              .having((e) => e.message, 'message', 'disk image is malformed')
              .having(
                (e) => e.message,
                'message',
                isNot(contains('SqliteException')),
              ),
        ),
      );
    });

    test('已经是 CacheException 的不再二次包装（rethrow）', () async {
      when(
        () => dao.softDeleteById('n1', any()),
      ).thenThrow(CacheException(message: 'Cache Error: inner'));
      await expectLater(
        source.delete('n1'),
        throwsA(
          isA<CacheException>().having(
            (e) => e.message,
            'message',
            'Cache Error: inner',
          ),
        ),
      );
    });
  });

  group('真实链路（内存库）', () {
    late AppDatabase db;
    late NoteLocalDataSourceImpl source;

    setUp(() {
      db = AppDatabase.memory();
      source = NoteLocalDataSourceImpl(db);
    });

    tearDown(() => db.close());

    test('insert -> watch 回读，且 update 不覆盖库里的 createdAt', () async {
      final inserted = await source.insert(
        Note(
          id: 'n1',
          title: '新笔记',
          content: '正文',
          createdAt: _t1,
          updatedAt: _t1,
        ),
      );
      expect(inserted.title, '新笔记');
      expect((await source.watch(const NoteQuery()).first).single.id, 'n1');

      // UseCase 传的 createdAt 是 now()，落库后必须仍读回 _t1。
      final updated = await source.update(
        Note(
          id: 'n1',
          title: '改过的标题',
          content: '正文',
          createdAt: DateTime(2030),
          updatedAt: _t2,
        ),
      );
      expect(updated.createdAt, _t1, reason: 'createdAt 不该被自动保存覆盖');
      expect(updated.title, '改过的标题');
      expect(updated.updatedAt, _t2);
    });

    test('背景全链路：insert 落库、整行 update 不覆盖、updateBackground 改 / 清', () async {
      final inserted = await source.insert(
        Note(
          id: 'n1',
          title: '带背景',
          content: '正文',
          background: NoteBackground.mint,
          createdAt: _t1,
          updatedAt: _t1,
        ),
      );
      expect(inserted.background, NoteBackground.mint);
      expect((await source.getById('n1')).background, NoteBackground.mint);

      await source.update(
        Note(id: 'n1', title: '改标题', createdAt: _t1, updatedAt: _t2),
      );
      expect(
        (await source.getById('n1')).background,
        NoteBackground.mint,
        reason: '整行 update 不写 background 列：自动保存不会把背景冲掉',
      );

      await source.updateBackground('n1', NoteBackground.blush);
      final changed = await source.getById('n1');
      expect(changed.background, NoteBackground.blush);
      expect(changed.title, '改标题', reason: '只写一列，别的字段不动');
      expect(changed.updatedAt, _t2, reason: '换背景不刷 updatedAt');

      await source.updateBackground('n1', null);
      expect((await source.getById('n1')).background, isNull);

      await expectLater(
        source.updateBackground('nope', NoteBackground.paper),
        throwsA(isA<CacheException>()),
      );
    });

    test('库里未知的 background id 降级为无背景（不崩页面）', () async {
      await db.customStatement(
        'INSERT INTO notes (id, title, content, background, created_at, updated_at) '
        'VALUES (?,?,?,?,?,?)',
        ['n1', '老数据', 'c', '未来版本的背景', 100, 100],
      );
      expect((await source.getById('n1')).background, isNull);
    });

    test('三态翻译在真实 SQL 上可观察：全部 / 未分类 / 单文件夹', () async {
      await db.customStatement(
        'INSERT INTO note_folders (id, name, created_at, updated_at) VALUES (?,?,?,?)',
        ['f1', '词声笔记', 100, 100],
      );
      await db.customStatement(
        'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
        'VALUES (?,?,?,?,?,?)',
        ['n1', '在文件夹里', 'c', 'f1', 100, 100],
      );
      await db.customStatement(
        'INSERT INTO notes (id, title, content, folder_id, created_at, updated_at) '
        'VALUES (?,?,?,?,?,?)',
        ['n2', '未分类', 'c', null, 100, 100],
      );

      expect(
        (await source.watch(const NoteQuery()).first).map((n) => n.id),
        hasLength(2),
      );
      expect(
        (await source.watch(NoteQuery.uncategorized()).first).map((n) => n.id),
        ['n2'],
      );
      expect((await source.watch(NoteQuery.of('f1')).first).map((n) => n.id), [
        'n1',
      ]);
    });

    test('软删除全链路：watch/搜索不含已删；watchDeleted 含；restore 后回来', () async {
      await source.insert(
        Note(
          id: 'n1',
          title: '会被搜到',
          content: '关键词alpha',
          createdAt: _t1,
          updatedAt: _t1,
        ),
      );

      // 搜索命中。
      expect(
        (await source.watch(const NoteQuery(searchTerm: 'alpha')).first),
        hasLength(1),
      );

      await source.delete('n1');

      // 列表与搜索都不再含已删笔记（deleted_at IS NULL 过滤在搜索条件之前）。
      expect(await source.watch(const NoteQuery()).first, isEmpty);
      expect(
        (await source.watch(const NoteQuery(searchTerm: 'alpha')).first),
        isEmpty,
      );
      // 回收站含，且带 deletedAt。
      final trashed = await source.watchDeleted().first;
      expect(trashed.single.id, 'n1');
      expect(trashed.single.deletedAt, isNotNull);

      // 恢复后回到列表。
      await source.restore('n1');
      expect(
        (await source.watch(const NoteQuery()).first).single.id,
        'n1',
      );
      expect(await source.watchDeleted().first, isEmpty);
    });

    test('purge 物理删除已软删的笔记；purgeAll 清空回收站', () async {
      for (final id in ['n1', 'n2']) {
        await source.insert(
          Note(id: id, title: id, createdAt: _t1, updatedAt: _t1),
        );
        await source.delete(id);
      }
      await source.purge('n1');
      expect((await source.watchDeleted().first).map((n) => n.id), ['n2']);

      await source.purgeAll();
      expect(await source.watchDeleted().first, isEmpty);
      // 物理删除后 getById 抛 not found。
      await expectLater(source.getById('n1'), throwsA(isA<CacheException>()));
    });
  });
}
