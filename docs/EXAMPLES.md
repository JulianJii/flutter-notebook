# 代码示例

> 本文的示例**全部取自仓库真实代码**（路径可直接打开核对），不再复述模板时期的 auth 示例——`lib/features/auth/` 在本项目中不存在。
> 可运行的独立演示页在 `lib/examples/`（`examples_hub_screen.dart` 是入口，网络协议演示在 `lib/examples/integrations/`）。

---

## 1. 一个完整用例（Domain）

`lib/features/notes/domain/usecases/update_note_use_case.dart` —— 笔记自动保存的入口，展示了用例的标配：输入校验返回 `Left(InputFailure)`，正常路径委托给接口。

```dart
class UpdateNoteUseCase {
  const UpdateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Note>> call(UpdateNoteParams params) {
    if (params.noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    if (params.title.trim().isEmpty && params.content.trim().isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Note must have a title or content')),
      );
    }
    final now = DateTime.now();
    return _repository.update(
      Note(
        id: params.noteId,
        title: params.title,
        content: params.content,
        folderId: params.targetFolderId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
```

## 2. DI 装配（providers）

`lib/features/notes/providers/notes_providers.dart` —— 注解式 codegen，装配顺序是 数据源 → 仓库 → 用例。

```dart
part 'notes_providers.g.dart';

@riverpod
NoteLocalDataSource noteLocalDataSource(Ref ref) {
  return NoteLocalDataSourceImpl(ref.watch(appDatabaseProvider));
}

@riverpod
NoteRepository noteRepository(Ref ref) {
  return NoteRepositoryImpl(ref.watch(noteLocalDataSourceProvider));
}

@riverpod
UpdateNoteUseCase updateNoteUseCase(Ref ref) {
  return UpdateNoteUseCase(ref.watch(noteRepositoryProvider));
}
```

## 3. 跟着一条链路读代码

| 要找什么 | 打开哪里 |
|---|---|
| 业务对象 | `features/notes/domain/entities/`：`note.dart`、`note_folder.dart`、`note_query.dart`、`note_background.dart` |
| 接口 | `features/notes/domain/repositories/`：返回 `Future<Either<Failure, T>>` 或 `Stream` |
| 单个业务操作 | `features/notes/domain/usecases/`（20 个，一类一操作） |
| drift 读写 | `features/notes/data/datasources/note_local_data_source.dart` |
| Exception → Failure | `features/notes/data/repositories/note_repository_impl.dart` |
| UI 状态 | `features/notes/presentation/providers/`：`note_list_provider.dart`（列表）、`note_editor_provider.dart`（编辑 / 自动保存）、`folder_provider.dart`、`note_search_provider.dart`、`deleted_note_list_provider.dart` |
| 页面 | `features/notes/presentation/screens/`、`features/notes/presentation/widgets/` |
| DI | `features/notes/providers/notes_providers.dart` |

`features/todos/`、`features/settings/` 是同样四层结构的更小样本，适合照着抄。

## 4. 列表用 Stream，不用一次性 Future

`lib/features/notes/presentation/providers/note_list_provider.dart` —— 参数族按 `NoteQuery` 定位，筛选 / 排序变化即自动重查：

```dart
@riverpod
Stream<List<Note>> noteList(Ref ref, NoteQuery query) {
  return ref.watch(watchNotesUseCaseProvider).call(query);
}
```

## 5. 日志（Data 层禁止 print / debugPrint）

`core/logging/logger_provider.dart` 提供 `loggerProvider` 与 `taggedLoggerProvider`：

```dart
final logger = ref.read(loggerProvider);
logger.e('save failed'); // v/d/i/w/e/c/p，另有 child(tag) 派生子 logger
```

> ⚠️ 早期文档提到的 `core/utils/extensions/`（`context.tr()`、`DateTime.timeAgo` 等）**不存在**，未实现。取文案用 `AppLocalizations.of(context).xxx`（gen-l10n 强类型 getter），日期格式化用 `core/localization` 的 `context.formatDate/formatTime/formatDateTime/formatCurrency` 扩展。
