import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/localization/localization_service.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

/// 设置。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **11 行 = 4 选择器 + 1 开关 + 6 chevron**，按「这行改的是谁」分成 4 组：
///
/// | 分组 | 行 | 行为 |
/// |---|---|---|
/// | 外观 | 字体 / 语言 | 选择器，点开弹层列出全部枚举值 / 档位 |
/// | 外观 | 主题 | chevron，跳主题页（明暗三档 + 配色方案） |
/// | 笔记 | 排序方式 / 列表布局 | 选择器 |
/// | 笔记 | 图片压缩 | 开关，管正文插图的处理口径 |
/// | 数据 | 数据与同步 / 最近删除 | chevron，均**已接线**跳二级页 |
/// | 关于 | 隐私政策 / 用户协议 / 关于 | chevron，同上 |
///
/// 分组口径是**影响面**：外观改整个应用怎么显示（字体 / 明暗配色 / 语言），笔记只管
/// 笔记自己（怎么排、怎么摆、插图怎么处理），数据是库的进出（导出导入同步、回收站），
/// 关于是一组静态文本。
/// ⚠️ 组名「关于」与组内最后一行同名，两处共用 `settingsAbout` —— 不为同义文案
/// 再加一个 ARB key（回收站页 = `RecentlyDeletedScreen`）。
///
/// 「云服务」分组已按产品要求去掉：应用是纯本地的，分组名没有事实依据。
/// 「提醒」分组随「强提醒」一并移除：待办稿待办没有日期 / 优先级字段，开关没有作用对象。
/// 「快捷功能」分组随其唯一一行「速记」一并移除：该行的二级页无稿，是一行点不动的死行。
///
/// 主题入口是设置稿之后补的一行（设置稿无主题行）：
/// 不给入口，`AppSettings.themeMode` / `colorScheme` 就只是永远读不到第二值的字段。
/// 值的选择在**主题页**（`ThemeScreen`），明暗与配色是两个正交维度。
///
/// ⛔ **不渲染 `AppBottomNav`**：设置是 root 层的顶层路由（`parentNavigatorKey`），
/// 整个盖住 Shell，稿上（设置稿）底部也没有 Tab。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `settingsProvider` → UseCase → Repository。
/// ⛔ **不建二级页**：值的选择走底部弹层（`_pickOption`），不跳页。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // 语言选择：`null` = 跟随系统（没选过或主动回退）。
    final languageCode = ref.watch(persistentLocaleProvider)?.languageCode;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                // 设置稿的返回箭头是深色，而 `AppIcon` 的默认色是 `outlineControl`
                // 浅灰（待按截图统一裁定）。
                // 这里按稿传色，不改 `core/ui`。
                color: context.colors.textPrimary,
                // `pop` 走 Navigator 的返回动画，与 `push` 进入成对；仅当直达
                // `/settings`（栈里没有下层页，如深链）pop 不掉时，才 `go` 回笔记列表。
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.notes),
              ),
              // 标题居中（形态 B），与文件夹管理 / 回收站 / 协议页同一形态；文案复用底栏
              // 的 `settings` key，不新增同义 key。
              centerTitle: Text(
                l10n.settings,
                style: context.textStyles.topBarTitle,
              ),
              // 设置稿顶栏下方**无** 1dp 分隔线（`AppTopBar` 默认画）。
              // 按「各页按实际稿传值」关掉。⚠️ 笔记列表 / 待办仍是默认的 true
              // （笔记列表稿 / 待办稿上同样没有这条线），待统一收敛。
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                // 卡片左右边距由 [AppSettingsGroup] 自己加（分组标题要落在 28dp 绝对
                // 缩进上，若在这里加 12dp 内边距，标题会变成 40dp）。
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    key: const Key('section_appearance'),
                    title: l10n.settingsGroupAppearance,
                    children: <Widget>[
                      // UI 字体。⛔ **只作用于 UI 文字**：每篇笔记的标题 / 正文走
                      // 该篇笔记自己的 `editorFontId`（笔记详情页顶栏的「字体」按钮）。
                      //
                      // 不走 `_selectTile` 的通用选项单：选中一款字体要先把字体文件
                      // 下载并注册进引擎，失败要留在弹层里让用户重试 —— 通用选项单
                      // 没有这个环节，它的选项是「立刻就能用」的枚举值。
                      AppListTile(
                        key: const Key('select_font_family'),
                        title: l10n.settingsFontFamily,
                        trailingValue: appFontLabel(l10n, settings.uiFontId),
                        trailing: AppIcon(
                          icon: AppIcons.chevronRight,
                          size: _kRowTrailingIconSize,
                          color: context.colors.textSecondary,
                        ),
                        onTap: () => _pickFont(context, ref),
                      ),
                      // 主题：明暗 × 配色两个维度都在独立的主题页里选
                      // （三档分段控件 + 配色列表），这里只留入口。
                      _chevronTile(
                        context,
                        key: const Key('chevron_theme'),
                        title: l10n.themeTitle,
                        dividerBefore: true,
                        onTap: () => context.push(AppRoutes.theme),
                      ),
                      // 语言：三档（跟随系统 / 中文 / English）。⚠️ 真源是 core 的
                      // `persistentLocaleProvider`（它自己写 SharedPreferences），
                      // ⛔ 不写进 `AppSettings` —— 两份偏好会让「跟随系统」无法表达。
                      // 与字体 / 主题同组：三者改的都是「整个应用怎么显示」。
                      _selectTile<String?>(
                        context,
                        key: const Key('select_language'),
                        title: l10n.language,
                        valueText: _languageLabel(l10n, languageCode),
                        options: _languageOptions,
                        current: languageCode,
                        labelOf: (code) => _languageLabel(l10n, code),
                        onSelected: (code) => ref
                            .read(persistentLocaleProvider.notifier)
                            .setLocale(code == null ? null : Locale(code)),
                        dividerBefore: true,
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    key: const Key('section_notes'),
                    title: l10n.settingsGroupNotes,
                    children: <Widget>[
                      _selectTile<AppNoteSort>(
                        context,
                        key: const Key('select_note_sort'),
                        title: l10n.settingsNoteSort,
                        valueText: _noteSortLabel(l10n, settings.noteSort),
                        options: AppNoteSort.values,
                        current: settings.noteSort,
                        labelOf: (sort) => _noteSortLabel(l10n, sort),
                        onSelected: notifier.setNoteSort,
                      ),
                      _selectTile<NoteLayout>(
                        context,
                        key: const Key('select_note_layout'),
                        title: l10n.settingsNoteLayout,
                        valueText: _noteLayoutLabel(l10n, settings.noteLayout),
                        options: NoteLayout.values,
                        current: settings.noteLayout,
                        labelOf: (layout) => _noteLayoutLabel(l10n, layout),
                        onSelected: notifier.setNoteLayout,
                        dividerBefore: true,
                      ),
                      // 插入图片前是否压缩。与排序 / 布局同组：三行都只管笔记自己
                      // （怎么排、怎么摆、正文插图怎么处理），消费方只有笔记详情
                      // （经 `noteCompressImagesProvider` 单向订阅这个 bool）。
                      AppSwitchRow(
                        key: const Key('switch_compress_images'),
                        title: l10n.settingsCompressImages,
                        value: settings.compressImages,
                        dividerBefore: true,
                        onChanged: notifier.setCompressImages,
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    key: const Key('section_data'),
                    title: l10n.settingsGroupData,
                    children: <Widget>[
                      _chevronTile(
                        context,
                        key: const Key('chevron_data_management'),
                        title: l10n.settingsDataManagement,
                        onTap: () => context.push(AppRoutes.dataManagement),
                      ),
                      _chevronTile(
                        context,
                        key: const Key('chevron_recent_deleted'),
                        title: l10n.settingsRecentDeleted,
                        dividerBefore: true,
                        onTap: () => context.push(AppRoutes.noteTrash),
                      ),
                    ],
                  ),
                  // 组名与组内最后一行同名（都复用 `settingsAbout`）：不为同义文案
                  // 再加 ARB key。要改组名就新增一个 key，别就地改这一行的文案。
                  AppSettingsGroup(
                    key: const Key('section_about'),
                    title: l10n.settingsAbout,
                    children: <Widget>[
                      _chevronTile(
                        context,
                        key: const Key('chevron_privacy_policy'),
                        title: l10n.settingsPrivacyPolicy,
                        onTap: () => context.push(AppRoutes.privacyPolicy),
                      ),
                      _chevronTile(
                        context,
                        key: const Key('chevron_user_agreement'),
                        title: l10n.settingsUserAgreement,
                        dividerBefore: true,
                        onTap: () => context.push(AppRoutes.userAgreement),
                      ),
                      _chevronTile(
                        context,
                        key: const Key('chevron_about'),
                        title: l10n.settingsAbout,
                        dividerBefore: true,
                        onTap: () => context.push(AppRoutes.about),
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

  /// chevron 行。全部 chevron 行均已接线，[onTap] 必填。
  Widget _chevronTile(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
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
      onTap: onTap,
    );
  }

  /// 右侧「当前值 + 右箭头」行：点一下**弹出选项单**，选中即写回。
  ///
  /// 「深色模式」行原是 `AppSwitchRow`、字体 / 排序 / 布局三行原是
  /// stepper（点一下翻转或循环到下一个值）：开关只有两态，`AppThemeMode.system`
  /// 因此永不可达；循环切换则看不见全部可选项。这里统一成选择器 ——
  /// 值由 [options] 全量列出，`current` 只决定勾。
  Widget _selectTile<T>(
    BuildContext context, {
    required String title,
    required String valueText,
    required List<T> options,
    required T current,
    required String Function(T value) labelOf,
    required ValueChanged<T> onSelected,
    Key? key,
    bool dividerBefore = false,
  }) {
    return AppListTile(
      key: key,
      title: title,
      trailingValue: valueText,
      trailing: AppIcon(
        icon: AppIcons.chevronRight,
        size: _kRowTrailingIconSize,
        color: context.colors.textSecondary,
      ),
      dividerBefore: dividerBefore,
      onTap: () async {
        final picked = await _pickOption<T>(
          context,
          options: options,
          current: current,
          labelOf: labelOf,
        );
        // ⚠️ **不能判 `picked != null`**：语言的「跟随系统」档就是 `null`，判空会让
        // 这一档永远选不中。重复选同一个值由各写入口自己短路
        // （`settingsProvider._write` 值没变就不写）。
        // `as T`：语言行的 `T` 是 `String?`，`T?` 与 `T` 在泛型体内不互通，显式转一次。
        if (picked != current) onSelected(picked as T);
      },
    );
  }
}

/// 行尾图标尺寸。chevron / stepper 均 20dp。
///
/// `AppIcon.defaultSize` 是 24dp 的**顶栏**尺寸；本页有 8 个行尾图标，
/// 提成文件内私有常量而不是散落 8 个字面量（⛔ 不改 `core/theme/tokens/`）。
const double _kRowTrailingIconSize = 20;

/// 弹出字体选择 → 写回 UI 字体。
///
/// ⚠️ **不能判 `picked != null`**：弹层的 `0` 就是「系统默认」这一档，判空会让它
/// 永远选不中（与设置页其余 `_selectTile` 同一个坑）。`null` 才是「用户取消了」。
///
/// ⚠️ 落库只写 id：id → 族名（含首次下载并注册）由 `core/fonts` 的
/// `fontFamilyOfProvider` 负责，本页不碰字体文件。
Future<void> _pickFont(BuildContext context, WidgetRef ref) async {
  final picked = await showAppFontPickerSheet(
    context,
    selected: appFontIndexOf(ref.read(settingsProvider).uiFontId),
  );
  if (picked == null) return;
  // `_write` 内部对「值没变」短路，重复选同一档不会产生一次 IO。
  ref.read(settingsProvider.notifier).setUiFontId(appFontIdAt(picked));
}

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

/// 语言三档：`null` 排第一（跟随系统是默认档），其余取 gen-l10n 支持的语言码。
///
/// ⛔ **不硬编码 `['zh', 'en']`**：加语言时 `AppLocalizations.supportedLocales`
/// 会跟着涨，写死列表会静默漏掉新语言。
final List<String?> _languageOptions = <String?>[
  null,
  ...AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
];

/// 语言码 → 当前值文案。`null` = 跟随系统。
///
/// 语言名用 `core` 现成的母语名映射（中文 / English），⛔ 不另加语言名文案 ——
/// 那样加一门语言要同时改 ARB 和映射表两处。
String _languageLabel(AppLocalizations l10n, String? code) => code == null
    ? l10n.settingsLanguageSystem
    : localeDisplayName(Locale(code));

/// 选项单：底部弹层，当前项打勾。选中即 `pop(value)`，取消即 `pop(null)`。
///
/// ⛔ 不引第二套选项控件：Material 的 `showModalBottomSheet` + 现成的 `AppListTile`
/// 已能表达，且字阶 / 内边距与页面内其他行同源（弹层视觉无稿，沿用 Material 默认）。
Future<T?> _pickOption<T>(
  BuildContext context, {
  required List<T> options,
  required T current,
  required String Function(T value) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final option in options)
            AppListTile(
              title: labelOf(option),
              titleWeight: option == current ? FontWeight.w600 : null,
              trailing: option == current
                  ? AppIcon(
                      icon: AppIcons.check,
                      size: _kRowTrailingIconSize,
                      color: context.colors.accent,
                    )
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(option),
            ),
        ],
      ),
    ),
  );
}
