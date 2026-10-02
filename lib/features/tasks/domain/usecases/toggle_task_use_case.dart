import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/tasks/domain/entities/task_entity.dart';
import 'package:init/features/tasks/domain/repositories/task_repository.dart';

class ToggleTaskUseCase {
  final TaskRepository _repository;

  ToggleTaskUseCase(this._repository);

  Future<Either<Failure, TaskEntity>> call(String id) {
    return _repository.toggleTaskCompletion(id);
  }
}
