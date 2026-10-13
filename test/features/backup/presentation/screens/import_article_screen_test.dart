import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/backup/presentation/providers/backup_file_service.dart';
import 'package:mynote/features/backup/presentation/screens/import_article_screen.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

Note _note() => Note(
  id: 'n1',
  title: 't',
  content: 'c',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUpAll(() => registerFallbackValue(_note()));

  late _MockNoteRepository repo;

  /// `create` 收到的笔记，按调用顺序。断言看它而不是看仓库的返回值 ——
  /// 「标题取哪来、正文是不是合法 Delta」才是这个页面要保证的事。
  late List<Note> created;
  late ProviderContainer container;

  setUp(() {
    repo = _MockNoteRepository();
    created = <Note>[];
    when(() => repo.create(any())).thenAnswer((invocation) async {
      final note = invocation.positionalArguments.first as Note;
      created.add(note);
      return Right<Failure, Note>(note);
    });
    container = ProviderContainer(
      overrides: [
        // override 打在**用例**上：页面只经 provider 取用例，这里也就守住了
        // 「presentation 不 import data」这条分层约束。
        createNoteUseCaseProvider.overrideWithValue(CreateNoteUseCase(repo)),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(
    WidgetTester tester, {
    required Future<List<PickedArticle>> Function() pick,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: ImportArticleScreen(pickFiles: pick),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickAndSettle(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('import_article_pick')));
    await tester.pumpAndSettle();
  }

  AppListTile pickTile(WidgetTester tester) =>
      tester.widget<AppListTile>(find.byKey(const Key('import_article_pick')));

  group('导入文章页', () {
    testWidgets('还没导过：不显示结果分组', (tester) async {
      await pump(tester, pick: () async => const <PickedArticle>[]);

      expect(find.text('导入文章'), findsOneWidget);
      expect(find.text('选择文件'), findsOneWidget);
      expect(find.byKey(const Key('import_article_results')), findsNothing);
    });

    testWidgets('一个 Markdown 文件 → 一篇笔记，标题取正文一级标题', (tester) async {
      await pump(
        tester,
        pick: () async => const <PickedArticle>[
          (name: 'a.md', content: '# 我的标题\n\n正文段落'),
        ],
      );
      await pickAndSettle(tester);

      expect(created, hasLength(1));
      expect(created.single.title, '我的标题');
      expect(created.single.folderId, isNull, reason: '导入一律进「未分类」');
      expect(NoteDelta.plainText(created.single.content), contains('正文段落'));

      expect(find.text('a.md'), findsOneWidget);
      expect(find.text('已导入'), findsOneWidget);
      expect(find.text('已导入 1 篇，0 篇失败'), findsOneWidget);
    });

    testWidgets('一批文件逐个独立：坏的只坏自己，好的照进', (tester) async {
      await pump(
        tester,
        pick: () async => const <PickedArticle>[
          (name: 'ok.html', content: '<title>好文章</title><p>正文</p>'),
          // content 为 null = 读不出文本（非 UTF-8）。
          (name: 'gbk.md', content: null),
          (name: 'blank.md', content: '   \n'),
        ],
      );
      await pickAndSettle(tester);

      expect(created, hasLength(1));
      expect(created.single.title, '好文章');

      expect(find.text('ok.html'), findsOneWidget);
      expect(find.text('gbk.md'), findsOneWidget);
      expect(find.text('blank.md'), findsOneWidget);
      expect(find.text('已导入'), findsOneWidget);
      expect(find.text('读不出文本，可能不是 UTF-8 编码'), findsOneWidget);
      expect(find.text('文件里没有内容'), findsOneWidget);
      expect(find.text('已导入 1 篇，2 篇失败'), findsOneWidget);
    });

    testWidgets('失败原因用危险色，成功用次级灰', (tester) async {
      await pump(
        tester,
        pick: () async => const <PickedArticle>[
          (name: 'gbk.md', content: null),
          (name: 'ok.md', content: '正文'),
        ],
      );
      await pickAndSettle(tester);

      Color? colorOf(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;

      final danger = tester
          .element(find.text('读不出文本，可能不是 UTF-8 编码'))
          .colors
          .feedbackDanger;
      expect(colorOf('读不出文本，可能不是 UTF-8 编码'), danger);

      final okElement = tester.element(find.text('已导入'));
      expect(colorOf('已导入'), okElement.colors.textSecondary);
    });

    testWidgets('全部失败：提示指向下面的原因，而不是一句「导入失败」', (tester) async {
      await pump(
        tester,
        pick: () async => const <PickedArticle>[
          (name: 'a.txt', content: 'not supported'),
        ],
      );
      await pickAndSettle(tester);

      expect(created, isEmpty);
      expect(find.text('不支持的格式，只认 Markdown 与 HTML'), findsOneWidget);
      expect(find.text('没有导入任何文章，请看下面的失败原因'), findsOneWidget);
    });

    testWidgets('取消选择：不建笔记，也不动上一次的结果', (tester) async {
      await pump(
        tester,
        pick: () async => const <PickedArticle>[(name: 'a.md', content: '正文')],
      );
      await pickAndSettle(tester);
      expect(created, hasLength(1));

      // 换成「取消」再点一次。
      await pump(tester, pick: () async => const <PickedArticle>[]);
      await pickAndSettle(tester);

      expect(created, hasLength(1), reason: '取消不该再建笔记');
      expect(find.text('a.md'), findsOneWidget, reason: '上一次的结果要留着');
    });

    testWidgets('导入过程中：入口行禁用 + 行尾转圈', (tester) async {
      final gate = Completer<List<PickedArticle>>();
      await pump(tester, pick: () => gate.future);

      expect(pickTile(tester).onTap, isNotNull);
      await tester.tap(find.byKey(const Key('import_article_pick')));
      // ⚠️ 不能用 pumpAndSettle：行尾的转圈会一直动，settle 不下来。
      await tester.pump();

      expect(pickTile(tester).onTap, isNull, reason: '忙态下不该再点开一次选择器');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete(const <PickedArticle>[(name: 'a.md', content: '正文')]);
      await tester.pumpAndSettle();

      expect(pickTile(tester).onTap, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
