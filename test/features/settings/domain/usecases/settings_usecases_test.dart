import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:mynote/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

final AppSettings _settings = const AppSettings(themeMode: AppThemeMode.dark);

void main() {
  late MockSettingsRepository repo;

  setUpAll(() {
    registerFallbackValue(_settings);
    registerFallbackValue(NoParams());
  });

  setUp(() {
    repo = MockSettingsRepository();
  });

  group('GetSettingsUseCase', () {
    test('成功：原样透传 Right(settings)', () async {
      when(
        () => repo.load(),
      ).thenAnswer((_) async => Right<Failure, AppSettings>(_settings));
      expect(
        await GetSettingsUseCase(repo)(NoParams()),
        Right<Failure, AppSettings>(_settings),
      );
    });

    test('失败透传：Left(CacheFailure) 原样，不吞异常、不二次包装', () async {
      when(() => repo.load()).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'prefs gone')),
      );
      final result = await GetSettingsUseCase(repo)(NoParams());
      result.fold(
        (f) => expect((f as CacheFailure).message, 'prefs gone'),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('SaveSettingsUseCase', () {
    test('成功：原样透传', () async {
      when(() => repo.save(any())).thenAnswer((_) async => const Right(unit));
      expect(
        await SaveSettingsUseCase(repo)(_settings),
        const Right<Failure, Unit>(unit),
      );
      verify(() => repo.save(_settings)).called(1);
    });

    test('失败透传：Left(CacheFailure) 原样', () async {
      when(
        () => repo.save(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await SaveSettingsUseCase(repo)(_settings);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });
}
