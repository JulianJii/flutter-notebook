import 'package:material_ui/material_ui.dart';

/// 设计稿强调色。`UI-IMPLEMENTATION-SPEC.md` §2.1 的 `accent`。
///
/// ⛔ 不要散落字面量：换配色方案时只有 `AppTheme` 会传新的 `accent`，
/// 其余 12 个中性色不动，故默认值集中在这里。
const Color kDesignAccent = Color(0xFFF0A020);

/// 语义色单一来源。取值来自 `UI-IMPLEMENTATION-SPEC.md` §2.1（14 行表格）。
///
/// 实现为 [ThemeExtension] 而非散落的 const：13 个语义色 + 深色模式，
/// 必须一处改全生效。见 `ARCHITECTURE-DESIGN.md` §7.3。
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceInverse,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textPlaceholder,
    required this.textSectionHeader,
    required this.accent,
    required this.divider,
    required this.outlineControl,
    required this.switchOff,
    required this.chipSelectedBg,
    required this.textDisabled,
  });

  /// 浅色模式取值。`UI-IMPLEMENTATION-SPEC.md` §2.1 原表。
  ///
  /// [accent] 由配色方案传入（`AppTheme`），默认 [kDesignAccent]。
  const AppColors.light({this.accent = kDesignAccent})
    : bg = const Color(0xFFF2F2F2),
      surface = const Color(0xFFFFFFFF),
      surfaceInverse = const Color(0xFF1A1A1A),
      textPrimary = const Color(0xFF1A1A1A),
      textSecondary = const Color(0xFF999999),
      textTertiary = const Color(0xFFB3B3B3),
      textPlaceholder = const Color(0xFFC0C0C0),
      textSectionHeader = const Color(0xFFA0A0A0),
      divider = const Color(0xFFE5E5E5),
      outlineControl = const Color(0xFF9E9E9E),
      switchOff = const Color(0xFFBDBDBD),
      chipSelectedBg = const Color(0xFFEFEFEF),
      textDisabled = const Color(0xFF666666);

  /// 深色模式取值。
  ///
  /// ⚠️ 中性色**不是**浅色的复制：深底配深字会不可读，故 13 个语义色全部
  /// 另给一套深色值（色板本身由 flex_color_scheme 从 [accent] 派生）。
  /// Q36 → docs/OPEN-DESIGN-QUESTIONS.md（深色表无稿，按 M3 深色规范反推）
  const AppColors.dark({this.accent = kDesignAccent})
    : bg = const Color(0xFF121212),
      surface = const Color(0xFF1E1E1E),
      surfaceInverse = const Color(0xFFE5E5E5),
      textPrimary = const Color(0xFFF2F2F2),
      textSecondary = const Color(0xFF999999),
      textTertiary = const Color(0xFF7A7A7A),
      textPlaceholder = const Color(0xFF5A5A5A),
      textSectionHeader = const Color(0xFF8A8A8A),
      divider = const Color(0xFF2E2E2E),
      outlineControl = const Color(0xFF9E9E9E),
      switchOff = const Color(0xFF4A4A4A),
      chipSelectedBg = const Color(0xFF2A2A2A),
      textDisabled = const Color(0xFFA0A0A0);

  /// 页面底色（列表页 / 设置页）。D1/D2/D4/D5 卡片外区域。
  final Color bg;

  /// 卡片与面板底色。D1–D5。
  final Color surface;

  /// 底部导航「选中」图标底。D1/D2。
  final Color surfaceInverse;

  /// 大标题、卡片标题、设置项标题、正文。D1–D5。
  final Color textPrimary;

  /// 摘要、设置项右侧值、待办副文案。D1/D3/D5。
  final Color textSecondary;

  /// 日期、详情页元信息。D1/D3。
  final Color textTertiary;

  /// 详情页「标题」占位符。D3。
  final Color textPlaceholder;

  /// 设置分组标题。D5。
  final Color textSectionHeader;

  /// FAB、加号、文件夹选中勾、新建文件夹图标、开关 on。D1/D2/D4/D5。
  ///
  /// ⚠️ 取色校准（2026-10-04，D2 原图 1080×2460 直方图取色）：FAB 圆面主色
  /// 峰值实测为 **`#FFBB10`**，与本表的 `#F0A020` 相差 15(R)/27(G)/16(B)，
  /// 远超「2 个色阶」。**本轮保留规格值未改**（改设计 token 是设计侧决策），
  /// 该差异已登记在 `specs/docs/PROJECT-STATUS.md`，等设计确认后再动这一个字段。
  final Color accent;

  /// 设置卡片内行分割线、底部导航顶部分隔线。D5/D1/D2。
  final Color divider;

  /// 复选框描边、底部导航未选中图标。D1/D2。
  final Color outlineControl;

  /// 「强提醒」开关关闭轨道。D5。
  final Color switchOff;

  /// 「全部」chip 选中底。D1。
  ///
  /// chip 未选中底是 [surface]（`#FFFFFF`），不另设字段。
  final Color chipSelectedBg;

  /// 「新建文件夹」行文案色。D4 `[推导]`。
  ///
  /// ⚠️ D4 实测的`#666` **不在** `UI-IMPLEMENTATION-SPEC.md` §2.1 的 14 行
  /// 颜色表里 —— 它既不是 [textPrimary]（标题黑）也不是 [textSecondary]
  /// （计数灰 `#999999`），是卡片内一个独立的中间灰，故补一个字段。
  /// JPEG 取色精度有限，登记为 §9 容差项。
  final Color textDisabled;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceInverse,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textPlaceholder,
    Color? textSectionHeader,
    Color? accent,
    Color? divider,
    Color? outlineControl,
    Color? switchOff,
    Color? chipSelectedBg,
    Color? textDisabled,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      textSectionHeader: textSectionHeader ?? this.textSectionHeader,
      accent: accent ?? this.accent,
      divider: divider ?? this.divider,
      outlineControl: outlineControl ?? this.outlineControl,
      switchOff: switchOff ?? this.switchOff,
      chipSelectedBg: chipSelectedBg ?? this.chipSelectedBg,
      textDisabled: textDisabled ?? this.textDisabled,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceInverse: Color.lerp(surfaceInverse, other.surfaceInverse, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      textSectionHeader: Color.lerp(
        textSectionHeader,
        other.textSectionHeader,
        t,
      )!,
      accent: Color.lerp(accent, other.accent, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      outlineControl: Color.lerp(outlineControl, other.outlineControl, t)!,
      switchOff: Color.lerp(switchOff, other.switchOff, t)!,
      chipSelectedBg: Color.lerp(chipSelectedBg, other.chipSelectedBg, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
    );
  }
}

/// `context.colors.accent` 的入口。
///
/// 必须在 `ThemeData.extensions` 里挂了 [AppColors] 才能读；未挂时返回
/// [AppColors.light] 而非抛异常 —— 让「忘接线」退化成视觉错误而不是崩溃。
extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? const AppColors.light();
}
