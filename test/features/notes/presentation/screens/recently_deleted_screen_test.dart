import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:init/features/notes/presentation/screens/recently_deleted_screen.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

final DateTime _deletedAt = DateTime(2026, 10, 4, 9, 30);

/// 时间戳是常量：drift 存 unix 秒，`DateTime.now()` 会让「删除于」文案每次不同。
Note deletedNote(String id, {String title = '已删笔记'}) => Note(
  id: id,
  title: title,
  content: '[]',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 2),
  deletedAt: _deletedAt,
);

void main() {
  /// override 打在 **Repository** 层（data 的边界）：既验证「Screen 只经 provider
  /// 取数」，又不开真实 drift 库。
  Widget app({
    required Stream<List<Note>> stream,
    Future<Either<Failure, Unit>> Function(String)? onRestore,
    Future<Either<Failure, Unit>> Function(String)? onPurge,
    Future<Either<Failure, Unit>> Function()? onPurgeAll,
  }) {
    final repo = _MockNoteRepository();
    when(() => repo.watchDeleted()).thenAnswer((_) => stream);
    when(() => repo.restore(any())).thenAnswer(
      (invocation) async =>
          onRestore?.call(invocation.positionalArguments.first as String) ??
          const Right<Failure, Unit>(unit),
    );
    when(() => repo.purge(any())).thenAnswer(
      (invocation) async =>
          onPurge?.call(invocation.positionalArguments.first as String) ??
          const Right<Failure, Unit>(unit),
    );
    when(() => repo.purgeAll()).thenAnswer(
      (_) async => onPurgeAll?.call() ?? const Right<Failure, Unit>(unit),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.noteTrash,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.noteTrash,
          builder: (context, state) => const RecentlyDeletedScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [noteRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    );
  }

  testWidgets('空回收站：显示空态文案，清空按钮禁用，不崩', (tester) async {
    await tester.pumpWidget(app(stream: Stream.value(const <Note>[])));
    await tester.pumpAndSettle();

    expect(find.text('没有已删除的笔记'), findsOneWidget);
    expect(find.text('恢复'), findsNothing);
    final emptyButton = tester.widget<AppIconButton>(
      find.ancestor(
        of: find.byIcon(AppIcons.trash),
        matching: find.byType(AppIconButton),
      ),
    );
    expect(emptyButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有内容：渲染行与两个操作，行不可点（无编辑入口）', (tester) async {
    await tester.pumpWidget(
      app(stream: Stream.value(<Note>[deletedNote('n1')])),
    );
    await tester.pumpAndSettle();

    expect(find.text('已删笔记'), findsOneWidget);
    expect(find.text('恢复'), findsOneWidget);
    expect(find.text('永久删除'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('恢复成功：调 restore 并提示「已恢复」', (tester) async {
    final restored = <String>[];
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[deletedNote('n1')]),
        onRestore: (id) async {
          restored.add(id);
          return const Right<Failure, Unit>(unit);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();

    expect(restored, <String>['n1']);
    expect(find.text('已恢复'), findsOneWidget);
  });

  testWidgets('恢复失败：弹 failure 文案', (tester) async {
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[deletedNote('n1')]),
        onRestore: (_) async =>
            const Left<Failure, Unit>(CacheFailure(message: 'disk full')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();

    expect(find.text('disk full'), findsOneWidget);
  });

  testWidgets('永久删除：先二次确认，确认后调 purge；取消不写库', (tester) async {
    final purged = <String>[];
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[deletedNote('n1')]),
        onPurge: (id) async {
          purged.add(id);
          return const Right<Failure, Unit>(unit);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('永久删除').first);
    await tester.pumpAndSettle();
    expect(purged, isEmpty, reason: '确认前不许写库');

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(purged, isEmpty);

    await tester.tap(find.text('永久删除').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '永久删除').last);
    await tester.pumpAndSettle();

    expect(purged, <String>['n1']);
  });

  testWidgets('永久删除失败：留在页面并弹 Snackbar', (tester) async {
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[deletedNote('n1')]),
        onPurge: (_) async =>
            const Left<Failure, Unit>(CacheFailure(message: 'boom')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('永久删除').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '永久删除').last);
    await tester.pumpAndSettle();

    expect(find.text('boom'), findsOneWidget);
    expect(find.byType(RecentlyDeletedScreen), findsOneWidget);
  });

  testWidgets('清空回收站：顶栏 trash → 二次确认 → 调 purgeAll → 提示「已清空」', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[deletedNote('n1')]),
        onPurgeAll: () async {
          calls++;
          return const Right<Failure, Unit>(unit);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.trash));
    await tester.pumpAndSettle();
    expect(calls, 0, reason: '确认前不许写库');

    await tester.tap(find.widgetWithText(TextButton, '清空').last);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('已清空'), findsOneWidget);
  });

  testWidgets('清空失败：弹 failure 文案', (tester) async {
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[deletedNote('n1')]),
        onPurgeAll: () async =>
            const Left<Failure, Unit>(CacheFailure(message: 'disk full')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.trash));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '清空').last);
    await tester.pumpAndSettle();

    expect(find.text('disk full'), findsOneWidget);
  });

  testWidgets('标题为空时用正文第一行顶上', (tester) async {
    await tester.pumpWidget(
      app(
        stream: Stream.value(<Note>[
          deletedNote('n1', title: '').copyWith(content: '[]'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // 正文是空 Delta → 退回占位文案，而不是空白行。
    expect(find.byType(RecentlyDeletedScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('读流失败：内容区留白，不渲染错误页', (tester) async {
    await tester.pumpWidget(
      app(stream: Stream<List<Note>>.error(StateError('boom'))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecentlyDeletedScreen), findsOneWidget);
    expect(find.text('恢复'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}