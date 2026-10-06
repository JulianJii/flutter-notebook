import 'package:drift/drift.dart';

/// 文件夹表。实体见 `features/notes/domain/entities/note_folder.dart`。
///
/// MVP 单层：无 `parent_id`。「全部」与「未分类」不是表里的行
/// （`ARCHITECTURE-DESIGN.md` §5.3）——「未分类」是 `notes.folder_id IS NULL`
/// 的系统视图。
@DataClassName('NoteFolderRow')
class NoteFolders extends Table {
  @override
  String get tableName => 'note_folders';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  /// 重名校验由这个 UNIQUE 承担；唯一约束冲突由 Repository 映射成
  /// `Left(InputFailure)`（不新增 Failure 类型）。实体层不做校验。
  TextColumn get name => text().unique()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  /// P4 拖拽排序位。越小越靠前，**同值按 [createdAt] 兜底** ——
  /// 迁移前的老数据全是默认值 0，兜底保证了升级后列表顺序与升级前一致。
  ///
  /// 写入只有两条路径：新建时取 `MAX+1`（排末尾），拖拽时整表写成 `0..n-1`
  /// （见 `FolderDao.insert` / `FolderDao.updateSortIndexes`）。
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();
}
