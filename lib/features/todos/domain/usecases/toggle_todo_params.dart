import 'package:equatable/equatable.dart';

/// `ToggleTodoUseCase` 的参数。**传目标值而非「翻转」**：重试（乐观更新失败后
/// 再提交一次）不会二次翻转。
///
/// ⚠️ [title] 不是可选：`TodoRepository.update` 收的是整个实体，让调用方显式传
/// 当前标题可以避免 Repository 内部去查，也让测试的 `verify` 能直接验证参数。
/// 「先读后写」是本 App 的既定取舍（没有并发写者，调用方本来就在持有列表）。
class ToggleTodoParams extends Equatable {
  const ToggleTodoParams({
    required this.todoId,
    required this.title,
    required this.isDone,
  });

  final String todoId;

  final String title;

  /// 目标勾选状态，**不是**「取反」。
  final bool isDone;

  @override
  List<Object?> get props => [todoId, title, isDone];
}
