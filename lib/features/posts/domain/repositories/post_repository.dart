import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/posts/domain/entities/post_entity.dart';

abstract class PostRepository {
  /// 从远程数据源获取帖子列表，离线或出错时回退到上次成功缓存的列表。
  ///
  /// 传入 [forceRefresh] 可跳过数据源中的短期缓存并重新请求网络。
  Future<Either<Failure, List<PostEntity>>> getPosts({
    bool forceRefresh = false,
  });
}
