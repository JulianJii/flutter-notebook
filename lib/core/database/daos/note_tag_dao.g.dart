// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_tag_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteTagDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteTagsTable get noteTags => attachedDatabase.noteTags;
  $NoteFoldersTable get noteFolders => attachedDatabase.noteFolders;
  $NotesTable get notes => attachedDatabase.notes;
  $NoteTagLinksTable get noteTagLinks => attachedDatabase.noteTagLinks;
  NoteTagDaoManager get managers => NoteTagDaoManager(this);
}

class NoteTagDaoManager {
  final _$NoteTagDaoMixin _db;
  NoteTagDaoManager(this._db);
  $$NoteTagsTableTableManager get noteTags =>
      $$NoteTagsTableTableManager(_db.attachedDatabase, _db.noteTags);
  $$NoteFoldersTableTableManager get noteFolders =>
      $$NoteFoldersTableTableManager(_db.attachedDatabase, _db.noteFolders);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
  $$NoteTagLinksTableTableManager get noteTagLinks =>
      $$NoteTagLinksTableTableManager(_db.attachedDatabase, _db.noteTagLinks);
}
