import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// 白色圆角容器。全 App **唯一**的卡片外观。
///
/// 取值来自 `UI-IMPLEMENTATION-SPEC.md` §2.1（`surface`）+ §2.4（`radius.card`
/// 12dp、`elevation.card` 0）+ §4 P1/P2/P4/P5（各卡片内边距）。
/// 底色 / 圆角 / 阴影**不在本文件定义**，而是继承 `ThemeData.cardTheme`
/// （见 `core/theme/app_theme.dart`）—— 那里是唯一来源。
///
/// ⚠️ 本组件**不认识业务**：笔记卡 / 待办卡 / 文件夹行 / 设置分组卡都长这样，
/// 但「笔记卡」是 `features/notes/` 的 `NoteCard`（T2）的事。
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = defaultPadding,
    this.onTap,
  });

  /// 笔记卡内边距。§2.3 `space.card.pad` = 12dp。
  /// 待办卡 / 文件夹行 / 设置行是左右 16dp，调用方传
  /// `EdgeInsets.symmetric(horizontal: AppSpacing.rowPadH, ...)`。
  static const EdgeInsets defaultPadding = EdgeInsets.all(AppSpacing.cardPad);

  final Widget child;

  /// 内边距。默认 12dp（笔记卡）。
  final EdgeInsets padding;

  /// 点击回调。null → 静态卡片（不可点）。
  ///
  /// ⚠️ 卡片「是否可点」在 5 张设计稿中**均无依据**（`COMPONENT-INVENTORY.md`
  /// §2 #4）。D1 笔记卡与 D2 待办卡看起来可点（但 §7 交互态表「Pressed | ❌
  /// 无稿」），D4 文件夹行可点（选中态有稿）。保留参数、默认静态，由各页面
  /// Task 决定。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Card(
      // M3 的 Card 默认 margin all(4) 与 surfaceTint 会破坏「白卡浮在灰底上」的
      // 分层结构（§4 P1），必须清零。
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      // 让 InkWell 的涟漪按 12dp 圆角裁剪。
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
