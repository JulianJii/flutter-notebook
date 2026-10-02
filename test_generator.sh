#!/bin/bash

# Flutter Riverpod 整洁架构 - 测试生成器
# 本脚本生成并运行带覆盖率的测试

# 颜色定义（美化输出）
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}      Test Generator & Runner         ${NC}"
echo -e "${BLUE}=======================================${NC}"

# 默认值
COVERAGE="yes"
REPORT="yes"
TARGET=""

# 显示用法说明的函数
usage() {
    echo -e "Usage: $0 [options]"
    echo -e "\nOptions:"
    echo -e "  --no-coverage         运行测试但不统计覆盖率"
    echo -e "  --no-report           不生成覆盖率报告"
    echo -e "  --target <path>       仅运行指定路径下的测试"
    echo -e "  --help                显示本帮助信息"
    echo -e "\nExamples:"
    echo -e "  $0                                # 运行全部测试（含覆盖率）"
    echo -e "  $0 --target test/features/auth/   # 仅运行 auth feature 测试"
    exit 1
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-coverage)
            COVERAGE="no"
            shift
            ;;
        --no-report)
            REPORT="no"
            shift
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Error: 未知选项: $1${NC}"
            usage
            ;;
    esac
done

# 检查 Flutter 是否已安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: 未找到 Flutter 命令。${NC}"
    exit 1
fi

# 运行测试
if [ "$COVERAGE" = "yes" ]; then
    echo -e "\n${YELLOW}正在运行带覆盖率的测试...${NC}"
    
    if [ -n "$TARGET" ]; then
        flutter test --coverage "$TARGET"
    else
        flutter test --coverage
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}测试失败！${NC}"
        exit 1
    fi
    
    # 按需要生成覆盖率报告
    if [ "$REPORT" = "yes" ]; then
        echo -e "\n${YELLOW}正在生成覆盖率报告...${NC}"
        
        if command -v lcov &> /dev/null; then
            # 使用 lcov 生成 HTML 报告
            genhtml coverage/lcov.info -o coverage/html
            
            if [ $? -eq 0 ]; then
                echo -e "\n${GREEN}覆盖率报告已生成！${NC}"
                echo -e "请在浏览器中打开 ${YELLOW}coverage/html/index.html${NC} 查看。"
                
                # 尝试在默认浏览器中打开报告
                if command -v open &> /dev/null; then
                    open coverage/html/index.html
                elif command -v xdg-open &> /dev/null; then
                    xdg-open coverage/html/index.html
                elif command -v start &> /dev/null; then
                    start coverage/html/index.html
                else
                    echo -e "请在浏览器中手动打开报告。"
                fi
            else
                echo -e "\n${RED}生成 HTML 覆盖率报告失败。${NC}"
                echo -e "请确认 lcov 已正确安装。"
            fi
        else
            echo -e "\n${YELLOW}lcov 未安装，无法生成 HTML 覆盖率报告。${NC}"
            echo -e "可通过以下方式安装："
            echo -e "  - macOS: brew install lcov"
            echo -e "  - Ubuntu/Debian: apt-get install lcov"
            echo -e "  - Windows: choco install lcov"
            echo -e "\n或者，可直接查看原始覆盖率数据：${YELLOW}coverage/lcov.info${NC}"
        fi
    fi
else
    echo -e "\n${YELLOW}正在运行不含覆盖率的测试...${NC}"
    
    if [ -n "$TARGET" ]; then
        flutter test "$TARGET"
    else
        flutter test
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}测试失败！${NC}"
        exit 1
    fi
fi

echo -e "\n${GREEN}✅ 测试已完成！${NC}"
exit 0
