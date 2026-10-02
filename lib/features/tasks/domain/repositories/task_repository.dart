import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/tasks/domain/entities/task_entity.dart';

/// 读取和修改 [TaskEntity] 的契约接口。
abstract class TaskRepository {
  /// 返回所有已持久化的任务。
  Future<Either<Failure, List<TaskEntity>>> getTasks();

  /// 持久化新任务。
  Future<Either<Failure, TaskEntity>> addTask(TaskEntity task);

  /// 持久化对已有任务的更改。
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task);

  /// 根据 id 删除任务。
  Future<Either<Failure, void>> deleteTask(String id);

  /// 根据 id 切换任务的 `isCompleted` 标志。
  Future<Either<Failure, TaskEntity>> toggleTaskCompletion(String id);
}
