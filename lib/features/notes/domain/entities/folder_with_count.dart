import 'package:equatable/equatable.dart';

import 'note_folder.dart';

/// 文件夹 + 其下笔记数。数据层的只读视图对象，**不是数据库表**，不落库。
///
/// 「全部 155」「未分类 154」**不是**本类型的实例（§5.3：不是表里的行）。
/// 那两行由 presentation 层（文件夹管理）组合（「未分类」是筛选哨兵，不是系统行）。
class FolderWithCount extends Equatable {
  const FolderWithCount({required this.folder, required this.count});

  final NoteFolder folder;

  /// 该文件夹下的笔记数。来源是 DAO 的一条 `GROUP BY`，**不是**逐个 count。
  final int count;

  @override
  List<Object?> get props => [folder, count];
}
