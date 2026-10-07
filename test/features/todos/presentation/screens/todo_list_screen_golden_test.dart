import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/shell/notes_shell.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';
import 'package:mynote/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

/// 待办稿基准视口（1080px = 360dp）。笔记列表 / 笔记详情 / 待办三份基线共用同一个，便于横向
/// 横向比对；`pixelRatio = 1.0` 让 1 dp = 1 物理像素。见 TASK-035 §2。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

/// 待办稿原样：1 张未勾选的卡。⚠️ 时间字段是常量 —— `DateTime.now()` 会让基线
/// 每天都不一样（即使本页不显示日期）。
final Todo _d2Todo = Todo(
  id: 't1',
  title: '测试',
  isDone: false,
  createdAt: DateTime(2026, 10, 3),
  updatedAt: DateTime(2026, 10, 3),
);

/// 复刻 `app_router.dart` 的 `StatefulShellRoute` 结构（**不复用 `routerProvider`** ——
/// 它带全局 override，是 golden 噪声）。必须套 `NotesShell`：待办稿的底部 2 Tab 是
/// 稿的一部分（不套就丢），且底部导航是 FAB 定位的参照物。
GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.todos,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NotesShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            // 极简占位即可：待办基线不关心笔记列表，用真 `NoteListScreen` 会把基线
            // 绑到笔记列表的数据上，多一处失败点。
            GoRoute(
              path: AppRoutes.notes,
              builder: (context, state) => const Scaffold(body: Text('notes')),
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
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(_d2Todo));

  testGoldenWidgets('待办列表 —待办稿原样形态（1 张未勾选卡）', (tester) async {
    final repo = _MockTodoRepository();
    when(
      () => repo.watchAll(),
    ).thenAnswer((_) => Stream<List<Todo>>.value(<Todo>[_d2Todo]));
    when(
      () => repo.update(any()),
    ).thenAnswer((_) async => Right<Failure, Todo>(_d2Todo));

    await expectMatchTestEnvironments(
      'todo_list_screen',
      tester: tester,
      widget: ProviderScope(
        // override 打在 Repository 层：`watchTodosUseCaseProvider` 因此根本不会
        // 被 build，真实 drift 库不会被打开。乐观覆盖层保持为空 → 锁的是**未勾选
        // 的初始态**。
        overrides: [todoRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _router(),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          debugShowCheckedModeBanner: false,
        ),
      ),
      testEnvironments: <TestEnvironment>[goldenEnv],
    );
  });

  /// 锁住本轮新增的两处视觉：顶栏的「清除已完成」入口 + 「已完成 N」折叠分隔行。
  /// 默认折叠态（`todoDoneSectionProvider.build() => false`）—— 已完成卡片不渲染，
  /// 它的删除线样式由 `todo_card_test` 的样式断言守。
  testGoldenWidgets('待办列表 — 已完成折叠分组（分隔行 + 清除入口）', (tester) async {
    final repo = _MockTodoRepository();
    when(() => repo.watchAll()).thenAnswer(
      (_) => Stream<List<Todo>>.value(<Todo>[
        _d2Todo,
        Todo(
          id: 't2',
          title: '已完成',
          isDone: true,
          createdAt: DateTime(2026, 10, 2),
          updatedAt: DateTime(2026, 10, 2),
        ),
      ]),
    );
    when(
      () => repo.update(any()),
    ).thenAnswer((_) async => Right<Failure, Todo>(_d2Todo));

    await expectMatchTestEnvironments(
      'todo_list_screen_done_section',
      tester: tester,
      widget: ProviderScope(
        overrides: [todoRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _router(),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          debugShowCheckedModeBanner: false,
        ),
      ),
      testEnvironments: <TestEnvironment>[goldenEnv],
    );
  });
}
