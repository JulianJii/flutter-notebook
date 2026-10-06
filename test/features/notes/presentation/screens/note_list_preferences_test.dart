import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/presentation/providers/folder_provider.dart';
import 'package:init/features/notes/presentation/providers/note_list_provider.dart';
import 'package:init/features/notes/presentation/screens/note_list_screen.dart';
import 'package:init/features/notes/presentation/widgets/note_card.dart';
import 'package:init/features/notes/presentation/widgets/note_masonry_grid.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

final AppSettings _default = AppSettings.defaults();

Note _note(String id) => Note(
  id: id,
  title: '标题 $id',
  content: '正文 $id',
  createdAt: DateTime(2026, 8, 25),
  updatedAt: DateTime(2026, 8, 25),
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
  });

  late List<NoteQuery> queries;

  /// 偏好从 **Repository** 层灌入（持久化的真实边界），因此这条链路测的是
  /// 「P5 改了偏好 → P1 立刻变」的真实路径，而不是 mock 掉整个 provider。
  Widget app(AppSettings stored) {
    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer((_) async => Right(stored));
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final router = GoRouter(
      initialLocation: '/notes',
      routes: <RouteBase>[
        GoRoute(
          path: '/notes',
          builder: (context, state) => const NoteListScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
        ),
      ],
    );
    addTearDown(router.dispose);

    queries = <NoteQuery>[];
    return ProviderScope(
      // key 让每次 pumpWidget 都得到**全新的 container**。`settingsProvider` 是
      // `keepAlive` 的，且只在 `build()` 的 microtask 里 `ref.read` 一次仓库；
      // 若沿用同一个 container，换掉的 override 不会让它重读（Riverpod 的
      // `didUpdateWidget` 只做 `updateOverrides`），偏好就永远停在第一帧的值。
      // 想要「不重启就生效」那条真实路径，用 `set*` 写同一个 provider即可 ——
      // 本文件是「给定持久化值 → P1 长什么样」的契约测试，所以换 container。
      key: ValueKey<AppSettings>(stored),
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        noteListProvider.overrideWith((ref, query) {
          queries.add(query);
          return Stream<List<Note>>.value(<Note>[_note('1'), _note('2')]);
        }),
        // 文件夹流也必须 override：它会一路走到真 drift，而 drift 在 stream
        // 取消时留 0 时长 `Timer.run`，fake_async zone 里每个用例都会挂在
        // 「A Timer is still pending」上（同 `AGENTS.md` §测试约定）。
        // 必须 override：它会一路走到真 drift，而 drift 在 stream 取消时留
        // 0 时长 `Timer.run`，fake_async zone 里每个用例都会挂在「A Timer is
        // still pending」上。⚠️ 用 `value([])` 而**不是** `empty()`：P1 要等
        // 文件夹流首次出值才建 `TabController`，空流永远停在 loading 会让
        // 内容区留白。
        folderProvider.overrideWith(
          (ref) => Stream<List<FolderWithCount>>.value(
            const <FolderWithCount>[],
          ),
        ),
      ],
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

  AppSettings withLayout(NoteLayout layout) =>
      AppSettings.defaults().copyWith(noteLayout: layout);

  testWidgets('noteLayout=list 渲染单列 N 行，复用同一张 NoteCard', (tester) async {
    await tester.pumpWidget(app(withLayout(NoteLayout.list)));
    await tester.pumpAndSettle();

    expect(find.byType(NoteMasonryGrid), findsNothing);
    expect(find.byType(NoteCard), findsNWidgets(2));
  });

  testWidgets('noteLayout=grid 渲染 2 列瀑布流', (tester) async {
    await tester.pumpWidget(app(_default));
    await tester.pumpAndSettle();

    expect(find.byType(NoteMasonryGrid), findsOneWidget);
  });

  testWidgets('noteSort 传进 NoteQuery.sort（UI 不再硬编码）', (tester) async {
    await tester.pumpWidget(
      app(_default.copyWith(noteSort: AppNoteSort.titleAsc)),
    );
    await tester.pumpAndSettle();

    expect(queries.last.sort, NoteSort.titleAsc);
  });

  testWidgets('默认档 noteSort = editedDesc', (tester) async {
    await tester.pumpWidget(app(_default));
    await tester.pumpAndSettle();

    expect(queries.last.sort, NoteSort.editedDesc);
  });

  testWidgets('textScale 改变后卡片标题与正文区字号随之改变', (tester) async {
    await tester.pumpWidget(app(_default));
    await tester.pumpAndSettle();
    double? sizeOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.fontSize;

    expect(sizeOf('标题 1'), 15, reason: 'cardTitle 当前基线 15sp');

    await tester.pumpWidget(
      app(_default.copyWith(textScale: TextScaleLevel.xLarge)),
    );
    await tester.pumpAndSettle();

    expect(sizeOf('标题 1'), 18.75, reason: '15 x 1.25');
  });

  testWidgets('textScale 不进 URL query（偏好不放 URL）', (tester) async {
    final router = GoRouter(
      initialLocation: '/notes',
      routes: <RouteBase>[
        GoRoute(
          path: '/notes',
          builder: (context, state) => const NoteListScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => Right(
        _default.copyWith(
          textScale: TextScaleLevel.xLarge,
          noteSort: AppNoteSort.titleAsc,
        ),
      ),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          noteListProvider.overrideWith(
            (ref, query) => Stream<List<Note>>.value(<Note>[_note('1')]),
          ),
          folderProvider.overrideWith(
            (ref) => const Stream<List<FolderWithCount>>.empty(),
          ),
        ],
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
      ),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.queryParameters, isEmpty);
  });
}
