import 'package:equatable/equatable.dart';

/// WebDAV 服务器配置。
///
/// ⛔ **不并进 `AppSettings`**：那是「App 长什么样、怎么排序」的偏好，本类是
/// 「数据搬到哪去」的凭据。混进一个实体会让每次改字号都重写一遍密码。
///
/// ⚠️ 密码明文落 SharedPreferences：本 App 无账号体系、无后端，设备本地存储
/// 已被系统沙箱保护；为它引入 keychain / 加密是给一个本地 App 上锁自己的门
/// （同见 `docs/FEATURES.md`「已知限制」）。
class WebDavConfig extends Equatable {
  const WebDavConfig({
    this.url = '',
    this.username = '',
    this.password = '',
    this.remoteFile = kDefaultRemoteFile,
    this.autoSyncOnStart = false,
    this.lastSyncAt,
  });

  /// 默认远端文件名。单文件快照 —— 不做目录、不做多版本，够用且不会留垃圾。
  static const String kDefaultRemoteFile = 'notebook.json';

  /// 服务器 / 目录地址，如 `https://dav.example.com/remote.php/dav/files/me/`。
  final String url;

  final String username;

  final String password;

  /// 远端文件名，挂在 [url] 下。
  final String remoteFile;

  /// App 启动时自动同步一次。
  final bool autoSyncOnStart;

  final DateTime? lastSyncAt;

  /// 地址非空即算「已配置」—— 用户名为空是匿名 WebDAV 的合法形态。
  bool get isConfigured => url.trim().isNotEmpty;

  WebDavConfig copyWith({
    String? url,
    String? username,
    String? password,
    String? remoteFile,
    bool? autoSyncOnStart,
    DateTime? lastSyncAt,
  }) {
    return WebDavConfig(
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      remoteFile: remoteFile ?? this.remoteFile,
      autoSyncOnStart: autoSyncOnStart ?? this.autoSyncOnStart,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    url,
    username,
    password,
    remoteFile,
    autoSyncOnStart,
    lastSyncAt,
  ];
}
