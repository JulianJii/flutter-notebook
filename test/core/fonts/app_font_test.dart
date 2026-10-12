import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/fonts/app_font.dart';
import 'package:mynote/core/ui/app_font_picker_sheet.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';

void main() {
  group('字体目录', () {
    test('id 唯一（弹层下标与持久化都按 id 认字）', () {
      final ids = appFonts.map((f) => f.id).toSet();
      expect(ids, hasLength(appFonts.length));
    });

    test('族名唯一（同一族名两行会让「换了个字体」看起来没反应）', () {
      final families = appFonts.map((f) => f.fontFamily).toSet();
      expect(families, hasLength(appFonts.length));
    });

    test('每条都有名字 / 下载地址 / 合法体积', () {
      for (final font in appFonts) {
        expect(font.label, isNotEmpty, reason: font.id);
        expect(font.downloadUrl, startsWith('https://'), reason: font.id);
        expect(font.sizeBytes, greaterThan(0), reason: font.id);
      }
    });

    test('appFontById：null / 未知 id -> null（= 系统默认）', () {
      expect(appFontById(null), isNull);
      expect(appFontById('nope'), isNull);
      expect(appFontById(appFonts.first.id), same(appFonts.first));
    });

    test('体积文案带单位', () {
      expect(
        const AppFont(
          id: 'x',
          label: 'x',
          fontFamily: 'x',
          downloadUrl: 'https://example.com/x.ttf',
          sizeBytes: 1572864,
        ).sizeLabel,
        '1.5 MB',
      );
    });
  });

  group('弹层下标约定', () {
    test('0 = 系统默认，1..n 与 appFonts 一一对应，且可往返', () {
      expect(appFontIdAt(0), isNull);
      expect(appFontIndexOf(null), 0);
      expect(appFontIndexOf('nope'), 0, reason: '未知 id 落回系统默认');

      for (var i = 0; i < appFonts.length; i++) {
        final id = appFontIdAt(i + 1);
        expect(id, appFonts[i].id);
        expect(appFontIndexOf(id), i + 1);
      }
    });

    test('未知 id 显示「系统默认」，已知 id 显示目录里的名字', () {
      final l10n = lookupAppLocalizations(const Locale('zh'));
      expect(appFontLabel(l10n, null), l10n.fontFamilySystem);
      expect(appFontLabel(l10n, 'nope'), l10n.fontFamilySystem);
      expect(appFontLabel(l10n, appFonts.first.id), appFonts.first.label);
    });
  });
}
