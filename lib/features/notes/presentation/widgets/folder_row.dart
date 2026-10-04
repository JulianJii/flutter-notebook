import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// D4 的文件夹行：左选中勾 / 中名称 / 右计数。唯一调用方是 P4（TASK-050）。
///
/// 容器与中右区都复用 `core/ui` 的 T1 组件（`AppCard` + `AppListTile`）——
/// 全App 只有一种卡片外观、一种行骨架，本组件只负责「文件夹」这一行的业务语义：
/// 32dp 对齐槽位里**仅选中项**画琥珀勾。
///
/// ⛔ **参数是标量而非 `FolderWithCount`**：组件不认识 domain 实体，因此
/// 「未分类」不需要 null 特判、测试也不必构造实体（`TASK-049` 决策 A）。
/// 由页面（P4）负责从 `FolderWithCount` 取 `folder?.name`。
///
/// ⛔ **无重命名 / 删除入口**：D4 无长按菜单、无多选、无行内编辑
/// （`UI-IMPLEMENTATION-SPEC.md` §4 P4段「本页无」）。
// TODO(Q11): D4 无重命名 / 删除入口（顶栏 trash 语义未知），待设计补稿。
/// `RenameFolderUseCase` / `DeleteFolderUseCase` 的 UI 待Q11 / Q12 回答后接线。
class FolderRow extends StatelessWidget {
  const FolderRow({
    required this.name,
    required this.count,
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  /// 文件夹名（「全部」/ 用户文件夹名 / 「未分类」）。由调用方传 l10n 结果。
  final String name;

  /// 右侧计数（D4 实测 155 / 1 / 154）。字阶 `text.value` + `secondary`。
  final int count;

  /// 选中态。D4 中**仅**通过左侧琥珀勾区分，无底色高亮。
  // TODO(Q25c): 选中行是否需要底色高亮无稿 —— D4 中「全部」纯白、其余行极浅灰，
  //             无法判定是选中态还是 JPEG 压缩噪声。当前只用琥珀勾区分。
  final bool isSelected;

  /// 点击回调。null → 不可点（不包 `InkWell`，无水波纹）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // 行内边距由 [AppListTile] 自己给（上下左右都是 [AppSpacing.rowPadH]），
      // 这里必须清零，否则 16dp 变32dp、卡高从54dp 变 86dp。
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: AppListTile(
        // TODO(Q25b): D4 未选中行**没有** leading 图标，导致「全部」行的名称
        //             比其余行右移 24dp、三行名称互不对齐。当前按设计稿原样
        //             实现（不加占位图标），待设计确认是否补占位。
        leading: isSelected
            ? SizedBox(
                width: AppSpacing.rowLeadingSlot,
                child: AppIcon(
                  icon: AppIcons.check,
                  color: context.colors.accent,
                  size: AppSpacing.rowIconSize,
                ),
              )
            : null,
        title: name,
        trailingValue: '$count',
      ),
    );
  }
}
