import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/note_query.dart';

part 'note_prefs_provider.g.dart';

/// notes 侧**唯一**读 settings 的地方：把设置里的两个偏好翻译成 notes 自己的
/// 类型，notes 的页面因此不必认识 `settings` 的 provider。
///
/// 为什么翻译放在这里：`AppNoteSort` 与 `NoteSort` 是两个 feature 各持一份的
/// 同名枚举（features 之间不互相 import 的代价，见 `app_settings.dart` 顶部注释），
/// 4 → 4 的映射总要落在某一边；放在 notes 侧只写一次，三个页面都不必知道
/// `AppNoteSort` 的存在。
///
/// `select` 不能省：watch 整个 `AppSettings` 会让改 `themeMode` / `locale` 等
/// 无关偏好时整页（含所有可见 NoteCard）跟着重建。
@riverpod
({NoteSort sort, NoteLayout layout}) noteListPrefs(Ref ref) {
  final (sort, layout) = ref.watch(
    settingsProvider.select((s) => (s.noteSort, s.noteLayout)),
  );
  return (
    sort: switch (sort) {
      AppNoteSort.editedDesc => NoteSort.editedDesc,
      AppNoteSort.editedAsc => NoteSort.editedAsc,
      AppNoteSort.createdDesc => NoteSort.createdDesc,
      AppNoteSort.titleAsc => NoteSort.titleAsc,
    },
    layout: layout,
  );
}

/// 文本缩放。settings 侧导出的是 `double`（原始值，不带 settings 的任何类型），
/// 这一层只是把订阅点收进本文件 —— notes 的页面因此不必 import settings 的
/// presentation，跨 feature 依赖只剩这一个文件。
@riverpod
double noteTextScale(Ref ref) => ref.watch(textScaleFactorProvider);

/// 插入图片前是否压缩（设置项「图片压缩」）。
///
/// 与 [noteTextScale] 同理：把订阅点收进本文件，笔记详情页因此不必 import
/// `settings` 的 presentation。`select` 同样不能省。
@riverpod
bool noteCompressImages(Ref ref) =>
    ref.watch(settingsProvider.select((s) => s.compressImages));
