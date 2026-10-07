import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:material_ui/material_ui.dart';

/// 待办稿的待办卡：左复选框 + 右标题，此外什么都没有（待办稿明确「无日期、无优先级、
/// 无删除入口」）。
///
/// 容器直接复用 `AppCard` —— 全 App 只有一种卡片外观（`UI-IMPLEMENTATION-SPEC.md`
/// §2.4：12dp 圆角、`elevation.card` = 0），不在这里自绘 `Container`。
///
/// **参数收扁平标量而不是整个 `Todo`**（与 `NoteCard` 相反）：`NoteCard` 必须收
/// `Note`，因为摘要规则（空 → 占位文案）与日期格式是卡片自己的表现规则；而本页
/// 对 `Todo` 没有任何派生规则 —— 标题单行不截断、无摘要、无日期。为一条不需要
/// 加工的数据引入实体依赖没有收益。
class TodoCard extends StatelessWidget {
  const TodoCard({
    required this.title,
    required this.checked,
    super.key,
    this.reminderAt,
    this.onChanged,
    this.onTap,
  });

  /// 待办标题，单行省略。
  final String title;

  /// 勾选态，由页面持有（`todoOverridesProvider` 的乐观层是唯一真相源）。
  final bool checked;

  /// 提醒时刻。null = 没设提醒 → 不渲染提醒标记。
  final DateTime? reminderAt;

  /// 勾选变更。null → 复选框禁用。
  final ValueChanged<bool>? onChanged;

  /// 卡片本体点击 → 编辑弹窗。
  ///
  /// ⚠️ 待办稿 **无卡片按压态视觉**（沿用 Material 默认），`AppCard` 只画涟漪。⛔ 不加
  /// `onLongPress`：长按与「点卡片」语义冲突，且 `AppCard` 没有该参数，要加就得动
  /// `core/ui`。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.rowPadH,
        vertical: _verticalPad,
      ),
      child: Row(
        children: <Widget>[
          // `AppCheckbox.size`（20dp）是该组件自己声明的「见方边长」（§4 待办），
          // 但 Material `Checkbox` 内部固定 8dp 内边距，实际占位 32dp —— 直接用
          // 会把卡片撑到 72dp，比待办稿的 60dp 高出整整一个内边距。这里把布局盒
          // 收回 20dp，让排版由真实内容（16sp × 1.4 = 22.4dp 行高）决定。
          // ⚠️ 代价：可点区从 32×32 降到 20×20。M3 的 48dp 目标本项目已经因为
          // 待办稿明确要求 20dp 视觉而放弃（TASK-013 选了 `shrinkWrap`），此处不再
          // 进一步压缩到不可用的程度以外的其他数值。
          SizedBox.square(
            dimension: AppCheckbox.size,
            child: AppCheckbox(value: checked, onChanged: onChanged),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: context.textStyles.rowTitle.copyWith(
                // 完成态：灰字 + 删除线。只改本组件，不动 Screen。
                color: checked
                    ? context.colors.textTertiary
                    : context.colors.textPrimary,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 提醒标记：让人一眼看出哪条设了提醒。⛔ 不单独给它一个点击区 ——
          // 整张卡点开就是详情小窗，再开一个入口等于同一件事两个地方做。
          if (reminderAt != null) ...[
            const SizedBox(width: AppSpacing.sm),
            AppIcon(
              icon: AppIcons.alarm,
              size: AppSpacing.rowIconSize,
              color: checked
                  ? context.colors.textTertiary
                  : context.colors.accent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppUtils.formatLocaleDateTime(context, reminderAt!),
              style: context.textStyles.meta.copyWith(
                color: checked
                    ? context.colors.textTertiary
                    : context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 卡片上下内边距。待办稿实测卡高 ≈60dp、内含 20dp 复选框 → `(60 − 20) / 2 = 20dp`。
  ///
  /// ⚠️ 写成 `cardPad`(12) + `sm`(8) 的具名 token 组合而不是单值 20：
  /// `AppSpacing` 没有 20 这一档，为一个组件新造 token 是纯仪式（且 20 会被待办稿的
  /// 复核结论推翻，届时改这一行比改 token + 它的 dartdoc 便宜）。
  static const double _verticalPad = AppSpacing.cardPad + AppSpacing.sm;
}
