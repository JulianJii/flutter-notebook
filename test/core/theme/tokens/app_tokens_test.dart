import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// ⚠️ 这里**只**断言 token 之间的关系与不变量（灰阶是否还分得开、字阶是否漏设
/// 颜色、`copyWith` 是否只动一个字段），不逐个转抄字面量 —— 把 `app_colors.dart`
/// 抄成 13 行 `expect(c.bg, const Color(0xFFF2F2F2))` 只会得到一个永远跟着
/// 源码一起改的镜子，改错了也一起绿。设计稿的绝对数值由 golden 基线锁。
void main() {
  group('AppColors', () {
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

    test('深色不是浅色的复制：底色与文字色都换了', () {
      expect(AppColors.dark().bg, isNot(AppColors.light().bg));
      expect(AppColors.dark().surface, isNot(AppColors.light().surface));
      expect(
        AppColors.dark().textPrimary,
        isNot(AppColors.light().textPrimary),
      );
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

  group('AppTextStyles', () {
    /// 13 个字阶全量遍历 —— 少写一个字阶名就会在这里被抓住。
    List<TextStyle> all(AppTextStyles t) => <TextStyle>[
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
    ];

    test('任何字阶都不设 color 与 fontFamily', () {
      final t = AppTextStyles.light();
      expect(all(t), hasLength(13));
      for (final style in all(t)) {
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
}
