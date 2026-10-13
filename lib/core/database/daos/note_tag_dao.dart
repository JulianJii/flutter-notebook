import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_tag_links_table.dart';
import '../tables/note_tags_table.dart';
import '../tables/notes_table.dart';

part 'note_tag_dao.g.dart';

/// 标签与笔记↔标签链接的 SQL。core 不认识业务实体 —— 返回 drift 行对象，
/// 行 → `Tag` 的转换在 `features/notes/data/datasources/tag_local_data_source.dart`。
///
/// ⚠️ 全部查询都过滤 `deleted_at IS NULL`（打 / 摘是墓碑，见
/// `note_tag_links_table.dart`），唯一例外是 [getByName]：
/// `createOrGet` 需要找到**已删的同名标签来复活**，而不是再插一行。
@DriftAccessor(tables: [NoteTags, NoteTagLinks, Notes])
class NoteTagDao extends DatabaseAccessor<AppDatabase>
    with _$NoteTagDaoMixin {
  NoteTagDao(super.db);

  /// 订阅全部存活标签 + 各自挂着的**存活**笔记数（回收站 / 墓碑笔记不计）。
  ///
  /// 一条 JOIN 出来，行数 = Σ(每个标签的链接数 + 1)，在 Dart 里折叠计数，
  /// 不做 `GROUP BY` 的 `selectOnly`（列得逐个枚举，可读性更差）。
  /// 排序 `name ASC`，管理页与筛选弹层共用。
  Stream<List<({NoteTagRow tag, int noteCount})>> watchAllWithCounts() {
    // ⚠️ 两个 join 都**不能** `useColumns: false`：行里要读 notes 的存在性来
    // 计数（left join 没配上 → readTableOrNull 为 null）。
    final query = select(noteTags).join([
      leftOuterJoin(
        noteTagLinks,
        (noteTagLinks.tagId.equalsExp(noteTags.id)) &
            noteTagLinks.deletedAt.isNull(),
      ),
      leftOuterJoin(
        notes,
        (notes.id.equalsExp(noteTagLinks.noteId)) &
            notes.deletedAt.isNull() &
            notes.purgedAt.isNull(),
      ),
    ]);
    query.where(noteTags.deletedAt.isNull());
    query.orderBy([OrderingTerm.asc(noteTags.name)]);

    return query.watch().map((rows) {
      final counts = <String, int>{};
      final tags = <NoteTagRow>[];
      var lastId = '';
      for (final row in rows) {
        final tag = row.readTable(noteTags);
        if (tag.id != lastId) {
          lastId = tag.id;
          tags.add(tag);
        }
        // 左连接没配到存活笔记的行（无链接 / 链接全在回收站）→ 不计数。
        if (row.readTableOrNull(notes) != null) {
          counts[tag.id] = (counts[tag.id] ?? 0) + 1;
        }
      }
      return <({NoteTagRow tag, int noteCount})>[
        for (final tag in tags) (tag: tag, noteCount: counts[tag.id] ?? 0),
      ];
    });
  }

  /// 全库「noteId → 标签名列表」映射。给 [Note.tags] 的两查合并用：
  /// 主查询每次推流，这里跟着查一次（一次 JOIN，非 N+1）。
  Future<Map<String, List<String>>> tagNamesByNoteId() async {
    final query = select(noteTagLinks).join([
      innerJoin(
        noteTags,
        (noteTags.id.equalsExp(noteTagLinks.tagId)) &
            noteTags.deletedAt.isNull(),
      ),
    ]);
    query.where(noteTagLinks.deletedAt.isNull());
    query.orderBy([OrderingTerm.asc(noteTagLinks.createdAt)]);
    final rows = await query.get();

    final map = <String, List<String>>{};
    for (final row in rows) {
      final link = row.readTable(noteTagLinks);
      final name = row.readTable(noteTags).name;
      (map[link.noteId] ??= <String>[]).add(name);
    }
    return map;
  }

  /// 一篇笔记当前的标签名（按挂接时间序）。打标弹层回填用。
  Future<List<String>> tagNamesForNote(String noteId) async {
    final map = await tagNamesByNoteIds([noteId]);
    return map[noteId] ?? const <String>[];
  }

  Future<Map<String, List<String>>> tagNamesByNoteIds(
    List<String> noteIds,
  ) async {
    final query = select(noteTagLinks).join([
      innerJoin(
        noteTags,
        (noteTags.id.equalsExp(noteTagLinks.tagId)) &
            noteTags.deletedAt.isNull(),
      ),
    ]);
    query.where(
      noteTagLinks.noteId.isIn(noteIds) & noteTagLinks.deletedAt.isNull(),
    );
    query.orderBy([OrderingTerm.asc(noteTagLinks.createdAt)]);
    final rows = await query.get();

    final map = <String, List<String>>{};
    for (final row in rows) {
      final link = row.readTable(noteTagLinks);
      (map[link.noteId] ??= <String>[]).add(row.readTable(noteTags).name);
    }
    return map;
  }

  /// 按 name 找标签，**含墓碑行**（复活用，见类注释）。
  Future<NoteTagRow?> getByName(String name) {
    return (select(noteTags)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
  }

  Future<NoteTagRow> insertTag(NoteTagsCompanion row) {
    return into(noteTags).insertReturning(row);
  }

  /// 改名。必须刷 `updated_at`：改名是一次变更，不刷的话合并键退回旧值，
  /// 远端会把旧名字滚回来。
  Future<int> renameTag(String tagId, String name, DateTime updatedAt) {
    return (update(noteTags)..where((t) => t.id.equals(tagId)))
        .write(NoteTagsCompanion(name: Value(name), updatedAt: Value(updatedAt)));
  }

  /// 删标签 = 墓碑 + 级联墓碑其全部挂接。**一个事务**：两半必须同生同死，
  /// 否则「标签已删但链接还挂着」的中间态会被同步推给对端。
  Future<void> softDeleteTag(String tagId, DateTime deletedAt) {
    return transaction(() async {
      await (update(noteTags)..where((t) => t.id.equals(tagId))).write(
        NoteTagsCompanion(deletedAt: Value(deletedAt), updatedAt: Value(deletedAt)),
      );
      await (update(noteTagLinks)..where(
            (l) => l.tagId.equals(tagId) & l.deletedAt.isNull(),
          )).write(
        NoteTagLinksCompanion(
          deletedAt: Value(deletedAt),
          updatedAt: Value(deletedAt),
        ),
      );
    });
  }

  /// 一篇笔记的挂接对齐到 [tagIds]（**链接层的唯一写入口**）。
  ///
  /// 单事务内：补挂缺失（复活同键的摘除墓碑 / 新插）、摘掉多余（打墓碑不物理删
  /// —— 摘除要跨设备传播），全部刷 `updated_at`。标签行的建 / 复活**不在**这里：
  /// id 由 Repository 生成（与 `NoteRepository.create` 同一条约定），本方法只认 id。
  Future<void> setNoteTagLinks(String noteId, List<String> tagIds) {
    return transaction(() async {
      final now = DateTime.now();
      final currentRows =
          await (select(noteTagLinks)
                ..where(
                  (l) =>
                      l.noteId.equals(noteId) & l.deletedAt.isNull(),
                ))
              .get();
      final currentIds = {for (final row in currentRows) row.tagId};
      final targetSet = tagIds.toSet();

      // 补挂 / 复活。
      for (final tagId in tagIds) {
        if (currentIds.contains(tagId)) continue;
        final tombstoned =
            await (select(noteTagLinks)..where(
                  (l) =>
                      l.noteId.equals(noteId) &
                      l.tagId.equals(tagId) &
                      l.deletedAt.isNotNull(),
                ))
                .getSingleOrNull();
        if (tombstoned != null) {
          // 复合主键占着位，直接把那一行复活。
          await (update(noteTagLinks)..where(
                (l) => l.noteId.equals(noteId) & l.tagId.equals(tagId),
              )).write(
            NoteTagLinksCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ),
          );
        } else {
          await into(noteTagLinks).insert(
            NoteTagLinksCompanion.insert(
              noteId: noteId,
              tagId: tagId,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }

      // 摘掉多余的链接。
      for (final link in currentRows) {
        if (!targetSet.contains(link.tagId)) {
          await (update(noteTagLinks)..where(
                (l) => l.noteId.equals(noteId) & l.tagId.equals(link.tagId),
              )).write(
            NoteTagLinksCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }
}
