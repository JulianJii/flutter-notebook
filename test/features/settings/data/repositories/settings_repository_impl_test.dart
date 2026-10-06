import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/storage/local_storage_service.dart';
import 'package:init/core/theme/app_color_scheme.dart';
import 'package:init/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocalStorageService extends Mock implements LocalStorageService {}

void main() {
  late _MockLocalStorageService storage;
  late SettingsRepositoryImpl repo;

  setUp(() {
    storage = _MockLocalStorageService();
    repo = SettingsRepositoryImpl(storage);
  });

  /// 走**真的** `LocalStorageService`（不 mock）：容错契约验证的是 JSON 解析，
  /// mock 掉解析等于把要测的东西一起 mock 掉。
  Future<SettingsRepositoryImpl> realRepo(Map<String, Object> seed) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepositoryImpl(LocalStorageService(prefs));
  }

  group('load', () {
    test('无 key -> Right(defaults)', () async {
      when(() => storage.getObject(any())).thenReturn(null);
      expect(
        await repo.load(),
        const Right<Failure, AppSettings>(AppSettings.defaults()),
      );
    });

    test('往返一致：save(X) -> load() == X（7 字段逐字段相等）', () async {
      const x = AppSettings(
        textScale: TextScaleLevel.xLarge,
        noteSort: AppNoteSort.titleAsc,
        noteLayout: NoteLayout.list,
        strongReminder: true,
        locale: 'en',
        themeMode: AppThemeMode.dark,
        colorScheme: AppColorScheme.violet,
      );
      final real = await realRepo({});

      expect(await real.save(x), const Right<Failure, Unit>(unit));
      expect(await real.load(), const Right<Failure, AppSettings>(x));
    });

    test('未知字段被忽略，其余字段正常读出', () async {
      final real = await realRepo({
        settingsStorageKey:
            '{"schemaVersion":1,"textScale":"large","foo":1,"bar":{"a":2}}',
      });
      final result = await real.load();
      result.fold(
        (f) => fail('应为 Right，实际 $f'),
        (s) => expect(s.textScale, TextScaleLevel.large),
      );
    });

    test('单字段类型错 -> 只有该字段回落，其余字段正确（绝不整份重置）', () async {
      final real = await realRepo({
        settingsStorageKey:
            '{"schemaVersion":1,"textScale":123,"noteSort":"NOPE",'
            '"strongReminder":"yes","noteLayout":"list","themeMode":"light"}',
      });
      final result = await real.load();
      result.fold((f) => fail('应为 Right，实际 $f'), (s) {
        expect(s.textScale, TextScaleLevel.normal, reason: '类型错 → 默认');
        expect(s.noteSort, AppNoteSort.editedDesc, reason: 'enum 名不认识 → 默认');
        expect(s.strongReminder, isFalse, reason: '类型错 → 默认');
        expect(s.noteLayout, NoteLayout.list, reason: '正确的字段必须保留');
        expect(s.themeMode, AppThemeMode.light, reason: '正确的字段必须保留');
      });
    });

    test('JSON 损坏 -> Right(defaults)，不返回 Left', () async {
      final real = await realRepo({settingsStorageKey: '{ not json'});
      expect(
        await real.load(),
        const Right<Failure, AppSettings>(AppSettings.defaults()),
      );
    });

    test('未知 schemaVersion -> 逐字段回落，不删 key、不整份重置', () async {
      final real = await realRepo({
        settingsStorageKey: '{"schemaVersion":99,"strongReminder":true}',
      });
      final result = await real.load();
      result.fold((f) => fail('应为 Right，实际 $f'), (s) {
        expect(s.strongReminder, isTrue, reason: '认识的字段照读');
        expect(s.textScale, TextScaleLevel.normal);
      });
      (await real.load()).fold(
        (f) => fail('应为 Right，实际 $f'),
        (s) => expect(s.strongReminder, isTrue, reason: 'key 没被删'),
      );
    });

    test('顶层是合法 JSON 但是 List -> Right(defaults)，不抛异常', () async {
      final real = await realRepo({settingsStorageKey: '[1,2,3]'});
      expect(
        await real.load(),
        const Right<Failure, AppSettings>(AppSettings.defaults()),
      );
    });

    test('顶层是 JSON 标量（字符串 / 数字）-> Right(defaults)', () async {
      for (final raw in <String>['"hello"', '42', 'true']) {
        final real = await realRepo({settingsStorageKey: raw});
        expect(
          await real.load(),
          const Right<Failure, AppSettings>(AppSettings.defaults()),
          reason: 'raw=$raw',
        );
      }
    });

    test('save 后落地的 key 只有一个 data key + JSON 内嵌 schemaVersion', () async {
      final real = await realRepo({});
      await real.save(AppSettings.defaults());
      final prefs = await SharedPreferences.getInstance();

      // ADR-14：单 key JSON。⛔ 不另开一个 int 版本 key —— 独立 key 会出现
      // 「数据在、版本标记丢了」的不一致状态，而版本号与数据同生共死就没有。
      expect(
        prefs.getKeys().where((k) => k.startsWith('app_settings')),
        <String>[settingsStorageKey],
      );
    });
  });

  /// TASK-044 路径 3 的完整矩阵：**逐字段**验证，每条坏值只影响自己。
  group('单字段类型错：逐字段回落（其余字段必须保留）', () {
    Future<AppSettings> loadWith(String rawJson) async {
      final real = await realRepo({settingsStorageKey: rawJson});
      return (await real.load()).fold((f) => fail('应为 Right，实际 $f'), (s) => s);
    }

    test('strongReminder 写成 String', () async {
      final s = await loadWith(
        '{"textScale":"large","noteSort":"editedAsc","noteLayout":"list",'
        '"strongReminder":"yes","themeMode":"dark","locale":"en"}',
      );
      expect(s.strongReminder, isFalse, reason: '坏字段回落默认');
      expect(s.textScale, TextScaleLevel.large);
      expect(s.noteSort, AppNoteSort.editedAsc);
      expect(s.noteLayout, NoteLayout.list);
      expect(s.themeMode, AppThemeMode.dark);
      expect(s.locale, 'en');
    });

    test('textScale 写成 int', () async {
      final s = await loadWith('{"textScale":1,"noteSort":"titleAsc"}');
      expect(s.textScale, TextScaleLevel.normal);
      expect(s.noteSort, AppNoteSort.titleAsc);
    });

    test('noteSort 写成 List', () async {
      final s = await loadWith(
        '{"noteSort":["editedDesc"],"noteLayout":"list"}',
      );
      expect(s.noteSort, AppNoteSort.editedDesc);
      expect(s.noteLayout, NoteLayout.list);
    });

    test('themeMode 写成 int', () async {
      final s = await loadWith('{"themeMode":3,"noteLayout":"list"}');
      expect(s.themeMode, AppThemeMode.system);
      expect(s.noteLayout, NoteLayout.list);
    });

    test('colorScheme 写成 int / 未知名 -> amber', () async {
      for (final raw in <String>['3', '"NOPE"', 'null']) {
        final s = await loadWith('{"colorScheme":$raw,"themeMode":"dark"}');
        expect(s.colorScheme, AppColorScheme.amber, reason: 'raw=$raw');
        expect(s.themeMode, AppThemeMode.dark, reason: '其余字段必须保留');
      }
    });

    test('locale 写成 int / 空串 -> null（null = 跟系统）', () async {
      for (final raw in <String>['42', '""']) {
        final s = await loadWith('{"locale":$raw,"noteLayout":"list"}');
        expect(s.locale, isNull, reason: 'raw=$raw');
        expect(s.noteLayout, NoteLayout.list);
      }
    });

    // ⚠️ **不支持但非空**的语言码（`"zz"`）在本层原样读出：data 层是纯 Dart，
    // ⛔ 不 import `gen/l10n`，也无从知道哪些语言码受支持。判定交给构造 `Locale`
    // 的那一层（`core/localization` 的 `isSupportedLocale`，TASK-045/046）。
    // 本层只负责「不是字符串 → 回落」与「空串 → 回落」这两种无争议的情况。
    test('不支持但非空的语言码：本层原样读出，判定交给 presentation 层', () async {
      final s = await loadWith('{"locale":"zz","noteLayout":"list"}');
      expect(s.locale, 'zz');
      expect(s.noteLayout, NoteLayout.list);
    });

    test('enum 名不认识（未来值 / 被改名）', () async {
      final s = await loadWith('{"textScale":"huge","noteLayout":"list"}');
      expect(s.textScale, TextScaleLevel.normal);
      expect(s.noteLayout, NoteLayout.list);
    });
  });

  group('save', () {
    test('成功 -> Right(unit)，且写的是单 key JSON', () async {
      final real = await realRepo({});
      expect(
        await real.save(AppSettings.defaults()),
        const Right<Failure, Unit>(unit),
      );

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(settingsStorageKey)!;
      expect(json, contains('"schemaVersion":$settingsSchemaVersion'));
      expect(
        json,
        contains('"noteSort":"editedDesc"'),
        reason: 'enum 按 name 序列化',
      );
    });

    test('CacheException -> Left(CacheFailure)', () async {
      when(
        () => storage.setObject(any(), any()),
      ).thenThrow(CacheException(message: 'Failed to save data'));
      final result = await repo.save(AppSettings.defaults());
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });

    test('未知异常 -> Left(CacheFailure)，不 rethrow', () async {
      when(() => storage.setObject(any(), any())).thenThrow(StateError('boom'));
      final result = await repo.save(AppSettings.defaults());
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('AppSettings', () {
    test('默认值与 ARCHITECTURE-DESIGN §2.13 的表格一致', () {
      const d = AppSettings.defaults();
      expect(d.textScale, TextScaleLevel.normal);
      expect(d.noteSort, AppNoteSort.editedDesc);
      expect(d.noteLayout, NoteLayout.grid);
      expect(d.strongReminder, isFalse);
      expect(d.locale, isNull, reason: '跟系统');
      expect(d.themeMode, AppThemeMode.system);
      expect(d.colorScheme, AppColorScheme.amber);
    });

    test('值相等：默认构造 == defaults()', () {
      expect(const AppSettings(), const AppSettings.defaults());
    });

    test('copyWith(locale: null) 真的把语言切回「跟系统」', () {
      const withLocale = AppSettings(locale: 'en');
      expect(withLocale.copyWith(locale: null).locale, isNull);
      expect(withLocale.copyWith().locale, 'en');
    });
  });
}
