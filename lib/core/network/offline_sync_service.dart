import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

/// 同步操作的状态
enum SyncStatus {
  /// 等待同步
  pending,

  /// 正在同步
  syncing,

  /// 已成功同步
  synced,

  /// 同步失败
  failed,

  /// 检测到同步冲突
  conflict,

  /// 已取消同步
  canceled,
}

/// 离线更改的操作类型
enum OfflineOperationType {
  /// 创建操作
  create,

  /// 更新操作
  update,

  /// 删除操作
  delete,

  /// 自定义操作
  custom,
}

/// 表示需要同步的离线更改
class OfflineChange {
  /// 此更改的唯一标识符
  final String id;

  /// 实体类型（例如 "user"、"post"、"comment"）
  final String entityType;

  /// 实体 ID（对于创建操作可以为 null）
  final String? entityId;

  /// 操作类型
  final OfflineOperationType operationType;

  /// 要同步的数据（对于删除操作可以为 null）
  final Map<String, dynamic>? data;

  /// 同步操作的状态
  final SyncStatus status;

  /// 更改创建时的时间戳
  final DateTime timestamp;

  /// 重试尝试次数
  final int retryCount;

  /// 上次重试尝试的时间
  final DateTime? lastRetryTime;

  /// 同步失败时的错误消息
  final String? errorMessage;

  /// 创建离线更改
  const OfflineChange({
    required this.id,
    required this.entityType,
    this.entityId,
    required this.operationType,
    this.data,
    required this.status,
    required this.timestamp,
    this.retryCount = 0,
    this.lastRetryTime,
    this.errorMessage,
  });

  /// 转换为 JSON 对象
  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'operationType': operationType.toString().split('.').last,
    'data': data,
    'status': status.toString().split('.').last,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
    'lastRetryTime': lastRetryTime?.toIso8601String(),
    'errorMessage': errorMessage,
  };

  /// 从 JSON 对象创建
  factory OfflineChange.fromJson(Map<String, dynamic> json) {
    return OfflineChange(
      id: json['id'],
      entityType: json['entityType'],
      entityId: json['entityId'],
      operationType: _parseOperationType(json['operationType']),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      status: _parseSyncStatus(json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      lastRetryTime: json['lastRetryTime'] != null
          ? DateTime.parse(json['lastRetryTime'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }

  /// 使用更新后的字段创建副本
  OfflineChange copyWith({
    String? id,
    String? entityType,
    String? entityId,
    OfflineOperationType? operationType,
    Map<String, dynamic>? data,
    SyncStatus? status,
    DateTime? timestamp,
    int? retryCount,
    DateTime? lastRetryTime,
    String? errorMessage,
  }) {
    return OfflineChange(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      data: data ?? this.data,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      lastRetryTime: lastRetryTime ?? this.lastRetryTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static OfflineOperationType _parseOperationType(String value) {
    switch (value) {
      case 'create':
        return OfflineOperationType.create;
      case 'update':
        return OfflineOperationType.update;
      case 'delete':
        return OfflineOperationType.delete;
      default:
        return OfflineOperationType.custom;
    }
  }

  static SyncStatus _parseSyncStatus(String value) {
    switch (value) {
      case 'pending':
        return SyncStatus.pending;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      case 'conflict':
        return SyncStatus.conflict;
      case 'canceled':
        return SyncStatus.canceled;
      default:
        return SyncStatus.pending;
    }
  }
}

/// 冲突解决策略的接口
abstract class ConflictResolutionStrategy {
  /// 解决本地与远程更改之间的冲突
  Future<Map<String, dynamic>> resolveConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic>? localData,
    required Map<String, dynamic>? remoteData,
    required OfflineOperationType operationType,
  });
}

/// 客户端胜出的冲突解决策略（客户端数据覆盖服务器）
class ClientWinsStrategy implements ConflictResolutionStrategy {
  @override
  Future<Map<String, dynamic>> resolveConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic>? localData,
    required Map<String, dynamic>? remoteData,
    required OfflineOperationType operationType,
  }) async {
    // 始终使用本地数据
    return localData ?? {};
  }
}

/// 服务器胜出的冲突解决策略（服务器数据覆盖客户端）
class ServerWinsStrategy implements ConflictResolutionStrategy {
  @override
  Future<Map<String, dynamic>> resolveConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic>? localData,
    required Map<String, dynamic>? remoteData,
    required OfflineOperationType operationType,
  }) async {
    // 始终使用远程数据
    return remoteData ?? {};
  }
}

/// 智能合并冲突解决策略（智能合并字段）
class SmartMergeStrategy implements ConflictResolutionStrategy {
  final Map<String, bool> _fieldPriorities;

  /// 使用字段优先级创建智能合并策略
  /// （true 表示该字段客户端胜出，false 表示服务器胜出）
  SmartMergeStrategy(this._fieldPriorities);

  @override
  Future<Map<String, dynamic>> resolveConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic>? localData,
    required Map<String, dynamic>? remoteData,
    required OfflineOperationType operationType,
  }) async {
    // 如果任一数据为 null，则返回非 null 的那个
    if (localData == null) return remoteData ?? {};
    if (remoteData == null) return localData;

    // 以远程数据为基础开始
    final result = Map<String, dynamic>.from(remoteData);

    // 根据字段优先级应用本地更改
    localData.forEach((key, value) {
      final clientWins = _fieldPriorities[key] ?? false;
      if (clientWins) {
        result[key] = value;
      }
    });

    return result;
  }
}

/// 同步离线更改的接口
abstract class OfflineSyncService {
  /// 将离线更改加入队列
  Future<OfflineChange> queueChange({
    required String entityType,
    String? entityId,
    required OfflineOperationType operationType,
    Map<String, dynamic>? data,
  });

  /// 开始同步待处理的更改
  Future<void> syncChanges();

  /// 获取实体的同步状态
  Future<SyncStatus?> getSyncStatus(String entityType, String entityId);

  /// 获取所有待处理的更改
  Future<List<OfflineChange>> getPendingChanges();

  /// 处理同步冲突
  Future<void> resolveConflict(
    String changeId,
    Map<String, dynamic> resolvedData,
  );

  /// 监听同步状态更改
  Stream<List<OfflineChange>> get syncStatusStream;

  /// 检查设备是否在线
  Future<bool> isOnline();

  /// 初始化同步服务
  Future<void> init();
}

/// 离线同步服务的实现
class SharedPreferencesOfflineSyncService implements OfflineSyncService {
  final SharedPreferences _prefs;
  final Connectivity _connectivity;
  final Lock _syncLock = Lock();

  final _uuid = const Uuid();
  final _syncController = StreamController<List<OfflineChange>>.broadcast();
  bool _isSyncing = false;

  static const String _keyPrefix = '${AppConstants.offlineSyncBox}:';

  /// 创建基于 SharedPreferences 的离线同步服务
  SharedPreferencesOfflineSyncService({
    required SharedPreferences prefs,
    required Connectivity connectivity,
    ConflictResolutionStrategy? conflictStrategy,
  }) : _prefs = prefs,
       _connectivity = connectivity;

  /// 将更改 ID 映射为存储键
  String _keyFor(String id) => '$_keyPrefix$id';

  @override
  Future<void> init() async {
    // 设置连通性监听器以实现自动同步
    _connectivity.onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        syncChanges();
      }
    });

    debugPrint('🔄 Offline sync service initialized');
  }

  @override
  Future<OfflineChange> queueChange({
    required String entityType,
    String? entityId,
    required OfflineOperationType operationType,
    Map<String, dynamic>? data,
  }) async {
    final id = _uuid.v4();
    final change = OfflineChange(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      data: data,
      status: SyncStatus.pending,
      timestamp: DateTime.now(),
    );

    // 存储更改
    await _prefs.setString(_keyFor(id), jsonEncode(change.toJson()));

    // 通知监听器
    _notifyListeners();

    // 如果在线则立即尝试同步
    if (await isOnline()) {
      syncChanges();
    }

    return change;
  }

  @override
  Future<void> syncChanges() async {
    // 防止同时进行多个同步尝试
    if (_isSyncing) return;

    // 检查连通性
    if (!await isOnline()) return;

    // 使用锁防止并发的同步操作
    await _syncLock.synchronized(() async {
      _isSyncing = true;

      // 通知监听器同步已开始
      _notifyListeners();

      try {
        // 获取所有待处理的更改
        final pendingChanges = await getPendingChanges().then(
          (changes) =>
              changes.where((c) => c.status == SyncStatus.pending).toList(),
        );

        // 按时间戳排序（最早的在前）
        pendingChanges.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // 处理每个更改
        for (final change in pendingChanges) {
          await _processChange(change);
        }
      } finally {
        _isSyncing = false;

        // 通知监听器同步已完成
        _notifyListeners();
      }
    });
  }

  Future<void> _processChange(OfflineChange change) async {
    // 标记为同步中
    final syncingChange = change.copyWith(status: SyncStatus.syncing);
    await _prefs.setString(_keyFor(change.id), jsonEncode(syncingChange.toJson()));
    _notifyListeners();

    try {
      // 在真实应用中，这里会调用你的 API
      // 目前，我们模拟延迟后的成功同步
      await Future.delayed(const Duration(milliseconds: 500));

      // 标记为已同步
      final syncedChange = syncingChange.copyWith(status: SyncStatus.synced);
      await _prefs.setString(_keyFor(change.id), jsonEncode(syncedChange.toJson()));
    } catch (e) {
      // 处理失败
      final failedChange = syncingChange.copyWith(
        status: SyncStatus.failed,
        retryCount: change.retryCount + 1,
        lastRetryTime: DateTime.now(),
        errorMessage: e.toString(),
      );
      await _prefs.setString(
        _keyFor(change.id),
        jsonEncode(failedChange.toJson()),
      );
    }

    // 通知监听器
    _notifyListeners();
  }

  @override
  Future<SyncStatus?> getSyncStatus(String entityType, String entityId) async {
    // 查找此实体的最新更改
    final changes = await getPendingChanges();
    final entityChanges = changes
        .where((c) => c.entityType == entityType && c.entityId == entityId)
        .toList();

    if (entityChanges.isEmpty) return null;

    // 按时间戳排序（最近的在前）
    entityChanges.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return entityChanges.first.status;
  }

  @override
  Future<List<OfflineChange>> getPendingChanges() async {
    final changes = <OfflineChange>[];

    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_keyPrefix)) {
        continue;
      }
      final json = _prefs.getString(key);
      if (json != null) {
        try {
          final change = OfflineChange.fromJson(jsonDecode(json));
          changes.add(change);
        } catch (e) {
          debugPrint('🔄 Error parsing change: $e');
        }
      }
    }

    return changes;
  }

  @override
  Future<void> resolveConflict(
    String changeId,
    Map<String, dynamic> resolvedData,
  ) async {
    // 获取原始更改
    final json = _prefs.getString(_keyFor(changeId));
    if (json == null) return;

    final change = OfflineChange.fromJson(jsonDecode(json));

    // 使用已解决的数据进行更新
    final resolvedChange = change.copyWith(
      data: resolvedData,
      status: SyncStatus.pending, // 重置为待处理状态以再次尝试同步
    );

    await _prefs.setString(
      _keyFor(changeId),
      jsonEncode(resolvedChange.toJson()),
    );

    // 通知监听器
    _notifyListeners();

    // 再次尝试同步
    syncChanges();
  }

  @override
  Stream<List<OfflineChange>> get syncStatusStream => _syncController.stream;

  void _notifyListeners() async {
    final changes = await getPendingChanges();
    _syncController.add(changes);
  }

  @override
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}

/// 用于跟踪同步状态的 StreamController
class StreamController<T> {
  final List<void Function(T)> _listeners = [];

  /// 创建广播流控制器
  StreamController.broadcast();

  /// 向流中添加一个值
  void add(T value) {
    for (final listener in _listeners) {
      listener(value);
    }
  }

  /// 获取该流
  Stream<T> get stream =>
      Stream<T>.periodic(const Duration(days: 365), (_) {
          throw UnimplementedError('This is a mock stream for demo purposes');
        }).asBroadcastStream()
        ..listen((event) {}, onDone: () {}, onError: (error, stack) {});
}
