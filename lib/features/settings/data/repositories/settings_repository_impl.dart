import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/storage/local_storage_service.dart';
import 'package:init/core/theme/app_color_scheme.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';

/// 偏好在 `SharedPreferences` 里的 key。**单 key JSON**（ADR-14）。
const String settingsStorageKey = 'app_settings';

/// 当前支持的 schema 版本。写在 JSON 里，与数据同生共死 ——
/// 不可能出现「数据在、版本标记丢了」的不一致。
///
/// ⚠️ 读的时候**不据此拒绝**：比当前高的版本走逐字段回落（认识的字段照读，
/// 不认识的忽略），不删 key、不整份重置 —— 整份重置会静默清掉用户的强提醒开关。
const int settingsSchemaVersion = 1;

/// `SettingsRepository` 的唯一实现。⛔ **不注入 logger**：Repository 没有 `Ref`，
/// 为它注入一个日志回调是纯样板；读失败静默回落默认值的理由写在 [load] 上。
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._storage);

  final LocalStorageService _storage;

  @override
  Future<Either<Failure, AppSettings>> load() async {
    try {
      final raw = _storage.getObject(settingsStorageKey);
      if (raw is! Map) {
        // 无 key / 写进去的不是 JSON 对象
        return const Right(AppSettings.defaults());
      }
      return Right(_fromJson(raw.cast<String, Object?>()));
    } on CacheException {
      // JSON 坏掉（getObject 内部已包成 CacheException）
      return const Right(AppSettings.defaults());
    } catch (_) {
      // 兜底：偏好读不出来不该阻断启动，用户也无法修复
      return const Right(AppSettings.defaults());
    }
  }

  @override
  Future<Either<Failure, Unit>> save(AppSettings settings) async {
    try {
      await _storage.setObject(settingsStorageKey, _toJson(settings));
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

/// enum 一律按 **`name`** 序列化，不用 `index`：`index` 在枚举顺序变化时会把用户
/// 偏好静默改成另一个值；`name` 不认识时回落默认值。
Map<String, Object?> _toJson(AppSettings s) {
  return <String, Object?>{
    'schemaVersion': settingsSchemaVersion,
    'textScale': s.textScale.name,
    'noteSort': s.noteSort.name,
    'noteLayout': s.noteLayout.name,
    'strongReminder': s.strongReminder,
    'locale': s.locale,
    'themeMode': s.themeMode.name,
    'colorScheme': s.colorScheme.name,
  };
}

/// **逐字段**回落：单个字段类型错（`textScale: 123`、enum 名不存在、
/// `strongReminder: "yes"`）只让**该字段**回默认值，其余字段正常读出。
/// 绝不整份回落到 `defaults` —— 那会把用户其他正确的偏好一起清掉。
/// 未知的 key 一律忽略（老版本残留 / 未来版本写入 / 人手加的）。
AppSettings _fromJson(Map<String, Object?> json) {
  const d = AppSettings.defaults();
  return AppSettings(
    textScale: _byName(TextScaleLevel.values, json['textScale']) ?? d.textScale,
    noteSort: _byName(AppNoteSort.values, json['noteSort']) ?? d.noteSort,
    noteLayout: _byName(NoteLayout.values, json['noteLayout']) ?? d.noteLayout,
    strongReminder: switch (json['strongReminder']) {
      final bool v => v,
      _ => d.strongReminder,
    },
    locale: switch (json['locale']) {
      // 空串不是合法的语言码：null 才是「跟系统」的语义。库里存进 `''` 只可能来自
      // 手改或旧版本 bug，构造 `Locale('')` 会得到一个匹配不到任何语言的实例。
      final String v when v.isNotEmpty => v,
      _ => null,
    },
    themeMode: _byName(AppThemeMode.values, json['themeMode']) ?? d.themeMode,
    colorScheme:
        _byName(AppColorScheme.values, json['colorScheme']) ?? d.colorScheme,
  );
}

/// 按 enum 的 **name** 查值。类型不是 `String` 或名字不认识都返回 `null`
/// （= 让调用方回落默认值）。`asNameMap()` 是 SDK 自带的 `EnumByName`，
/// 不用引入 `collection` 包做线性查找。
T? _byName<T extends Enum>(List<T> values, Object? raw) {
  return raw is String ? values.asNameMap()[raw] : null;
}
