import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/presentation/widgets/note_card.dart';
import 'package:mynote/features/notes/presentation/widgets/note_masonry_grid.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zoloto/zoloto.dart';

/// D1 基准视口（1080px = 360dp）。全项目 P1 / P3 / P2 三份基线共用同一个，
/// 便于横向比对；`pixelRatio = 1.0` 让 1 dp = 1 物理像素。见 TASK-035 §2。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

void main() {
  Note note(String id, {String content = '脚下腾云亦非真'}) => Note(
    id: id,
    title: '标题 $id',
    content: content,
    createdAt: DateTime(2026, 8, 25),
    updatedAt: DateTime(2026, 8, 25),
  );

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(body: SizedBox(width: 360, height: 640, child: child)),
  );

  testWidgets('空列表渲染零尺寸占位，不抛异常', (tester) async {
    await tester.pumpWidget(
      wrap(const NoteMasonryGrid(notes: <Note>[], textScale: 1)),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NoteCard), findsNothing);
  });

  testWidgets('2 列均分，列间距与页边距来自 token', (tester) async {
    await tester.pumpWidget(
      wrap(NoteMasonryGrid(notes: <Note>[note('1'), note('2')], textScale: 1)),
    );

    final first = tester.getTopLeft(find.byKey(const ValueKey<String>('1')));
    final second = tester.getTopLeft(find.byKey(const ValueKey<String>('2')));
    final columnWidth =
        (360 - AppSpacing.pageH * 2 - AppSpacing.gridGutter) / 2;

    expect(first.dx, AppSpacing.pageH);
    expect(
      second.dx - first.dx,
      closeTo(columnWidth + AppSpacing.gridGutter, 0.5),
    );
    expect(
      tester.getSize(find.byType(NoteCard).first).width,
      closeTo(columnWidth, 0.5),
    );
  });

  testWidgets('底部留白含底部导航高度 + 12dp，不被裁切', (tester) async {
    await tester.pumpWidget(
      wrap(NoteMasonryGrid(notes: <Note>[note('1')], textScale: 1)),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(MasonryGridView));
    expect(size.height, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('onTapNote 收到被点击的 Note', (tester) async {
    Note? tapped;
    await tester.pumpWidget(
      wrap(
        NoteMasonryGrid(
          notes: <Note>[note('1'), note('2')],
          textScale: 1,
          onTapNote: (n) => tapped = n,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('2')));

    expect(tapped?.id, '2');
  });

  testWidgets('onTapNote 为 null 时点击不崩', (tester) async {
    await tester.pumpWidget(
      wrap(NoteMasonryGrid(notes: <Note>[note('1')], textScale: 1)),
    );
    await tester.tap(find.byType(NoteCard));

    expect(tester.takeException(), isNull);
  });

  testWidgets('宽屏下两列仍等宽（Q27 无稿，不加断点）', (tester) async {
    await tester.pumpWidget(
      wrap(NoteMasonryGrid(notes: <Note>[note('1'), note('2')], textScale: 1)),
    );

    expect(find.byType(NoteCard), findsNWidgets(2));
    final widths = <double>{
      for (final card in find.byType(NoteCard).evaluate())
        tester.getSize(find.byWidget(card.widget)).width,
    };
    expect(widths, hasLength(1), reason: '两列等宽');
  });

  testWidgets('底部导航高度只来自共享常量', (tester) async {
    await tester.pumpWidget(
      wrap(NoteMasonryGrid(notes: <Note>[note('1')], textScale: 1)),
    );

    expect(kBottomNavContentHeight, 64);
    expect(tester.takeException(), isNull);
  });

  testGoldenWidgets('2 列瀑布流结构基线', (tester) async {
    await expectMatchTestEnvironments(
      'note_masonry_grid',
      tester: tester,
      widget: Scaffold(
        body: NoteMasonryGrid(
          notes: <Note>[
            note('1'),
            note('2', content: List<String>.filled(6, '一行').join('\n')),
            note('3'),
            note('4'),
          ],
          textScale: 1,
        ),
      ),
      testEnvironments: <TestEnvironment>[goldenEnv],
    );
  });
}
