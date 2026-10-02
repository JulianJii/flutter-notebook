import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/network/api_client.dart';
import 'package:init/core/providers/network_providers.dart';
import 'package:init/core/utils/app_utils.dart';
import 'package:init/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  /// 使用邮箱和密码登录用户
  Future<UserModel> login({required String email, required String password});

  /// 注册新用户
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(/*this._apiClient*/);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // 检查网络连接
      final hasNetwork = await AppUtils.hasNetworkConnection();
      if (!hasNetwork) {
        throw NetworkException();
      }

      // 在真实应用中，这里会发起 API 调用
      // 在本模板中，我们模拟一次成功的登录

      // 模拟带延迟的后端调用
      await Future.delayed(const Duration(seconds: 1));

      // 创建用于演示的模拟用户
      return UserModel(
        id: 'user-123',
        name: 'John Doe',
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 在真实实现中：
      // final response = await _apiClient.post('/auth/login', data: {
      //   'email': email,
      //   'password': password,
      // });
      // return UserModel.fromJson(response['user']);
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 检查网络连接
      final hasNetwork = await AppUtils.hasNetworkConnection();
      if (!hasNetwork) {
        throw NetworkException();
      }

      // 在真实应用中，这里会发起 API 调用
      // 在本模板中，我们模拟一次成功的注册

      // 模拟带延迟的后端调用
      await Future.delayed(const Duration(seconds: 1));

      // 创建用于演示的模拟用户
      return UserModel(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 在真实实现中：
      // final response = await _apiClient.post('/auth/register', data: {
      //   'name': name,
      //   'email': email,
      //   'password': password,
      // });
      // return UserModel.fromJson(response['user']);
    } on Exception catch (e) {
      throw _handleException(e);
    }
  }

  // 处理异常的辅助方法
  Exception _handleException(Exception e) {
    if (e is NetworkException ||
        e is ServerException ||
        e is UnauthorizedException ||
        e is BadRequestException) {
      return e;
    }
    return ServerException(message: e.toString());
  }
}

// Provider 定义
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  // final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(/*apiClient*/);
});

// ApiClient provider 定义
final apiClientProvider = Provider.autoDispose<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});
