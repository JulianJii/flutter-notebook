import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';

import '../entities/webdav_config.dart';
import '../repositories/backup_repository.dart';

/// 读 WebDAV 配置。读不到返回默认值（未配置），不返回 `Left` ——
/// 「还没配过服务器」是正常状态，不是错误。
class GetWebDavConfigUseCase {
  const GetWebDavConfigUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, WebDavConfig>> call(NoParams params) {
    return _repository.loadConfig();
  }
}
