import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_elevation.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// 页面顶部栏容器。统一高度、安全区与图标组间距。
///
/// 3 种形态由参数组合表达（`DEVELOPMENT-GUIDELINES.md` §8：不用布尔开关）：
/// - A 右对齐图标组：`AppTopBar(actions: [...])`
/// - B 居中标题 + 右侧图标：`AppTopBar(leading: ..., centerTitle: ..., actions: [...])`  ← D4
/// - C 仅返回：`AppTopBar(leading: ...)`  ← D5
///
/// 取值来自 `UI-IMPLEMENTATION-SPEC.md` §0（高 56dp）、§4 P1~P5（各页 AppBar）。
// TODO(Q28): SafeArea 按「非 edge-to-edge」实现，待设计确认
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.leading,
    this.centerTitle,
    this.actions = const <Widget>[],
    this.showDivider = true,
  });

  /// 左侧控件，通常是 `AppIconButton`（TASK-010）。null → 左侧留空（形态 A）。
  final Widget? leading;

  /// 居中标题，通常是 `Text`。null → 不渲染标题（形态 A / C）。
  final Widget? centerTitle;

  /// 右侧图标组，按给定顺序排列（D1: folder → settings；D3: share → palette → overflow）。
  final List<Widget> actions;

  /// 顶栏底边是否画 1dp 分隔线。
  ///
  /// ⚠️ 顶栏分隔线在 5 张设计稿中**均无明确依据**（§2.4 的 `elevation.nav` 1dp 是
  /// 底部导航的）。默认 true 是按 `COMPONENT-INVENTORY.md` §2 #1 的签名；各页面在
  /// Phase 4/5/7 接线时应按实际稿传值。取值 1dp `AppColors.divider`。
  final bool showDivider;

  /// 顶栏内容区高度，不含状态栏安全区。
  static const double height = 56;

  /// 图标按钮之间的间距。`UI-IMPLEMENTATION-SPEC.md` §4 P1 `[推导: 8dp]`。
  static const double _actionGap = AppSpacing.chipGap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.divider,
                  width: AppStroke.divider,
                ),
              )
            : null,
      ),
      // ⚠️ 幂等：Tab 内页面已被 `NotesShell` 的 SafeArea 消费掉顶部 inset，这里加 0；
      // push 到 root 的页面（P3/P4/P5）需要自己避让状态栏。
      child: SafeArea(
        top: true,
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
            child: Row(
              children: <Widget>[
                ?leading,
                // 标题占满剩余空间并居中；无标题时留空。
                Expanded(
                  child: centerTitle == null
                      ? const SizedBox.shrink()
                      : Center(child: centerTitle),
                ),
                for (var i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: _actionGap),
                  actions[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
