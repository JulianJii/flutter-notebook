import 'package:mynote/core/utils/app_clock.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/entities/todo_priority.dart';
import 'package:mynote/features/todos/domain/entities/todo_recurrence.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 新建待办。业务规则：标题 trim 后非空。
///
/// ⛔ **不校验标题长度**：待办稿是单行卡片，超长由 UI 层换行 / 省略处理；凭空定一个
/// 上限（如 100）是自造产品规则。
/// ⛔ 不生成 uuid（传空串给 Repository）。
class CreateTodoUseCase {
  const CreateTodoUseCase(this._repository);

  final TodoRepository _repository;

  /// [priority] / [recurrence] 是**具名可选参数**而不是 `CreateTodoParams`：
  /// ⛔ 它们各有各自的默认值（`normal` / `null`），漏传与传默认值**行为完全一致**
  /// —— 不像 `UpdateTodoParams.reminderAt` 那样「漏传 = 清空」。所以这里用默认值
  /// 是安全的，不需要一个强制表态的参数对象。UI 上没选优先级就等于普通。
  Future<Either<Failure, Todo>> call(
    String title, {
    TodoPriority priority = TodoPriority.normal,
    TodoRecurrence? recurrence,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Todo title must not be empty')),
      );
    }
    final now = AppClock.appNow();
    return _repository.create(
      Todo(
        id: '',
        title: trimmed,
        isDone: false,
        createdAt: now,
        updatedAt: now,
        priority: priority,
        recurrence: recurrence,
      ),
    );
  }
}
