import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/note_editor_provider.dart';
import '../widgets/note_editor_pane.dart';

// 编辑主体已抽到 `note_editor_pane.dart`（宽屏双栏复用同一套逻辑）。
// 这里**重新导出**几个与详情页语义绑定的类型，既有测试与调用方的 import 不必改。
export '../widgets/note_editor_pane.dart'
    show BackgroundPickerSheet, NoteMetaLine, imagePathsOf, insertImageAtCursor;

/// 笔记详情 / 编辑**整页外壳**。
///
/// 只做两件与路由相关的事：
/// 1. `PopScope`：拦住系统返回 / 手势返回，先 `flush()` 草稿再退（数据保护）。
/// 2. 深链直达（栈里没有下层）时退化成 `go(AppRoutes.notes)`。
///
/// 编辑本身（标题 / 正文 / 工具条 / 拖入插图的）全在 [NoteEditorPane] 里，
/// 宽屏双栏的右栏复用的也是它 —— ⛔ 不要在这里再写一份编辑逻辑。
class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({required this.noteId, this.folderId, super.key});

  /// 真实 uuid，或 [kNewNoteId]。
  final String noteId;

  /// 新笔记的落地分类（`/notes/new?folder=<id>`）。null = 未分类。
  final String? folderId;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  /// `PopScope` 的「已允许退出」标志。见 [_leave]。
  bool _allowPop = false;

  /// 返回前若仍脏就立即落库 —— **零成本兜底**：不询问、不弹窗，
  /// `flush()` 内部对非 dirty 直接返回。
  ///
  /// `PopScope` 必接：漏掉系统返回键 / 手势返回等于数据丢失。
  /// `canPop: false` 会同时拦下手势与代码里的 `pop()`，故用 `_allowPop` 放行，
  /// 并等一帧让 `PopScope` 读到新值。
  Future<void> _leave() async {
    await ref
        .read(
          noteEditorProvider(widget.noteId, folderId: widget.folderId).notifier,
        )
        .flush();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 深链直达（栈里没有下层）时 `pop` 会抛 "There is nothing to pop"，
      // 与文件夹管理 / 设置 / 回收站 / 法务页同一写法：退不回就回笔记列表。
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.notes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        // 白底（笔记详情稿）—— 与笔记列表/待办的 `bg` 不同。
        backgroundColor: context.colors.surface,
        body: NoteEditorPane(
          noteId: widget.noteId,
          folderId: widget.folderId,
          onClosed: _leave,
          onDeleted: () => context.go(AppRoutes.notes),
        ),
      ),
    );
  }
}
