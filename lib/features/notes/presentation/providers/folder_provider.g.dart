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
/// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
/// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
///
/// ⛔ **不复用 `noteListProvider` 再 `.length`**：那条链路是「取列表再数长度」，
/// 会把全部未分类笔记的正文（Quill Delta JSON）读进内存只为拿一个整数，
/// 且每次笔记变动都重来一遍。DAO 里那条 `COUNT(*)` 就是为它准备的。

@ProviderFor(uncategorizedCount)
final uncategorizedCountProvider = UncategorizedCountProvider._();

/// 「未分类」的笔记数（D4 的 `未分类 154`）。
///
/// ⚠️ **这里的取名不归 provider**：l10n 文案与设计稿用字由消费方
/// （P4，`TASK-050`）决定，provider 不知道也不该知道。
///
/// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
/// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
///
/// ⛔ **不复用 `noteListProvider` 再 `.length`**：那条链路是「取列表再数长度」，
/// 会把全部未分类笔记的正文（Quill Delta JSON）读进内存只为拿一个整数，
/// 且每次笔记变动都重来一遍。DAO 里那条 `COUNT(*)` 就是为它准备的。

final class UncategorizedCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// 「未分类」的笔记数（D4 的 `未分类 154`）。
  ///
  /// ⚠️ **这里的取名不归 provider**：l10n 文案与设计稿用字由消费方
  /// （P4，`TASK-050`）决定，provider 不知道也不该知道。
  ///
  /// ⛔ **不复用 `folderProvider` 再 `where`**：`FolderWithCount.folder` 是非空的
  /// `NoteFolder`（「未分类」不是表里的行），流里根本没有可筛的那一行。
  ///
  /// ⛔ **不复用 `noteListProvider` 再 `.length`**：那条链路是「取列表再数长度」，
  /// 会把全部未分类笔记的正文（Quill Delta JSON）读进内存只为拿一个整数，
  /// 且每次笔记变动都重来一遍。DAO 里那条 `COUNT(*)` 就是为它准备的。
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
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return uncategorizedCount(ref);
  }
}

String _$uncategorizedCountHash() =>
    r'e5c05dcaa1fa009f43edb3c6ff7251a88e49862b';
