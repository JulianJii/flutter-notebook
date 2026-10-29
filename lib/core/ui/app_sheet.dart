import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/ui/app_breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// 全 App 底部弹层的统一入口。
///
/// 存在理由只有一条：**大屏限宽**。`showModalBottomSheet` 默认铺满窗口宽度，
/// 在 1280dp 的桌面窗口上会把「选个文件夹」摊成一整条横贯屏幕的浮层。
/// 收口到这一个函数后，各处调用点不必各写一遍 `constraints`，将来调宽度
/// 也只改 [AppBreakpoints.sheetMaxWidth] 一处。
///
/// 窄屏（< [AppBreakpoints.rail]）**不传 constraints / shape**：保持 Material
/// 原样，手机上的弹层视觉逐像素不变。
///
/// ⚠️ 参数是 `showModalBottomSheet` 的透传子集，只放本项目真正用到的几个：
/// 多了就是替 Material 抄一遍签名。
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = false,
}) {
  // ⚠️ 用 [currentWindowWidth] 而不是 `context.usesNavRail`：本函数是在
  // `onTap` 之后才调用的，那时 `MediaQuery.sizeOf(context)` 会在 build 之外
  // 建立继承依赖，让调用方（常常是整页）被动订阅窗口尺寸。
  final isWide = currentWindowWidth() >= AppBreakpoints.rail;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor,
    elevation: elevation,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    // 宽屏：顶部圆角 + 限宽。调用方自己传了 `shape` 就尊重它
    //（背景选择弹层是无底色的，加圆角没有意义）。
    shape:
        shape ??
        (isWide
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
              )
            : null),
    constraints: isWide
        ? const BoxConstraints(maxWidth: AppBreakpoints.sheetMaxWidth)
        : null,
    builder: builder,
  );
}
