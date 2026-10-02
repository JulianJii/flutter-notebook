#!/bin/bash

# 应用图标生成器
# 本脚本使用 flutter_launcher_icons 为所有平台生成应用图标
# -----------------------------------------------------------------------------

# 设置文字颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    Flutter App Icon Generator        ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# 检查 flutter_launcher_icons.yaml 是否存在
if [ ! -f "flutter_launcher_icons.yaml" ]; then
    echo -e "${RED}Error: 未找到 flutter_launcher_icons.yaml！${NC}"
    echo -e "${YELLOW}请确认根目录下存在该配置文件。${NC}"
    exit 1
fi

# 检查源图标是否存在
# 从 yaml 中提取 image_path（简单 grep，复杂 yaml 可能失效，但标准配置足够）
ICON_PATH=$(grep "image_path:" flutter_launcher_icons.yaml | head -n 1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d "'")

if [ ! -f "$ICON_PATH" ]; then
    echo -e "${YELLOW}Warning: 未找到源图标（$ICON_PATH）。${NC}"
    echo -e "运行本脚本前，请确认 ${GREEN}$ICON_PATH${NC} 处存在图标。"
    echo -e "推荐尺寸：1024x1024 png"
    echo
    read -p "是否仍要继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}操作已取消。${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}已找到源图标：$ICON_PATH${NC}"
fi

echo -e "${BLUE}正在为所有平台生成图标...${NC}"
echo

# 运行生成器
dart run flutter_launcher_icons

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}✅ 图标生成成功！${NC}"
    echo -e "   - Android: mipmap 资源已更新"
    echo -e "   - iOS: Assets.xcassets 已更新"
    echo -e "   - Web: 图标与 manifest 已更新"
    echo -e "   - Windows/macOS: 图标文件已更新"
else
    echo
    echo -e "${RED}❌ 生成图标时出错。${NC}"
    exit 1
fi
