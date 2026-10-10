import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/presentation/screens/folder_manager_screen.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockFolderRepository extends Mock implements FolderRepository {}

/// 与笔记列表 / 待办 / 笔记详情三份基线同一视口（`test/features/notes/.../note_list_screen_golden_test.dart`），
/// 便于四张基线横向比对。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

/// 一个真实文件夹（`count` 已不在行内显示，但实体照旧带它）。
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
  testGoldenWidgets('文件夹管理 — 只有真实文件夹 + 新建文件夹，行内无计数', (tester) async {
    final folderRepo = _MockFolderRepository();
    when(
      () => folderRepo.watchWithCounts(),
    ).thenAnswer((_) => Stream<List<FolderWithCount>>.value(_folders));

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
