import 'package:equatable/equatable.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';

const Object _unset = Object();

/// 一条笔记。
///
/// 字段集与 `ARCHITECTURE-DESIGN.md` §5.2 逐项一致：**既不漏也不多**。
///
/// ⛔ **不落库的派生字段一律不加**：`wordCount`（用 `WordCounter` 现算）、
/// `snippet`、`folderName`。派生值落库 = 同步 bug 来源。
/// ⛔ **不预留字段**：`sortIndex` / `isPinned` / `isFavorite` / `color` /
/// `hasAttachment`（原 CONFLICT-10 对 `deletedAt` 的保留已随「最近删除」
/// 功能落地解除，见 `notes_table.dart` 头注）。
/// ⛔ **不建状态枚举**（§6.1）：设计稿对 `Note` 无任何状态描述。
/// ⛔ **无 getter**：`isEmpty` / `hasContent` 等一律不加，需要时在 UI 层现算。
class Note extends Equatable {
  const Note({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.content = '',
    this.folderId,
    this.background,
    this.deletedAt,
  });

  final String id;

  final String title;

  /// 正文。**Quill Delta 的 JSON 字符串**（`flutter_quill` 的唯一真相源）——
  /// 要纯文本（字数、摘要、搜索）走 `NoteDelta.plainText`，⛔ 别在别处
  /// 自己 `jsonDecode`。
  final String content;

  /// 所属文件夹。null = 「未分类」。
  ///
  /// ⚠️ 这里的 null 是「**这条笔记没有文件夹**」，与「不过滤」的语义无关 ——
  /// 那是 [NoteQuery] 的三态筛选（`ARCHITECTURE-DESIGN.md` §5.3）。
  final String? folderId;

  /// 纸张背景。null = 无背景（白底）。
  ///
  /// ⚠️ 它是**视觉属性**，不是编辑内容：由专用用例（`UpdateNoteBackgroundUseCase`）
  /// 只写这一列，不刷新 [updatedAt]。
  final NoteBackground? background;

  /// 本地时钟。domain 不做时区转换（§5.7「时钟」行）。
  final DateTime createdAt;

  final DateTime updatedAt;

  /// 软删除时刻。null = 正常笔记；非 null = 已进「最近删除」。
  /// 由 Repository / DataSource 写定，UI 只读不派生。
  final DateTime? deletedAt;

  /// [folderId] 用哨兵而非 `?? this.folderId` —— 否则
  /// `copyWith(folderId: null)`（显式移回「未分类」）会失效。
  /// [background] / [deletedAt] 同理：都需要「显式置回 null」。
  Note copyWith({
    String? title,
    String? content,
    Object? folderId = _unset,
    Object? background = _unset,
    Object? deletedAt = _unset,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: identical(folderId, _unset)
          ? this.folderId
          : folderId as String?,
      background: identical(background, _unset)
          ? this.background
          : background as NoteBackground?,
      deletedAt: identical(deletedAt, _unset)
          ? this.deletedAt
          : deletedAt as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    folderId,
    background,
    deletedAt,
    createdAt,
    updatedAt,
  ];
}
