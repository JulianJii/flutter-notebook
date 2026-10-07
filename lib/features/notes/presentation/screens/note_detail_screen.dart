import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/logging/logger_provider.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
// `BackgroundPickerSheet` 收 `AssetGenImage`，本页不再直接引用 `Assets.*`。
import 'package:mynote/gen/assets.gen.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/note_editor_provider.dart';
import '../widgets/note_background_image.dart';

/// P3 笔记详情 / 编辑（D3）。
///
/// **单态编辑页**（Q22）：D3 呈现的就是编辑态（空标题 + 有正文 + 灰色占位符）。
/// 做「阅读态 / 编辑态切换」就要自造一个无稿的只读态，并多维护一个 `isEditing`
/// 状态字段 —— 为无稿问题加状态违反 §9「能派生的不存 / 无稿不自造」。
///
/// ⛔ **不建 `AppTextField`**（`ARCHITECTURE-DESIGN.md` §7.2：解锁条件是
/// Q10 / Q22 未定）。若最终形态就是「无边框纯文本 + 灰色占位符」，它只是一条
/// `InputDecoration` 样式，不值得单独建组件。
class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({required this.noteId, super.key});

  /// 真实 uuid，或 [kNewNoteId]。
  final String noteId;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  // controller 是草稿的**权威来源**（`ARCHITECTURE-DESIGN.md` §8.1 P3 行：
  // 4 个 Local State）。provider 的 `draft*` 只用于 `isDirty` 与字数。
  late final TextEditingController _titleController;
  late final QuillController _contentController;
  late final FocusNode _titleFocus;

  /// 库 → controller 灌值期间为 true，抑制回写：否则首次 resolve 会被误判为
  /// 用户编辑，`isDirty` 假阳性、返回时白落一次库。
  bool _hydrating = false;

  /// `PopScope` 的「已允许退出」标志。见 [_leave]。
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = QuillController.basic();
    _titleFocus = FocusNode();
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController
      ..removeListener(_onContentChanged)
      ..dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  /// 正文变更 → 落库草稿。
  ///
  /// ⚠️ **每次按键全量序列化**（`ponytail:` 单文档 O(n)，笔记体量下不可测；
  /// 出现万字长文卡顿就改成 `controller.changes` 增量合并 + debounce）。
  void _onContentChanged() {
    if (_hydrating) return;
    ref
        .read(noteEditorProvider(widget.noteId).notifier)
        .setContent(NoteDelta.encode(_contentController.document.toDelta()));
  }

  /// 库里的原始值灌进编辑器。旧笔记存的是纯文本，[NoteDelta.decode] 负责兜底。
  void _hydrateContent(String raw) {
    _hydrating = true;
    _contentController.document = Document.fromDelta(NoteDelta.decode(raw));
    _hydrating = false;
  }

  /// 返回前若仍脏就立即落库 —— **零成本兜底**：不询问、不弹窗（Q24 / Q34 无稿），
  /// `flush()` 内部对非 dirty 直接返回。
  ///
  /// `PopScope` 必接：漏掉系统返回键 / 手势返回等于数据丢失。
  /// `canPop: false` 会同时拦下手势与代码里的 `pop()`，故用 `_allowPop` 放行，
  /// 并等一帧让 `PopScope` 读到新值。
  Future<void> _leave() async {
    await ref.read(noteEditorProvider(widget.noteId).notifier).flush();
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 深链直达（栈里没有下层）时 `pop` 会抛 "There is nothing to pop"，
      // 与 P4 / P5 / 回收站 / 法务页同一写法：退不回就回 P1。
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.notes);
      }
    });
  }

  /// 删除当前笔记：二次确认 → `DeleteNoteUseCase`（软删除）→ 回列表。
  ///
  /// ⛔ **不先 `flush`**：草稿还没落库就删，等于「先存再删」，多一次 IO，还会让
  /// `_leave()` 与删除抢同一个 `NoteEditor`。用户要删就是不要这些内容。
  ///
  /// ⛔ **成功后用 `go` 而非 `pop`**：`pop` 会退回上一页（可能正是这条笔记的详情
  /// 入口），留下一张读不到数据的空壳页。
  ///
  /// Q34 → docs/OPEN-DESIGN-QUESTIONS.md（确认弹窗与 Snackbar 沿用 Material 默认形态）
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.deleteNoteConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(deleteNoteUseCaseProvider)(widget.noteId);
    if (!mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {
        AppUtils.showSnackBar(context, message: l10n.noteDeleted);
        context.go(AppRoutes.notes);
      },
    );
  }

  /// palette：弹出底部滑动弹层选背景（D3）。选中即 `pop(index)`，取消不改。
  ///
  /// 弹层的下标语义（0 = 无背景，1..n = 纹理）在这里与 [NoteBackground] 互转；
  /// 落库交给 `NoteEditor.setBackground`（已有笔记只写背景列、不刷 `updatedAt`）。
  Future<void> _pickBackground() async {
    final current = ref
        .read(noteEditorProvider(widget.noteId))
        .value
        ?.draftBackground;
    final picked = await showModalBottomSheet<int>(
      context: context,
      // 弹层无底色（D3）：只留一条浅色顶边，纸纹直接浮在页面背景上。
      backgroundColor: Colors.transparent,
      // 抬升阴影是给有底色的弹层用的；无底色时它只剩一道污渍。
      elevation: 0,
      builder: (sheetContext) => BackgroundPickerSheet(
        backgrounds: noteBackgroundImages,
        selected: current == null ? 0 : current.index + 1,
      ),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(noteEditorProvider(widget.noteId).notifier)
        .setBackground(picked == 0 ? null : NoteBackground.values[picked - 1]);
  }

  /// 分享当前草稿到系统分享面板（Q8）。
  ///
  /// 分享的是**草稿**不是库里那份：用户看到什么就分享什么，因此不先 `flush`。
  /// 标题与正文都空时直接返回 —— share_plus 对空 text 抛 `ArgumentError`。
  ///
  /// `sharePositionOrigin` 不是可选美化：iPad 上缺它系统面板没锚点、直接抛错。
  Future<void> _share() async {
    final state = ref.read(noteEditorProvider(widget.noteId)).value;
    if (state == null) return;
    final title = state.draftTitle.trim();
    final text = <String>[
      if (title.isNotEmpty) title,
      NoteDelta.plainText(state.draftContent).trim(),
    ].where((line) => line.isNotEmpty).join('\n\n');
    if (text.isEmpty) return;

    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: title.isEmpty ? null : title,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object catch (error) {
      // 无分享实现的环境（桌面 / 模拟器）会抛，不能让它带着页面一起崩。
      ref.read(taggedLoggerProvider('notes')).w('share failed', error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 库中值 → controller，**只灌一次**（首次 resolve）。之后只有
    // controller → provider 一个方向；provider 的 `saved*` 变化不再回灌，
    // 否则 debounce 保存后会触发一次 `onChanged`，把「保存」误判为「编辑」，
    // `isDirty` 反复翻转。
    ref.listen<AsyncValue<NoteEditorState>>(noteEditorProvider(widget.noteId), (
      prev,
      next,
    ) {
      final loaded = next.value;
      if (loaded == null) return;
      // 自动保存失败：弹一句就清状态（否则 debounce 期间会反复弹）。
      // Q33 / Q34：Snackbar 视觉无稿，沿用既有 `AppUtils.showSnackBar`。
      final failure = loaded.lastFailure;
      if (failure != null) {
        // post-frame：listener 是在 provider 通知里同步跑的，那一刻可能正处于
        // build/layout 阶段，直接 `showSnackBar` 会打到一个还没布局完的 messenger。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AppUtils.showSnackBar(context, message: failure.message);
        });
        ref.read(noteEditorProvider(widget.noteId).notifier).clearFailure();
      }
      if (prev?.value != null) return;
      _titleController.text = loaded.draftTitle;
      _hydrateContent(loaded.draftContent);
    });

    // ⛔ 只订阅 `createdAt` —— 它是本页唯一一个**不随每次按键变**的字段
    // （`isNew` 由它派生，落库后也只变一次）。订阅整份 state 会让每敲一个字
    // 都重建含 `QuillEditor` 的整棵子树；字数行自己订阅 `wordCount`（见
    // [_NoteMetaSlot]）。
    final createdAt = ref.watch(
      noteEditorProvider(widget.noteId).select((s) => s.value?.createdAt),
    );
    // P5「文字大小」：标题区 / 元信息行 / 正文区三处同步放大
    // （`ARCHITECTURE-DESIGN.md` §4 的取值来源表）。
    final textScale = ref.watch(textScaleFactorProvider);
    // 背景单独 select：只有真正换背景时才重建本页，不随每次按键。
    final background = ref.watch(
      noteEditorProvider(
        widget.noteId,
      ).select((s) => s.value?.draftBackground),
    );
    final backgroundImage = noteBackgroundImageOrNull(background);

    // Q32 / Q33 → docs/OPEN-DESIGN-QUESTIONS.md（首屏读库的 Loading / Error 视觉无稿）
    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        // 白底（D3）—— 与 P1/P2 的 `bg` 不同。
        backgroundColor: context.colors.surface,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 背景图层（palette 切换）：半透明压在正文下面，保证文字可读。
            if (backgroundImage != null)
              Positioned.fill(
                child: Opacity(
                  opacity: kNoteBackgroundOpacity,
                  child: backgroundImage.image(fit: BoxFit.cover),
                ),
              ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _TopBar(
                    onBack: _leave,
                    onShare: _share,
                    onPalette: _pickBackground,
                    // 未落库的新笔记（`/notes/new`）库里没有对应行，删除只会拿到一句
                    // 「not found」—— 图标置灰而非弹一个必然失败的确认框。
                    canDelete: createdAt != null,
                    onDelete: _delete,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.bottomSafe,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageH,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            _titleField(context, textScale),
                            const SizedBox(height: AppSpacing.sm),
                            if (createdAt != null)
                              _NoteMetaSlot(
                                noteId: widget.noteId,
                                createdAt: createdAt,
                                textScale: textScale,
                              ),
                            const SizedBox(height: AppSpacing.lg),
                            _EditorToolbar(controller: _contentController),
                            const SizedBox(height: AppSpacing.sm),
                            _contentField(context, textScale),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleField(BuildContext context, double textScale) {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocus,
      onChanged: ref.read(noteEditorProvider(widget.noteId).notifier).setTitle,
      // D3 无输入框视觉：边框、下划线、光标样式均无稿，不自造。
      style: context.textStyles.detailTitle
          .scaled(textScale)
          .copyWith(color: context.colors.textPrimary),
      cursorColor: context.colors.textPrimary,
      decoration: InputDecoration.collapsed(
        hintText: AppLocalizations.of(context).noteTitleHint,
        hintStyle: context.textStyles.detailTitle
            .scaled(textScale)
            .copyWith(color: context.colors.textPlaceholder),
      ),
    );
  }

  Widget _contentField(BuildContext context, double textScale) {
    // 段落间距**不额外实现**：D3 的段落间距 = 2×行距，是正文内容里本来就有
    // 的 `\n\n`。手写 `ParagraphStyle` 插空行会与用户输入的换行叠加成双倍空行。
    //
    // `DefaultTextStyle` 是把 Design Token 的正文样式喂给 Quill 的唯一入口：
    // Quill 的 `DefaultStyles.getInstance` 从 `DefaultTextStyle.of(context)` 取
    // 基准样式，而它读的是 **flutter SDK** 的 Theme —— 本项目用 `material_ui`
    // 的 Theme，两套互不相通，不显式喂就是默认字号 + 暗色模式下黑字黑底。
    return DefaultTextStyle(
      style: context.textStyles.body
          .scaled(textScale)
          .copyWith(color: context.colors.textPrimary),
      child: QuillEditor.basic(
        controller: _contentController,
        config: const QuillEditorConfig(
          // 外层已有 SingleChildScrollView，编辑器内不再自带滚动。
          scrollable: false,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// 正文富文本工具条。
///
/// **常驻一行**，不做「聚焦才浮出」：浮出要额外订阅编辑器焦点态，而本页是单态
/// 编辑页（见本文件头注），常驻一行 42dp 不引入任何新状态。
///
/// 按钮集是**裁剪过的**：Quill 默认全量（字体 / 字号 / 对齐 / 颜色 / 代码块 /
/// 上下标 / 缩进 / 剪贴板 / 搜索）一行滑不完，找按钮要一直横向拖。
/// 关掉的每一项下面都写了理由 —— Q9（溢出菜单）/ Q10（配色）出稿后再加回。
class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({required this.controller});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // 底边一条分隔线把工具条与正文分开。页面 `Column` 的交叉轴是 `start`，
      // 故要显式撑满，否则这条线只盖住工具条本身那一段。
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: QuillSimpleToolbar(
          controller: controller,
          config: QuillSimpleToolbarConfig(
            // 单行：`multiRowsDisplay: false` 走 Quill 自带的横向滚动按钮列表
            // （固定高 42dp，放不下时两侧出现滚动箭头）。360dp 竖屏放不下 11 个
            // 按钮，故**必然**是「一行 + 可滑动」而不是 `Wrap` 的两行。
            multiRowsDisplay: false,
            // 默认底色是 `Theme.canvasColor`，与本页纸面白底不一致。
            color: context.colors.surface,
            showDividers: true,
            sectionDividerColor: context.colors.divider,
            showUndo: true,
            showRedo: true,
            showBoldButton: true,
            showItalicButton: true,
            showUnderLineButton: true,
            showStrikeThrough: true,
            showListNumbers: true,
            showListBullets: true,
            showQuote: true,
            showLink: true,
            showClearFormat: true,
            // 字体 / 字号：P5「文字大小」已是页面级设置，正文里再插一套会打架。
            showFontFamily: false,
            showFontSize: false,
            showSmallButton: false,
            showLineHeightButton: false,
            // 颜色 / 背景色：Q10「配色 / 样式」无稿，`palette` 按钮暂占该语义。
            showColorButton: false,
            showBackgroundColorButton: false,
            // H1/H2：页面顶部已有独立标题输入框，正文再给标题层级与之重复。
            showHeaderStyle: false,
            showAlignmentButtons: false,
            showIndent: false,
            showListCheck: false,
            // 代码 / 上下标 / 剪贴板 / 搜索：笔记正文无此语义。
            showCodeBlock: false,
            showInlineCode: false,
            showSubscript: false,
            showSuperscript: false,
            showSearchButton: false,
            showDirection: false,
          ),
        ),
      ),
    );
  }
}

/// D3 的顶栏：左 `back` + 右 3 图标，无标题。
///
/// palette 接了「切换正文背景图」（循环：无背景 ↔ 3 张纸张纹理，见
/// [noteBackgroundImages]）。Q10 原本的「配色 / 样式」语义
/// 尚无稿，先以背景切换落地，出稿后再扩展。
/// share 接了系统分享（Q8）；overflow 接了「删除」——它是 Q9 未定稿菜单里唯一
/// 有确定语义的一项（`DeleteNoteUseCase` 已就绪）。待 Q9 出稿再改成真正的菜单。
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.onBack,
    required this.onShare,
    required this.onPalette,
    required this.onDelete,
    required this.canDelete,
  });

  final VoidCallback onBack;

  final VoidCallback onShare;

  final VoidCallback onPalette;

  final VoidCallback onDelete;

  /// false → 删除图标禁用（笔记尚未落库）。
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTopBar(
      leading: AppIconButton(
        icon: AppIcons.back,
        tooltip: AppLocalizations.of(context).back,
        onPressed: onBack,
      ),
      actions: <Widget>[
        AppIconButton(
          icon: AppIcons.share,
          tooltip: AppLocalizations.of(context).share,
          onPressed: onShare,
        ),
        AppIconButton(
          icon: AppIcons.palette,
          tooltip: AppLocalizations.of(context).palette,
          onPressed: onPalette,
        ),
        AppIconButton(
          icon: AppIcons.overflow,
          tooltip: canDelete
              ? AppLocalizations.of(context).deleteNote
              : AppLocalizations.of(context).more,
          onPressed: canDelete ? onDelete : null,
        ),
      ],
    );
  }
}

/// [NoteMetaLine] 的订阅壳。存在的**唯一**理由是隔离 rebuild：
/// `wordCount` 依赖 `draftContent`，每敲一个字都变。挂在页面里就等于让
/// 每一次按键都重建 `Scaffold` + `QuillEditor` + 整段正文的排版；自己
/// `select` 之后，重建范围缩到这一行文本。
class _NoteMetaSlot extends ConsumerWidget {
  const _NoteMetaSlot({
    required this.noteId,
    required this.createdAt,
    required this.textScale,
  });

  final String noteId;

  /// 父级已判非空（落库成功后才有），这里只透传，不重复订阅。
  final DateTime createdAt;
  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordCount = ref.watch(
      noteEditorProvider(noteId).select((s) => s.value?.wordCount),
    );
    return NoteMetaLine(
      createdAt: createdAt,
      wordCount: wordCount ?? 0,
      textScale: textScale,
    );
  }
}

/// 详情页元信息行：`10月3日 6:40 | 35字`。
///
/// T3 页面内组件，语义与 P3 绑定，不上提为 `core/ui`、不单独建文件
/// （`DEVELOPMENT-GUIDELINES.md` §7.3「1 个页面 + 语义与页面绑定 → 页面内」）。
/// 类名不加 `_` 前缀是为了 widget 测试能直接引用它。
class NoteMetaLine extends StatelessWidget {
  const NoteMetaLine({
    required this.createdAt,
    required this.wordCount,
    required this.textScale,
    super.key,
  });

  final DateTime createdAt;

  /// 已由 `WordCounter` 算好的字数。本组件**不调** `WordCounter`（保持纯展示）。
  final int wordCount;

  /// P5「文字大小」的排版系数，由 `NoteDetailScreen` 透传。⛔ 必填无默认。
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMd(locale).format(createdAt);
    // ⚠️ 刻意用 `h:mm` 而不是 `DateFormat.jm`：D3 显示「6:40」**无 AM/PM**，
    // 而 `jm` 在 zh locale 下输出「上午6:40」。12/24 小时制偏好待设计补稿。
    final time = DateFormat('h:mm', locale).format(createdAt);

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: '$date $time'),
          // 分隔符两侧各留约 6dp（12sp 下一个空格 ≈3dp，两个 ≈6dp）。§4 P3 `[推导]`。
          const TextSpan(text: '  |  '),
          TextSpan(
            text: AppLocalizations.of(context).noteMetaWordCount(wordCount),
          ),
        ],
      ),
      style: context.textStyles.meta
          .scaled(textScale)
          .copyWith(color: context.colors.textTertiary),
    );
  }
}

/// 背景选择弹层（D3）：横向滑动的纸张缩略图，选中项描琥珀边（D3 实测）。
///
/// 下标语义：0 = 无背景（白底 + 示意横线），1..n = [backgrounds]。
/// 调用方负责与 `NoteBackground` 互转（下标 `index - 1` → `values[index - 1]`）。
/// 选中即 `Navigator.pop(index)`，取消（下滑 / 点遮罩）返回 null = 不改。
///
/// T3 页面内组件，语义与 P3 绑定，不上提为 `core/ui`、不单独建文件
/// （`DEVELOPMENT-GUIDELINES.md` §7.3）。类名不加 `_` 前缀是为了 widget 测试能引用它。
class BackgroundPickerSheet extends StatelessWidget {
  const BackgroundPickerSheet({
    required this.backgrounds,
    required this.selected,
    super.key,
  });

  /// 纸张纹理候选，展示顺序即切换顺序。
  final List<AssetGenImage> backgrounds;

  /// 当前选中下标（0 = 无背景）。
  final int selected;

  /// 缩略图尺寸。稿上约 100×135，按屏宽比例取整到 88×120（D3 `[推导]`）。
  static const double _tileWidth = 88;
  static const double _tileHeight = 120;

  /// 圆角与描边（选中 2dp 琥珀，未选中 1dp 分隔色）。
  static const double _radius = 12;

  /// 「无背景」缩略图里的示意横线宽度，稿上四条不等长（D3 实测）。
  static const List<double> _blankLines = <double>[56, 72, 64, 48];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppDivider(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: SizedBox(
              height: _tileHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
                children: <Widget>[
                  for (var index = 0; index <= backgrounds.length; index++)
                    _tile(context, index),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context);
    final isSelected = index == selected;
    final colors = context.colors;
    return Padding(
      // 末项不留右侧空隙，末项圆角与页面右边距自然对齐。
      padding: EdgeInsets.only(
        right: index == backgrounds.length ? 0 : AppSpacing.gridGutter,
      ),
      child: Semantics(
        key: ValueKey<int>(index),
        button: true,
        selected: isSelected,
        label: index == 0 ? l10n.noteBackgroundNone : l10n.noteBackground,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(index),
          child: Container(
            width: _tileWidth,
            height: _tileHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: isSelected ? colors.accent : colors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: index == 0
                ? _blankTile(context)
                : backgrounds[index - 1].image(
                    width: _tileWidth,
                    height: _tileHeight,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
    );
  }

  /// 「无背景」缩略图：白底 + 四条示意横线。
  Widget _blankTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final width in _blankLines)
            Container(
              width: width,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.textPlaceholder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
