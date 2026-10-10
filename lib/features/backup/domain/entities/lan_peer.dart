import 'package:equatable/equatable.dart';

/// 广播信标的协议标识。收信标时先比这个，不是本 App 的包一律忽略
/// （同一个局域网里可能有别的 App 在用 UDP 广播）。
const String kLanBeaconApp = 'mynote';

/// 信标协议版本。报文结构变了才动它 —— 解析时**不**据此拒绝（只解析认识的字段），
/// 因为同版本的两台设备必然兼容，而跨版本拒绝会让用户看到「明明在线却搜不到」。
const int kLanBeaconVersion = 1;

/// UDP 发现端口（固定）。与 HTTP 同步端口分开 —— 发现是持续的小包，同步是一次
/// 的大包，混在一个端口上会让大包阻塞信标。
///
/// ⚠️ 固定端口意味着「同一个局域网里只能有一个 MyNote 实例对外可见」—— 实际上
/// 无所谓：多台设备各自绑定同一端口时，`reuseAddress` 让广播都能收到，各自在
/// 信标里报自己的 HTTP 端口，收信标的一侧按 `address` 区分。
const int kLanDiscoveryPort = 47653;

/// 信标的广播周期。2 秒是权衡：更短费电且刷屏，更长则用户点完「刷新」要干等。
const Duration kLanBeaconInterval = Duration(seconds: 2);

/// 超过这个时长没再收到对端信标，就把它从列表里移除。
///
/// 取 [kLanBeaconInterval] 的 4 倍：对端最多能漏 3 个包而不被误判为掉线。
const Duration kLanPeerTimeout = Duration(seconds: 8);

/// 局域网里发现到的一台设备。
class LanPeer extends Equatable {
  const LanPeer({
    required this.address,
    required this.port,
    required this.name,
    required this.lastSeen,
  });

  /// 对端 IP。由信标的**来源地址**给出，所以不需要额外的 DNS 解析
  /// （`.local` 名字在很多网络里解析不了）。
  final String address;

  /// 对端的 HTTP 同步端口（随机端口，每次开启服务都会变，所以必须在信标里带）。
  final int port;

  /// 对端显示名。只是给用户辨认用的，**不参与任何身份判定**（无口令）。
  final String name;

  /// 最近一次收到它信标的时刻。用于算超时。
  final DateTime lastSeen;

  /// 用户可读的一行：`192.168.1.23 · 客厅的 iPhone`。
  String get label => '$address · $name';

  LanPeer copyWith({DateTime? lastSeen}) => LanPeer(
    address: address,
    port: port,
    name: name,
    lastSeen: lastSeen ?? this.lastSeen,
  );

  Map<String, Object?> toBeacon() => <String, Object?>{
    'app': kLanBeaconApp,
    'version': kLanBeaconVersion,
    'name': name,
    'port': port,
  };

  /// 解析信标。**不是本 App 的 / 结构不对 → `null`**（静默忽略，不报错 ——
  /// 局域网里别人的广播包不是错误）。
  static LanPeer? fromBeacon(
    Map<String, Object?> json,
    String address,
    DateTime now,
  ) {
    if (json['app'] != kLanBeaconApp) return null;
    final port = json['port'];
    if (port is! int || port <= 0 || port > 65535) return null;

    return LanPeer(
      address: address,
      port: port,
      name: json['name'] is String ? json['name']! as String : address,
      lastSeen: now,
    );
  }

  @override
  List<Object?> get props => <Object?>[address, port, name, lastSeen];
}

/// `POST /sync` 的请求体。
///
/// ⚠️ `clientTime` 不是装饰 —— 它是对时的**第一个采样点**。服务端回 `serverTime`
/// 后，客户端凑齐 t0/t1/t2 三个采样，用 NTP 式算法算偏差（见 `lan_client`）。
class LanSyncRequest {
  const LanSyncRequest({required this.snapshot, required this.clientTime});

  /// 发起方的全量快照（`BackupSnapshot` 的 JSON 对象）。
  final Map<String, Object?> snapshot;

  /// 发起方发出请求的时刻。
  final DateTime clientTime;

  Map<String, Object?> toJson() => <String, Object?>{
    'snapshot': snapshot,
    'clientTime': clientTime.toIso8601String(),
  };
}

/// `POST /sync` 的响应体：合并后的快照 + 服务端时刻。
class LanSyncResponse {
  const LanSyncResponse({required this.snapshot, required this.serverTime});

  /// 双方合并的结果。**两端写同一份** → 一次往返即收敛。
  final Map<String, Object?> snapshot;

  /// 服务端处理请求的时刻（= 对时的 t1）。
  final DateTime serverTime;

  Map<String, Object?> toJson() => <String, Object?>{
    'snapshot': snapshot,
    'serverTime': serverTime.toIso8601String(),
  };
}