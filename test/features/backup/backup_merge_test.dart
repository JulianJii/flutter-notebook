import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';

/// drift 存 `DateTime` 用 unix **秒**，毫秒级的值会全部塌成 0（与库里读回的
/// 值对不上）。所有时间戳都用整秒。
final DateTime t1 = DateTime.fromMillisecondsSinceEpoch(100 * 1000);
final DateTime t2 = DateTime.fromMillisecondsSinceEpoch(200 * 1000);
final DateTime t3 = DateTime.fromMillisecondsSinceEpoch(300 * 1000);

BackupNote note({
  String id = 'n1',
  String title = '标题',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    BackupNote(
      id: id,
      title: title,
      content: '正文',
      folderId: null,
      background: null,
      createdAt: t1,
      updatedAt: updatedAt ?? t2,
      deletedAt: deletedAt,
    );

BackupFolder folder(String id, String name) => BackupFolder(
  id: id,
  name: name,
  createdAt: t1,
  updatedAt: t2,
  sortIndex: 0,
);

BackupSnapshot snapshot({
  List<BackupNote> notes = const <BackupNote>[],
  List<BackupFolder> folders = const <BackupFolder>[],
}) =>
    BackupSnapshot(
      exportedAt: t3,
      notes: notes,
      folders: folders,
      todos: const <BackupTodo>[],
    );

void main() {
  group('BackupSnapshot.merge', () {
    test('对端更新更晚 → 对端赢，计入 updated', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(title: '本地', updatedAt: t2)]),
        snapshot(notes: <BackupNote>[note(title: '对端', updatedAt: t3)]),
      );

      expect(merged.merged.notes.single.title, '对端');
      expect(merged.result, const BackupImportResult(updated: 1));
    });

    test('本地更新更晚 → 保留本地，不计 updated', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(title: '本地', updatedAt: t3)]),
        snapshot(notes: <BackupNote>[note(title: '对端', updatedAt: t2)]),
      );

      expect(merged.merged.notes.single.title, '本地');
      expect(merged.result, BackupImportResult.empty);
    });

    test('本地没有 → 计入 inserted', () {
      final merged = BackupSnapshot.merge(
        snapshot(),
        snapshot(notes: <BackupNote>[note()]),
      );

      expect(merged.merged.notes.single.id, 'n1');
      expect(merged.result, const BackupImportResult(inserted: 1));
    });

    /// ⚠️ 这是合并键取「`updatedAt` 与 `deletedAt` 较晚者」的唯一理由：
    /// 软删除不刷新 `updatedAt`，只比 `updatedAt` 的话，一条更早的编辑会把
    /// 已删除的笔记复活。
    test('删除比本地编辑更晚 → 删除赢，不复活', () {
      final merged = BackupSnapshot.merge(
        // 本地 t2 改过标题；对端 t1 的版本在 t3 被删了。
        snapshot(notes: <BackupNote>[note(title: '本地改过', updatedAt: t2)]),
        snapshot(
          notes: <BackupNote>[note(title: '对端', updatedAt: t1, deletedAt: t3)],
        ),
      );

      expect(merged.merged.notes.single.deletedAt, t3);
      expect(merged.result, const BackupImportResult(updated: 1));
    });

    test('本地独有的行原样保留（合并是并集，不删东西）', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(id: 'n1')]),
        snapshot(notes: <BackupNote>[note(id: 'n2')]),
      );

      expect(merged.merged.notes.map((n) => n.id), <String>{'n1', 'n2'});
      expect(merged.result, const BackupImportResult(inserted: 1));
    });
  });

  group('BackupSnapshot.parse', () {
    test('JSON 往返不丢字段', () {
      final original = snapshot(
        notes: <BackupNote>[note(deletedAt: t3)],
        folders: <BackupFolder>[folder('f1', '工作')],
      );

      final parsed = BackupSnapshot.parse(original.toJson());

      expect(parsed.skipped, 0);
      expect(parsed.snapshot.notes.single.title, '标题');
      expect(parsed.snapshot.notes.single.deletedAt, t3);
      expect(parsed.snapshot.folders.single.name, '工作');
    });

    test('坏行跳过并计数，好行照读', () {
      final raw = <String, Object?>{
        'version': backupSnapshotVersion,
        'notes': <Object?>[
          note(id: 'ok').toJson(),
          <String, Object?>{'createdAt': t1.toIso8601String()}, // 缺 id
          42, // 不是对象
        ],
      };

      final parsed = BackupSnapshot.parse(raw);

      expect(parsed.skipped, 2);
      expect(parsed.snapshot.notes.single.id, 'ok');
    });

    test('顶层不是对象 → 空快照', () {
      expect(BackupSnapshot.parse('not a map').snapshot.isEmpty, isTrue);
    });
  });

  group('BackupLocalDataSource', () {
    late AppDatabase db;
    late BackupLocalDataSource source;

    setUp(() {
      db = AppDatabase.memory();
      source = BackupLocalDataSource(db);
    });

    tearDown(() => db.close());

    test('写入后读回一致（含回收站里的软删除笔记）', () async {
      final skipped = await source.write(
        snapshot(
          notes: <BackupNote>[note(deletedAt: t3)],
          folders: <BackupFolder>[folder('f1', '工作')],
        ),
      );

      expect(skipped, 0);
      final read = await source.read();
      expect(read.notes.single.id, 'n1');
      expect(read.notes.single.deletedAt, t3);
      expect(read.folders.single.name, '工作');
    });

    /// `note_folders.name` 是 UNIQUE，跨设备各建同名文件夹必然撞车。撞了改名，
    /// 不丢数据。
    test('同名文件夹改名而不是丢弃', () async {
      final skipped = await source.write(
        snapshot(
          folders: <BackupFolder>[folder('f1', '工作'), folder('f2', '工作')],
        ),
      );

      expect(skipped, 0);
      final read = await source.read();
      expect(
        read.folders.map((f) => f.name).toList()..sort(),
        <String>['工作', '工作 (2)'],
      );
    });

    test('指向不存在文件夹的 folderId 被清洗成 null', () async {
      await source.write(
        snapshot(
          notes: <BackupNote>[
            BackupNote(
              id: 'n1',
              title: '标题',
              content: '',
              folderId: '不存在的文件夹',
              background: null,
              createdAt: t1,
              updatedAt: t2,
              deletedAt: null,
            ),
          ],
        ),
      );

      final read = await source.read();
      // 外键开着，不清洗这条根本插不进去。
      expect(read.notes.single.folderId, isNull);
    });

    test('重复写入是幂等的（同步可以随时重试）', () async {
      final payload = snapshot(notes: <BackupNote>[note()]);
      await source.write(payload);
      await source.write(payload);

      final read = await source.read();
      expect(read.notes.length, 1);
    });
  });
}
