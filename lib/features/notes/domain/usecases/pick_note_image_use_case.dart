import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';

import '../entities/note_image.dart';
import '../repositories/note_image_repository.dart';

/// 挑图片插进笔记正文。
///
/// 零逻辑薄封装（同 `ImportBackupUseCase`）：文件怎么被挑出来、要不要压，
/// 分别是 data 层与调用方的决定 —— 这里只把请求原样传下去，好让 presentation
/// 侧能整体替换成假的 repository 做测试。
class PickNoteImageUseCase {
  const PickNoteImageUseCase(this._repository);

  final NoteImageRepository _repository;

  Future<Either<Failure, List<NoteImage>>> call({required bool compress}) =>
      _repository.pickImages(compress: compress);
}
