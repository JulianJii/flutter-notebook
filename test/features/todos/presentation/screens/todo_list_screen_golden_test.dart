import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/shell/notes_shell.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';
import 'package:init/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockTodoRepository extends Mock implements TodoRepository {}

/// D2 基准视口（1080px = 360dp）。P1 / P3 / P2 三份基线共用同一个，便于横向
/// 横向比对；`pixelRatio = 1.0` 让 1 dp = 1 物理像素。见 TASK-035 §2。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

/// D2 原样：1 张未勾选的卡。⚠️ 时间字段是常量 —— `DateTime.now()` 会让基线
/// 每天都不一样（即使本页不显示日期）。
final Todo _d2Todo = Todo(
  id: 't1',
  title: '测试',
  isDone: false,
  createdAt: DateTime(2026, 10, 3),
  updatedAt: DateTime(2026, 10, 3),
);

/// 复刻 `app_router.dart` 的 `StatefulShellRoute` 结构（**不复用 `routerProvider`** ——
/// 它带全局 override，是 golden 噪声）。必须套 `NotesShell`：D2 的底部 2 Tab 是
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
            // 极简占位即可：P2 基线不关心笔记列表，用真 `NoteListScreen` 会把基线
            // 绑到 P1 的数据上，多一处失败点。
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

  testGoldenWidgets('P2 待办列表 — D2 原样形态（1 张未勾选卡）', (tester) async {
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
          theme: AppTheme.lightTheme,
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
