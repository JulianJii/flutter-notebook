import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mynote/core/constants/app_constants.dart';
import 'package:mynote/core/updates/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockDio extends Mock implements Dio {}

final _installed = PackageInfo(
  appName: 'MyNote',
  packageName: 'com.wode.mynote',
  version: '1.0.0',
  buildNumber: '1',
  buildSignature: '',
);

Response<dynamic> _releaseResponse(Map<String, dynamic> body) =>
    Response<dynamic>(
      requestOptions: RequestOptions(
        path: AppConstants.githubLatestReleaseApiUrl,
      ),
      data: body,
    );

void main() {
  late MockDio dio;
  late BasicUpdateService service;

  setUp(() {
    dio = MockDio();
    service = BasicUpdateService(dio: dio, installedPackageInfo: _installed);
  });

  group('isUpdateNeeded', () {
    test('release tag 的 v 前缀不影响比较', () {
      // 剥前缀前 `v1.0.1` 会被读成 0.0.1，从而漏报更新。
      expect(service.isUpdateNeeded('1.0.0', 'v1.0.1'), isTrue);
      expect(service.isUpdateNeeded('v1.0.0', '1.0.0'), isFalse);
    });

    test('按 major / minor / patch 逐级比较，不是字符串比较', () {
      expect(service.isUpdateNeeded('1.9.0', '1.10.0'), isTrue);
      expect(service.isUpdateNeeded('1.0.9', '1.0.10'), isTrue);
      expect(service.isUpdateNeeded('2.0.0', '1.99.99'), isFalse);
    });

    test('不足三段的版本号补 0', () {
      expect(service.isUpdateNeeded('1.0', '1.0.0'), isFalse);
      expect(service.isUpdateNeeded('1.0', '1.0.1'), isTrue);
    });
  });

  group('checkForUpdates', () {
    test('解析 release 的 tag_name / html_url / body', () async {
      when(
        () => dio.get<dynamic>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => _releaseResponse(<String, dynamic>{
          'tag_name': 'v1.2.0',
          'html_url':
              'https://github.com/JulianJii/flutter-notebook/releases/tag/v1.2.0',
          'body': 'Bug fixes',
        }),
      );

      final result = await service.checkForUpdates();

      expect(result, UpdateCheckResult.updateAvailable);
      final info = await service.getUpdateInfo();
      expect(info?.latestVersion, 'v1.2.0');
      expect(info?.releaseNotes, 'Bug fixes');
      expect(info?.updateUrl, contains('releases/tag/v1.2.0'));
    });

    test('版本相同或更高时不过报更新', () async {
      when(
        () => dio.get<dynamic>(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => _releaseResponse(<String, dynamic>{'tag_name': 'v1.0.0'}),
      );

      expect(await service.checkForUpdates(), UpdateCheckResult.upToDate);
    });

    test('请求失败（限流 / 断网）兜成 checkFailed', () async {
      when(
        () => dio.get<dynamic>(any(), options: any(named: 'options')),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      expect(await service.checkForUpdates(), UpdateCheckResult.checkFailed);
    });

    test('payload 缺 tag_name 兜成 checkFailed', () async {
      when(
        () => dio.get<dynamic>(any(), options: any(named: 'options')),
      ).thenAnswer((_) async => _releaseResponse(<String, dynamic>{}));

      expect(await service.checkForUpdates(), UpdateCheckResult.checkFailed);
    });
  });

  test('displayVersion 去掉展示时的 v 前缀', () {
    expect(displayVersion('v1.2.0'), '1.2.0');
    expect(displayVersion('1.2.0'), '1.2.0');
  });
}
