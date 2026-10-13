import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_query.dart';
import '../../domain/utils/note_delta.dart';
import '../providers/note_list_provider.dart';
import '../providers/note_prefs_provider.dart';

/// 弹出全局搜索面板（桌面 `Ctrl+F`）。
///
/// 与笔记列表页的那个内联搜索框**是两套东西**：面板自持 `TextEditingController`
/// 与本地关键字（⛔ 不写 `noteSearchProvider`），因此在面板里打字不会顺手把背后
/// 的笔记列表也过滤掉。数据侧复用 `noteListProvider` + `noteListPrefsProvider`，
/// 不新建查询链路。
///
/// ⛔ 不做 debounce：见 `note_search_provider.dart` 顶部既有裁决（本项目笔记量级
/// 下参数化 `LIKE` 全表扫描是几十微秒）。
///
/// ⚠️ 视觉**无稿**（设计未出全局搜索弹层），按既有 token 推导：页面偏上登场、
/// 白底、无阴影、靠底色差与分隔线分层；不新增色值 / 字阶。
Future<void> showNoteSearchPanel(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => const NoteSearchPanel(),
);

/// 全局搜索面板本体（可被 widget 测试直接引用，故不加 `_` 前缀）。
class NoteSearchPanel extends ConsumerStatefulWidget {
  const NoteSearchPanel({super.key});

  @override
  ConsumerState<NoteSearchPanel> createState() => _NoteSearchPanelState();
}

class _NoteSearchPanelState extends ConsumerState<NoteSearchPanel> {
  late final TextEditingController _controller;
  String _term = '';

  /// 面板宽度上限。无稿：比笔记详情正文区窄，读长标题不必扫整屏。
  static const double _kMaxWidth = 560;

  /// 输入行距屏幕顶部的距离（`Dialog` 的 `insetPadding.vertical`）。
  static const double _kTopInset = 80;

  /// 结果区高度上限（屏高占比），超出在面板内滚动。
  static const double _kResultsHeightRatio = 0.6;

  /// 摘要截断长度。`AppListTile.subtitle` 没有 `maxLines`，不截断会让一条结果
  /// 占满整个面板。
  static const int _kSnippetMaxChars = 80;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _term = '');
  }

  /// 打开一条结果：先关面板再 push 详情（详情是二级页，⛔ 不能用 `go` ——
  /// 返回键要回到打开面板前的页面）。
  ///
  /// ⚠️ `GoRouter` 必须先取出来：`pop` 之后本 widget 的 `context` 已失效。
  void _open(Note note) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutes.noteDetailPath(note.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final term = _term.trim();
    final sort = ref.watch(noteListPrefsProvider.select((prefs) => prefs.sort));

    // ⛔ 没有关键字时**不订阅**：`searchTerm: ''` 在 datasource 里会被归一成
    // `null`，等于「查全部笔记」，白白扫一次全表。
    final AsyncValue<List<Note>> results = term.isEmpty
        ? const AsyncData<List<Note>>(<Note>[])
        : ref.watch(noteListProvider(NoteQuery(searchTerm: term, sort: sort)));
    final notes = results.value ?? const <Note>[];

    return Dialog(
      // 偏上登场（无稿：搜索是「抬头看一眼」的动作，不占屏幕中心）。
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: _kTopInset,
      ),
      backgroundColor: colors.surface,
      // 全 App 无阴影（`AppElevation.card` = 0），弹层同样靠底色差浮起。
      elevation: AppElevation.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _kMaxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * _kResultsHeightRatio,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _inputField(context, l10n, notes),
            // 没有关键字时面板只留一行输入框（无稿：「最近笔记」这类初始列表无稿，
            // 不自造）。
            if (term.isNotEmpty) ...<Widget>[
              const AppDivider(
                indent: AppSpacing.rowPadH,
                endIndent: AppSpacing.rowPadH,
              ),
              // `Flexible` + 内部 `shrinkWrap`：结果少时面板跟着变矮，多了才滚动。
              Flexible(
                child: notes.isEmpty
                    ? _emptyState(context, l10n, results.hasValue)
                    : _results(context, notes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    BuildContext context,
    AppLocalizations l10n,
    List<Note> notes,
  ) {
    final style = context.textStyles.body;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.rowPadH,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          AppIcon(
            icon: AppIcons.search,
            size: AppSpacing.rowIconSize,
            color: colors.textPlaceholder,
          ),
          const SizedBox(width: AppSpacing.chipGap),
          Expanded(
            child: TextField(
              key: const Key('global_search_field'),
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _term = value),
              // Enter 打开第一条：无稿，取「搜索面板」的通用惯例。
              onSubmitted: notes.isEmpty ? null : (_) => _open(notes.first),
              style: style.copyWith(color: colors.textPrimary),
              cursorColor: colors.textPrimary,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: l10n.notesSearchHint,
                hintStyle: style.copyWith(color: colors.textPlaceholder),
              ),
            ),
          ),
          // 清空按钮沿用笔记列表搜索框的写法（同一个字形 + tooltip）。
          if (_term.isNotEmpty)
            IconButton(
              tooltip: l10n.notesSearchClear,
              icon: const AppIcon(icon: AppIcons.trash, size: 18),
              onPressed: _clear,
            ),
        ],
      ),
    );
  }

  /// 空态：读库返回了空列表才算「没找到」—— 流还没出值时不闪这一行。
  Widget _emptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool hasValue,
  ) {
    if (!hasValue) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        l10n.emptySearchResult,
        // 与笔记列表页的搜索空态逐字一致（同字阶同色）。
        style: context.textStyles.subtitle.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
    );
  }

  Widget _results(BuildContext context, List<Note> notes) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return AppListTile(
          key: ValueKey<String>(note.id),
          // ⚠️ 无标题的笔记就显示空的标题行（与卡片一致），不自造「无标题」文案：
          // 摘要在旁边已经能认出是哪条。
          title: note.title,
          subtitle: _snippetOf(note.content),
          trailing: const AppIcon(icon: AppIcons.chevronRight),
          onTap: () => _open(note),
        );
      },
    );
  }

  /// 正文纯文本 → 压成单行 → 截断。空正文返回 null（不渲染副标题行）。
  static String? _snippetOf(String content) {
    final text = NoteDelta.plainText(
      content,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    // `substring` 可能切在代理对上（emoji）；列表里至多一个替换字形，不做处理。
    return text.length > _kSnippetMaxChars
        ? '${text.substring(0, _kSnippetMaxChars)}…'
        : text;
  }
}
