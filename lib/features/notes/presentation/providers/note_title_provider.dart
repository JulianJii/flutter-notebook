import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/notes_providers.dart';

part 'note_title_provider.g.dart';

/// 一篇笔记的标题（一次性读）。给待办卡上的「挂接笔记」chip 用：
/// 挂接是低频状态，为每个 chip 常驻一条笔记流是浪费；读不到（笔记已被
/// 物理清扫）返回空串，由 UI 兜底提示（见 `TodoCard` 的挂接 chip）。
@riverpod
Future<String> noteTitle(Ref ref, String noteId) async {
  final result = await ref.watch(getNoteUseCaseProvider).call(noteId);
  return result.fold((_) => '', (note) => note.title);
}
