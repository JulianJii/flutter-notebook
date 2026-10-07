import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 新建待办。业务规则：标题 trim 后非空。
///
/// ⛔ **不校验标题长度**：待办稿是单行卡片，超长由 UI 层换行 / 省略处理；凭空定一个
/// 上限（如 100）是自造产品规则（§2.4 未定义）。
/// ⛔ 不生成 uuid（传空串给 Repository）。
class CreateTodoUseCase {
  const CreateTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Todo>> call(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Todo title must not be empty')),
      );
    }
    final now = DateTime.now();
    return _repository.create(
      Todo(
        id: '',
        title: trimmed,
        isDone: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
