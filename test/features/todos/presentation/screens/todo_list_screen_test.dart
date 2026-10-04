import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/shell/notes_shell.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';
import 'package:init/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:init/features/todos/presentation/widgets/todo_card.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

/// `ToggleTodoUseCase` 在 `repo.update` 之前会 `DateTime.now()`，所以只能断言
/// 落到 Repository 层的 `Todo` 的业务字段（id / title / isDone）。
DateTime _d() => DateTime(2026, 10, 3);

Todo todo(String id, {bool isDone = false}) => Todo(
  id: id,
  title: '待办 $id',
  isDone: isDone,
  createdAt: _d(),
  updatedAt: _d(),
);

void main() {
  setUpAll(() => registerFallbackValue(todo('fallback')));

  /// override 打在 **Repository** 层（data 的边界）：既验证「Screen 只经 provider
  /// 取数」这条分层约束，又不接真实 drift 库（stream 取消时留下的 0 时长 Timer
  /// 会让每个用例挂在「A Timer is still pending」上）。
  Widget app(
    GoRouter router, {
    required Stream<List<Todo>> stream,
    Future<Either<Failure, Todo>> Function(Todo)? onUpdate,
  }) {
    final repo = _MockTodoRepository();
    when(() => repo.watchAll()).thenAnswer((_) => stream);
    when(() => repo.update(any())).thenAnswer(
      (invocation) async =>
          onUpdate?.call(invocation.positionalArguments.first as Todo) ??
          Right<Failure, Todo>(todo('t1', isDone: true)),
    );

    return ProviderScope(
      overrides: [todoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    );
  }

  /// 复刻 `app_router.dart` 的 Shell 结构 —— `/todos` 必须在
  /// `StatefulShellRoute.indexedStack` 内（ADR 5：Tab 保状态）。
  GoRouter shellRouter() {
    final router = GoRouter(
      initialLocation: AppRoutes.todos,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              NotesShell(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.notes,
                  builder: (context, state) =>
                      const Scaffold(body: Text('占位·笔记')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.todos,
                  builder: (context, state) => const TodoListScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const Scaffold(body: Text('占位·设置')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('空列表：渲染大标题与 FAB，不崩、不显示空态文案', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(const <Todo>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppLargeTitle), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppLargeTitle),
        matching: find.text('待办'),
      ),
      findsOneWidget,
    );
    expect(find.byType(TodoCard), findsNothing);
    expect(find.text('暂无待办'), findsNothing, reason: 'Q31 无稿，不建空态');
    expect(find.byType(AppFab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有数据：渲染全部待办卡', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(<Todo>[todo('t1'), todo('t2')])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TodoCard), findsNWidgets(2));
    expect(find.text('待办 t1'), findsOneWidget);
  });

  testWidgets('顶栏只有 1 个图标（settings），无 folder 图标', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(const <Todo>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppIconButton), findsOneWidget);
    expect(find.byIcon(AppIcons.settings), findsOneWidget);
    expect(find.byIcon(AppIcons.folder), findsNothing, reason: 'D2 顶栏无 folder');
  });

  testWidgets('点 settings 图标跳 /settings', (tester) async {
    final router = shellRouter();
    await tester.pumpWidget(app(router, stream: Stream.value(const <Todo>[])));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.settings));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.settings);
  });

  testWidgets('不额外渲染 AppBottomNav（Shell 渲染的那唯一一个）', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(const <Todo>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('列表容器：ListView.separated，左右 12dp，底部留出底栏高度', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(<Todo>[todo('t1'), todo('t2')])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    final card = tester.getRect(find.byType(AppCard).first);
    expect(card.left, AppSpacing.pageH);
    expect(
      card.right,
      tester.view.physicalSize.width / tester.view.devicePixelRatio -
          AppSpacing.pageH,
      reason: '通栏卡片：左右各 12dp',
    );
  });

  testWidgets('点复选框：勾选态立即变化（乐观，不等落库）', (tester) async {
    final pending = Completer<Either<Failure, Todo>>();
    final captured = <Todo>[];

    await tester.pumpWidget(
      app(
        shellRouter(),
        stream: Stream.value(<Todo>[todo('t1')]),
        onUpdate: (t) {
          captured.add(t);
          return pending.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppCheckbox));
    await tester.pump();

    expect(tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value, isTrue);
    expect(captured.single.id, 't1');
    expect(captured.single.isDone, isTrue);
    expect(captured.single.title, '待办 t1');

    pending.complete(Right(todo('t1', isDone: true)));
    await tester.pumpAndSettle();
  });

  testWidgets('落库失败：勾选态自动回弹，无 Snackbar', (tester) async {
    await tester.pumpWidget(
      app(
        shellRouter(),
        stream: Stream.value(<Todo>[todo('t1')]),
        onUpdate: (_) async =>
            const Left<Failure, Todo>(CacheFailure(message: 'disk full')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppCheckbox));
    await tester.pumpAndSettle();

    expect(tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value, isFalse);
    expect(find.byType(SnackBar), findsNothing, reason: 'Q34 无稿，不弹提示');
  });

  testWidgets('读库失败：内容区留白，不渲染错误页', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream<List<Todo>>.error(StateError('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TodoCard), findsNothing);
    expect(find.byType(TodoListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点 FAB：无跳转、无弹层、不崩（Q7 无稿）', (tester) async {
    final router = shellRouter();
    await tester.pumpWidget(app(router, stream: Stream.value(const <Todo>[])));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(router.state.uri.path, AppRoutes.todos);
  });

  testWidgets('ADR 5 防回归：/todos 在 Shell 内，切 Tab 后滚动位置保持', (tester) async {
    final router = shellRouter();
    await tester.pumpWidget(
      app(
        router,
        stream: Stream.value(<Todo>[for (var i = 1; i <= 20; i++) todo('t$i')]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, -600), 3000);
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final offset = scrollable.position.pixels;
    expect(offset, greaterThan(0), reason: '先确认真的滚动了');
    final firstVisible = tester
        .widgetList<TodoCard>(find.byType(TodoCard))
        .first;

    router.go(AppRoutes.notes);
    await tester.pumpAndSettle();
    router.go(AppRoutes.todos);
    await tester.pumpAndSettle();

    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      closeTo(offset, 1),
      reason: 'Tab 切换后滚动位置必须保持（ADR 5）',
    );
    expect(
      tester.widgetList<TodoCard>(find.byType(TodoCard)).first,
      same(firstVisible),
      reason: '同一个 Scrollable 实例 —— /todos 被挪出 Shell 就会失效',
    );
  });
}
