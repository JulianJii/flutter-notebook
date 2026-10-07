import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:material_ui/material_ui.dart';

/// 20dp 见方复选框（待办稿待办行左侧）。
///
/// 度量来自 `UI-IMPLEMENTATION-SPEC.md` §4 待办：`checkboxOutline` 20dp /
/// 圆角 `radius.checkbox` 6dp / 描边 2dp `color.outline.control`（`#9E9E9E`）。
///
/// 视觉全部靠 `ThemeData` / `CheckboxTheme` 对齐 —— 本组件内零硬编码色值，
/// checked 态沿用 Material 默认，要改只改 `AppTheme` 一处。
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({required this.value, super.key, this.onChanged});

  /// 勾选状态。由页面持有（筛选/批量操作状态，不是组件内部状态）。
  final bool value;

  /// 变更回调。null → 禁用（⚠️ 禁用态沿用 Material 默认）。
  final ValueChanged<bool>? onChanged;

  /// 见方边长。§4 待办「20dp」。
  static const double size = 20;

  /// 圆角。§2.4 `radius.checkbox` = 6dp。
  static const double radius = AppRadius.checkbox;

  /// 描边。§4 待办「描边 2dp」。
  static const double strokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final handler = onChanged;

    return Checkbox(
      value: value,
      // material_ui 的 Checkbox.onChanged 是 `ValueChanged<bool?>`（为 tristate
      // 准备）。本组件不开 tristate，回调值恒非 null，故在这里收窄回 `bool`。
      onChanged: handler == null ? null : (v) => handler(v ?? false),
      // Material 的 Checkbox 内边距固定 8dp，撑大 20dp 目标的命中区但不改变
      // 视觉边长 —— 稿上量的是**方框**边长不是命中区。
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      side: BorderSide(
        color: context.colors.outlineControl,
        width: strokeWidth,
      ),
    );
  }
}
