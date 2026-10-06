import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// 设计稿 15 个图标语义的集中映射。取值来自 `UI-IMPLEMENTATION-SPEC.md` §2.5。
///
/// ⚠️ 设计稿是 JPEG 截图，无法提取矢量图标资源；这里用 Material Icons 的
/// outlined / rounded 变体近似。M3 的 outlined 图标本身就是 2dp 描边 + 圆端点，
/// 与 §2.5 尾注的度量一致。拿到设计提供的图标资源后，只改这一个文件。
///
/// ⚠️ 3 处已知字形偏差（见 `PROJECT-STATUS.md`）：`settings`（稿为六边形内含圆，
/// 实现为齿轮）、`navNotes` / `navTodo`（稿的「圆角方块外框」实为选中态背景，
/// 已由 `AppBottomNav` 的 28dp 深色圆角方块实现）。
abstract final class AppIcons {
  const AppIcons._();

  // ---- 顶栏（D1~D5）----
  static const IconData folder = Icons.folder_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData back = Icons.arrow_back;
  static const IconData share = Icons.ios_share_outlined;
  static const IconData palette = Icons.palette_outlined;
  static const IconData overflow = Icons.more_vert;

  // ---- 页面内（D1/D2/D4）----
  static const IconData plus = Icons.add;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData stepper = Icons.swap_vert;
  static const IconData trash = Icons.delete_outline;
  static const IconData check = Icons.check;
  static const IconData circlePlusOutline = Icons.add_circle_outline;
  static const IconData checkboxOutline = Icons.check_box_outlined;

  /// P4 拖动排序把手。**不在设计稿的 15 个语义里**（稿无排序入口），
  /// 取平台惯例的 `drag_handle`。
  static const IconData drag = Icons.drag_handle;

  // ---- 底部导航（D1/D2）----
  static const IconData navNotes = Icons.list_rounded;
  static const IconData navTodo = Icons.check_rounded;
}

/// 24dp 线性图标。统一尺寸、描边与颜色语义。
///
/// 度量规则来自 `UI-IMPLEMENTATION-SPEC.md` §2.5 尾注：
/// 统一 24dp 线性图标、2dp 描边、圆角端点。
///
/// ⚠️ 描边宽度不可控：`IconData` 不携带 strokeWidth，2dp 描边靠选用 M3 的
/// outlined 变体实现（[AppIcons] 全部映射都指向 outlined / rounded）。
/// 若设计要求非 2dp 的笔画，只能改用自定义 `CustomPainter` —— **在拿到设计
/// 提供的图标资源之前不做**。
class AppIcon extends StatelessWidget {
  const AppIcon({
    required this.icon,
    super.key,
    this.size = defaultSize,
    this.color,
  });

  /// 顶部栏图标的视觉尺寸。§2.5「顶部栏图标视觉尺寸 24dp」。
  static const double defaultSize = 24;

  /// 图标字形。取值来自 [AppIcons]。
  final IconData icon;

  /// 视觉尺寸（dp）。不填则 [defaultSize]。
  ///
  /// ⚠️ 这是**图形**尺寸。触控区是 [AppIconButton] 的事（≥48dp），
  /// 不要在组件里用 size 撑大触控区。
  final double size;

  /// 图标颜色。null → `colors.outlineControl`。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? context.colors.outlineControl,
    );
  }
}
