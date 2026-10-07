import 'backup_import_result.dart';

/// 快照格式版本。写进 JSON 的 `version` 字段。
///
/// ⚠️ 读的时候**据此拒绝**比它高的版本（[BackupSnapshot.parse] 不拒绝，由
/// Repository 判）：未来的格式我们读不懂，静默降级解析会造出一堆缺字段的
/// 半残数据 —— 那比「无法导入」更难收拾。
const int backupSnapshotVersion = 1;

/// 快照里的一篇笔记。`content` 是 Quill Delta 的 JSON 字符串，与库里同格式
/// （`NoteDeltaCodec` 的编解码结果），本层不做任何解释。
class BackupNote {
  const BackupNote({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.background,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;

  final String title;

  final String content;

  /// null = 未分类。
  final String? folderId;

  final String? background;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// 合并比较键。
  ///
  /// ⚠️ 取 `updatedAt` 与 `deletedAt` 的**较晚者**：软删除也是一次变更，只用
  /// `updatedAt` 比的话，「A 机删除 / B 机改标题」会让一条更晚的编辑把已删除
  /// 的笔记复活（删除不刷新 `updatedAt`，见 `NoteDao.softDeleteById`）。
  DateTime get version => deletedAt == null || deletedAt!.isBefore(updatedAt)
      ? updatedAt
      : deletedAt!;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'content': content,
    'folderId': folderId,
    'background': background,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  /// 坏行返回 `null`（由 [_rows] 计入 skipped）。外部输入，逐字段 `is` 校验。
  static BackupNote? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null || id.isEmpty || createdAt == null || updatedAt == null) {
      return null;
    }
    return BackupNote(
      id: id,
      title: _str(json['title']) ?? '',
      content: _str(json['content']) ?? '',
      folderId: _str(json['folderId']),
      background: _str(json['background']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: _date(json['deletedAt']),
    );
  }
}

/// 快照里的一个文件夹。
///
/// ⚠️ `name` 在库里是 UNIQUE。跨设备各自新建同名文件夹会撞约束 —— 由
/// `BackupLocalDataSource` 改名重试，这里**不做**去重（合并规则只认 id）。
class BackupFolder {
  const BackupFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
  });

  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  final int sortIndex;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sortIndex': sortIndex,
  };

  static BackupFolder? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final name = _str(json['name']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null ||
        id.isEmpty ||
        name == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BackupFolder(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sortIndex: json['sortIndex'] is int ? json['sortIndex']! as int : 0,
    );
  }
}

/// 快照里的一条待办。
class BackupTodo {
  const BackupTodo({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String title;

  final bool isDone;

  final DateTime createdAt;

  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static BackupTodo? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final title = _str(json['title']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null ||
        id.isEmpty ||
        title == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BackupTodo(
      id: id,
      title: title,
      isDone: json['isDone'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// 一份完整的数据快照 = `notes` + `note_folders` + `todos` 三张表的全量。
///
/// 导出、导入、WebDAV 同步共用这一个模型，差别只在「字节从哪来到哪去」。
///
/// ⚠️ **不含设置偏好**：偏好在 SharedPreferences 里，与本 App 的数据库不同源，
/// 一起搬会让「换设备」变成「连主题一起换」，不是用户要的。
class BackupSnapshot {
  const BackupSnapshot({
    required this.exportedAt,
    required this.notes,
    required this.folders,
    required this.todos,
  });

  /// 「远端还没有文件」的空快照。同步首推时用它当基线。
  factory BackupSnapshot.empty() => BackupSnapshot(
    exportedAt: DateTime.fromMillisecondsSinceEpoch(0),
    notes: const <BackupNote>[],
    folders: const <BackupFolder>[],
    todos: const <BackupTodo>[],
  );

  final DateTime exportedAt;

  final List<BackupNote> notes;

  final List<BackupFolder> folders;

  final List<BackupTodo> todos;

  bool get isEmpty => notes.isEmpty && folders.isEmpty && todos.isEmpty;

  int get count => notes.length + folders.length + todos.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'version': backupSnapshotVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'notes': notes.map((n) => n.toJson()).toList(growable: false),
    'folders': folders.map((f) => f.toJson()).toList(growable: false),
    'todos': todos.map((t) => t.toJson()).toList(growable: false),
  };

  /// 解析一份 JSON 已 decode 的对象。**不校验版本**（Repository 负责）。
  ///
  /// 返回 `skipped`：坏行（缺 id / 时间戳不是 ISO 串 / 不是对象）逐条跳过计数 ——
  /// 导入的是外部输入，一条脏数据不该炸掉整个导入，但也不该被静默吞掉。
  static ({BackupSnapshot snapshot, int skipped}) parse(Object? raw) {
    if (raw is! Map) return (snapshot: BackupSnapshot.empty(), skipped: 0);
    final json = raw.cast<String, Object?>();

    final notes = _rows(json['notes'], BackupNote.fromJson);
    final folders = _rows(json['folders'], BackupFolder.fromJson);
    final todos = _rows(json['todos'], BackupTodo.fromJson);

    return (
      snapshot: BackupSnapshot(
        exportedAt: _date(json['exportedAt']) ?? DateTime.now(),
        notes: notes.rows,
        folders: folders.rows,
        todos: todos.rows,
      ),
      skipped: notes.skipped + folders.skipped + todos.skipped,
    );
  }

  /// 双向合并：逐条比 [version]，新的赢；一样新保留 [local]（避免无意义写库）。
  ///
  /// 只新增不删除 —— 本项目「永不丢数据」，合并后的并集必然 ≥ 任一方的集合。
  /// ⚠️ 待办是硬删除、无墓碑：A 机删掉一条后，B 机的同一条会在下次同步被带回来
  static ({BackupSnapshot merged, BackupImportResult result}) merge(
    BackupSnapshot local,
    BackupSnapshot incoming,
  ) {
    final folders = _mergeById(
      local.folders,
      incoming.folders,
      (f) => f.id,
      (f) => f.updatedAt,
    );
    final notes = _mergeById(
      local.notes,
      incoming.notes,
      (n) => n.id,
      (n) => n.version,
    );
    final todos = _mergeById(
      local.todos,
      incoming.todos,
      (t) => t.id,
      (t) => t.updatedAt,
    );

    final result = BackupImportResult(
      inserted: folders.inserted + notes.inserted + todos.inserted,
      updated: folders.updated + notes.updated + todos.updated,
      skipped: 0,
    );

    return (
      merged: BackupSnapshot(
        exportedAt: DateTime.now(),
        notes: notes.rows,
        folders: folders.rows,
        todos: todos.rows,
      ),
      result: result,
    );
  }
}

/// 按 id 合并两批行。[versionOf] 给比较键，相等时保留本地。
({List<T> rows, int inserted, int updated}) _mergeById<T>(
  List<T> local,
  List<T> incoming,
  String Function(T) idOf,
  DateTime Function(T) versionOf,
) {
  final localById = <String, T>{for (final row in local) idOf(row): row};
  final incomingIds = <String>{for (final row in incoming) idOf(row)};

  var inserted = 0;
  var updated = 0;
  final rows = <T>[];

  for (final row in incoming) {
    final mine = localById[idOf(row)];
    if (mine == null) {
      inserted++;
      rows.add(row);
    } else if (versionOf(row).isAfter(versionOf(mine))) {
      updated++;
      rows.add(row);
    } else {
      rows.add(mine);
    }
  }

  // 本地独有（对端没有 / 对端已永久删除）的行原样保留。
  for (final row in local) {
    if (!incomingIds.contains(idOf(row))) rows.add(row);
  }

  return (rows: rows, inserted: inserted, updated: updated);
}

/// 解析一个数组，逐行容错。`decode` 返回 null = 坏行。
({List<T> rows, int skipped}) _rows<T>(
  Object? raw,
  T? Function(Map<String, Object?> json) decode,
) {
  var skipped = 0;
  final rows = <T>[];
  if (raw is! List) return (rows: rows, skipped: skipped);

  for (final item in raw) {
    if (item is! Map) {
      skipped++;
      continue;
    }
    final row = decode(item.cast<String, Object?>());
    if (row == null) {
      skipped++;
    } else {
      rows.add(row);
    }
  }
  return (rows: rows, skipped: skipped);
}

/// 取值：不是 `String` 就当没有。导入的文件是外部输入，不做 `as` 强转。
String? _str(Object? value) => value is String ? value : null;

/// 取时间戳：只认 ISO-8601（库里写进去的格式）。
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
