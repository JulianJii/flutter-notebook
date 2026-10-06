import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:init/features/notes/presentation/screens/note_list_screen.dart';
import 'package:init/features/notes/presentation/widgets/note_card.dart';
import 'package:init/features/notes/presentation/widgets/note_masonry_grid.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

class _MockFolderRepository extends Mock implements FolderRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
  });

  List<Note> notes(int count) => <Note>[
    for (var i = 1; i <= count; i++)
      Note(
        id: 'n$i',
        title: '标题 $i',
        content: '正文 $i',
        createdAt: DateTime(2026, 8, 25),
        updatedAt: DateTime(2026, 8, 25),
      ),
  ];

  List<FolderWithCount> folders() => <FolderWithCount>[
    FolderWithCount(
      folder: NoteFolder(
        id: 'f1',
        name: '闻声笔记',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      count: 1,
    ),
  ];

  /// override 打在 **Repository** 层（data 的边界）而不是 UI provider 层 ——
  /// 这样测试同时验证了「Screen 只经 provider 取数」这条分层约束（约束 2）。
  Widget app(
    GoRouter router, {
    required Stream<List<Note>> notesStream,
    List<FolderWithCount>? folderItems,
    void Function(NoteQuery query)? onWatch,
  }) {
    final noteRepo = _MockNoteRepository();
    when(() => noteRepo.watch(any())).thenAnswer((invocation) {
      onWatch?.call(invocation.positionalArguments.first as NoteQuery);
      return notesStream;
    });
    final folderRepo = _MockFolderRepository();
    when(() => folderRepo.watchWithCounts()).thenAnswer(
      (_) => Stream<List<FolderWithCount>>.value(
        folderItems ?? const <FolderWithCount>[],
      ),
    );
    // P1 从 `settingsProvider` 读排序 / 布局 / 文字大小（TASK-047），而它经
    // `sharedPreferencesProvider` 落到插件上 —— 测试环境无插件实现，必须在
    // **Repository** 层 override（同 `settings_screen_test`）。默认值即 D1 对照态。
    final settingsRepo = _MockSettingsRepository();
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

  /// 复刻 `app_router.dart` 的 `/notes` 分支结构（不复用 `routerProvider`，
  /// 它带全局 override，是 widget 测试的噪声）。
  GoRouter routerFor(String location) {
    final router = GoRouter(
      initialLocation: location,
      routes: <RouteBase>[
        GoRoute(
          path: '/notes',
          builder: (context, state) => const NoteListScreen(),
          routes: <RouteBase>[
            GoRoute(
              path: 'new',
              builder: (context, state) => const Scaffold(body: Text('新建')),
            ),
            GoRoute(
              path: 'folders',
              builder: (context, state) => const Scaffold(body: Text('占位·文件夹')),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  Scaffold(body: Text('详情 ${state.pathParameters['id']}')),
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('占位·设置')),
        ),
      ],
    );
    addTearDown(router.dispose);
    return router;
  }

  testWidgets('空列表：渲染 chip 行与 FAB，不崩、不显示空态文案', (tester) async {
    await tester.pumpWidget(
      app(routerFor('/notes'), notesStream: Stream.value(const <Note>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NoteMasonryGrid), findsOneWidget);
    expect(find.byType(NoteCard), findsNothing);
    expect(find.text('暂无笔记'), findsNothing, reason: 'Q31 无稿，不建空态');
    expect(find.byType(AppFab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有数据：渲染全部卡片 + 顶栏标题', (tester) async {
    await tester.pumpWidget(
      app(routerFor('/notes'), notesStream: Stream.value(notes(4))),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppTopBar),
        matching: find.text('笔记'),
      ),
      findsOneWidget,
    );
    expect(find.byType(NoteCard), findsNWidgets(4));
  });

  testWidgets('点 FAB：跳到 /notes/new（Q6 按「空白编辑器」落地）', (tester) async {
    final router = routerFor('/notes');
    await tester.pumpWidget(
      app(router, notesStream: Stream.value(const <Note>[])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.noteNew);
  });

  testWidgets('分类 tab 栏：全部 + 每个文件夹 + 未分类，顺序固定', (tester) async {
    await tester.pumpWidget(
      app(
        routerFor('/notes'),
        notesStream: Stream.value(const <Note>[]),
        folderItems: folders(),
      ),
    );
    await tester.pumpAndSettle();

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final labels = tabBar.tabs.map((tab) => (tab as Tab).text).toList();

    expect(labels, <String>['全部', '闻声笔记', '未分类']);
    expect(tabBar.controller!.index, 0, reason: '默认选中「全部」');
  });

  testWidgets('点文件夹 tab：URL 变为 ?folder=<id>，选中态跟随', (tester) async {
    final router = routerFor('/notes');
    await tester.pumpWidget(
      app(
        router,
        notesStream: Stream.value(const <Note>[]),
        folderItems: folders(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('闻声笔记'));
    await tester.pumpAndSettle();

    expect(router.state.uri.queryParameters['folder'], 'f1');
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
  });

  testWidgets('点「未分类」用哨兵字面量，点「全部」清空 query', (tester) async {
    final router = routerFor('/notes?folder=uncategorized');
    await tester.pumpWidget(
      app(router, notesStream: Stream.value(const <Note>[])),
    );
    await tester.pumpAndSettle();

    expect(
      router.state.uri.queryParameters['folder'],
      'uncategorized',
      reason: '哨兵字面量在 app_routes.dart 有常量，URL 上仍是该字符串',
    );
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters.containsKey('folder'), isFalse);
  });

  testWidgets('左右滑动内容区：官方 TabBarView 切分类并写回 URL', (tester) async {
    final router = routerFor('/notes');
    await tester.pumpWidget(
      app(
        router,
        notesStream: Stream.value(const <Note>[]),
        folderItems: folders(),
      ),
    );
    await tester.pumpAndSettle();

    // 左滑一屏 → 第 2 个 tab「闻声笔记」。
    await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(router.state.uri.queryParameters['folder'], 'f1');
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
  });

  testWidgets('点卡片：跳转到 /notes/:id，参数为该笔记 id', (tester) async {
    final router = routerFor('/notes');
    await tester.pumpWidget(app(router, notesStream: Stream.value(notes(2))));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NoteCard).first);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/notes/n1');
    expect(find.text('详情 n1'), findsOneWidget);
  });

  testWidgets('顶栏只有 2 个图标按钮（搜索在内容区，不占顶栏）', (tester) async {
    await tester.pumpWidget(
      app(routerFor('/notes'), notesStream: Stream.value(const <Note>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppIconButton), findsNWidgets(2));
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.byIcon(AppIcons.folder), findsOneWidget);
    expect(find.byIcon(AppIcons.settings), findsOneWidget);
  });

  testWidgets('点顶栏图标分别去文件夹页与设置页', (tester) async {
    final router = routerFor('/notes');
    await tester.pumpWidget(
      app(router, notesStream: Stream.value(const <Note>[])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.folder));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/notes/folders');

    router.go('/notes');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.settings));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/settings');
  });

  testWidgets('不渲染 AppBottomNav（由 NotesShell 渲染一次）', (tester) async {
    await tester.pumpWidget(
      app(routerFor('/notes'), notesStream: Stream.value(const <Note>[])),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('读库失败：内容区留白，不显示错误页、不崩', (tester) async {
    await tester.pumpWidget(
      app(
        routerFor('/notes'),
        notesStream: Stream<List<Note>>.error(StateError('boom')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NoteCard), findsNothing);
    expect(find.text('暂无笔记'), findsNothing);
  });

  group('搜索（Q1 落地）', () {
    const Key field = Key('note_search_field');

    testWidgets('搜索框常驻在筛选 chip 上方，无内容时不显示清空按钮', (tester) async {
      await tester.pumpWidget(
        app(routerFor('/notes'), notesStream: Stream.value(notes(2))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(field), findsOneWidget);
      expect(find.text('搜索笔记'), findsOneWidget, reason: '空态显示占位符');

      final fieldTop = tester.getTopLeft(find.byKey(field)).dy;
      expect(
        fieldTop,
        lessThan(tester.getTopLeft(find.byType(TabBar)).dy),
        reason: '搜索框在分类 tab 栏上方',
      );
      expect(find.byIcon(AppIcons.trash), findsNothing);
    });

    testWidgets('输入：查询带上 searchTerm，清空后归回 null', (tester) async {
      final queries = <NoteQuery>[];
      await tester.pumpWidget(
        app(
          routerFor('/notes'),
          notesStream: Stream.value(const <Note>[]),
          onWatch: queries.add,
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.last.searchTerm, isNull, reason: '空搜索词不传空串');

      await tester.enterText(find.byKey(field), '花');
      await tester.pumpAndSettle();
      expect(queries.last.searchTerm, '花');
      expect(find.byIcon(AppIcons.trash), findsOneWidget, reason: '有内容才给清空');

      await tester.tap(find.byIcon(AppIcons.trash));
      await tester.pumpAndSettle();
      expect(queries.last.searchTerm, isNull);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
        reason: '清空按钮要把输入框一起清掉',
      );
    });

    testWidgets('搜索与文件夹筛选叠加，不是互斥', (tester) async {
      final queries = <NoteQuery>[];
      await tester.pumpWidget(
        app(
          routerFor('/notes?folder=f1'),
          notesStream: Stream.value(const <Note>[]),
          folderItems: folders(),
          onWatch: queries.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(field), '花');
      await tester.pumpAndSettle();

      expect(queries.last.folder, isA<SingleFolder>());
      expect((queries.last.folder as SingleFolder).folderId, 'f1');
      expect(queries.last.searchTerm, '花');
    });

    testWidgets('搜索无结果：显示「没有找到相关笔记」；无搜索词的空列表不显示', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(routerFor('/notes'), notesStream: Stream.value(const <Note>[])),
      );
      await tester.pumpAndSettle();
      expect(find.text('没有找到相关笔记'), findsNothing, reason: '空列表不是搜索无结果');

      await tester.enterText(find.byKey(field), '绝不匹配的词');
      await tester.pumpAndSettle();

      expect(find.byType(NoteCard), findsNothing);
      expect(find.text('没有找到相关笔记'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
