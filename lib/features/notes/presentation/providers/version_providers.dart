import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/note_version.dart';
import '../../providers/notes_providers.dart';

part 'version_providers.g.dart';

/// 一篇笔记的版本历史（新→旧）。历史页的数据源。
@riverpod
Stream<List<NoteVersion>> noteHistory(Ref ref, String noteId) {
  return ref.watch(watchNoteVersionsUseCaseProvider).call(noteId);
}

/// 单个版本的**一次性读**（预览页用，与标签展示行同一取舍：不常驻订阅）。
@riverpod
Future<NoteVersion> noteVersion(Ref ref, String versionId) {
  return ref.watch(noteVersionRepositoryProvider).getById(versionId).then(
    (either) => either.fold(
      (failure) => throw failure,
      (version) => version,
    ),
  );
}
