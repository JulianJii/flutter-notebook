import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/ui/app_icon.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/presentation/screens/folder_manager_screen.dart';
import 'package:mynote/features/notes/presentation/widgets/create_folder_row.dart';
import 'package:mynote/features/notes/presentation/widgets/folder_row.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockFolderRepository extends Mock implements FolderRepository {}

final NoteFolder _f1 = NoteFolder(
  id: 'f1',
  name: '闻声笔记',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
final NoteFolder _f2 = NoteFolder(
  id: 'f2',
  name: '速记',
  createdAt: DateTime(2026, 1, 2),
  updatedAt: DateTime(2026, 1, 2),
);
void main() {
  setUpAll(() {
    registerFallbackValue(
      NoteFolder(
        id: '',
        name: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    // `reorder(List<String>)` 的 ids：mocktail 的 any()/captureAny() 要它。
    registerFallbackValue(<String>[]);
  });

  late GoRouter router;
  // 提成 main 作用域的变量：`verifyNever` 必须打在**注入了的那一个** mock 上，
  // 写在 `app()` 内部新建的实例上永远是空断言。
  late FolderRepository folderRepo;

  setUp(() {
    router = GoRouter(
      initialLocation: '/notes/folders',
      routes: <RouteBase>[
        GoRoute(
          path: '/notes/folders',
          builder: (context, state) => const FolderManagerScreen(),
        ),
        GoRoute(
          path: '/notes',
          builder: (context, state) => Scaffold(
            body: Text('notes:${state.uri.queryParameters['folder'] ?? 'all'}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  /// override 打在 Repository 层（data 的边界）；**不接真实 drift 库**。
  Widget app({int uncategorized = 154, List<FolderWithCount>? folders}) {
    final repo = _MockFolderRepository();
    when(repo.watchWithCounts).thenAnswer(
      (_) => Stream<List<FolderWithCount>>.value(
        folders ?? <FolderWithCount>[FolderWithCount(folder: _f1, count: 1)],
      ),
    );
    when(() => repo.reorder(any())).thenAnswer((_) async => const Right(unit));
    // 「未分类」走 DAO 的 `COUNT(*)` 透传，不再是「取笔记列表再 .length」——
    // 所以这里 stub 的是一个标量流，不是一批假笔记。
    when(
      repo.watchUncategorizedCount,
    ).thenAnswer((_) => Stream<int>.value(uncategorized));
    folderRepo = repo;
    return ProviderScope(
      overrides: [folderRepositoryProvider.overrideWithValue(repo)],
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

  List<FolderRow> rows(WidgetTester tester) =>
      tester.widgetList<FolderRow>(find.byType(FolderRow)).toList();

  testWidgets('行序：全部 → 各文件夹 → 未分类 → 新建文件夹', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(FolderRow), findsNWidgets(3));
    expect(find.byType(CreateFolderRow), findsOneWidget);

    final items = rows(tester);
    expect(items[0].name, '全部');
    expect(items[1].name, '闻声笔记');
    expect(items[2].name, '未分类');
    // D4 的 1 + 154 = 155。真实文件夹行**没有计数**（那一位是拖动图标）。
    expect(items.map((e) => e.count).toList(), <int?>[155, null, 154]);
  });

  testWidgets('文件夹行右侧是拖动图标，且只有真实文件夹可拖', (tester) async {
    await tester.pumpWidget(
      app(
        folders: <FolderWithCount>[
          FolderWithCount(folder: _f1, count: 1),
          FolderWithCount(folder: _f2, count: 2),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 把手是唯一入口：框架内置把手已关（桌面端它会再加一个）。
    expect(find.byIcon(AppIcons.drag), findsNWidgets(2));
    expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    expect(list.buildDefaultDragHandles, isFalse);
  });

  testWidgets('拖动 → 按落点把新顺序交给 reorder', (tester) async {
    await tester.pumpWidget(
      app(
        folders: <FolderWithCount>[
          FolderWithCount(folder: _f1, count: 1),
          FolderWithCount(folder: _f2, count: 2),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 手势本身是框架的活；这里只验「落点 → ids」的换算（onReorderItem 已经
    // 扣掉被拖走的那一项，故 1 → 0 就是把第二个挪到最前）。
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(1, 0);
    await tester.pumpAndSettle();

    final captured =
        verify(() => folderRepo.reorder(captureAny())).captured.single
            as List<String>;
    expect(captured, <String>['f2', 'f1']);
  });

  testWidgets('进入页面时按 URL query 决定哪一行选中', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(rows(tester).map((e) => e.isSelected).toList(), <bool>[
      true,
      false,
      false,
    ]);

    router.go('/notes/folders?folder=f1');
    await tester.pumpAndSettle();
    expect(rows(tester).map((e) => e.isSelected).toList(), <bool>[
      false,
      true,
      false,
    ]);
  });

  testWidgets('点文件夹行跳到 /notes?folder=<id>', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('闻声笔记'));
    await tester.pumpAndSettle();

    expect(find.text('notes:f1'), findsOneWidget);
  });

  testWidgets('点「未分类」行跳到 /notes?folder=uncategorized', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('未分类'));
    await tester.pumpAndSettle();

    expect(find.text('notes:uncategorized'), findsOneWidget);
  });

  testWidgets('点「全部」行回到 /notes（不带 query）', (tester) async {
    router = GoRouter(
      initialLocation: '/notes/folders?folder=uncategorized',
      routes: <RouteBase>[
        GoRoute(
          path: '/notes/folders',
          builder: (context, state) => const FolderManagerScreen(),
        ),
        GoRoute(
          path: '/notes',
          builder: (context, state) => Scaffold(
            body: Text('notes:${state.uri.queryParameters['folder'] ?? 'all'}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    expect(find.text('notes:all'), findsOneWidget);
  });

  testWidgets('顶栏无删除图标', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('新建文件夹弹窗可输入、可取消，取消不提交', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CreateFolderRow));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '旅行');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => folderRepo.create(any()));
  });
}
