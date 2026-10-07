import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppColors 数值与 UI-IMPLEMENTATION-SPEC §2.1 一致', () {
    test('13 个语义色', () {
      const c = AppColors.light();
      expect(c.bg, const Color(0xFFF2F2F2));
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(c.surfaceInverse, const Color(0xFF1A1A1A));
      expect(c.textPrimary, const Color(0xFF1A1A1A));
      expect(c.textSecondary, const Color(0xFF999999));
      expect(c.textTertiary, const Color(0xFFB3B3B3));
      expect(c.textPlaceholder, const Color(0xFFC0C0C0));
      expect(c.textSectionHeader, const Color(0xFFA0A0A0));
      expect(c.accent, const Color(0xFFF0A020));
      expect(c.divider, const Color(0xFFE5E5E5));
      expect(c.outlineControl, const Color(0xFF9E9E9E));
      expect(c.switchOff, const Color(0xFFBDBDBD));
      expect(c.chipSelectedBg, const Color(0xFFEFEFEF));
    });

    test('5 个灰阶互不相同，且按亮度排序严格递增（没被压成 2~3 档）', () {
      const c = AppColors.light();
      // ⚠️ 不能按声明顺序断言：`textSectionHeader` #A0A0A0 比
      // `textSecondary` #999999 **浅**，规格 §2.1 原表就是这样（实测设置稿亦然）。
      // 真正的性质是「5 个互不相同的灰阶」，排序后才谈得上递进。
      final greys = <int>[
        c.textPrimary.toARGB32(),
        c.textSecondary.toARGB32(),
        c.textSectionHeader.toARGB32(),
        c.textTertiary.toARGB32(),
        c.textPlaceholder.toARGB32(),
      ]..sort();

      expect(greys, hasLength(5), reason: '5 个灰阶应各自独立');
      expect(greys.toSet(), hasLength(5), reason: '存在被取色误差压成同值的灰阶');
      for (var i = 1; i < greys.length; i++) {
        expect(
          greys[i] - greys[i - 1],
          greaterThanOrEqualTo(8),
          reason: '第 $i 档与前一档只差 ${greys[i] - greys[i - 1]}，肉眼不可辨',
        );
      }
    });

    test('chip 选中底与卡片面可区分', () {
      const c = AppColors.light();
      expect(c.chipSelectedBg, isNot(c.surface));
    });

    test('copyWith 只改指定字段，其余保留', () {
      const c = AppColors.light();
      final updated = c.copyWith(accent: const Color(0xFF112233));
      expect(updated.accent, const Color(0xFF112233));
      expect(updated.bg, c.bg);
      expect(updated.textPrimary, c.textPrimary);
    });

    test('lerp 在 t=0 / t=1 两端等于各自实例', () {
      const a = AppColors.light();
      const b = AppColors.dark();
      expect(a.lerp(b, 0).accent, a.accent);
      expect(a.lerp(b, 1).accent, b.accent);
    });
  });

  group('AppTextStyles 数值（size 已整体下收一档，weight/height 不变）', () {
    test('13 个字阶的 size / weight / height', () {
      const t = AppTextStyles.light();

      void expectStyle(
        TextStyle s,
        double size,
        FontWeight weight,
        double height,
      ) {
        expect(s.fontSize, size, reason: 'fontSize');
        expect(s.fontWeight, weight, reason: 'fontWeight');
        expect(s.height, height, reason: 'height');
      }

      expectStyle(t.displayTitle, 20, FontWeight.w700, 1.2);
      expectStyle(t.detailTitle, 19, FontWeight.w500, 1.3);
      expectStyle(t.cardTitle, 15, FontWeight.w600, 1.4);
      expectStyle(t.rowTitle, 15, FontWeight.w400, 1.4);
      expectStyle(t.rowTitleStrong, 15, FontWeight.w600, 1.4);
      expectStyle(t.body, 15, FontWeight.w400, 1.7); // 13 级里唯一的 1.7
      expectStyle(t.snippet, 13, FontWeight.w400, 1.5);
      expectStyle(t.value, 13, FontWeight.w400, 1.4);
      expectStyle(t.subtitle, 12, FontWeight.w400, 1.4);
      expectStyle(t.chip, 13, FontWeight.w500, 1.0);
      expectStyle(t.meta, 11, FontWeight.w400, 1.4);
      expectStyle(t.navLabel, 11, FontWeight.w500, 1.0);
      expectStyle(t.topBarTitle, 16, FontWeight.w600, 1.2);
    });

    test('任何字阶都不设 color 与 fontFamily', () {
      const t = AppTextStyles.light();
      for (final style in <TextStyle>[
        t.displayTitle,
        t.detailTitle,
        t.cardTitle,
        t.rowTitle,
        t.rowTitleStrong,
        t.body,
        t.snippet,
        t.value,
        t.subtitle,
        t.chip,
        t.meta,
        t.navLabel,
        t.topBarTitle,
      ]) {
        expect(style.color, isNull);
        expect(style.fontFamily, isNull);
      }
    });

    test('copyWith 只改指定字段，其余保留', () {
      const t = AppTextStyles.light();
      final updated = t.copyWith(body: const TextStyle(fontSize: 99));
      expect(updated.body.fontSize, 99);
      expect(updated.cardTitle, t.cardTitle);
    });
  });

  group('AppSpacing / AppRadius / AppElevation / AppStroke', () {
    test('9 个间距取值与规格一致', () {
      expect(AppSpacing.pageH, 12);
      expect(AppSpacing.gridGutter, 12);
      expect(AppSpacing.gridRow, 12);
      expect(AppSpacing.cardPad, 12);
      expect(AppSpacing.rowPadH, 16);
      expect(AppSpacing.sectionHeaderIndent, 28);
      expect(AppSpacing.topBar, 16);
      expect(AppSpacing.chipGap, 8);
      expect(AppSpacing.bottomSafe, 34);
    });

    test('3 个圆角取值与规格一致', () {
      expect(AppRadius.card, 12);
      expect(AppRadius.navIcon, 8);
      expect(AppRadius.checkbox, 6);
    });

    test('3 个阴影 / 2 个描边取值与规格一致', () {
      expect(AppElevation.card, 0);
      expect(AppElevation.nav, 0);
      expect(AppElevation.fab, hasLength(1));
      expect(AppElevation.fab.first.offset, const Offset(0, 4));
      expect(AppElevation.fab.first.blurRadius, 12);
      expect(AppElevation.fab.first.color.toARGB32(), 0x33000000);
      expect(AppStroke.icon, 2);
      expect(AppStroke.divider, 1);
    });
  });
}
