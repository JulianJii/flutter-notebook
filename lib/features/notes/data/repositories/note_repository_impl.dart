import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/data/datasources/note_local_data_source.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
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

  /// **不加 try**：流是异步的，`try/catch` 捕不到流错误，加了是假防护 —— 流错误
  /// 走 `handleError`（见 [_toFailure]）。
  ///
  /// 错误由 datasource 以 `Stream.error(CacheException)` 抛出，在这一层映射成
  /// `CacheFailure`：UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  @override
  Stream<List<Note>> watch(NoteQuery query) =>
      _localDataSource.watch(query).handleError(_toFailure);

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

  /// 只改背景：**不**刷新 `updatedAt`（换背景不是编辑，排序键不该跳变）。
  @override
  Future<Either<Failure, Unit>> updateBackground(
    String noteId,
    NoteBackground? background,
  ) async {
    try {
      await _localDataSource.updateBackground(noteId, background);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// 软删除：进「最近删除」。`deleted_at` 由 datasource 写 `now()`，
  /// **不**刷新 `updatedAt`（删除不是编辑，列表排序键不该因删除而跳变）。
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

  @override
  Stream<List<Note>> watchDeleted() =>
      _localDataSource.watchDeleted().handleError(_toFailure);

  @override
  Future<Either<Failure, Unit>> restore(String noteId) async {
    try {
      await _localDataSource.restore(noteId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> purge(String noteId) async {
    try {
      await _localDataSource.purge(noteId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> purgeAll() async {
    try {
      await _localDataSource.purgeAll();
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
    background: note.background,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  );
}

/// 流错误 → `CacheFailure`：流是异步的，`try/catch` 抓不到，只能 `handleError`。
/// datasource 已保证抛上来的只有 `CacheException`（drift 的原始异常不越那一层），
/// 所以这里不必再认 SQL 错误类型。
///
/// ⚠️ `handleError` 不恢复订阅：错误发出后流即关闭，与「读库失败」的语义一致。
Never _toFailure(Object e) => throw e is CacheException
    ? CacheFailure(message: e.message)
    : CacheFailure(message: e.toString());
