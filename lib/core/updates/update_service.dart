import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// 展示用版本号：Release tag 常写成 `v1.2.0`，UI 上去掉前缀。
String displayVersion(String version) =>
    version.replaceFirst(RegExp(r'^[vV]'), '');

/// 应用版本检查的结果
enum UpdateCheckResult {
  /// 应用已是最新版本
  upToDate,

  /// 有可选的更新可用
  updateAvailable,

  /// 需要关键更新
  criticalUpdateRequired,

  /// 检查失败或无法执行
  checkFailed,
}

/// 可用更新的信息
class UpdateInfo {
  /// 可用的最新版本
  final String latestVersion;

  /// 最低要求版本
  final String minimumRequiredVersion;

  /// 该更新是否关键
  final bool isCritical;

  /// 最新版本的发布说明
  final String? releaseNotes;

  /// 更新应用的 URL（商店 URL）
  final String? updateUrl;

  /// 创建更新信息
  const UpdateInfo({
    required this.latestVersion,
    required this.minimumRequiredVersion,
    required this.isCritical,
    this.releaseNotes,
    this.updateUrl,
  });

  /// 使用给定字段替换创建此更新信息的副本
  UpdateInfo copyWith({
    String? latestVersion,
    String? minimumRequiredVersion,
    bool? isCritical,
    String? releaseNotes,
    String? updateUrl,
  }) {
    return UpdateInfo(
      latestVersion: latestVersion ?? this.latestVersion,
      minimumRequiredVersion:
          minimumRequiredVersion ?? this.minimumRequiredVersion,
      isCritical: isCritical ?? this.isCritical,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      updateUrl: updateUrl ?? this.updateUrl,
    );
  }
}

/// 应用更新服务的接口
abstract class UpdateService {
  /// 检查是否有可用更新
  Future<UpdateCheckResult> checkForUpdates();

  /// 获取可用更新的信息
  Future<UpdateInfo?> getUpdateInfo();

  /// 提示用户更新应用
  Future<bool> promptUpdate({bool force = false});

  /// 打开应用商店以更新应用
  Future<bool> openUpdateUrl();

  /// 初始化更新服务。幂等，重复调用不再读 `PackageInfo`。
  Future<void> init();

  /// 当前安装的版本号（如 `1.0.0`）。未初始化时回退到 `AppConstants.appVersion`。
  String get currentVersion;

  /// 比较版本字符串以判断是否需要更新
  bool isUpdateNeeded(String currentVersion, String latestVersion);

  /// 判断更新是否关键
  bool isCriticalUpdate(String currentVersion, String minimumRequired);
}

/// 更新服务实现：最新版本读 GitHub Release（`.../releases/latest`）。
///
/// 应用未上架任何应用商店，故没有商店版本号可比对；Release 的 `html_url`
/// 就是下载页，用户自行取用安装包。
class BasicUpdateService implements UpdateService {
  final Dio _dio;

  PackageInfo? _packageInfo;
  UpdateInfo? _updateInfo;

  /// [installedPackageInfo] 供测试注入，生产不传（走 `PackageInfo.fromPlatform`）。
  BasicUpdateService({required Dio dio, PackageInfo? installedPackageInfo})
    : _dio = dio,
      _packageInfo = installedPackageInfo;

  @override
  Future<void> init() async {
    if (_packageInfo != null) return;
    _packageInfo = await PackageInfo.fromPlatform();
    debugPrint(
      '⬆️ Update service initialized: v${_packageInfo?.version}+${_packageInfo?.buildNumber}',
    );
  }

  @override
  String get currentVersion => _packageInfo?.version ?? AppConstants.appVersion;

  @override
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      // 确保已初始化
      if (_packageInfo == null) {
        await init();
      }

      _updateInfo = await _fetchUpdateInfo();

      // 检查是否需要更新
      if (_updateInfo == null) {
        return UpdateCheckResult.checkFailed;
      }

      // 检查这是否是关键更新
      if (isCriticalUpdate(
        _packageInfo!.version,
        _updateInfo!.minimumRequiredVersion,
      )) {
        return UpdateCheckResult.criticalUpdateRequired;
      }

      // 检查是否有可用更新
      if (isUpdateNeeded(_packageInfo!.version, _updateInfo!.latestVersion)) {
        return UpdateCheckResult.updateAvailable;
      }

      return UpdateCheckResult.upToDate;
    } catch (e) {
      debugPrint('⬆️ Update check failed: $e');
      return UpdateCheckResult.checkFailed;
    }
  }

  @override
  Future<UpdateInfo?> getUpdateInfo() async {
    if (_updateInfo == null) {
      await checkForUpdates();
    }
    return _updateInfo;
  }

  @override
  Future<bool> promptUpdate({bool force = false}) async {
    // 确保我们有更新信息
    final updateInfo = await getUpdateInfo();
    if (updateInfo == null) {
      return false;
    }

    debugPrint(
      '⬆️ Prompting for update to version ${updateInfo.latestVersion} '
      '(current: ${_packageInfo?.version})',
    );

    // 在真实应用中，这里会向用户显示对话框
    // 若用户同意更新则返回 true
    return true;
  }

  @override
  Future<bool> openUpdateUrl() async {
    try {
      final updateInfo = await getUpdateInfo();
      // 没有 release 信息时退到仓库的 Release 列表页。
      return await _launchUrl(
        updateInfo?.updateUrl ?? '${AppConstants.githubRepoUrl}/releases',
      );
    } catch (e) {
      debugPrint('⬆️ Failed to open update URL: $e');
      return false;
    }
  }

  @override
  bool isUpdateNeeded(String currentVersion, String latestVersion) {
    // 比较语义化版本
    // 这是一个简化的版本，仅比较 major.minor.patch
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      // 比较主版本号
      if (latest[0] > current[0]) return true;
      if (latest[0] < current[0]) return false;

      // 比较次版本号
      if (latest[1] > current[1]) return true;
      if (latest[1] < current[1]) return false;

      // 比较修订版本号
      return latest[2] > current[2];
    } catch (e) {
      debugPrint('⬆️ Version comparison error: $e');
      return false;
    }
  }

  @override
  bool isCriticalUpdate(String currentVersion, String minimumRequired) {
    try {
      final current = _parseVersion(currentVersion);
      final minimum = _parseVersion(minimumRequired);

      // 如果当前版本低于最低要求版本，则为关键更新
      if (current[0] < minimum[0]) return true;
      if (current[0] > minimum[0]) return false;

      if (current[1] < minimum[1]) return true;
      if (current[1] > minimum[1]) return false;

      return current[2] < minimum[2];
    } catch (e) {
      debugPrint('⬆️ Critical update check error: $e');
      return false;
    }
  }

  // 辅助方法：将 "1.2.3" / "v1.2.3" / "1.2" 解析为整数列表 [1, 2, 3]
  List<int> _parseVersion(String version) {
    // Release tag 通常带 `v` 前缀，不剥掉会被下面的取数正则读成 0。
    final parts = version.trim().replaceFirst(RegExp(r'^[vV]'), '').split('.');
    // 不足三段补 0（`1.2` → `1.2.0`）；超过三段的部分不参与比较。
    while (parts.length < 3) {
      parts.add('0');
    }

    return parts.take(3).map((part) {
      // 移除任何非数字后缀
      final match = RegExp(r'^\d+').firstMatch(part);
      final digitPart = match != null ? match.group(0) : '0';
      return int.tryParse(digitPart ?? '0') ?? 0;
    }).toList();
  }

  // 打开 URL 的辅助方法
  Future<bool> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      return await launchUrl(Uri.parse(url));
    }
    return false;
  }

  /// 从 GitHub 拉最新 Release。`tag_name` 是版本号真源，`html_url` 是下载页。
  ///
  /// 未认证调用限 60 次/小时/IP，超限（403/429）由 Dio 抛错，
  /// `checkForUpdates` 统一兜成 [UpdateCheckResult.checkFailed]。
  Future<UpdateInfo> _fetchUpdateInfo() async {
    final response = await _dio.get<dynamic>(
      AppConstants.githubLatestReleaseApiUrl,
      options: Options(
        headers: <String, String>{
          // GitHub API 要求带 User-Agent，否则 403。
          'User-Agent': AppConstants.appName,
          'Accept': 'application/vnd.github+json',
        },
      ),
    );

    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Release payload is not a map');
    }

    final latest = data['tag_name'] as String? ?? '';
    if (latest.isEmpty) {
      throw const FormatException('Release has no tag_name');
    }

    return UpdateInfo(
      latestVersion: latest,
      // GitHub Release 没有「最低要求版本」概念：填当前版本让
      // `isCriticalUpdate` 恒为 false（填 latest 会让它恒为 true，
      // 有新版时反而永远走 `criticalUpdateRequired`）。
      minimumRequiredVersion: currentVersion,
      isCritical: false,
      releaseNotes: data['body'] as String?,
      updateUrl: data['html_url'] as String?,
    );
  }
}
