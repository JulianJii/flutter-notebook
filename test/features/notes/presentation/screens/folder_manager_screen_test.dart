import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
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
  ///
  /// [createResult] 是新建文件夹的写库结果（默认成功）—— 失败分支要在建 widget
  /// **之前**就 stub 好，mock 只在 `app()` 里建。
  Widget app({List<FolderWithCount>? folders, Either<Failure, NoteFolder>? createResult}) {
    final repo = _MockFolderRepository();
    when(repo.watchWithCounts).thenAnswer(
      (_) => Stream<List<FolderWithCount>>.value(
        folders ?? <FolderWithCount>[FolderWithCount(folder: _f1, count: 1)],
      ),
    );
    when(() => repo.reorder(any())).thenAnswer((_) async => const Right(unit));
    when(() => repo.delete(any())).thenAnswer((_) async => const Right(unit));
    when(
      () => repo.create(any()),
    ).thenAnswer((_) async => createResult ?? Right<Failure, NoteFolder>(_f1));
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

  testWidgets('行序：各真实文件夹 → 新建文件夹；没有「全部」「未分类」，也没有计数', (tester) async {
    await tester.pumpWidget(
      app(
        folders: <FolderWithCount>[
          FolderWithCount(folder: _f1, count: 1),
          FolderWithCount(folder: _f2, count: 2),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FolderRow), findsNWidgets(2));
    expect(find.byType(CreateFolderRow), findsOneWidget);
    expect(rows(tester).map((e) => e.name).toList(), <String>['闻声笔记', '速记']);
    // 「全部」「未分类」是笔记列表的分类 tab，本页不列；行内也不显示笔记数。
    expect(find.text('全部'), findsNothing);
    expect(find.text('未分类'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
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

    expect(rows(tester).map((e) => e.isSelected).toList(), <bool>[false]);

    router.go('/notes/folders?folder=f1');
    await tester.pumpAndSettle();
    expect(rows(tester).map((e) => e.isSelected).toList(), <bool>[true]);
  });

  testWidgets('点文件夹行跳到 /notes?folder=<id>', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('闻声笔记'));
    await tester.pumpAndSettle();

    expect(find.text('notes:f1'), findsOneWidget);
  });

  testWidgets('顶栏无删除图标', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  /// 删除入口是**长按**：行内 `trailing` 已被拖拽手柄占满，加图标会挤掉拖拽区
  /// （`FolderRow` 有测试钉住布局），而多选态要新增选中态 —— 长按是唯一不改动
  /// 现有视觉的选项。
  testWidgets('长按文件夹弹菜单 → 确认 → 软删除', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('闻声笔记'));
    await tester.pumpAndSettle();
    expect(find.text('删除文件夹'), findsOneWidget);

    await tester.tap(find.text('删除文件夹'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    verify(() => folderRepo.delete('f1')).called(1);
    expect(find.text('已移入回收站'), findsOneWidget);
  });

  testWidgets('菜单里取消 → 确认框都不出现，不写库', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('闻声笔记'));
    await tester.pumpAndSettle();
    // 底部菜单关闭（点菜单外的「新建文件夹」行触发 pop 不可靠，直接用
    // 系统返回 —— 与用户实际按返回键一致）。
    final back = tester.state<NavigatorState>(find.byType(Navigator).first);
    back.pop();
    await tester.pumpAndSettle();

    verifyNever(() => folderRepo.delete(any()));
  });

  testWidgets('确认框点取消 → 不写库', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('闻声笔记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除文件夹'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => folderRepo.delete(any()));
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

  /// 弹窗内联校验：报错显示在输入框下方、**弹窗不关**，改完直接再提交。
  testWidgets('空名 / 超长 / 重名 → 就地报错且不写库；合法名 → 提交 trim 后的值', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CreateFolderRow));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    final field = find.byType(TextField);
    final save = find.widgetWithText(TextButton, '保存');

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('请输入文件夹名称'), findsOneWidget);

    await tester.enterText(field, '名' * 41);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('文件夹名称不能超过 40 个字符'), findsOneWidget);

    // 库里已有「闻声笔记」（`_f1`）。
    await tester.enterText(field, '闻声笔记');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('已存在同名文件夹'), findsOneWidget);
    expect(dialog, findsOneWidget, reason: '弹窗不关：用户改个名就能接着提交');
    verifyNever(() => folderRepo.create(any()));

    await tester.enterText(field, ' 旅行 ');
    await tester.tap(save);
    await tester.pumpAndSettle();

    final created =
        verify(() => folderRepo.create(captureAny())).captured.single
            as NoteFolder;
    expect(created.name, '旅行', reason: '两端空格在提交前 trim');
    expect(dialog, findsNothing);
  });

  /// 弹窗打开期间名字被占（导入 / 恢复）→ 库里的 UNIQUE 冲突回来的是
  /// `InputFailure`，弹给用户的必须是本地化文案，不是 SQL 原文。
  testWidgets('写库撞重名 → SnackBar 是本地化文案', (tester) async {
    await tester.pumpWidget(
      app(
        createResult: const Left(
          InputFailure(
            message: 'UNIQUE: UNIQUE constraint failed: note_folders.name',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CreateFolderRow));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '旅行');
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('已存在同名文件夹'), findsOneWidget);
    expect(find.textContaining('UNIQUE'), findsNothing);
  });
}
