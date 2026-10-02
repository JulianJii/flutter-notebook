import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当 GraphQL 端点返回 `errors` 数组时抛出（成功的 HTTP 200 仍可能携带
/// GraphQL 级别的错误），或者当传输本身失败时抛出。
class GraphQLException implements Exception {
  GraphQLException(this.errors);

  final List<String> errors;

  @override
  String toString() => errors.join('; ');
}

/// 基于 Dio 构建的轻量 GraphQL 客户端。
///
/// GraphQL over HTTP 只是一个带有 JSON 主体 `{query, variables, operationName}`
/// 的 POST 请求和一个 JSON 响应 `{data, errors}`——无需专用的客户端库
///（及其自身的状态管理/widget 树约定）即可在已拥有 HTTP 客户端和 Riverpod
/// 的应用中使用。`query` 和 `mutate` 在底层是相同的操作；
/// 它们只是为了在调用点提高可读性而拆分。
class GraphQLClient {
  GraphQLClient(this._dio, {required this.endpoint});

  final Dio _dio;
  final String endpoint;

  Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) => _execute(document, variables: variables, operationName: operationName);

  Future<Map<String, dynamic>> mutate(
    String document, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) => _execute(document, variables: variables, operationName: operationName);

  Future<Map<String, dynamic>> _execute(
    String document, {
    Map<String, dynamic>? variables,
    String? operationName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: {
          'query': document,
          'variables': ?variables,
          'operationName': ?operationName,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final body = response.data ?? const <String, dynamic>{};
      final errors = body['errors'] as List<dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        throw GraphQLException(
          errors
              .map(
                (e) =>
                    (e as Map<String, dynamic>)['message']?.toString() ??
                    'Unknown GraphQL error',
              )
              .toList(),
        );
      }
      return (body['data'] as Map<String, dynamic>?) ?? const {};
    } on DioException catch (e) {
      throw GraphQLException([e.message ?? 'Network error']);
    }
  }
}

/// 每个 [endpoint] 一个客户端，这样屏幕可以与多个 GraphQL API 通信
/// 而不会共享 header/拦截器。
final graphQLClientProvider = Provider.autoDispose
    .family<GraphQLClient, String>(
      (ref, endpoint) => GraphQLClient(Dio(), endpoint: endpoint),
    );
