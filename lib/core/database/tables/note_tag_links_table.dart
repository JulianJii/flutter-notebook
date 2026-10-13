import 'package:drift/drift.dart';

import 'note_tags_table.dart';
import 'notes_table.dart';

/// 笔记 ↔ 标签的多对多关联。
///
/// ## 主键是复合键 (note_id, tag_id)
///
/// 一篇笔记对同一个标签最多一条链接，天然去重；「换个链接行」没有意义。
/// 合并时的比较键也由此复合而成（`noteId::tagId`，见 `BackupNoteTagLink`）。
///
/// ## 删除语义：软删除（`deleted_at`）
///
/// 「把标签从笔记上摘掉」是一次用户操作，必须跨设备传播 —— 物理 DELETE 的行
/// 对端「不存在」，合并时会被原样带回来（摘掉的标签自己长回来）。所以摘标签
/// 写墓碑（`deleted_at` + 刷 `updated_at`），查询一律过滤 `deleted_at IS NULL`。
/// 打标签 = 复活（墓碑清回 null + 刷时间），行可反复复用。
///
/// `ON DELETE CASCADE`（两个方向）只在**物理删除**时触发：笔记被保留期清扫
/// 连带删链接；标签行墓碑永存（见 `note_tags_table.dart`），CASCADE 到 tags
/// 实际不触发，声明它只为物理删行时不留悬挂链接。
@DataClassName('NoteTagLinkRow')
@TableIndex(name: 'idx_note_tag_links_note_id', columns: {#noteId})
@TableIndex(name: 'idx_note_tag_links_tag_id', columns: {#tagId})
class NoteTagLinks extends Table {
  @override
  String get tableName => 'note_tag_links';

  @override
  Set<Column> get primaryKey => {noteId, tagId};

  TextColumn get noteId => text().references(
    Notes,
    #id,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get tagId => text().references(
    NoteTags,
    #id,
    onDelete: KeyAction.cascade,
  )();

  DateTimeColumn get createdAt => dateTime()();

  /// **合并比较键**。打 / 摘标签都刷它。
  DateTimeColumn get updatedAt => dateTime()();

  /// 摘除墓碑。null = 挂接中；非 null = 已摘掉，查询过滤。
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
