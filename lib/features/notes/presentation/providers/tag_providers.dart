import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/tag.dart';
import '../../providers/notes_providers.dart';

part 'tag_providers.g.dart';

/// 全部标签（含存活笔记数，name ASC）。标签筛选弹层与标签管理页共用，
/// 数据链路固定 Screen → 本 provider → UseCase → Repository。
@riverpod
Stream<List<Tag>> tagList(Ref ref) {
  return ref.watch(watchTagsUseCaseProvider).call(NoParams());
}

/// 一篇笔记标签名的**一次性读**。详情页的展示行用它而非流 —— 常驻 drift 流
/// 在测试 teardown 会留一个「关流 Timer」，炸 flutter_test 的 pending-timer
/// 不变量；一行展示也不值得常驻订阅。[version] 无业务语义，只用于
/// 「打标弹层保存完 +1 强制重查」。
@riverpod
Future<List<String>> noteTagsSnapshot(Ref ref, String noteId, int version) {
  return ref
      .watch(getNoteTagsUseCaseProvider)
      .call(noteId)
      .then((either) => either.fold((_) => <String>[], (names) => names));
}
