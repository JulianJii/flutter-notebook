#!/bin/bash

# Flutter 本地化辅助脚本
# 本脚本用于管理 Flutter 应用的本地化语言文件

# 颜色定义（美化输出）
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}   Flutter Localization Helper Tool    ${NC}"
echo -e "${BLUE}=======================================${NC}"

BASE_ARB_DIR="lib/l10n/arb"
BASE_ARB_FILE="${BASE_ARB_DIR}/intl_en.arb"

# 检查 flutter 是否已安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: 未找到 Flutter 命令。${NC}"
    exit 1
fi

# 生成本地化文件的函数
generate_localization() {
    echo -e "${YELLOW}正在生成本地化文件...${NC}"
    flutter gen-l10n
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}本地化文件生成成功！${NC}"
    else
        echo -e "${RED}生成本地化文件失败！${NC}"
        exit 1
    fi
}

# 列出所有支持语言的函数
list_languages() {
    echo -e "${YELLOW}当前支持的语言:${NC}"
    
    # 查找所有 ARB 文件并提取语言码
    for file in ${BASE_ARB_DIR}/intl_*.arb; do
        lang_code=$(basename "$file" | sed 's/intl_\(.*\)\.arb/\1/')
        
        # 尽可能从 ARB 文件中获取语言名称
        if [ -f "$file" ]; then
            lang_name=$(grep -o '"@@locale": "[^"]*"' "$file" | cut -d'"' -f4)
            if [ -z "$lang_name" ]; then
                lang_name=$lang_code
            fi
            echo -e " - ${GREEN}$lang_code${NC} ($lang_name)"
        fi
    done
}

# 创建新语言文件的函数
create_language() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: 未提供语言码。${NC}"
        echo -e "Usage: $0 add-language <language_code>"
        exit 1
    fi
    
    lang_code=$1
    new_arb_file="${BASE_ARB_DIR}/intl_${lang_code}.arb"
    
    if [ -f "$new_arb_file" ]; then
        echo -e "${RED}Error: 语言 '${lang_code}' 的文件已存在。${NC}"
        exit 1
    fi
    
    if [ ! -f "$BASE_ARB_FILE" ]; then
        echo -e "${RED}Error: 未找到基础语言文件（${BASE_ARB_FILE}）。${NC}"
        exit 1
    fi
    
    # 复制基础语言文件并更新 locale
    cp "$BASE_ARB_FILE" "$new_arb_file"
    
    # 更新新文件中的 locale
    sed -i '' "s/\"@@locale\": \"en\"/\"@@locale\": \"${lang_code}\"/" "$new_arb_file"
    
    echo -e "${GREEN}已创建新语言文件: ${new_arb_file}${NC}"
    echo -e "${YELLOW}请在新文件中翻译各字符串。${NC}"
}

# 检查缺失翻译的函数
check_missing() {
    echo -e "${YELLOW}正在检查缺失的翻译...${NC}"
    
    if [ ! -f "$BASE_ARB_FILE" ]; then
        echo -e "${RED}Error: 未找到基础语言文件（${BASE_ARB_FILE}）。${NC}"
        exit 1
    fi
    
    # 从基础文件获取所有 key
    base_keys=$(grep -o '"[^"]*": "[^"]*"' "$BASE_ARB_FILE" | grep -v "@@" | cut -d'"' -f2)
    
    # 逐个检查各语言文件
    for file in ${BASE_ARB_DIR}/intl_*.arb; do
        if [ "$file" != "$BASE_ARB_FILE" ]; then
            lang_code=$(basename "$file" | sed 's/intl_\(.*\)\.arb/\1/')
            echo -e "\nChecking ${BLUE}${lang_code}${NC}:"
            
            missing=0
            for key in $base_keys; do
                if ! grep -q "\"$key\":" "$file"; then
                    echo -e " - Missing: ${RED}$key${NC}"
                    missing=$((missing + 1))
                fi
            done
            
            if [ $missing -eq 0 ]; then
                echo -e " ${GREEN}✓ 翻译完整${NC}"
            else
                echo -e " ${RED}缺失 $missing 条翻译${NC}"
            fi
        fi
    done
}

# 获取用法说明的函数
usage() {
    echo -e "Usage: $0 <command>"
    echo -e "\nCommands:"
    echo -e "  ${GREEN}generate${NC}     - 生成本地化文件"
    echo -e "  ${GREEN}list${NC}         - 列出支持的语言"
    echo -e "  ${GREEN}add${NC} <code>   - 新增语言（例如 'add fr' 表示法语）"
    echo -e "  ${GREEN}check${NC}        - 检查缺失的翻译"
    echo -e "  ${GREEN}help${NC}         - 显示本帮助信息"
}

# 主命令解析
case "$1" in
    generate)
        generate_localization
        ;;
    list)
        list_languages
        ;;
    add)
        create_language "$2"
        ;;
    check)
        check_missing
        ;;
    help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac

exit 0
