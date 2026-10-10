import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:uuid/uuid.dart';

/// 文件夹 Repository 的唯一实现。
///
/// 与 [NoteRepositoryImpl] 同构，多一处**唯一的**特殊映射：
/// UNIQUE 冲突 → `InputFailure`（重名）。判据是 datasource 打上的
/// [kUniqueConstraintPrefix] 前缀 —— 共用同一个常量，所以 Repository
/// 既不 import drift 也不 import sqlite3，SQL 细节不漏进这一层。
/// ⛔ **不预查重名**：预查 + 更新 = 两次查询 + 一个竞态窗口。
class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl(this._localDataSource, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final FolderLocalDataSource _localDataSource;
  final Uuid _uuid;

  /// 不包 `Either`（流有成败用 `AsyncValue` 表达），也不加 try —— 流错误由
  /// `handleError` 映射成 `CacheFailure`（见 [_toFailure]）。
  @override
  Stream<List<FolderWithCount>> watchWithCounts() {
    return _localDataSource.watchWithCounts().handleError(_toFailure);
  }

  @override
  Stream<int> watchUncategorizedCount() {
    return _localDataSource.watchUncategorizedCount().handleError(_toFailure);
  }

  @override
  Stream<List<NoteFolder>> watchTrashed() {
    return _localDataSource.watchTrashed().handleError(_toFailure);
  }

  @override
  Future<Either<Failure, NoteFolder>> create(NoteFolder folder) => _guard(
    () async => _localDataSource.insert(
      folder.id.isEmpty ? _withId(folder, _uuid.v4()) : folder,
    ),
  );

  @override
  Future<Either<Failure, NoteFolder>> rename(String folderId, String name) =>
      _guard(() async => _localDataSource.rename(folderId, name));

  @override
  Future<Either<Failure, Unit>> delete(String folderId) => _guard(() async {
    await _localDataSource.delete(folderId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> restore(String folderId) => _guard(() async {
    await _localDataSource.restore(folderId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> purge(String folderId) => _guard(() async {
    await _localDataSource.purge(folderId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> purgeAllTrashed() => _guard(() async {
    await _localDataSource.purgeAllTrashed();
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> reorder(List<String> orderedFolderIds) =>
      _guard(() async {
        await _localDataSource.reorder(orderedFolderIds);
        return unit;
      });

  /// 每个写方法的 `try/catch` 都长一个样，抄了六遍就成噪声了 —— 收在一处。
  ///
  /// ⚠️ 返回 `void` 的方法要在闭包里显式 `return unit`：直接把 `Future<void>`
  /// 塞进来会让 `T` 推成 `void`，与 `Either<Failure, Unit>` 不兼容。
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on CacheException catch (e) {
      return _mapFailure(e.message);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// **唯一**的判定分支，只写这一处，其余方法不复制。
  ///
  /// 判据是 datasource 打上的 [kUniqueConstraintPrefix] 前缀 —— 共用同一个常量，
  /// 所以 Repository 既不 import drift 也不 import sqlite3，SQL 细节不漏进这一层。
  ///
  /// 两条产出 `InputFailure` 的路径：建/改名撞重名，以及**恢复时原名已被占用**
  /// （用户删了「工作」、新建了另一个「工作」、再恢复旧的）。
  ///
  /// ⛔ 不靠 `message.contains('UNIQUE')` 匹配 SQLite 错误文案（drift 换版本就失效），
  /// ⛔ 不新增 Failure 类型（`CacheFailure` 之外复用既有的 `InputFailure`）。
  Either<Failure, T> _mapFailure<T>(String message) {
    return message.startsWith(kUniqueConstraintPrefix)
        ? Left(InputFailure(message: message))
        : Left(CacheFailure(message: message));
  }

  /// 流错误 → `CacheFailure`：流是异步的，`try/catch` 抓不到，只能 `handleError`。
  /// 三个 watch 都是读，撞不到 UNIQUE，所以不走 [_mapFailure]。
  ///
  /// ⚠️ `handleError` 不恢复订阅：错误发出后流即关闭，与「读库失败」的语义一致。
  Never _toFailure(Object e) => throw e is CacheException
      ? CacheFailure(message: e.message)
      : CacheFailure(message: e.toString());
}

/// 给 [folder] 补上 id。⛔ 不用 `copyWith`：`NoteFolder.copyWith` 刻意不带 `id`
/// （id 是实体身份，`TASK-014` 的设计），改实体不在本 Task 的 Scope。
NoteFolder _withId(NoteFolder folder, String id) {
  return NoteFolder(
    id: id,
    name: folder.name,
    createdAt: folder.createdAt,
    updatedAt: folder.updatedAt,
    deletedAt: folder.deletedAt,
  );
}
