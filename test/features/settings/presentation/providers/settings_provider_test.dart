import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_color_scheme.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repo;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(const AppSettings.defaults()));

  setUp(() {
    repo = _MockSettingsRepository();
    when(() => repo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  /// 让 microtask 里的 `_load` 跑完（`build()` 同步返回默认值，加载是异步的）。
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('初始 state 是默认值', () async {
    expect(container.read(settingsProvider), AppSettings.defaults());
    await settle();
  });

  test('加载成功：state 被替换为持久化值', () async {
    const stored = AppSettings(
      textScale: TextScaleLevel.large,
      noteLayout: NoteLayout.list,
    );
    when(
      () => repo.load(),
    ).thenAnswer((_) async => const Right<Failure, AppSettings>(stored));

    expect(container.read(settingsProvider), AppSettings.defaults());
    await settle();
    expect(container.read(settingsProvider), stored);
  });

  test('加载失败：state 保持默认值，不崩', () async {
    when(
      () => repo.load(),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'boom')));

    container.read(settingsProvider);
    await settle();
    expect(container.read(settingsProvider), AppSettings.defaults());
  });

  test('加载落地前用户已改过偏好：旧快照不覆盖用户的选择', () async {
    when(() => repo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(
        AppSettings(textScale: TextScaleLevel.small),
      ),
    );

    container.read(settingsProvider);
    container
        .read(settingsProvider.notifier)
        .setTextScale(TextScaleLevel.xLarge);
    await settle();

    expect(container.read(settingsProvider).textScale, TextScaleLevel.xLarge);
  });

  test('setNoteSort 立即改变 state（不等 IO，同一事件循环内）', () async {
    container.read(settingsProvider.notifier).setNoteSort(AppNoteSort.titleAsc);
    expect(container.read(settingsProvider).noteSort, AppNoteSort.titleAsc);
    await settle();
  });

  test('set* 调用一次 save，传入完整对象且只改一个字段', () async {
    container.read(settingsProvider.notifier).setNoteLayout(NoteLayout.list);
    await settle();

    final captured =
        verify(() => repo.save(captureAny())).captured.single as AppSettings;
    expect(captured.noteLayout, NoteLayout.list);
    // 关键回归：set* 只改一个字段，其余**不能**被 copyWith 清空。
    expect(captured.textScale, AppSettings.defaults().textScale);
    expect(captured.noteSort, AppSettings.defaults().noteSort);
    expect(captured.themeMode, AppSettings.defaults().themeMode);
  });

  test('setColorScheme 立即改 state，且不动 themeMode（两个维度互不覆盖）', () async {
    final n = container.read(settingsProvider.notifier);
    n.setThemeMode(AppThemeMode.dark);
    n.setColorScheme(AppColorScheme.green);

    final s = container.read(settingsProvider);
    expect(s.colorScheme, AppColorScheme.green);
    expect(s.themeMode, AppThemeMode.dark);
    verify(() => repo.save(any())).called(2);
    await settle();
  });

  test('3 个 setter 各改各的字段', () async {
    final n = container.read(settingsProvider.notifier);
    n.setTextScale(TextScaleLevel.xLarge);
    n.setNoteSort(AppNoteSort.createdDesc);
    n.setNoteLayout(NoteLayout.list);
    await settle();

    final s = container.read(settingsProvider);
    expect(s.textScale, TextScaleLevel.xLarge);
    expect(s.noteSort, AppNoteSort.createdDesc);
    expect(s.noteLayout, NoteLayout.list);
    verify(() => repo.save(any())).called(3);
  });

  test('设置与当前相同的值不触发写入', () async {
    // grid 已是默认值
    container.read(settingsProvider.notifier).setNoteLayout(NoteLayout.grid);
    await settle();
    verifyNever(() => repo.save(any()));
  });

  test('写失败：state 保持新值，不回滚、不抛异常', () async {
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));

    container
        .read(settingsProvider.notifier)
        .setTextScale(TextScaleLevel.xLarge);
    await settle();

    expect(container.read(settingsProvider).textScale, TextScaleLevel.xLarge);
  });

  test('textScaleFactor 随 textScale 变化（4 档线性）', () async {
    expect(container.read(textScaleFactorProvider), 1.0);

    final n = container.read(settingsProvider.notifier);
    n.setTextScale(TextScaleLevel.small);
    expect(container.read(textScaleFactorProvider), 0.875);
    n.setTextScale(TextScaleLevel.large);
    expect(container.read(textScaleFactorProvider), 1.125);
    n.setTextScale(TextScaleLevel.xLarge);
    expect(container.read(textScaleFactorProvider), 1.25);
    await settle();
  });

  test('公开面：provider 文件不 re-export repository / use case', () {
    // `FEATURE-DEPENDENCIES.md` §5.1：settings 的公开面只有 settingsProvider
    // 与 AppSettings。这里用源码级断言守住 —— 一旦有人加了 export，测试就红。
    final source = File(
      'lib/features/settings/presentation/providers/settings_provider.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('export ')));
    expect(source, isNot(contains('../data/')));
  });
}
