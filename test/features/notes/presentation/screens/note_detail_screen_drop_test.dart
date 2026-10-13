import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';
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
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
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

/// 1×1 的红像素 JPEG 在测试里没必要真解码 —— 这里只验证「拖入链路」。
final Uint8List _bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]);

final DateTime _fixed = DateTime(2026, 10, 3, 6, 40);
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
    registerFallbackValue(const <String>[]);
  });

  /// 与 `note_image_insert_test.dart` 同一套壳，只把「挑图片」换成 mock。
  Widget app(MockPickNoteImage pick, MockSettingsRepository settingsRepo) {
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

    final get = MockGetNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note));
    final update = MockUpdateNote();
    when(() => update(any())).thenAnswer((_) async => Right(_note));

    return ProviderScope(
      overrides: [
        getNoteUseCaseProvider.overrideWithValue(get),
        updateNoteUseCaseProvider.overrideWithValue(update),
        createNoteUseCaseProvider.overrideWithValue(MockCreateNote()),
        deleteNoteUseCaseProvider.overrideWithValue(MockDeleteNote()),
        updateNoteBackgroundUseCaseProvider.overrideWithValue(
          MockUpdateNoteBackground(),
        ),
        pickNoteImageUseCaseProvider.overrideWithValue(pick),
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

  /// 已预热设置（同 `note_image_insert_test`：详情页不读设置，压缩开关由 `fromPaths`
  /// 的调用方读 —— 默认值就是「压缩开」）。
  Future<void> pumpEditor(WidgetTester tester, MockPickNoteImage pick) async {
    final settingsRepo = MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => settingsRepo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await tester.pumpWidget(app(pick, settingsRepo));
    await tester.pumpAndSettle();
    ProviderScope.containerOf(
      tester.element(find.byType(NoteDetailScreen)),
      listen: false,
    ).read(settingsProvider);
    await tester.pumpAndSettle();
  }

  /// 直接喂 `DropTarget` 的回调 —— `desktop_drop` 的平台侧是原生插件，widget 测试
  /// 里没有真实的拖放事件；`DropDoneDetails` 是公开的 const 构造，可以自己造。
  DropTarget dropTarget(WidgetTester tester) =>
      tester.widget<DropTarget>(find.byType(DropTarget));

  DropDoneDetails detailsOf(List<String> paths) => DropDoneDetails(
    files: <DropItem>[for (final path in paths) DropItemFile(path)],
    localPosition: Offset.zero,
    globalPosition: Offset.zero,
  );

  /// 记录 `fromPaths` 收到的路径，并按 [images] 回答。
  MockPickNoteImage stubPick({required List<NoteImage> images}) {
    final pick = MockPickNoteImage();
    when(
      () => pick.fromPaths(any(), compress: any(named: 'compress')),
    ).thenAnswer((_) async => Right(images));
    return pick;
  }

  testWidgets('拖入图片 → 正文出现图片（与工具条插图同一条链路）', (tester) async {
    final pick = stubPick(
      images: <NoteImage>[NoteImage(bytes: _bytes, mime: 'image/jpeg')],
    );
    await pumpEditor(tester, pick);

    dropTarget(tester).onDragDone!(detailsOf(<String>['C:/tmp/a.png']));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    final paths = verify(
      () =>
          pick.fromPaths(captureAny(), compress: captureAny(named: 'compress')),
    ).captured;
    expect(paths.first, <String>['C:/tmp/a.png']);
    expect(paths.last, isTrue, reason: '设置里「图片压缩」默认开');
  });

  testWidgets('拖入多张 → 依次插入', (tester) async {
    final pick = stubPick(
      images: <NoteImage>[
        NoteImage(bytes: _bytes, mime: 'image/jpeg'),
        NoteImage(bytes: _bytes, mime: 'image/jpeg'),
      ],
    );
    await pumpEditor(tester, pick);

    dropTarget(tester).onDragDone!(
      detailsOf(<String>['C:/tmp/a.png', 'C:/tmp/b.jpg']),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('非图片文件被丢掉：不读字节、不插入、不提示', (tester) async {
    final pick = stubPick(images: <NoteImage>[]);
    await pumpEditor(tester, pick);

    dropTarget(tester).onDragDone!(
      detailsOf(<String>['C:/tmp/笔记.txt', 'C:/tmp/文件夹']),
    );
    await tester.pumpAndSettle();

    verifyNever(() => pick.fromPaths(any(), compress: any(named: 'compress')));
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('图片读不出来 / 超上限 → 提示且不插入', (tester) async {
    final pick = MockPickNoteImage();
    when(
      () => pick.fromPaths(any(), compress: any(named: 'compress')),
    ).thenAnswer(
      (_) async => const Left<Failure, List<NoteImage>>(ImageFailure()),
    );
    await pumpEditor(tester, pick);

    dropTarget(tester).onDragDone!(detailsOf(<String>['C:/tmp/huge.png']));
    await tester.pumpAndSettle();

    expect(find.textContaining('图片插入失败'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('拖动经过时浮出「可放下」提示，离开即消失', (tester) async {
    final pick = stubPick(images: <NoteImage>[]);
    await pumpEditor(tester, pick);

    final entered = DropEventDetails(
      localPosition: Offset.zero,
      globalPosition: Offset.zero,
    );
    expect(find.byKey(const Key('note_drop_highlight')), findsNothing);

    dropTarget(tester).onDragEntered!(entered);
    await tester.pump();
    expect(find.byKey(const Key('note_drop_highlight')), findsOneWidget);

    dropTarget(tester).onDragExited!(entered);
    await tester.pump();
    expect(find.byKey(const Key('note_drop_highlight')), findsNothing);
  });
}
