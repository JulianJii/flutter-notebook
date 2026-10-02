import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/tasks/domain/entities/task_entity.dart';
import 'package:init/features/tasks/domain/repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository _repository;

  GetTasksUseCase(this._repository);

  Future<Either<Failure, List<TaskEntity>>> call() {
    return _repository.getTasks();
  }
}
