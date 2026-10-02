/// Flutter Riverpod 整洁架构 Feature 生成器
///
/// 此 Dart 文件可以编程方式用于生成新 feature
/// 它镜像了 generate_feature.sh 脚本的功能
/// 但允许与 IDE 插件或 Flutter 工具进行更复杂的集成。
library;

import 'dart:io';

class FeatureGenerator {
  final String featureName;
  final bool withUi;
  final bool withTests;
  final bool withDocs;

  /// PascalCase 格式的 feature 名称（例如 UserProfile）
  late final String pascalCase;

  /// camelCase 格式的 feature 名称（例如 userProfile）
  late final String camelCase;

  FeatureGenerator({
    required this.featureName,
    this.withUi = true,
    this.withTests = true,
    this.withDocs = true,
  }) {
    pascalCase = _toPascalCase(featureName);
    camelCase = _toCamelCase(featureName);
  }

  /// 为 feature 生成所有文件和文件夹
  Future<void> generate() async {
    stdout.writeln('Generating feature: $featureName');

    await _createDirectories();
    await _createFiles();

    stdout.writeln('Feature $featureName generated successfully!');
  }

  /// 创建 feature 的目录结构
  Future<void> _createDirectories() async {
    final baseDir = 'lib/features/$featureName';

    // 数据层
    await _createDir('$baseDir/data/datasources');
    await _createDir('$baseDir/data/models');
    await _createDir('$baseDir/data/repositories');

    // 领域层
    await _createDir('$baseDir/domain/entities');
    await _createDir('$baseDir/domain/repositories');
    await _createDir('$baseDir/domain/usecases');

    // 表现层（如启用）
    if (withUi) {
      await _createDir('$baseDir/presentation/providers');
      await _createDir('$baseDir/presentation/screens');
      await _createDir('$baseDir/presentation/widgets');
    }

    // Providers 文件夹
    await _createDir('$baseDir/providers');

    // 测试目录（如启用）
    if (withTests) {
      await _createDir('test/features/$featureName/data');
      await _createDir('test/features/$featureName/domain');
      if (withUi) {
        await _createDir('test/features/$featureName/presentation');
      }
    }

    // 文档（如启用）
    if (withDocs) {
      await _createDir('docs/features');
    }
  }

  /// 为 feature 创建所有模板文件
  Future<void> _createFiles() async {
    final baseDir = 'lib/features/$featureName';

    // 数据层文件
    await _createFile('$baseDir/data/models/${featureName}_model.dart', '''
// $pascalCase 模型
// 实现 ${pascalCase}Entity，并添加额外的数据层功能

import '../../domain/entities/${featureName}_entity.dart';

class ${pascalCase}Model extends ${pascalCase}Entity {
  ${pascalCase}Model({
    required String id,
    // 在此添加必填字段
  }) : super(
          id: id,
          // 使用必填字段初始化父类
        );

  // 从 JSON 创建模型的工厂方法
  factory ${pascalCase}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalCase}Model(
      id: json['id'],
      // 从 JSON 映射其他字段
    );
  }

  // 将模型转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 在此添加其他字段
    };
  }

  // 创建带有修改字段的副本
  ${pascalCase}Model copyWith({
    String? id,
    // 在此添加其他字段
  }) {
    return ${pascalCase}Model(
      id: id ?? this.id,
      // 使用空值合并运算符添加其他字段
    );
  }
}
''');

    await _createFile(
      '$baseDir/data/datasources/${featureName}_remote_datasource.dart',
      '''
// $pascalCase 远程数据源
// 处理 API 调用和外部数据源

import '../models/${featureName}_model.dart';

abstract class ${pascalCase}RemoteDataSource {
  /// 从远程 API 获取 $camelCase 数据
  ///
  /// 所有错误码都会抛出 [ServerException]
  Future<List<${pascalCase}Model>> get${pascalCase}s();
  
  /// 根据 ID 获取指定的 $camelCase
  Future<${pascalCase}Model?> get${pascalCase}ById(String id);
}

class ${pascalCase}RemoteDataSourceImpl implements ${pascalCase}RemoteDataSource {
  // 在此添加你的 API client
  // final ApiClient apiClient;
  
  ${pascalCase}RemoteDataSourceImpl(/*{required this.apiClient}*/);
  
  @override
  Future<List<${pascalCase}Model>> get${pascalCase}s() async {
    // TODO: 实现 API 调用
    throw UnimplementedError();
  }
  
  @override
  Future<${pascalCase}Model?> get${pascalCase}ById(String id) async {
    // TODO: 实现 API 调用
    throw UnimplementedError();
  }
}
''',
    );

    await _createFile(
      '$baseDir/data/datasources/${featureName}_local_datasource.dart',
      '''
// $pascalCase 本地数据源
// 处理本地存储操作（SharedPreferences、SQLite 等）

import '../models/${featureName}_model.dart';

abstract class ${pascalCase}LocalDataSource {
  /// 获取缓存的 $camelCase 数据
  ///
  /// 如果没有缓存数据则抛出 [CacheException]
  Future<List<${pascalCase}Model>> getCached${pascalCase}s();
  
  /// 缓存 $camelCase 数据
  Future<void> cache${pascalCase}s(List<${pascalCase}Model> ${camelCase}s);
}

class ${pascalCase}LocalDataSourceImpl implements ${pascalCase}LocalDataSource {
  // 在此添加你的存储客户端
  // final SharedPreferences sharedPreferences;
  
  ${pascalCase}LocalDataSourceImpl(/*{required this.sharedPreferences}*/);
  
  @override
  Future<List<${pascalCase}Model>> getCached${pascalCase}s() async {
    // TODO: 实现本地存储读取
    throw UnimplementedError();
  }
  
  @override
  Future<void> cache${pascalCase}s(List<${pascalCase}Model> ${camelCase}s) async {
    // TODO: 实现本地存储缓存
    throw UnimplementedError();
  }
}
''',
    );

    await _createFile(
      '$baseDir/data/repositories/${featureName}_repository_impl.dart',
      '''
// $pascalCase 仓库实现
// 实现领域层的仓库接口

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/${featureName}_entity.dart';
import '../../domain/repositories/${featureName}_repository.dart';
import '../datasources/${featureName}_local_datasource.dart';
import '../datasources/${featureName}_remote_datasource.dart';
import '../models/${featureName}_model.dart';

class ${pascalCase}RepositoryImpl implements ${pascalCase}Repository {
  final ${pascalCase}RemoteDataSource remoteDataSource;
  final ${pascalCase}LocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  ${pascalCase}RepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
  
  @override
  Future<Either<Failure, List<${pascalCase}Entity>>> getAll${pascalCase}s() async {
    if (await networkInfo.isConnected) {
      try {
        final remote${pascalCase}s = await remoteDataSource.get${pascalCase}s();
        await localDataSource.cache${pascalCase}s(remote${pascalCase}s);
        return Right(remote${pascalCase}s);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final local${pascalCase}s = await localDataSource.getCached${pascalCase}s();
        return Right(local${pascalCase}s);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
  
  @override
  Future<Either<Failure, ${pascalCase}Entity>> get${pascalCase}ById(String id) async {
    // TODO: 实现按 ID 获取的功能
    throw UnimplementedError();
  }
}
''',
    );

    // 领域层文件
    await _createFile('$baseDir/domain/entities/${featureName}_entity.dart', '''
// $pascalCase 实体
// 核心业务实体，与数据源无关

import 'package:equatable/equatable.dart';

class ${pascalCase}Entity extends Equatable {
  final String id;
  // 在此添加更多字段
  
  const ${pascalCase}Entity({
    required this.id,
    // 在此添加必填字段
  });
  
  @override
  List<Object> get props => [id];
}
''');

    await _createFile(
      '$baseDir/domain/repositories/${featureName}_repository.dart',
      '''
// $pascalCase 仓库接口
// 定义数据操作的契约

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/${featureName}_entity.dart';

abstract class ${pascalCase}Repository {
  /// 获取所有 $camelCase 实体
  ///
  /// 返回 [Failure] 或 [List<${pascalCase}Entity>]
  Future<Either<Failure, List<${pascalCase}Entity>>> getAll${pascalCase}s();
  
  /// 根据 ID 获取指定的 $camelCase 实体
  ///
  /// 返回 [Failure] 或 [${pascalCase}Entity]
  Future<Either<Failure, ${pascalCase}Entity>> get${pascalCase}ById(String id);
}
''',
    );

    await _createFile(
      '$baseDir/domain/usecases/get_all_${featureName}s.dart',
      '''
// 获取全部 ${pascalCase}s 的用例
// 获取所有 $camelCase 实体的业务逻辑

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/${featureName}_repository.dart';

class GetAll${pascalCase}s implements UseCase<List<${pascalCase}Entity>, NoParams> {
  final ${pascalCase}Repository repository;
  
  GetAll${pascalCase}s(this.repository);
  
  @override
  Future<Either<Failure, List<${pascalCase}Entity>>> call(NoParams params) {
    return repository.getAll${pascalCase}s();
  }
}
''',
    );

    await _createFile(
      '$baseDir/domain/usecases/get_${featureName}_by_id.dart',
      '''
// 根据 ID 获取 $pascalCase 的用例
// 获取指定 $camelCase 实体的业务逻辑

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/${featureName}_repository.dart';

class Get${pascalCase}ById implements UseCase<${pascalCase}Entity, ${pascalCase}Params> {
  final ${pascalCase}Repository repository;
  
  Get${pascalCase}ById(this.repository);
  
  @override
  Future<Either<Failure, ${pascalCase}Entity>> call(${pascalCase}Params params) {
    return repository.get${pascalCase}ById(params.id);
  }
}

class ${pascalCase}Params extends Equatable {
  final String id;
  
  const ${pascalCase}Params({required this.id});
  
  @override
  List<Object> get props => [id];
}
''',
    );

    // 如请求则添加 UI 文件
    if (withUi) {
      await _createUiFiles(baseDir);
    }

    // Provider 文件
    await _createFile('$baseDir/providers/${featureName}_providers.dart', '''
// $pascalCase Providers
// 为 $featureName feature 提供的 Riverpod providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_info.dart';
import '../data/datasources/${featureName}_local_datasource.dart';
import '../data/datasources/${featureName}_remote_datasource.dart';
import '../data/repositories/${featureName}_repository_impl.dart';
import '../domain/entities/${featureName}_entity.dart';
import '../domain/repositories/${featureName}_repository.dart';
import '../domain/usecases/get_all_${featureName}s.dart';
import '../domain/usecases/get_${featureName}_by_id.dart';

// 数据源
final ${camelCase}RemoteDataSourceProvider = Provider<${pascalCase}RemoteDataSource>(
  (ref) => ${pascalCase}RemoteDataSourceImpl(
    // 在此添加依赖
  ),
);

final ${camelCase}LocalDataSourceProvider = Provider<${pascalCase}LocalDataSource>(
  (ref) => ${pascalCase}LocalDataSourceImpl(
    // 在此添加依赖
  ),
);

// 仓库
final ${camelCase}RepositoryProvider = Provider<${pascalCase}Repository>(
  (ref) => ${pascalCase}RepositoryImpl(
    remoteDataSource: ref.read(${camelCase}RemoteDataSourceProvider),
    localDataSource: ref.read(${camelCase}LocalDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  ),
);

// 用例
final getAll${pascalCase}sProvider = Provider<GetAll${pascalCase}s>(
  (ref) => GetAll${pascalCase}s(ref.read(${camelCase}RepositoryProvider)),
);

final get${pascalCase}ByIdProvider = Provider<Get${pascalCase}ById>(
  (ref) => Get${pascalCase}ById(ref.read(${camelCase}RepositoryProvider)),
);

// 状态 providers
final ${camelCase}ListProvider = FutureProvider<List<${pascalCase}Entity>>(
  (ref) async {
    final usecase = ref.read(getAll${pascalCase}sProvider);
    final result = await usecase(NoParams());
    
    return result.fold(
      (failure) => throw Exception(failure.toString()),
      (${camelCase}s) => ${camelCase}s,
    );
  },
);

final selected${pascalCase}IdProvider = StateProvider<String?>((ref) => null);

final selected${pascalCase}Provider = FutureProvider<${pascalCase}Entity?>((ref) async {
  final id = ref.watch(selected${pascalCase}IdProvider);
  if (id == null) return null;
  
  final usecase = ref.read(get${pascalCase}ByIdProvider);
  final result = await usecase(${pascalCase}Params(id: id));
  
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    ($camelCase) => $camelCase,
  );
});
''');

    // 如请求则创建测试文件
    if (withTests) {
      await _createTestFiles();
    }

    // 如请求则创建文档
    if (withDocs) {
      await _createDocFiles();
    }
  }

  /// 创建表现层文件
  Future<void> _createUiFiles(String baseDir) async {
    await _createFile(
      '$baseDir/presentation/screens/${featureName}_list_screen.dart',
      '''
// $pascalCase 列表页面
// 显示 $camelCase 项目列表的页面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/${featureName}_providers.dart';
import '../widgets/${featureName}_list_item.dart';

class ${pascalCase}ListScreen extends ConsumerWidget {
  const ${pascalCase}ListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ${camelCase}sAsync = ref.watch(${camelCase}ListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('${pascalCase}s'),
      ),
      body: ${camelCase}sAsync.when(
        data: (${camelCase}s) => ListView.builder(
          itemCount: ${camelCase}s.length,
          itemBuilder: (context, index) => ${pascalCase}ListItem(
            $camelCase: ${camelCase}s[index],
            onTap: () {
              ref.read(selected${pascalCase}IdProvider.notifier).state = ${camelCase}s[index].id;
              // 跳转到详情页面
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: \${error.toString()}'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加新的 $camelCase 操作
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
''',
    );

    await _createFile(
      '$baseDir/presentation/screens/${featureName}_detail_screen.dart',
      '''
// $pascalCase 详情页面
// 显示指定 $camelCase 详情的页面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/${featureName}_providers.dart';

class ${pascalCase}DetailScreen extends ConsumerWidget {
  const ${pascalCase}DetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ${camelCase}Async = ref.watch(selected${pascalCase}Provider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascalCase Details'),
      ),
      body: ${camelCase}Async.when(
        data: ($camelCase) {
          if ($camelCase == null) {
            return const Center(child: Text('$pascalCase not found'));
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: \${$camelCase.id}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                // 在此添加更多字段
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: \${error.toString()}'),
        ),
      ),
    );
  }
}
''',
    );

    await _createFile(
      '$baseDir/presentation/widgets/${featureName}_list_item.dart',
      '''
// $pascalCase 列表项
// 在列表中显示单个 $camelCase 的组件

import 'package:flutter/material.dart';

import '../../domain/entities/${featureName}_entity.dart';

class ${pascalCase}ListItem extends StatelessWidget {
  final ${pascalCase}Entity $camelCase;
  final VoidCallback onTap;
  
  const ${pascalCase}ListItem({
    Key? key,
    required this.$camelCase,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('$pascalCase \${$camelCase.id}'),
        // 在此添加更多详情
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
''',
    );

    await _createFile(
      '$baseDir/presentation/providers/${featureName}_ui_providers.dart',
      '''
// $pascalCase UI Providers
// 专用于 UI 状态的 Riverpod providers

import 'package:flutter_riverpod/flutter_riverpod.dart';

// UI 状态 providers
final ${camelCase}FilterProvider = StateProvider<String>((ref) => '');

final ${camelCase}SortOrderProvider = StateProvider<SortOrder>((ref) => SortOrder.asc);

enum SortOrder { asc, desc }
''',
    );
  }

  /// 创建测试文件
  Future<void> _createTestFiles() async {
    // TODO: 实现测试文件的创建
    // 这将镜像 shell 脚本的测试文件创建
  }

  /// 创建文档文件
  Future<void> _createDocFiles() async {
    // TODO: 实现文档文件的创建
    // 这将镜像 shell 脚本的文档文件创建
  }

  /// 辅助方法：创建目录及其父目录（若不存在）
  Future<void> _createDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      stdout.writeln('Created directory: $path');
    }
  }

  /// 辅助方法：使用给定内容创建文件
  Future<void> _createFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
    stdout.writeln('Created file: $path');
  }

  /// 将 snake_case 转换为 PascalCase
  String _toPascalCase(String input) {
    return input
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join('');
  }

  /// 将 snake_case 转换为 camelCase
  String _toCamelCase(String input) {
    final pascal = _toPascalCase(input);
    return pascal.isEmpty ? '' : pascal[0].toLowerCase() + pascal.substring(1);
  }
}

void main(List<String> args) {
  // 使用示例：
  // dart run lib/core/cli/feature_generator.dart user_profile
  if (args.isEmpty) {
    stdout.writeln('Please provide a feature name in snake_case format.');
    return;
  }

  final generator = FeatureGenerator(featureName: args.first);
  generator.generate();
}
