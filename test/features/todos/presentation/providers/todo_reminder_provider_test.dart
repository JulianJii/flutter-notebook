import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/notifications/reminder_scheduler.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/usecases/update_todo_params.dart';
import 'package:init/features/todos/domain/usecases/update_todo_use_case.dart';
import 'package:init/features/todos/presentation/providers/todo_reminder_provider.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockReminderScheduler extends Mock implements ReminderScheduler {}

class MockUpdateTodo extends Mock implements UpdateTodoUseCase {}

void main() {
  final now = DateTime(2026, 10, 7, 12);

  Todo todo({DateTime? reminderAt}) => Todo(
    id: 't1',
    title: '买牛奶',
    createdAt: now,
    updatedAt: now,
    reminderAt: reminderAt,
  );

  setUpAll(() {
    registerFallbackValue(
      const UpdateTodoParams(
        todoId: 't1',
        title: '',
        isDone: false,
        reminderAt: null,
      ),
    );
  });

  late MockReminderScheduler scheduler;
  late MockUpdateTodo update;

  ProviderContainer containerFor({
    bool permission = true,
    Future<void> Function()? onSchedule,
    Future<void> Function()? onCancel,
  }) {
    scheduler = MockReminderScheduler();
    update = MockUpdateTodo();
    when(
      () => scheduler.requestPermission(),
    ).thenAnswer((_) async => permission);
    when(
      () => scheduler.schedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        at: any(named: 'at'),
      ),
    ).thenAnswer((_) async => onSchedule?.call());
    when(
      () => scheduler.cancel(any()),
    ).thenAnswer((_) async => onCancel?.call());
    // 只回一个固定实体：本测试断言的是「传给 UseCase 的参数」和「有没有调调度器」，
    // 返回值不影响分支。
    when(
      () => update(any()),
    ).thenAnswer((_) async => Right<Failure, Todo>(todo()));

    final container = ProviderContainer(
      overrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
        updateTodoUseCaseProvider.overrideWithValue(update),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('设置成功：先落库再调度，通知 id 由待办 id 派生', () async {
    final container = containerFor();
    final at = DateTime.now().add(const Duration(hours: 1));

    final result = await container
        .read(todoReminderProvider)
        .set(todo(), at, '提醒正文');

    expect(result, TodoReminderResult.ok);
    final captured =
        verify(() => update(captureAny())).captured.single as UpdateTodoParams;
    expect(captured.reminderAt, at);
    verify(
      () => scheduler.schedule(
        id: reminderNotificationId('t1'),
        title: '买牛奶',
        body: '提醒正文',
        at: at,
      ),
    ).called(1);
  });

  test('选了过去的时刻：不落库、不调度', () async {
    final container = containerFor();

    // ⚠️ 必须用真实时钟：`now` 是 2026-10-07 12:00 这类固定值，机器时间比它早时
    // 「减一分钟」仍然是将来，断言就假失败了。
    final result = await container
        .read(todoReminderProvider)
        .set(todo(), DateTime.now().subtract(const Duration(minutes: 1)), 'x');

    expect(result, TodoReminderResult.inThePast);
    verifyNever(() => update(any()));
    verifyNever(
      () => scheduler.schedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        at: any(named: 'at'),
      ),
    );
  });

  test('没给通知权限：不落库（存了也提醒不了）', () async {
    final container = containerFor(permission: false);

    final result = await container
        .read(todoReminderProvider)
        .set(todo(), DateTime.now().add(const Duration(hours: 1)), 'x');

    expect(result, TodoReminderResult.permissionDenied);
    verifyNever(() => update(any()));
  });

  test('落库失败：不算设置成功，也不调度', () async {
    final container = containerFor();
    when(() => update(any())).thenAnswer(
      (_) async =>
          const Left<Failure, Todo>(CacheFailure(message: 'disk full')),
    );

    final result = await container
        .read(todoReminderProvider)
        .set(todo(), DateTime.now().add(const Duration(hours: 1)), 'x');

    expect(result, TodoReminderResult.failed);
    verifyNever(
      () => scheduler.schedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        at: any(named: 'at'),
      ),
    );
  });

  test('落库成功但调度抛异常：返回 failed（值已入库，交给 UI 提示）', () async {
    final container = containerFor(
      onSchedule: () => throw StateError('no alarm permission'),
    );

    final result = await container
        .read(todoReminderProvider)
        .set(todo(), DateTime.now().add(const Duration(hours: 1)), 'x');

    expect(result, TodoReminderResult.failed);
    verify(() => update(any())).called(1);
  });

  test('清除：先取消通知再落库 null', () async {
    final container = containerFor();

    final result = await container
        .read(todoReminderProvider)
        .clear(todo(reminderAt: DateTime.now().add(const Duration(hours: 1))));

    expect(result, TodoReminderResult.ok);
    verify(() => scheduler.cancel(reminderNotificationId('t1'))).called(1);
    final captured =
        verify(() => update(captureAny())).captured.single as UpdateTodoParams;
    expect(captured.reminderAt, isNull);
  });

  test('取消通知失败：不往下写库（免得留下还会响的提醒）', () async {
    final container = containerFor(
      onCancel: () => throw StateError('plugin down'),
    );

    final result = await container
        .read(todoReminderProvider)
        .clear(todo(reminderAt: DateTime.now().add(const Duration(hours: 1))));

    expect(result, TodoReminderResult.failed);
    verifyNever(() => update(any()));
  });
}
