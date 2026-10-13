import 'package:drift/drift.dart';

/// 笔记标签。实体见 `features/notes/domain/entities/tag.dart`。
///
/// ## 为什么有 `deleted_at`（墓碑）
///
/// 与 `notes` / `note_folders` / `todos` 同一架构：合并是并集（按 `version`
/// 取新），物理 DELETE 的行在远端「不存在」，对端会判定本地更新而把它原样
/// 带回来 —— 删除标签若不留痕，会在别的设备上复活。软删 + 列表过滤即可，
/// 标签行体积极小，**不做**保留期物理清扫（`ponytail:` 墓碑永存，若将来
/// 标签量成为问题再接入 `TombstoneSweeper`）。
///
/// ## `name` 故意**不**加 UNIQUE
///
/// 跨设备各自新建同名标签会撞约束（`note_folders` 那套「改名重试」对标签
/// 不适用：名字就是标签的语义，`(2)` 后缀是垃圾）。`createOrGet` 按 name
/// 查找复用来兜底；两台设备各建一个同名标签的代价是合并后出现两行同名，
/// 用户删掉一行即可，比改名重试的静默改名诚实。
@DataClassName('NoteTagRow')
@TableIndex(name: 'idx_note_tags_name', columns: {#name})
class NoteTags extends Table {
  @override
  String get tableName => 'note_tags';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  /// 标签名。大小写敏感（SQLite 默认 collation），不做 trim 之外的归一化。
  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// **合并比较键**。打标 / 改名 / 删除都刷它，否则删除打不过对端一次更晚的
  /// 编辑（同 `BackupNote.version` 的教训）。
  DateTimeColumn get updatedAt => dateTime()();

  /// 软删除时刻。null = 正常标签；非 null = 已被用户删除，列表与打标入口
  /// 全部过滤，行只活在同步链路里。
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
