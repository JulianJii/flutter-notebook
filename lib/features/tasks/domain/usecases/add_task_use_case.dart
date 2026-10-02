import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/tasks/domain/entities/task_entity.dart';
import 'package:init/features/tasks/domain/repositories/task_repository.dart';

class AddTaskUseCase {
  final TaskRepository _repository;

  AddTaskUseCase(this._repository);

  Future<Either<Failure, TaskEntity>> call(TaskEntity task) {
    if (task.title.trim().isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Task title cannot be empty')),
      );
    }
    return _repository.addTask(task);
  }
}
