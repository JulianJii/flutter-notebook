import 'dart:async';

import 'package:init/core/logging/logger_provider.dart';
import 'package:init/features/notes/domain/usecases/create_note_params.dart';
import 'package:init/features/notes/domain/usecases/update_note_params.dart';
import 'package:init/features/notes/domain/utils/word_counter.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_editor_provider.g.dart';

/// 新建笔记的哨兵 id。与 `AppRoutes.noteNew`（`/notes/new`）一一对应。
const String kNewNoteId = 'new';

const Object _unset = Object();

/// P3 的草稿状态：一次读 + 局部更新，**不需要 stream**（`ARCHITECTURE-DESIGN.md`
/// §6.2 P3）。用 `AsyncNotifier` 让 loading / error 零成本。
///
/// ⛔ **零状态枚举**：loading / error 由 `AsyncValue` 承载，`isDirty` /
/// `wordCount` / `isNew` 全是派生 getter（§6.3「能派生的一律不存」）。
class NoteEditorState {
  const NoteEditorState({
    this.draftTitle = '',
    this.draftContent = '',
    this.savedTitle = '',
    this.savedContent = '',
    this.createdAt,
    this.isSaving = false,
  });

  /// 草稿。`TextEditingController` 的值经 `onChanged` 落到这里。
  final String draftTitle;
  final String draftContent;

  /// 上次**成功落库**的值。与 `draft*` 不同 —— 落库失败时 `draft*` 保留而
  /// `saved*` 不动，`isDirty` 因此仍为 true，用户可再次触发保存（不丢数据）。
  final String savedTitle;
  final String savedContent;

  final DateTime? createdAt;

  final bool isSaving;

  bool get isDirty => draftTitle != savedTitle || draftContent != savedContent;

  int get wordCount => WordCounter.count(draftContent);

  /// 新笔记还没有 `createdAt`，因此 `isNew` 派生自它而不是另存一个 flag。
  bool get isNew => createdAt == null;

  NoteEditorState copyWith({
    String? draftTitle,
    String? draftContent,
    String? savedTitle,
    String? savedContent,
    Object? createdAt = _unset,
    bool? isSaving,
  }) {
    return NoteEditorState(
      draftTitle: draftTitle ?? this.draftTitle,
      draftContent: draftContent ?? this.draftContent,
      savedTitle: savedTitle ?? this.savedTitle,
      savedContent: savedContent ?? this.savedContent,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
///
/// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
/// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。
@riverpod
class NoteEditor extends _$NoteEditor {
  Timer? _debounce;

  /// `build` 的入参。codegen 不把 family 参数存成字段，`flush()` 又要用，故显式留一份。
  late String _noteId;

  @override
  Future<NoteEditorState> build(String noteId) {
    _noteId = noteId;
    // 不取消会「页面已销毁但定时器触发」，写进已 dispose 的 provider。
    ref.onDispose(() => _debounce?.cancel());

    if (noteId == kNewNoteId) {
      return Future.value(const NoteEditorState());
    }
    return ref
        .read(getNoteUseCaseProvider)(noteId)
        .then(
          (result) => result.fold(
            // `Failure` 本身就是 `Object`，直接抛即可，`AsyncValue.error` 会承载它。
            (failure) => throw failure,
            (note) => NoteEditorState(
              draftTitle: note.title,
              draftContent: note.content,
              savedTitle: note.title,
              savedContent: note.content,
              createdAt: note.createdAt,
            ),
          ),
        );
  }

  void setTitle(String value) => _edit((s) => s.copyWith(draftTitle: value));

  void setContent(String value) =>
      _edit((s) => s.copyWith(draftContent: value));

  void _edit(NoteEditorState Function(NoteEditorState) apply) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(apply(current));
    _scheduleSave();
  }

  /// debounce 500ms —— `ARCHITECTURE-DESIGN.md` §4 P3 / §8.6 明确的值。
  /// 不用 debounce 包：加一个依赖不值 3 行 `Timer`。
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), flush);
  }

  /// 立即落库。**public**：`NoteDetailScreen` 返回前直接调它，不在 Screen 里
  /// 重写一遍保存逻辑。非 dirty 直接返回，因此正常返回路径零开销、可重复调用。
  Future<void> flush() async {
    _debounce?.cancel();
    final current = state.value;
    if (current == null || !current.isDirty) return;

    state = AsyncData(current.copyWith(isSaving: true));
    final result = current.isNew
        ? await ref.read(createNoteUseCaseProvider)(
            CreateNoteParams(
              title: current.draftTitle,
              content: current.draftContent,
            ),
          )
        : await ref.read(updateNoteUseCaseProvider)(
            UpdateNoteParams(
              noteId: _noteId,
              title: current.draftTitle,
              content: current.draftContent,
            ),
          );

    // 标题与正文都为空时不做特殊处理：交给 UseCase 的 `InputFailure`，
    // UI 不重复校验（`ARCHITECTURE-DESIGN.md` §4 P1 链路）。
    state = AsyncData(
      result.fold(
        // 失败：草稿保留、`saved*` 不动 → `isDirty` 仍为 true，可再次触发保存。
        // TODO(Q33): 保存失败的用户可见反馈无稿（Snackbar / Dialog 整类缺失，见 Q34）。
        // TODO(Q24): 保存指示器无稿，`isSaving` 目前只被测试与未来使用。
        (failure) {
          ref
              .read(taggedLoggerProvider('notes'))
              .w('note save failed', error: failure);
          return current.copyWith(isSaving: false);
        },
        (saved) => current.copyWith(
          isSaving: false,
          savedTitle: saved.title,
          savedContent: saved.content,
          createdAt: saved.createdAt,
        ),
      ),
    );
  }
}
