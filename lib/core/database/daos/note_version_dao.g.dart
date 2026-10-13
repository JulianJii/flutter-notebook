// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_version_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteVersionDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteFoldersTable get noteFolders => attachedDatabase.noteFolders;
  $NotesTable get notes => attachedDatabase.notes;
  $NoteVersionsTable get noteVersions => attachedDatabase.noteVersions;
  NoteVersionDaoManager get managers => NoteVersionDaoManager(this);
}

class NoteVersionDaoManager {
  final _$NoteVersionDaoMixin _db;
  NoteVersionDaoManager(this._db);
  $$NoteFoldersTableTableManager get noteFolders =>
      $$NoteFoldersTableTableManager(_db.attachedDatabase, _db.noteFolders);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
  $$NoteVersionsTableTableManager get noteVersions =>
      $$NoteVersionsTableTableManager(_db.attachedDatabase, _db.noteVersions);
}
