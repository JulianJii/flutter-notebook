import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';
import 'package:uuid/uuid.dart';

/// 待办 Repository 的唯一实现。与 [NoteRepositoryImpl] 同构。
///
/// ⛔ **不提供 `toggle()`**：勾选是 `isDone` 这一个字段的变更，单独开一个方法名
/// 只会让调用方多一次心智映射（`REPOSITORY-MAP.md` §1.3）。上层传**目标值**，
/// 不传「翻转」—— 重试时不会二次翻转。
class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._localDataSource, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final TodoLocalDataSource _localDataSource;
  final Uuid _uuid;

  /// 不包 `Either`（流有成败用 `AsyncValue` 表达），不加 try —— 流错误由
  /// `handleError` 映射成 `CacheFailure`（见 [_toFailure]）。
  @override
  Stream<List<Todo>> watchAll() =>
      _localDataSource.watchAll().handleError(_toFailure);

  @override
  Future<Either<Failure, Todo>> create(Todo todo) async {
    try {
      final toSave = todo.id.isEmpty ? _withId(todo, _uuid.v4()) : todo;
      return Right(await _localDataSource.insert(toSave));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// `updatedAt` 在这里刷新。`createdAt` 同样不由本方法决定：datasource 的 update
  /// 是部分写入，不碰 `created_at`，待办不会在 `createdAt DESC` 的列表里跳位。
  @override
  Future<Either<Failure, Todo>> update(Todo todo) async {
    try {
      return Right(
        await _localDataSource.update(todo.copyWith(updatedAt: DateTime.now())),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String todoId) async {
    try {
      await _localDataSource.delete(todoId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteCompleted() async {
    try {
      return Right(await _localDataSource.deleteCompleted());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

/// 给 [todo] 补上 id。⛔ 不用 `copyWith`：`Todo.copyWith` 刻意不带 `id`
/// （id 是实体身份，`TASK-014` 的设计），改实体不在本 Task 的 Scope。
Todo _withId(Todo todo, String id) {
  return Todo(
    id: id,
    title: todo.title,
    isDone: todo.isDone,
    reminderAt: todo.reminderAt,
    createdAt: todo.createdAt,
    updatedAt: todo.updatedAt,
  );
}

/// 流错误 → `CacheFailure`：流是异步的，`try/catch` 抓不到，只能 `handleError`。
/// datasource 已保证抛上来的只有 `CacheException`（drift 的原始异常不越那一层）。
///
/// ⚠️ `handleError` 不恢复订阅：错误发出后流即关闭，与「读库失败」的语义一致。
Never _toFailure(Object e) => throw e is CacheException
    ? CacheFailure(message: e.message)
    : CacheFailure(message: e.toString());
