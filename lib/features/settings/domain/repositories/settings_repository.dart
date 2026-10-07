import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';

/// 用户偏好的领域抽象。实现在 data 层（`TASK-022`）。
///
/// **这是唯一一个不经过 DataSource 的 Repository 实现** —— 直接用
/// `core/storage/local_storage_service.dart`。只有 6 个标量、一次 JSON 读、
/// 一次 JSON 写，再包一层 `SettingsLocalDataSource` 是三层壳包一个
/// `getObject` / `setObject`，纯样板（`REPOSITORY-MAP.md` §2.4）。
abstract class SettingsRepository {
  /// 读偏好。
  ///
  /// ⚠️ **读不到 / JSON 损坏 / 单个字段类型错时一律返回 `Right`**，绝不返回
  /// `Left`：偏好读不出来不该把启动链路拖成错误态，用户也无法修复。
  /// 字段级错误**逐字段**回落默认值，不整份丢弃（`TASK-029` §2 的要求 2 / 3）。
  Future<Either<Failure, AppSettings>> load();

  /// 写偏好。**全量写 6 个标量**，不计算字段 diff。
  Future<Either<Failure, Unit>> save(AppSettings settings);
}
