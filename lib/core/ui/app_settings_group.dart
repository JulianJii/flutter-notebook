import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_card.dart';
import 'package:mynote/core/ui/app_section_header.dart';
import 'package:material_ui/material_ui.dart';

/// 一个设置分组 = **卡外标题 + 一张白卡**。设置 / 主题页 / 数据与同步页 /
/// WebDAV 配置页共用。
///
/// 此前这 20 行在四个页面里各抄了一份（`_Group`），新增第五个设置页时会变成
/// 第五份 —— 抽出来比继续抄便宜。
///
/// ⛔ **标题必须在卡外**：它的 28dp 左缩进是页面**绝对**缩进（= 12 页面边距 +
/// 16 行内边距），被卡片的 12dp 包裹后会变成 40dp。
/// ⛔ **卡内不加内边距**：行的左右 16dp 由 `AppListTile` 提供，加了会出现
/// 12 + 16 = 28dp 的双重缩进。
class AppSettingsGroup extends StatelessWidget {
  const AppSettingsGroup({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(text: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
