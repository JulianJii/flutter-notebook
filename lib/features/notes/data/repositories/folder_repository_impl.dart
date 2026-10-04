import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
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

  /// 直接透传，不包 `Either`（流有成败用 `AsyncValue` 表达），也不加 try。
  @override
  Stream<List<FolderWithCount>> watchWithCounts() {
    return _localDataSource.watchWithCounts();
  }

  @override
  Future<Either<Failure, NoteFolder>> create(NoteFolder folder) async {
    try {
      final toSave = folder.id.isEmpty ? _withId(folder, _uuid.v4()) : folder;
      return Right(await _localDataSource.insert(toSave));
    } on CacheException catch (e) {
      return _mapFailure(e.message);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteFolder>> rename(
    String folderId,
    String name,
  ) async {
    try {
      return Right(await _localDataSource.rename(folderId, name));
    } on CacheException catch (e) {
      return _mapFailure(e.message);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String folderId) async {
    try {
      await _localDataSource.delete(folderId);
      return const Right(unit);
    } on CacheException catch (e) {
      return _mapFailure(e.message);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// **唯一**的判定分支，只写这一处，其余方法不复制。
  ///
  /// ⛔ 不靠 `message.contains('UNIQUE')` 匹配 SQLite 错误文案（drift 换版本就失效），
  /// ⛔ 不新增 Failure 类型（`CacheFailure` 之外复用既有的 `InputFailure`）。
  Either<Failure, T> _mapFailure<T>(String message) {
    return message.startsWith(kUniqueConstraintPrefix)
        ? Left(InputFailure(message: message))
        : Left(CacheFailure(message: message));
  }
}

/// 给 [folder] 补上 id。⛔ 不用 `copyWith`：`NoteFolder.copyWith` 刻意不带 `id`
/// （id 是实体身份，`TASK-014` 的设计），改实体不在本 Task 的 Scope。
NoteFolder _withId(NoteFolder folder, String id) {
  return NoteFolder(
    id: id,
    name: folder.name,
    createdAt: folder.createdAt,
    updatedAt: folder.updatedAt,
  );
}
