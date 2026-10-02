# Flutter App Renamer (Windows / PowerShell)
# 与 rename_app.sh 行为一致：重命名应用并在各平台更新包名。
# 用法（PowerShell 7 / Windows PowerShell）：
#   powershell -ExecutionPolicy Bypass -File .\rename_app.ps1 --app-name "My App" --package-name com.wode.myapp

# 不声明 param()，否则 PowerShell 会把 --app-name 之类当作参数名并报错；
# 因此统一手工解析 $args，保持与 .sh 相同的命令行约定。

$ErrorActionPreference = 'Stop'

# 就地正则替换（.NET 正则，替换串按字面插入，避免 $ 被当作分组引用）
function Edit-TextFile {
    param([string]$Path, [string]$Pattern, [string]$Replacement)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($Path)
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $Replacement }
    $result = [regex]::Replace($content, $Pattern, $evaluator)
    [System.IO.File]::WriteAllText($Path, $result, $utf8)
}

# 更新 Info.plist 中某个 key 对应的 <string> 值；key 不存在时按需追加
function Set-PlistValue {
    param([string]$Path, [string]$Key, [string]$Value, [switch]$InsertWhenMissing)
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($Path)
    $pattern = '(?s)<key>' + [regex]::Escape($Key) + '</key>\s*<string>(.*?)</string>'
    $block = '<key>' + $Key + '</key>' + "`n`t<string>" + $Value + '</string>'
    $existing = [regex]::Match($content, $pattern)
    if ($existing.Success) {
        # 值为 $(...) 构建变量时不覆盖（如 $(PRODUCT_NAME) / $(PRODUCT_BUNDLE_IDENTIFIER)）
        if ($existing.Groups[1].Value -match '^\$\(.+\)$') { return }
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $block }
        $content = [regex]::Replace($content, $pattern, $evaluator)
    } elseif ($InsertWhenMissing -and $content -match '(?s)<key>CFBundleDisplayName</key>\s*<string>.*?</string>') {
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $m.Groups[0].Value + "`n`t" + $block }
        $content = [regex]::Replace($content, '(?s)(<key>CFBundleDisplayName</key>\s*<string>.*?</string>)', $evaluator)
    } else {
        return
    }
    [System.IO.File]::WriteAllText($Path, $content, $utf8)
}

function Show-Usage {
    Write-Host "Usage: rename_app.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host '  --app-name "New App Name"            Set the new app display name (required)'
    Write-Host "  --package-name com.wode.newapp     Set the new package name (optional; keeps current if omitted)"
    Write-Host "  --help                                Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host '  .\rename_app.ps1 --app-name "My Amazing App" --package-name com.mycompany.amazingapp'
    Write-Host ""
    exit 1
}

# ---- 解析参数 ----
$newAppName = $null
$newPackageName = $null
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '--app-name' { $newAppName = $args[++$i] }
        '--package-name' { $newPackageName = $args[++$i] }
        '--help' { Show-Usage }
        default {
            Write-Host "Error: Unknown option: $($args[$i])" -ForegroundColor Red
            Show-Usage
        }
    }
}

# ---- 校验参数（--package-name 可选：省略则沿用当前包名）----
if (-not $newAppName) {
    Write-Host 'Error: --app-name is required' -ForegroundColor Red
    Show-Usage
}
if ($newPackageName -and $newPackageName -cnotmatch '^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$') {
    Write-Host 'Error: Package name must be in valid format (e.g., com.wode.app)' -ForegroundColor Red
    exit 1
}

# ---- 定位项目根目录并校验 ----
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)
$root = Get-Location
$pubspecPath = Join-Path $root 'pubspec.yaml'
if (-not (Test-Path $pubspecPath)) {
    Write-Host 'Error: pubspec.yaml not found. Please run this script from the root of your Flutter project.' -ForegroundColor Red
    exit 1
}

# 显示名 -> 合法 Dart 包名（小写，空格/连字符 -> 下划线）
# 注：.sh 里该值在最后一步才计算，却在 Windows/Linux 步骤提前引用（恒为空）。
# 此处提前算出，避免 .sh 中的这个 bug。
$pubspecAppName = ($newAppName.ToLowerInvariant() -replace '[\s-]+', '_')

$pubspecContent = [System.IO.File]::ReadAllText($pubspecPath)
$nameMatch = [regex]::Match($pubspecContent, '(?m)^name:\s*([^\s#]+)')
if (-not $nameMatch.Success) {
    Write-Host 'Error: Could not determine current package name from pubspec.yaml' -ForegroundColor Red
    exit 1
}
$currentAppName = $nameMatch.Groups[1].Value

# 当前 Android 包名：优先 AndroidManifest 的 package=；现代模板已移除该属性，
# 回退到 build.gradle(.kts) 的 namespace / applicationId。必须在改写 gradle 之前取值。
$manifest = 'android/app/src/main/AndroidManifest.xml'
$gradleGroovy = 'android/app/build.gradle'
$gradleKts = 'android/app/build.gradle.kts'
$oldPackageName = $null
if (Test-Path $manifest) {
    $packageMatch = [regex]::Match([System.IO.File]::ReadAllText($manifest), 'package="([^"]+)"')
    if ($packageMatch.Success) { $oldPackageName = $packageMatch.Groups[1].Value }
}
if (-not $oldPackageName) {
    if (Test-Path $gradleKts) {
        $c = [System.IO.File]::ReadAllText($gradleKts)
        $m = [regex]::Match($c, 'namespace = "([^"]+)"')
        if (-not $m.Success) { $m = [regex]::Match($c, 'applicationId = "([^"]+)"') }
        if ($m.Success) { $oldPackageName = $m.Groups[1].Value }
    } elseif (Test-Path $gradleGroovy) {
        $c = [System.IO.File]::ReadAllText($gradleGroovy)
        $m = [regex]::Match($c, 'namespace "([^"]+)"')
        if (-not $m.Success) { $m = [regex]::Match($c, 'applicationId "([^"]+)"') }
        if ($m.Success) { $oldPackageName = $m.Groups[1].Value }
    }
}

# --package-name 省略 = 只改“名字”（显示名 + .app/二进制/工程名）；包名/Bundle ID 保持不动，且不改 Dart 包名(pubspec name)与源码 import。
# ponytail: 假定各平台包名/Bundle ID 与 Android 当前值一致；若某平台单独改过，请显式传 --package-name。
$keepPackageName = $false
if (-not $newPackageName) {
    if (-not $oldPackageName) {
        Write-Host 'Error: --package-name omitted but the current package could not be inferred from android/. Please pass it explicitly.' -ForegroundColor Red
        exit 1
    }
    $newPackageName = $oldPackageName
    $keepPackageName = $true
}

Write-Host "Current app name identifier: $currentAppName" -ForegroundColor Yellow
Write-Host "New app display name: $newAppName" -ForegroundColor Yellow
if ($keepPackageName) {
    Write-Host "New package name: $newPackageName (keeping current)" -ForegroundColor Yellow
} else {
    Write-Host "New package name: $newPackageName" -ForegroundColor Yellow
}

$answer = Read-Host "`nDo you want to proceed with renaming? This operation cannot be easily undone. (y/N)"
if ($answer -cnotmatch '^[Yy]') {
    Write-Host 'Operation canceled.' -ForegroundColor Yellow
    exit 0
}

Write-Host 'Starting renaming process...' -ForegroundColor Cyan

# ---- 1. Android ----
Write-Host '[1/8] Updating Android files' -ForegroundColor Cyan
if (Test-Path 'android') {
    $stringsXml = 'android/app/src/main/res/values/strings.xml'
    if (-not (Test-Path $stringsXml)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $stringsXml) | Out-Null
        $lines = @(
            '<?xml version="1.0" encoding="utf-8"?>',
            '<resources>',
            '    <string name="app_name">' + $newAppName + '</string>',
            '</resources>'
        )
        [System.IO.File]::WriteAllText($stringsXml, ($lines -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
    } else {
        Edit-TextFile $stringsXml '(?s)<string name="app_name">.*?</string>' ('<string name="app_name">' + $newAppName + '</string>')
    }

    # 旧包名已在确认前取好（见上方），这里直接复用；保持当前包名时跳过 gradle 改写。
    if (-not $keepPackageName -and (Test-Path $gradleGroovy)) {
        Edit-TextFile $gradleGroovy 'applicationId ".*"' ('applicationId "' + $newPackageName + '"')
        Edit-TextFile $gradleGroovy 'namespace ".*"' ('namespace "' + $newPackageName + '"')
    } elseif (-not $keepPackageName -and (Test-Path $gradleKts)) {
        Edit-TextFile $gradleKts 'applicationId = ".*"' ('applicationId = "' + $newPackageName + '"')
        Edit-TextFile $gradleKts 'namespace = ".*"' ('namespace = "' + $newPackageName + '"')
    }

    if ((Test-Path $manifest) -and $oldPackageName) {
        Edit-TextFile $manifest ('package="' + $oldPackageName + '"') ('package="' + $newPackageName + '"')
    }

    # 移动 Android 包目录并更新 Kotlin/Java 里的 package 声明
    # 新旧包名相同时跳过搬迁：否则自移动失败后 Remove-Item 会误删源码。
    if ($oldPackageName -and $newPackageName -ne $oldPackageName) {
        $oldPath = $oldPackageName.Replace('.', '/')
        $newPath = $newPackageName.Replace('.', '/')
        foreach ($srcRoot in @('java', 'kotlin')) {
            $oldDir = 'android/app/src/main/' + $srcRoot + '/' + $oldPath
            $newDir = 'android/app/src/main/' + $srcRoot + '/' + $newPath
            if (Test-Path -LiteralPath $oldDir) {
                New-Item -ItemType Directory -Force -Path $newDir | Out-Null
                Get-ChildItem -LiteralPath $oldDir | Move-Item -Destination $newDir -Force
                Get-ChildItem -LiteralPath $newDir -Recurse -File | Where-Object { $_.Extension -in '.kt', '.java' } | ForEach-Object {
                    Edit-TextFile $_.FullName ('(?m)^package ' + [regex]::Escape($oldPackageName)) ('package ' + $newPackageName)
                }
                Remove-Item -LiteralPath $oldDir -Recurse -Force
            }
        }
    }
}

# ---- 2. iOS ----
Write-Host '[2/8] Updating iOS files' -ForegroundColor Cyan
$iosPlist = 'ios/Runner/Info.plist'
if (Test-Path $iosPlist) {
    Set-PlistValue $iosPlist 'CFBundleName' $newAppName -InsertWhenMissing
    Set-PlistValue $iosPlist 'CFBundleDisplayName' $newAppName
    # bundle identifier 由 project.pbxproj 控制，Info.plist 保持 $(PRODUCT_BUNDLE_IDENTIFIER) 不动
}
# 保持当前包名时跳过；只替换主 Target 的 Bundle ID，保留 .RunnerTests 等后缀
if (-not $keepPackageName -and (Test-Path 'ios/Runner.xcodeproj/project.pbxproj')) {
    $oldBundle = Get-Content 'ios/Runner.xcodeproj/project.pbxproj' | ForEach-Object { if ($_ -match 'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);') { $matches[1] } } | Where-Object { $_ -notmatch 'Tests' } | Select-Object -First 1
    if ($oldBundle) {
        Edit-TextFile 'ios/Runner.xcodeproj/project.pbxproj' ('PRODUCT_BUNDLE_IDENTIFIER = ' + [regex]::Escape($oldBundle)) ('PRODUCT_BUNDLE_IDENTIFIER = ' + $newPackageName)
    }
}

# ---- 3. macOS ----
Write-Host '[3/8] Updating macOS files' -ForegroundColor Cyan
$macPlist = 'macos/Runner/Info.plist'
if (Test-Path $macPlist) {
    Set-PlistValue $macPlist 'CFBundleName' $newAppName
    Set-PlistValue $macPlist 'CFBundleDisplayName' $newAppName
    # bundle identifier 由 project.pbxproj 控制，Info.plist 保持 $(PRODUCT_BUNDLE_IDENTIFIER) 不动
}
# 保持当前包名时跳过；只替换主 Target 的 Bundle ID，保留 .RunnerTests 等后缀
if (-not $keepPackageName -and (Test-Path 'macos/Runner.xcodeproj/project.pbxproj')) {
    $oldBundle = Get-Content 'macos/Runner.xcodeproj/project.pbxproj' | ForEach-Object { if ($_ -match 'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);') { $matches[1] } } | Where-Object { $_ -notmatch 'Tests' } | Select-Object -First 1
    if ($oldBundle) {
        Edit-TextFile 'macos/Runner.xcodeproj/project.pbxproj' ('PRODUCT_BUNDLE_IDENTIFIER = ' + [regex]::Escape($oldBundle)) ('PRODUCT_BUNDLE_IDENTIFIER = ' + $newPackageName)
    }
}
# 产物名（PRODUCT_NAME）：macOS 的 CFBundleName = $(PRODUCT_NAME)，改这里即改名（变量保留）；
# 同时同步测试 target 的 TEST_HOST，否则测试找不到宿主 App。
if (Test-Path 'macos/Runner.xcodeproj/project.pbxproj') {
    $macPbxContent = [System.IO.File]::ReadAllText('macos/Runner.xcodeproj/project.pbxproj')
    $oldProduct = [regex]::Matches($macPbxContent, 'PRODUCT_NAME = ([^;\r\n]+);') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -notmatch '\$\(' } | Select-Object -First 1
    if ($oldProduct) {
        Edit-TextFile 'macos/Runner.xcodeproj/project.pbxproj' ('PRODUCT_NAME = ' + [regex]::Escape($oldProduct) + ';') ('PRODUCT_NAME = ' + $newAppName + ';')
        Edit-TextFile 'macos/Runner.xcodeproj/project.pbxproj' 'TEST_HOST = "\$\(BUILT_PRODUCTS_DIR\)/[^/]+\.app/\$\(BUNDLE_EXECUTABLE_FOLDER_PATH\)/[^"]+"' ('TEST_HOST = "$(BUILT_PRODUCTS_DIR)/' + $newAppName + '.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/' + $newAppName + '"')
    }
}

# ---- 4. Windows ----
Write-Host '[4/8] Updating Windows files' -ForegroundColor Cyan
if (Test-Path 'windows') {
    $cmake = 'windows/CMakeLists.txt'
    if (Test-Path $cmake) {
        Edit-TextFile $cmake 'project\(.*\)' ('project(' + $pubspecAppName + ' LANGUAGES CXX)')
        Edit-TextFile $cmake 'set\(BINARY_NAME ".*"\)' ('set(BINARY_NAME "' + $pubspecAppName + '")')
    }
    $rc = 'windows/runner/Runner.rc'
    if (Test-Path $rc) {
        Edit-TextFile $rc 'VALUE "FileDescription", "[^"]*"' ('VALUE "FileDescription", "' + $newAppName + '"')
        Edit-TextFile $rc 'VALUE "ProductName", "[^"]*"' ('VALUE "ProductName", "' + $newAppName + '"')
    }
}

# ---- 5. Linux ----
Write-Host '[5/8] Updating Linux files' -ForegroundColor Cyan
if (Test-Path 'linux') {
    $linuxCmake = 'linux/CMakeLists.txt'
    # Linux 模板的 project() 固定为 runner 且无人引用，不改；只改二进制名
    if (Test-Path $linuxCmake) {
        Edit-TextFile $linuxCmake 'set\(BINARY_NAME ".*"\)' ('set(BINARY_NAME "' + $pubspecAppName + '")')
        # 应用 ID（属身份，仅完整重命名时改）
        if (-not $keepPackageName) {
            Edit-TextFile $linuxCmake 'set\(APPLICATION_ID ".*"\)' ('set(APPLICATION_ID "' + $newPackageName + '")')
        }
    }
    # 窗口标题（显示名）。现代 Flutter 模板位于 linux/runner/，旧版位于 linux/。
    $linuxApp = @('linux/runner/my_application.cc', 'linux/my_application.cc') | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($linuxApp) {
        Edit-TextFile $linuxApp 'gtk_header_bar_set_title\(header_bar, "[^"]*"\)' ('gtk_header_bar_set_title(header_bar, "' + $newAppName + '")')
        Edit-TextFile $linuxApp 'gtk_window_set_title\(window, "[^"]*"\)' ('gtk_window_set_title(window, "' + $newAppName + '")')
        # 应用 ID（字面量形式，属身份，仅完整重命名时改）
        if (-not $keepPackageName) {
            Edit-TextFile $linuxApp 'g_application_set_application_id \(application, ".*"\);' ('g_application_set_application_id (application, "' + $newPackageName + '");')
        }
    }
}

# ---- 6. Web ----
Write-Host '[6/8] Updating web files' -ForegroundColor Cyan
if (Test-Path 'web') {
    if (Test-Path 'web/index.html') {
        Edit-TextFile 'web/index.html' '<title>.*</title>' ('<title>' + $newAppName + '</title>')
    }
    if (Test-Path 'web/manifest.json') {
        Edit-TextFile 'web/manifest.json' '"name": ".*"' ('"name": "' + $newAppName + '"')
        Edit-TextFile 'web/manifest.json' '"short_name": ".*"' ('"short_name": "' + $newAppName + '"')
    }
}

# ---- 7. pubspec.yaml ----
Write-Host '[7/8] Updating pubspec.yaml' -ForegroundColor Cyan
if (-not $keepPackageName) {
    Edit-TextFile $pubspecPath '(?m)^name:.*' ('name: ' + $pubspecAppName)
}
if ([System.IO.File]::ReadAllText($pubspecPath) -match '(?m)^description: "A new Flutter project\."') {
    Edit-TextFile $pubspecPath '(?m)^description:.*' ('description: "' + $newAppName + ' - A Flutter application."')
}

# ---- 8. 常量与 import ----
Write-Host '[8/8] Updating app constants and main files' -ForegroundColor Cyan
Get-ChildItem -Path lib -Recurse -Filter *.dart -File | Where-Object {
    $_.Name -match 'constants' -and $_.FullName -match 'app'
} | ForEach-Object {
    $constantsContent = [System.IO.File]::ReadAllText($_.FullName)
    if ($constantsContent -match 'appName') {
        Edit-TextFile $_.FullName "static const String appName = '[^']*'" ("static const String appName = '" + $newAppName + "'")
        Edit-TextFile $_.FullName 'static const String appName = "[^"]*"' ('static const String appName = "' + $newAppName + '"')
    }
}

if (-not $keepPackageName) {
    foreach ($dartDir in @('lib', 'test', 'tool')) {
        if (Test-Path $dartDir) {
            Get-ChildItem -Path $dartDir -Recurse -Filter *.dart -File | ForEach-Object {
                Edit-TextFile $_.FullName ("import 'package:" + $currentAppName) ("import 'package:" + $pubspecAppName)
                Edit-TextFile $_.FullName ('import "package:' + $currentAppName) ('import "package:' + $pubspecAppName)
            }
        }
    }
}

# ---- 完成 ----
Write-Host ''
Write-Host 'App successfully renamed!' -ForegroundColor Green
Write-Host "   - Display Name: $newAppName" -ForegroundColor Yellow
Write-Host "   - Package/Bundle ID: $newPackageName" -ForegroundColor Yellow
if ($keepPackageName) {
    Write-Host "   - Dart Package Name: $currentAppName (unchanged)" -ForegroundColor Yellow
} else {
    Write-Host "   - Dart Package Name: $pubspecAppName" -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '1. Run flutter clean' -ForegroundColor Cyan
Write-Host '2. Run flutter pub get' -ForegroundColor Cyan
Write-Host "3. Re-run flutter build for each platform you're targeting" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Note: You may need to manually update some references if you have complex platform-specific code.' -ForegroundColor Yellow
exit 0
