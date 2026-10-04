import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/settings/presentation/providers/settings_provider.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/note_editor_provider.dart';

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
  late final TextEditingController _contentController;
  late final FocusNode _titleFocus;
  late final FocusNode _contentFocus;

  /// `PopScope` 的「已允许退出」标志。见 [_leave]。
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
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
      if (mounted) context.pop();
    });
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
      if (loaded == null || prev?.value != null) return;
      _titleController.text = loaded.draftTitle;
      _contentController.text = loaded.draftContent;
    });

    final editor = ref.watch(noteEditorProvider(widget.noteId));
    final loaded = editor.value;
    // P5「文字大小」：标题区 / 元信息行 / 正文区三处同步放大
    // （`ARCHITECTURE-DESIGN.md` §4 的取值来源表）。
    final textScale = ref.watch(textScaleFactorProvider);

    // TODO(Q32): Loading 视觉无稿（首屏读库）
    // TODO(Q33): Error 视觉无稿（读库失败）—— 错误只落日志，UI 保持空白
    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leave();
      },
      child: Scaffold(
        // 白底（D3）—— 与 P1/P2 的 `bg` 不同。
        backgroundColor: context.colors.surface,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _TopBar(onBack: _leave),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
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
                        if (loaded != null && !loaded.isNew)
                          NoteMetaLine(
                            createdAt: loaded.createdAt!,
                            wordCount: loaded.wordCount,
                            textScale: textScale,
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        _contentField(context, textScale),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    return TextField(
      controller: _contentController,
      focusNode: _contentFocus,
      onChanged: ref
          .read(noteEditorProvider(widget.noteId).notifier)
          .setContent,
      maxLines: null,
      // 段落间距**不额外实现**：D3 的段落间距 = 2×行距，是正文内容里本来就有
      // 的 `\n\n`。手写 `ParagraphStyle` 插空行会与用户输入的换行叠加成双倍空行。
      style: context.textStyles.body
          .scaled(textScale)
          .copyWith(color: context.colors.textPrimary),
      cursorColor: context.colors.textPrimary,
      // 正文无占位符（D3 有内容）；`InputDecoration.collapsed` 在本项目的
      // `material_ui` fork 里把 `hintText` 声明成必填，故传空串。
      decoration: const InputDecoration.collapsed(hintText: ''),
    );
  }
}

/// D3 的顶栏：左 `back` + 右 3 图标，无标题。
///
/// ⚠️ 三个右侧图标**只画不接**（`ROADMAP.md` §4.3：不要因为业务没能力就把图标
/// 删掉，那会让页面与设计稿不符）。点击只记日志 + TODO。
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void log(String message) {
      ref.read(taggedLoggerProvider('notes')).i(message);
    }

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
          // TODO(Q8): share 的分享目标形态未定（系统分享 / 应用内导出面板）
          onPressed: () => log('share tapped, Q8 unresolved'),
        ),
        AppIconButton(
          icon: AppIcons.palette,
          tooltip: AppLocalizations.of(context).palette,
          // TODO(Q10): palette 作用未知（配色主题 / 文字样式 / 富文本工具）
          onPressed: () => log('palette tapped, Q10 unresolved'),
        ),
        AppIconButton(
          icon: AppIcons.overflow,
          tooltip: AppLocalizations.of(context).more,
          // TODO(Q9): overflow 菜单内容与样式未知
          onPressed: () => log('overflow tapped, Q9 unresolved'),
        ),
      ],
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
