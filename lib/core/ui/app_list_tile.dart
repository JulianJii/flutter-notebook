import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/core/ui/app_divider.dart';
import 'package:material_ui/material_ui.dart';

/// 设置 / 文件夹 / 待办的通用行。P2 / P4 / P5 三页共用一个组件。
///
/// 6 种形态由 5 个可选参数的**组合**表达（`ARCHITECTURE-DESIGN.md` §7.6：
/// 布尔开关是「设计失败的味道」）：
///
/// | 形态 | 参数组合 | 稿 |
/// |---|---|---|
/// | 纯文字 | `title` | — |
/// | 前置复选框 | `leading` + `title` | D2 |
/// | 前置勾 + 右侧计数 | `leading` + `title` + `trailingValue` | D4 |
/// | 右箭头 | `title` + `trailing` | D5 |
/// | 右值 + 右图标 | `title` + `trailingValue` + `trailing` | D5 |
/// | 副标题 + 开关 | `title` + `subtitle` + `titleWeight` + `trailing` | D5 |
///
/// ⛔ **无 `height` 参数**：D5 chevron 行 56dp / switch 行 72dp / D4 行 ≈60dp
/// / D2 行 ≈60dp 四个稿值不同。行高由 [AppTextStyles.rowTitle] + 上下
/// [AppSpacing.rowPadH] 自然得出，一份代码覆盖全部四值。
///
/// ⛔ **不管 `leading` 宽度**：D4 的 32dp 对齐槽位（选中项显示 20dp 琥珀勾、
/// 未选中留空，导致名称左边界右移 24dp 不对齐 —— **Q25b**）由 `FolderRow`
/// 负责，见 `TASK-049`。
///
/// ⛔ **不含业务语义**：本组件不认识「笔记 / 待办 / 文件夹」，`title` /
/// `subtitle` 是中性文案参数。
///
/// ⚠️ **无稿项**：D5 只画了 Switch 的 off 态（**Q26b**）、D2 只有 unchecked
/// 复选框（**Q21**）、全稿无按压态（**Q35**）。本组件只负责行骨架。
class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingValue,
    this.onTap,
    this.dividerBefore = false,
    this.titleWeight,
  });

  /// 主文案，由调用方传 l10n 结果。§2.2 `text.rowTitle`（16sp / w400）。
  final String title;

  /// 副文案（D5「强提醒」）。非 null 时渲染第二行，字阶 `text.subtitle`。
  final String? subtitle;

  /// 左侧插槽。调用方自选尺寸并负责对齐（D4 的 32dp 槽位见 Q25b）。
  final Widget? leading;

  /// 右侧插槽。chevron 图标 / stepper 图标 / 开关。
  final Widget? trailing;

  /// 右端当前值（D4 计数、D5 stepper 行的「默认」）。字阶 `text.value`。
  final String? trailingValue;

  /// 点击回调。null → **不包 `InkWell`**，不做水波纹。
  ///
  /// ⚠️ D5 二级页未设计（**Q14**），稿中按压态无稿（**Q35**），
  /// 故不可点行完全无交互反馈。`ROADMAP.md` §4.3 要求二级页保持不可点 +
  /// `TODO(Q14)`。
  final VoidCallback? onTap;

  /// 行上方 1dp 分割线（D5 同卡片内多行）。
  final bool dividerBefore;

  /// 标题字重。null → `text.rowTitle` 的 w400；D5「强提醒」传 w600。
  final FontWeight? titleWeight;

  /// `trailingValue` 与相邻元素的间距（D5 stepper 行左右间距 8dp `[推导]`）。
  static const double gap = AppSpacing.chipGap;

  /// `subtitle` 与 `title` 的间距（D5 强提醒行实测 4dp）。
  static const double subtitleGap = 4;

  /// 分割线左缩进，与行文字左边界对齐。
  ///
  /// 16dp 卡片内边距 = D5 实测的「28dp」= 页面 12 + 卡片 16。⚠️ 传了非 null
  /// `leading` 时本组件**测不到**它的宽度（组件保持哑的，见 Q25b），故缩进
  /// 仍是 16dp 而非「leading 宽 + 16dp」；带 leading 的分割线对齐由调用方
  /// （`FolderRow`）用 `AppDivider` 自行处理。
  static const double indent = AppSpacing.rowPadH;

  @override
  Widget build(BuildContext context) {
    return Column(
      // min：行高永远由内容决定，绝不撑满父级给的有限高度。父级若是
      // ListView（无界）两者等价；父级若给了 bounded height（如测试里的
      // Scaffold body），max 会让单行涨到整屏。
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dividerBefore) AppDivider(indent: indent),
        _body(context),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final colors = context.colors;
    final titleStyle = context.textStyles.rowTitle.copyWith(
      fontWeight: titleWeight,
    );

    final row = Row(
      children: [
        if (leading != null) ...[leading!, SizedBox(width: gap)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: titleStyle),
              if (subtitle != null) ...[
                SizedBox(height: subtitleGap),
                Text(
                  subtitle!,
                  style: context.textStyles.subtitle.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailingValue != null) ...[
          SizedBox(width: gap),
          Text(
            trailingValue!,
            style: context.textStyles.value.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
        if (trailing != null) ...[SizedBox(width: gap), trailing!],
      ],
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.rowPadH,
        vertical: AppSpacing.rowPadH,
      ),
      child: row,
    );

    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}
