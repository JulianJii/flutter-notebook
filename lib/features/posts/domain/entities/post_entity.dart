import 'package:equatable/equatable.dart';

/// 表示内容列表中单条帖子的领域实体。
class PostEntity extends Equatable {
  final String id;
  final String authorName;
  final String title;
  final String body;
  final DateTime publishedAt;

  const PostEntity({
    required this.id,
    required this.authorName,
    required this.title,
    required this.body,
    required this.publishedAt,
  });

  @override
  List<Object?> get props => [id, authorName, title, body, publishedAt];
}
