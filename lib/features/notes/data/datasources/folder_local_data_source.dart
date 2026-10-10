import 'package:mynote/core/utils/app_clock.dart';
import 'package:drift/drift.dart' show DriftWrappedException, Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/folder_dao.dart';
import 'package:mynote/core/database/tables/note_folders_table.dart'
    show trashedFolderName, visibleFolderName;
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';

/// UNIQUE 冲突在 [CacheException.message] 里的**前缀**。
///
/// 产生方是本文件的 [SqlError] 判定，消费方是 `FolderRepositoryImpl`
/// （`TASK-022` §3 方案 A）。**共用同一个常量** —— 判重不靠
/// `message.contains('UNIQUE')`（前缀与 SQLite 错误文案耦合，drift 换版本就失效），
/// Repository 也不 import drift / sqlite3（SQL 细节不漏进 Repository）。
const String kUniqueConstraintPrefix = 'UNIQUE: ';

/// 文件夹的本地数据源。[FolderLocalDataSourceImpl.delete] 与 `.restore` 是**全 App
/// 唯一**需要显式 `db.transaction()` 的数据方法（`REPOSITORY-MAP.md` §2.2）——
/// 两者都是「读当前 `name` → 据此算出让出版/原名 → 写回」，拆开就有竞态。
abstract class FolderLocalDataSource {
  /// 订阅文件夹 + 笔记数。结果里**不含**「全部」「未分类」两行（§5.3）。
  ///
  /// 错误传播：drift 的 watch 不在流里抛同步异常；读库失败以
  /// `Stream.error(CacheException)` 出现，由 Repository 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<FolderWithCount>> watchWithCounts();

  /// 「未分类」笔记数。DAO 里已经是 `COUNT(*)`，这里纯透传，不做任何 Dart 层
  /// 计数（那需要先把全部未分类笔记的正文读进内存）。
  Stream<int> watchUncategorizedCount();

  /// 插入。[NoteFolder.id] 必须已由 Repository 填好 uuid。
  Future<NoteFolder> insert(NoteFolder folder);

  /// 重命名。**不预查重名** —— 一次 UPDATE 让 `note_folders.name` 的 UNIQUE 索引
  /// 判重（查重 + 更新 = 两次查询 + 一个竞态窗口）。
  ///
  /// 名称冲突时抛 [CacheException]，其 `message` 以 [kUniqueConstraintPrefix]
  /// 开头 —— 映射成 `InputFailure` 是 Repository 的活。
  Future<NoteFolder> rename(String folderId, String name);

  /// 软删除：改名让出原名 + 写 `deleted_at` + 其下笔记 `folder_id` 置 NULL，
  /// **同一个事务**。命中 0 行 → 抛 [CacheException]。
  ///
  /// ⛔ **不是物理删**：删除要能跨设备传播（`BackupFolder.version`）。
  Future<void> delete(String folderId);

  /// 从回收站恢复：改名回原名 + `deleted_at` 置 null + 刷 `updated_at`。
  /// 原名已被占用时抛 [CacheException]（保留让出版，不悄悄改名）。
  Future<void> restore(String folderId);

  /// 订阅回收站里的文件夹（`deleted_at IS NOT NULL`），按删除时间倒序。
  Stream<List<NoteFolder>> watchTrashed();

  /// 回收站的「永久删除」：**物理**删行。只由回收站 UI 发起。
  Future<void> purge(String folderId);

  /// 清空回收站。命中 0 行**不抛**（= 已清空），与 [purge] 的语义不同。
  Future<void> purgeAllTrashed();

  /// 按给定顺序重排（文件夹管理拖拽）。[orderedFolderIds] 是 UI 上的完整最终顺序，
  /// 实现把它整表写成 `sort_index = 0..n-1`。
  Future<void> reorder(List<String> orderedFolderIds);
}

class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  /// 持有 [AppDatabase] 而不只是 [FolderDao]：DAO 拿不到 `transaction()`。
  FolderLocalDataSourceImpl(this._db, {FolderDao? dao})
    : _dao = dao ?? FolderDao(_db);

  final AppDatabase _db;
  final FolderDao _dao;

  @override
  Stream<List<FolderWithCount>> watchWithCounts() {
    return _guardStream(
      _dao.watchWithCounts().map(
        (rows) => rows
            .map(
              (row) => FolderWithCount(
                folder: _toEntity(row.folder),
                count: row.count,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Stream<int> watchUncategorizedCount() =>
      _guardStream(_dao.watchUncategorizedCount());

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
      NoteFoldersCompanion(name: Value(name), updatedAt: Value(AppClock.appNow())),
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

  /// 软删除：进回收站。**不是**物理删 —— 删除要能跨设备传播（见
  /// `BackupFolder.version`）。
  ///
  /// 一件事三步，**必须同事务**：改 `name` 让出原名（`name` 是 UNIQUE，
  /// 否则用户再建同名文件夹会撞约束）→ 写 `deleted_at` → 把它下面的笔记
  /// 落进未分类。任一步单独发生都会留下半截状态。
  ///
  /// ⚠️ `nullOutFolder` 在软删除下**不再是冗余**：外键 `ON DELETE SET NULL`
  /// 只在物理 DELETE 时触发，行还在库里就不会置空，必须显式调。
  @override
  Future<void> delete(String folderId) => _guard(() async {
    await _db.transaction(() async {
      final row = await _read(folderId);
      if (row == null) {
        throw CacheException(message: 'Folder not found: $folderId');
      }
      final hit = await _dao.markTrashed(
        folderId,
        trashedFolderName(row.name, folderId),
        AppClock.appNow(),
      );
      if (!hit) {
        throw CacheException(message: 'Folder not found: $folderId');
      }
      await _dao.nullOutFolder(folderId);
    });
  });

  /// 从回收站恢复。改名回原名 + `deleted_at` 置 null + 刷 `updated_at`
  /// （后者是同步能传出去的前提，见 `FolderDao.markRestored`）。
  ///
  /// ⚠️ 原名可能已被重新占用（用户删了「工作」、新建了另一个「工作」、再恢复
  /// 旧的）。撞 UNIQUE 时保留让出版并计为失败 —— 比悄悄改名好：用户的意图是
  /// 恢复原文件夹，不是一个同名的空壳。
  @override
  Future<void> restore(String folderId) => _guard(() async {
    await _db.transaction(() async {
      final row = await _read(folderId);
      if (row == null) {
        throw CacheException(message: 'Folder not found: $folderId');
      }
      final visible = visibleFolderName(row.name, folderId);
      final hit = await _writeRestored(folderId, visible);
      if (!hit) {
        // 带 [kUniqueConstraintPrefix] 前缀 → Repository 映射成 `InputFailure`
        // （原名已被占用，是用户的输入冲突，不是读库失败）。
        throw CacheException(
          message: '${kUniqueConstraintPrefix}Folder name is taken: $visible',
        );
      }
    });
  });

  @override
  Stream<List<NoteFolder>> watchTrashed() => _guardStream(
    _dao.watchTrashed().map((rows) => rows.map(_toEntity).toList()),
  );

  /// 回收站的「永久删除」：物理删行。
  @override
  Future<void> purge(String folderId) => _guard(() async {
    final removed = await _dao.deleteById(folderId);
    if (removed == 0) {
      throw CacheException(message: 'Folder not found: $folderId');
    }
  });

  /// 清空回收站。命中 0 行**不抛**（= 已清空），与 [purge] 的语义不同。
  @override
  Future<void> purgeAllTrashed() => _guard(() => _dao.deleteAllTrashed());

  /// 恢复写入的唯一入口：UNIQUE 冲突在这里就地判掉，翻译成「名字被占」。
  ///
  /// 与 `BackupLocalDataSource._tryWriteFolder` 同一手法（那里重试改名，
  /// 这里不重试 —— 恢复时改名等于换了个文件夹）。
  Future<bool> _writeRestored(String folderId, String visibleName) async {
    try {
      return await _dao.markRestored(
        folderId,
        visibleName,
        AppClock.appNow(),
      );
    } on SqliteException {
      return false;
    } on DriftWrappedException {
      return false;
    }
  }

  @override
  Future<void> reorder(List<String> orderedFolderIds) {
    return _guard(() => _dao.updateSortIndexes(orderedFolderIds));
  }

  /// 读单行。软删除 / 恢复都要先读出当前 `name` 才能算出该写成什么
  /// —— 让出版是 `trashedFolderName(当前存储值, id)`，剥回原名是
  /// `visibleFolderName(当前存储值, id)`，两者都以**存储值**为输入。
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
    // 回收站里的 `name` 存着让出后缀（`工作#f1`），领域实体这一侧永远是干净的。
    // 条件不可省：活文件夹的名字里本来就可能有 `#`。
    name: row.deletedAt == null
        ? row.name
        : visibleFolderName(row.name, row.id),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
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

/// 流版本的 [_guard]：drift 的 `watch` 只在**流里**报错，`try/catch` 抓不到。
/// 映射规则与 [_guard] 一致（含 UNIQUE 前缀判定）；错误发出后流即关闭
/// （[Stream.handleError] 不恢复订阅）—— 读库失败是终态。
Stream<T> _guardStream<T>(Stream<T> source) {
  return source.handleError((Object e) {
    if (e is CacheException) throw e;
    if (e is SqliteException) throw CacheException(message: e.message);
    if (e is DriftWrappedException) throw CacheException(message: e.message);
    throw CacheException(message: e.toString());
  });
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
