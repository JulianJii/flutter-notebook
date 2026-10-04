import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/presentation/providers/note_list_provider.dart';
import 'package:init/features/notes/presentation/screens/folder_manager_screen.dart';
import 'package:init/features/notes/presentation/widgets/create_folder_row.dart';
import 'package:init/features/notes/presentation/widgets/folder_row.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockFolderRepository extends Mock implements FolderRepository {}

final NoteFolder _f1 = NoteFolder(
  id: 'f1',
  name: '闻声笔记',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
final Note _note = Note(
  id: 'n1',
  title: '标题',
  content: '正文',
  createdAt: DateTime(2026, 8, 25),
  updatedAt: DateTime(2026, 8, 25),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(
      NoteFolder(
        id: '',
        name: '',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
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
  Widget app({int uncategorized = 154}) {
    final repo = _MockFolderRepository();
    when(repo.watchWithCounts).thenAnswer(
      (_) => Stream<List<FolderWithCount>>.value(<FolderWithCount>[
        FolderWithCount(folder: _f1, count: 1),
      ]),
    );
    folderRepo = repo;
    return ProviderScope(
      overrides: [
        folderRepositoryProvider.overrideWithValue(repo),
        noteListProvider.overrideWith(
          (ref, query) => Stream<List<Note>>.value(
            List<Note>.filled(
              query.folder is UncategorizedNotes ? uncategorized : 1,
              _note,
            ),
          ),
        ),
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
    // D4 的 1 + 154 = 155。
    expect(items.map((e) => e.count).toList(), <int>[155, 1, 154]);
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

  testWidgets('顶栏 trash 不可点：点击不发生任何导航', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(FolderManagerScreen), findsOneWidget);
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
