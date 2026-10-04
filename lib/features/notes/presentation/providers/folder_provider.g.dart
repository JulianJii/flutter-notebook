// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 文件夹 + 每个文件夹的笔记数。**P4 的 `FolderRow` 与 P1 的筛选 chip 共用
/// 这一个数据源**（`ARCHITECTURE-DESIGN.md` §3.2）。
///
/// 数据由 drift watch 驱动，`AsyncValue` 已覆盖 loading / data / error，
/// 因此**无自定义 State**（§6.2 P4 段 / R8）。空列表用 `value?.isEmpty` 派生。
///
/// ⚠️ 结果里**只有真实文件夹**，0 笔记的文件夹也在内（`count = 0`，DAO 的
/// `LEFT JOIN` 语义）。「全部」与「未分类」**不是**本流的行（§5.3）——
/// 前者由消费方求和，后者见 [uncategorizedCountProvider]。
///
/// ⛔ 不做二次排序：`ORDER BY created_at ASC` 已在 DAO 的 SQL 里排完
/// （设计稿无排序入口）。

@ProviderFor(folder)
final folderProvider = FolderProvider._();

/// 文件夹 + 每个文件夹的笔记数。**P4 的 `FolderRow` 与 P1 的筛选 chip 共用
/// 这一个数据源**（`ARCHITECTURE-DESIGN.md` §3.2）。
///
/// 数据由 drift watch 驱动，`AsyncValue` 已覆盖 loading / data / error，
/// 因此**无自定义 State**（§6.2 P4 段 / R8）。空列表用 `value?.isEmpty` 派生。
///
/// ⚠️ 结果里**只有真实文件夹**，0 笔记的文件夹也在内（`count = 0`，DAO 的
/// `LEFT JOIN` 语义）。「全部」与「未分类」**不是**本流的行（§5.3）——
/// 前者由消费方求和，后者见 [uncategorizedCountProvider]。
///
/// ⛔ 不做二次排序：`ORDER BY created_at ASC` 已在 DAO 的 SQL 里排完
/// （设计稿无排序入口）。

final class FolderProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FolderWithCount>>,
          List<FolderWithCount>,
          Stream<List<FolderWithCount>>
        >
    with
        $FutureModifier<List<FolderWithCount>>,
        $StreamProvider<List<FolderWithCount>> {
  /// 文件夹 + 每个文件夹的笔记数。**P4 的 `FolderRow` 与 P1 的筛选 chip 共用
  /// 这一个数据源**（`ARCHITECTURE-DESIGN.md` §3.2）。
  ///
  /// 数据由 drift watch 驱动，`AsyncValue` 已覆盖 loading / data / error，
  /// 因此**无自定义 State**（§6.2 P4 段 / R8）。空列表用 `value?.isEmpty` 派生。
  ///
  /// ⚠️ 结果里**只有真实文件夹**，0 笔记的文件夹也在内（`count = 0`，DAO 的
  /// `LEFT JOIN` 语义）。「全部」与「未分类」**不是**本流的行（§5.3）——
  /// 前者由消费方求和，后者见 [uncategorizedCountProvider]。
  ///
  /// ⛔ 不做二次排序：`ORDER BY created_at ASC` 已在 DAO 的 SQL 里排完
  /// （设计稿无排序入口）。
  FolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderHash();

  @$internal
  @override
  $StreamProviderElement<List<FolderWithCount>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FolderWithCount>> create(Ref ref) {
    return folder(ref);
  }
}

String _$folderHash() => r'514356286c6bc2063055c06cc677fc0fddf3f8c6';

/// 「未分类」的笔记数（D4 的 `未分类 154`）。
///
/// ⚠️ **这里的取名不归 provider**：l10n 文案与设计稿用字由消费方
/// （P4，`TASK-050`）决定，provider 不知道也不该知道。
///
/// ponytail: 用「未分类笔记列表的长度」而不是一条 COUNT 查询 —— DAO 已有
/// `watchUncategorizedCount()`，但 TASK-017 判 `FolderRepository` 恰好 4 个方法、
/// TASK-021 判 datasource 不提供它，链路在 repository 层断开；为一行 COUNT 去松
/// 4 个别的 Task 的既定接口不划算，而未分类笔记的行数与 D4 实测的 154 同量级。
/// 天花板：未分类笔记到万级时会把整批行读进内存。升级路径：给 `FolderRepository`
/// + `FolderLocalDataSource` 各加一个 3 行透传，本provider 改成直连
/// （调用方零改动）。
///
/// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
/// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
///
/// ⛔ **返回 `AsyncValue<int>` 而不是 `Stream<int>`**（A41）：任务书 §1 的骨架写
/// `.map((notes) => notes.length)`，但 Riverpod 3.4.3 的 `AsyncValue` 只有
/// `map` / `whenData` / `when`（**都要求 3 个分支回调**），没有单参 `map`；
/// `Ref.stream` 也不存在（3.0 移除）。而 `ref.watch(noteListProvider(q))` 拿到的
/// 已经是 `AsyncValue<List<Note>>` —— 再套一层 `Stream` 只能靠
/// `Stream.multi` + `ref.listen` 手工搭，那是**为了类型签名而手写事件流**。
/// `AsyncValue` 派生（§6.3）零成本，消费方 `ref.watch(uncategorizedCountProvider)`
/// 拿到的仍是 `AsyncValue<int>`，与 `StreamProvider` 的读法**逐字一致**。

@ProviderFor(uncategorizedCount)
final uncategorizedCountProvider = UncategorizedCountProvider._();

/// 「未分类」的笔记数（D4 的 `未分类 154`）。
///
/// ⚠️ **这里的取名不归 provider**：l10n 文案与设计稿用字由消费方
/// （P4，`TASK-050`）决定，provider 不知道也不该知道。
///
/// ponytail: 用「未分类笔记列表的长度」而不是一条 COUNT 查询 —— DAO 已有
/// `watchUncategorizedCount()`，但 TASK-017 判 `FolderRepository` 恰好 4 个方法、
/// TASK-021 判 datasource 不提供它，链路在 repository 层断开；为一行 COUNT 去松
/// 4 个别的 Task 的既定接口不划算，而未分类笔记的行数与 D4 实测的 154 同量级。
/// 天花板：未分类笔记到万级时会把整批行读进内存。升级路径：给 `FolderRepository`
/// + `FolderLocalDataSource` 各加一个 3 行透传，本provider 改成直连
/// （调用方零改动）。
///
/// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
/// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
///
/// ⛔ **返回 `AsyncValue<int>` 而不是 `Stream<int>`**（A41）：任务书 §1 的骨架写
/// `.map((notes) => notes.length)`，但 Riverpod 3.4.3 的 `AsyncValue` 只有
/// `map` / `whenData` / `when`（**都要求 3 个分支回调**），没有单参 `map`；
/// `Ref.stream` 也不存在（3.0 移除）。而 `ref.watch(noteListProvider(q))` 拿到的
/// 已经是 `AsyncValue<List<Note>>` —— 再套一层 `Stream` 只能靠
/// `Stream.multi` + `ref.listen` 手工搭，那是**为了类型签名而手写事件流**。
/// `AsyncValue` 派生（§6.3）零成本，消费方 `ref.watch(uncategorizedCountProvider)`
/// 拿到的仍是 `AsyncValue<int>`，与 `StreamProvider` 的读法**逐字一致**。

final class UncategorizedCountProvider
    extends
        $FunctionalProvider<AsyncValue<int>, AsyncValue<int>, AsyncValue<int>>
    with $Provider<AsyncValue<int>> {
  /// 「未分类」的笔记数（D4 的 `未分类 154`）。
  ///
  /// ⚠️ **这里的取名不归 provider**：l10n 文案与设计稿用字由消费方
  /// （P4，`TASK-050`）决定，provider 不知道也不该知道。
  ///
  /// ponytail: 用「未分类笔记列表的长度」而不是一条 COUNT 查询 —— DAO 已有
  /// `watchUncategorizedCount()`，但 TASK-017 判 `FolderRepository` 恰好 4 个方法、
  /// TASK-021 判 datasource 不提供它，链路在 repository 层断开；为一行 COUNT 去松
  /// 4 个别的 Task 的既定接口不划算，而未分类笔记的行数与 D4 实测的 154 同量级。
  /// 天花板：未分类笔记到万级时会把整批行读进内存。升级路径：给 `FolderRepository`
  /// + `FolderLocalDataSource` 各加一个 3 行透传，本provider 改成直连
  /// （调用方零改动）。
  ///
  /// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
  /// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
  ///
  /// ⛔ **返回 `AsyncValue<int>` 而不是 `Stream<int>`**（A41）：任务书 §1 的骨架写
  /// `.map((notes) => notes.length)`，但 Riverpod 3.4.3 的 `AsyncValue` 只有
  /// `map` / `whenData` / `when`（**都要求 3 个分支回调**），没有单参 `map`；
  /// `Ref.stream` 也不存在（3.0 移除）。而 `ref.watch(noteListProvider(q))` 拿到的
  /// 已经是 `AsyncValue<List<Note>>` —— 再套一层 `Stream` 只能靠
  /// `Stream.multi` + `ref.listen` 手工搭，那是**为了类型签名而手写事件流**。
  /// `AsyncValue` 派生（§6.3）零成本，消费方 `ref.watch(uncategorizedCountProvider)`
  /// 拿到的仍是 `AsyncValue<int>`，与 `StreamProvider` 的读法**逐字一致**。
  UncategorizedCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uncategorizedCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uncategorizedCountHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AsyncValue<int> create(Ref ref) {
    return uncategorizedCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int>>(value),
    );
  }
}

String _$uncategorizedCountHash() =>
    r'6e700282102552420bc7febc286f686f972fdee7';
