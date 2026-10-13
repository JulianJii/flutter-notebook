import 'package:drift/drift.dart';

import 'notes_table.dart';

/// 单篇笔记的版本历史（自动快照）。
///
/// ## 与全局快照（`BackupSnapshot`）的区别
///
/// 全局快照是「找回」：WebDAV 端的历史文件 + 并集合并，删除传播比任何历史
/// 版本都新，恢复不了单篇的过去。本表是**真回滚**：编辑停止后防抖存版，
/// 恢复 = 用版本内容覆盖当前笔记（覆盖前当前内容先自动存一版，防丢）。
///
/// ## 删除语义
///
/// - 笔记**软删除**（进回收站）：版本跟着隐藏，不单独处理 —— 版本是笔记的
///   从属数据，恢复笔记时历史还在。
/// - 笔记**物理清扫**（墓碑过期）：`ON DELETE CASCADE` 连带删版本。
/// - 超过每篇上限（设置项，默认 50）淘汰**最旧**：物理 DELETE。不跨设备传播
///   是可接受的：两台设备各自存满 50 版后按 `created_at` 各自淘汰，最终收敛
///   到同一批最近的版本（`ponytail:` 淘汰不进墓碑 —— 给几十 KB 的正文行做
///   永存墓碑，快照只会越滚越大，收益为负）。
@DataClassName('NoteVersionRow')
@TableIndex(name: 'idx_note_versions_note_id', columns: {#noteId})
class NoteVersions extends Table {
  @override
  String get tableName => 'note_versions';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  /// 所属笔记。CASCADE 见类注释。
  TextColumn get noteId => text().references(
    Notes,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// 存版时刻的标题。与 [content] 一起构成该版本的完整快照 —— 只存正文
  /// 不存标题的话，改标题的历史就丢了。
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Quill Delta 的 JSON 字符串，与 `notes.content` 同格式，本表不做解释。
  TextColumn get content => text().withDefault(const Constant(''))();

  /// 存版时刻。列表按它倒序；**合并比较键**（版本只增不改，无墓碑）。
  DateTimeColumn get createdAt => dateTime()();
}
