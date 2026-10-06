import 'package:fpdart/fpdart.dart';

import 'package:init/core/error/failures.dart';

import '../entities/webdav_config.dart';
import '../repositories/backup_repository.dart';

/// 用**当前表单里还没保存**的配置探一次服务器。
///
/// ⛔ 不复用 [SaveWebDavConfigUseCase] + 同步：测试连接不该把一份可能填错的
/// 配置写进本地，也不该动数据。
class TestWebDavUseCase {
  const TestWebDavUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, Unit>> call(WebDavConfig config) {
    return _repository.testConnection(config);
  }
}
