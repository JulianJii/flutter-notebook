import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_params.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/watch_todos_use_case.dart';
import 'package:init/features/todos/presentation/providers/todo_list_provider.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchTodos extends Mock implements WatchTodosUseCase {}

class MockToggleTodo extends Mock implements ToggleTodoUseCase {}

Todo todo(String id, {bool isDone = false}) => Todo(
  id: id,
  title: '待办 $id',
  isDone: isDone,
  createdAt: DateTime(2026, 10, 3),
  updatedAt: DateTime(2026, 10, 3),
);

void main() {
  setUpAll(() {
    registerFallbackValue(todo('t1'));
    registerFallbackValue(
      const ToggleTodoParams(
        todoId: 't1',
        title: '',
        isDone: false,
        reminderAt: null,
      ),
    );
  });

  ProviderContainer containerFor(
    Stream<List<Todo>> stream, {
    MockToggleTodo? toggle,
  }) {
    final watch = MockWatchTodos();
    when(() => watch(NoParams())).thenAnswer((_) => stream);
    final container = ProviderContainer(
      overrides: [
        watchTodosUseCaseProvider.overrideWithValue(watch),
        toggleTodoUseCaseProvider.overrideWithValue(toggle ?? MockToggleTodo()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// autoDispose provider 靠 listener 续命。
  void keepAlive(ProviderContainer container) {
    addTearDown(
      container
          .listen<AsyncValue<List<Todo>>>(
            todoListProvider,
            (_, _) {},
            fireImmediately: true,
          )
          .close,
    );
    addTearDown(
      container
          .listen<Map<String, bool>>(
            todoOverridesProvider,
            (_, _) {},
            fireImmediately: true,
          )
          .close,
    );
  }

  test('todoListProvider 把 UseCase 的 stream 原样暴露', () async {
    final container = containerFor(
      Stream.value(<Todo>[todo('t1'), todo('t2')]),
    );
    keepAlive(container);
    await pumpEventQueue();

    expect(container.read(todoListProvider).value, hasLength(2));
  });

  test('空列表：value 是空数组，empty 是派生不是状态', () async {
    final container = containerFor(Stream.value(const <Todo>[]));
    keepAlive(container);
    await pumpEventQueue();

    expect(container.read(todoListProvider).value, isEmpty);
  });

  test('stream 抛错：AsyncValue.hasError 为 true', () async {
    final container = containerFor(
      Stream<List<Todo>>.error(const CacheFailure(message: 'boom')),
    );
    keepAlive(container);
    await pumpEventQueue();

    expect(container.read(todoListProvider).hasError, isTrue);
    expect(container.read(todoListProvider).value, isNull);
  });

  test('toggle 立即改变展示值（乐观，不等落库）', () async {
    final toggle = MockToggleTodo();
    // 用一个永不完成的 Completer 模拟「落库还在飞」。
    final pending = Completer<Either<Failure, Todo>>();
    when(() => toggle(any())).thenAnswer((_) => pending.future);
    final container = containerFor(
      Stream.value(<Todo>[todo('t1')]),
      toggle: toggle,
    );
    keepAlive(container);
    await pumpEventQueue();

    final future = container
        .read(todoOverridesProvider.notifier)
        .toggle(todo('t1'), true);
    final shown = applyTodoOverrides(
      container.read(todoListProvider).value!,
      container.read(todoOverridesProvider),
    );

    expect(shown.single.isDone, isTrue, reason: '落库未完成时已显示新值');

    pending.complete(Right(todo('t1', isDone: true)));
    expect(await future, isTrue);
  });

  test('toggle 落库失败：回滚，展示值回到原值', () async {
    final toggle = MockToggleTodo();
    when(
      () => toggle(any()),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
    final container = containerFor(
      Stream.value(<Todo>[todo('t1')]),
      toggle: toggle,
    );
    keepAlive(container);
    await pumpEventQueue();

    final ok = await container
        .read(todoOverridesProvider.notifier)
        .toggle(todo('t1'), true);

    expect(ok, isFalse);
    final shown = applyTodoOverrides(
      container.read(todoListProvider).value!,
      container.read(todoOverridesProvider),
    );
    expect(shown.single.isDone, isFalse);
    expect(container.read(todoOverridesProvider), isEmpty);
  });

  test('stream 推来权威值后，覆盖不再改变展示值', () async {
    final toggle = MockToggleTodo();
    when(
      () => toggle(any()),
    ).thenAnswer((_) async => Right(todo('t1', isDone: true)));
    final controller = StreamController<List<Todo>>();
    final container = containerFor(controller.stream, toggle: toggle);
    controller.add(<Todo>[todo('t1')]);
    keepAlive(container);
    await pumpEventQueue();

    await container
        .read(todoOverridesProvider.notifier)
        .toggle(todo('t1'), true);

    controller.add(<Todo>[todo('t1', isDone: true)]);
    await pumpEventQueue();

    final shown = applyTodoOverrides(
      container.read(todoListProvider).value!,
      container.read(todoOverridesProvider),
    );
    expect(shown.single.isDone, isTrue);
    expect(
      container.read(todoOverridesProvider)['t1'],
      isTrue,
      reason: '覆盖可以留着：它恒等于 stream 值，视觉零影响',
    );
    await controller.close();
  });

  test('连续点同一项：覆盖值跟随最后一次 toggle', () async {
    final toggle = MockToggleTodo();
    when(() => toggle(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.single as ToggleTodoParams;
      return Right(todo(params.todoId, isDone: params.isDone));
    });
    final container = containerFor(
      Stream.value(<Todo>[todo('t1')]),
      toggle: toggle,
    );
    keepAlive(container);
    await pumpEventQueue();

    await container
        .read(todoOverridesProvider.notifier)
        .toggle(todo('t1'), true);
    await container
        .read(todoOverridesProvider.notifier)
        .toggle(todo('t1'), false);

    expect(container.read(todoOverridesProvider)['t1'], isFalse);
  });

  test('不同项的覆盖互不影响', () async {
    final toggle = MockToggleTodo();
    when(() => toggle(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.single as ToggleTodoParams;
      return Right(todo(params.todoId, isDone: params.isDone));
    });
    final container = containerFor(
      Stream.value(<Todo>[todo('t1'), todo('t2')]),
      toggle: toggle,
    );
    keepAlive(container);
    await pumpEventQueue();

    await container
        .read(todoOverridesProvider.notifier)
        .toggle(todo('t1'), true);
    final shown = applyTodoOverrides(
      container.read(todoListProvider).value!,
      container.read(todoOverridesProvider),
    );

    expect(shown.first.isDone, isTrue);
    expect(shown.last.isDone, isFalse);
  });

  test('列表顺序由 stream（DAO 的 SQL）决定，provider 不重排', () async {
    final container = containerFor(
      Stream.value(<Todo>[todo('t2'), todo('t1')]),
    );
    keepAlive(container);
    await pumpEventQueue();

    expect(
      container.read(todoListProvider).value!.map((t) => t.id).toList(),
      <String>['t2', 't1'],
    );
  });
}
