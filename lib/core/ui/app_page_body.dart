import 'package:mynote/core/ui/app_breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// 页面主体：**安全区 + 宽屏限宽居中**，窄屏零视觉变化。
///
/// 用法：直接当 `Scaffold.body`（二级页），或套在已有的 `SafeArea` 里
/// （笔记列表 / 待办 —— 它们在 `NotesShell` 内，顶部 inset 已被 Shell 消费）。
/// 嵌套 `SafeArea` 是幂等的：内层看到的 padding 已经是 0。
///
/// ⚠️ 为什么把 `SafeArea` 也收进来：如果只做限宽，每个页面都得写成
/// `SafeArea(child: AppPageBody(child: Column(...)))` —— 12 个二级页各改两处
/// 括号；合成一个组件后每页只改一个词，少 11 次「括号配错」的机会。
///
/// ⚠️ 为什么里面还要垫一层 `SizedBox(width: double.infinity)`：
/// 只用 `Center + ConstrainedBox` 时子节点拿到的是**松约束**，一个
/// `Column(mainAxisSize.max)` 会缩到最宽子节点的宽度、而不是撑满 840dp，
/// 窄屏上就等于把整页从「撑满」改成了「按内容收缩」—— 这是会动的。
/// 垫了 SizedBox 之后子节点拿到的是 `min(可用宽度, maxWidth)` 的**紧约束**，
/// 窄屏上与不限宽时逐像素一致。
class AppPageBody extends StatelessWidget {
  const AppPageBody({
    required this.child,
    super.key,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.bottom = true,
  });

  final Widget child;

  /// 内容最大宽度。默认二级页的 840dp；列表型页面可传更窄的值。
  final double maxWidth;

  /// 是否避让底部安全区。传给内部 [SafeArea]（默认 true，与 `SafeArea` 一致）。
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
