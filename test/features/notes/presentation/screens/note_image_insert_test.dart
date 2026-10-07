import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/ui/ui.dart';
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

/// 1×1 的红像素 JPEG 在测试里没必要真解码 —— 这里只验证「插入链路」，
/// 解不了会走 `errorBuilder`，`Image` 这个 widget 依然会被建出来。
final _bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]);

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
  });

  /// 与 `note_detail_screen_test.dart` 同一套壳（GoRouter + 本地化 + settings
  /// 假仓库），只把「挑图片」换成 mock —— 这条链路是本次唯一被测对象。
  Widget app(MockPickNoteImage pick) {
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
    // 插入图片 → 正文变脏 → debounce 到点后自动 flush。不 stub 会拿到 null。
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

  Future<void> pumpWith(
    WidgetTester tester,
    MockPickNoteImage pick,
  ) async {
    await tester.pumpWidget(app(pick));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.image));
    await tester.pumpAndSettle();
  }

  testWidgets('点工具条图片按钮 → 正文出现图片', (tester) async {
    final pick = MockPickNoteImage();
    when(
      () => pick(compress: any(named: 'compress')),
    ).thenAnswer((_) async => Right(<NoteImage>[NoteImage(bytes: _bytes, mime: 'image/jpeg')]));

    await pumpWith(tester, pick);

    expect(find.byType(Image), findsOneWidget);
    verify(() => pick(compress: true)).called(1);
  });

  testWidgets('压缩开关关掉 → 原图直插（compress: false）', (tester) async {
    final pick = MockPickNoteImage();
    final settingsRepo = MockSettingsRepository();
    when(() => settingsRepo.load()).thenAnswer(
      (_) async => Right<Failure, AppSettings>(
        AppSettings.defaults().copyWith(compressImages: false),
      ),
    );
    when(
      () => pick(compress: any(named: 'compress')),
    ).thenAnswer((_) async => Right(<NoteImage>[NoteImage(bytes: _bytes, mime: 'image/jpeg')]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
        child: app(pick),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.image));
    await tester.pumpAndSettle();

    verify(() => pick(compress: false)).called(1);
  });

  testWidgets('挑图失败 → 提示且不插入图片', (tester) async {
    final pick = MockPickNoteImage();
    when(
      () => pick(compress: any(named: 'compress')),
    ).thenAnswer((_) async => const Left<Failure, List<NoteImage>>(ImageFailure()));

    await pumpWith(tester, pick);

    expect(find.textContaining('图片插入失败'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('用户取消（空列表）→ 静默返回，不插入也不提示', (tester) async {
    final pick = MockPickNoteImage();
    when(
      () => pick(compress: any(named: 'compress')),
    ).thenAnswer((_) async => const Right<Failure, List<NoteImage>>(<NoteImage>[]));

    await pumpWith(tester, pick);

    expect(find.byType(Image), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
