import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:zoloto/zoloto.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return Zoloto.setup(
    testMain: testMain,
    config: ZolotoConfig.defaultSetup(
      // 沿用原有 golden_toolkit 目录约定
      goldenFolderName: 'goldens',
      // 1.5% 容差比较器，保证跨平台一致性
      // （处理 macOS 与 Linux CI 之间的字体渲染差异）
      comparatorFactory: (testFile) =>
          ZolotoFileComparator(testFile, toleranceThreshold: 0.015),
      // 使用应用真实主题作为 golden 外壳
      // （应用主题来自 material_ui，与 zoloto 的 flutter/material 版本不兼容，
      // 因此这里自行构造 material_ui 的 MaterialApp 外壳）
      appWrapperFactory: () => (child) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    ),
  );
}
