import 'package:mynote/core/ui/app_list_tile.dart';
import 'package:material_ui/material_ui.dart';

/// 设置行：标题（w600）+ 副说明 + 右侧开关（设置稿「强提醒」）。
///
/// 是 [AppListTile] 的一层薄封装 —— 行高 / 内边距 / 分割线全部复用 TASK-012
/// 的那一份实现，设置稿的 72dp（switch 行）与 56dp（chevron 行）差异自动成立。
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    required this.title,
    required this.value,
    super.key,
    this.subtitle,
    this.onChanged,
    this.dividerBefore = false,
  });

  /// 标题文案，由调用方传 l10n 结果。
  final String title;

  /// 副说明。稿中为「持续响铃且静音和勿扰状态下仍有效」。
  final String? subtitle;

  /// 开关当前值。由页面 / SettingsNotifier 持有。
  final bool value;

  /// 变更回调。null → 禁用（⚠️ 禁用态沿用 Material 默认）。
  final ValueChanged<bool>? onChanged;

  /// 行上方 1dp 分割线（同卡片内开关不是首行时传 true）。
  final bool dividerBefore;

  /// 标题字重。设置稿「强提醒」是 `text.rowTitleStrong`（w600）。
  static const FontWeight titleWeight = FontWeight.w600;

  /// 开关纵向占位。稿中轨道高 26dp；Material `Switch` 默认更高，用 shrinkWrap
  /// + 固定高度压缩，避免把 72dp 行撑破。
  static const double switchHeight = 26;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      titleWeight: titleWeight,
      dividerBefore: dividerBefore,
      // ⛔ 不给 onTap：稿中只画了开关本身，行按压态无稿。
      trailing: SizedBox(
        height: switchHeight,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
