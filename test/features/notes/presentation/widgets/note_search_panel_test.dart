import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/ui/app_icon.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/presentation/widgets/note_search_panel.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

final DateTime _fixed = DateTime(2026, 8, 25);

Note _note(String id, String title, String content) => Note(
  id: id,
  title: title,
  content: content,
  createdAt: _fixed,
  updatedAt: _fixed,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const AppSettings.defaults());
  });

  /// 面板必须活在真 router 里：`_open` 走 `GoRouter.of(context)` + `push`
  /// （点结果要落到笔记详情，且返回时回到打开面板前的页面）。
  Widget app({
    required Stream<List<Note>> notes,
    required List<NoteQuery> watched,
  }) {
    final noteRepo = _MockNoteRepository();
    when(() => noteRepo.watch(any())).thenAnswer((invocation) {
      watched.add(invocation.positionalArguments.first as NoteQuery);
      return notes;
    });
    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    final router = GoRouter(
      initialLocation: '/home',
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showNoteSearchPanel(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/notes/:id',
          builder: (context, state) =>
              Scaffold(body: Text('详情 ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(noteRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
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

  Future<void> openPanel(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('未输入时只有输入行：不查库、不出结果也不出空态', (tester) async {
    final watched = <NoteQuery>[];
    await openPanel(
      tester,
      app(
        notes: Stream<List<Note>>.value(<Note>[_note('n1', '标题一', '正文一')]),
        watched: watched,
      ),
    );

    expect(find.byKey(const Key('global_search_field')), findsOneWidget);
    expect(watched, isEmpty, reason: '空关键字不该订阅（等于查全部笔记）');
    expect(find.text('标题一'), findsNothing);
    expect(find.text('没有找到相关笔记'), findsNothing);
  });

  testWidgets('输入关键字 → 按搜索词查库并列出结果', (tester) async {
    final watched = <NoteQuery>[];
    await openPanel(
      tester,
      app(
        notes: Stream<List<Note>>.value(<Note>[_note('n1', '标题一', '正文一')]),
        watched: watched,
      ),
    );

    await tester.enterText(find.byKey(const Key('global_search_field')), '标题');
    await tester.pumpAndSettle();

    expect(watched.last.searchTerm, '标题');
    expect(find.text('标题一'), findsOneWidget);
    expect(find.text('正文一'), findsOneWidget);
  });

  testWidgets('无匹配 → 与笔记列表页同一句空态文案', (tester) async {
    await openPanel(
      tester,
      app(
        // ⚠️ 必须是「推出一个空列表」，不是 `Stream.empty()`：后者一个事件都不发，
        // 面板会一直停在 loading，空态文案根本不会出现。
        notes: Stream<List<Note>>.value(const <Note>[]),
        watched: <NoteQuery>[],
      ),
    );

    await tester.enterText(
      find.byKey(const Key('global_search_field')),
      '不存在的词',
    );
    await tester.pumpAndSettle();

    expect(find.text('没有找到相关笔记'), findsOneWidget);
  });

  testWidgets('点结果 → 关闭面板并 push 笔记详情', (tester) async {
    await openPanel(
      tester,
      app(
        notes: Stream<List<Note>>.value(<Note>[_note('n1', '标题一', '正文一')]),
        watched: <NoteQuery>[],
      ),
    );

    await tester.enterText(find.byKey(const Key('global_search_field')), '标题');
    await tester.pumpAndSettle();

    await tester.tap(find.text('标题一'));
    await tester.pumpAndSettle();

    expect(find.text('详情 n1'), findsOneWidget);
    expect(find.byKey(const Key('global_search_field')), findsNothing);
  });

  testWidgets('清空按钮 → 关键字清零、结果区收起', (tester) async {
    await openPanel(
      tester,
      app(
        notes: Stream<List<Note>>.value(<Note>[_note('n1', '标题一', '正文一')]),
        watched: <NoteQuery>[],
      ),
    );

    await tester.enterText(find.byKey(const Key('global_search_field')), '标题');
    await tester.pumpAndSettle();
    expect(find.text('标题一'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.trash));
    await tester.pumpAndSettle();

    expect(find.text('标题一'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('global_search_field')))
          .controller
          ?.text,
      isEmpty,
    );
  });
}
