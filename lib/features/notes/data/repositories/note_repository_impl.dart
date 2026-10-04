import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/data/datasources/note_local_data_source.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:uuid/uuid.dart';

/// 笔记 Repository 的唯一实现。
///
/// 沿用 `TaskRepositoryImpl` 的三条约定：字段私有 `_x`、`Uuid` 走可选命名参数、
/// `on CacheException` + `catch (e)` 双层兜底 —— **绝不把异常抛给调用方**。
///
/// ⛔ **不排序**：`ORDER BY` 在 `NoteDao` 的 SQL 里排完了（§4.2 末行）。
/// ⛔ **不记笔记标题与正文**（隐私）：本类不打日志。
class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._localDataSource, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final NoteLocalDataSource _localDataSource;
  final Uuid _uuid;

  /// 直接透传，**不加 try**：流是异步的，`try/catch` 捕不到流错误，加了是假防护。
  ///
  /// 错误由 datasource 以 `Stream.error(CacheException)` 抛出 —— UI 侧只会看到
  /// `AsyncValue.error(CacheFailure)`（`ARCHITECTURE-DESIGN.md` §6.4）。
  @override
  Stream<List<Note>> watch(NoteQuery query) => _localDataSource.watch(query);

  @override
  Future<Either<Failure, Note>> getById(String noteId) async {
    try {
      return Right(await _localDataSource.getById(noteId));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// uuid 在这里生成（UseCase 与 DataSource 都不碰 uuid）：传空串即「请你给个 id」。
  @override
  Future<Either<Failure, Note>> create(Note note) async {
    try {
      final toSave = note.id.isEmpty ? _withId(note, _uuid.v4()) : note;
      return Right(await _localDataSource.insert(toSave));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// `updatedAt` 在这里刷新 —— **创建时刻与编辑时刻是两个不同的业务事实**（§5.2）。
  ///
  /// `createdAt` 不由本方法决定：datasource 的 update 是**部分写入**，根本不碰
  /// `created_at` 列，所以库里的「首次保存时刻」不会被自动保存覆盖。
  @override
  Future<Either<Failure, Note>> update(Note note) async {
    try {
      return Right(
        await _localDataSource.update(note.copyWith(updatedAt: DateTime.now())),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// ⚠️ **裁决点（CONFLICT-10）**：删除语义由 `ARCHITECTURE-DESIGN.md` §5.4 /
  /// ADR-7 判定的**硬删除**决定。若裁决改为软删除，datasource 的
  /// `deleteById` 要换成一次 `UPDATE ... SET deleted_at`，并且**必须在同一个
  /// commit** 里加：`deleted_at` 列 + 全部查询的 `deleted_at IS NULL` 过滤 +
  /// `listTrashed` / `restore` / `purge` + 回收站页面（Q14）。
  /// 禁止只加列不加页面 —— 无页面的软删除 = 用户数据静默消失，比硬删除更糟。
  // TODO(CONFLICT-10): 删除语义待产品裁决；裁决后删掉本注释块并同步 §5.4。
  @override
  Future<Either<Failure, Unit>> delete(String noteId) async {
    try {
      await _localDataSource.delete(noteId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

/// 给 [note] 补上 id。
///
/// ⛔ 不用 `copyWith`：它刻意不带 `id`（id 是实体的身份，`TASK-014` 的设计），
/// 而改实体属 `TASK-014` 的 Scope。已有的 id 直接原样返回。
Note _withId(Note note, String id) {
  return Note(
    id: id,
    title: note.title,
    content: note.content,
    folderId: note.folderId,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  );
}
