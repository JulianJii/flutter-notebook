import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mynote/features/backup/domain/entities/lan_peer.dart';

/// 局域网设备发现：UDP 广播信标。
///
/// **为什么是 UDP 广播而不是 mDNS**：`multicast_dns` 只会「查」不会「发布」——
/// 它的 `lib/src/` 里只有 `encodeMDnsQuery` / `decodeMDnsResponse`，**没有任何应答
/// 编码器**，`MDnsClient` 也没有注册服务的 API（源码里留着
/// `// TODO: Support queries coming in for published entries.`）。要真用 mDNS，A 机
/// 得手写 DNS 应答包（PTR + SRV + TXT + A，还要处理 cache-flush 位与 name 压缩，
/// 约 120 行线格式），外加 Android 的 `CHANGE_WIFI_MULTICAST_STATE` 与 iOS 的
/// `NSBonjourServices`，而组播在公司 WiFi / 访客网络 / Android 省电模式下照样不通。
///
/// 广播信标纯 `dart:io`，两端各约 30 行，零新依赖。
/// ⚠️ 代价：**广播被路由器丢弃时搜不到设备**。所以 UI 同时保留「手输 IP」入口 ——
/// 见「已知限制」。
///
/// ⛔ 不 import Flutter（本文件被 data 层直接用）。
class LanDiscovery {
  LanDiscovery({this.deviceName = ''});

  /// 本机在信标里的显示名。空则用 IP（见 `LanPeer.fromBeacon` 的回落）。
  final String deviceName;

  RawDatagramSocket? _sender;
  RawDatagramSocket? _listener;
  Timer? _timer;
  final Map<String, LanPeer> _peers = <String, LanPeer>{};
  final StreamController<List<LanPeer>> _controller =
      StreamController<List<LanPeer>>.broadcast();

  /// 本机的 IPv4 地址，用来把**自己收到自己的广播**滤掉。
  ///
  /// 在 [start] 时取一次而不是每次收包都取：`NetworkInterface.list` 是系统调用，
  /// 每个包查一次会在信标密集时白烧 CPU。网卡热插拔后取不到新值 —— 代价只是
  /// 「换了网络后可能要重启本机服务才能被搜到」，可接受。
  List<String> _selfAddresses = const <String>[];

  /// 发现的设备流。**已经在听的订阅者会立刻拿到当前已知列表**。
  Stream<List<LanPeer>> get peers => _controller.stream;

  /// 本机对外提供的 HTTP 端口（由 `LanServer` 绑定后填进来，写进信标）。
  int advertisedPort = 0;

  bool get isListening => _listener != null;

  /// 开始广播 + 监听。已在跑时幂等返回。
  ///
  /// [advertisedPort] 为 0 时**只监听不广播**（服务还没起来，广播出去也没用）。
  Future<void> start({int? advertisedPort}) async {
    if (advertisedPort != null) this.advertisedPort = advertisedPort;
    if (_listener != null) return;

    try {
      _selfAddresses = await _resolveSelfAddresses();
      _listener = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kLanDiscoveryPort,
        reuseAddress: true,
      );
      _listener!.broadcastEnabled = true;
      _listener!.listen(
        (event) {
          // `RawDatagramSocket.listen` 给的是「有事发生」，数据要自己 receive ——
          // 它不是 `Stream<Datagram>`。
          if (event != RawSocketEvent.read) return;
          final datagram = _listener?.receive();
          if (datagram != null) _onDatagram(datagram);
        },
        onError: (Object _) {},
        cancelOnError: false,
      );
    } on SocketException {
      // ⚠️ 端口被别的进程占着 → 搜不到设备，但「手输 IP」那条路仍然可用。
      // 不抛：发现失败不该让整个「局域网同步」功能不可用。
      _listener = null;
      return;
    }

    await _startBroadcasting();
    _timer = Timer.periodic(kLanBeaconInterval, (_) => _broadcast());
    _emit();
  }

  Future<void> _startBroadcasting() async {
    // 发送端用**随机端口**：与监听端口解耦，省得同一个 socket 既发又收。
    _sender = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _sender!.broadcastEnabled = true;
  }

  /// 手动加一台设备（手输 IP 的入口）。绕过发现直接把它加进列表。
  void addManualPeer(String address, String name) {
    final peer = LanPeer(
      address: address,
      port: advertisedPort == 0 ? 0 : advertisedPort,
      name: name,
      lastSeen: DateTime.now(),
    );
    _peers['${peer.address}:${peer.port}'] = peer;
    _emit();
  }

  /// 停掉广播与监听。⚠️ 必须调 —— 否则 UDP socket 会一直占着端口，
  /// 且 `StreamController` 不关会导致监听它的 widget 泄漏。
  ///
  /// ⚠️ `RawDatagramSocket.close()` 返回 **void**（不是 Future）—— 关 socket
  /// 是同步动作，没有「等它关完」的必要，`await` 一个 void 会编译不过。
  void stop() {
    _timer?.cancel();
    _timer = null;
    _sender?.close();
    _sender = null;
    _listener?.close();
    _listener = null;
    _peers.clear();
    _emit();
  }

  void dispose() {
    _controller.close();
  }

  void _broadcast() {
    final socket = _sender;
    if (socket == null || advertisedPort == 0) return;
    final payload = utf8.encode(
      jsonEncode(
        LanPeer(
          address: '',
          port: advertisedPort,
          name: deviceName,
          lastSeen: DateTime.now(),
        ).toBeacon(),
      ),
    );
    try {
      socket.send(
        payload,
        InternetAddress('255.255.255.255', type: InternetAddressType.IPv4),
        kLanDiscoveryPort,
      );
    } on SocketException {
      // 网络刚断之类 —— 等下一个周期。
    }
  }

  void _onDatagram(Datagram datagram) {
    final now = DateTime.now();
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(datagram.data));
    } catch (_) {
      return; // 不是我们的包（或根本不是 JSON），静默忽略。
    }
    if (decoded is! Map) return;

    final peer = LanPeer.fromBeacon(
      decoded.cast<String, Object?>(),
      datagram.address.address,
      now,
    );
    // 本机也会收到自己的广播（loopback），滤掉。
    if (peer == null || _isSelf(peer.address)) return;

    _peers['${peer.address}:${peer.port}'] = peer;
    _evictStale(now);
    _emit();
  }

  /// 本机所有 IPv4 地址都算「自己」。只比 `datagram.address` 不够 ——
  /// 某些系统下从 `anyIPv4` 收到的是未绑定具体地址的形式。
  bool _isSelf(String address) => _selfAddresses.contains(address);

  Future<List<String>> _resolveSelfAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return interfaces
          .expand((i) => i.addresses)
          .map((a) => a.address)
          .toList(growable: false);
    } on SocketException {
      // 拿不到网卡列表时**不做过滤**：宁可把自己列出来，也不要漏掉真设备。
      return const <String>[];
    }
  }

  void _evictStale(DateTime now) {
    _peers.removeWhere(
      (_, peer) => now.difference(peer.lastSeen) > kLanPeerTimeout,
    );
  }

  void _emit() {
    if (_controller.isClosed) return;
    final list = _peers.values.toList()
      ..sort((a, b) => a.address.compareTo(b.address));
    _controller.add(list);
  }
}