import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/presentation/screens/folder_manager_screen.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockFolderRepository extends Mock implements FolderRepository {}

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

/// P4 自己不渲染笔记卡，只用得到「未分类」的**计数**。计数走 DAO 的
/// `COUNT(*)` 透传，所以这里连一条假笔记都不需要。
const int _uncategorized = 154;

/// 只提供一条路由：`AppIconButton` 的 back 不可点（`canPop() == false` 时才导航），
/// 基线不需要完整 Shell。
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
  testGoldenWidgets('P4 文件夹管理 — 全部 155 / 闻声笔记 1 / 未分类 154', (tester) async {
    final folderRepo = _MockFolderRepository();
    when(
      () => folderRepo.watchWithCounts(),
    ).thenAnswer((_) => Stream<List<FolderWithCount>>.value(_folders));
    when(() => folderRepo.watchUncategorizedCount()).thenAnswer(
      (_) => Stream<int>.value(_uncategorized),
    );

    await expectMatchTestEnvironments(
      'folder_manager_screen',
      tester: tester,
      widget: ProviderScope(
        overrides: [folderRepositoryProvider.overrideWithValue(folderRepo)],
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
