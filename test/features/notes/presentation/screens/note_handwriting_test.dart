import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/pick_note_image_use_case.dart';
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

class MockGetNote extends Mock implements GetNoteUseCase {}

class MockUpdateNote extends Mock implements UpdateNoteUseCase {}

class MockCreateNote extends Mock implements CreateNoteUseCase {}

class MockDeleteNote extends Mock implements DeleteNoteUseCase {}

class MockUpdateNoteBackground extends Mock
    implements UpdateNoteBackgroundUseCase {}

class MockPickNoteImage extends Mock implements PickNoteImageUseCase {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

final DateTime _fixed = DateTime(2026, 10, 15, 10, 30);
final Note _note = Note(
  id: 'n1',
  title: '',
  content: '',
  createdAt: _fixed,
  updatedAt: _fixed,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_note);
    registerFallbackValue(const AppSettings.defaults());
    registerFallbackValue(
      const UpdateNoteParams(noteId: 'n1', title: '', content: ''),
    );
  });

  /// 与 `note_image_insert_test.dart` 同一套壳（GoRouter + 本地化 + 假仓库）——
  /// 手写板与「插入图片」的差别只在图片来源，落库链路完全共用。
  Widget app() {
    final router = GoRouter(
      initialLocation: '/notes/n1',
      routes: <RouteBase>[
        GoRoute(
          path: '/notes',
          builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              builder: (context, state) => const NoteDetailScreen(noteId: 'n1'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    final db = AppDatabase.memory();
    addTearDown(db.close);

    final get = MockGetNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note));
    final update = MockUpdateNote();
    when(() => update(any())).thenAnswer((_) async => Right(_note));
    final settingsRepo = MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    return ProviderScope(
      overrides: [
        // ⚠️ 必须给内存库：导出走 `runAsync`（真实事件循环），drift 的懒打开
        // 会跟着跑起来 —— 不换掉的话它会去 `path_provider` 取文档目录，测试里
        // 没有插件实现，直接 `MissingPluginException` 把用例判失败。
        appDatabaseProvider.overrideWithValue(db),
        getNoteUseCaseProvider.overrideWithValue(get),
        updateNoteUseCaseProvider.overrideWithValue(update),
        createNoteUseCaseProvider.overrideWithValue(MockCreateNote()),
        deleteNoteUseCaseProvider.overrideWithValue(MockDeleteNote()),
        updateNoteBackgroundUseCaseProvider.overrideWithValue(
          MockUpdateNoteBackground(),
        ),
        pickNoteImageUseCaseProvider.overrideWithValue(MockPickNoteImage()),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    );
  }

  /// 打开手写板：从编辑页工具条点「手写板」按钮。
  Future<void> openBoard(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.draw));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingBoard), findsOneWidget);
  }

  /// 在画板上写一笔（down → 两次 move → up）。
  Future<void> writeStroke(WidgetTester tester) async {
    final board = find.byType(DrawingBoard);
    expect(
      tester.getSize(board).height,
      greaterThan(100),
      reason: '画布被挤没了：${tester.getSize(board)}',
    );
    final center = tester.getCenter(board);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// 「完成」要真正离屏渲染画布（`RenderRepaintBoundary.toImage`），那是个
  /// **真实异步**操作：测试的 fake async 推不动它，必须借 `runAsync` 让出
  /// 真实事件循环，之后再 pump 让 `pop` 生效。
  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.text('完成'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('画一笔 → 完成 → 正文插进一张图片', (tester) async {
    await openBoard(tester);
    await writeStroke(tester);

    // 第一道关：手势确实落到了画布上（撤销由禁用变可用）。
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
          .onPressed,
      isNotNull,
      reason: '手势没画到画布上',
    );

    await tapDone(tester);

    // 第二道关：导出的 PNG 非空 → 对话框带着结果关闭。
    expect(find.byType(DrawingBoard), findsNothing, reason: '导出失败，对话框没关');
    // 正文里的 image embed 由 `NoteImageEmbedBuilder` 渲染成 `Image.memory`。
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('空画布点完成 → 直接关闭，不插白图', (tester) async {
    await openBoard(tester);
    await tapDone(tester);

    expect(find.byType(DrawingBoard), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('取消 → 丢弃内容，不插图', (tester) async {
    await openBoard(tester);
    await writeStroke(tester);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(DrawingBoard), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('橡皮擦与色板可切换（工具条接线）', (tester) async {
    await openBoard(tester);

    // 5 个工具 + 撤销 / 重做 / 清空 + 5 个色块，全部有 tooltip（无障碍必需）。
    expect(find.byTooltip('橡皮擦'), findsOneWidget);
    expect(find.byTooltip('红色'), findsOneWidget);

    await tester.tap(find.byTooltip('橡皮擦'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('红色'));
    await tester.pumpAndSettle();

    // 无内容时撤销 / 重做 / 清空不可用（`canUndo()` 为 false → 按钮禁用）。
    // ⚠️ `AppIconButton` 是把 tooltip 传给 `IconButton` 的，Tooltip 在 IconButton
    // **内部**：用 `widgetWithIcon` 找，`find.descendant(of: byTooltip)` 找不到。
    final undo = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.undo),
    );
    expect(undo.onPressed, isNull);
  });
}
