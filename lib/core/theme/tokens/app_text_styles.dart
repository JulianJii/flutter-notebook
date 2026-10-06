import 'package:material_ui/material_ui.dart';

/// 字体层级单一来源。13 级字阶。
///
/// ⚠️ **13 级的 size 已整体下收一档**（标题 24→20、正文 17→15、元信息 12→11
/// 等），`height` / `weight` 保持不变 —— 用户要求「更紧凑、一屏信息更多」。
/// 故当前取值**不再等于** `UI-IMPLEMENTATION-SPEC.md` §2.2 的实测值；字阶的
/// 相对关系（谁比谁大、谁更粗）仍与设计稿一致，只改了绝对值。
///
/// 实现为 [ThemeExtension]：`textScale`（P5 的「文字大小」，`ROADMAP.md`
/// MVP-A 第 6 项）落地后要在这里统一乘系数。见 `ARCHITECTURE-DESIGN.md` §7.3。
///
/// ⛔ **13 个字阶都不设 `color` 与 `fontFamily`**：
/// - `color` 走 [AppColors] + `DefaultTextStyle`，两处各改一次即可
///   （13 字阶 × 2 色会变成 26 个字段，实际用到的组合不超过 8 种）。
/// - `fontFamily` 待 Q26（设计稿未标注中文字体族）。
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.displayTitle,
    required this.detailTitle,
    required this.cardTitle,
    required this.rowTitle,
    required this.rowTitleStrong,
    required this.body,
    required this.snippet,
    required this.value,
    required this.subtitle,
    required this.chip,
    required this.meta,
    required this.navLabel,
    required this.topBarTitle,
  });

  /// 浅色模式取值。13 级字阶在此**一次性定档**（见 `AppTextStylesContext`）。
  ///
  /// ⛔ **不设 `fontFamily`**：设计稿未标注中文字体族（Q26）。
  const AppTextStyles.light()
    : displayTitle = const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      detailTitle = const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      cardTitle = const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      rowTitle = const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      rowTitleStrong = const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      body = const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.7,
      ),
      snippet = const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      value = const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      subtitle = const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      chip = const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.0,
      ),
      meta = const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      navLabel = const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.0,
      ),
      topBarTitle = const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  /// 深色模式取值。字阶不含颜色，light / dark 两套完全等价。
  const AppTextStyles.dark() : this.light();

  /// 页面大标题「笔记」「待办」；设置页顶部大标题。20/w700/1.2。D1/D2/D5。
  final TextStyle displayTitle;

  /// 笔记详情标题（未输入时显示占位符）。19/w500/1.3。D3。
  final TextStyle detailTitle;

  /// 笔记卡片标题。15/w600/1.4。D1。
  final TextStyle cardTitle;

  /// 待办标题、设置项标题、文件夹名。15/w400/1.4。D2/D4/D5。
  final TextStyle rowTitle;

  /// 带副标题的强调行（强提醒）。15/w600/1.4。D5。
  final TextStyle rowTitleStrong;

  /// 笔记详情正文。15/w400/1.7 —— 13 级里唯一的 1.7，是 D3 的段落感来源。D3。
  final TextStyle body;

  /// 笔记卡片摘要。13/w400/1.5。D1。
  final TextStyle snippet;

  /// 设置项右侧当前值。13/w400/1.4。D5。
  final TextStyle value;

  /// 设置项副说明。12/w400/1.4。D5。
  final TextStyle subtitle;

  /// 分类 chip。13/w500/1.0。D1。
  final TextStyle chip;

  /// 卡片日期、详情页元信息。11/w400/1.4。D1/D3。
  final TextStyle meta;

  /// 底部导航标签。11/w500/1.0。选中态 w700 由调用方
  /// `context.textStyles.navLabel.copyWith(fontWeight: FontWeight.w700)` 派生 ——
  /// 不另设字段，选中态是「同一语义的不同 weight」，不是新语义。D1/D2。
  final TextStyle navLabel;

  /// 居中顶部栏标题。16/w600/1.2。D4。
  final TextStyle topBarTitle;

  @override
  AppTextStyles copyWith({
    TextStyle? displayTitle,
    TextStyle? detailTitle,
    TextStyle? cardTitle,
    TextStyle? rowTitle,
    TextStyle? rowTitleStrong,
    TextStyle? body,
    TextStyle? snippet,
    TextStyle? value,
    TextStyle? subtitle,
    TextStyle? chip,
    TextStyle? meta,
    TextStyle? navLabel,
    TextStyle? topBarTitle,
  }) {
    return AppTextStyles(
      displayTitle: displayTitle ?? this.displayTitle,
      detailTitle: detailTitle ?? this.detailTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      rowTitle: rowTitle ?? this.rowTitle,
      rowTitleStrong: rowTitleStrong ?? this.rowTitleStrong,
      body: body ?? this.body,
      snippet: snippet ?? this.snippet,
      value: value ?? this.value,
      subtitle: subtitle ?? this.subtitle,
      chip: chip ?? this.chip,
      meta: meta ?? this.meta,
      navLabel: navLabel ?? this.navLabel,
      topBarTitle: topBarTitle ?? this.topBarTitle,
    );
  }

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) {
    if (other is! AppTextStyles) return this;
    return AppTextStyles(
      displayTitle: TextStyle.lerp(displayTitle, other.displayTitle, t)!,
      detailTitle: TextStyle.lerp(detailTitle, other.detailTitle, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      rowTitle: TextStyle.lerp(rowTitle, other.rowTitle, t)!,
      rowTitleStrong: TextStyle.lerp(rowTitleStrong, other.rowTitleStrong, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      snippet: TextStyle.lerp(snippet, other.snippet, t)!,
      value: TextStyle.lerp(value, other.value, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      chip: TextStyle.lerp(chip, other.chip, t)!,
      meta: TextStyle.lerp(meta, other.meta, t)!,
      navLabel: TextStyle.lerp(navLabel, other.navLabel, t)!,
      topBarTitle: TextStyle.lerp(topBarTitle, other.topBarTitle, t)!,
    );
  }
}

/// 按 P5 的「文字大小」缩放一个字阶。[scale] 由 `textScaleFactorProvider`
/// （`features/settings`）提供 —— **core 只认识 `double`，不认识
/// `TextScaleLevel`**（R1 / R7，见 `FEATURE-DEPENDENCIES.md` §5.1）。
///
/// [scale] 为 1.0 时与 `UI-IMPLEMENTATION-SPEC.md` §2.2 的实测值完全一致，
/// 故默认档下所有 golden 基线不变。
///
/// ⛔ **不给 [scale] 默认值**：留默认值会让漏接的调用点静默按 1.0 渲染，
/// 表现为「设置改了但这处没变」且无处报错。必填参数让编译器强制表态。
///
/// ponytail: 本期只用 `AppSettings.textScale`，不接 `MediaQuery.textScaler`
/// —— 两者相乘会让正文在系统最大字号下达到 42sp。解锁条件 = Q29 深色模式稿
/// + UX-05 无障碍补稿（`ROADMAP.md` §5 序 24）。
extension AppTextStyleScale on TextStyle {
  TextStyle scaled(double scale) =>
      fontSize == null ? this : copyWith(fontSize: fontSize! * scale);
}

/// `context.textStyles.cardTitle` 的入口。未挂载时降级为
/// [AppTextStyles.light] 而不抛异常，理由同 [AppColorsContext]。
extension AppTextStylesContext on BuildContext {
  AppTextStyles get textStyles =>
      Theme.of(this).extension<AppTextStyles>() ?? const AppTextStyles.light();
}
