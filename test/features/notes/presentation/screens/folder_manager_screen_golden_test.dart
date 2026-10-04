import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:init/features/notes/presentation/screens/folder_manager_screen.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockFolderRepository extends Mock implements FolderRepository {}

class _MockNoteRepository extends Mock implements NoteRepository {}

/// 与 P1 / P2 / P3 三份基线同一视口（`test/features/notes/.../note_list_screen_golden_test.dart`），
/// 便于四张基线横向比对。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

/// D4 实测的三个数：`全部 155 = 闻声笔记 1 + 未分类 154`。
/// ⚠️ 全部常量 —— `DateTime.now()` 会让基线每天都不一样。
final List<FolderWithCount> _folders = <FolderWithCount>[
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

/// P4 自己不渲染笔记卡，这里只需要一个占位实体撑起未分类计数。
final Note _note = Note(
  id: 'n1',
  title: '标题',
  content: '正文',
  createdAt: DateTime(2026, 8, 25),
  updatedAt: DateTime(2026, 8, 25),
);

/// P4 不读 `/notes` 的笔记列表，但 `uncategorizedCountProvider` 经
/// `noteListProvider(NoteQuery.uncategorized())` 派生 → 必须一起 override。
const int _uncategorized = 154;

/// 只提供一条路由：`AppIconButton` 的 back / trash 都不可点（back 在
/// `canPop() == false` 时才导航，trash 永远禁用），基线不需要完整 Shell。
GoRouter _router() => GoRouter(
  initialLocation: '/notes/folders',
  routes: <RouteBase>[
    GoRoute(
      path: '/notes/folders',
      builder: (context, state) => const FolderManagerScreen(),
    ),
    GoRoute(
      path: '/notes',
      builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
    ),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(const NoteQuery()));

  testGoldenWidgets('P4 文件夹管理 — 全部 155 / 闻声笔记 1 / 未分类 154', (tester) async {
    final folderRepo = _MockFolderRepository();
    when(
      () => folderRepo.watchWithCounts(),
    ).thenAnswer((_) => Stream<List<FolderWithCount>>.value(_folders));
    final noteRepo = _MockNoteRepository();
    when(() => noteRepo.watch(any())).thenAnswer(
      (_) => Stream<List<Note>>.value(List<Note>.filled(_uncategorized, _note)),
    );

    await expectMatchTestEnvironments(
      'folder_manager_screen',
      tester: tester,
      widget: ProviderScope(
        overrides: [
          folderRepositoryProvider.overrideWithValue(folderRepo),
          noteRepositoryProvider.overrideWithValue(noteRepo),
        ],
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
