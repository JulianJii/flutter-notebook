import 'dart:async';

import 'package:init/core/error/failures.dart';
import 'package:init/core/logging/logger_provider.dart';
import 'package:init/features/notes/domain/entities/note_background.dart';
import 'package:init/features/notes/domain/usecases/create_note_params.dart';
import 'package:init/features/notes/domain/usecases/update_note_background_params.dart';
import 'package:init/features/notes/domain/usecases/update_note_params.dart';
import 'package:init/features/notes/domain/utils/note_delta.dart';
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
    this.draftBackground,
    this.savedBackground,
    this.createdAt,
    this.isSaving = false,
    this.lastFailure,
  });

  /// 草稿。`TextEditingController` 的值经 `onChanged` 落到这里。
  final String draftTitle;
  final String draftContent;

  /// 上次**成功落库**的值。与 `draft*` 不同 —— 落库失败时 `draft*` 保留而
  /// `saved*` 不动，`isDirty` 因此仍为 true，用户可再次触发保存（不丢数据）。
  final String savedTitle;
  final String savedContent;

  /// 当前选中的纸张背景（null = 无背景）。
  ///
  /// ⛔ **不计入 [isDirty]**：换背景不是编辑。已有笔记由 [NoteEditor.setBackground]
  /// 走「只写背景列」的窄通道即时落库，新笔记随首次 `create` 一并写入。
  final NoteBackground? draftBackground;

  /// 上次成功落库的背景。与 [draftBackground] 对称，便于判断是否需要补写。
  final NoteBackground? savedBackground;

  final DateTime? createdAt;

  final bool isSaving;

  /// 最近一次落库失败。**唯一的用户可见失败信号**（Q33 / Q34：Snackbar 视觉无稿，
  /// 沿用 `AppUtils.showSnackBar`）。
  ///
  /// 为什么不直接用 `flush()` 的返回值：自动保存走 `Timer`，返回值被丢弃 ——
  /// 恰好是最该提示的路径会静默。UI 读这个字段弹完提示后调 [NoteEditor.clearFailure]
  /// 清空，避免 debounce 期间重复弹。
  final Failure? lastFailure;

  bool get isDirty => draftTitle != savedTitle || draftContent != savedContent;

  /// `draftContent` 是 Quill Delta JSON，需先还原纯文本再计数。
  int get wordCount => WordCounter.count(NoteDelta.plainText(draftContent));

  /// 新笔记还没有 `createdAt`，因此 `isNew` 派生自它而不是另存一个 flag。
  bool get isNew => createdAt == null;

  NoteEditorState copyWith({
    String? draftTitle,
    String? draftContent,
    String? savedTitle,
    String? savedContent,
    Object? draftBackground = _unset,
    Object? savedBackground = _unset,
    Object? createdAt = _unset,
    bool? isSaving,
    Object? lastFailure = _unset,
  }) {
    return NoteEditorState(
      draftTitle: draftTitle ?? this.draftTitle,
      draftContent: draftContent ?? this.draftContent,
      savedTitle: savedTitle ?? this.savedTitle,
      savedContent: savedContent ?? this.savedContent,
      draftBackground: identical(draftBackground, _unset)
          ? this.draftBackground
          : draftBackground as NoteBackground?,
      savedBackground: identical(savedBackground, _unset)
          ? this.savedBackground
          : savedBackground as NoteBackground?,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      isSaving: isSaving ?? this.isSaving,
      lastFailure: identical(lastFailure, _unset)
          ? this.lastFailure
          : lastFailure as Failure?,
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

  /// `/notes/new` 下 `create` 成功后拿到的真实 uuid。
  ///
  /// 不记它就会静默丢数据：`create` 一落库 `createdAt` 变非空 → `isNew` 转 false，
  /// 但 `_noteId` 仍是哨兵 `'new'`，用户继续编辑再 `flush()` 就变成拿 `'new'` 去
  /// `update` 一条不存在的记录 → 永远失败，草稿存不进去且无任何提示。
  String? _savedId;

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
              draftBackground: note.background,
              savedBackground: note.background,
              createdAt: note.createdAt,
            ),
          ),
        );
  }

  void setTitle(String value) => _edit((s) => s.copyWith(draftTitle: value));

  void setContent(String value) =>
      _edit((s) => s.copyWith(draftContent: value));

  /// 切换纸张背景（null = 无背景）。
  ///
  /// 已有笔记：走窄通道**即时落库**（只写背景列、不刷新 `updatedAt`），因此
  /// ⛔ 不进 [NoteEditorState.isDirty] 的自动保存链路。
  ///
  /// 新笔记（`/notes/new`，库里还没有行）：只更新草稿，随首次 `create` 一并写库
  /// —— 只有背景没有内容的空笔记照旧不产生记录。
  Future<void> setBackground(NoteBackground? value) async {
    final current = state.value;
    if (current == null || current.draftBackground == value) return;
    state = AsyncData(current.copyWith(draftBackground: value));
    if (current.isNew) return;

    final result = await ref.read(updateNoteBackgroundUseCaseProvider)(
      UpdateNoteBackgroundParams(
        // `create` 过一次就用真实 id（与 `flush` 同一条约定）。
        noteId: _savedId ?? _noteId,
        background: value,
      ),
    );
    // `await` 期间用户可能还在打字：合并进**最新**的 state，别把 `current`
    // 整份写回去覆盖掉刚输入的内容。
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      result.fold(
        (failure) {
          ref
              .read(taggedLoggerProvider('notes'))
              .w('note background save failed', error: failure);
          // 草稿保留用户的选择（视觉已生效），失败信号交给 UI 弹提示。
          return latest.copyWith(lastFailure: failure);
        },
        (_) => latest.copyWith(savedBackground: value, lastFailure: null),
      ),
    );
  }

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

    // 刻意**不**写 `isSaving: true` 的中间态：它没有任何 UI 消费方（Q24），却会让
    // 每次自动保存多一次整页重建。等真做保存指示器时再在这一行加回去。
    final result = current.isNew
        ? await ref.read(createNoteUseCaseProvider)(
            CreateNoteParams(
              title: current.draftTitle,
              content: current.draftContent,
              // 先选背景、后写内容：首次落库时把背景一起带上。
              background: current.draftBackground,
            ),
          )
        : await ref.read(updateNoteUseCaseProvider)(
            UpdateNoteParams(
              // `create` 过一次就用真实 id：`_noteId` 在 `/notes/new` 下是哨兵。
              noteId: _savedId ?? _noteId,
              title: current.draftTitle,
              content: current.draftContent,
            ),
          );

    // 标题与正文都为空时不做特殊处理：交给 UseCase 的 `InputFailure`，
    // UI 不重复校验（`ARCHITECTURE-DESIGN.md` §4 P1 链路）。
    state = AsyncData(
      result.fold(
        // 失败：草稿保留、`saved*` 不动 → `isDirty` 仍为 true，可再次触发保存。
        // 失败信号写进 `lastFailure` 供 UI 弹提示（Q33 / Q34）。
        (failure) {
          ref
              .read(taggedLoggerProvider('notes'))
              .w('note save failed', error: failure);
          return current.copyWith(isSaving: false, lastFailure: failure);
        },
        (saved) {
          _savedId ??= saved.id;
          return current.copyWith(
            isSaving: false,
            savedTitle: saved.title,
            savedContent: saved.content,
            savedBackground: saved.background,
            createdAt: saved.createdAt,
            lastFailure: null,
          );
        },
      ),
    );
  }

  /// 清掉已提示过的失败（UI 弹完 Snackbar 立刻调）。
  void clearFailure() {
    final current = state.value;
    if (current == null || current.lastFailure == null) return;
    state = AsyncData(current.copyWith(lastFailure: null));
  }
}
