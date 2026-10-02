import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/core/storage/local_storage_service.dart';
import 'package:init/features/posts/data/models/post_model.dart';

/// 在设备上缓存最近获取的帖子，以便离线时仍能显示内容列表。
abstract class PostCacheDataSource {
  Future<List<PostModel>> getCachedPosts();
  Future<void> cachePosts(List<PostModel> posts);
}

class PostCacheDataSourceImpl implements PostCacheDataSource {
  final LocalStorageService _localStorageService;

  PostCacheDataSourceImpl(this._localStorageService);

  @override
  Future<List<PostModel>> getCachedPosts() async {
    try {
      final data = _localStorageService.getObject(AppConstants.postsCacheKey);
      if (data == null) return [];
      return (data as List)
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(message: 'Failed to parse cached posts: $e');
    }
  }

  @override
  Future<void> cachePosts(List<PostModel> posts) async {
    await _localStorageService.setObject(
      AppConstants.postsCacheKey,
      posts.map((p) => p.toJson()).toList(),
    );
  }
}

final postCacheDataSourceProvider = Provider<PostCacheDataSource>((ref) {
  return PostCacheDataSourceImpl(ref.watch(localStorageServiceProvider));
});
