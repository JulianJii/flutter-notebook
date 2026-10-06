import 'package:init/core/notifications/reminder_scheduler.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/usecases/update_todo_params.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_reminder_provider.g.dart';

/// 设置提醒的结果。UI 只负责把它翻译成一句 l10n —— provider 不碰 `BuildContext`。
enum TodoReminderResult {
  ok,

  /// 选在了过去：插件会直接抛 `ArgumentError`，必须在交给它之前拦下。
  inThePast,

  /// 用户没给通知权限。此时**不落库** —— 存了也提醒不了，不如让用户先授权。
  permissionDenied,

  /// 落库失败，或落库成功但通知没注册成功。
  failed,
}

/// 待办提醒的编排：**先落库，成功再调度**。
///
/// ⛔ 不进 `domain`：定时通知是平台能力，而 domain 禁 import Flutter；项目既有的
/// 「写操作由 provider / Screen 直接调 UseCase」在这里同样成立（见
/// `todo_list_provider.dart` 的 `TodoOverrides`）。
/// ⛔ 不做乐观更新：设置提醒是个弹窗里的显式提交，没有「先改后回滚」的必要，
/// drift 的 watch 会把新值推回来。
@riverpod
TodoReminder todoReminder(Ref ref) => TodoReminder(ref);

class TodoReminder {
  const TodoReminder(this._ref);

  final Ref _ref;

  /// 给 [todo] 设一个提醒时刻。[body] 是通知正文，由 UI 传（通知文案要本地化，
  /// provider 没有 `BuildContext`，硬编一句英文会漏进界面）。
  Future<TodoReminderResult> set(Todo todo, DateTime at, String body) async {
    if (!at.isAfter(DateTime.now())) {
      return TodoReminderResult.inThePast;
    }
    final granted = await _scheduler.requestPermission();
    if (!granted) {
      return TodoReminderResult.permissionDenied;
    }

    final saved = await _ref.read(updateTodoUseCaseProvider)(
      UpdateTodoParams(
        todoId: todo.id,
        title: todo.title,
        isDone: todo.isDone,
        reminderAt: at,
      ),
    );
    if (saved.isLeft()) return TodoReminderResult.failed;

    try {
      await _scheduler.schedule(
        id: reminderNotificationId(todo.id),
        title: todo.title,
        body: body,
        at: at,
      );
      return TodoReminderResult.ok;
    } catch (_) {
      // ⚠️ 故意**不**回滚 `reminderAt`：值已经写进库了，回滚要再写一次；这里返回
      // failed 让 UI 提示「提醒没设上」，比留一个静默失败的开关诚实。
      return TodoReminderResult.failed;
    }
  }

  /// 清除提醒。**先取消通知再落库**：反过来的话，落库成功而取消失败会留下一条
  /// 用户已经「删掉」却还会响的提醒。
  Future<TodoReminderResult> clear(Todo todo) async {
    try {
      await _scheduler.cancel(reminderNotificationId(todo.id));
    } catch (_) {
      return TodoReminderResult.failed;
    }
    final saved = await _ref.read(updateTodoUseCaseProvider)(
      UpdateTodoParams(
        todoId: todo.id,
        title: todo.title,
        isDone: todo.isDone,
        reminderAt: null,
      ),
    );
    return saved.isLeft() ? TodoReminderResult.failed : TodoReminderResult.ok;
  }

  ReminderScheduler get _scheduler => _ref.read(reminderSchedulerProvider);
}
