import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';

import 'app_color_scheme.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_elevation.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_text_styles.dart';

/// 全 App 主题。明暗 × 配色方案由 [_build] 统一产出，差异只有
/// （brightness + AppColors + AppTextStyles + ColorScheme 派生）。
///
/// 色板由 flex_color_scheme 从 [AppColorSchemeSeed.seed] 派生（surfaceMode 混合
/// + FlexKeyColors）；语义色与字阶仍全部来自 `lib/core/theme/tokens/`，
/// 本文件**不含任何语义色的字面量**（仅配色方案的 4 个主色在
/// `app_color_scheme.dart`，中性色一个都没有）。
///
/// ⚠️ `appBarTheme` 刻意**不设** `centerTitle`：顶栏由 `AppTopBar` 自绘，
/// 对齐是它的参数（TASK-009）。
class AppTheme {
  const AppTheme._();

  static ThemeData light([AppColorScheme scheme = AppColorScheme.amber]) =>
      _cached(Brightness.light, scheme);

  static ThemeData dark([AppColorScheme scheme = AppColorScheme.amber]) =>
      _cached(Brightness.dark, scheme);

  /// 2 明暗 × 4 方案 = 8 份，用到才构建。
  ///
  /// ⚠️ **缓存不可省**：`MaterialApp` 每次 build 都读 `theme` / `darkTheme`，
  /// 每次重建 `ThemeData` 会让整个 App 的 inherited 主题换新实例。
  static final Map<(Brightness, AppColorScheme), ThemeData> _cache =
      <(Brightness, AppColorScheme), ThemeData>{};

  static ThemeData _cached(Brightness brightness, AppColorScheme scheme) =>
      _cache.putIfAbsent((brightness, scheme), () => _build(brightness, scheme));

  static ThemeData _build(Brightness brightness, AppColorScheme scheme) {
    final isLight = brightness == Brightness.light;
    final colors = isLight
        ? AppColors.light(accent: Color(scheme.seed))
        : AppColors.dark(accent: Color(scheme.seed));
    final textStyles = isLight
        ? const AppTextStyles.light()
        : const AppTextStyles.dark();

    // 方案 C（`ARCHITECTURE-DESIGN.md` §7.3 / TASK-006 §1）：保留 M3 的协调色，
    // 只覆盖设计稿明确给出的 7 个值。其余 surface 阶留 FCS 派生 —— 凭空设计
    // 20 多个无稿值会让 SnackBar / Chip / TextField / Dialog 一起歪。
    final base =
        (isLight
                ? FlexColorScheme.light(
                    colors: FlexSchemeColor.from(
                      primary: colors.accent,
                      brightness: brightness,
                    ),
                    surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
                    keyColors: const FlexKeyColors(),
                  )
                : FlexColorScheme.dark(
                    colors: FlexSchemeColor.from(
                      primary: colors.accent,
                      brightness: brightness,
                    ),
                    surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
                    keyColors: const FlexKeyColors(),
                  ))
            .toTheme;

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: colors.accent,
        onPrimary: colors.surface,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.outlineControl,
        surfaceContainer: colors.bg,
        surfaceContainerLowest: colors.bg,
      ),
      scaffoldBackgroundColor: colors.bg,
      // ↓ 语义色 + 字阶的读取入口。缺这两行 context.colors 会走降级分支。
      extensions: <ThemeExtension<dynamic>>[colors, textStyles],
      appBarTheme: AppBarTheme(
        elevation: AppElevation.card,
        backgroundColor: colors.bg,
        foregroundColor: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.card,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: AppStroke.divider,
        color: colors.divider,
      ),
    );
  }
}
