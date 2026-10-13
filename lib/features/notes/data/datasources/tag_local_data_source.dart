import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_tag_dao.dart';

import '../../domain/entities/tag.dart';

/// 标签的本地数据源：只做「`Tag` 实体 ↔ drift 行」的转换与 DAO 透传。
/// SQL 全部在 [NoteTagDao]（与 `NoteLocalDataSource` / `NoteDao` 同一条边界）。
abstract class TagLocalDataSource {
  /// 全部存活标签 + 存活笔记数（`Tag.noteCount` 在这里装配）。
  Stream<List<Tag>> watchAll();

  Future<List<String>> namesForNote(String noteId);

  /// 插入新标签（id 由调用方——Repository——生成）。
  Future<Tag> insert(Tag tag);

  /// 按名找（含墓碑行，复活用），找不到返回 null。
  Future<Tag?> getByName(String name);

  Future<void> rename(String tagId, String name);

  Future<void> delete(String tagId);

  Future<void> setNoteTagLinks(String noteId, List<String> tagIds);
}

class TagLocalDataSourceImpl implements TagLocalDataSource {
  TagLocalDataSourceImpl(AppDatabase db, {NoteTagDao? dao})
    : _dao = dao ?? NoteTagDao(db);

  final NoteTagDao _dao;

  @override
  Stream<List<Tag>> watchAll() => _dao.watchAllWithCounts().map(
    (rows) => <Tag>[
      for (final (:tag, :noteCount) in rows)
        Tag(id: tag.id, name: tag.name, noteCount: noteCount),
    ],
  );

  @override
  Future<List<String>> namesForNote(String noteId) =>
      _dao.tagNamesForNote(noteId);

  @override
  Future<Tag> insert(Tag tag) async {
    final row = await _dao.insertTag(
      NoteTagsCompanion.insert(
        id: tag.id,
        name: tag.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return Tag(id: row.id, name: row.name, noteCount: 0);
  }

  @override
  Future<Tag?> getByName(String name) async {
    final row = await _dao.getByName(name);
    return row == null ? null : Tag(id: row.id, name: row.name, noteCount: 0);
  }

  @override
  Future<void> rename(String tagId, String name) =>
      _dao.renameTag(tagId, name, DateTime.now());

  @override
  Future<void> delete(String tagId) =>
      _dao.softDeleteTag(tagId, DateTime.now());

  @override
  Future<void> setNoteTagLinks(String noteId, List<String> tagIds) =>
      _dao.setNoteTagLinks(noteId, tagIds);
}
