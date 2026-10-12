import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';

/// 读用户偏好。启动时调一次填充设置。
///
/// **零逻辑的薄封装**：「16 个动作一个签名」是本项目的既定决定，
/// 这里不加任何额外分支。
/// 容错不在这一层：`load()` 读不出来返回 `Right(defaults)`，由 Repository 保证。
class GetSettingsUseCase {
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, AppSettings>> call(NoParams params) {
    return _repository.load();
  }
}
