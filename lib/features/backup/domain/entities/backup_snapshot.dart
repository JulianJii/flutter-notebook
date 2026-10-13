import 'backup_import_result.dart';

/// **v2**：文件夹与待办加 `deletedAt`（跨设备软删除）。
///
/// 快照格式版本。写进 JSON 的 `version` 字段。
///
/// ⚠️ 读的时候**据此拒绝**比它高的版本（[BackupSnapshot.parse] 不拒绝，由
/// Repository 判）：未来的格式我们读不懂，静默降级解析会造出一堆缺字段的
/// 半残数据 —— 那比「无法导入」更难收拾。
///
/// **v4**：加 `subtasks`（子项）。**向后兼容** —— 老快照没有这个键，解析出来
/// 是空列表，A 机尚未升级时同步不会误删 B 机的子项。
///
/// ⚠️ 子项**必须**进快照：不同步的话 A 机勾掉的子项会在 B 机同步后变回没勾，
/// 那是丢数据，而本 App 的第一原则是永不丢数据。
///
/// **v3**：三类实体各加 `purgedAt`（**永久删除的墓碑**）。**向后兼容** ——
/// v1 / v2 文件没有这个字段，解析出来是 `null` = 从未被永久删除，与升级前
/// 行为一致。
///
/// ⚠️ v3 才是「永久删除能跨设备传播」的版本。在此之前 `purgedAt` 恒为 null，
/// 合并是纯并集，A 机物理删掉的行在 B 机不存在 → B 判定本地更新 → 原样带回来。
/// 老快照导入后全部视为「未永久删除」，不会误删任何东西。
///
/// ⚠️ v5 只加了一列 `editorFontId`。**必须升版本号**：不升的话，旧版 App 会照读
/// 新版快照、把不认识的那一列丢掉，用户换台设备或回滚版本就静默丢掉全部笔记字体；
/// 升了之后旧版 App 会明确拒绝导入（`BackupRepositoryImpl` 的版本门）。
/// 反方向（新版读 v4 老快照）不受影响：字段缺失就是 null = 系统默认字体。
///
/// **v6**：加 `tags` / `tagLinks` / `noteVersions` 三个列表（标签、笔记↔标签
/// 链接、单篇版本历史）与 `BackupTodo.linkedNoteId`（待办挂笔记）。**向后兼容**
/// —— 老快照没有这些键，解析出来是空列表 / null，不会误删任何东西。
/// ⚠️ 同 v5 的理由必须升版本号：不升的话旧版 App 会把三张新表的数据静默丢掉。
const int backupSnapshotVersion = 6;

/// 快照里的一篇笔记。`content` 是 Quill Delta 的 JSON 字符串，与库里同格式
/// （`NoteDeltaCodec` 的编解码结果），本层不做任何解释。
class BackupNote {
  const BackupNote({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.background,
    this.editorFontId,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.purgedAt,
    this.isPinned = false,
    this.isFavorite = false,
  });

  final String id;

  final String title;

  final String content;

  /// null = 未分类。
  final String? folderId;

  final String? background;

  /// 这篇笔记的编辑器字体 id（`core/fonts` 目录里的 id）。null = 系统默认。
  ///
  /// ⚠️ **参与同步**（v5 起）：它是用户数据的一部分，与 [background] 同类 ——
  /// 漏掉的话，换台设备恢复后字体全被清零。
  final String? editorFontId;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// **永久删除墓碑**。非 null = 已被「永久删除」，行只活在同步链路里。
  final DateTime? purgedAt;

  /// 置顶。参与同步（它是用户数据的一部分，不是本机视图状态）。
  final bool isPinned;

  /// 收藏。参与同步，理由同 [isPinned]。
  final bool isFavorite;

  /// 合并比较键。
  ///
  /// ⚠️ 取 `updatedAt` / `deletedAt` / `purgedAt` 的**较晚者**：软删除与永久删除
  /// 都是一次变更，只用 `updatedAt` 比的话，「A 机永久删除 / B 机改标题」会让
  /// 一条更晚的编辑把已删除的笔记复活（删除不刷新 `updatedAt`）。
  DateTime get version => _latestOf(updatedAt, deletedAt, purgedAt);

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'content': content,
    'folderId': folderId,
    'background': background,
    'editorFontId': editorFontId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
    'purgedAt': purgedAt?.toIso8601String(),
    'isPinned': isPinned,
    'isFavorite': isFavorite,
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
      editorFontId: _str(json['editorFontId']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: _date(json['deletedAt']),
      purgedAt: _date(json['purgedAt']),
      isPinned: json['isPinned'] == true,
      isFavorite: json['isFavorite'] == true,
    );
  }
}

/// 快照里的一个文件夹。
///
/// ⚠️ `name` 在库里是 UNIQUE。跨设备各自新建同名文件夹会撞约束 —— 由
/// `BackupLocalDataSource` 改名重试，这里**不做**去重（合并规则只认 id）。
///
/// ⚠️ `name` 存的是**让出版**（`<原名>#<id>`，见
/// `note_folders_table.dart` 的 `trashedFolderName`），不是用户看到的名字。
/// 跨设备合并时两侧都要用同一套约定，否则恢复会写回一个带 `#` 的名字。
class BackupFolder {
  const BackupFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
    this.deletedAt,
    this.purgedAt,
  });

  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  final int sortIndex;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// **永久删除墓碑**。非 null = 已被「永久删除」，行只活在同步链路里。
  final DateTime? purgedAt;

  /// 合并比较键。语义同 [BackupNote.version]（软删除与永久删除都是一次变更，
  /// 且都不刷 `updatedAt`），抽成共用逻辑避免三处各写一遍、各错一遍。
  DateTime get version => _latestOf(updatedAt, deletedAt, purgedAt);

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sortIndex': sortIndex,
    'deletedAt': deletedAt?.toIso8601String(),
    'purgedAt': purgedAt?.toIso8601String(),
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
      deletedAt: _date(json['deletedAt']),
      purgedAt: _date(json['purgedAt']),
    );
  }
}

/// 快照里的一条待办。
///
/// ⚠️ `reminderAt`（提醒时刻）**必须出现在这里**：`BackupLocalDataSource._writeTodos`
/// 用的是 `InsertMode.insertOrReplace`，而 SQLite 的 `INSERT OR REPLACE` 语义是
/// 「DELETE + INSERT」—— **未列出的列一律取默认值**。少写这一列 = 每同步一次就把
/// 接收端全部待办的提醒时间清零（不是「不同步」，是「清空」）。
/// 同理适用于 [deletedAt]：漏了它，每同步一次就把所有已删待办复活。
class BackupTodo {
  const BackupTodo({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    required this.priority,
    this.recurrence,
    this.linkedNoteId,
    this.reminderAt,
    this.deletedAt,
    this.purgedAt,
  });

  final String id;

  final String title;

  final bool isDone;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// null = 没设提醒。
  final DateTime? reminderAt;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// **永久删除墓碑**。非 null = 已被「永久删除」，行只活在同步链路里。
  final DateTime? purgedAt;

  /// 优先级（存**稳定 id** 而非数值：数值重排会让老数据全错，见 `TodoPriority`）。
  final String priority;

  /// 重复规则 id。null = 不重复。
  final String? recurrence;

  /// 挂接的笔记 id。null = 未挂接。**参与同步**（用户数据，漏了等于每次同步
  /// 把接收端的挂接清掉）。指向已被物理清扫的笔记时由 UI 兜底提示（见
  /// `todos_table.dart` 的 `linkedNoteId` 列注释）。
  final String? linkedNoteId;

  /// 合并比较键。语义同 [BackupNote.version]。
  DateTime get version => _latestOf(updatedAt, deletedAt, purgedAt);

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
    'purgedAt': purgedAt?.toIso8601String(),
    'priority': priority,
    'recurrence': recurrence,
    'linkedNoteId': linkedNoteId,
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
      reminderAt: _date(json['reminderAt']),
      deletedAt: _date(json['deletedAt']),
      purgedAt: _date(json['purgedAt']),
      // ⚠️ 缺字段（v3 及更早的快照）回落成 `normal`，不是 null：优先级不是
      // 「没有」，没有优先级就是「普通」。
      priority: _str(json['priority']) ?? 'normal',
      recurrence: _str(json['recurrence']),
      linkedNoteId: _str(json['linkedNoteId']),
    );
  }
}

/// 快照里的一条子项。
///
/// ⛔ **没有 `deletedAt`**：子项没有回收站（见 `todo_subtasks_table.dart`）。
/// 「删掉一条子项」是真的物理删 —— 而那**不跨设备传播**：对端同步后会把它原样
/// 带回来。这是子项层有意接受的代价（父待办的墓碑仍然会传播，所以「删掉整条
/// 待办带子项」在两台设备上是一致的）。
class BackupTodoSubtask {
  const BackupTodoSubtask({
    required this.id,
    required this.todoId,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String todoId;

  final String title;

  final bool isDone;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 合并比较键。子项**只加不减**（没有删除墓碑），所以只有 `updatedAt` 一项。
  DateTime get version => updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'todoId': todoId,
    'title': title,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static BackupTodoSubtask? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final todoId = _str(json['todoId']);
    final title = _str(json['title']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null ||
        id.isEmpty ||
        todoId == null ||
        todoId.isEmpty ||
        title == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BackupTodoSubtask(
      id: id,
      todoId: todoId,
      title: title,
      isDone: json['isDone'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// 快照里的一个标签。
///
/// 与 `BackupNote` 同一套墓碑语义（软删除要跨设备传播），`version` 取
/// `updatedAt` / `deletedAt` 较晚者。没有 `purgedAt`：标签行体积极小，
/// 墓碑永存不接入保留期清扫（见 `note_tags_table.dart` 类注释）。
class BackupNoteTag {
  const BackupNoteTag({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 非 null = 已被用户删除，行只活在同步链路里。
  final DateTime? deletedAt;

  /// 合并比较键。语义同 [BackupNote.version]（少 `purgedAt` 一项）。
  DateTime get version => _latestOf(updatedAt, deletedAt, null);

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  static BackupNoteTag? fromJson(Map<String, Object?> json) {
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
    return BackupNoteTag(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: _date(json['deletedAt']),
    );
  }
}

/// 快照里的一条笔记↔标签链接。
///
/// ⚠️ 合并比较键是**复合键** `noteId::tagId`（表的主键就是复合主键，
/// `BackupSnapshot.merge` 据此合并），不是单列 id。
class BackupNoteTagLink {
  const BackupNoteTagLink({
    required this.noteId,
    required this.tagId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String noteId;

  final String tagId;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 非 null = 已摘掉（墓碑，见 `note_tag_links_table.dart` 类注释）。
  final DateTime? deletedAt;

  /// 合并比较键。摘标签是一次变更，同 [BackupNoteTag.version] 的语义。
  DateTime get version => _latestOf(updatedAt, deletedAt, null);

  /// [BackupSnapshot.merge] 用的复合主键。
  String get mergeKey => '$noteId::$tagId';

  Map<String, Object?> toJson() => <String, Object?>{
    'noteId': noteId,
    'tagId': tagId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  static BackupNoteTagLink? fromJson(Map<String, Object?> json) {
    final noteId = _str(json['noteId']);
    final tagId = _str(json['tagId']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (noteId == null ||
        noteId.isEmpty ||
        tagId == null ||
        tagId.isEmpty ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BackupNoteTagLink(
      noteId: noteId,
      tagId: tagId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: _date(json['deletedAt']),
    );
  }
}

/// 快照里的一个单篇笔记版本。
///
/// ⛔ **没有墓碑**：超上限淘汰最旧是物理 DELETE，不跨设备传播 —— 两台设备
/// 各自存满后按 `createdAt` 各自淘汰，最终收敛到同一批最近版本（见
/// `note_versions_table.dart` 类注释）。合并比较键取 `createdAt`（只增不改）。
class BackupNoteVersion {
  const BackupNoteVersion({
    required this.id,
    required this.noteId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  final String id;

  final String noteId;

  final String title;

  /// Quill Delta 的 JSON 字符串，与 [BackupNote.content] 同格式。
  final String content;

  final DateTime createdAt;

  /// 合并比较键。版本只增不改，`createdAt` 就是它的身份与新旧。
  DateTime get version => createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'noteId': noteId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  static BackupNoteVersion? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final noteId = _str(json['noteId']);
    final createdAt = _date(json['createdAt']);
    if (id == null ||
        id.isEmpty ||
        noteId == null ||
        noteId.isEmpty ||
        createdAt == null) {
      return null;
    }
    return BackupNoteVersion(
      id: id,
      noteId: noteId,
      title: _str(json['title']) ?? '',
      content: _str(json['content']) ?? '',
      createdAt: createdAt,
    );
  }
}

/// 合并比较键的共用实现：三个时间戳里取最晚者。
///
/// ⚠️ 这是三类实体**唯一**的版本语义出处 —— 抄成三份必然会有一份漏掉墓碑，
/// 而漏掉的后果是「永久删除打不过对端一次更晚的编辑」，删除静默失效。
/// `base` 非空（`updatedAt` 从不 nullable），故不需要 `max` 包的空列表。
DateTime _latestOf(DateTime base, DateTime? a, DateTime? b) {
  var latest = base;
  if (a != null && a.isAfter(latest)) latest = a;
  if (b != null && b.isAfter(latest)) latest = b;
  return latest;
}

/// 一份完整的数据快照 = 库里全部业务表的全量（notes / note_folders / todos /
/// todo_subtasks / note_tags / note_tag_links / note_versions）。
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
    this.subtasks = const <BackupTodoSubtask>[],
    this.tags = const <BackupNoteTag>[],
    this.tagLinks = const <BackupNoteTagLink>[],
    this.noteVersions = const <BackupNoteVersion>[],
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

  /// 全部子项（**不分组**：归属靠每行的 `todoId`）。
  final List<BackupTodoSubtask> subtasks;

  /// 全部标签（含墓碑行：删除也要传播，见 [BackupNoteTag]）。
  final List<BackupNoteTag> tags;

  /// 全部笔记↔标签链接（含摘除墓碑，归属靠每行的复合键）。
  final List<BackupNoteTagLink> tagLinks;

  /// 全部单篇版本历史（不分组：归属靠每行的 `noteId`）。
  final List<BackupNoteVersion> noteVersions;

  bool get isEmpty =>
      notes.isEmpty &&
      folders.isEmpty &&
      todos.isEmpty &&
      subtasks.isEmpty &&
      tags.isEmpty &&
      tagLinks.isEmpty &&
      noteVersions.isEmpty;

  int get count =>
      notes.length +
      folders.length +
      todos.length +
      subtasks.length +
      tags.length +
      tagLinks.length +
      noteVersions.length;

  /// 快照里出现过的笔记 id 集合。写 links / versions 前用来清洗悬挂外键
  /// （parse 跳过坏笔记行时，它挂的链接/版本就成了孤儿，见
  /// `BackupLocalDataSource` 的写入顺序注释）。
  Set<String> get noteIds => <String>{for (final n in notes) n.id};

  /// 快照里出现过的标签 id 集合，用途同 [noteIds]。
  Set<String> get tagIds => <String>{for (final t in tags) t.id};

  Map<String, Object?> toJson() => <String, Object?>{
    'version': backupSnapshotVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'notes': notes.map((n) => n.toJson()).toList(growable: false),
    'folders': folders.map((f) => f.toJson()).toList(growable: false),
    'todos': todos.map((t) => t.toJson()).toList(growable: false),
    'subtasks': subtasks.map((s) => s.toJson()).toList(growable: false),
    'tags': tags.map((t) => t.toJson()).toList(growable: false),
    'tagLinks': tagLinks.map((l) => l.toJson()).toList(growable: false),
    'noteVersions': noteVersions
        .map((v) => v.toJson())
        .toList(growable: false),
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
    // ⚠️ 缺这个键（v3 及更早）不是错误，是空列表 —— `_rows` 已经这么处理了。
    final subtasks = _rows(json['subtasks'], BackupTodoSubtask.fromJson);
    // v6 起的三张新表，同上：老快照缺键 = 空列表。
    final tags = _rows(json['tags'], BackupNoteTag.fromJson);
    final tagLinks = _rows(json['tagLinks'], BackupNoteTagLink.fromJson);
    final noteVersions = _rows(json['noteVersions'], BackupNoteVersion.fromJson);

    return (
      snapshot: BackupSnapshot(
        exportedAt: _date(json['exportedAt']) ?? DateTime.now(),
        notes: notes.rows,
        folders: folders.rows,
        todos: todos.rows,
        subtasks: subtasks.rows,
        tags: tags.rows,
        tagLinks: tagLinks.rows,
        noteVersions: noteVersions.rows,
      ),
      skipped:
          notes.skipped +
          folders.skipped +
          todos.skipped +
          subtasks.skipped +
          tags.skipped +
          tagLinks.skipped +
          noteVersions.skipped,
    );
  }

  /// 双向合并：逐条比 [version]，新的赢；一样新保留 [local]（避免无意义写库）。
  ///
  /// 三类实体用**同一个**比较键 `max(updatedAt, deletedAt, purgedAt)` ——
  /// 软删除与永久删除都是一次变更。这是删除能跨设备传播的**全部**机制：
  /// 库里存的是墓碑行，不是硬删除。没有墓碑的合并是纯并集，A 机删掉的行在
  /// B 机「不存在」，B 会判定本地那条更新并把它原样带回来。
  static ({BackupSnapshot merged, BackupImportResult result}) merge(
    BackupSnapshot local,
    BackupSnapshot incoming,
  ) {
    final folders = _mergeById(
      local.folders,
      incoming.folders,
      (f) => f.id,
      (f) => f.version,
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
      (t) => t.version,
    );
    // 子项与待办走**同一套**并集规则。它没有墓碑，所以只用 `updatedAt` 比 ——
    // 勾选会刷它，语义与待办的 `isDone` 切换完全一致。
    final subtasks = _mergeById(
      local.subtasks,
      incoming.subtasks,
      (s) => s.id,
      (s) => s.version,
    );
    final tags = _mergeById(
      local.tags,
      incoming.tags,
      (t) => t.id,
      (t) => t.version,
    );
    // 链接的主键是复合键 (noteId, tagId)，合并键跟着主键走。
    final tagLinks = _mergeById(
      local.tagLinks,
      incoming.tagLinks,
      (l) => l.mergeKey,
      (l) => l.version,
    );
    // 版本只增不改（无墓碑），比较键取 `createdAt`。
    final noteVersions = _mergeById(
      local.noteVersions,
      incoming.noteVersions,
      (v) => v.id,
      (v) => v.version,
    );

    final result = BackupImportResult(
      inserted:
          folders.inserted +
          notes.inserted +
          todos.inserted +
          subtasks.inserted +
          tags.inserted +
          tagLinks.inserted +
          noteVersions.inserted,
      updated:
          folders.updated +
          notes.updated +
          todos.updated +
          subtasks.updated +
          tags.updated +
          tagLinks.updated +
          noteVersions.updated,
      skipped: 0,
    );

    return (
      merged: BackupSnapshot(
        exportedAt: DateTime.now(),
        notes: notes.rows,
        folders: folders.rows,
        todos: todos.rows,
        subtasks: subtasks.rows,
        tags: tags.rows,
        tagLinks: tagLinks.rows,
        noteVersions: noteVersions.rows,
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

  /// 本地独有（对端没有 / 对端尚未收到墓碑）的行原样保留。
  ///
  /// ⚠️ 保留不等于「不删」：**软删除与永久删除的行都会带着墓碑一起被保留下来**，
  /// 写库后仍然是回收站态 / 已永久删除态 —— 删除正是这样传播的。这里保留的只是
  /// 「对方没提过的行」，删除是对方**提了**、且提了墓碑的那一类。
  ///
  /// ⚠️ 对方**物理清扫**掉的墓碑行（超过保留期）不会出现在对方快照里，于是这里
  /// 会把它当「本地独有」保留下来。这是刻意的：保留期必须长于任何设备的可能离线
  /// 时长，清扫只在「对所有设备都已过期」时才执行。
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
