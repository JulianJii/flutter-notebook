import 'package:equatable/equatable.dart';

/// 一次导入 / 同步的结果统计。
///
/// 三个计数互斥且穷尽「进来的每一行去了哪」：本地没有 → 新增；本地有但对端
/// 更新 → 更新；解析失败或写库被拒 → 跳过。
class BackupImportResult extends Equatable {
  const BackupImportResult({
    this.inserted = 0,
    this.updated = 0,
    this.skipped = 0,
  });

  static const BackupImportResult empty = BackupImportResult();

  final int inserted;

  final int updated;

  final int skipped;

  int get changed => inserted + updated;

  @override
  List<Object?> get props => <Object?>[inserted, updated, skipped];
}
