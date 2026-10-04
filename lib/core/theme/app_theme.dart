import 'package:material_ui/material_ui.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_elevation.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_text_styles.dart';

/// 全 App 主题。light / dark 由 [_build] 统一产出，差异只有 4 个变量
/// （brightness + AppColors + AppTextStyles + ColorScheme 派生）。
/// 取值全部来自 `lib/core/theme/tokens/`（TASK-005），本文件**不含任何
/// 字面量颜色或 dp 数字**。
///
/// ⚠️ `appBarTheme` 刻意**不设** `centerTitle`：顶栏由 `AppTopBar` 自绘，
/// 对齐是它的参数（TASK-009）。
/// ⚠️ 深色模式当前与浅色同值（`UI-IMPLEMENTATION-SPEC.md` §2.1「深色模式对应色：[无稿]」
/// + Q29）。拿到深色表后只改 `AppColors.dark()`，本文件零改动。
class AppTheme {
  const AppTheme._();

  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colors = isLight ? const AppColors.light() : const AppColors.dark();
    final textStyles = isLight
        ? const AppTextStyles.light()
        : const AppTextStyles.dark();

    // 方案 C（`ARCHITECTURE-DESIGN.md` §7.3 / TASK-006 §1）：保留 M3 的协调色，
    // 只覆盖设计稿明确给出的 7 个值。其余 surface 阶留 M3 默认 —— 凭空设计
    // 20 多个无稿值会让 SnackBar / Chip / TextField / Dialog 一起歪。
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.surface,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          outline: colors.outlineControl,
          surfaceContainer: colors.bg,
          surfaceContainerLowest: colors.bg,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
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
