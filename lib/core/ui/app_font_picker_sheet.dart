import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../fonts/app_font.dart';
import '../fonts/font_providers.dart';
import '../theme/tokens/app_colors.dart';
import '../utils/app_utils.dart';
import 'app_icon.dart';
import 'app_list_tile.dart';
import 'app_sheet.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';

/// 字体选择弹层的下标约定：`0` = 系统默认（不加任何字体），`1..n` = `appFonts[i-1]`。
const int _kSystemOption = 0;

/// 弹层下标 → 字体 id（`null` = 系统默认）。与 [_kSystemOption] 成对使用。
String? appFontIdAt(int index) =>
    index <= _kSystemOption ? null : appFonts[index - 1].id;

/// 字体 id → 弹层下标。
int appFontIndexOf(String? id) {
  final font = appFontById(id);
  return font == null ? _kSystemOption : appFonts.indexOf(font) + 1;
}

/// 字体 id → 上屏的名字。`null` / 不认识的 id 都显示「系统默认」。
///
/// ⚠️ 字体名本身来自目录（专有名词，不进 ARB），只有「系统默认」是文案。
String appFontLabel(AppLocalizations l10n, String? id) =>
    appFontById(id)?.label ?? l10n.fontFamilySystem;

/// 字体选择弹层（只服务设置页的 UI 字体）。
///
/// 返回值照抄背景弹层（`BackgroundPickerSheet`）的约定：`0` = 系统默认、
/// `null` = 取消 —— 因此调用方**不能**用 `picked != null` 判断「用户选没选」。
///
/// ⛔ **下载只发生在点中某一行的那一刻**：行内转圈 → 注册成功才 `pop`。
/// 失败弹提示且**不改变当前选择**，所以上层拿不到「选了一个装不上的字体」这种状态，
/// 也⛔不需要在别处再写一次失败回滚。
///
/// ⛔ **不用各字体自身渲染字体名**：那会让「打开弹层」= 下载全部字体（合计约 70 MB）。
/// 名称一律用当前 UI 字体渲染，只用副标题标注体积给用户一个耗时预期。
Future<int?> showAppFontPickerSheet(
  BuildContext context, {
  required int selected,
}) {
  return showAppBottomSheet<int>(
    context: context,
    builder: (_) => AppFontPickerSheet(selected: selected),
  );
}

/// 行尾图标尺寸与行尾的转圈同宽，切换时行不会左右跳动。
const double _kTrailingSize = 20;

/// [showAppFontPickerSheet] 的弹层本体。
///
/// ⚠️ `ConsumerStatefulWidget` 而非无状态：下载在途是**本弹层的局部状态**
/// （转圈画在哪一行、期间禁点），不属于任何 feature 的持久状态。
class AppFontPickerSheet extends ConsumerStatefulWidget {
  const AppFontPickerSheet({required this.selected, super.key});

  /// 当前已选中的下标（`0` = 系统默认）。
  final int selected;

  @override
  ConsumerState<AppFontPickerSheet> createState() => _AppFontPickerSheetState();
}

class _AppFontPickerSheetState extends ConsumerState<AppFontPickerSheet> {
  /// 正在下载/注册的行。非 null 时其余行一律不可点（避免并发下多份字体）。
  int? _loading;

  Future<void> _select(int index) async {
    // 系统默认不必下载；重选当前项也不必（重复点同一行不该产生一次 IO）。
    if (index == _kSystemOption || index == widget.selected) {
      Navigator.of(context).pop(index);
      return;
    }

    final font = appFonts[index - 1];
    setState(() => _loading = index);
    final loaded = await ref.read(fontLoaderServiceProvider).ensureLoaded(font);
    if (!mounted) return;
    if (loaded) {
      Navigator.of(context).pop(index);
      return;
    }

    // 失败：留在弹层里、选项保持不变，用户可以直接再点一次重试。
    setState(() => _loading = null);
    AppUtils.showSnackBar(
      context,
      message: AppLocalizations.of(context).fontLoadFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ⚠️ **必须可滚**：字体有 7 行且每行带体积副标题，在竖屏手机上一定超过
    // `showModalBottomSheet` 的默认高度上限（屏高的 9/16），不可滚就是一片溢出。
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var index = 0; index <= appFonts.length; index++)
              AppListTile(
                key: Key('font_option_$index'),
                title: index == _kSystemOption
                    ? l10n.fontFamilySystem
                    : appFonts[index - 1].label,
                subtitle: index == _kSystemOption
                    ? null
                    : appFonts[index - 1].sizeLabel,
                titleWeight: index == widget.selected ? FontWeight.w600 : null,
                trailing: _trailing(context, index),
                onTap: _loading == null ? () => _select(index) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget? _trailing(BuildContext context, int index) {
    if (_loading == index) {
      return const SizedBox(
        width: _kTrailingSize,
        height: _kTrailingSize,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (index != widget.selected) return null;
    return AppIcon(
      icon: AppIcons.check,
      size: _kTrailingSize,
      color: context.colors.accent,
    );
  }
}
