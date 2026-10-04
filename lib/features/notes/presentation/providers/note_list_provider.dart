import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_query.dart';
import '../../providers/notes_providers.dart';

part 'note_list_provider.g.dart';

/// 订阅笔记列表。参数族按 [NoteQuery] 定位：相同 query 复用同一个 stream，
/// 不同 query 各自独立（依赖 `NoteQuery` 的值相等，见 `note_query.dart`）。
///
/// 排序**不在 provider 里注入**：调用方（P1，`NoteListScreen`）用
/// [withAppNoteSort] 把偏好的排序填进 `NoteQuery.sort` 再传进来。理由有二：
/// 一是本 provider 保持零偏好依赖（Phase 4 的东西不因 Phase 7 变质），
/// 二是「哪个 query 在看」由页面决定，provider 无从判断该不该改排序。
///
/// 文件夹筛选来自 URL（`?folder=xxx`）而不是全局 state
/// （`ARCHITECTURE-DESIGN.md` §8.2 / §8.5）：存成内存 state 会让 chip 高亮态
/// 与 URL 成为两个真相源。调用方从 `GoRouterState` 读出 query param 后组装
/// `NoteQuery` 传进来，本 provider 因此不 import `go_router`，单测零路由依赖。
@riverpod
Stream<List<Note>> noteList(Ref ref, NoteQuery query) {
  return ref.watch(watchNotesUseCaseProvider).call(query);
}

/// P5「选择排序方式」→ `NoteQuery.sort`。
///
/// ⚠️ **两个 feature 各有一个同名 `NoteSort`**（`AppNoteSort` 在 `settings`，
/// `NoteSort` 在 `notes`）：features 之间零互相 import（`R2`），而 `NoteSort`
/// 是笔记业务概念、不能提到 `core`（`R7`）。故在此显式 4 → 4 映射 —— 重复
/// 4 个枚举值比让 `settings` 反向依赖 `notes` 便宜，与 `NoteDaoOrder` 同理。
NoteQuery withAppNoteSort(NoteQuery query, AppNoteSort sort) => query.copyWith(
  sort: switch (sort) {
    AppNoteSort.editedDesc => NoteSort.editedDesc,
    AppNoteSort.editedAsc => NoteSort.editedAsc,
    AppNoteSort.createdDesc => NoteSort.createdDesc,
    AppNoteSort.titleAsc => NoteSort.titleAsc,
  },
);
