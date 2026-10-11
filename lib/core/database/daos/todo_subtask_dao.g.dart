// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_subtask_dao.dart';

// ignore_for_file: type=lint
mixin _$TodoSubtaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $TodosTable get todos => attachedDatabase.todos;
  $TodoSubtasksTable get todoSubtasks => attachedDatabase.todoSubtasks;
  TodoSubtaskDaoManager get managers => TodoSubtaskDaoManager(this);
}

class TodoSubtaskDaoManager {
  final _$TodoSubtaskDaoMixin _db;
  TodoSubtaskDaoManager(this._db);
  $$TodosTableTableManager get todos =>
      $$TodosTableTableManager(_db.attachedDatabase, _db.todos);
  $$TodoSubtasksTableTableManager get todoSubtasks =>
      $$TodoSubtasksTableTableManager(_db.attachedDatabase, _db.todoSubtasks);
}
