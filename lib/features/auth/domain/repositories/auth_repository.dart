import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// 使用邮箱和密码登录用户
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// 注册新用户
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  /// 退出当前用户登录
  Future<Either<Failure, void>> logout();

  /// 检查用户是否已认证
  Future<Either<Failure, bool>> isAuthenticated();

  /// 获取当前已认证的用户
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// 更新当前用户资料信息
  Future<Either<Failure, UserEntity>> updateProfile(UserEntity user);
}
