import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/backup/presentation/providers/backup_file_service.dart';
import 'package:mynote/features/backup/presentation/widgets/backup_feedback.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/domain/utils/note_import.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 导入文章页（`/settings/import`）：选 Markdown / HTML 文件 → 每个文件一篇笔记。
///
/// 与数据与同步页同形态：root 层二级页，整屏盖住 Shell。
///
/// 归属 backup 而不是 settings：这里只是「数据搬运」的又一个入口，而全 App 唯一
/// 碰 `file_picker` 的地方（`backup_file_service.dart`）就在这个 feature 里。
///
/// 一个文件一篇笔记、逐文件独立成败 —— 某个文件坏了不该让整批停住，所以失败原因
/// 是**按行落在结果列表里**的，而不是弹一个全局错误就完事。
class ImportArticleScreen extends ConsumerStatefulWidget {
  const ImportArticleScreen({super.key, this.pickFiles = pickArticleFiles});

  /// 选文件。**做成可注入的**：widget 测试里换成假实现，免得测试真去弹系统
  /// 文件选择器（弹出来也没法在测试里点）。
  final Future<List<PickedArticle>> Function() pickFiles;

  @override
  ConsumerState<ImportArticleScreen> createState() =>
      _ImportArticleScreenState();
}

class _ImportArticleScreenState extends ConsumerState<ImportArticleScreen> {
  /// 导入中。选文件期间也为 true —— 否则连点两下会开出两个文件选择器。
  var _running = false;

  /// 上一次导入的结果，一行一个文件。[reason] 为 null = 成功。
  var _results = const <({String name, String? reason})>[];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: AppPageBody(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                color: colors.textPrimary,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.settings),
              ),
              centerTitle: Text(
                l10n.settingsImportArticle,
                style: context.textStyles.topBarTitle,
              ),
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    title: l10n.importArticleGroupSource,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('import_article_pick'),
                        title: l10n.importArticlePick,
                        subtitle: l10n.importArticlePickDesc,
                        trailing: _running ? _spinner(context) : null,
                        onTap: _running ? null : _pick,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.rowPadH,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      l10n.importArticleNote,
                      style: context.textStyles.meta.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  // 还没导过就不显示结果分组 —— 空分组比「暂无结果」更省事，也
                  // 省下一条只为占位的文案。
                  if (_results.isNotEmpty)
                    AppSettingsGroup(
                      key: const Key('import_article_results'),
                      title: l10n.importArticleGroupResult,
                      children: <Widget>[
                        for (final (index, result) in _results.indexed)
                          _ResultRow(
                            name: result.name,
                            detail: result.reason ?? l10n.importArticleCreated,
                            ok: result.reason == null,
                            dividerBefore: index > 0,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _running = true);

    final List<PickedArticle> picked;
    try {
      picked = await widget.pickFiles();
    } on Object {
      // 选择器自己炸了（平台层的问题）。别把页面卡在忙态上，给一句通用失败。
      if (!mounted) return;
      setState(() => _running = false);
      showFeedbackSnack(context, l10n.dataErrorUnknown, ok: false);
      return;
    }
    if (!mounted) return;
    // 用户取消 → 空列表。什么都不做（也不清掉上一次的结果）。
    if (picked.isEmpty) {
      setState(() => _running = false);
      return;
    }

    final results = <({String name, String? reason})>[
      for (final file in picked) await _importOne(file, l10n),
    ];
    if (!mounted) return;
    setState(() {
      _running = false;
      _results = results;
    });

    final created = results.where((result) => result.reason == null).length;
    showFeedbackSnack(
      context,
      created == 0
          ? l10n.importArticleAllFailed
          : l10n.importArticleDone(created, results.length - created),
      ok: created > 0,
    );
  }

  /// 导入一个文件。**失败只返回原因，不抛** —— 一个坏文件不该中断这一批。
  Future<({String name, String? reason})> _importOne(
    PickedArticle file,
    AppLocalizations l10n,
  ) async {
    final content = file.content;
    if (content == null) {
      return (name: file.name, reason: l10n.importArticleReasonUnreadable);
    }
    // 选择器已经按扩展名滤过一遍，这里是兜底（口令式传入的文件名不受它管）。
    if (!NoteImport.isSupported(file.name)) {
      return (name: file.name, reason: l10n.importArticleReasonUnsupported);
    }
    // null = 文件里只有空白，落库只会得到一条空笔记。
    final article = NoteImport.parse(fileName: file.name, content: content);
    if (article == null) {
      return (name: file.name, reason: l10n.importArticleReasonEmpty);
    }

    final result = await ref.read(createNoteUseCaseProvider)(
      CreateNoteParams(
        title: article.title,
        content: NoteDelta.encode(article.delta),
        // folderId 不传 = 「未分类」。
      ),
    );
    return (
      name: file.name,
      reason: result.fold(
        (_) => l10n.importArticleReasonWriteFailed,
        (_) => null,
      ),
    );
  }

  Widget _spinner(BuildContext context) => SizedBox(
    width: _kTrailingIconSize,
    height: _kTrailingIconSize,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: context.colors.textSecondary,
    ),
  );
}

/// 一行结果：文件名 + 结果（成功 / 失败原因）。
///
/// 不复用 `AppListTile`：它的副标题颜色写死 `textSecondary`，而失败原因要醒目的
/// 危险色 —— 为了一个颜色给三页共用的组件加参数不划算，这里复刻它的行骨架即可。
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.name,
    required this.detail,
    required this.ok,
    required this.dividerBefore,
  });

  final String name;

  /// 成功文案或失败原因（都已本地化）。
  final String detail;

  /// true = 导入成功。
  final bool ok;

  final bool dividerBefore;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (dividerBefore) const AppDivider(indent: AppListTile.indent),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.rowPadH,
            vertical: AppSpacing.rowPadH,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name,
                style: context.textStyles.rowTitle,
                // 文件名可能很长，允许折两行而不是溢出。
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppListTile.subtitleGap),
              Text(
                detail,
                style: context.textStyles.subtitle.copyWith(
                  color: ok ? colors.textSecondary : colors.feedbackDanger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const double _kTrailingIconSize = 20;
