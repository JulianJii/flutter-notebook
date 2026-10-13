import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_router.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/window/desktop_shortcuts.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:mynote/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockGetNote extends Mock implements GetNoteUseCase {}

class _MockUpdateNote extends Mock implements UpdateNoteUseCase {}

class _MockCreateNote extends Mock implements CreateNoteUseCase {}

class _MockDeleteNote extends Mock implements DeleteNoteUseCase {}

class _MockUpdateNoteBackground extends Mock
    implements UpdateNoteBackgroundUseCase {}

final DateTime _fixed = DateTime(2026, 10, 3, 6, 40);
final Note _note = Note(
  id: 'n1',
  title: '旧标题',
  content: '',
  createdAt: _fixed,
  updatedAt: _fixed,
);

/// 轻壳：只验「按了键之后路由去哪」的分支，页面全是 stub。
/// ⚠️ 路径顺序与 `app_router.dart` 一致：`new` / `trash` 不能被 `:id` 吃掉。
List<RouteBase> _shellRoutes() => <RouteBase>[
  GoRoute(
    path: '/notes',
    builder: (context, state) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => GoRouter.of(context).push('/settings'),
          child: const Text('去设置'),
        ),
      ),
    ),
  ),
  GoRoute(
    path: '/notes/new',
    builder: (context, state) => const Scaffold(body: Text('新建页')),
  ),
  GoRoute(
    path: '/notes/trash',
    builder: (context, state) => const Scaffold(body: Text('回收站页')),
  ),
  GoRoute(
    path: '/settings',
    builder: (context, state) => const Scaffold(body: Text('设置页')),
  ),
];

/// 真编辑页：`/notes` 上有个按钮 push 到 `/notes/n1`（`Esc` 需要真有一层可退）。
List<RouteBase> _editorRoutes() => <RouteBase>[
  GoRoute(
    path: '/notes',
    builder: (context, state) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => GoRouter.of(context).push('/notes/n1'),
          child: const Text('打开笔记'),
        ),
      ),
    ),
  ),
  GoRoute(
    path: '/notes/:id',
    builder: (context, state) =>
        NoteDetailScreen(noteId: state.pathParameters['id']!),
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
    registerFallbackValue(_note);
    registerFallbackValue(
      const UpdateNoteParams(noteId: 'n1', title: '', content: ''),
    );
  });

  /// 复刻 `main.dart` 的挂载位置：`DesktopShortcuts` 在 Navigator **之上**。
  ///
  /// ⚠️ 测试 router 必须用**同一个** [rootNavigatorKey]：快捷键层的 `Esc`
  /// 与 `Ctrl+F` 都是在这个 key 上找 Navigator / Overlay 的。
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required List<RouteBase> routes,
    String initialLocation = '/notes',
  }) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: routes,
    );
    addTearDown(router.dispose);

    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final noteRepo = _MockNoteRepository();
    when(
      () => noteRepo.watch(any()),
    ).thenAnswer((_) => Stream<List<Note>>.value(const <Note>[]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 快捷键层读的是 App 的单例 routerProvider —— 测试要把它指向本地 router。
          routerProvider.overrideWithValue(router),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          noteRepositoryProvider.overrideWithValue(noteRepo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          builder: (context, child) =>
              DesktopShortcuts(child: child ?? const SizedBox.shrink()),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// 按下 `Ctrl + key`（Windows 组合键的写法）。
  Future<void> pressCtrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  /// 当前位置取 `state.uri`：`routerDelegate.currentConfiguration.uri` 对
  /// `push` 出来的页面是过期值（见 `desktop_shortcuts.dart` 的注释），拿它断言会
  /// 把「push 成功了」误判成没成功。
  String locationOf(GoRouter router) => router.state.uri.toString();

  testWidgets('Ctrl+N：从笔记列表进入空白编辑页', (tester) async {
    final router = await pumpApp(tester, routes: _shellRoutes());

    await pressCtrl(tester, LogicalKeyboardKey.keyN);

    expect(locationOf(router), '/notes/new');
  });

  testWidgets('Ctrl+N：带上当前分类（?folder= 透传，哨兵不传）', (tester) async {
    final router = await pumpApp(
      tester,
      routes: _shellRoutes(),
      initialLocation: '/notes?folder=f1',
    );

    await pressCtrl(tester, LogicalKeyboardKey.keyN);

    expect(locationOf(router), '/notes/new?folder=f1');
  });

  testWidgets('Ctrl+N：已在笔记二级页不叠一层新编辑页', (tester) async {
    final router = await pumpApp(
      tester,
      routes: _shellRoutes(),
      initialLocation: '/notes/trash',
    );

    await pressCtrl(tester, LogicalKeyboardKey.keyN);

    expect(locationOf(router), '/notes/trash');
  });

  testWidgets('Ctrl+,：打开设置，且已在设置时不重复压栈', (tester) async {
    final router = await pumpApp(tester, routes: _shellRoutes());

    await pressCtrl(tester, LogicalKeyboardKey.comma);
    expect(locationOf(router), '/settings');

    // 再按一次不该再压一层 —— 退一次就该回到笔记列表。
    await pressCtrl(tester, LogicalKeyboardKey.comma);
    expect(locationOf(router), '/settings');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(locationOf(router), '/notes');
  });

  testWidgets('Ctrl+F：弹出全局搜索面板，连按不叠第二个', (tester) async {
    await pumpApp(tester, routes: _shellRoutes());

    await pressCtrl(tester, LogicalKeyboardKey.keyF);
    expect(find.byKey(const Key('global_search_field')), findsOneWidget);

    await pressCtrl(tester, LogicalKeyboardKey.keyF);
    expect(find.byKey(const Key('global_search_field')), findsOneWidget);
  });

  testWidgets('Esc：返回上一页（走 maybePop，无路可退时不炸）', (tester) async {
    final router = await pumpApp(tester, routes: _shellRoutes());

    // 顶层按 Esc：没有任何可退的路由，只要求不崩、位置不变。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(locationOf(router), '/notes');

    await tester.tap(find.text('去设置'));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/settings');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(locationOf(router), '/notes');
  });

  group('编辑页', () {
    /// 真编辑页 + mock 用例。返回 (router, update) 供断言。
    Future<GoRouter> pumpEditor(
      WidgetTester tester, {
      required _MockUpdateNote update,
    }) async {
      final get = _MockGetNote();
      when(() => get('n1')).thenAnswer((_) async => Right(_note));
      when(() => update(any())).thenAnswer((_) async => Right(_note));

      final settingsRepo = _MockSettingsRepository();
      when(() => settingsRepo.load()).thenAnswer(
        (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
      );
      when(
        () => settingsRepo.save(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/notes',
        routes: _editorRoutes(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            getNoteUseCaseProvider.overrideWithValue(get),
            updateNoteUseCaseProvider.overrideWithValue(update),
            createNoteUseCaseProvider.overrideWithValue(_MockCreateNote()),
            deleteNoteUseCaseProvider.overrideWithValue(_MockDeleteNote()),
            updateNoteBackgroundUseCaseProvider.overrideWithValue(
              _MockUpdateNoteBackground(),
            ),
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: router,
            builder: (context, child) =>
                DesktopShortcuts(child: child ?? const SizedBox.shrink()),
            localizationsDelegates: <LocalizationsDelegate<dynamic>>[
              ...AppLocalizations.localizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('打开笔记'));
      await tester.pumpAndSettle();
      // 改标题 → 草稿变脏。⏳ 不等 500ms debounce：下面的断言只认快捷键那一次落库。
      await tester.enterText(find.byType(TextField).first, '新标题');
      await tester.pump(const Duration(milliseconds: 100));
      return router;
    }

    testWidgets('Ctrl+S：立即把草稿落库，不离开编辑页', (tester) async {
      final update = _MockUpdateNote();
      final router = await pumpEditor(tester, update: update);

      await pressCtrl(tester, LogicalKeyboardKey.keyS);

      final params =
          verify(() => update(captureAny())).captured.single
              as UpdateNoteParams;
      expect(params.title, '新标题');
      expect(locationOf(router), '/notes/n1');
    });

    testWidgets('Esc：先落库再退出（不绕过编辑页的未保存保护）', (tester) async {
      final update = _MockUpdateNote();
      final router = await pumpEditor(tester, update: update);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // `Esc` 走 `maybePop` → `PopScope` 拦下 → 编辑页 `_leave()` 的 `flush()`
      // 把草稿写库 → 才真的退出。⚠️ 改回 `pop()` 这条断言就会挂。
      verify(() => update(any())).called(1);
      expect(locationOf(router), '/notes');
    });
  });
}
