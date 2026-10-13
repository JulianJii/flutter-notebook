import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/tag.dart';

/// 标签的领域抽象。实现在 data 层。
abstract class TagRepository {
  /// 订阅全部标签（含各标签的存活笔记数），按名字升序。
  /// 流错误约定与 `NoteRepository.watch` 一致。
  Stream<List<Tag>> watchAll();

  /// 一篇笔记当前的标签名列表（一次性读，弹层回填用）。
  Future<Either<Failure, List<String>>> namesForNote(String noteId);

  /// 按名取标签：存在（含墓碑）返回其 id；不存在则创建。
  /// 幂等 —— 打标弹层「输入即建」的底层入口。
  Future<Either<Failure, String>> createOrGetId(String name);

  /// 把一篇笔记的标签对齐到 [names]（trim / 去空 / 去重后的全集，
  /// 替换式而非增量）。内部先 createOrGet 每个名字，再对齐挂接。
  Future<Either<Failure, Unit>> setNoteTags(String noteId, List<String> names);

  /// 重命名（改名是用户数据变更，跨设备传播）。
  Future<Either<Failure, Unit>> rename(String tagId, String name);

  /// 删除：标签打墓碑 + 其全部挂接级联墓碑（从所有笔记上摘掉）。
  Future<Either<Failure, Unit>> delete(String tagId);
}
