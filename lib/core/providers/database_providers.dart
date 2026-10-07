import 'package:mynote/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

/// 全 App 单例数据库。keepAlive：数据库必须活到 App 结束。
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(AppDatabase.openConnection());
  ref.onDispose(db.close);
  return db;
}
