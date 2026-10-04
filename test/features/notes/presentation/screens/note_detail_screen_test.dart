import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/ui/ui.dart';
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

class MockGetNote extends Mock implements GetNoteUseCase {}

class MockUpdateNote extends Mock implements UpdateNoteUseCase {}

class MockCreateNote extends Mock implements CreateNoteUseCase {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// 成功读取 n1 的 mock。stub 放在各测试里而不是 app() 助手里，避免覆盖读库失败的用例。
MockGetNote stubbedGet() {
  final get = MockGetNote();
  when(() => get('n1')).thenAnswer((_) async => Right(_emptyTitleNote));
  return get;
}

final DateTime _fixed = DateTime(2026, 10, 3, 6, 40);
final Note _emptyTitleNote = Note(
  id: 'n1',
  title: '',
  content: '三花聚顶本是幻',
  createdAt: _fixed,
  updatedAt: _fixed,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_emptyTitleNote);
    registerFallbackValue(
      const UpdateNoteParams(noteId: 'n1', title: '', content: ''),
    );
    registerFallbackValue(const CreateNoteParams(title: '', content: ''));
    registerFallbackValue(const AppSettings.defaults());
  });

  /// 套一层真实 `GoRouter`：`context.pop()` / `PopScope` 需要 `Navigator`。
  Widget app(String noteId, MockGetNote get, {MockUpdateNote? update}) {
    final router = GoRouter(
      initialLocation: '/notes/n1',
      routes: <RouteBase>[
        GoRoute(
          path: '/notes',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              builder: (context, state) => NoteDetailScreen(noteId: noteId),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    if (update != null) {
      when(() => update(any())).thenAnswer((_) async => Right(_emptyTitleNote));
    }

    // P3 从 `settingsProvider` 读「文字大小」（TASK-047），而它经
    // `sharedPreferencesProvider` 落到插件上 —— 测试环境无插件实现，必须在
    // **Repository** 层 override（同 `settings_screen_test`）。
    final settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    return ProviderScope(
      overrides: [
        getNoteUseCaseProvider.overrideWithValue(get),
        updateNoteUseCaseProvider.overrideWithValue(update ?? MockUpdateNote()),
        createNoteUseCaseProvider.overrideWithValue(MockCreateNote()),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
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

  testWidgets('已有笔记：标题占位符 + 元信息行 + 正文', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    expect(find.text('标题'), findsOneWidget, reason: '空标题显示占位符');
    expect(find.textContaining('10月3日'), findsOneWidget);
    expect(find.textContaining('6:40'), findsOneWidget);
    expect(
      find.textContaining('上午'),
      findsNothing,
      reason: '用 h:mm 而不是 jm，jm 在 zh 下会带「上午」',
    );
    expect(find.textContaining('7字'), findsOneWidget);
    expect(find.byType(NoteMetaLine), findsOneWidget);
  });

  testWidgets('顶栏：back + 3 个图标，无标题', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    expect(find.byType(AppIconButton), findsNWidgets(4));
    expect(find.byIcon(AppIcons.back), findsOneWidget);
    expect(find.byIcon(AppIcons.share), findsOneWidget);
    expect(find.byIcon(AppIcons.palette), findsOneWidget);
    expect(find.byIcon(AppIcons.overflow), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing, reason: 'P3 是二级 Push 页');
  });

  testWidgets('页面底色为白（surface），与 P1 的灰底不同', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, const AppColors.light().surface);
    expect(scaffold.backgroundColor, isNot(const AppColors.light().bg));
  });

  testWidgets('输入正文后元信息行字数实时变化', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet(), update: MockUpdateNote()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '三花聚顶本是幻\n\n脚下腾云亦非真');
    await tester.pump();

    expect(find.textContaining('14字'), findsOneWidget);
  });

  testWidgets('新建笔记：不显示元信息行，build 不读库', (tester) async {
    final get = MockGetNote();
    when(() => get(any())).thenAnswer((_) async => Right(_emptyTitleNote));

    await tester.pumpWidget(app(kNewNoteId, get));
    await tester.pumpAndSettle();

    expect(find.byType(NoteMetaLine), findsNothing, reason: '新笔记无 createdAt');
    expect(find.text('标题'), findsOneWidget);
    verifyNever(() => get(any()));
  });

  testWidgets('读库失败：页面留白，不崩溃、不显示错误页', (tester) async {
    final get = MockGetNote();
    when(
      () => get('n1'),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'boom')));

    await tester.pumpWidget(app('n1', get));
    await tester.pumpAndSettle();

    expect(find.byType(NoteMetaLine), findsNothing);
  });

  testWidgets('点 share / palette / overflow 不崩溃、无弹层', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    for (final icon in <IconData>[
      AppIcons.share,
      AppIcons.palette,
      AppIcons.overflow,
    ]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
    }

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('输入后点 back：内容已保存（flush 生效），不弹对话框', (tester) async {
    final update = MockUpdateNote();
    await tester.pumpWidget(app('n1', stubbedGet(), update: update));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '新正文');
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    final captured = verify(() => update(captureAny())).captured;
    expect(captured, hasLength(1), reason: '返回前 flush 落库');
    expect((captured.single as UpdateNoteParams).content, '新正文');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('未修改时返回不触发落库（flush 幂等）', (tester) async {
    final update = MockUpdateNote();
    await tester.pumpWidget(app('n1', stubbedGet(), update: update));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    verifyNever(() => update(any()));
  });
}
