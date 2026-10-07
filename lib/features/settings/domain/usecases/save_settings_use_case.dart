import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';

/// 写用户偏好。**全量写 6 个标量**，不计算字段 diff。
///
/// 零逻辑的薄封装（与 `GetSettingsUseCase` 同理）。写失败只返回 `Left`，
/// **不回滚内存里的 state**：偏好写失败弹错误框是过度设计，用户无法修复；
/// 回滚逻辑归 `settingsProvider`（`TASK-045`）。
class SaveSettingsUseCase {
  const SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, Unit>> call(AppSettings settings) {
    return _repository.save(settings);
  }
}
