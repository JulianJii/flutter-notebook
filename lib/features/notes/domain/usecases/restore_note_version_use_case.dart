import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_version.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_version_repository.dart';

/// 恢复某个版本 = **真回滚**（区别于全局快照的「找回」）：
///
/// 1. 先把**当前内容**存为一版（防丢 —— 用户恢复错了还能再翻回来）；
/// 2. 再用版本内容覆盖笔记（`NoteRepository.update` 会刷 `updatedAt`，
///    覆盖本身是一次内容编辑，必须跨设备传播）。
///
/// ⛔ 两步顺序不可倒：先覆盖再存当前版的话，去重逻辑会把「刚恢复的内容」
/// 当成最新一版跳过，当前内容就真丢了。
class RestoreNoteVersionUseCase {
  const RestoreNoteVersionUseCase(this._versions, this._notes);

  final NoteVersionRepository _versions;
  final NoteRepository _notes;

  Future<Either<Failure, Unit>> call(String versionId, int limit) async {
    final NoteVersion version;
    switch (await _versions.getById(versionId)) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        version = value;
    }

    final Note note;
    switch (await _notes.getById(version.noteId)) {
      case Left(:final value):
        // 版本还在但笔记没了（极端：挂接清扫竞态）。无事可做，如实上报。
        return Left(value);
      case Right(:final value):
        note = value;
    }

    // 当前内容先存一版（id 空串 = Repository 生成 uuid）。
    // 备份失败不拦恢复：草稿里仍是旧内容，主体动作是恢复。
    await _versions.saveVersion(
      NoteVersion(
        id: '',
        noteId: note.id,
        title: note.title,
        content: note.content,
        createdAt: AppClock.appNow(),
      ),
      limit,
    );

    // update 返回更新后的 Note；本用例的产出是「恢复了」这件事本身 → Unit。
    return _notes
        .update(note.copyWith(title: version.title, content: version.content))
        .then((result) => result.map((_) => unit));
  }
}
