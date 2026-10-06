import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/router/app_router.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/shell/notes_shell.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/ui/app_bottom_nav.dart';
import 'package:init/core/ui/app_icon.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:init/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:init/features/notes/presentation/screens/note_list_screen.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/presentation/screens/settings_screen.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';
import 'package:init/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

class MockFolderRepository extends Mock implements FolderRepository {}

class MockTodoRepository extends Mock implements TodoRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
  });

  // routerProvider 不再依赖 authProvider / persistentLocaleProvider，
  // 因此无需 SharedPreferences override 即可构建。
  ProviderContainer newContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  /// `/notes`、`/notes/:id`（TASK-034 / 038）、`/todos`（TASK-042）与 `/settings`
  /// （TASK-046）自这些 Task 起是**真实 Screen**，它们经 DI 连 repository / 偏好。
  /// 这里 override 到 mock 而不是接内存 SQLite / SharedPreferences：既跑得更快，也
  /// 不产生 drift 在 stream 取消时留下的 0 时长 Timer（那会让每个用例挂在
  /// 「A Timer is still pending」断言上）。
  ///
  /// 顺带：`NotesShell` 的底部导航标签现在走 l10n（§15 禁止硬编码文案），
  /// 因此 `MaterialApp` 必须挂 delegates。
  Widget app(GoRouter router) {
    final noteRepo = MockNoteRepository();
    when(
      () => noteRepo.watch(any()),
    ).thenAnswer((_) => Stream<List<Note>>.value(const <Note>[]));
    when(
      () => noteRepo.getById(any()),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'not found')));
    final folderRepo = MockFolderRepository();
    when(
      () => folderRepo.watchWithCounts(),
      // `value([])` 而不是 `empty()`：P1 等文件夹流首次出值才建 TabController。
    ).thenAnswer((_) => Stream<List<FolderWithCount>>.value(const []));
    final todoRepo = MockTodoRepository();
    when(
      () => todoRepo.watchAll(),
    ).thenAnswer((_) => const Stream<List<Todo>>.empty());

    final settingsRepo = MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
        folderRepositoryProvider.overrideWithValue(folderRepo),
        todoRepositoryProvider.overrideWithValue(todoRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
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

  testWidgets('CONFLICT-01 回归：未登录启动落在 /notes 而非 /login', (tester) async {
    await tester.pumpWidget(app(newContainer().read(routerProvider)));
    await tester.pumpAndSettle();

    expect(find.byType(NoteListScreen), findsOneWidget);
    expect(find.text('/login'), findsNothing);
  });

  testWidgets('初始位置是 /notes', (tester) async {
    final router = newContainer().read(routerProvider);
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.initial,
    );
  });

  testWidgets('6 条笔记路由全部可解析', (tester) async {
    final router = newContainer().read(routerProvider);
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    for (final path in <String>[
      AppRoutes.notes,
      AppRoutes.todos,
      AppRoutes.settings,
      AppRoutes.noteFolders,
      AppRoutes.noteNew,
      '/notes/some-id',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        path,
        reason: '$path 未匹配到任何路由',
      );
    }
  });

  test('CONFLICT-02 回归：使用 StatefulShellRoute.indexedStack', () {
    final router = newContainer().read(routerProvider);
    expect(
      router.configuration.routes.whereType<StatefulShellRoute>().length,
      1,
      reason: '缺少 StatefulShellRoute → 底部 Tab 无法保状态',
    );
    final shell = router.configuration.routes
        .whereType<StatefulShellRoute>()
        .single;
    expect(shell.branches, hasLength(2));
  });

  group('P5 路由接线（TASK-046）', () {
    test('ADR A8：P5 只在一条路径下注册（无 /notes/settings 双注册）', () {
      final router = newContainer().read(routerProvider);
      // 顶层 GoRoute（root navigator）
      expect(
        router.configuration.routes
            .whereType<GoRoute>()
            .where((route) => route.path == AppRoutes.settings)
            .length,
        1,
      );
      // 递归扫进 Shell 的子路由，确保没有第二处把 P5 挂到别的路径
      final paths = <String>[];
      void walk(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is GoRoute) {
            paths.add(route.path);
            walk(route.routes);
          }
        }
      }

      walk(router.configuration.routes);
      expect(paths.where((p) => p.endsWith('settings')), <String>['/settings']);
    });

    testWidgets('/settings 渲染真实 P5，而非占位页', (tester) async {
      final router = newContainer().read(routerProvider);
      await tester.pumpWidget(app(router));
      await tester.pumpAndSettle();

      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('占位页 · TASK-050 替换'), findsNothing);
      expect(find.text('/settings'), findsNothing);
    });

    testWidgets('P5 点返回回到 P1（返回目标是 /notes，不是 pop 空栈）', (tester) async {
      final router = newContainer().read(routerProvider);
      await tester.pumpWidget(app(router));
      await tester.pumpAndSettle();

      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.notes,
      );
      expect(find.byType(NoteListScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
    });
  });

  testWidgets('未匹配路径落到 errorBuilder 而非崩溃', (tester) async {
    final router = newContainer().read(routerProvider);
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    router.go('/nope');
    await tester.pumpAndSettle();
    expect(find.text('404 · /nope'), findsOneWidget);

    // 恢复出口跳 AppRoutes.initial（不再是旧的 /home）
    await tester.tap(find.text('返回笔记'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteListScreen), findsOneWidget);
  });

  // Shell 是 NotesShell / AppBottomNav 唯一真实宿主。
  group('NotesShell 宿主冒烟', () {
    Future<GoRouter> pumpApp(WidgetTester tester) async {
      final router = newContainer().read(routerProvider);
      await tester.pumpWidget(app(router));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('启动即笔记 Shell：真实 P1 Screen + 底部 2 Tab', (tester) async {
      await pumpApp(tester);

      expect(find.byType(NotesShell), findsOneWidget);
      expect(find.byType(NoteListScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsOneWidget);
      // 底部导航标签来自 l10n（不再是硬编码字面量）
      expect(find.text('笔记'), findsWidgets);
      expect(find.text('待办'), findsOneWidget);

      // 页面底色由主题提供（`AppTheme.scaffoldBackgroundColor`），Shell 不覆盖它
      final scaffold = tester.widget<Scaffold>(
        find
            .descendant(
              of: find.byType(NotesShell),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      expect(scaffold.backgroundColor, isNull);
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        const AppColors.light().bg,
      );
    });
    testWidgets('底部导航切 Tab：选中态跟随，点已选中的 Tab 不跳回', (tester) async {
      final router = await pumpApp(tester);
      // 按标签定位而不是按 InkWell 下标：P1 真实 Screen 自己也含多个 InkWell。
      final todoTab = find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('待办'),
      );

      await tester.tap(todoTab);
      await tester.pumpAndSettle();
      expect(find.byType(TodoListScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.todos,
      );

      // 再点已选中的第 2 项：留在原地
      await tester.tap(todoTab);
      await tester.pumpAndSettle();
      expect(find.byType(TodoListScreen), findsOneWidget);
    });

    testWidgets('顶栏 SafeArea 幂等：Shell 内不加顶部 inset', (tester) async {
      tester.view.padding = const FakeViewPadding(top: 100);
      addTearDown(tester.view.resetPadding);

      await pumpApp(tester);

      // SafeArea 已消费顶部 100px，内容区从 100 开始，不再叠加
      final navTop = tester.getRect(find.byType(AppBottomNav)).top;
      expect(
        tester.getRect(find.byType(NoteListScreen)).center.dy,
        greaterThan(100),
      );
      expect(navTop, greaterThan(0));
    });

    testWidgets('P3 是 root 层二级页：底部导航只在 Tab 主页出现', (tester) async {
      final router = await pumpApp(tester);

      router.go('/notes/some-id');
      await tester.pumpAndSettle();

      expect(find.byType(NoteDetailScreen), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      // 返回 Tab 主页后底部导航恢复。
      router.go(AppRoutes.notes);
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testWidgets('二级页返回：详情页 pop 回 P1，不抛 nothing to pop', (tester) async {
      final router = await pumpApp(tester);

      // 列表进入详情走 `push`（见 `note_list_screen.dart` 的 `openNote`），
      // 栈里有下层才能 pop —— `go` 会替换整条栈导致返回炸掉。
      router.push(AppRoutes.noteDetailPath('some-id'));
      await tester.pumpAndSettle();
      expect(find.byType(NoteDetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NoteListScreen), findsOneWidget);
    });
  });
}
