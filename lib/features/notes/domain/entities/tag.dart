import 'package:equatable/equatable.dart';

/// 一个标签。[noteCount] 是**展示用派生值**（挂着的存活笔记数，回收站 /
/// 墓碑笔记不计），由 DAO 的 JOIN 现算，不在库里 —— 派生值落库才是 bug。
class Tag extends Equatable {
  const Tag({required this.id, required this.name, required this.noteCount});

  final String id;

  final String name;

  final int noteCount;

  @override
  List<Object?> get props => [id, name, noteCount];
}
