import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_elevation.dart';
import 'package:material_ui/material_ui.dart';

/// 圆形浮动按钮。直径 64dp / 琥珀底 / 白色 `plus`，出现在 P1 / P2。
///
/// 度量来自 `UI-IMPLEMENTATION-SPEC.md` §4 P1：直径 64dp、边距 12dp、
/// 图标 24dp 白色 `plus`；底色 `color.accent`，阴影 `elevation.fab`
/// （偏移 ≈4dp / 模糊 ≈12dp / 透明度 ≈20%，D1/D2 画面中**唯一**带阴影的元素）。
///
/// ⚠️ **位置不由本组件负责**：右下 12dp 边距由调用方用
/// `Scaffold.floatingActionButton` + `FloatingActionButtonLocation.endFloat` 定位。
///
/// ⚠️ `onPressed == null` 时**整个组件不渲染** —— 稿中只有 enabled 态，
/// 不存在「禁用态 FAB」（**Q35**）。故不加 `isEnabled` 参数。
///
/// ⛔ 不做长按展开多动作（**Q6** 无稿）、不做 `Hero`、不做按压缩放动画（§2.6）。
class AppFab extends StatelessWidget {
  const AppFab({required this.onPressed, super.key, this.icon = Icons.add});

  /// 点击回调。null → 不渲染。
  final VoidCallback? onPressed;

  /// 图标字形。稿中固定为 `plus`；保留参数以便 Q6 答「展开多动作」时不必改签名。
  final IconData icon;

  /// 直径。§4 P1「直径 64dp」。
  static const double size = 64;

  /// 图形尺寸。§4 P1「图标 24dp」。
  static const double iconSize = 24;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: context.colors.accent,
        shape: const CircleBorder(),
        shadows: AppElevation.fab,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
