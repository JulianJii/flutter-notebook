import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_test/flutter_quill_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/fonts/font_loader_service.dart';
import 'package:mynote/core/fonts/font_providers.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_editor_font_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_editor_font_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_flags_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_flags_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:mynote/features/notes/presentation/providers/note_editor_provider.dart';
import 'package:mynote/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/fake_font_registrar.dart';

class MockGetNote extends Mock implements GetNoteUseCase {}

class MockUpdateNote extends Mock implements UpdateNoteUseCase {}

class MockCreateNote extends Mock implements CreateNoteUseCase {}

class MockDeleteNote extends Mock implements DeleteNoteUseCase {}

class _MockUpdateNoteBackground extends Mock
    implements UpdateNoteBackgroundUseCase {}

/// 记录置顶 / 收藏写入的参数。用 [calls] 而不是 `verify`，因为同一测试里会连点
/// 两次 —— 要断言的是「第二次写的是另一列、且没把第一列抹掉」。
class MockUpdateNoteFlags extends Mock implements UpdateNoteFlagsUseCase {
  final List<UpdateNoteFlagsParams> calls = <UpdateNoteFlagsParams>[];

  @override
  Future<Either<Failure, Unit>> call(UpdateNoteFlagsParams params) async {
    calls.add(params);
    return const Right(unit);
  }
}

/// 记录字体写入的参数。用 [calls] 而不是 `verify`，理由同 [MockUpdateNoteFlags]。
class MockUpdateNoteEditorFont extends Mock
    implements UpdateNoteEditorFontUseCase {
  final List<UpdateNoteEditorFontParams> calls =
      <UpdateNoteEditorFontParams>[];

  @override
  Future<Either<Failure, Unit>> call(UpdateNoteEditorFontParams params) async {
    calls.add(params);
    return const Right(unit);
  }
}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// 编辑器正文外层 `DefaultTextStyle` 的当前样式（标题与正文的字都从它取）。
DefaultTextStyle _editorTextStyle(WidgetTester tester) {
  // `find.ancestor` 由近及远，`.first` 就是紧贴编辑器的那一层。
  return tester.widget<DefaultTextStyle>(
    find
        .ancestor(
          of: find.byType(QuillEditor),
          matching: find.byType(DefaultTextStyle),
        )
        .first,
  );
}

/// 成功读取 n1 的 mock。stub 放在各测试里而不是 app() 助手里，避免覆盖读库失败的用例。
MockGetNote stubbedGet() {
  final get = MockGetNote();
  when(() => get('n1')).thenAnswer((_) async => Right(_emptyTitleNote));
  return get;
}

/// 正文为指定值的 mock —— 正文是 Quill Delta，`enterText` 插在光标处而非覆盖
/// 全文，要断言「输入后的字数 / 落库内容」就得从空正文起手。
MockGetNote stubbedGetWith(String content) {
  final get = MockGetNote();
  when(
    () => get('n1'),
  ).thenAnswer((_) async => Right(_emptyTitleNote.copyWith(content: content)));
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
    registerFallbackValue(
      const UpdateNoteBackgroundParams(
        noteId: 'n1',
        background: NoteBackground.paper,
      ),
    );
    registerFallbackValue(
      const UpdateNoteEditorFontParams(noteId: 'n1', fontId: 'smileySans'),
    );
    registerFallbackValue(const AppSettings.defaults());
  });

  /// 套一层真实 `GoRouter`：`context.pop()` / `PopScope` 需要 `Navigator`。
  Widget app(
    String noteId,
    MockGetNote get, {
    MockUpdateNote? update,
    MockDeleteNote? delete,
    _MockUpdateNoteBackground? updateBackground,
    MockUpdateNoteFlags? updateFlags,
    MockUpdateNoteEditorFont? updateFont,
    FakeFontRegistrar? fontRegistrar,
  }) {
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

    // 传了 `delete` 就由用例自己 stub（要断言失败路径）；没传则给一个成功的默认。
    final del = delete ?? MockDeleteNote();
    if (delete == null) {
      when(() => del(any())).thenAnswer((_) async => const Right(unit));
    }

    // 同上：背景窄通道默认成功，避免测试去碰真实的数据库 provider。
    final updateBg = updateBackground ?? _MockUpdateNoteBackground();
    if (updateBackground == null) {
      when(() => updateBg(any())).thenAnswer((_) async => const Right(unit));
    }

    // 同上：置顶 / 收藏窄通道默认成功。
    final flags = updateFlags ?? MockUpdateNoteFlags();

    // 同上：字体窄通道默认成功。
    final font = updateFont ?? MockUpdateNoteEditorFont();

    // 笔记详情（插入图片时）从 `settingsProvider` 读「图片压缩」，而它经
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
        deleteNoteUseCaseProvider.overrideWithValue(del),
        updateNoteBackgroundUseCaseProvider.overrideWithValue(updateBg),
        updateNoteFlagsUseCaseProvider.overrideWithValue(flags),
        updateNoteEditorFontUseCaseProvider.overrideWithValue(font),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        // 字体弹层选中一款字体会真去 `DynamicFont.url(...)` 下载字体文件，
        // 测试里换成「立刻成功」的替身（真实加载逻辑由 core/fonts 的单测覆盖）。
        fontLoaderServiceProvider.overrideWithValue(
          FontLoaderService(fontRegistrar ?? FakeFontRegistrar()),
        ),
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

  testWidgets('顶栏：back + 调色 / 字体 / 更多，无标题', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    // 共 4 个 AppIconButton：back + 调色 + 字体 + 正文工具条的「插入图片」。
    // 「更多」是 PopupMenuButton，不在其中。
    expect(find.byType(AppIconButton), findsNWidgets(4));
    expect(find.byIcon(AppIcons.back), findsOneWidget);
    expect(find.byIcon(AppIcons.palette), findsOneWidget);
    expect(find.byIcon(AppIcons.fontFamily), findsOneWidget);
    expect(find.byIcon(AppIcons.overflow), findsOneWidget);
    expect(find.byIcon(AppIcons.image), findsOneWidget);

    // 分享 / 置顶 / 收藏都收进了「更多」下拉，菜单未展开时页面上没有这些字形。
    expect(find.byIcon(AppIcons.share), findsNothing);
    expect(find.byIcon(AppIcons.pushPin), findsNothing);
    expect(find.byIcon(AppIcons.starOutline), findsNothing);
    expect(find.byType(AppBottomNav), findsNothing, reason: '整页盖在嵌套 Push 页');
  });

  testWidgets('字体：顶栏弹层选一款字体 → 只写字体列，标题与正文一起换', (tester) async {
    final font = MockUpdateNoteEditorFont();
    await tester.pumpWidget(app('n1', stubbedGet(), updateFont: font));
    await tester.pumpAndSettle();

    expect(
      _editorTextStyle(tester).style.fontFamily,
      isNull,
      reason: '默认 = 系统字体',
    );

    await tester.tap(find.byIcon(AppIcons.fontFamily));
    await tester.pumpAndSettle();
    expect(find.text('系统默认'), findsOneWidget, reason: '弹层第一档是系统默认');

    await tester.tap(find.text('得意黑'));
    await tester.pumpAndSettle();

    // 窄通道：只带 noteId 与字体 id，不碰标题 / 正文 / updatedAt。
    expect(font.calls, hasLength(1));
    expect(font.calls.single.noteId, 'n1');
    expect(font.calls.single.fontId, 'smileySans');

    expect(_editorTextStyle(tester).style.fontFamily, 'SmileySans-Oblique');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).style?.fontFamily,
      'SmileySans-Oblique',
      reason: '标题跟着一起换',
    );
  });

  testWidgets('字体：库里存过就按它渲染（冷启动重开笔记的路径）', (tester) async {
    final get = MockGetNote();
    when(() => get('n1')).thenAnswer(
      (_) async => Right(_emptyTitleNote.copyWith(editorFontId: 'lxgwWenKai')),
    );

    await tester.pumpWidget(app('n1', get));
    await tester.pumpAndSettle();

    expect(_editorTextStyle(tester).style.fontFamily, 'LXGWWenKai');
  });

  testWidgets('字体：下载失败留在弹层里，不写库、不改当前字体', (tester) async {
    final font = MockUpdateNoteEditorFont();
    await tester.pumpWidget(
      app(
        'n1',
        stubbedGet(),
        updateFont: font,
        fontRegistrar: FakeFontRegistrar(succeeds: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.fontFamily));
    await tester.pumpAndSettle();
    await tester.tap(find.text('得意黑'));
    await tester.pumpAndSettle();

    expect(find.text('得意黑'), findsOneWidget, reason: '弹层还在，用户可以再点一次');
    expect(font.calls, isEmpty, reason: '没落库，选择没变');
    expect(_editorTextStyle(tester).style.fontFamily, isNull);
  });

  testWidgets('更多菜单：置顶 / 收藏写库并翻成实心字形', (tester) async {
    final updateFlags = MockUpdateNoteFlags();
    await tester.pumpWidget(app('n1', stubbedGet(), updateFlags: updateFlags));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.overflow));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note_toggle_pin')), findsOneWidget);
    expect(find.byKey(const Key('note_share')), findsOneWidget);
    // 菜单落在按钮**下方**，不盖住按钮（`PopupMenuPosition.under`）
    expect(
      tester.getRect(find.byKey(const Key('note_toggle_pin'))).top,
      greaterThanOrEqualTo(
        tester.getRect(find.byKey(const Key('note_more'))).bottom,
      ),
    );
    expect(find.byKey(const Key('note_toggle_favorite')), findsOneWidget);
    expect(find.byKey(const Key('note_delete')), findsOneWidget);
    // 未置顶 / 未收藏时显示空心字形与「置顶 / 收藏」文案
    expect(find.byIcon(AppIcons.pushPin), findsOneWidget);
    expect(find.byIcon(AppIcons.starOutline), findsOneWidget);
    expect(find.text('置顶'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);

    await tester.tap(find.byKey(const Key('note_toggle_pin')));
    await tester.pumpAndSettle();
    expect(
      updateFlags.calls.single.isPinned,
      isTrue,
      reason: '只写置顶列，收藏列传 null（= 不动）',
    );
    expect(updateFlags.calls.single.isFavorite, isNull);

    // 已置顶 → 文案与字形都翻成「撤销」态（实心见 _TopBar 注释）
    await tester.tap(find.byIcon(AppIcons.overflow));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.pushPinFilled), findsOneWidget);
    expect(find.text('取消置顶'), findsOneWidget);

    await tester.tap(find.byKey(const Key('note_toggle_favorite')));
    await tester.pumpAndSettle();
    expect(updateFlags.calls.last.isFavorite, isTrue);
    expect(updateFlags.calls.last.isPinned, isNull, reason: '不把置顶列抹掉');

    await tester.tap(find.byIcon(AppIcons.overflow));
    await tester.pumpAndSettle();
    expect(find.byIcon(AppIcons.starFilled), findsOneWidget);
    expect(find.text('取消收藏'), findsOneWidget);
  });

  testWidgets('新笔记未落库：菜单里只有分享能点', (tester) async {
    await tester.pumpWidget(app(kNewNoteId, MockGetNote()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.overflow));
    await tester.pumpAndSettle();

    bool enabled(String key) =>
        tester.widget<PopupMenuItem<dynamic>>(find.byKey(Key(key))).enabled;

    // 三个写库动作库里还没有行 → 置灰；分享的是草稿，不需要库里有这行。
    expect(enabled('note_toggle_pin'), isFalse);
    expect(enabled('note_toggle_favorite'), isFalse);
    expect(enabled('note_delete'), isFalse);
    expect(enabled('note_share'), isTrue);
  });

  testWidgets('页面底色为白（surface），与笔记列表的灰底不同', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, const AppColors.light().surface);
    expect(scaffold.backgroundColor, isNot(const AppColors.light().bg));
  });

  testWidgets('输入正文后元信息行字数实时变化', (tester) async {
    await tester.pumpWidget(
      app('n1', stubbedGetWith(''), update: MockUpdateNote()),
    );
    await tester.pumpAndSettle();

    await tester.quillEnterTextAtPosition(
      find.byType(QuillEditor),
      '三花聚顶本是幻\n\n脚下腾云亦非真',
      0,
    );
    await tester.pump();

    expect(find.textContaining('14字'), findsOneWidget);
  });

  testWidgets('工具条：常驻 + 点加粗真的落到文档上', (tester) async {
    final update = MockUpdateNote();
    await tester.pumpWidget(app('n1', stubbedGetWith(''), update: update));
    await tester.pumpAndSettle();

    expect(find.byType(QuillSimpleToolbar), findsOneWidget);

    // ⚠️ 顺序是「先点加粗，再输入」：Quill 在折叠选区下把格式挂到光标处的
    // block / 输入流上，**不追溯**已经插入的文字（先输入再点加粗，Delta 是干净的）。
    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();
    await tester.quillEnterTextAtPosition(find.byType(QuillEditor), '正文', 0);
    await tester.pump();
    // 等 500ms debounce 落库。
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final captured = verify(() => update(captureAny())).captured;
    final delta = NoteDelta.decode((captured.last as UpdateNoteParams).content);
    expect(
      delta.toList().any((op) => op.attributes?['bold'] == true),
      isTrue,
      reason: '工具条接的是本页 controller，点加粗要真进 Delta，不是摆设',
    );
  });

  testWidgets('编辑窗口占满剩余空间、工具条在其下方：点正文下方空白也能落光标', (tester) async {
    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    final editor = find.byType(QuillEditor);
    final editorRect = tester.getRect(editor);
    expect(
      editorRect.height,
      greaterThan(200),
      reason: '正文只有一行，编辑窗口也要占满剩余空间（默认最大化）',
    );
    expect(
      tester.getTopLeft(find.byType(QuillSimpleToolbar)).dy,
      greaterThanOrEqualTo(editorRect.bottom),
      reason: '工具条在编辑窗口下面，不是上面',
    );

    // 点在正文最后一行**下方**的空白区：编辑器没有占满高度时这里点不进光标。
    await tester.tapAt(Offset(editorRect.center.dx, editorRect.bottom - 20));
    await tester.pump();

    final controller = tester.findRawEditor(editor).controller;
    expect(
      controller.selection.baseOffset,
      greaterThan(0),
      reason: '空白区的点击要落到编辑器上（光标移到最近一行），不是打在空白上',
    );
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

  testWidgets('点 share：标题 + 正文纯文本交给系统分享面板', (tester) async {
    // 测试环境没有插件实现，拦掉 share_plus 的 MethodChannel 拿真正发出去的参数
    // （比 mock 一层 provider 更贴近真实链路）。
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return '';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await tester.pumpWidget(app('n1', stubbedGet()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.overflow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note_share')));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'share');
    expect(calls.single.arguments['text'], '三花聚顶本是幻');
  });

  testWidgets('空笔记点 share：直接返回，不发空文本（share_plus 会抛）', (tester) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return '';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    // 未落库的新笔记也能分享草稿 —— 分享不写库，不该被 isPersisted 挡住。
    await tester.pumpWidget(app(kNewNoteId, MockGetNote()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.overflow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note_share')));
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点 palette 弹出背景弹层：选第 2 张出背景图，点空白项撤回', (tester) async {
    final updateBackground = _MockUpdateNoteBackground();
    when(
      () => updateBackground(any()),
    ).thenAnswer((_) async => const Right(unit));
    await tester.pumpWidget(
      app('n1', stubbedGet(), updateBackground: updateBackground),
    );
    await tester.pumpAndSettle();

    Image? backgroundImage() => tester
        .widgetList<Image>(find.byType(Image))
        .where((image) => image.image is AssetBundleImageProvider)
        .cast<Image?>()
        .firstOrNull;

    // 默认无背景，也未开弹层
    expect(backgroundImage(), isNull);
    expect(find.byType(BottomSheet), findsNothing);

    // 点 palette → 弹层里有 3 张纹理 + 「无背景」占位
    await tester.tap(find.byIcon(AppIcons.palette));
    await tester.pumpAndSettle();
    final sheet = find.byType(BackgroundPickerSheet);
    expect(sheet, findsOneWidget);

    // 选第 2 张纹理（index 2 → backgrounds[1] → NoteBackground.mint）
    await tester.tap(find.byKey(const ValueKey<int>(2)));
    await tester.pumpAndSettle();
    expect(find.byType(BackgroundPickerSheet), findsNothing);
    expect(backgroundImage(), isNotNull);

    // 已有笔记：选择即走窄通道落库（只写背景列，不刷 updatedAt）
    final saved =
        verify(() => updateBackground(captureAny())).captured.single
            as UpdateNoteBackgroundParams;
    expect(saved.noteId, 'n1');
    expect(saved.background, NoteBackground.mint);

    // 再打开、选「无背景」占位 → 撤回背景，并落库 null
    await tester.tap(find.byIcon(AppIcons.palette));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<int>(0)));
    await tester.pumpAndSettle();
    expect(backgroundImage(), isNull);
    final cleared =
        verify(() => updateBackground(captureAny())).captured.last
            as UpdateNoteBackgroundParams;
    expect(cleared.background, isNull);
  });

  testWidgets('库里已保存的背景：进页面直接渲染，无需再选', (tester) async {
    final get = MockGetNote();
    when(() => get('n1')).thenAnswer(
      (_) async =>
          Right(_emptyTitleNote.copyWith(background: NoteBackground.blush)),
    );

    await tester.pumpWidget(app('n1', get));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => image.image is AssetBundleImageProvider),
      isNotEmpty,
      reason: '背景是持久化属性，重开笔记必须还原',
    );
  });

  testWidgets('输入后点 back：内容已保存（flush 生效），不弹对话框', (tester) async {
    final update = MockUpdateNote();
    await tester.pumpWidget(app('n1', stubbedGetWith(''), update: update));
    await tester.pumpAndSettle();

    await tester.quillEnterTextAtPosition(find.byType(QuillEditor), '新正文', 0);
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    final captured = verify(() => update(captureAny())).captured;
    expect(captured, hasLength(1), reason: '返回前 flush 落库');
    expect(
      NoteDelta.plainText((captured.single as UpdateNoteParams).content).trim(),
      '新正文',
      reason: '落库的是 Delta JSON，比对前先还原纯文本',
    );
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('未修改时返回不触发落库（flush 幂等）', (tester) async {
    final update = MockUpdateNote();
    await tester.pumpWidget(app('n1', stubbedGetWith(''), update: update));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    verifyNever(() => update(any()));
  });

  group('删除：更多菜单 = 二次确认 → 删 → 回列表', () {
    const String confirmBody = '确定要删除这篇笔记吗？删除后可在「最近删除」中恢复。';

    /// 展开「更多」菜单并点「删除」—— 删除项的入口。
    Future<void> tapDelete(WidgetTester tester) async {
      await tester.tap(find.byIcon(AppIcons.overflow));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note_delete')));
      await tester.pumpAndSettle();
    }

    testWidgets('点「删除」弹确认；取消不调 UseCase', (tester) async {
      final del = MockDeleteNote();
      when(() => del(any())).thenAnswer((_) async => const Right(unit));
      await tester.pumpWidget(app('n1', stubbedGet(), delete: del));
      await tester.pumpAndSettle();

      await tapDelete(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(confirmBody), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();

      verifyNever(() => del(any()));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(NoteDetailScreen), findsOneWidget);
    });

    testWidgets('确认删除：收到真实 noteId 并跳回 /notes', (tester) async {
      final del = MockDeleteNote();
      when(() => del(any())).thenAnswer((_) async => const Right(unit));
      await tester.pumpWidget(app('n1', stubbedGet(), delete: del));
      await tester.pumpAndSettle();

      await tapDelete(tester);
      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      verify(() => del('n1')).called(1);
      expect(
        find.byType(NoteDetailScreen),
        findsNothing,
        reason: '成功删除后回列表，留着详情页只会显示一张读不到数据的空壳',
      );
    });

    testWidgets('删除失败：留在详情页并弹 Snackbar', (tester) async {
      final del = MockDeleteNote();
      when(
        () => del(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'boom')));
      await tester.pumpWidget(app('n1', stubbedGet(), delete: del));
      await tester.pumpAndSettle();

      await tapDelete(tester);
      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      expect(find.byType(NoteDetailScreen), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
    });

    testWidgets('新建笔记（未落库）：更多菜单禁用，点了不弹也不删', (tester) async {
      final del = MockDeleteNote();
      when(() => del(any())).thenAnswer((_) async => const Right(unit));
      await tester.pumpWidget(app(kNewNoteId, MockGetNote(), delete: del));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.overflow));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => del(any()));
    });
  });

  group('自动保存失败：弹 Snackbar，且只弹一次', () {
    testWidgets('落库失败弹 failure 文案；clearFailure 后不重复弹', (tester) async {
      final update = MockUpdateNote();
      // ⚠️ `app()` 会给非 null 的 update 打一层成功默认桩，故失败桩必须**在它之后**打。
      final widget = app('n1', stubbedGet(), update: update);
      when(
        () => update(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '新标题');
      // 等 500ms debounce 触发自动保存。
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      verify(() => update(any())).called(1);
      expect(find.text('disk full'), findsOneWidget);

      // 再触发一次失败：Snackbar 只有一个（上次弹完即 clearFailure）。
      await tester.enterText(find.byType(TextField).first, '再改一次');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('disk full'), findsOneWidget);
    });

    testWidgets('保存成功不弹 Snackbar', (tester) async {
      final update = MockUpdateNote();
      await tester.pumpWidget(app('n1', stubbedGet(), update: update));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '新标题');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      verify(() => update(any())).called(1);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
