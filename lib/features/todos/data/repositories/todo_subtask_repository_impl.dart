import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:mynote/features/todos/data/datasources/todo_subtask_local_data_source.dart';
import 'package:mynote/features/todos/domain/entities/todo_subtask.dart';
import 'package:mynote/features/todos/domain/repositories/todo_subtask_repository.dart';
import 'package:uuid/uuid.dart';

/// 子项 Repository。为唯一实现（与 `TodoRepositoryImpl` 同形）。
class TodoSubtaskRepositoryImpl implements TodoSubtaskRepository {
  TodoSubtaskRepositoryImpl(this._localDataSource, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final TodoSubtaskLocalDataSource _localDataSource;
  final Uuid _uuid;

  @override
  Stream<List<TodoSubtask>> watchByTodo(String todoId) =>
      _localDataSource.watchByTodo(todoId).handleError(_toFailure);

  @override
  Future<Either<Failure, TodoSubtask>> create(TodoSubtask subtask) =>
      _guard(() async {
        final now = AppClock.appNow();
        final created = subtask.id.isEmpty
            ? TodoSubtask(
                id: _uuid.v4(),
                todoId: subtask.todoId,
                title: subtask.title,
                isDone: subtask.isDone,
                createdAt: now,
                updatedAt: now,
              )
            : subtask;
        await _localDataSource.insert(created);
        return created;
      });

  /// 每次写入都重打 [TodoSubtask.updatedAt] —— 它是跨设备合并子项勾选的键，
  /// 用调用方传的值会在「先构造实体后稍后才落库」的场景下拿到一个过期的时间戳。
  @override
  Future<Either<Failure, Unit>> update(TodoSubtask subtask) =>
      _guard<Unit>(() async {
        await _localDataSource.update(
          subtask.copyWith(updatedAt: AppClock.appNow()),
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> delete(String subtaskId) =>
      _guard<Unit>(() async {
        await _localDataSource.delete(subtaskId);
        return unit;
      });

  /// 一次 [Future] 只包一个失败，与另两个 Repository 同形。
  static Failure _toFailure(Object e) => e is CacheException
      ? CacheFailure(message: e.message)
      : CacheFailure(message: e.toString());

  static Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}