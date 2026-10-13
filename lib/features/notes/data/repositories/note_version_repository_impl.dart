import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/data/datasources/note_version_local_data_source.dart';
import 'package:mynote/features/notes/domain/entities/note_version.dart';
import 'package:mynote/features/notes/domain/repositories/note_version_repository.dart';
import 'package:uuid/uuid.dart';

/// 版本历史 Repository 的唯一实现。约定与 `NoteRepositoryImpl` 相同。
class NoteVersionRepositoryImpl implements NoteVersionRepository {
  NoteVersionRepositoryImpl(this._localDataSource, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final NoteVersionLocalDataSource _localDataSource;
  final Uuid _uuid;

  /// uuid 在这里生成（datasource 与 DAO 都不碰 uuid）。
  @override
  Future<Either<Failure, Unit>> saveVersion(NoteVersion version, int limit) async {
    try {
      final withId = version.id.isEmpty
          ? NoteVersion(
              id: _uuid.v4(),
              noteId: version.noteId,
              title: version.title,
              content: version.content,
              createdAt: version.createdAt,
            )
          : version;
      await _localDataSource.saveVersion(withId, limit);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<NoteVersion>> watchVersions(String noteId) =>
      _localDataSource.watchVersions(noteId).handleError(_toFailure);

  @override
  Future<Either<Failure, NoteVersion>> getById(String versionId) async {
    try {
      return Right(await _localDataSource.getById(versionId));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

/// 流错误 → `CacheFailure`（与 `NoteRepositoryImpl._toFailure` 同形）。
Never _toFailure(Object e) => throw e is CacheException
    ? CacheFailure(message: e.message)
    : CacheFailure(message: e.toString());
