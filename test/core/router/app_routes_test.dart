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

    test('initial 指向 P1 笔记列表', () {
      expect(AppRoutes.initial, AppRoutes.notes);
    });

    test('两条固定子路径不是 /notes 的重复', () {
      expect(AppRoutes.noteNew, isNot(AppRoutes.notes));
      expect(AppRoutes.noteFolders, isNot(AppRoutes.notes));
    });

    test('文件夹筛选 query key 为 folder', () {
      expect(AppRoutes.folderQueryKey, 'folder');
    });
  });
}
