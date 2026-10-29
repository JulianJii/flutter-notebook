import 'package:material_ui/material_ui.dart';

/// 响应式断点与宽屏度量。**全 App 唯一来源**。
///
/// 项目的设计稿只有手机竖屏一档，宽屏形态是后补的；断点值集中在这里，
/// 页面里禁止再写 `600` / `1024` 这类字面量（否则两处各调一次就漂了）。
///
/// 三档布局由两个断点切出，连续缩放时**单向收放**：
/// 三栏工作台（≥1024）→ 侧栏 + 单栏列表（≥600）→ 手机布局（<600）。
abstract final class AppBreakpoints {
  /// 达到即用左侧导航栏，否则底部导航。
  ///
  /// 600dp 是 Material 的「small → medium」分界：手机上竖屏宽度普遍 < 480，
  /// 横屏手机约 640–900（此时底栏两项会被拉开成两端距离半个屏幕，必须换掉）。
  static const double rail = 600;

  /// 达到即启用笔记「列表 + 编辑」双栏。
  ///
  /// 1024dp 之下左栏（380）+ 编辑区（≥600）会挤到正文一行不足 40 个字符，
  /// 不如退回单栏整页编辑。
  static const double twoPane = 1024;

  /// 二级页（设置 / 主题 / 文件夹管理 / 数据与同步 …）的内容最大宽度。
  ///
  /// 表单与分组卡超过 840dp 后，标题与右侧值之间会出现大片空白，眼睛要横跨
  /// 整屏才能读完一行。
  static const double contentMaxWidth = 840;

  /// 底部弹层在大屏上的最大宽度。
  static const double sheetMaxWidth = 640;

  /// 对话框最大宽度。与弹层分开：确认框只有一两行文案，640 会显得空。
  static const double dialogMaxWidth = 420;

  /// 左侧导航栏宽度。图标 24 + 文字 11sp 竖排，88dp 足够且不抢内容。
  static const double railWidth = 88;
}

/// 断点的 `BuildContext` 入口。
///
/// ⚠️ 内部只用 [MediaQuery.sizeOf]：它只订阅 `MediaQuery.size` 这一个 aspect，
/// 窗口尺寸不变时（滚动、键盘弹出改变 `viewInsets`）不会触发重建 —— 这是
/// 每个列表项都要读断点时唯一可接受的开销。⛔ 不要换成 `MediaQuery.of(context).size`。
extension AppBreakpointsContext on BuildContext {
  /// 当前窗口是否足够宽、应使用左侧导航栏。
  bool get usesNavRail => MediaQuery.sizeOf(this).width >= AppBreakpoints.rail;

  /// 当前窗口是否足够宽、应启用笔记双栏。
  bool get isTwoPane => MediaQuery.sizeOf(this).width >= AppBreakpoints.twoPane;
}

/// 当前窗口的逻辑宽度，**不建立任何依赖**。
///
/// 给 `BuildContext` 之外的地方用（快捷键回调、`showMenu` 前的判断等）：
/// 那里既拿不到 build 期的 `MediaQuery`，也不该为了读一次尺寸把整棵子树
/// 绑到窗口尺寸上。
double currentWindowWidth() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return view.physicalSize.width / view.devicePixelRatio;
}
