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
}
