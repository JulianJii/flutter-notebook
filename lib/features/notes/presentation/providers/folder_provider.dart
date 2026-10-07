import 'package:mynote/core/usecases/usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/folder_with_count.dart';
import '../../providers/notes_providers.dart';

part 'folder_provider.g.dart';

/// 文件夹 + 每个文件夹的笔记数。**P4 的 `FolderRow` 与 P1 的筛选 chip 共用
/// 这一个数据源**（`ARCHITECTURE-DESIGN.md` §3.2）。
///
/// 数据由 drift watch 驱动，`AsyncValue` 已覆盖 loading / data / error，
/// 因此**无自定义 State**（§6.2 P4 段 / R8）。空列表用 `value?.isEmpty` 派生。
///
/// ⚠️ 结果里**只有真实文件夹**，0 笔记的文件夹也在内（`count = 0`，DAO 的
/// `LEFT JOIN` 语义）。「全部」与「未分类」**不是**本流的行（§5.3）——
/// 前者由消费方求和，后者见 [uncategorizedCountProvider]。
///
/// ⛔ 不做二次排序：`ORDER BY sort_index ASC, created_at ASC` 已在 DAO 的 SQL 里
/// 排完。P4 拖拽后 `sort_index` 一变，drift watch 就推出新顺序 —— 顺序的真相源
/// 只有这一条 SQL。
@riverpod
Stream<List<FolderWithCount>> folder(Ref ref) {
  return ref.watch(watchFolderCountsUseCaseProvider).call(NoParams());
}

/// 「未分类」的笔记数（D4 的 `未分类 154`）。
///
/// ⚠️ **这里的取名不归 provider**：l10n 文案与设计稿用字由消费方
/// （P4，`TASK-050`）决定，provider 不知道也不该知道。
///
/// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
/// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
///
/// ⛔ **不复用 `noteListProvider` 再 `.length`**：那条链路是「取列表再数长度」，
/// 会把全部未分类笔记的正文（Quill Delta JSON）读进内存只为拿一个整数，
/// 且每次笔记变动都重来一遍。DAO 里那条 `COUNT(*)` 就是为它准备的。
@riverpod
Stream<int> uncategorizedCount(Ref ref) {
  return ref.watch(folderRepositoryProvider).watchUncategorizedCount();
}
