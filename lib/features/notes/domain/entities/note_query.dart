import 'package:equatable/equatable.dart';

const Object _unset = Object();

/// 笔记列表的文件夹筛选三态。
///
/// `sealed` 而非「`String? folderId` + 布尔开关」：3 个子类型无分支、无布尔
/// 组合，三态**穷尽且互斥** —— 构造不出「既筛某文件夹又只要未分类」这种
/// 可表达但无意义的状态。
sealed class NoteFolderFilter extends Equatable {
  const NoteFolderFilter();

  @override
  List<Object?> get props => [];
}

/// 「全部」—— 不加 folder 条件。
final class AllFolders extends NoteFolderFilter {
  const AllFolders();

  @override
  List<Object?> get props => ['all'];
}

/// 「未分类」—— `folder_id IS NULL` 的系统视图，不占表行。
final class UncategorizedNotes extends NoteFolderFilter {
  const UncategorizedNotes();

  @override
  List<Object?> get props => ['uncategorized'];
}

/// 「词声笔记」等用户文件夹。
final class SingleFolder extends NoteFolderFilter {
  const SingleFolder(this.folderId);

  final String folderId;

  @override
  List<Object?> get props => ['single', folderId];
}

/// 笔记排序。手动拖拽的 `sort_index` 留待有稿时再加，
/// 本期只有这 4 种时间/标题序。
enum NoteSort { editedDesc, editedAsc, createdDesc, titleAsc }

/// 笔记列表的一次查询。`StreamProvider.family` 直接消费它，故 `==` /
/// `hashCode` 必须覆盖**全部**字段（漏一个就是「改了筛选但 UI 不刷新」的沉默 bug）。
class NoteQuery extends Equatable {
  const NoteQuery({
    this.folder = const AllFolders(),
    this.sort = NoteSort.editedDesc,
    this.searchTerm,
    this.tagId,
    this.limit,
    this.offset = 0,
  });

  /// 筛某个具体文件夹。
  factory NoteQuery.of(String folderId) =>
      NoteQuery(folder: SingleFolder(folderId));

  /// 只看未分类。
  factory NoteQuery.uncategorized() =>
      NoteQuery(folder: const UncategorizedNotes());

  final NoteFolderFilter folder;

  final NoteSort sort;

  /// 搜索词。数据层备好一行 `LIKE`（参数化，非 FTS5）。
  ///
  /// ⚠️ 空串归一化在 datasource：`''` 会生成 `LIKE '%%'`
  /// 匹配全部，实体不替上层做判断。
  final String? searchTerm;

  /// 标签筛选。null = 不按标签过滤；非 null = 只看挂了这个标签的笔记。
  /// 与 [folder] / [searchTerm] 是**叠加**关系。挂接已被摘除（墓碑）的
  /// 标签不算数（数据层过滤 `deleted_at IS NULL`）。
  final String? tagId;

  /// 单页条数。字段先在，不做无限滚动控制器。
  final int? limit;

  final int offset;

  /// [searchTerm] 用哨兵 —— `copyWith(searchTerm: null)` 必须真的清掉。
  /// [limit] 不需要哨兵：null 就是「无限制」，没有「清空 null」的需求。
  NoteQuery copyWith({
    NoteFolderFilter? folder,
    NoteSort? sort,
    Object? searchTerm = _unset,
    Object? tagId = _unset,
    int? limit,
    int? offset,
  }) {
    return NoteQuery(
      folder: folder ?? this.folder,
      sort: sort ?? this.sort,
      searchTerm: identical(searchTerm, _unset)
          ? this.searchTerm
          : searchTerm as String?,
      tagId: identical(tagId, _unset) ? this.tagId : tagId as String?,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  List<Object?> get props => [folder, sort, searchTerm, tagId, limit, offset];
}
