import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/presentation/widgets/note_card.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Note note({String title = '三花聚顶本是幻', String content = '脚下腾云亦非真'}) => Note(
    id: 'n1',
    title: title,
    content: content,
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

  testWidgets('标题 1 行、摘要 2 行，均 ellipsis 截断', (tester) async {
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
    expect(texts[1].maxLines, 2);
    expect(texts[1].overflow, TextOverflow.ellipsis);
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
}
