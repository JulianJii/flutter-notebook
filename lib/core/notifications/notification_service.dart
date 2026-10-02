import 'dart:async';

/// 表示通知消息的模型类
class NotificationMessage {
  /// 通知的唯一标识符
  final String id;

  /// 通知标题
  final String? title;

  /// 通知正文文本
  final String? body;

  /// 可选的图片 URL
  final String? imageUrl;

  /// 可选的数据载荷
  final Map<String, dynamic>? data;

  /// 点击通知时要执行的深层链接或动作
  final String? action;

  /// 通知渠道或类别
  final String? channel;

  /// 通知是否在应用处于前台时收到
  final bool foreground;

  const NotificationMessage({
    required this.id,
    this.title,
    this.body,
    this.imageUrl,
    this.data,
    this.action,
    this.channel,
    this.foreground = true,
  });

  @override
  String toString() {
    return 'NotificationMessage{'
        'id: $id, '
        'title: $title, '
        'body: $body, '
        'imageUrl: $imageUrl, '
        'data: $data, '
        'action: $action, '
        'channel: $channel, '
        'foreground: $foreground'
        '}';
  }
}

/// 通知权限状态的接口
enum NotificationPermissionStatus {
  notDetermined,
  denied,
  authorized,
  provisional,
}

/// 通知服务的接口
abstract class NotificationService {
  /// 初始化通知服务
  Future<void> init();

  /// 请求显示通知的权限
  Future<NotificationPermissionStatus> requestPermission();

  /// 获取当前通知权限状态
  Future<NotificationPermissionStatus> getPermissionStatus();

  /// 通过 Firebase Cloud Messaging 或 APNs 注册推送通知
  Future<String?> getToken();

  /// 处理应用处于后台或已终止时收到的通知
  Future<void> handleBackgroundMessage(Map<String, dynamic> message);

  /// 配置通知渠道（Android）
  Future<void> configureChannels();

  /// 订阅通知主题
  Future<void> subscribeToTopic(String topic);

  /// 取消订阅通知主题
  Future<void> unsubscribeFromTopic(String topic);

  /// 显示本地通知
  Future<void> showLocalNotification({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? action,
    String? channel,
  });

  /// 按 id 清除指定的通知
  Future<void> clearNotification(String id);

  /// 清除所有通知
  Future<void> clearAllNotifications();

  /// 传入通知的 Stream
  Stream<NotificationMessage> get notificationStream;

  /// 通知点击的 Stream
  Stream<NotificationMessage> get notificationTapStream;
}
