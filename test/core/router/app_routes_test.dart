import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/router/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('6 条路径全部以 / 开头且互不相同', () {
      final paths = <String>[
        AppRoutes.notes,
        AppRoutes.noteNew,
        AppRoutes.noteFolders,
        AppRoutes.noteDetail,
        AppRoutes.todos,
        AppRoutes.settings,
      ];

      for (final path in paths) {
        expect(path, startsWith('/'), reason: '$path 缺少前导 /');
      }
      expect(paths.toSet(), hasLength(paths.length), reason: '存在重复路径');
    });

    test('initial 指向笔记列表', () {
      expect(AppRoutes.initial, AppRoutes.notes);
    });
  });
}
