// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_dao.dart';

// ignore_for_file: type=lint
mixin _$FolderDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteFoldersTable get noteFolders => attachedDatabase.noteFolders;
  $NotesTable get notes => attachedDatabase.notes;
  FolderDaoManager get managers => FolderDaoManager(this);
}

class FolderDaoManager {
  final _$FolderDaoMixin _db;
  FolderDaoManager(this._db);
  $$NoteFoldersTableTableManager get noteFolders =>
      $$NoteFoldersTableTableManager(_db.attachedDatabase, _db.noteFolders);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
}
