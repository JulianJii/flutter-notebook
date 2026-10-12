import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/fonts/app_font.dart';
import 'package:mynote/core/fonts/font_loader_service.dart';
import 'package:mynote/core/fonts/font_providers.dart';

import '../../support/fake_font_registrar.dart';

void main() {
  final font = appFonts.first;

  group('FontLoaderService', () {
    test('成功：只注册一次，后续同字体命中缓存', () async {
      final registrar = FakeFontRegistrar();
      final loader = FontLoaderService(registrar);

      expect(await loader.ensureLoaded(font), isTrue);
      expect(await loader.ensureLoaded(font), isTrue);
      expect(registrar.registered, <String>[font.fontFamily]);
    });

    test('并发调用同一字体只注册一次（合并在途请求）', () async {
      final registrar = FakeFontRegistrar();
      final loader = FontLoaderService(registrar);

      final results = await Future.wait(<Future<bool>>[
        loader.ensureLoaded(font),
        loader.ensureLoaded(font),
        loader.ensureLoaded(font),
      ]);

      expect(results, everyElement(isTrue));
      expect(registrar.registered, <String>[font.fontFamily]);
    });

    test('失败不缓存：网络恢复后能重试成功', () async {
      final registrar = FakeFontRegistrar(succeeds: false);
      final loader = FontLoaderService(registrar);

      expect(await loader.ensureLoaded(font), isFalse);

      registrar.succeeds = true;
      expect(await loader.ensureLoaded(font), isTrue);
      expect(registrar.registered, hasLength(2));
    });
  });

  group('fontFamilyOf', () {
    ProviderContainer containerWith(FakeFontRegistrar registrar) {
      final container = ProviderContainer(
        overrides: [
          fontLoaderServiceProvider.overrideWithValue(
            FontLoaderService(registrar),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('null / 未知 id -> null，且不触发任何下载（系统默认是零成本档）', () async {
      final registrar = FakeFontRegistrar();
      final container = containerWith(registrar);

      expect(await container.read(fontFamilyOfProvider(null).future), isNull);
      expect(await container.read(fontFamilyOfProvider('nope').future), isNull);
      expect(registrar.registered, isEmpty);
    });

    test('已知 id -> 目录里的族名', () async {
      final registrar = FakeFontRegistrar();
      final container = containerWith(registrar);

      expect(
        await container.read(fontFamilyOfProvider(font.id).future),
        font.fontFamily,
      );
    });

    test('注册失败 -> error，消费方读 value 得到 null（回落系统默认，不阻塞页面）', () async {
      final container = containerWith(FakeFontRegistrar(succeeds: false));
      // ⚠️ 不 await `.future`：Riverpod 3 对失败的 provider 会自动退避重试，
      // 那个 future 要等到「不再重试」才会落定 —— 断言会挂到超时。
      // 这里改为订阅错误流：失败状态一出现就能看到。
      final errors = <Object?>[];
      container.listen<AsyncValue<String?>>(fontFamilyOfProvider(font.id), (
        _,
        next,
      ) {
        if (next.hasError) errors.add(next.error);
      });
      await pumpEventQueue();

      expect(errors, isNotEmpty);
      expect(errors.first, isA<FontFailure>());
      expect(container.read(fontFamilyOfProvider(font.id)).value, isNull);
    });
  });
}
