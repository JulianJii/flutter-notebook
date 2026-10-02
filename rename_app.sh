#!/bin/bash

# Flutter 应用重命名工具
# 本脚本用于重命名 Flutter 应用，并跨所有平台更新包名
# -----------------------------------------------------------------------------

# 设置文字颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}      Flutter 应用重命名脚本      ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# 跨平台就地编辑 sed。BSD/macOS 的 sed 在 -i 后需要（可为空的）备份扩展名参数
#（`sed -i '' ...`）；而 Linux 上的 GNU sed 会把该空字符串当作要编辑的文件，
#导致 "No such file or directory" 错误。所有就地编辑都应通过本函数，而非直接调用 `sed -i`。
sed_i() {
    local script="$1"
    shift
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$script" "$@"
    else
        sed -i "$script" "$@"
    fi
}
export -f sed_i

# 显示用法说明的函数
show_usage() {
    echo -e "Usage: $0 [options]"
    echo -e "\nOptions:"
    echo -e "  --app-name \"New App Name\"   设置新的应用显示名称（必填）"
    echo -e "  --package-name com.wode.newapp   设置新的包名（可选，省略则沿用当前包名）"
    echo -e "  --help                      显示本帮助信息"
    echo
    echo -e "Examples:"
    echo -e "  $0 --app-name \"My Amazing App\" --package-name com.mycompany.amazingapp"
    echo
    exit 1
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --app-name)
            NEW_APP_NAME="$2"
            shift 2
            ;;
        --package-name)
            NEW_PACKAGE_NAME="$2"
            shift 2
            ;;
        --help)
            show_usage
            ;;
        *)
            echo -e "${RED}Error: 未知选项: $1${NC}"
            show_usage
            ;;
    esac
done

# 校验必填参数（--package-name 可选：省略则沿用当前包名）
if [ -z "$NEW_APP_NAME" ]; then
    echo -e "${RED}Error: --app-name 为必填项${NC}"
    show_usage
fi

# 校验包名格式（com.wode.app）——仅在显式提供时校验
if [ -n "$NEW_PACKAGE_NAME" ] && ! [[ $NEW_PACKAGE_NAME =~ ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+[0-9a-z_]$ ]]; then
    echo -e "${RED}Error: 包名必须是合法格式（例如 com.wode.app）${NC}"
    exit 1
fi

# 获取当前应用信息
CURRENT_DIR=$(pwd)
PUBSPEC_PATH="$CURRENT_DIR/pubspec.yaml"

if [ ! -f "$PUBSPEC_PATH" ]; then
    echo -e "${RED}Error: 未找到 pubspec.yaml。请从 Flutter 项目根目录运行本脚本。${NC}"
    exit 1
fi

# 获取当前应用名称与包名
CURRENT_APP_NAME=$(grep "name:" "$PUBSPEC_PATH" | head -n 1 | awk -F': ' '{print $2}' | tr -d ' ')
# 显示名称 -> 合法的 Dart 包名（小写；空格/连字符 -> _）。
# 在此处计算：下方 Windows/Linux 的 CMake 步骤已引用它，因此
# 不能推迟到步骤 7 再计算。
PUBSPEC_APP_NAME=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')

# 当前 Android 包名：优先 AndroidManifest 的 package=；现代 Flutter 模板已移除该属性，
# 回退到 build.gradle(.kts) 的 namespace / applicationId。必须在改写 gradle 之前取值。
CURRENT_PACKAGE_NAME=""
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    CURRENT_PACKAGE_NAME=$(grep -o 'package="[^"]*"' "android/app/src/main/AndroidManifest.xml" | head -n 1 | sed 's/package="\(.*\)"/\1/')
fi
if [ -z "$CURRENT_PACKAGE_NAME" ] && [ -f "android/app/build.gradle.kts" ]; then
    CURRENT_PACKAGE_NAME=$(grep -o 'namespace = "[^"]*"' "android/app/build.gradle.kts" | head -n 1 | sed 's/namespace = "\(.*\)"/\1/')
    if [ -z "$CURRENT_PACKAGE_NAME" ]; then
        CURRENT_PACKAGE_NAME=$(grep -o 'applicationId = "[^"]*"' "android/app/build.gradle.kts" | head -n 1 | sed 's/applicationId = "\(.*\)"/\1/')
    fi
fi
if [ -z "$CURRENT_PACKAGE_NAME" ] && [ -f "android/app/build.gradle" ]; then
    CURRENT_PACKAGE_NAME=$(grep -o 'namespace "[^"]*"' "android/app/build.gradle" | head -n 1 | sed 's/namespace "\(.*\)"/\1/')
    if [ -z "$CURRENT_PACKAGE_NAME" ]; then
        CURRENT_PACKAGE_NAME=$(grep -o 'applicationId "[^"]*"' "android/app/build.gradle" | head -n 1 | sed 's/applicationId "\(.*\)"/\1/')
    fi
fi

# --package-name 省略 = 只改“名字”（显示名 + .app/二进制/工程名）；包名/Bundle ID 保持不动，且不改 Dart 包名(pubspec name)与源码 import。
# ponytail: 假定各平台包名/Bundle ID 与 Android 当前值一致；若某平台单独改过，请显式传 --package-name。
KEEP_PACKAGE_NAME=0
if [ -z "$NEW_PACKAGE_NAME" ]; then
    if [ -z "$CURRENT_PACKAGE_NAME" ]; then
        echo -e "${RED}Error: 未提供 --package-name，且无法从 android/ 推断当前包名，请显式指定。${NC}"
        exit 1
    fi
    NEW_PACKAGE_NAME="$CURRENT_PACKAGE_NAME"
    KEEP_PACKAGE_NAME=1
fi

echo -e "${YELLOW}当前应用标识符:${NC} $CURRENT_APP_NAME"
echo -e "${YELLOW}新的应用显示名称:${NC} $NEW_APP_NAME"
if [ "$KEEP_PACKAGE_NAME" -eq 1 ]; then
    echo -e "${YELLOW}新的包名:${NC} $NEW_PACKAGE_NAME ${BLUE}(保持当前包名)${NC}"
else
    echo -e "${YELLOW}新的包名:${NC} $NEW_PACKAGE_NAME"
fi

# 与用户确认
echo
read -p "是否确认执行重命名？该操作难以撤销。(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}操作已取消。${NC}"
    exit 0
fi

echo -e "${BLUE}开始重命名流程...${NC}"

# 递归统计目录下文件数量的函数
count_files() {
    find "$1" -type f | wc -l | tr -d ' '
}

# 计算总步骤数
TOTAL_STEPS=8
CURRENT_STEP=0

# 更新进度的函数
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP+1))
    echo -e "${BLUE}[$CURRENT_STEP/$TOTAL_STEPS] $1${NC}"
}

# 1. 更新 Android 文件
update_progress "更新 Android 文件"

# Android 应用名称（strings.xml）——兼容单行与多行两种写法
if [ -f "android/app/src/main/res/values/strings.xml" ]; then
    sed_i "s|<string name=\"app_name\">[^<]*</string>|<string name=\"app_name\">$NEW_APP_NAME</string>|" "android/app/src/main/res/values/strings.xml"
    sed_i "/<string name=\"app_name\">[[:space:]]*$/,/<\/string>/c\\
    <string name=\"app_name\">$NEW_APP_NAME<\/string>" "android/app/src/main/res/values/strings.xml"
elif [ -d "android/app/src/main/res/values" ]; then
    mkdir -p "android/app/src/main/res/values"
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<resources>
    <string name=\"app_name\">$NEW_APP_NAME</string>
</resources>" > "android/app/src/main/res/values/strings.xml"
fi

# 旧包名已在确认前取好（见上方 CURRENT_PACKAGE_NAME），这里直接复用。
OLD_PACKAGE_NAME="$CURRENT_PACKAGE_NAME"

# Android 包名（build.gradle 或 build.gradle.kts）——保持当前包名时跳过
if [ "$KEEP_PACKAGE_NAME" -eq 0 ] && [ -f "android/app/build.gradle" ]; then
    sed_i "s/applicationId \".*\"/applicationId \"$NEW_PACKAGE_NAME\"/g" "android/app/build.gradle"
    sed_i "s/namespace \".*\"/namespace \"$NEW_PACKAGE_NAME\"/g" "android/app/build.gradle"
elif [ "$KEEP_PACKAGE_NAME" -eq 0 ] && [ -f "android/app/build.gradle.kts" ]; then
    # 处理 Kotlin DSL 格式（使用 = 而非空格）
    sed_i "s/applicationId = \".*\"/applicationId = \"$NEW_PACKAGE_NAME\"/g" "android/app/build.gradle.kts"
    sed_i "s/namespace = \".*\"/namespace = \"$NEW_PACKAGE_NAME\"/g" "android/app/build.gradle.kts"
fi

# Android 清单文件（仅在仍含 package= 属性时）
if [ -n "$OLD_PACKAGE_NAME" ] && [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    sed_i "s/package=\"$OLD_PACKAGE_NAME\"/package=\"$NEW_PACKAGE_NAME\"/g" "android/app/src/main/AndroidManifest.xml"
fi

# Android 源码包目录：kotlin 与 java 都处理；包名声明与目录搬迁不再依赖 manifest 的 package=
# 新旧包名相同时跳过搬迁：否则 mv 自移动失败，随后的 rm -rf 会误删源码。
if [ -n "$OLD_PACKAGE_NAME" ] && [ "$NEW_PACKAGE_NAME" != "$OLD_PACKAGE_NAME" ]; then
    OLD_PACKAGE_PATH=$(echo "$OLD_PACKAGE_NAME" | tr '.' '/')
    NEW_PACKAGE_PATH=$(echo "$NEW_PACKAGE_NAME" | tr '.' '/')

    for SRC_ROOT in java kotlin; do
        OLD_SRC_DIR="android/app/src/main/$SRC_ROOT/$OLD_PACKAGE_PATH"
        NEW_SRC_DIR="android/app/src/main/$SRC_ROOT/$NEW_PACKAGE_PATH"

        # 仅在旧目录存在时才尝试
        if [ -d "$OLD_SRC_DIR" ]; then
            mkdir -p "$NEW_SRC_DIR"
            mv "$OLD_SRC_DIR"/* "$NEW_SRC_DIR/"

            # 更新 Kotlin/Java 文件中的包名。`find -exec` 直接执行二进制，
            #无法识别已导出的 sed_i shell 函数；因此通过 `bash -c` 间接调用。
            find "$NEW_SRC_DIR" -type f \( -name "*.kt" -o -name "*.java" \) -exec bash -c 'sed_i "$1" "$2"' _ "s/^package $OLD_PACKAGE_NAME/package $NEW_PACKAGE_NAME/g" {} \;

            # 清理旧目录
            rm -rf "$OLD_SRC_DIR"
        fi
    done
fi

# 2. 更新 iOS 文件
update_progress "更新 iOS 文件"

# iOS 应用名称（Info.plist）
if [ -f "ios/Runner/Info.plist" ]; then
    FOUND_BUNDLE_NAME=$(grep -A 1 "CFBundleName" "ios/Runner/Info.plist")
    # 值为 $(...) 构建变量时不覆盖（如 $(PRODUCT_NAME)）
    if [ -n "$FOUND_BUNDLE_NAME" ] && ! grep -A 1 "<key>CFBundleName</key>" "ios/Runner/Info.plist" | grep -q '<string>\$('; then
        sed_i "s/<key>CFBundleName<\/key>.*/<key>CFBundleName<\/key>\\
	<string>$NEW_APP_NAME<\/string>/g" "ios/Runner/Info.plist"
    else
        # 若不存在 CFBundleName，则紧跟 CFBundleDisplayName 之后添加
        sed_i "/<key>CFBundleDisplayName<\/key>/a\\
	<key>CFBundleName<\/key>\\
	<string>$NEW_APP_NAME<\/string>" "ios/Runner/Info.plist"
    fi
    
    # 同时更新 CFBundleDisplayName
    FOUND_DISPLAY_NAME=$(grep -A 1 "CFBundleDisplayName" "ios/Runner/Info.plist")
    if [ -n "$FOUND_DISPLAY_NAME" ] && ! grep -A 1 "<key>CFBundleDisplayName</key>" "ios/Runner/Info.plist" | grep -q '<string>\$('; then
        sed_i "s/<key>CFBundleDisplayName<\/key>.*/<key>CFBundleDisplayName<\/key>\\
	<string>$NEW_APP_NAME<\/string>/g" "ios/Runner/Info.plist"
    fi
    
    # bundle identifier 由 project.pbxproj 的 PRODUCT_BUNDLE_IDENTIFIER 控制；
    # Info.plist 保持 $(PRODUCT_BUNDLE_IDENTIFIER) 引用不动。
fi

# 更新 iOS 工程文件（保持当前包名时跳过；只替换主 Target 的 Bundle ID，保留 .RunnerTests 等后缀）
if [ "$KEEP_PACKAGE_NAME" -eq 0 ] && [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    IOS_OLD_BUNDLE=$(sed -n 's/.*PRODUCT_BUNDLE_IDENTIFIER = \([^;]*\);.*/\1/p' "ios/Runner.xcodeproj/project.pbxproj" | grep -v 'Tests' | head -n 1)
    if [ -n "$IOS_OLD_BUNDLE" ]; then
        sed_i "s/PRODUCT_BUNDLE_IDENTIFIER = $IOS_OLD_BUNDLE/PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE_NAME/g" "ios/Runner.xcodeproj/project.pbxproj"
    fi
fi

# 3. 更新 macOS 文件
update_progress "更新 macOS 文件"

if [ -d "macos" ]; then
    # macOS 应用名称（Info.plist）
    if [ -f "macos/Runner/Info.plist" ]; then
        FOUND_BUNDLE_NAME=$(grep -A 1 "CFBundleName" "macos/Runner/Info.plist")
        # 值为 $(...) 构建变量时不覆盖（如 $(PRODUCT_NAME)）
        if [ -n "$FOUND_BUNDLE_NAME" ] && ! grep -A 1 "<key>CFBundleName</key>" "macos/Runner/Info.plist" | grep -q '<string>\$('; then
            sed_i "s/<key>CFBundleName<\/key>.*/<key>CFBundleName<\/key>\\
	<string>$NEW_APP_NAME<\/string>/g" "macos/Runner/Info.plist"
        fi
        
        # 同时更新 CFBundleDisplayName
        FOUND_DISPLAY_NAME=$(grep -A 1 "CFBundleDisplayName" "macos/Runner/Info.plist")
        if [ -n "$FOUND_DISPLAY_NAME" ] && ! grep -A 1 "<key>CFBundleDisplayName</key>" "macos/Runner/Info.plist" | grep -q '<string>\$('; then
            sed_i "s/<key>CFBundleDisplayName<\/key>.*/<key>CFBundleDisplayName<\/key>\\
	<string>$NEW_APP_NAME<\/string>/g" "macos/Runner/Info.plist"
        fi
        
        # bundle identifier 由 project.pbxproj 的 PRODUCT_BUNDLE_IDENTIFIER 控制；
        # Info.plist 保持 $(PRODUCT_BUNDLE_IDENTIFIER) 引用不动。
    fi
    
    # 更新 macOS 工程文件（保持当前包名时跳过；只替换主 Target 的 Bundle ID，保留 .RunnerTests 等后缀）
    if [ "$KEEP_PACKAGE_NAME" -eq 0 ] && [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
        MAC_OLD_BUNDLE=$(sed -n 's/.*PRODUCT_BUNDLE_IDENTIFIER = \([^;]*\);.*/\1/p' "macos/Runner.xcodeproj/project.pbxproj" | grep -v 'Tests' | head -n 1)
        if [ -n "$MAC_OLD_BUNDLE" ]; then
            sed_i "s/PRODUCT_BUNDLE_IDENTIFIER = $MAC_OLD_BUNDLE/PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE_NAME/g" "macos/Runner.xcodeproj/project.pbxproj"
        fi
    fi

    # 产物名（PRODUCT_NAME）：macOS 的 CFBundleName = $(PRODUCT_NAME)，改这里即改名（变量保留）；
    # 同时同步测试 target 的 TEST_HOST，否则测试找不到宿主 App。
    if [ -f "macos/Runner.xcodeproj/project.pbxproj" ]; then
        MAC_OLD_PRODUCT=$(sed -n 's/.*PRODUCT_NAME = \([^;]*\);.*/\1/p' "macos/Runner.xcodeproj/project.pbxproj" | grep -v '\$(' | head -n 1)
        if [ -n "$MAC_OLD_PRODUCT" ]; then
            sed_i "s/PRODUCT_NAME = $MAC_OLD_PRODUCT;/PRODUCT_NAME = $NEW_APP_NAME;/g" "macos/Runner.xcodeproj/project.pbxproj"
            sed_i "s|TEST_HOST = \"\$(BUILT_PRODUCTS_DIR)/[^/]*\.app/\$(BUNDLE_EXECUTABLE_FOLDER_PATH)/[^\"]*\"|TEST_HOST = \"\$(BUILT_PRODUCTS_DIR)/$NEW_APP_NAME.app/\$(BUNDLE_EXECUTABLE_FOLDER_PATH)/$NEW_APP_NAME\"|g" "macos/Runner.xcodeproj/project.pbxproj"
        fi
    fi
fi

# 4. 更新 Windows 文件
update_progress "更新 Windows 文件"

if [ -d "windows" ]; then
    # 更新 CMakeLists.txt 中的应用名称与二进制名（属“名字”，随 --app-name 一起改）
    if [ -f "windows/CMakeLists.txt" ]; then
        # 工程名（应使用 snake_case）
        sed_i "s/project(.*)/project($PUBSPEC_APP_NAME LANGUAGES CXX)/g" "windows/CMakeLists.txt"
        
        # 二进制名称
        sed_i "s/set(BINARY_NAME \".*\")/set(BINARY_NAME \"$PUBSPEC_APP_NAME\")/g" "windows/CMakeLists.txt"
    fi
    
    # 更新 runner.rc 中的应用名称
    if [ -f "windows/runner/Runner.rc" ]; then
        sed_i "s/VALUE \"FileDescription\", \"[^\"]*\"/VALUE \"FileDescription\", \"$NEW_APP_NAME\"/g" "windows/runner/Runner.rc"
        sed_i "s/VALUE \"ProductName\", \"[^\"]*\"/VALUE \"ProductName\", \"$NEW_APP_NAME\"/g" "windows/runner/Runner.rc"
    fi
fi

# 5. 更新 Linux 文件
update_progress "更新 Linux 文件"

if [ -d "linux" ]; then
    # 更新 CMakeLists.txt 中的二进制名（属“名字”）。Linux 模板的 project() 固定为 runner 且无人引用，不改。
    if [ -f "linux/CMakeLists.txt" ]; then
        
        # 二进制名称
        sed_i "s/set(BINARY_NAME \".*\")/set(BINARY_NAME \"$PUBSPEC_APP_NAME\")/g" "linux/CMakeLists.txt"
        
        # 应用 ID（属身份，仅完整重命名时改）
        if [ "$KEEP_PACKAGE_NAME" -eq 0 ]; then
            sed_i "s/set(APPLICATION_ID \".*\")/set(APPLICATION_ID \"$NEW_PACKAGE_NAME\")/g" "linux/CMakeLists.txt"
        fi
    fi
    
    # 窗口标题（显示名）。现代 Flutter 模板位于 linux/runner/，旧版位于 linux/。
    LINUX_APP_CC=""
    for LINUX_CC in "linux/runner/my_application.cc" "linux/my_application.cc"; do
        if [ -f "$LINUX_CC" ]; then
            LINUX_APP_CC="$LINUX_CC"
            break
        fi
    done
    if [ -n "$LINUX_APP_CC" ]; then
        sed_i "s/gtk_header_bar_set_title(header_bar, \"[^\"]*\")/gtk_header_bar_set_title(header_bar, \"$NEW_APP_NAME\")/g" "$LINUX_APP_CC"
        sed_i "s/gtk_window_set_title(window, \"[^\"]*\")/gtk_window_set_title(window, \"$NEW_APP_NAME\")/g" "$LINUX_APP_CC"
        # 应用 ID（字面量形式，属身份，仅完整重命名时改）
        if [ "$KEEP_PACKAGE_NAME" -eq 0 ]; then
            sed_i "s/g_application_set_application_id (application, \".*\");/g_application_set_application_id (application, \"$NEW_PACKAGE_NAME\");/g" "$LINUX_APP_CC"
        fi
    fi
fi

# 6. 更新 web 文件
update_progress "更新 web 文件"

if [ -d "web" ]; then
    # 更新 index.html 中的标题
    if [ -f "web/index.html" ]; then
        sed_i "s/<title>.*<\/title>/<title>$NEW_APP_NAME<\/title>/g" "web/index.html"
    fi
    
    # 更新 manifest.json
    if [ -f "web/manifest.json" ]; then
        sed_i "s/\"name\": \".*\"/\"name\": \"$NEW_APP_NAME\"/g" "web/manifest.json"
        sed_i "s/\"short_name\": \".*\"/\"short_name\": \"$NEW_APP_NAME\"/g" "web/manifest.json"
    fi
fi

# 7. 更新 pubspec.yaml
update_progress "更新 pubspec.yaml"

# 更新 pubspec.yaml 中的 name —— 必须为合法的 Dart 包名（仅改显示名时保留原 Dart 包名）
if [ "$KEEP_PACKAGE_NAME" -eq 0 ]; then
    sed_i "s/^name: .*/name: $PUBSPEC_APP_NAME/g" "$PUBSPEC_PATH"
fi

# 更新 pubspec.yaml 中的 description —— 仅在仍为模板默认值时替换，避免覆盖项目自定义描述
if grep -q '^description: "A new Flutter project\."' "$PUBSPEC_PATH"; then
    sed_i "s/^description: .*/description: \"$NEW_APP_NAME - A Flutter application.\"/g" "$PUBSPEC_PATH"
fi

# 8. 更新常量与入口文件
update_progress "更新应用常量与入口文件"

# 检查是否存在 app_constants.dart 文件
APP_CONSTANTS_FILES=$(find . -path "*/lib/*" -name "*constants*.dart" | grep -i "app")
if [ -n "$APP_CONSTANTS_FILES" ]; then
    for constants_file in $APP_CONSTANTS_FILES; do
        if grep -q "appName" "$constants_file"; then
            sed_i "s/static const String appName = '.*'/static const String appName = '$NEW_APP_NAME'/g" "$constants_file"
            sed_i "s/static const String appName = \".*\"/static const String appName = \"$NEW_APP_NAME\"/g" "$constants_file"
        fi
    done
fi

# 更新 dart 文件中的 import（覆盖 lib/test/tool，单双引号均处理）——仅完整重命名（Dart 包名变化）时执行
if [ "$KEEP_PACKAGE_NAME" -eq 0 ]; then
    for DART_DIR in lib test tool; do
        if [ -d "$DART_DIR" ]; then
            find "$DART_DIR" -type f -name "*.dart" -exec bash -c 'sed_i "$1" "$2"' _ "s/import 'package:$CURRENT_APP_NAME/import 'package:$PUBSPEC_APP_NAME/g" {} \;
            find "$DART_DIR" -type f -name "*.dart" -exec bash -c 'sed_i "$1" "$2"' _ "s/import \"package:$CURRENT_APP_NAME/import \"package:$PUBSPEC_APP_NAME/g" {} \;
        fi
    done
fi

# 成功提示
echo 
echo -e "${GREEN}✅ 应用重命名成功！${NC}"
echo -e "   - 显示名称: ${YELLOW}$NEW_APP_NAME${NC}"
echo -e "   - 包名 / Bundle ID: ${YELLOW}$NEW_PACKAGE_NAME${NC}"
if [ "$KEEP_PACKAGE_NAME" -eq 1 ]; then
    echo -e "   - Dart 包名: ${YELLOW}$CURRENT_APP_NAME${NC} ${BLUE}(未改动)${NC}"
else
    echo -e "   - Dart 包名: ${YELLOW}$PUBSPEC_APP_NAME${NC}"
fi
echo

echo -e "${BLUE}后续步骤:${NC}"
echo -e "1. 运行 ${YELLOW}flutter clean${NC}"
echo -e "2. 运行 ${YELLOW}flutter pub get${NC}"
echo -e "3. 针对各目标平台重新执行 ${YELLOW}flutter build${NC}"
echo

echo -e "${YELLOW}注意:${NC} 若你含有复杂的平台特定代码，可能需要手动更新部分引用。"
echo

exit 0
