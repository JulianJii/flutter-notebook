import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_background.dart';
import 'package:init/features/notes/presentation/widgets/note_background_image.dart';
import 'package:init/features/notes/presentation/widgets/note_card.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Note note({
    String title = '三花聚顶本是幻',
    String content = '脚下腾云亦非真',
    NoteBackground? background,
  }) => Note(
    id: 'n1',
    title: title,
    content: content,
    background: background,
    createdAt: DateTime(2026, 8, 25),
    updatedAt: DateTime(2026, 8, 25),
  );

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(body: SizedBox(width: 160, child: child)),
  );

  testWidgets('渲染标题 / 摘要 / 日期三段', (tester) async {
    await tester.pumpWidget(wrap(NoteCard(note: note(), textScale: 1)));

    expect(find.text('三花聚顶本是幻'), findsOneWidget);
    expect(find.text('脚下腾云亦非真'), findsOneWidget);
    expect(find.text('8月25日'), findsOneWidget);
  });

  testWidgets('正文为空时显示占位文案', (tester) async {
    await tester.pumpWidget(
      wrap(NoteCard(note: note(content: '   '), textScale: 1)),
    );

    expect(find.text('无附加文案'), findsOneWidget);
  });

  testWidgets('标题 1 行、摘要最多 6 行，均 ellipsis 截断', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteCard(
          note: note(content: List<String>.filled(20, '一行内容').join('\n')),
          textScale: 1,
        ),
      ),
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts[0].maxLines, 1);
    expect(texts[0].overflow, TextOverflow.ellipsis);
    expect(texts[1].maxLines, 6);
    expect(texts[1].overflow, TextOverflow.ellipsis);
  });

  testWidgets('正文越长卡片越高（瀑布流错落的来源）', (tester) async {
    Future<double> heightOf(String content) async {
      await tester.pumpWidget(wrap(NoteCard(note: note(content: content), textScale: 1)));
      return tester.getSize(find.byType(NoteCard)).height;
    }

    final oneLine = await heightOf('一行');
    final longText = await heightOf(List<String>.filled(40, '行').join('\n'));

    expect(longText - oneLine, greaterThan(AppSpacing.sm * 4));
  });

  testWidgets('标题为空时不抛异常（不崩卡片）', (tester) async {
    await tester.pumpWidget(
      wrap(NoteCard(note: note(title: ''), textScale: 1)),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('onTap 非空时被调用一次', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(NoteCard(note: note(), textScale: 1, onTap: () => tapped++)),
    );
    await tester.tap(find.byType(NoteCard));

    expect(tapped, 1);
  });

  testWidgets('onTap 为 null 时无 InkWell、点击不崩', (tester) async {
    await tester.pumpWidget(wrap(NoteCard(note: note(), textScale: 1)));
    await tester.tap(find.byType(NoteCard));

    expect(find.byType(InkWell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('卡片高度随内容变化，不写死高度', (tester) async {
    await tester.pumpWidget(wrap(NoteCard(note: note(), textScale: 1)));
    final short = tester.getSize(find.byType(NoteCard)).height;

    await tester.pumpWidget(
      wrap(
        NoteCard(
          note: note(content: List<String>.filled(30, '行').join('\n')),
          textScale: 1,
        ),
      ),
    );
    final tall = tester.getSize(find.byType(NoteCard)).height;

    expect(tall, greaterThan(short));
  });

  testWidgets('三段间距均为 AppSpacing.sm，卡片内边距为 AppSpacing.cardPad', (tester) async {
    await tester.pumpWidget(wrap(NoteCard(note: note(), textScale: 1)));

    final titleBottom = tester.getBottomLeft(find.text('三花聚顶本是幻')).dy;
    final snippetTop = tester.getTopLeft(find.text('脚下腾云亦非真')).dy;
    final snippetBottom = tester.getBottomLeft(find.text('脚下腾云亦非真')).dy;
    final dateTop = tester.getTopLeft(find.text('8月25日')).dy;

    expect(snippetTop - titleBottom, closeTo(AppSpacing.sm, 0.5));
    expect(dateTop - snippetBottom, closeTo(AppSpacing.sm, 0.5));
  });

  testWidgets('卡片容器是 AppCard，不是自绘 Container', (tester) async {
    await tester.pumpWidget(wrap(NoteCard(note: note(), textScale: 1)));

    expect(find.byType(Card), findsOneWidget);
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.margin, EdgeInsets.zero);
    expect(card.surfaceTintColor, Colors.transparent);
  });

  testWidgets('无背景：卡片不画背景图层', (tester) async {
    await tester.pumpWidget(wrap(NoteCard(note: note(), textScale: 1)));

    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => image.image is AssetBundleImageProvider),
      isEmpty,
    );
  });

  testWidgets('有背景：纸纹铺满整卡且半透明，内容仍保留卡片内边距', (tester) async {
    await tester.pumpWidget(
      wrap(NoteCard(note: note(background: NoteBackground.blush), textScale: 1)),
    );

    final images = tester
        .widgetList<Image>(find.byType(Image))
        .where((image) => image.image is AssetBundleImageProvider)
        .toList();
    expect(images, hasLength(1), reason: '背景 = 卡片预览的一部分');

    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(Image),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      kNoteBackgroundOpacity,
      reason: '与详情页共用一个透明度常量',
    );

    // full-bleed：背景与卡片同宽同高（内边距不吃掉背景）。
    final cardSize = tester.getSize(find.byType(NoteCard));
    final imageSize = tester.getSize(find.byType(Image));
    expect(imageSize.width, closeTo(cardSize.width, 1));
    expect(imageSize.height, closeTo(cardSize.height, 1));

    // 内容左内边距仍是 cardPad。
    expect(
      tester.getTopLeft(find.text('三花聚顶本是幻')).dx -
          tester.getTopLeft(find.byType(NoteCard)).dx,
      closeTo(AppSpacing.cardPad, 1),
    );
  });
}
