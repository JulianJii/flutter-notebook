import 'package:drift/drift.dart' show DriftWrappedException, Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:init/core/database/app_database.dart';
import 'package:init/core/database/daos/folder_dao.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';

/// UNIQUE 冲突在 [CacheException.message] 里的**前缀**。
///
/// 产生方是本文件的 [SqlError] 判定，消费方是 `FolderRepositoryImpl`
/// （`TASK-022` §3 方案 A）。**共用同一个常量** —— 判重不靠
/// `message.contains('UNIQUE')`（前缀与 SQLite 错误文案耦合，drift 换版本就失效），
/// Repository 也不 import drift / sqlite3（SQL 细节不漏进 Repository）。
const String kUniqueConstraintPrefix = 'UNIQUE: ';

/// 文件夹的本地数据源。[FolderLocalDataSourceImpl.delete] 是**全 App 唯一**
/// 需要显式 `db.transaction()` 的数据方法（`REPOSITORY-MAP.md` §2.2）。
abstract class FolderLocalDataSource {
  /// 订阅文件夹 + 笔记数。结果里**不含**「全部」「未分类」两行（§5.3）。
  ///
  /// 错误传播：drift 的 watch 不在流里抛同步异常；读库失败以
  /// `Stream.error(CacheException)` 出现，由 Repository 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<FolderWithCount>> watchWithCounts();

  /// 插入。[NoteFolder.id] 必须已由 Repository 填好 uuid。
  Future<NoteFolder> insert(NoteFolder folder);

  /// 重命名。**不预查重名** —— 一次 UPDATE 让 `note_folders.name` 的 UNIQUE 索引
  /// 判重（查重 + 更新 = 两次查询 + 一个竞态窗口）。
  ///
  /// 名称冲突时抛 [CacheException]，其 `message` 以 [kUniqueConstraintPrefix]
  /// 开头 —— 映射成 `InputFailure` 是 Repository 的活。
  Future<NoteFolder> rename(String folderId, String name);

  /// 删除：删文件夹行 + 其下笔记 `folder_id` 置 NULL，**同一个事务**（Q37）。
  /// 命中 0 行 → 抛 [CacheException]。
  Future<void> delete(String folderId);
}

class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  /// 持有 [AppDatabase] 而不只是 [FolderDao]：DAO 拿不到 `transaction()`。
  FolderLocalDataSourceImpl(this._db, {FolderDao? dao})
    : _dao = dao ?? FolderDao(_db);

  final AppDatabase _db;
  final FolderDao _dao;

  @override
  Stream<List<FolderWithCount>> watchWithCounts() {
    return _dao.watchWithCounts().map(
      (rows) => rows
          .map(
            (row) => FolderWithCount(
              folder: _toEntity(row.folder),
              count: row.count,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<NoteFolder> insert(NoteFolder folder) => _guard(() async {
    final row = await _dao.insert(
      NoteFoldersCompanion.insert(
        id: folder.id,
        name: folder.name,
        createdAt: folder.createdAt,
        updatedAt: folder.updatedAt,
      ),
    );
    return _toEntity(row);
  });

  @override
  Future<NoteFolder> rename(String folderId, String name) => _guard(() async {
    // `updatedAt` 在这里取时钟：DAO 刻意不刷新它（测试要能注入固定时间），
    // 而 `RenameFolderUseCase` 只传 (folderId, name)，没有时间戳可传。
    final hit = await _dao.rename(
      folderId,
      NoteFoldersCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
    );
    if (!hit) {
      throw CacheException(message: 'Folder not found: $folderId');
    }
    // 回读：入参只有 id + 新名字，createdAt 无从得知。
    final row = await _read(folderId);
    if (row == null) {
      throw CacheException(message: 'Folder not found: $folderId');
    }
    return _toEntity(row);
  });

  @override
  Future<void> delete(String folderId) => _guard(() async {
    await _db.transaction(() async {
      // 显式置 NULL 与外键 ON DELETE SET NULL 冗余：原子性不寄托在某个
      // drift / SQLite 版本的外键行为上（Q37 问的正是这个）。
      await _dao.nullOutFolder(folderId);
      final removed = await _dao.deleteById(folderId);
      if (removed == 0) {
        throw CacheException(message: 'Folder not found: $folderId');
      }
    });
  });

  /// 重命名后回读单行。
  ///
  /// `FolderDao` 没有 `getById`，而 [NoteFolder] 的 `createdAt` 是必填 —— 不回读
  /// 就只能编一个时间戳给上层。用 drift DSL（不是裸 SQL）单表查询，不新增 DAO 方法
  /// （DAO 是 `TASK-019` 的产物，本轮不改）。
  Future<NoteFolderRow?> _read(String folderId) {
    return (_db.select(
      _db.noteFolders,
    )..where((t) => t.id.equals(folderId))).getSingleOrNull();
  }
}

/// drift 行 → 领域实体的**直连**（⛔ 不建 Model 层，`REPOSITORY-MAP.md` §0）。
/// 「文件夹 + 计数」的组装也在这里：DAO 给的是行 + 标量，domain 要的是一个视图对象。
NoteFolder _toEntity(NoteFolderRow row) {
  return NoteFolder(
    id: row.id,
    name: row.name,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// 读库失败的统一边界。与笔记侧的差别只有一处：**UNIQUE 冲突打上
/// [kUniqueConstraintPrefix] 前缀**，让 Repository 能判出「重名」并映射成
/// `InputFailure`，而不用去认 SQLite 的错误文案。
Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on CacheException {
    rethrow;
  } on SqliteException catch (e) {
    if (e.extendedResultCode == _sqlConstraintUnique) {
      throw CacheException(message: '$kUniqueConstraintPrefix${e.message}');
    }
    throw CacheException(message: e.message);
  } on DriftWrappedException catch (e) {
    throw CacheException(message: e.message);
  } on Exception catch (e) {
    throw CacheException(message: e.toString());
  }
}

/// SQLite 的 `SQLITE_CONSTRAINT_UNIQUE` 扩展结果码（`19 | (8 << 8) = 2067`）。
///
/// ⚠️ **为什么是本地常量而不是 `SqlExtendedError.SQLITE_CONSTRAINT_UNIQUE`**：
/// 那两个符号住在 `package:sqlite3`，而 sqlite3 是 drift 的**传递**依赖 —— 直接
/// import 会触发 `depend_on_referenced_packages`，要消掉它就得给 `pubspec.yaml`
/// 加一条本轮不该动的依赖。`SqliteException` 本身可以从 `package:drift/native.dart`
/// 拿到（drift 原样 re-export），所以只有这一个码需要本地写。
/// 来源：https://sqlite.org/rescode.html —— SQLite 的结果码是 ABI 的一部分，
/// 不会随 sqlite3 包的版本变化。
/// ponytail: 若将来给 pubspec 加了 sqlite3 直依赖，把这里换回 `SqlExtendedError`。
const int _sqlConstraintUnique = 2067;
