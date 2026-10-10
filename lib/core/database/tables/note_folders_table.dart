import 'package:drift/drift.dart';

/// 文件夹表。实体见 `features/notes/domain/entities/note_folder.dart`。
///
/// MVP 单层：无 `parent_id`。「全部」与「未分类」不是表里的行
/// （`ARCHITECTURE-DESIGN.md` §5.3）——「未分类」是 `notes.folder_id IS NULL`
/// 的系统视图。
///
/// ## 删除语义
///
/// 软删除（`deleted_at`），与 `notes` 同形，**不是**物理删：删除必须能跨设备
/// 传播（见 `BackupFolder.version`），而硬删除不留痕。
///
/// ⚠️ **`name` 的 UNIQUE 会把名字锁住**：回收站里的行仍占着名字，用户删了
/// 「工作」再建「工作」会撞约束。所以进回收站时**改名让出**（见
/// `FolderDao.trashById` 的 `_trashedName` 约定），恢复时改回。
@DataClassName('NoteFolderRow')
class NoteFolders extends Table {
  @override
  String get tableName => 'note_folders';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  /// 重名校验由这个 UNIQUE 承担；唯一约束冲突由 Repository 映射成
  /// `Left(InputFailure)`（不新增 Failure 类型）。实体层不做校验。
  ///
  /// ⚠️ 回收站里的文件夹会把 `name` 改成 `<原名>#<id>` 来让出原名
  /// （见类注释），所以这里存的不是用户看到的名字，而是「要么原名、要么让出版」。
  TextColumn get name => text().unique()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  /// 文件夹管理拖拽排序位。越小越靠前，**同值按 [createdAt] 兜底** ——
  /// 迁移前的老数据全是默认值 0，兜底保证了升级后列表顺序与升级前一致。
  ///
  /// 写入只有两条路径：新建时取 `MAX+1`（排末尾），拖拽时整表写成 `0..n-1`
  /// （见 `FolderDao.insert` / `FolderDao.updateSortIndexes`）。
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  /// 软删除时刻。null = 正常文件夹；非 null = 在回收站里。
  ///
  /// 恢复即置回 null。**物理 DELETE 只由回收站的「永久删除」发起**。
  ///
  /// 删文件夹**不动**它下面笔记的 `folder_id`：笔记随之落进「未分类」是外键
  /// `ON DELETE SET NULL` 的语义，但软删除下 FK 不触发，所以由
  /// `FolderLocalDataSourceImpl.trash` 显式置 NULL（与 FK 规则冗余但原子，
  /// 见该方法注释）。
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// 回收站里文件夹的 `name` 存成 `<原名>#<id>`，以此**让出原名**。
///
/// 为什么必须让出：`note_folders.name` 是 UNIQUE，回收站里的行仍占着名字，
/// 用户删了「工作」再建「工作」会撞约束报错（见类注释）。
///
/// 为什么带 id 而不是别的后缀：id 唯一 → 让出版**必然不与任何行撞名**，
/// 不需要重试、不需要查重、不需要部分唯一索引（那会牵出漂移不认识的索引）。
/// 代价是回收站里的原始 `name` 带着这一段，由 [visibleFolderName] 在展示层剥掉。
///
/// ponytail: 这是个约定而非强约束 —— 数据库层面无法阻止别人手写一个带 `#` 的
/// 名字。真要强约束得给 `name` 加 CHECK，那是为一个我们自己能遵守的约定上锁。
String trashedFolderName(String name, String id) => '$name#$id';

/// 从存储的 `name` 还原出用户看到的名字：剥掉 `#$id` 后缀。
///
/// **非回收站的行原样返回** —— 活着的文件夹名里本来就可能有 `#`，不能无条件剥。
/// 所以调用方必须先看 `deletedAt`。
String visibleFolderName(String storedName, String id) {
  final suffix = '#$id';
  return storedName.endsWith(suffix)
      ? storedName.substring(0, storedName.length - suffix.length)
      : storedName;
}
