import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/posts/data/datasources/post_cache_data_source.dart';
import 'package:init/features/posts/data/datasources/post_remote_data_source.dart';
import 'package:init/features/posts/data/repositories/post_repository_impl.dart';
import 'package:init/features/posts/domain/repositories/post_repository.dart';
import 'package:init/features/posts/domain/usecases/get_posts_use_case.dart';

/// 数据层依赖注入提供者
/// 这些提供者负责创建和管理数据层实例

// --- Repository ---
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(
    ref.watch(postRemoteDataSourceProvider),
    ref.watch(postCacheDataSourceProvider),
  );
});

// --- Use Cases ---
final getPostsUseCaseProvider = Provider<GetPostsUseCase>((ref) {
  return GetPostsUseCase(ref.watch(postRepositoryProvider));
});
