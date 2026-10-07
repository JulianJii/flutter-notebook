import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// 文件夹管理稿的文件夹行：左选中勾 / 中名称 / 右计数或拖动图标。唯一调用方是文件夹管理
/// （TASK-050）。
///
/// 容器与中右区都复用 `core/ui` 的 T1 组件（`AppCard` + `AppListTile`）——
/// 全App 只有一种卡片外观、一种行骨架，本组件只负责「文件夹」这一行的业务语义：
/// 32dp 对齐槽位里**仅选中项**画琥珀勾。
///
/// ⛔ **参数是标量而非 `FolderWithCount`**：组件不认识 domain 实体，因此
/// 「未分类」不需要 null 特判、测试也不必构造实体（`TASK-049` 决策 A）。
/// 由页面（文件夹管理）负责从 `FolderWithCount` 取 `folder?.name`。
///
/// ⛔ **无重命名 / 删除入口**：文件夹管理稿无长按菜单、无多选、无行内编辑
/// （`UI-IMPLEMENTATION-SPEC.md` §4 P4段「本页无」）。顶栏也不画 trash ——
/// 本页只提供「新建」与拖拽排序。
class FolderRow extends StatelessWidget {
  const FolderRow({
    required this.name,
    super.key,
    this.count,
    this.trailing,
    this.isSelected = false,
    this.onTap,
  });

  /// 文件夹名（「全部」/ 用户文件夹名 / 「未分类」）。由调用方传 l10n 结果。
  final String name;

  /// 右侧计数（文件夹管理稿实测 155 / 1 / 154）。字阶 `text.value` + `secondary`。
  /// null → 不画计数（真实文件夹行把它换成了 [trailing] 的拖动图标）。
  final int? count;

  /// 右侧插槽。文件夹管理传拖动图标（`ReorderableDragStartListener`）。
  ///
  /// ⛔ 本组件不认识拖拽：「全部」/「未分类」是不可拖的系统行，传 null 即可，
  /// 组件不需要 `isDraggable` 之类的开关。
  final Widget? trailing;

  /// 选中态。文件夹管理稿中**仅**通过左侧琥珀勾区分，无底色高亮。
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
        // 未选中行按稿不加占位图标（选中 / 未选中因此左边界不齐，稿如此）。
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
        trailingValue: count == null ? null : '$count',
        trailing: trailing,
      ),
    );
  }
}
