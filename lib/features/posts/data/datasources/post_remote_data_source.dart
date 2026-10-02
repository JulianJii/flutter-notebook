import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/utils/app_utils.dart';
import 'package:init/features/posts/data/models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getPosts();
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  // final ApiClient _apiClient;

  PostRemoteDataSourceImpl(/*this._apiClient*/);

  @override
  Future<List<PostModel>> getPosts() async {
    final hasNetwork = await AppUtils.hasNetworkConnection();
    if (!hasNetwork) {
      throw NetworkException();
    }

    // 在真实应用中，这里会发起 API 调用，例如：
    // final response = await _apiClient.get('/posts');
    // return (response as List)
    //     .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
    //     .toList();

    // 模拟带延迟的后端调用，与模板中 auth/survey 功能一致，
    // 无需配置后端即可开箱即用。
    await Future.delayed(const Duration(milliseconds: 600));

    return List.generate(12, (index) {
      final id = index + 1;
      return PostModel(
        id: '$id',
        authorName: 'Author ${(id % 4) + 1}',
        title: 'Post #$id: Building with Clean Architecture',
        body:
            'This is a sample post body demonstrating the posts feed feature, '
            'backed by a repository that caches results locally for offline '
            'viewing. Post index: $id.',
        publishedAt: DateTime.now().subtract(Duration(hours: id * 3)),
      );
    });
  }
}

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSourceImpl();
});
