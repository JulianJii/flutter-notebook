import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:init/core/feature_flags/feature_flag_service.dart';

/// 使用远程配置的功能开关服务实现
/// 在真实应用中，这会使用 Firebase Remote Config 或类似的服务
class RemoteFeatureFlagService extends FeatureFlagService {
  final Map<String, dynamic> _defaultValues = {};
  final Map<String, dynamic> _remoteValues = {};
  final List<VoidCallback> _listeners = [];
  bool _initialized = false;
  Timer? _fetchTimer;

  @override
  Future<void> init() async {
    // 在真实实现中，这里会初始化 Firebase Remote Config
    debugPrint('🚩 RemoteFeatureFlagService initializing...');

    // 模拟远程配置初始化延迟
    await Future.delayed(const Duration(seconds: 1));

    // 设置默认拉取超时时间
    _setFetchTimeout(const Duration(hours: 12));

    // 设置最小拉取间隔
    _setMinimumFetchInterval(const Duration(hours: 1));

    _initialized = true;
    debugPrint('🚩 RemoteFeatureFlagService initialized');

    // 拉取初始值
    await fetchAndActivate();

    // 在后台设置周期性拉取
    _setupPeriodicFetching();

    return;
  }

  /// 设置远程值的自动周期性拉取
  void _setupPeriodicFetching() {
    _fetchTimer?.cancel();
    _fetchTimer = Timer.periodic(const Duration(hours: 12), (_) {
      fetchAndActivate();
    });
  }

  /// 设置拉取操作的超时时间
  void _setFetchTimeout(Duration timeout) {
    // 在真实实现中，这里会配置 Firebase Remote Config
    debugPrint(
      '🚩 RemoteFeatureFlagService: Set fetch timeout to ${timeout.inSeconds} seconds',
    );
  }

  /// 设置拉取操作之间的最小间隔
  void _setMinimumFetchInterval(Duration interval) {
    // 在真实实现中，这里会配置 Firebase Remote Config
    debugPrint(
      '🚩 RemoteFeatureFlagService: Set minimum fetch interval to ${interval.inSeconds} seconds',
    );
  }

  @override
  bool isFeatureEnabled(String featureKey) {
    return getBool(featureKey, defaultValue: false);
  }

  @override
  String getString(String key, {required String defaultValue}) {
    final remoteValue = _remoteValues[key];
    if (remoteValue is String) {
      return remoteValue;
    }

    final defaultConfigValue = _defaultValues[key];
    if (defaultConfigValue is String) {
      return defaultConfigValue;
    }

    return defaultValue;
  }

  @override
  int getInt(String key, {required int defaultValue}) {
    final remoteValue = _remoteValues[key];
    if (remoteValue is int) {
      return remoteValue;
    } else if (remoteValue is String) {
      return int.tryParse(remoteValue) ?? defaultValue;
    }

    final defaultConfigValue = _defaultValues[key];
    if (defaultConfigValue is int) {
      return defaultConfigValue;
    } else if (defaultConfigValue is String) {
      return int.tryParse(defaultConfigValue) ?? defaultValue;
    }

    return defaultValue;
  }

  @override
  double getDouble(String key, {required double defaultValue}) {
    final remoteValue = _remoteValues[key];
    if (remoteValue is double) {
      return remoteValue;
    } else if (remoteValue is int) {
      return remoteValue.toDouble();
    } else if (remoteValue is String) {
      return double.tryParse(remoteValue) ?? defaultValue;
    }

    final defaultConfigValue = _defaultValues[key];
    if (defaultConfigValue is double) {
      return defaultConfigValue;
    } else if (defaultConfigValue is int) {
      return defaultConfigValue.toDouble();
    } else if (defaultConfigValue is String) {
      return double.tryParse(defaultConfigValue) ?? defaultValue;
    }

    return defaultValue;
  }

  @override
  bool getBool(String key, {required bool defaultValue}) {
    final remoteValue = _remoteValues[key];
    if (remoteValue is bool) {
      return remoteValue;
    } else if (remoteValue is String) {
      return remoteValue.toLowerCase() == 'true';
    } else if (remoteValue is num) {
      return remoteValue != 0;
    }

    final defaultConfigValue = _defaultValues[key];
    if (defaultConfigValue is bool) {
      return defaultConfigValue;
    } else if (defaultConfigValue is String) {
      return defaultConfigValue.toLowerCase() == 'true';
    } else if (defaultConfigValue is num) {
      return defaultConfigValue != 0;
    }

    return defaultValue;
  }

  @override
  Color getColor(String key, {required Color defaultValue}) {
    final value = getString(key, defaultValue: '');
    if (value.isEmpty) return defaultValue;

    if (value.startsWith('#')) {
      try {
        final hex = value.replaceFirst('#', '');
        final intValue = int.parse(hex, radix: 16);
        if (hex.length == 6) {
          return Color(0xFF000000 + intValue);
        } else if (hex.length == 8) {
          return Color(intValue);
        }
      } catch (e) {
        debugPrint('🚩 Error parsing color: $e');
      }
    }
    return defaultValue;
  }

  @override
  Future<void> fetchAndActivate() async {
    if (!_initialized) {
      await init();
    }

    debugPrint(
      '🚩 RemoteFeatureFlagService: Fetching remote configurations...',
    );

    // 在真实实现中，这里会从 Firebase Remote Config 拉取值
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));

    // 在真实场景中，我们会从远程服务获取这些值
    // 这里仅模拟一些值用于演示
    final Map<String, dynamic> fetchedValues = {
      'enable_dark_mode': true,
      'enable_push_notifications': true,
      'enable_analytics': true,
      'enable_biometric_login': true,
      'api_timeout_ms': 20000,
      'home_screen_layout': 'list', // 已从默认值 'grid' 更改
      'primary_color': '#FF4CAF50', // 已从默认的蓝色更改
    };

    // 更新我们缓存的远程值
    _remoteValues.addAll(fetchedValues);

    debugPrint('🚩 RemoteFeatureFlagService: Remote configs activated');
    debugPrint('🚩 Fetched values: $_remoteValues');

    _notifyListeners();
    return;
  }

  @override
  void setDefaults(Map<String, dynamic> defaults) {
    _defaultValues.addAll(defaults);
    debugPrint('🚩 Default values set: $defaults');
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _fetchTimer?.cancel();
    _listeners.clear();
  }
}
