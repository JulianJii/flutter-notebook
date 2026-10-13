import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mynote/core/router/app_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/features/notes/presentation/providers/note_editor_provider.dart';
import 'package:mynote/features/notes/presentation/screens/note_list_screen.dart';
import 'package:mynote/features/notes/presentation/widgets/note_search_panel.dart';

/// 桌面键盘快捷键层。
///
/// 挂 `MaterialApp.router` 的 `builder` 里、`DesktopWindowFrame` **之内**、
/// **Navigator 之上**：只有这一层能覆盖所有页面与弹层（页面内各自注册 Shortcuts
/// 会漏掉「焦点不在页面上」的时刻 —— 冷启动时焦点在最外层路由的 FocusScope 上，
/// 按键从 `primaryFocus` 向上冒泡，本层因此必然在链上；而页面内的处理者不在）。
///
/// 组合键（Windows 用 Ctrl，macOS 同组再注册一份 Cmd，见 [_bindings]）：
/// | 键 | 行为 |
/// |---|---|
/// | `Ctrl+N` | 新建笔记（带上下拉当前分类），已在笔记二级页时 no-op |
/// | `Ctrl+F` | 弹出全局搜索面板（[showNoteSearchPanel]） |
/// | `Ctrl+S` | 立即落库当前编辑页（非编辑页 no-op） |
/// | `Ctrl+,` | 打开设置 |
/// | `Esc` | 返回上一页（[rootNavigatorKey] 的 `maybePop`） |
///
/// ⛔ **Esc 必须 `maybePop`**：`pop()` 绕过 `PopScope`，等于绕过编辑页的未保存
/// 保护（编辑页靠 `PopScope` 拦下返回、先 `flush()` 草稿再退）。
///
/// ⛔ 不按平台开关：移动端根本按不出 Ctrl 组合键，装上去是零副作用的一层，
/// 少一个平台分支。
///
/// 该层虽然叫「桌面」，判断位置的依据是**路由 URL**而不是平台：
/// `ref.read(routerProvider).routerDelegate.currentConfiguration.uri`。
class DesktopShortcuts extends ConsumerStatefulWidget {
  const DesktopShortcuts({required this.child, super.key});

  /// 应用内容（`MaterialApp.router` 的 `child`，即 Navigator）。
  final Widget child;

  @override
  ConsumerState<DesktopShortcuts> createState() => _DesktopShortcutsState();
}

class _DesktopShortcutsState extends ConsumerState<DesktopShortcuts> {
  /// 搜索面板是否已打开。只用于防重入（`Ctrl+F` 连按不叠第二个面板）——
  /// 单独建一个 provider 存这个布尔位不值当。
  bool _searchOpen = false;

  /// 当前路由位置。Build 期**不** `watch` 路由：那会让每次导航都重建本层，
  /// 连带把下面的 Navigator 一起重建。
  ///
  /// ⚠️ 取 `state.uri` 而**不是** `routerDelegate.currentConfiguration.uri`：
  /// 后者对 `push` 出来的页面是**过期值**（实测停在 push 前的 URL），
  /// 于是「是不是已经在编辑页 / 设置页」这类判断会全部判错。
  Uri get _location => ref.read(routerProvider).state.uri;

  /// 新建笔记。
  ///
  /// ⛔ 已在笔记二级页（详情 / 新建 / 文件夹 / 回收站）直接 no-op：在一条还没
  /// 保存的编辑之上再叠一个「新建」，只会让人分不清哪一层是哪个草稿。
  void _newNote() {
    final uri = _location;
    if (uri.path.startsWith('${AppRoutes.notes}/')) return;

    ref
        .read(routerProvider)
        .push(
          AppRoutes.noteNewPath(
            // 复用笔记列表页的同一条映射（`uncategorized` 是筛选指令不是文件夹 id，
            // 直接透传会把哨兵当 uuid 写进新笔记的归属）。
            folderId: newNoteFolderId(
              uri.queryParameters[AppRoutes.folderQueryKey],
            ),
          ),
        );
  }

  /// 全局搜索面板。任意页面可用。
  Future<void> _search() async {
    if (_searchOpen) return;
    // ⚠️ 不能用本层的 `context` 调 `showDialog`：本层在 Navigator **之上**，
    // `Navigator.of(context)` 向上找不到 Navigator（会直接断言失败）。
    // `overlay.context` 是 Navigator 的子节点，取它当锚点。
    final overlayContext = rootNavigatorKey.currentState?.overlay?.context;
    if (overlayContext == null) return;

    setState(() => _searchOpen = true);
    await showNoteSearchPanel(overlayContext);
    if (!mounted) return;
    setState(() => _searchOpen = false);
  }

  /// 立即落库当前编辑页。
  ///
  /// ⛔ 不新增「当前编辑的是哪篇」这种状态：笔记 id 就在 URL 里（`/notes/:id`、
  /// `/notes/new` 的 `new` 即 `kNewNoteId`），分类在 `?folder=` 里 —— 与编辑页
  /// 传给 `noteEditorProvider` 的参数逐字一致，因此命中的是同一个 provider 实例。
  /// `flush()` 非 dirty 直接返回，可重复调用。
  Future<void> _save() async {
    final uri = _location;
    // 文件夹管理 / 回收站不是编辑器：照 URL 去读一篇不存在的笔记纯属白跑一次库。
    if (uri.path == AppRoutes.noteFolders || uri.path == AppRoutes.noteTrash) {
      return;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'notes') return;

    await ref
        .read(
          noteEditorProvider(
            segments[1],
            folderId: uri.queryParameters[AppRoutes.folderQueryKey],
          ).notifier,
        )
        .flush();
  }

  /// 打开设置。已在设置（含其二级页）时不重复压栈。
  void _openSettings() {
    if (_location.path.startsWith(AppRoutes.settings)) return;
    ref.read(routerProvider).push(AppRoutes.settings);
  }

  /// 返回上一页。与点返回按钮等价 —— `maybePop` 无路可退时返回 false，天然安全。
  void _back() => rootNavigatorKey.currentState?.maybePop();

  /// 组合键 → 回调。
  ///
  /// 每组同时注册 `Ctrl` 与 `Cmd` 两份：`SingleActivator` 的 `control` / `meta`
  /// 是**互斥**的，表达不了「二者其一」，而 macOS 用户按的是 Cmd。
  Map<ShortcutActivator, VoidCallback> _bindings() {
    final Map<ShortcutActivator, VoidCallback> bindings =
        <ShortcutActivator, VoidCallback>{};
    for (final meta in const <bool>[false, true]) {
      bindings.addAll(<ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyN, control: !meta, meta: meta):
            _newNote,
        SingleActivator(LogicalKeyboardKey.keyF, control: !meta, meta: meta):
            _search,
        SingleActivator(LogicalKeyboardKey.keyS, control: !meta, meta: meta):
            _save,
        SingleActivator(LogicalKeyboardKey.comma, control: !meta, meta: meta):
            _openSettings,
      });
    }
    bindings[const SingleActivator(LogicalKeyboardKey.escape)] = _back;
    return bindings;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(bindings: _bindings(), child: widget.child);
  }
}
