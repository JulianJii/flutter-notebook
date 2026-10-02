import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/core/storage/local_storage_service.dart';
import 'package:init/core/storage/secure_storage_service.dart';
import 'package:init/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:init/features/auth/data/models/user_model.dart';
import 'package:init/features/auth/domain/entities/user_entity.dart';
import 'package:init/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final LocalStorageService _localStorageService;
  final SecureStorageService _secureStorageService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required LocalStorageService localStorageService,
    required SecureStorageService secureStorageService,
  }) : _remoteDataSource = remoteDataSource,
       _localStorageService = localStorageService,
       _secureStorageService = secureStorageService;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // 将用户数据保存到本地
      await _localStorageService.setObject(
        AppConstants.userDataKey,
        response.toJson(),
      );

      // 安全地保存 auth token
      await _secureStorageService.write(
        key: AppConstants.tokenKey,
        value: response.id, // 演示起见，假设 token 存储在 id 中
      );

      return Right(response.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );

      // 将用户数据保存到本地
      await _localStorageService.setObject(
        AppConstants.userDataKey,
        response.toJson(),
      );

      // 安全地保存 auth token
      await _secureStorageService.write(
        key: AppConstants.tokenKey,
        value: response.id, // 演示起见，假设 token 存储在 id 中
      );

      return Right(response.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on BadRequestException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // 从本地存储中移除用户数据
      await _localStorageService.remove(AppConstants.userDataKey);

      // 从安全存储中移除 auth token
      await _secureStorageService.delete(key: AppConstants.tokenKey);

      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final token = await _secureStorageService.read(
        key: AppConstants.tokenKey,
      );
      return Right(token != null && token.isNotEmpty);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final userData = _localStorageService.getObject(AppConstants.userDataKey);

      if (userData == null) {
        return const Left(AuthFailure(message: 'User not found'));
      }

      final user = UserModel.fromJson(userData as Map<String, dynamic>);
      return Right(user.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(UserEntity user) async {
    try {
      final updated = UserModel.fromEntity(
        user.copyWith(updatedAt: DateTime.now()),
      );

      // 在本地保存更新后的用户资料。在真实应用中，
      // 还会通过数据源同步到远程后端。
      await _localStorageService.setObject(
        AppConstants.userDataKey,
        updated.toJson(),
      );

      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception {
      return const Left(ServerFailure());
    }
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService.create();
});

// Repository provider 定义
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localStorageService: ref.watch(localStorageServiceProvider),
    secureStorageService: ref.watch(secureStorageServiceProvider),
  );
});
