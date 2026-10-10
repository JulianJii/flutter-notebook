/// 应用时钟。落库的 `updated_at` / `deleted_at` 一律走 [appNow]，**不直接调
/// `DateTime.now()`**。
///
/// ## 为什么需要它
///
/// 同步的合并键是 `max(updatedAt, deletedAt)`（`BackupSnapshot.merge`），
/// 比的是各台设备**自己的墙上时钟**。两台设备时钟差 5 分钟，那台快的就会**静默**
/// 覆盖慢的那台的改动 —— 不是「冲突提示」，是数据直接消失。
///
/// 局域网同步握手时会交换双方时间、算出偏差（见 `LAN` 同步），把 [offset] 设
/// 进来，之后本机写的时间戳就是「以对端为准」的。
///
/// ## 边界（重要）
///
/// - **只影响写入时间戳的取法**，不改变 `DateTime.now()` 本身。日志、动画、
///   「刚刚」相对时间显示都仍用系统时钟 —— 偏移量通常在秒级，那些场景用不上，
///   改了反而会让「15 分钟前」之类的文案抖动。
/// - **不保证绝对正确**：偏差只在局域网同步那一刻刷新一次，之后不再校正。
///   它解决的是「两台设备长期各自跑偏」，不是「精确对时」。
/// - **`BackupLocalDataSource` 写回路径刻意不走这里**：那份时间戳**来自对端**，
///   换成 [appNow] 会让每一条合并进来的记录都变成「刚刚编辑过」，破坏合并语义。
///
/// ponytail: 静态可变状态。替代方案是把 offset 注入 8 个构造函数（笔记 4 /
/// 文件夹 2 / 待办 4，含 repository 与 datasource），代价是每个测试都要记得重置它
/// —— 收益不匹配复杂度。真要注入时先看 [reset] 的使用点有多少。
abstract final class AppClock {
  /// 本机时钟相对系统时钟的偏差。由局域网同步握手写入。
  static Duration _offset = Duration.zero;

  /// 落库时间戳的**唯一**取法。
  static DateTime appNow() => DateTime.now().add(_offset);

  static Duration get offset => _offset;

  /// 设置偏差。局域网同步握手成功后调用。
  ///
  /// ⚠️ 偏移量会**持久化**（`ClockOffsetStore`），所以重启后仍生效 —— 否则设备
  /// 一重启就回到错误的本地时钟，而用户可能几天内不再同步。
  static void setOffset(Duration offset) => _offset = offset;

  /// 清零。回的是「不再信任对端的时钟」。
  static void reset() => _offset = Duration.zero;
}