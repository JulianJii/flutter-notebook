import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/usecases/create_note_params.dart';
import 'package:init/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/update_note_params.dart';
import 'package:init/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:init/features/notes/presentation/providers/note_editor_provider.dart';
import 'package:init/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockGetNote extends Mock implements GetNoteUseCase {}

class _MockUpdateNote extends Mock implements UpdateNoteUseCase {}

class _MockCreateNote extends Mock implements CreateNoteUseCase {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// 与 P1 基线**完全一致**的视口，全项目统一（见 TASK-035 §2）。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

/// ⚠️ 固定常量 —— `DateTime.now()` 会让基线每天都不一样。D3 的「10月3日 6:40」。
final DateTime _fixed = DateTime(2026, 10, 3, 6, 40);

/// D3 原样形态：**空标题 + 有正文**（5 段 = 35 字）。
final Note _d3Note = Note(
  id: 'n1',
  title: '',
  content: '三花聚顶本是幻\n\n脚下腾云亦非真\n\n人若不为形所累\n\n眼前便是大罗天\n\n一九玄关显秘论',
  createdAt: _fixed,
  updatedAt: _fixed,
);

/// 复刻 `app_router.dart` 的 `/notes` 分支（**不复用 `routerProvider`**）。
/// 套一层 `/notes` 父路由是为了让 `context.pop()` 有上一页可退。
/// ⚠️ 不套 `NotesShell` / `AppBottomNav`：P3 是二级 Push 页，D3 无底部导航。
GoRouter _router() => GoRouter(
  initialLocation: '/notes/n1',
  routes: <RouteBase>[
    GoRoute(
      path: '/notes',
      builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      routes: <RouteBase>[
        GoRoute(
          path: 'new',
          builder: (context, state) =>
              const NoteDetailScreen(noteId: kNewNoteId),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              NoteDetailScreen(noteId: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_d3Note);
    registerFallbackValue(
      const UpdateNoteParams(noteId: 'n1', title: '', content: ''),
    );
    registerFallbackValue(const CreateNoteParams(title: '', content: ''));
    registerFallbackValue(const AppSettings.defaults());
  });

  testGoldenWidgets('P3 笔记详情 — D3 原样形态（空标题 + 有正文）', (tester) async {
    final get = _MockGetNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_d3Note));
    final update = _MockUpdateNote();
    when(() => update(any())).thenAnswer((_) async => Right(_d3Note));
    final create = _MockCreateNote();
    when(() => create(any())).thenAnswer((_) async => Right(_d3Note));
    // P3 读 `settingsProvider` 的「文字大小」（TASK-047）→ 必须 override 到
    // Repository，否则会撞上测试环境里未实现的 `sharedPreferencesProvider`。
    // 基线锁的是**默认档**（`textScale = normal` → 系数 1.0），故此处的
    // `AppSettings.defaults()` 就是 D3 的对照值。
    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await expectMatchTestEnvironments(
      'note_detail_screen',
      tester: tester,
      widget: ProviderScope(
        // 三条 UseCase 全 override 是防御性的：只 override get 时，实现里多调
        // 另外两个中的任意一个都会去真连 DB。
        overrides: [
          getNoteUseCaseProvider.overrideWithValue(get),
          updateNoteUseCaseProvider.overrideWithValue(update),
          createNoteUseCaseProvider.overrideWithValue(create),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: _router(),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
            FlutterQuillLocalizations.delegate,
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
