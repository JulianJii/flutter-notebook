import 'package:equatable/equatable.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';

const Object _unset = Object();

/// 一条笔记。
///
/// 字段集与 `ARCHITECTURE-DESIGN.md` §5.2 逐项一致：**既不漏也不多**。
///
/// ⛔ **不落库的派生字段一律不加**：`wordCount`（用 `WordCounter` 现算）、
/// `snippet`、`folderName`。派生值落库 = 同步 bug 来源。
/// ⛔ **不预留字段**：`sortIndex` / `color` / `hasAttachment`。
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
    this.editorFontId,
    this.deletedAt,
    this.isPinned = false,
    this.isFavorite = false,
    this.purgedAt,
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

  /// 这篇笔记的编辑器字体：`core/fonts` 目录里某个字体的 **id**，null = 系统默认。
  ///
  /// ⛔ **存 id 不存族名**：族名是 `DynamicFont` 注册进引擎用的名字，属于
  /// `core/fonts` 的目录数据（换字体版本可能变），本层也不 import 它。
  ///
  /// ⚠️ 它是**每篇笔记的视觉属性**，与 [background] 同类：由专用用例
  /// （`UpdateNoteEditorFontUseCase`）只写这一列、不刷新 [updatedAt]。
  final String? editorFontId;

  /// 本地时钟。domain 不做时区转换（§5.7「时钟」行）。
  final DateTime createdAt;

  final DateTime updatedAt;

  /// 软删除时刻。null = 正常笔记；非 null = 已进「最近删除」。
  /// 由 Repository / DataSource 写定，UI 只读不派生。
  final DateTime? deletedAt;

  /// 置顶。列表排序里恒排未置顶之前，**与 [createdAt] / [updatedAt] 无关**。
  final bool isPinned;

  /// 收藏。与 [isPinned] 是两个正交维度：置顶管「最近要看的在前面」，
  /// 收藏管「重要的找得到」。
  final bool isFavorite;

  /// 永久删除墓碑时刻。UI 与业务逻辑都**不看它** —— 它只活在数据层与同步链路里，
  /// 让「永久删除」能跨设备传播（见 `notes_table.dart` 的列注释）。
  final DateTime? purgedAt;

  /// [folderId] 用哨兵而非 `?? this.folderId` —— 否则
  /// `copyWith(folderId: null)`（显式移回「未分类」）会失效。
  /// [background] / [editorFontId] / [deletedAt] / [purgedAt] 同理：都需要
  /// 「显式置回 null」（换回「系统默认字体」正是其中一种）。
  Note copyWith({
    String? title,
    String? content,
    Object? folderId = _unset,
    Object? background = _unset,
    Object? editorFontId = _unset,
    Object? deletedAt = _unset,
    Object? purgedAt = _unset,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isFavorite,
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
      editorFontId: identical(editorFontId, _unset)
          ? this.editorFontId
          : editorFontId as String?,
      deletedAt: identical(deletedAt, _unset)
          ? this.deletedAt
          : deletedAt as DateTime?,
      purgedAt: identical(purgedAt, _unset)
          ? this.purgedAt
          : purgedAt as DateTime?,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
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
    editorFontId,
    deletedAt,
    purgedAt,
    isPinned,
    isFavorite,
    createdAt,
    updatedAt,
  ];
}
