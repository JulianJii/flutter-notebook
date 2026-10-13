import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_version_dao.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/notes/domain/entities/note_version.dart';

/// 单篇版本历史的本地数据源：只做「`NoteVersion` 实体 ↔ drift 行」的转换与
/// DAO 透传（与 `NoteLocalDataSource` 同一条边界）。
abstract class NoteVersionLocalDataSource {
  /// 存一版（去重 + 按上限淘汰在 DAO 的事务里）。
  Future<void> saveVersion(NoteVersion version, int limit);

  /// 订阅一篇笔记的版本（新→旧）。
  Stream<List<NoteVersion>> watchVersions(String noteId);

  /// 读单条。找不到抛 [CacheException]。
  Future<NoteVersion> getById(String versionId);
}

class NoteVersionLocalDataSourceImpl implements NoteVersionLocalDataSource {
  NoteVersionLocalDataSourceImpl(AppDatabase db, {NoteVersionDao? dao})
    : _dao = dao ?? NoteVersionDao(db);

  final NoteVersionDao _dao;

  @override
  Future<void> saveVersion(NoteVersion version, int limit) =>
      _dao.saveVersion(
        version.noteId,
        versionId: version.id,
        title: version.title,
        content: version.content,
        createdAt: version.createdAt,
        limit: limit,
      );

  @override
  Stream<List<NoteVersion>> watchVersions(String noteId) =>
      _dao.watchVersions(noteId).map(
        (rows) => <NoteVersion>[
          for (final row in rows)
            NoteVersion(
              id: row.id,
              noteId: row.noteId,
              title: row.title,
              content: row.content,
              createdAt: row.createdAt,
            ),
        ],
      );

  @override
  Future<NoteVersion> getById(String versionId) async {
    final row = await _dao.getById(versionId);
    if (row == null) {
      throw CacheException(message: 'NoteVersion not found: $versionId');
    }
    return NoteVersion(
      id: row.id,
      noteId: row.noteId,
      title: row.title,
      content: row.content,
      createdAt: row.createdAt,
    );
  }
}
