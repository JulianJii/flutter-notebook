import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言选择的落盘 + 「跟随系统」的解析。
///
/// ⚠️ **用 `testWidgets` 而不是 `test`**：`appLocaleProvider` 读
/// `WidgetsBinding.instance.platformDispatcher`，必须有 binding。系统语言一律由
/// `localeTestValue` 指定 —— 否则断言会随跑测试的机器语言变。
void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  });

  /// 指定系统语言，并在用例结束后还原。
  void setSystemLocale(WidgetTester tester, Locale locale) {
    tester.platformDispatcher.localeTestValue = locale;
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  }

  testWidgets('没选过：state 为 null，生效语言 = 系统语言', (tester) async {
    setSystemLocale(tester, const Locale('en', 'US'));

    expect(container.read(persistentLocaleProvider), isNull);
    // ⚠️ 系统语言带国家码（`en_US`），provider 原样透传，故只比主语言码。
    expect(container.read(appLocaleProvider).languageCode, 'en');
  });

  testWidgets('系统语言不受支持：回落中文', (tester) async {
    setSystemLocale(tester, const Locale('fr'));

    expect(container.read(appLocaleProvider), const Locale('zh'));
  });

  testWidgets('setLocale：落盘并盖过系统语言', (tester) async {
    setSystemLocale(tester, const Locale('zh'));

    await container
        .read(persistentLocaleProvider.notifier)
        .setLocale(const Locale('en'));

    expect(container.read(appLocaleProvider), const Locale('en'));
    expect(prefs.getString(languageCodeKey), 'en');
  });

  testWidgets('setLocale(null)：删键，回到跟随系统', (tester) async {
    setSystemLocale(tester, const Locale('zh'));

    await container
        .read(persistentLocaleProvider.notifier)
        .setLocale(const Locale('en'));
    await container.read(persistentLocaleProvider.notifier).setLocale(null);

    expect(container.read(persistentLocaleProvider), isNull);
    expect(prefs.getString(languageCodeKey), isNull);
    expect(container.read(appLocaleProvider), const Locale('zh'));
  });

  testWidgets('不受支持的语言码：state 与落盘都不动', (tester) async {
    setSystemLocale(tester, const Locale('zh'));

    await container
        .read(persistentLocaleProvider.notifier)
        .setLocale(const Locale('fr'));

    expect(container.read(persistentLocaleProvider), isNull);
    expect(prefs.getString(languageCodeKey), isNull);
  });
}
