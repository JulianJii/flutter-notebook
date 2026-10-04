import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/shell/notes_shell.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/features/notes/presentation/providers/note_editor_provider.dart';
import 'package:init/features/notes/presentation/screens/folder_manager_screen.dart';
import 'package:init/features/notes/presentation/screens/note_detail_screen.dart';
import 'package:init/features/notes/presentation/screens/note_list_screen.dart';
import 'package:init/features/settings/presentation/screens/settings_screen.dart';
import 'package:init/features/todos/presentation/screens/todo_list_screen.dart';
import 'package:material_ui/material_ui.dart';

/// 全局 navigator key，供顶层（非 branch 内）路由使用。
/// `/settings` 需要覆盖整个 Shell 显示，因此挂在 root 上。
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 唯一 routerProvider（`DEVELOPMENT-GUIDELINES.md` §13 规则 1）。
///
/// 无 `redirect`：笔记 App 无登录（CONFLICT-01 已裁决移除登录守卫）。
/// 不 watch `persistentLocaleProvider`：语言由 `main.dart` 的 `MaterialApp.locale`
/// 负责，在此 watch 会让语言切换重建 GoRouter 并丢失导航栈。
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.initial,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            NotesShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.notes,
                builder: (context, state) => const NoteListScreen(),
                routes: <RouteBase>[
                  // ⚠️ 顺序不可调换：`folders` 与 `new` 都必须先于 `:id` 注册，
                  // 否则 'folders' / 'new' 会被当作笔记 id。
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const NoteDetailScreen(noteId: kNewNoteId),
                  ),
                  GoRoute(
                    path: 'folders',
                    builder: (context, state) => const FolderManagerScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        NoteDetailScreen(noteId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.todos,
                builder: (context, state) => const TodoListScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    // 404 是路由层诊断页，不是产品错误页（`COMPONENT-INVENTORY.md` §2 不含
    // `AppErrorView`），故不抽组件。恢复出口跳 `AppRoutes.initial`。
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('404 · ${state.uri.path}'),
            const SizedBox(height: AppSpacing.chipGap),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.initial),
              child: const Text('返回笔记'),
            ),
          ],
        ),
      ),
    ),
  );
});
