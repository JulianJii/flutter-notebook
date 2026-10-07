import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/shell/notes_shell.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';
import 'package:mynote/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:mynote/features/todos/presentation/widgets/todo_card.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
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
    Future<Either<Failure, Todo>> Function(Todo)? onCreate,
    Future<Either<Failure, Unit>> Function(String)? onDelete,
    Future<Either<Failure, int>> Function()? onDeleteCompleted,
  }) {
    final repo = _MockTodoRepository();
    when(() => repo.watchAll()).thenAnswer((_) => stream);
    when(() => repo.create(any())).thenAnswer(
      (invocation) async =>
          onCreate?.call(invocation.positionalArguments.first as Todo) ??
          Right<Failure, Todo>(todo('created')),
    );
    when(() => repo.update(any())).thenAnswer(
      (invocation) async =>
          onUpdate?.call(invocation.positionalArguments.first as Todo) ??
          Right<Failure, Todo>(todo('t1', isDone: true)),
    );
    when(() => repo.delete(any())).thenAnswer(
      (invocation) async =>
          onDelete?.call(invocation.positionalArguments.first as String) ??
          const Right<Failure, Unit>(unit),
    );
    when(() => repo.deleteCompleted()).thenAnswer(
      (_) async => onDeleteCompleted?.call() ?? const Right<Failure, int>(0),
    );

    return ProviderScope(
      overrides: [todoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
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

  testWidgets('空列表：顶栏渲染「待办」标题与 FAB，内容区显示空态文案', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(const <Todo>[])),
    );
    await tester.pumpAndSettle();

    // 标题在顶栏内（形态 A'），不再另起一行大标题。
    expect(find.byType(AppLargeTitle), findsNothing);
    expect(
      find.descendant(of: find.byType(AppTopBar), matching: find.text('待办')),
      findsOneWidget,
    );
    expect(find.byType(TodoCard), findsNothing);
    expect(find.text('还没有待办'), findsOneWidget);
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

  testWidgets('顶栏只有 trash + settings 两个图标，无 folder 图标', (tester) async {
    await tester.pumpWidget(
      app(shellRouter(), stream: Stream.value(const <Todo>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppIconButton), findsNWidgets(2));
    expect(find.byIcon(AppIcons.settings), findsOneWidget);
    expect(find.byIcon(AppIcons.trash), findsOneWidget);
    expect(find.byIcon(AppIcons.folder), findsNothing, reason: '待办稿顶栏无 folder');
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

    // 乐观值立即生效：卡片当场归入「已完成」分组（默认折叠 → 不再渲染），
    // 不等落库。
    expect(find.text('已完成 1'), findsOneWidget);
    expect(captured.single.id, 't1');
    expect(captured.single.isDone, isTrue);
    expect(captured.single.title, '待办 t1');

    pending.complete(Right(todo('t1', isDone: true)));
    await tester.pumpAndSettle();
  });

  testWidgets('落库失败：勾选态自动回弹并弹 Snackbar', (tester) async {
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
    expect(find.text('勾选没有保存成功，已恢复原状态'), findsOneWidget);
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

  testWidgets('点 FAB：弹新建对话框，保存后写入一条未完成待办', (tester) async {
    final created = <Todo>[];
    final router = shellRouter();
    await tester.pumpWidget(
      app(
        router,
        stream: Stream.value(const <Todo>[]),
        onCreate: (t) async {
          created.add(t);
          return Right<Failure, Todo>(t);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('新建待办'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  买牛奶  ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(created.single.title, '买牛奶', reason: '标题经 use case trim');
    expect(created.single.isDone, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
    expect(router.state.uri.path, AppRoutes.todos, reason: '原地新建，不跳转');
    expect(tester.takeException(), isNull);
  });

  testWidgets('新建：取消 / 空标题都不写库', (tester) async {
    final created = <Todo>[];
    final router = shellRouter();
    await tester.pumpWidget(
      app(
        router,
        stream: Stream.value(const <Todo>[]),
        onCreate: (t) async {
          created.add(t);
          return Right<Failure, Todo>(t);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(created, isEmpty);
    expect(find.byType(SnackBar), findsNothing, reason: '空输入本地拦下，不算失败');
  });

  testWidgets('新建失败：弹 Snackbar 提示 failure 文案', (tester) async {
    final router = shellRouter();
    await tester.pumpWidget(
      app(
        router,
        stream: Stream.value(const <Todo>[]),
        onCreate: (_) async =>
            const Left<Failure, Todo>(CacheFailure(message: 'disk full')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '买牛奶');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('disk full'), findsOneWidget);
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

  group('编辑 / 删除入口（点卡片）', () {
    Future<void> pumpOneTodo(
      WidgetTester tester, {
      required GoRouter router,
      bool isDone = false,
      Future<Either<Failure, Todo>> Function(Todo)? onUpdate,
      Future<Either<Failure, Unit>> Function(String)? onDelete,
    }) async {
      await tester.pumpWidget(
        app(
          router,
          stream: Stream.value(<Todo>[todo('t1', isDone: isDone)]),
          onUpdate: onUpdate,
          onDelete: onDelete,
        ),
      );
      await tester.pumpAndSettle();
    }

    /// 点卡片 → 详情小窗（提醒 / 完成），再点小窗里的铅笔 → 原来的编辑弹窗。
    ///
    /// ⚠️ 小窗**不自己关**：编辑弹窗叠在它上面，关掉弹窗还能接着设提醒。
    Future<void> openEditDialog(WidgetTester tester) async {
      await tester.tap(find.byType(TodoCard));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byTooltip('编辑待办'));
      await tester.pumpAndSettle();
    }

    testWidgets('点卡片：先弹详情小窗，再点铅笔弹编辑弹窗（预填当前标题）', (tester) async {
      await pumpOneTodo(tester, router: shellRouter());

      await tester.tap(find.byType(TodoCard));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('提醒时间'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);

      await tester.tap(find.byTooltip('编辑待办'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('编辑待办'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '待办 t1',
        reason: '输入框预填当前标题',
      );
      expect(find.text('删除待办'), findsOneWidget);
    });

    testWidgets('改标题保存：update 收到新标题，且保留 isDone', (tester) async {
      final saved = <Todo>[];
      await pumpOneTodo(
        tester,
        router: shellRouter(),
        isDone: true,
        onUpdate: (t) async {
          saved.add(t);
          return Right<Failure, Todo>(t);
        },
      );
      // 已完成项默认折叠，先展开才能点到卡片。
      await tester.tap(find.text('已完成 1'));
      await tester.pumpAndSettle();

      await openEditDialog(tester);
      await tester.enterText(find.byType(TextField), '买牛奶');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(saved.single.title, '买牛奶');
      expect(
        saved.single.isDone,
        isTrue,
        reason: 'update 是全量覆盖写，漏传 isDone 会把已完成态抹掉',
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('取消 / 空标题都不写库', (tester) async {
      final saved = <Todo>[];
      final router = shellRouter();
      await pumpOneTodo(
        tester,
        router: router,
        onUpdate: (t) async {
          saved.add(t);
          return Right<Failure, Todo>(t);
        },
      );

      await openEditDialog(tester);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // 小窗没关，再点铅笔就能重新开编辑弹窗（不用退到列表）。
      await tester.tap(find.byTooltip('编辑待办'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(saved, isEmpty);
      expect(find.byType(SnackBar), findsNothing, reason: '空输入本地拦下');
    });

    testWidgets('编辑失败：弹 Snackbar 提示 failure 文案', (tester) async {
      await pumpOneTodo(
        tester,
        router: shellRouter(),
        onUpdate: (_) async =>
            const Left<Failure, Todo>(CacheFailure(message: 'disk full')),
      );

      await openEditDialog(tester);
      await tester.enterText(find.byType(TextField), '买牛奶');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('disk full'), findsOneWidget);
    });

    testWidgets('删除：先二次确认，确认后 delete 收到该待办 id', (tester) async {
      final deleted = <String>[];
      await pumpOneTodo(
        tester,
        router: shellRouter(),
        onDelete: (id) async {
          deleted.add(id);
          return const Right<Failure, Unit>(unit);
        },
      );

      await openEditDialog(tester);
      await tester.tap(find.text('删除待办'));
      await tester.pumpAndSettle();

      expect(find.text('确定要删除这条待办吗？此操作无法撤销。'), findsOneWidget);
      expect(deleted, isEmpty, reason: '确认前不许写库');

      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(deleted, <String>['t1']);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('删除确认点取消：不写库', (tester) async {
      final deleted = <String>[];
      await pumpOneTodo(
        tester,
        router: shellRouter(),
        onDelete: (id) async {
          deleted.add(id);
          return const Right<Failure, Unit>(unit);
        },
      );

      await openEditDialog(tester);
      await tester.tap(find.text('删除待办'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(deleted, isEmpty);
      expect(find.byType(TodoCard), findsOneWidget);
    });

    testWidgets('删除失败：弹 Snackbar', (tester) async {
      await pumpOneTodo(
        tester,
        router: shellRouter(),
        onDelete: (_) async =>
            const Left<Failure, Unit>(CacheFailure(message: 'boom')),
      );

      await openEditDialog(tester);
      await tester.tap(find.text('删除待办'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.text('boom'), findsOneWidget);
      expect(find.byType(TodoCard), findsOneWidget);
    });
  });

  group('已完成折叠分组 + 清除已完成', () {
    Future<void> pumpMixed(
      WidgetTester tester, {
      required GoRouter router,
      Future<Either<Failure, int>> Function()? onDeleteCompleted,
    }) async {
      await tester.pumpWidget(
        app(
          router,
          stream: Stream.value(<Todo>[todo('t1'), todo('d1', isDone: true)]),
          onDeleteCompleted: onDeleteCompleted,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('默认折叠：分隔行显示计数，已完成卡片不渲染', (tester) async {
      await pumpMixed(tester, router: shellRouter());

      expect(find.text('已完成 1'), findsOneWidget);
      expect(find.text('待办 t1'), findsOneWidget);
      expect(find.text('待办 d1'), findsNothing);
      expect(find.byType(TodoCard), findsOneWidget);
    });

    testWidgets('点分隔行展开：已完成卡片出现，再点收起', (tester) async {
      await pumpMixed(tester, router: shellRouter());

      await tester.tap(find.text('已完成 1'));
      await tester.pumpAndSettle();
      expect(find.text('待办 d1'), findsOneWidget);
      expect(find.byType(TodoCard), findsNWidgets(2));

      await tester.tap(find.text('已完成 1'));
      await tester.pumpAndSettle();
      expect(find.text('待办 d1'), findsNothing);
    });

    testWidgets('已完成项在未完成项之后（保序切分，不重排）', (tester) async {
      await pumpMixed(tester, router: shellRouter());
      await tester.tap(find.text('已完成 1'));
      await tester.pumpAndSettle();

      final order = tester
          .widgetList<TodoCard>(find.byType(TodoCard))
          .map((c) => c.title)
          .toList();
      expect(order, <String>['待办 t1', '待办 d1']);
    });

    testWidgets('清除已完成：二次确认 → 调 deleteCompleted → 提示已清空', (tester) async {
      var calls = 0;
      await pumpMixed(
        tester,
        router: shellRouter(),
        onDeleteCompleted: () async {
          calls++;
          return const Right<Failure, int>(1);
        },
      );

      await tester.tap(find.byIcon(AppIcons.trash));
      await tester.pumpAndSettle();
      expect(calls, 0, reason: '确认前不许写库');
      expect(find.text('确定要清除全部已完成的待办吗？此操作无法撤销。'), findsOneWidget);

      await tester.tap(find.text('清除已完成').last);
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('已清空'), findsOneWidget);
    });

    testWidgets('清除已完成点取消：不写库', (tester) async {
      var calls = 0;
      await pumpMixed(
        tester,
        router: shellRouter(),
        onDeleteCompleted: () async {
          calls++;
          return const Right<Failure, int>(1);
        },
      );

      await tester.tap(find.byIcon(AppIcons.trash));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.text('已完成 1'), findsOneWidget);
    });

    testWidgets('清除已完成失败：弹 Snackbar', (tester) async {
      await pumpMixed(
        tester,
        router: shellRouter(),
        onDeleteCompleted: () async =>
            const Left<Failure, int>(CacheFailure(message: 'disk full')),
      );

      await tester.tap(find.byIcon(AppIcons.trash));
      await tester.pumpAndSettle();
      await tester.tap(find.text('清除已完成').last);
      await tester.pumpAndSettle();

      expect(find.text('disk full'), findsOneWidget);
    });

    testWidgets('无已完成项时清除按钮禁用', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          shellRouter(),
          stream: Stream.value(<Todo>[todo('t1')]),
          onDeleteCompleted: () async {
            calls++;
            return const Right<Failure, int>(1);
          },
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<AppIconButton>(
        find.ancestor(
          of: find.byIcon(AppIcons.trash),
          matching: find.byType(AppIconButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(find.text('已完成 1'), findsNothing, reason: '空分组不画分隔行');
      expect(calls, 0);
    });
  });
}
