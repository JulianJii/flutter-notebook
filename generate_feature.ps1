# Feature Generator (Windows / PowerShell)
# 与 generate_feature.sh 行为一致：生成四层 feature 脚手架。
# 用法（PowerShell 7 / Windows PowerShell）：
#   powershell -ExecutionPolicy Bypass -File .\generate_feature.ps1 --name user_profile
#   powershell -ExecutionPolicy Bypass -File .\generate_feature.ps1 --name auth --no-ui

# 不声明 param()，统一手工解析 $args，保持与 .sh 相同的命令行约定。

$ErrorActionPreference = 'Stop'

# 写入 Dart 文件：UTF-8 无 BOM + LF 换行 + 结尾换行
function Write-DartFile {
    param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $text = $Content -replace "`r`n", "`n"
    if (-not $text.EndsWith("`n")) { $text += "`n" }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $text, $utf8)
}

function Show-Usage {
    Write-Host "Usage: generate_feature.ps1 [options] --name <feature_name>"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --name <feature_name>    Name of the feature (required, use snake_case)"
    Write-Host "  --no-ui                  Generate without UI/presentation layer"
    Write-Host "  --no-repo                Generate without repository pattern (simplified structure)"
    Write-Host "  --help                   Display this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\generate_feature.ps1 --name user_profile"
    Write-Host "  .\generate_feature.ps1 --name auth --no-ui"
    exit 1
}

# ---- 解析参数 ----
$featureName = $null
$withUi = $true
$withRepo = $true

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '--name' { $featureName = $args[++$i] }
        '--no-ui' { $withUi = $false }
        '--no-repo' { $withRepo = $false }
        '--help' { Show-Usage }
        default {
            Write-Host "Error: Unknown option: $($args[$i])" -ForegroundColor Red
            Show-Usage
        }
    }
}

if (-not $featureName) {
    Write-Host 'Error: --name is required' -ForegroundColor Red
    Show-Usage
}

# snake_case -> PascalCase / camelCase
$pascalCase = (($featureName -split '_') | Where-Object { $_ -ne '' } | ForEach-Object {
        $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1)
    }) -join ''
$camelCase = $pascalCase.Substring(0, 1).ToLowerInvariant() + $pascalCase.Substring(1)

# 定位项目根目录并校验
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

$baseDir = "lib/features/$featureName"
if (Test-Path -LiteralPath $baseDir) {
    Write-Host "Error: Feature $featureName already exists at $baseDir" -ForegroundColor Red
    exit 1
}

Write-Host "Generating feature: $featureName ($pascalCase)" -ForegroundColor Blue

# ==========================================
# Domain Layer
# ==========================================
if ($withRepo) {
    Write-DartFile "$baseDir/domain/entities/${featureName}_entity.dart" @"
import 'package:freezed_annotation/freezed_annotation.dart';

part '${featureName}_entity.freezed.dart';

@freezed
abstract class ${pascalCase}Entity with _`$${pascalCase}Entity {
  const factory ${pascalCase}Entity({
    required String id,
    required String name,
  }) = _${pascalCase}Entity;
}
"@

    Write-DartFile "$baseDir/domain/repositories/${featureName}_repository.dart" @"
import '../entities/${featureName}_entity.dart';

abstract class ${pascalCase}Repository {
  Future<List<${pascalCase}Entity>> get${pascalCase}s();
  Future<${pascalCase}Entity> get${pascalCase}(String id);
}
"@

    Write-DartFile "$baseDir/domain/usecases/get_${featureName}s_usecase.dart" @"
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../entities/${featureName}_entity.dart';
import '../repositories/${featureName}_repository.dart';
import '../../data/repositories/${featureName}_repository_impl.dart';

part 'get_${featureName}s_usecase.g.dart';

@riverpod
Future<List<${pascalCase}Entity>> get${pascalCase}s(Ref ref) {
  return ref.watch(${camelCase}RepositoryProvider).get${pascalCase}s();
}
"@
}

# ==========================================
# Data Layer
# ==========================================
if ($withRepo) {
    Write-DartFile "$baseDir/data/models/${featureName}_model.dart" @"
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/${featureName}_entity.dart';

part '${featureName}_model.freezed.dart';
part '${featureName}_model.g.dart';

@freezed
abstract class ${pascalCase}Model with _`$${pascalCase}Model {
  const ${pascalCase}Model._();

  const factory ${pascalCase}Model({
    required String id,
    required String name,
  }) = _${pascalCase}Model;

  factory ${pascalCase}Model.fromJson(Map<String, dynamic> json) => 
      _`$${pascalCase}ModelFromJson(json);

  ${pascalCase}Entity toEntity() => ${pascalCase}Entity(id: id, name: name);
}
"@
} else {
    Write-DartFile "$baseDir/data/models/${featureName}_model.dart" @"
import 'package:freezed_annotation/freezed_annotation.dart';

part '${featureName}_model.freezed.dart';
part '${featureName}_model.g.dart';

@freezed
abstract class ${pascalCase}Model with _`$${pascalCase}Model {
  const factory ${pascalCase}Model({
    required String id,
    required String name,
  }) = _${pascalCase}Model;

  factory ${pascalCase}Model.fromJson(Map<String, dynamic> json) => 
      _`$${pascalCase}ModelFromJson(json);
}
"@
}

if ($withRepo) {
    Write-DartFile "$baseDir/data/datasources/${featureName}_remote_data_source.dart" @"
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/network_providers.dart';
import '../models/${featureName}_model.dart';

part '${featureName}_remote_data_source.g.dart';

abstract class ${pascalCase}RemoteDataSource {
  Future<List<${pascalCase}Model>> fetch${pascalCase}s();
  Future<${pascalCase}Model> fetch${pascalCase}(String id);
}

@riverpod
${pascalCase}RemoteDataSource ${camelCase}RemoteDataSource(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ${pascalCase}RemoteDataSourceImpl(dio);
}

class ${pascalCase}RemoteDataSourceImpl implements ${pascalCase}RemoteDataSource {
  final Dio _dio;
  
  ${pascalCase}RemoteDataSourceImpl(this._dio);

  @override
  Future<List<${pascalCase}Model>> fetch${pascalCase}s() async {
    // final response = await _dio.get('/${featureName}s');
    // return (response.data as List).map((e) => ${pascalCase}Model.fromJson(e)).toList();
    await Future.delayed(const Duration(seconds: 1));
    return [
      const ${pascalCase}Model(id: '1', name: 'Item 1'),
      const ${pascalCase}Model(id: '2', name: 'Item 2'),
    ];
  }

  @override
  Future<${pascalCase}Model> fetch${pascalCase}(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    return ${pascalCase}Model(id: id, name: 'Item `$id');
  }
}
"@

    Write-DartFile "$baseDir/data/repositories/${featureName}_repository_impl.dart" @"
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/${featureName}_entity.dart';
import '../../domain/repositories/${featureName}_repository.dart';
import '../datasources/${featureName}_remote_data_source.dart';

part '${featureName}_repository_impl.g.dart';

@riverpod
${pascalCase}Repository ${camelCase}Repository(Ref ref) {
  final remoteDataSource = ref.watch(${camelCase}RemoteDataSourceProvider);
  return ${pascalCase}RepositoryImpl(remoteDataSource);
}

class ${pascalCase}RepositoryImpl implements ${pascalCase}Repository {
  final ${pascalCase}RemoteDataSource _remoteDataSource;

  ${pascalCase}RepositoryImpl(this._remoteDataSource);

  @override
  Future<List<${pascalCase}Entity>> get${pascalCase}s() async {
    final models = await _remoteDataSource.fetch${pascalCase}s();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<${pascalCase}Entity> get${pascalCase}(String id) async {
    final model = await _remoteDataSource.fetch${pascalCase}(id);
    return model.toEntity();
  }
}
"@
}

# ==========================================
# Presentation Layer
# ==========================================
if ($withUi) {
    if ($withRepo) {
        Write-DartFile "$baseDir/presentation/controllers/${featureName}_controller.dart" @"
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/${featureName}_entity.dart';
import '../../domain/usecases/get_${featureName}s_usecase.dart';

part '${featureName}_controller.g.dart';

@riverpod
class ${pascalCase}Controller extends _`$${pascalCase}Controller {
  @override
  FutureOr<List<${pascalCase}Entity>> build() {
    return ref.watch(get${pascalCase}sProvider.future);
  }
  
  Future<void> refresh() async {
     state = const AsyncValue.loading();
     state = await AsyncValue.guard(() => ref.refresh(get${pascalCase}sProvider.future));
  }
}
"@
    } else {
        Write-DartFile "$baseDir/presentation/controllers/${featureName}_controller.dart" @"
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/${featureName}_model.dart';

part '${featureName}_controller.g.dart';

@riverpod
class ${pascalCase}Controller extends _`$${pascalCase}Controller {
  @override
  FutureOr<List<${pascalCase}Model>> build() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    return [
       const ${pascalCase}Model(id: '1', name: 'Simple Item 1'),
       const ${pascalCase}Model(id: '2', name: 'Simple Item 2'),
    ];
  }
}
"@
    }

    Write-DartFile "$baseDir/presentation/screens/${featureName}_screen.dart" @"
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/${featureName}_controller.dart';

class ${pascalCase}Screen extends ConsumerWidget {
  const ${pascalCase}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ${camelCase}State = ref.watch(${camelCase}ControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('${pascalCase} Feature'),
      ),
      body: ${camelCase}State.when(
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
        error: (err, stack) => Center(child: Text('Error: `$err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(${camelCase}ControllerProvider.notifier).refresh(); // Or specialized method
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
"@
}

Write-Host "Feature $featureName generated successfully!" -ForegroundColor Green
Write-Host "Don't forget to run: " -ForegroundColor Yellow -NoNewline
Write-Host "dart run build_runner build -d" -ForegroundColor Blue
exit 0
