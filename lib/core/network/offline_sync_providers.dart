import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/network/offline_sync_service.dart';
import 'package:init/core/providers/storage_providers.dart';

/// 连通性服务的 Provider
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// 冲突解决策略的 Provider
final conflictResolutionStrategyProvider = Provider<ConflictResolutionStrategy>(
  (ref) {
    // 使用带字段优先级的智能合并策略
    return SmartMergeStrategy({
      'id': false, // 服务器胜出
      'createdAt': false, // 服务器在创建时间戳上胜出
      'updatedAt': true, // 客户端在更新时间戳上胜出
      // 根据需要添加更多字段优先级
    });
  },
);

/// 离线同步服务的 Provider
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final connectivity = ref.watch(connectivityProvider);
  final conflictStrategy = ref.watch(conflictResolutionStrategyProvider);

  final service = SharedPreferencesOfflineSyncService(
    prefs: prefs,
    connectivity: connectivity,
    conflictStrategy: conflictStrategy,
  );

  // 初始化服务
  service.init();

  return service;
});

/// 待处理更改的 Provider
final pendingChangesProvider = StreamProvider<List<OfflineChange>>((ref) {
  final offlineSyncService = ref.watch(offlineSyncServiceProvider);
  return offlineSyncService.syncStatusStream;
});

/// 在线状态的 Provider
final isOnlineProvider = FutureProvider.autoDispose<bool>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  final connectivityResult = await connectivity.checkConnectivity();
  return !connectivityResult.contains(ConnectivityResult.none);
});

/// 显示离线状态和同步状态的 widget
class OfflineStatusIndicator extends ConsumerWidget {
  /// 创建离线状态指示器
  const OfflineStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final pendingChangesAsync = ref.watch(pendingChangesProvider);

    return isOnlineAsync.when(
      data: (isOnline) {
        return pendingChangesAsync.when(
          data: (pendingChanges) {
            final hasPending = pendingChanges.any(
              (c) => c.status == SyncStatus.pending,
            );
            final hasSyncing = pendingChanges.any(
              (c) => c.status == SyncStatus.syncing,
            );
            final hasFailed = pendingChanges.any(
              (c) => c.status == SyncStatus.failed,
            );

            if (!isOnline) {
              return _buildIndicator(Icons.cloud_off, 'Offline', Colors.orange);
            } else if (hasSyncing) {
              return _buildIndicator(
                Icons.sync,
                'Syncing',
                Colors.blue,
                isAnimated: true,
              );
            } else if (hasFailed) {
              return _buildIndicator(
                Icons.error_outline,
                'Sync errors',
                Colors.red,
              );
            } else if (hasPending) {
              return _buildIndicator(
                Icons.pending_outlined,
                'Changes pending',
                Colors.orange,
              );
            } else {
              return _buildIndicator(
                Icons.cloud_done,
                'All synced',
                Colors.green,
              );
            }
          },
          loading: () => _buildIndicator(
            Icons.sync,
            'Checking sync',
            Colors.blue,
            isAnimated: true,
          ),
          error: (error, stack) =>
              _buildIndicator(Icons.cloud_off, 'Sync error', Colors.red),
        );
      },
      loading: () => _buildIndicator(
        Icons.cloud_queue,
        'Checking connection',
        Colors.grey,
      ),
      error: (error, stack) =>
          _buildIndicator(Icons.cloud_off, 'Connection error', Colors.red),
    );
  }

  Widget _buildIndicator(
    IconData icon,
    String message,
    Color color, {
    bool isAnimated = false,
  }) {
    return Tooltip(
      message: message,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnimated)
            RotatingIcon(icon: icon, color: color)
          else
            Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(message, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

/// 持续旋转的图标
class RotatingIcon extends StatefulWidget {
  /// 要显示的图标
  final IconData icon;

  /// 图标的颜色
  final Color color;

  /// 创建旋转图标
  const RotatingIcon({super.key, required this.icon, required this.color});

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: 16),
    );
  }
}
