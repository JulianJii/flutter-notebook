import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

/// P5 设置（D5）。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **8 行 = 4 可写 + 4 不可点**，一一对应 D5 的 6 个区块：
///
/// | 分组 | 行 | 行为 |
/// |---|---|---|
/// | 云服务 | 最近删除 | chevron，**不可点**（Q14） |
/// | 笔记样式 | 文字大小 / 选择排序方式 / 笔记列表布局 | stepper，点一下循环到下一个枚举值 |
/// | 快捷功能 | 速记 | chevron，**不可点**（Q14） |
/// | 提醒 | 强提醒 | 开关，写回 `settingsProvider` |
/// | 其他 | 隐私政策 / 用户协议 | chevron，**不可点**（Q14） |
///
/// ⛔ **不渲染 `AppBottomNav`**：P5 是 root 层的顶层路由（`parentNavigatorKey`），
/// 整个盖住 Shell，稿上（D5）底部也没有 Tab。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `settingsProvider` → UseCase → Repository。
/// ⛔ **不建二级页 / 不建选择器弹层**（Q14 / Q25 未答，见 Out of Scope）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                // D5 的返回箭头是深色，而 `AppIcon` 的默认色是 `outlineControl`
                // 浅灰（`PROJECT-STATUS.md` §3.10 待办 #2：待按截图统一裁定）。
                // 这里按稿传色，不改 `core/ui`。
                color: context.colors.textPrimary,
                // `go` 而非 `pop`：`/settings` 是 root 层的顶层路由，栈里没有下层
                // 页面可 pop（`app_routes.dart` 已写明「返回目标为 P1」）。
                onPressed: () => context.go(AppRoutes.notes),
              ),
              // D5 顶栏下方**无** 1dp 分隔线（`AppTopBar` 默认画）。
              // 按 §3.9 待办 #2「各页按实际稿传值」关掉。⚠️ P1 / P2 仍是默认的 true
              // （D1 / D2 上同样没有这条线），统一收敛归 TASK-051。
              showDivider: false,
            ),
            // D5 的大标题就是「笔记」，与 P1 / 底栏同一个词 → 复用 `notes` 这个 key，
            // 不新增第 2 个同义 key（新增即两份可能漂移的文案）。
            // `textScale: 1` —— 同 P2：P5 的行用 `AppListTile`，D5 上没有
            // 「文字大小」这一行的消费方（`ARCHITECTURE-DESIGN.md` §4）。
            AppLargeTitle(text: l10n.notes, textScale: 1),
            Expanded(
              child: ListView(
                // 卡片左右边距由 [_Group] 自己加（分组标题要落在 28dp 绝对缩进上，
                // 若在这里加 12dp 内边距，标题会变成 40dp）。
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  _Group(
                    key: const Key('section_cloud'),
                    title: l10n.settingsGroupCloud,
                    children: <Widget>[
                      _chevronTile(
                        context,
                        key: const Key('chevron_recent_deleted'),
                        title: l10n.settingsRecentDeleted,
                      ),
                    ],
                  ),
                  _Group(
                    key: const Key('section_note_style'),
                    title: l10n.settingsGroupNoteStyle,
                    children: <Widget>[
                      _stepperTile(
                        context,
                        key: const Key('stepper_text_scale'),
                        title: l10n.settingsTextScale,
                        valueText: _textScaleLabel(l10n, settings.textScale),
                        onStep: () => notifier.setTextScale(
                          _cycle(TextScaleLevel.values, settings.textScale),
                        ),
                      ),
                      _stepperTile(
                        context,
                        key: const Key('stepper_note_sort'),
                        title: l10n.settingsNoteSort,
                        valueText: _noteSortLabel(l10n, settings.noteSort),
                        dividerBefore: true,
                        onStep: () => notifier.setNoteSort(
                          _cycle(AppNoteSort.values, settings.noteSort),
                        ),
                      ),
                      _stepperTile(
                        context,
                        key: const Key('stepper_note_layout'),
                        title: l10n.settingsNoteLayout,
                        valueText: _noteLayoutLabel(l10n, settings.noteLayout),
                        dividerBefore: true,
                        onStep: () => notifier.setNoteLayout(
                          _cycle(NoteLayout.values, settings.noteLayout),
                        ),
                      ),
                    ],
                  ),
                  _Group(
                    key: const Key('section_quick'),
                    title: l10n.settingsGroupQuick,
                    children: <Widget>[
                      _chevronTile(
                        context,
                        key: const Key('chevron_quick_capture'),
                        title: l10n.settingsQuickCapture,
                      ),
                    ],
                  ),
                  _Group(
                    key: const Key('section_reminder'),
                    title: l10n.settingsGroupReminder,
                    children: <Widget>[
                      AppSwitchRow(
                        key: const Key('switch_strong_reminder'),
                        title: l10n.settingsStrongReminder,
                        subtitle: l10n.settingsStrongReminderDesc,
                        value: settings.strongReminder,
                        onChanged: notifier.setStrongReminder,
                      ),
                    ],
                  ),
                  _Group(
                    key: const Key('section_other'),
                    title: l10n.settingsGroupOther,
                    children: <Widget>[
                      _chevronTile(
                        context,
                        key: const Key('chevron_privacy_policy'),
                        title: l10n.settingsPrivacyPolicy,
                      ),
                      _chevronTile(
                        context,
                        key: const Key('chevron_user_agreement'),
                        title: l10n.settingsUserAgreement,
                        dividerBefore: true,
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

  /// Q14：D5 的 chevron 行二级页全部无稿 → 保持不可点，但右箭头照常画出来。
  Widget _chevronTile(
    BuildContext context, {
    required String title,
    Key? key,
    bool dividerBefore = false,
  }) {
    return AppListTile(
      key: key,
      title: title,
      trailing: AppIcon(
        icon: AppIcons.chevronRight,
        size: _kRowTrailingIconSize,
        color: context.colors.textSecondary,
      ),
      dividerBefore: dividerBefore,
      onTap: null, // ← 关键：不可点
      // TODO(Q14): 该行的二级页未设计（最近删除 / 速记 / 隐私政策 / 用户协议），
      // 补稿后接线。
    );
  }

  /// 右侧「当前值 + 上下双箭头」行。
  ///
  /// TODO(Q14): 点击是「弹选择器」还是「循环切换」待设计确认 —— 本页按「循环切换」
  /// 实现（零新增组件、零凭空视觉，见 `TASK-046` §3 的三方案裁决）。
  Widget _stepperTile(
    BuildContext context, {
    required String title,
    required String valueText,
    required VoidCallback onStep,
    Key? key,
    bool dividerBefore = false,
  }) {
    return AppListTile(
      key: key,
      title: title,
      trailingValue: valueText,
      // TODO(Q25): 稿上是「上下双箭头」。`AppIcons.stepper`(`Icons.swap_vert`) 是
      // TASK-010 已有的最接近语义（⛔ 不为对齐这一个字形去改 `core/ui`），
      // 形态待设计校准。
      trailing: AppIcon(
        icon: AppIcons.stepper,
        size: _kRowTrailingIconSize,
        color: context.colors.textSecondary,
      ),
      dividerBefore: dividerBefore,
      onTap: onStep,
    );
  }
}

/// 一个分组 = 标题 + 一张白卡。页面内私有组件（`DEVELOPMENT-GUIDELINES.md` §7.2）。
///
/// ⛔ **不加新组件**：`AppSectionHeader`（TASK-011）+ `AppCard`（TASK-011）已能表达
/// D5 的分组结构，本类只做「标题在卡外、左右边距只给卡」的排版。
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children, super.key});

  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 分组标题在卡外侧：它的 28dp 左缩进是**页面绝对**缩进（= 12 页面边距 +
        // 16 行内边距），所以不能被卡片的 12dp 包裹。
        AppSectionHeader(text: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
          child: AppCard(
            // 卡内不加内边距：行的左右 16dp 由 `AppListTile` 提供（D5 实测
            // 卡片左边界 → 行文字 16dp）。加了会出现 12 + 16 = 28dp 的双重缩进。
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

/// 行尾图标尺寸。`UI-IMPLEMENTATION-SPEC.md` §2.5：chevron / stepper 均 20dp。
///
/// `AppIcon.defaultSize` 是 24dp 的**顶栏**尺寸；本页有 8 个行尾图标，
/// 提成文件内私有常量而不是散落 8 个字面量（⛔ 不改 `core/theme/tokens/`）。
const double _kRowTrailingIconSize = 20;

/// 循环到下一个枚举值（3 个 stepper 行共用）。
///
/// TODO(Q14): 若设计改判为「弹选择器」，删掉本函数与 3 处 `onStep` 的循环体，
/// 改为打开对应选择页 —— 届时才需要弹层视觉。
T _cycle<T extends Enum>(List<T> values, T current) =>
    values[(current.index + 1) % values.length];

/// 文字大小 → 当前值文案。
///
/// ⛔ **不直接上屏 `TextScaleLevel.name`**：那会显示英文 `xLarge`。
/// 映射是 P5 专属文案，故放页面内而不进 `core/`（约束 7）。
String _textScaleLabel(AppLocalizations l10n, TextScaleLevel level) =>
    switch (level) {
      // D5 上默认值显示的是「默认」而不是「标准」→ `normal` 这一档的文案是「默认」。
      TextScaleLevel.small => l10n.settingsTextScaleSmall,
      TextScaleLevel.normal => l10n.settingsTextScaleDefault,
      TextScaleLevel.large => l10n.settingsTextScaleLarge,
      TextScaleLevel.xLarge => l10n.settingsTextScaleXLarge,
    };

/// 排序方式 → 当前值文案。4 值穷尽 `switch`，无 `default`（新增枚举值编译失败）。
String _noteSortLabel(AppLocalizations l10n, AppNoteSort sort) =>
    switch (sort) {
      AppNoteSort.editedDesc => l10n.settingsSortEditedDesc,
      AppNoteSort.editedAsc => l10n.settingsSortEditedAsc,
      AppNoteSort.createdDesc => l10n.settingsSortCreatedDesc,
      AppNoteSort.titleAsc => l10n.settingsSortTitleAsc,
    };

/// 列表布局 → 当前值文案。
String _noteLayoutLabel(AppLocalizations l10n, NoteLayout layout) =>
    switch (layout) {
      NoteLayout.grid => l10n.settingsLayoutGrid,
      NoteLayout.list => l10n.settingsLayoutList,
    };
