import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/ui/app_card.dart';
import 'package:init/core/ui/app_icon.dart';
import 'package:init/features/notes/presentation/widgets/create_folder_row.dart';
import 'package:init/features/notes/presentation/widgets/folder_row.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: <LocalizationsDelegate<dynamic>>[
    ...AppLocalizations.localizationsDelegates,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  home: Scaffold(body: SizedBox(width: 336, child: child)),
);

void main() {
  group('FolderRow', () {
    testWidgets('未选中：无 check，名称与计数照常渲染', (tester) async {
      await tester.pumpWidget(_wrap(const FolderRow(name: '未分类', count: 154)));

      expect(find.byIcon(AppIcons.check), findsNothing);
      expect(find.text('未分类'), findsOneWidget);
      expect(find.text('154'), findsOneWidget);
    });

    testWidgets('选中：显示 20dp 琥珀色 check', (tester) async {
      await tester.pumpWidget(
        _wrap(const FolderRow(name: '全部', count: 155, isSelected: true)),
      );

      expect(find.byIcon(AppIcons.check), findsOneWidget);
      expect(tester.widget<AppIcon>(find.byType(AppIcon)).size, 20);
      expect(find.text('155'), findsOneWidget);
    });

    testWidgets('计数右对齐、14sp；名称 16sp', (tester) async {
      await tester.pumpWidget(
        _wrap(const FolderRow(name: '闻声笔记', count: 1, isSelected: true)),
      );

      expect(tester.widget<Text>(find.text('1')).style?.fontSize, 14);
      expect(tester.widget<Text>(find.text('闻声笔记')).style?.fontSize, 16);
      expect(
        tester.getTopRight(find.text('1')).dx,
        greaterThan(tester.getTopRight(find.text('闻声笔记')).dx),
      );
    });

    testWidgets('onTap 非空时被调用一次', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(FolderRow(name: '全部', count: 155, onTap: () => tapped++)),
      );
      await tester.tap(find.byType(FolderRow));

      expect(tapped, 1);
    });

    testWidgets('onTap 为 null 时点击无反应且不崩', (tester) async {
      await tester.pumpWidget(_wrap(const FolderRow(name: '全部', count: 155)));
      await tester.tap(find.byType(FolderRow), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(InkWell), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('行高由 rowTitle + 上下 rowPadH 得出，不写死高度', (tester) async {
      await tester.pumpWidget(
        _wrap(const FolderRow(name: '闻声笔记', count: 1, isSelected: true)),
      );

      // 16sp x 1.4 + 16x2 = 54.4（D4 实测 ~60，未写死）。
      expect(tester.getSize(find.byType(FolderRow)).height, closeTo(54.4, 1));
      expect(find.byType(AppCard), findsOneWidget);
    });
  });

  group('CreateFolderRow', () {
    testWidgets('图标在文案上方、琥珀色；文案是「新建文件夹」', (tester) async {
      await tester.pumpWidget(_wrap(const CreateFolderRow()));

      final icon = find.byIcon(AppIcons.circlePlusOutline);
      expect(icon, findsOneWidget);
      expect(find.text('新建文件夹'), findsOneWidget);
      expect(
        tester.getTopLeft(icon).dy,
        lessThan(tester.getTopLeft(find.text('新建文件夹')).dy),
      );
      expect(
        tester.getTopLeft(find.text('新建文件夹')).dy -
            tester.getBottomLeft(icon).dy,
        closeTo(CreateFolderRow.iconGap, 0.5),
      );
    });

    testWidgets('卡高约 72dp，比 FolderRow 高', (tester) async {
      await tester.pumpWidget(_wrap(const CreateFolderRow()));
      final create = tester.getSize(find.byType(CreateFolderRow)).height;

      await tester.pumpWidget(_wrap(const FolderRow(name: '全部', count: 155)));
      final row = tester.getSize(find.byType(FolderRow)).height;

      expect(create, closeTo(72, 1.5));
      expect(create, greaterThan(row));
    });

    testWidgets('onTap 为 null 时点击无反应且不崩', (tester) async {
      await tester.pumpWidget(_wrap(const CreateFolderRow()));
      await tester.tap(find.byType(CreateFolderRow), warnIfMissed: false);
      await tester.pump();

      expect(find.byType(InkWell), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
