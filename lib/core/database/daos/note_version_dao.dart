import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_versions_table.dart';

part 'note_version_dao.g.dart';

/// 单篇笔记版本历史的 SQL。返回 drift 行对象，转换在
/// `features/notes/data/datasources/note_version_local_data_source.dart`。
@DriftAccessor(tables: [NoteVersions])
class NoteVersionDao extends DatabaseAccessor<AppDatabase>
    with _$NoteVersionDaoMixin {
  NoteVersionDao(super.db);

  /// 存一版。**去重**：与最近一版 title + content 都相同就跳过 —— 防抖已经
  /// 把存版频率压到「每次编辑会话至多一版」，这里再挡掉「改了又改回去」
  /// 与「恢复后原样再存」这两类无信息量的版本。
  ///
  /// 存完按 [limit] 淘汰最旧（物理 DELETE，见 `note_versions_table.dart`）。
  /// 整个动作单事务：去重比较与插入之间不留竞态窗口。
  ///
  /// ⚠️ [versionId] 由调用方（Repository）生成 uuid —— 与 `NoteRepository.create`
  /// 同一条「id 生成不进 DAO」的约定；被去重跳过时它只是被丢弃。
  Future<void> saveVersion(
    String noteId, {
    required String versionId,
    required String title,
    required String content,
    required DateTime createdAt,
    required int limit,
  }) {
    return transaction(() async {
      final latest =
          await (select(noteVersions)
                ..where((t) => t.noteId.equals(noteId))
                ..orderBy([
                  (t) => OrderingTerm.desc(t.createdAt),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (latest != null &&
          latest.title == title &&
          latest.content == content) {
        return;
      }

      await into(noteVersions).insert(
        NoteVersionsCompanion.insert(
          id: versionId,
          noteId: noteId,
          title: Value(title),
          content: Value(content),
          createdAt: createdAt,
        ),
      );

      // 淘汰最旧：按 createdAt 倒序跳过前 limit 条，剩下的删掉。
      final survivors =
          await (select(noteVersions)
                ..where((t) => t.noteId.equals(noteId))
                ..orderBy([
                  (t) => OrderingTerm.desc(t.createdAt),
                ]))
              .get();
      if (survivors.length <= limit) return;
      final staleIds = survivors.skip(limit).map((row) => row.id).toList();
      await (delete(noteVersions)..where((t) => t.id.isIn(staleIds))).go();
    });
  }

  /// 订阅一篇笔记的版本（新→旧）。历史时间线的唯一查询入口。
  Stream<List<NoteVersionRow>> watchVersions(String noteId) {
    return (select(noteVersions)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// 读单条（恢复用）。不存在返回 null。
  Future<NoteVersionRow?> getById(String versionId) {
    return (select(
      noteVersions,
    )..where((t) => t.id.equals(versionId))).getSingleOrNull();
  }
}
