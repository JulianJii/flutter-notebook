import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/presentation/screens/note_list_screen.dart';
import 'package:mynote/features/notes/presentation/widgets/note_card.dart';
import 'package:mynote/features/notes/presentation/widgets/note_editor_pane.dart';
import 'package:mynote/features/notes/presentation/widgets/notes_wide_layout.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

class _MockFolderRepository extends Mock implements FolderRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// 宽屏双栏（≥1024dp）：左列表 + 右编辑，**选中态不进 URL**。
///
/// 这几条断言盯的是本次改造最容易退化的三点：
/// 1. 窄窗口（1010）不许出现双栏 —— 否则右栏会把列表挤成一条缝；
/// 2. 宽窗口点卡片**不压路由**（URL 仍是 `/notes`）—— 否则「双栏」名存实亡；
/// 3. 关掉右栏能回到空态，且不抛异常。
void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
  });

  Note note(String id) => Note(
    id: id,
    title: '标题 $id',
    content: '正文 $id',
    createdAt: DateTime(2026, 8, 25),
    updatedAt: DateTime(2026, 8, 25),
  );

  void useWindow(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget app(GoRouter router, List<Note> notes) {
    final noteRepo = _MockNoteRepository();
    when(
      () => noteRepo.watch(any()),
    ).thenAnswer((_) => Stream<List<Note>>.value(notes));
    // 右栏挂载时会读这篇笔记（`NoteEditorProvider.build`）。
    when(
      () => noteRepo.getById(any()),
    ).thenAnswer((_) async => Right<Failure, Note>(notes.first));
    final folderRepo = _MockFolderRepository();
    when(
      () => folderRepo.watchWithCounts(),
    ).thenAnswer((_) => Stream<List<FolderWithCount>>.value(const []));
    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
        folderRepositoryProvider.overrideWithValue(folderRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          // 右栏是真实的 Quill 编辑器，缺它工具栏按钮全崩。
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    );
  }

  /// 复刻 `/notes` 分支：`/notes` 与它的 `:id` 子路由（后者用于验证「窄屏才 push」）。
  GoRouter routerFor(String location) => GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NoteListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                Scaffold(body: Text('整页编辑 ${state.pathParameters['id']}')),
          ),
        ],
      ),
    ],
  );

  testWidgets('宽屏：出现双栏与右栏空态，不出现整页编辑', (tester) async {
    useWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(app(routerFor('/notes'), <Note>[note('n1')]));
    await tester.pumpAndSettle();

    expect(find.byType(NotesWideLayout), findsOneWidget);
    expect(find.byType(NoteEditorPane), findsNothing);
    expect(
      find.text(AppLocalizations.of(
        tester.element(find.byType(NotesWideLayout)),
      ).notePaneEmptyTitle),
      findsOneWidget,
    );
    // 左栏固定宽度（不是按窗口比例）。
    expect(
      tester.getSize(find.byKey(const Key('notes_wide_list'))).width,
      NotesWideLayout.listWidth,
    );
  });

  testWidgets('宽屏点卡片：右栏出编辑器，且不压路由（URL 仍是 /notes）', (tester) async {
    useWindow(tester, const Size(1280, 800));
    final router = routerFor('/notes');
    await tester.pumpWidget(app(router, <Note>[note('n1')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NoteCard));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorPane), findsOneWidget);
    expect(router.state.uri.path, '/notes', reason: '双栏的选中态不进 URL');
  });

  testWidgets('宽屏关掉右栏：回到空态', (tester) async {
    useWindow(tester, const Size(1280, 800));
    await tester.pumpWidget(app(routerFor('/notes'), <Note>[note('n1')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NoteCard));
    await tester.pumpAndSettle();
    expect(find.byType(NoteEditorPane), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorPane), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('中等宽度（1010dp）：仍是单栏，点卡片走整页路由', (tester) async {
    useWindow(tester, const Size(1010, 800));
    final router = routerFor('/notes');
    await tester.pumpWidget(app(router, <Note>[note('n1')]));
    await tester.pumpAndSettle();

    expect(find.byType(NotesWideLayout), findsNothing);

    await tester.tap(find.byType(NoteCard));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/notes/n1');
    expect(find.text('整页编辑 n1'), findsOneWidget);
  });
}
