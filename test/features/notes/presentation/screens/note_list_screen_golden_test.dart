import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/shell/notes_shell.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/presentation/screens/note_list_screen.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

class _MockFolderRepository extends Mock implements FolderRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// D1 基准视口（1080px = 360dp）。P1 / P3 / P2 三份基线共用同一个，
/// 便于横向比对；`pixelRatio = 1.0` 让 1 dp = 1 物理像素。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

DateTime _d(int m, int d) => DateTime(2026, m, d);

/// 覆盖 D1 的 4 种卡片形态：正常摘要 / 空摘要占位文案 / 纯数字标题 / 多行长摘要。
/// ⚠️ 全部常量 —— `DateTime.now()` 会让基线每天都不一样。
final List<Note> _notes = <Note>[
  Note(
    id: 'n1',
    title: '三花聚顶本是幻',
    content: '脚下腾云亦非真',
    createdAt: _d(8, 25),
    updatedAt: _d(8, 25),
  ),
  Note(
    id: 'n2',
    title: '自己现在的一切…',
    content: '',
    createdAt: _d(8, 25),
    updatedAt: _d(8, 25),
  ),
  Note(
    id: 'n3',
    title: '会员到期禁用',
    content: '修改用户名\n默认密码',
    createdAt: _d(7, 13),
    updatedAt: _d(7, 13),
  ),
  Note(
    id: 'n4',
    title: '5200',
    content: '',
    createdAt: _d(7, 4),
    updatedAt: _d(7, 4),
  ),
  Note(
    id: 'n5',
    title: '焊工',
    content: '',
    createdAt: _d(6, 29),
    updatedAt: _d(6, 29),
  ),
  Note(
    id: 'n6',
    title: '《卜算子·自嘲》',
    content: '本是后山人，偶做前堂客。\n醉舞经阁半卷书，\n坐井说天阔。',
    createdAt: _d(6, 20),
    updatedAt: _d(6, 20),
  ),
];

final List<FolderWithCount> _folders = <FolderWithCount>[
  FolderWithCount(
    folder: NoteFolder(
      id: 'f1',
      name: '闻声笔记',
      createdAt: _d(1, 1),
      updatedAt: _d(1, 1),
    ),
    count: 1,
  ),
];

/// 复刻 `app_router.dart` 的 `StatefulShellRoute` 结构（**不复用 `routerProvider`** ——
/// 它带全局 override，是 golden 噪声）。带上 `NotesShell` 才能让基线覆盖 D1 的
/// 完整页面形态（含底部 2 Tab）与 TASK-034 的 FAB 定位决策。
GoRouter _router() => GoRouter(
  initialLocation: AppRoutes.notes,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          NotesShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.notes,
              builder: (context, state) => const NoteListScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      const Scaffold(body: SizedBox.shrink()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.todos,
              builder: (context, state) =>
                  const Scaffold(body: SizedBox.shrink()),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
  });

  testGoldenWidgets('P1 笔记列表 — 有数据态', (tester) async {
    final noteRepo = _MockNoteRepository();
    when(
      () => noteRepo.watch(any()),
    ).thenAnswer((_) => Stream<List<Note>>.value(_notes));
    final folderRepo = _MockFolderRepository();
    when(
      () => folderRepo.watchWithCounts(),
    ).thenAnswer((_) => Stream<List<FolderWithCount>>.value(_folders));
    // P1 读 `settingsProvider`（TASK-047）→ 必须 override 到 Repository，否则
    // 撞上测试环境里未实现的 `sharedPreferencesProvider`。基线锁的是**默认档**
    // （`noteSort = editedDesc` / `noteLayout = grid` / `textScale = normal`
    // → 系数 1.0），故 `AppSettings.defaults()` 就是 D1 的对照态。
    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await expectMatchTestEnvironments(
      'note_list_screen',
      tester: tester,
      widget: ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(noteRepo),
          folderRepositoryProvider.overrideWithValue(folderRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
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
