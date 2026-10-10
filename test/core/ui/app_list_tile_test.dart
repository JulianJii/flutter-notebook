import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/app_divider.dart';
import 'package:mynote/core/ui/app_list_tile.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

const _trailingKey = Key('trailing');

void main() {
  group('6 种形态', () {
    const variants = <String, Widget>{
      'titleOnly': AppListTile(title: '纯文字行'),
      'leadingCheckbox': AppListTile(
        title: '买牛奶',
        leading: SizedBox(width: 20, height: 20),
      ),
      'checkPlusCount': AppListTile(
        title: '未分类',
        leading: SizedBox(width: 32),
        trailingValue: '154',
      ),
      'chevron': AppListTile(title: '清空回收站', trailing: SizedBox(width: 20)),
      'stepperPlusValue': AppListTile(
        title: '文字大小',
        trailingValue: '默认',
        trailing: SizedBox(width: 20),
      ),
      'switchPlusSubtitle': AppListTile(
        title: '强提醒',
        subtitle: '为收藏的笔记开启强提醒状态',
        titleWeight: FontWeight.w600,
        trailing: SizedBox(width: 44, height: 26),
      ),
    };

    testWidgets('逐个形态均能渲染', (tester) async {
      for (final entry in variants.entries) {
        await tester.pumpWidget(_wrap(entry.value));
        expect(tester.takeException(), isNull, reason: entry.key);
        expect(find.byType(AppListTile), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('有副标题时渲染第二行；无副标题时不留空行', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppListTile(title: '强提醒', subtitle: '副文案')),
      );
      expect(find.text('副文案'), findsOneWidget);

      await tester.pumpWidget(_wrap(const AppListTile(title: '强提醒')));
      expect(find.text('副文案'), findsNothing);
    });

    testWidgets('trailingValue 与 trailing 之间间距 8dp', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppListTile(
            title: '文字大小',
            trailingValue: '默认',
            trailing: const SizedBox(key: _trailingKey, width: 20, height: 20),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(_trailingKey)).dx -
            tester.getTopRight(find.text('默认')).dx,
        AppListTile.gap,
      );
    });

    testWidgets('titleWeight 覆盖字重', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppListTile(title: '强提醒', titleWeight: FontWeight.w600)),
      );
      expect(
        tester.widget<Text>(find.text('强提醒')).style?.fontWeight,
        FontWeight.w600,
      );

      await tester.pumpWidget(_wrap(const AppListTile(title: '清空回收站')));
      expect(
        tester.widget<Text>(find.text('清空回收站')).style?.fontWeight,
        AppTheme.light().extension<AppTextStyles>()!.rowTitle.fontWeight,
      );
    });
  });

  group('可点性', () {
    testWidgets('onTap == null 时不生成水波纹层', (tester) async {
      await tester.pumpWidget(_wrap(const AppListTile(title: '清空回收站')));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('onTap != null 时包 InkWell 且回调触发', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(AppListTile(title: '清空回收站', onTap: () => tapped++)),
      );

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.text('清空回收站'));
      expect(tapped, 1);
    });
  });

  group('dividerBefore', () {
    testWidgets('false 时不渲染分割线', (tester) async {
      await tester.pumpWidget(_wrap(const AppListTile(title: '云服务')));
      expect(find.byType(AppDivider), findsNothing);
    });

    testWidgets('true 时在行上方渲染一条缩进 16dp 的 AppDivider', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppListTile(title: '云服务', dividerBefore: true)),
      );

      expect(find.byType(AppDivider), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('云服务')).dy >
            tester.getTopLeft(find.byType(AppDivider)).dy,
        isTrue,
        reason: '分割线必须在行文字上方',
      );

      final divider = tester.widget<AppDivider>(find.byType(AppDivider));
      expect(divider.indent, AppListTile.indent);
    });
  });
}
