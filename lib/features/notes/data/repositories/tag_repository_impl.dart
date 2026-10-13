import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/data/datasources/tag_local_data_source.dart';
import 'package:mynote/features/notes/domain/entities/tag.dart';
import 'package:mynote/features/notes/domain/repositories/tag_repository.dart';
import 'package:uuid/uuid.dart';

/// 标签 Repository 的唯一实现。约定与 `NoteRepositoryImpl` 相同：
/// `Uuid` 走可选命名参数、异常 → `Failure` 绝不上抛、流错误 `handleError`。
class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._localDataSource, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final TagLocalDataSource _localDataSource;
  final Uuid _uuid;

  @override
  Stream<List<Tag>> watchAll() =>
      _localDataSource.watchAll().handleError(_toFailure);

  @override
  Future<Either<Failure, List<String>>> namesForNote(String noteId) async {
    try {
      return Right(await _localDataSource.namesForNote(noteId));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createOrGetId(String name) async {
    try {
      return Right(await _ensureTagId(name));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// 幂等的「名字 → 标签 id」：同名（含墓碑）复用，不存在才建。
  @override
  Future<Either<Failure, Unit>> setNoteTags(
    String noteId,
    List<String> names,
  ) async {
    try {
      // 先保证每个名字都有标签行（建 / 复活），再一次性对齐挂接 ——
      // 标签行即便半途失败也只是多一行无人挂接的空标签（管理页可删），
      // 而挂接对齐本身是单事务的。
      final ids = <String>[
        for (final name in names) await _ensureTagId(name),
      ];
      await _localDataSource.setNoteTagLinks(noteId, ids);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  Future<String> _ensureTagId(String name) async {
    final existing = await _localDataSource.getByName(name);
    if (existing != null) return existing.id;
    final created = await _localDataSource.insert(
      Tag(id: _uuid.v4(), name: name, noteCount: 0),
    );
    return created.id;
  }

  @override
  Future<Either<Failure, Unit>> rename(String tagId, String name) async {
    try {
      await _localDataSource.rename(tagId, name);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String tagId) async {
    try {
      await _localDataSource.delete(tagId);
      return const Right(unit);
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
