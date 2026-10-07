import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/app_color_scheme.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

/// 主题页：明暗 × 配色**两个独立维度**，各存各的偏好、互不覆盖。
///
/// | 分组 | 控件 | 写入 |
/// |---|---|---|
/// | 明暗模式 | 三档分段控件（浅色 / 深色 / 跟随系统） | `setThemeMode` |
/// | 配色方案 | 方案列表（主色圆点 + 选中勾） | `setColorScheme` |
///
/// 色板由 `AppTheme` 交给 flex_color_scheme 从方案主色派生；这里只负责选值。
///
/// ⛔ **不渲染 `AppBottomNav`**：root 层路由，整屏盖住 Shell，与 P5 同形态。
/// ⛔ **不直接 watch Repository / UseCase**：Screen → `settingsProvider` →
/// UseCase → Repository。
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

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
                color: context.colors.textPrimary,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.notes),
              ),
              centerTitle: Text(
                l10n.themeTitle,
                style: context.textStyles.topBarTitle,
              ),
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    title: l10n.themeSectionBrightness,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.rowPadH),
                        child: _BrightnessPicker(
                          current: settings.themeMode,
                          onChanged: notifier.setThemeMode,
                        ),
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    title: l10n.themeSectionPalette,
                    children: <Widget>[
                      for (final scheme in AppColorScheme.values)
                        AppListTile(
                          key: Key('palette_${scheme.name}'),
                          leading: _PaletteDot(color: Color(scheme.seed)),
                          title: _paletteLabel(l10n, scheme),
                          trailing: settings.colorScheme == scheme
                              ? AppIcon(
                                  icon: AppIcons.check,
                                  size: AppSpacing.rowIconSize,
                                  color: context.colors.accent,
                                )
                              : null,
                          dividerBefore: scheme != AppColorScheme.values.first,
                          onTap: () => notifier.setColorScheme(scheme),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.rowPadH,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          l10n.themeCurrent(
                            _paletteLabel(l10n, settings.colorScheme),
                            _modeLabel(l10n, settings.themeMode),
                          ),
                          style: context.textStyles.meta.copyWith(
                            color: context.colors.textTertiary,
                          ),
                        ),
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
}

/// 明暗三档分段控件。点哪档切哪档，无二次确认。
///
/// ⛔ 不用 `_pickOption` 弹层：三档一次点开可见，弹层多一次点击且看不到全貌。
/// ⛔ `showSelectedIcon: false`：M3 默认在选中档插一个勾，三档文案已经够长。
class _BrightnessPicker extends StatelessWidget {
  const _BrightnessPicker({required this.current, required this.onChanged});

  final AppThemeMode current;

  final ValueChanged<AppThemeMode> onChanged;

  /// 档位顺序固定为「浅色 / 深色 / 跟随系统」（枚举顺序是 system 优先，故显式列出）。
  static const List<AppThemeMode> _order = <AppThemeMode>[
    AppThemeMode.light,
    AppThemeMode.dark,
    AppThemeMode.system,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AppThemeMode>(
        segments: <ButtonSegment<AppThemeMode>>[
          for (final mode in _order)
            ButtonSegment<AppThemeMode>(
              value: mode,
              label: Text(_modeLabel(l10n, mode)),
            ),
        ],
        selected: <AppThemeMode>{current},
        onSelectionChanged: (selected) => onChanged(selected.first),
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: SegmentedButton.styleFrom(
          backgroundColor: colors.chipSelectedBg,
          foregroundColor: colors.textSecondary,
          selectedBackgroundColor: colors.accent,
          selectedForegroundColor: colors.surface,
          textStyle: context.textStyles.chip,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.navIcon),
          ),
          side: BorderSide.none,
        ),
      ),
    );
  }
}

/// 方案主色圆点。让「选配色」变成所见即所得，而不是选一个抽象名字。
class _PaletteDot extends StatelessWidget {
  const _PaletteDot({required this.color});

  /// 与行内图标同尺寸（`AppSpacing.rowIconSize`），避免色点比勾还大。
  static const double size = AppSpacing.rowIconSize;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.divider),
      ),
    );
  }
}

/// 配色方案 → 名称。4 值穷尽 `switch`，无 `default`（新增枚举值编译失败）。
String _paletteLabel(AppLocalizations l10n, AppColorScheme scheme) =>
    switch (scheme) {
      AppColorScheme.amber => l10n.themePaletteAmber,
      AppColorScheme.blue => l10n.themePaletteBlue,
      AppColorScheme.green => l10n.themePaletteGreen,
      AppColorScheme.violet => l10n.themePaletteViolet,
    };

/// 明暗 → 名称。3 值穷尽 `switch`。
String _modeLabel(AppLocalizations l10n, AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => l10n.settingsThemeSystem,
  AppThemeMode.light => l10n.settingsThemeLight,
  AppThemeMode.dark => l10n.settingsThemeDark,
};
