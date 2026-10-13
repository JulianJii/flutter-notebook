// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_subtask_dao.dart';

// ignore_for_file: type=lint
mixin _$TodoSubtaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteFoldersTable get noteFolders => attachedDatabase.noteFolders;
  $NotesTable get notes => attachedDatabase.notes;
  $TodosTable get todos => attachedDatabase.todos;
  $TodoSubtasksTable get todoSubtasks => attachedDatabase.todoSubtasks;
  TodoSubtaskDaoManager get managers => TodoSubtaskDaoManager(this);
}

class TodoSubtaskDaoManager {
  final _$TodoSubtaskDaoMixin _db;
  TodoSubtaskDaoManager(this._db);
  $$NoteFoldersTableTableManager get noteFolders =>
      $$NoteFoldersTableTableManager(_db.attachedDatabase, _db.noteFolders);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db.attachedDatabase, _db.todos);
  $$TodoSubtasksTableTableManager get todoSubtasks =>
      $$TodoSubtasksTableTableManager(_db.attachedDatabase, _db.todoSubtasks);
}
