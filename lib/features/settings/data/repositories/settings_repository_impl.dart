import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/fonts/app_font.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/storage/local_storage_service.dart';
import 'package:mynote/core/theme/app_color_scheme.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';

/// 偏好在 `SharedPreferences` 里的 key。**单 key JSON**。
const String settingsStorageKey = 'app_settings';

/// 当前支持的 schema 版本。写在 JSON 里，与数据同生共死 ——
/// 不可能出现「数据在、版本标记丢了」的不一致。
///
/// ⚠️ 读的时候**不据此拒绝**：比当前高的版本走逐字段回落（认识的字段照读，
/// 不认识的忽略），不删 key、不整份重置 —— 整份重置会静默清掉用户的主题选择。
///
/// v2：`fontFamily`（系统族名 4 档）→ `uiFontId`（字体目录 id）。旧 key 由
/// 「未知 key 一律忽略」自然丢掉，旧值不需要迁移代码。
const int settingsSchemaVersion = 2;

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
    'uiFontId': s.uiFontId,
    'noteSort': s.noteSort.name,
    'noteLayout': s.noteLayout.name,
    'themeMode': s.themeMode.name,
    'colorScheme': s.colorScheme.name,
    'compressImages': s.compressImages,
    'noteVersionLimit': s.noteVersionLimit,
  };
}

/// **逐字段**回落：单个字段类型错（`fontFamily: 123`、enum 名不存在、
/// `themeMode: true`）只让**该字段**回默认值，其余字段正常读出。
/// 绝不整份回落到 `defaults` —— 那会把用户其他正确的偏好一起清掉。
/// 未知的 key 一律忽略（老版本残留 / 未来版本写入 / 人手加的）。
///
/// ⚠️ `textScale` 字段已下线（「文字大小」整项删除），旧数据里的残留 key 由
/// 「未知 key 一律忽略」自然丢掉，⛔ 不需要迁移代码。
AppSettings _fromJson(Map<String, Object?> json) {
  const d = AppSettings.defaults();
  return AppSettings(
    uiFontId: _fontId(json['uiFontId']),
    noteSort: _byName(AppNoteSort.values, json['noteSort']) ?? d.noteSort,
    noteLayout: _byName(NoteLayout.values, json['noteLayout']) ?? d.noteLayout,
    // ⚠️ `locale` 字段已下线（语言真源在 `core`），旧数据里残留的 `locale` key
    // 由「未知 key 一律忽略」逐字段回落的规则自然丢掉，不需要迁移代码。
    themeMode: _byName(AppThemeMode.values, json['themeMode']) ?? d.themeMode,
    colorScheme:
        _byName(AppColorScheme.values, json['colorScheme']) ?? d.colorScheme,
    compressImages: (json['compressImages'] as bool?) ?? d.compressImages,
    noteVersionLimit: _clampedInt(
      json['noteVersionLimit'],
      d.noteVersionLimit,
    ),
  );
}

/// 版本上限：不是 int、越界（含老快照的 0 / 负数）一律夹回边界内 ——
/// 非法值不该让整个偏好读不出来。
int _clampedInt(Object? raw, int fallback) {
  if (raw is! int) return fallback;
  return raw.clamp(minNoteVersionLimit, maxNoteVersionLimit);
}

/// 按 enum 的 **name** 查值。类型不是 `String` 或名字不认识都返回 `null`
/// （= 让调用方回落默认值）。`asNameMap()` 是 SDK 自带的 `EnumByName`，
/// 不用引入 `collection` 包做线性查找。
T? _byName<T extends Enum>(List<T> values, Object? raw) {
  return raw is String ? values.asNameMap()[raw] : null;
}

/// UI 字体 id：类型不是 `String`、或字符串**不在 `core/fonts` 目录里**，都返回
/// `null`（= 系统默认）。
///
/// ⚠️ 第二道校验不是多余的：字体目录会被裁剪 / 换源，落着一个目录里不存在的 id
/// 只会换来一个永远解析不到的族名 —— 那时用户看到的是「设置里写着某字体，
/// 显示却是系统字体」，比直接回落更难解释。
String? _fontId(Object? raw) => raw is String ? appFontById(raw)?.id : null;
