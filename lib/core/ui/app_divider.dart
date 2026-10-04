import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_elevation.dart';
import 'package:material_ui/material_ui.dart';

/// 1dp 可缩进分割线。用于设置卡片内的行间分隔（D5）。
///
/// 度量来自 `UI-IMPLEMENTATION-SPEC.md` §2.4（`stroke.divider` = 1dp）
/// + §4 P5 结构规则（「分割线左端与行文字左对齐（缩进 28dp），右端到卡片内边距」）。
///
/// 默认值刻意是「贴边」，28dp/16dp 是 P5 的局部值，由调用方传
/// `AppSpacing.sectionHeaderIndent` / `AppSpacing.rowPadH`。
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
    this.thickness = AppStroke.divider,
  });

  /// 左缩进。P5 传 `AppSpacing.sectionHeaderIndent`（28dp），使分割线左端
  /// 与行文字左边界对齐。
  final double indent;

  /// 右缩进。P5 传 `AppSpacing.rowPadH`（16dp），使分割线右端到卡片内边距。
  final double endIndent;

  /// 线色。null → `colors.divider`（`#E5E5E5`，§2.1）。
  final Color? color;

  /// 线宽。默认 1dp（`AppStroke.divider`）。
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: indent,
      endIndent: endIndent,
      thickness: thickness,
      color: color ?? context.colors.divider,
    );
  }
}
