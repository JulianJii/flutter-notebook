import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 文件夹管理稿列表末尾的「新建文件夹」行动作。唯一调用方是文件夹管理（TASK-050）。
///
/// 与 [FolderRow] 同为 `AppCard` 白卡，但布局是**垂直居中**的一列：琥珀色 ⊕ 在上、
/// 文案在下，实测略高 ≈72dp。无描边、无箭头、无计数。
///
/// ⛔ **只把 [onTap] 往上抛**：新建文件夹的输入弹窗无设计稿，由文件夹管理决定，
/// 本组件不建 `AppDialog` / `AppBottomSheet`。
class CreateFolderRow extends StatelessWidget {
  const CreateFolderRow({super.key, this.onTap});

  /// 点击回调。null → 不可点（不包 `InkWell`，无水波纹）。
  final VoidCallback? onTap;

  /// 图标与文案的间距。6dp（文件夹管理稿实测）。测试按它断言垂直排布。
  static const double iconGap = AppSpacing.actionRowIconGap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      // 上下 12dp + 内容48.4（20 图标 + 6 间距 + 22.4 文案）≈ 72dp，
      // 横向留0 由父级ListView 的12dp 页边距负责。
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(
            icon: AppIcons.circlePlusOutline,
            color: colors.accent,
            size: AppSpacing.rowIconSize,
          ),
          const SizedBox(height: iconGap),
          Text(
            AppLocalizations.of(context).createFolder,
            style: context.textStyles.rowTitle.copyWith(
              color: colors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
