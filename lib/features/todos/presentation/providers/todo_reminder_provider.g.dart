// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_reminder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 待办提醒的编排：**先落库，成功再调度**。
///
/// ⛔ 不进 `domain`：定时通知是平台能力，而 domain 禁 import Flutter；项目既有的
/// 「写操作由 provider / Screen 直接调 UseCase」在这里同样成立（见
/// `todo_list_provider.dart` 的 `TodoOverrides`）。
/// ⛔ 不做乐观更新：设置提醒是个弹窗里的显式提交，没有「先改后回滚」的必要，
/// drift 的 watch 会把新值推回来。

@ProviderFor(todoReminder)
final todoReminderProvider = TodoReminderProvider._();

/// 待办提醒的编排：**先落库，成功再调度**。
///
/// ⛔ 不进 `domain`：定时通知是平台能力，而 domain 禁 import Flutter；项目既有的
/// 「写操作由 provider / Screen 直接调 UseCase」在这里同样成立（见
/// `todo_list_provider.dart` 的 `TodoOverrides`）。
/// ⛔ 不做乐观更新：设置提醒是个弹窗里的显式提交，没有「先改后回滚」的必要，
/// drift 的 watch 会把新值推回来。

final class TodoReminderProvider
    extends $FunctionalProvider<TodoReminder, TodoReminder, TodoReminder>
    with $Provider<TodoReminder> {
  /// 待办提醒的编排：**先落库，成功再调度**。
  ///
  /// ⛔ 不进 `domain`：定时通知是平台能力，而 domain 禁 import Flutter；项目既有的
  /// 「写操作由 provider / Screen 直接调 UseCase」在这里同样成立（见
  /// `todo_list_provider.dart` 的 `TodoOverrides`）。
  /// ⛔ 不做乐观更新：设置提醒是个弹窗里的显式提交，没有「先改后回滚」的必要，
  /// drift 的 watch 会把新值推回来。
  TodoReminderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoReminderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoReminderHash();

  @$internal
  @override
  $ProviderElement<TodoReminder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TodoReminder create(Ref ref) {
    return todoReminder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoReminder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoReminder>(value),
    );
  }
}

String _$todoReminderHash() => r'49bbe056f59929c836597a6a38e1ae1cdd82c5ac';
