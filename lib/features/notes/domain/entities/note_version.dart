import 'package:equatable/equatable.dart';

/// 单篇笔记的一个历史版本。`title` + `content` 构成该时点的完整快照
/// （`content` 是 Quill Delta 的 JSON 字符串，与 `Note.content` 同格式）。
///
/// ⛔ 只增不改：版本没有编辑语义，「恢复」是对笔记的写操作，版本行自己
/// 永远是历史。淘汰最旧 = 物理 DELETE（不跨设备传播，两台设备各自收敛，
/// 见 `note_versions_table.dart` 的类注释）。
class NoteVersion extends Equatable {
  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final String id;

  final String noteId;

  final String title;

  final String content;

  /// 存版时刻。列表按它倒序；它也是同步合并的比较键。
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, noteId, title, content, createdAt];
}
