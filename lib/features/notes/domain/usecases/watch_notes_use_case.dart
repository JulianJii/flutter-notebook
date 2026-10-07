import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 按 [NoteQuery] 订阅笔记列表。**唯一的列表数据入口**，UI 靠它拿流。
///
/// ⛔ **返回 `Stream` 而不是 `Either`**：`Either` 表达单次操作的成败，流有成败
/// 用 `AsyncValue` 表达。包一层只会让每个消费点写 `.fold`。
/// ⛔ 不继承 `core/usecases/usecase.dart` 的 `UseCase`（那是个零继承的死基类）。
class WatchNotesUseCase {
  const WatchNotesUseCase(this._repository);

  final NoteRepository _repository;

  /// 非法参数（`limit < 0`）直接给**空流**：不抛异常、不返回 `Left`
  /// （流本来就没有 `Left` 这个概念）。
  Stream<List<Note>> call(NoteQuery query) {
    final limit = query.limit;
    if (limit != null && limit < 0) {
      return const Stream.empty();
    }
    return _repository.watch(query);
  }
}
