import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/logging/logger_provider.dart';
import 'package:mynote/core/notifications/reminder_scheduler.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/entities/todo_recurrence.dart';
import 'package:mynote/features/todos/domain/usecases/update_todo_params.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 把库里的提醒现状**投影到平台通知**。
///
/// 挂在应用根部（`main.dart`）一次即���。它同时覆盖四个入口，因为它们其实是同一件事：
/// ① 设备重启后平台侧已排的通知全丢 → 冷启动首次对账补回；
/// ② 软删除待办没撤通知 → 该行离开对账集合，`cancelAll` 顺手带走；
/// ③ 从回收站恢复待办 → 该行重新进入集合，提醒自动回来；
/// ④ 批量清除已完成 → 同 ②。
///
/// 之前这四条散在各个 Screen 里各撤一次，漏掉 ①（没有调用点）和 ③（恢复路径没撤过）
/// 是必然的 —— 漏的表现是「删掉的待办到点照响」与「恢复后不响」。收敛到一处后，
/// 新增删除入口不会再漏：它只要改库就会被这条流看见。
///
/// ponytail: listen + 150ms debounce，不是「每次写都同步一次」。一次编辑弹窗的
/// 连写（改名 → 改提醒 → 切完成）本该只触发一次平台重排；真要做到逐次精确，
/// 得在 DAO 层做脏行追踪，收益不抵复杂度。
class ReminderReconciler extends ConsumerStatefulWidget {
  const ReminderReconciler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderReconciler> createState() => _ReminderReconcilerState();
}

class _ReminderReconcilerState extends ConsumerState<ReminderReconciler> {
  StreamSubscription<List<Todo>>? _sub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 首帧后就订阅：initState 里挂 stream subscription 会在挂载途中同步 emit，
    // 触发 "setState during build"。空过一帧再开始，两种时序都能收进同一个 debounce。
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    if (!mounted) return;
    _sub = ref
        .read(watchTodosUseCaseProvider)(NoParams())
        .listen((todos) {
          _debounce?.cancel();
          _debounce = Timer(
            const Duration(milliseconds: 150),
            () => _reconcile(todos),
          );
        });
  }

  Future<void> _reconcile(List<Todo> todos) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    try {
      await scheduler.init();
    } catch (_) {
      // 平台通道起不来（桌面端首次初始化失败等）：没有提醒可管，不重试。
      return;
    }
    final now = DateTime.now();
    final body = lookupAppLocalizations(
      ref.read(appLocaleProvider),
    ).todoReminderNotificationBody;

    // 重复提醒：把过期的 `reminder_at` 往前滚，并把未来 N 场一次排上。
    // ⛔ **不 await** —— 滚动要写库，写库的 drift 流又会触发下一轮对账。
    // 同步等它会让这一轮把两件事串起来，且期间用户改标题会被覆盖。
    // 幂等：滚动是 `while (at <= now) at = next(at)`，并发跑两次结果相同。
    for (final todo in todos) {
      final recurrence = todo.recurrence;
      if (recurrence == null || todo.reminderAt == null) continue;
      if (todo.reminderAt!.isAfter(now)) continue;
      unawaited(_rollForward(todo, recurrence));
    }

    final entries = <ReminderEntry>[];
    for (final todo in todos) {
      final at = todo.reminderAt;
      if (at == null || !at.isAfter(now)) continue;
      final recurrence = todo.recurrence;
      if (recurrence == null) {
        entries.add((
          id: reminderNotificationId(todo.id),
          title: todo.title,
          body: body,
          at: at,
        ));
        continue;
      }
      // 重复：一次排 [kOccurrenceHorizon] 场，各自不同的通知 id。
      var occurrence = at;
      for (var i = 0; i < kOccurrenceHorizon; i++) {
        entries.add((
          id: occurrenceNotificationId(todo.id, i),
          title: todo.title,
          body: body,
          at: occurrence,
        ));
        occurrence = recurrence.nextAfter(occurrence);
      }
    }
    await scheduler.rescheduleAll(entries);
  }

  /// 把过期的重复提醒 `reminder_at` 往前滚到将来，并刷 `updatedAt`。
  ///
  /// ⚠️ **必须刷 `updatedAt`**：滚过之后这条待办的 `reminder_at` 变了，而
  /// `reminder_at` **不参与**合并键（`BackupTodo.version` 只看
  /// `updatedAt` / `deletedAt` / `purgedAt`）。不刷的话另一台设备算出来的
  /// 「下一次」时间戳更老，同步时会被判成本地胜出，把滚动结果覆盖回去。
  Future<void> _rollForward(Todo todo, TodoRecurrence recurrence) async {
    var at = todo.reminderAt!;
    final now = DateTime.now();
    // 上限 1000 次 ≈ 2.7 年的 daily。设上限是为了防住「recurrence 列是脏数据
    // 或时钟被拨到 2099 年」时把 CPU 烧掉 —— 那是一条坏数据，不该拖垮 App。
    for (var i = 0; i < 1000 && !at.isAfter(now); i++) {
      final next = recurrence.nextAfter(at);
      if (!next.isAfter(at)) return; // `none` 或溢出：停下，别死循环
      at = next;
    }
    final result = await ref.read(updateTodoUseCaseProvider)(
      UpdateTodoParams(
        todoId: todo.id,
        title: todo.title,
        isDone: todo.isDone,
        reminderAt: at,
        priority: todo.priority,
        recurrence: todo.recurrence,
        linkedNoteId: todo.linkedNoteId,
      ),
    );
    if (result.isLeft()) {
      ref
          .read(taggedLoggerProvider('todos'))
          .w('reminder roll-forward failed', error: result);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}