#!/bin/bash

# Flutter Riverpod 整洁架构 - Feature 生成器
# 使用现代 Riverpod 与整洁架构最佳实践生成一个 feature。

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

usage() {
  echo -e "${YELLOW}Usage: $0 [options] --name <feature_name>${NC}"
  echo -e "\nOptions:"
  echo -e "  --name <feature_name>    Feature 名称（必填，使用 snake_case）"
  echo -e "  --no-ui                  不生成 UI/presentation 层"
  echo -e "  --no-repo                不生成 repository 模式（简化结构）"
  echo -e "  --help                   显示本帮助信息"
  echo -e "\nExamples:"
  echo -e "  $0 --name user_profile"
  echo -e "  $0 --name auth --no-ui"
  exit 1
}

# 默认值
FEATURE_NAME=""
WITH_UI="yes"
WITH_REPO="yes"

# 解析参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --name)
      FEATURE_NAME="$2"; shift 2;;
    --no-ui)
      WITH_UI="no"; shift;;
    --no-repo)
      WITH_REPO="no"; shift;;
    --help)
      usage;;
    *)
      echo -e "${RED}未知选项: $1${NC}"; usage;;
  esac
done

if [[ -z "$FEATURE_NAME" ]]; then
  echo -e "${RED}Error: --name 为必填项${NC}"; usage
fi

# 将 snake_case 转换为 PascalCase 与 camelCase
PASCAL_CASE=$(echo "$FEATURE_NAME" | awk -F_ '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' OFS='')
CAMEL_CASE="$(tr '[:upper:]' '[:lower:]' <<< ${PASCAL_CASE:0:1})${PASCAL_CASE:1}"

BASE_DIR="lib/features/$FEATURE_NAME"

if [[ -d "$BASE_DIR" ]]; then
  echo -e "${RED}Error: Feature $FEATURE_NAME 已存在于 $BASE_DIR${NC}"; exit 1
fi

echo -e "${BLUE}正在生成 feature: $FEATURE_NAME ($PASCAL_CASE)${NC}"

# 创建目录
if [[ "$WITH_REPO" == "yes" ]]; then
  mkdir -p "$BASE_DIR/data/datasources"
  mkdir -p "$BASE_DIR/data/models"
  mkdir -p "$BASE_DIR/data/repositories"
  mkdir -p "$BASE_DIR/domain/entities"
  mkdir -p "$BASE_DIR/domain/repositories"
  mkdir -p "$BASE_DIR/domain/usecases"
else
  mkdir -p "$BASE_DIR/data/models"
fi

if [[ "$WITH_UI" == "yes" ]]; then
  mkdir -p "$BASE_DIR/presentation/controllers"
  mkdir -p "$BASE_DIR/presentation/screens"
  mkdir -p "$BASE_DIR/presentation/widgets"
fi

# ==========================================
# Domain 层
# ==========================================

if [[ "$WITH_REPO" == "yes" ]]; then
  # 实体（Entity）
  cat > "$BASE_DIR/domain/entities/${FEATURE_NAME}_entity.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';

part '${FEATURE_NAME}_entity.freezed.dart';

@freezed
abstract class ${PASCAL_CASE}Entity with _\$${PASCAL_CASE}Entity {
  const factory ${PASCAL_CASE}Entity({
    required String id,
    required String name,
  }) = _${PASCAL_CASE}Entity;
}
EOF

  # 仓库接口（Repository Interface）
  cat > "$BASE_DIR/domain/repositories/${FEATURE_NAME}_repository.dart" << EOF
import '../entities/${FEATURE_NAME}_entity.dart';

abstract class ${PASCAL_CASE}Repository {
  Future<List<${PASCAL_CASE}Entity>> get${PASCAL_CASE}s();
  Future<${PASCAL_CASE}Entity> get${PASCAL_CASE}(String id);
}
EOF

  # UseCases
  cat > "$BASE_DIR/domain/usecases/get_${FEATURE_NAME}s_usecase.dart" << EOF
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/${FEATURE_NAME}_entity.dart';
import '../repositories/${FEATURE_NAME}_repository.dart';
import '../../data/repositories/${FEATURE_NAME}_repository_impl.dart';

part 'get_${FEATURE_NAME}s_usecase.g.dart';

@riverpod
Future<List<${PASCAL_CASE}Entity>> get${PASCAL_CASE}s(Ref ref) {
  return ref.watch(${CAMEL_CASE}RepositoryProvider).get${PASCAL_CASE}s();
}
EOF
fi

# ==========================================
# Data 层
# ==========================================

# 模型（Model）
cat > "$BASE_DIR/data/models/${FEATURE_NAME}_model.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';
EOF

if [[ "$WITH_REPO" == "yes" ]]; then
  cat >> "$BASE_DIR/data/models/${FEATURE_NAME}_model.dart" << EOF
import '../../domain/entities/${FEATURE_NAME}_entity.dart';

part '${FEATURE_NAME}_model.freezed.dart';
part '${FEATURE_NAME}_model.g.dart';

@freezed
abstract class ${PASCAL_CASE}Model with _\$${PASCAL_CASE}Model {
  const ${PASCAL_CASE}Model._();

  const factory ${PASCAL_CASE}Model({
    required String id,
    required String name,
  }) = _${PASCAL_CASE}Model;

  factory ${PASCAL_CASE}Model.fromJson(Map<String, dynamic> json) => 
      _\$${PASCAL_CASE}ModelFromJson(json);

  ${PASCAL_CASE}Entity toEntity() => ${PASCAL_CASE}Entity(id: id, name: name);
}
EOF
else
  cat >> "$BASE_DIR/data/models/${FEATURE_NAME}_model.dart" << EOF

part '${FEATURE_NAME}_model.freezed.dart';
part '${FEATURE_NAME}_model.g.dart';

@freezed
abstract class ${PASCAL_CASE}Model with _\$${PASCAL_CASE}Model {
  const factory ${PASCAL_CASE}Model({
    required String id,
    required String name,
  }) = _${PASCAL_CASE}Model;

  factory ${PASCAL_CASE}Model.fromJson(Map<String, dynamic> json) => 
      _\$${PASCAL_CASE}ModelFromJson(json);
}
EOF
fi

if [[ "$WITH_REPO" == "yes" ]]; then
  # 数据源（DataSource）
  cat > "$BASE_DIR/data/datasources/${FEATURE_NAME}_remote_data_source.dart" << EOF
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/network_providers.dart';
import '../models/${FEATURE_NAME}_model.dart';

part '${FEATURE_NAME}_remote_data_source.g.dart';

abstract class ${PASCAL_CASE}RemoteDataSource {
  Future<List<${PASCAL_CASE}Model>> fetch${PASCAL_CASE}s();
  Future<${PASCAL_CASE}Model> fetch${PASCAL_CASE}(String id);
}

@riverpod
${PASCAL_CASE}RemoteDataSource ${CAMEL_CASE}RemoteDataSource(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ${PASCAL_CASE}RemoteDataSourceImpl(dio);
}

class ${PASCAL_CASE}RemoteDataSourceImpl implements ${PASCAL_CASE}RemoteDataSource {
  final Dio _dio;
  
  ${PASCAL_CASE}RemoteDataSourceImpl(this._dio);

  @override
  Future<List<${PASCAL_CASE}Model>> fetch${PASCAL_CASE}s() async {
    // 示例：final response = await _dio.get('/${FEATURE_NAME}s');
    // 示例：return (response.data as List).map((e) => ${PASCAL_CASE}Model.fromJson(e)).toList();
    await Future.delayed(const Duration(seconds: 1));
    return [
      const ${PASCAL_CASE}Model(id: '1', name: 'Item 1'),
      const ${PASCAL_CASE}Model(id: '2', name: 'Item 2'),
    ];
  }

  @override
  Future<${PASCAL_CASE}Model> fetch${PASCAL_CASE}(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    return ${PASCAL_CASE}Model(id: id, name: 'Item $id');
  }
}
EOF

  # 仓库实现（Repository Impl）
  cat > "$BASE_DIR/data/repositories/${FEATURE_NAME}_repository_impl.dart" << EOF
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/${FEATURE_NAME}_entity.dart';
import '../../domain/repositories/${FEATURE_NAME}_repository.dart';
import '../datasources/${FEATURE_NAME}_remote_data_source.dart';

part '${FEATURE_NAME}_repository_impl.g.dart';

@riverpod
${PASCAL_CASE}Repository ${CAMEL_CASE}Repository(Ref ref) {
  final remoteDataSource = ref.watch(${CAMEL_CASE}RemoteDataSourceProvider);
  return ${PASCAL_CASE}RepositoryImpl(remoteDataSource);
}

class ${PASCAL_CASE}RepositoryImpl implements ${PASCAL_CASE}Repository {
  final ${PASCAL_CASE}RemoteDataSource _remoteDataSource;

  ${PASCAL_CASE}RepositoryImpl(this._remoteDataSource);

  @override
  Future<List<${PASCAL_CASE}Entity>> get${PASCAL_CASE}s() async {
    final models = await _remoteDataSource.fetch${PASCAL_CASE}s();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<${PASCAL_CASE}Entity> get${PASCAL_CASE}(String id) async {
    final model = await _remoteDataSource.fetch${PASCAL_CASE}(id);
    return model.toEntity();
  }
}
EOF
fi

# ==========================================
# Presentation 层
# ==========================================

if [[ "$WITH_UI" == "yes" ]]; then
  # 控制器（Controller）
  cat > "$BASE_DIR/presentation/controllers/${FEATURE_NAME}_controller.dart" << EOF
import 'package:riverpod_annotation/riverpod_annotation.dart';
EOF

  if [[ "$WITH_REPO" == "yes" ]]; then
  cat >> "$BASE_DIR/presentation/controllers/${FEATURE_NAME}_controller.dart" << EOF
import '../../domain/entities/${FEATURE_NAME}_entity.dart';
import '../../domain/usecases/get_${FEATURE_NAME}s_usecase.dart';

part '${FEATURE_NAME}_controller.g.dart';

@riverpod
class ${PASCAL_CASE}Controller extends _\$${PASCAL_CASE}Controller {
  @override
  FutureOr<List<${PASCAL_CASE}Entity>> build() {
    return ref.watch(get${PASCAL_CASE}sProvider.future);
  }
  
  Future<void> refresh() async {
     state = const AsyncValue.loading();
     state = await AsyncValue.guard(() => ref.refresh(get${PASCAL_CASE}sProvider.future));
  }
}
EOF
  else
    # 直接使用 Model 的简单控制器
    cat >> "$BASE_DIR/presentation/controllers/${FEATURE_NAME}_controller.dart" << EOF
import '../../data/models/${FEATURE_NAME}_model.dart';

part '${FEATURE_NAME}_controller.g.dart';

@riverpod
class ${PASCAL_CASE}Controller extends _\$${PASCAL_CASE}Controller {
  @override
  FutureOr<List<${PASCAL_CASE}Model>> build() async {
    // 模拟 API 调用
    await Future.delayed(const Duration(seconds: 1));
    return [
       const ${PASCAL_CASE}Model(id: '1', name: 'Simple Item 1'),
       const ${PASCAL_CASE}Model(id: '2', name: 'Simple Item 2'),
    ];
  }
}
EOF
  fi

  # 页面（Screen）
  cat > "$BASE_DIR/presentation/screens/${FEATURE_NAME}_screen.dart" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/${FEATURE_NAME}_controller.dart';

class ${PASCAL_CASE}Screen extends ConsumerWidget {
  const ${PASCAL_CASE}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ${CAMEL_CASE}State = ref.watch(${CAMEL_CASE}ControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('${PASCAL_CASE} Feature'),
      ),
      body: ${CAMEL_CASE}State.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text(item.id),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: \$err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(${CAMEL_CASE}ControllerProvider.notifier).refresh(); // 或其他专用方法
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
EOF
fi

echo -e "${GREEN}Feature $FEATURE_NAME 生成成功！${NC}"
echo -e "${YELLOW}别忘了运行:${NC} ${BLUE}dart run build_runner build -d${NC}"
