#!/bin/bash

# Clash订阅链接获取脚本
# 功能：每5分钟从GitHub页面获取最新的免费Clash订阅链接

# 配置变量
URL="https://raw.githubusercontent.com/tolinkshare2/tolinkshare2.github.io/main/README.md"
OUTPUT_FILE="clash_subscription.txt"
INTERVAL=300  # 5分钟（单位：秒）

# 颜色输出配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取Clash订阅链接的函数
get_clash_link() {
    # 从网页内容中提取Clash订阅链接
    # 格式：在"🚀免费Clash订阅链接"后面，跟着一个代码块(```...```)
    local content=$(curl -s --connect-timeout 10 "$URL")

    if [ $? -ne 0 ]; then
        echo -e "${RED}错误：无法连接到GitHub页面${NC}"
        return 1
    fi

    # 提取方法：
    # 1. 找到"🚀免费Clash订阅链接"标记
    # 2. 提取到下一个"免费v2rayN订阅链接"标记之间的内容
    # 3. 找到第一个HTTP链接
    local clash_link=$(echo "$content" | sed -n '/免费Clash订阅链接/,/免费v2rayN订阅链接/p' | grep '^https' | head -1)

    if [ -z "$clash_link" ]; then
        echo -e "${RED}错误：未找到Clash订阅链接${NC}"
        return 1
    fi

    echo "$clash_link"
    return 0
}

# 主循环
main() {
    echo -e "${GREEN}=== Clash订阅链接自动获取脚本 ===${NC}"
    echo -e "${YELLOW}目标URL: $URL${NC}"
    echo -e "${YELLOW}获取间隔: $((INTERVAL / 60))分钟${NC}"
    echo -e "${YELLOW}输出文件: $OUTPUT_FILE${NC}"
    echo "----------------------------------------"

    while true; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 正在获取最新Clash订阅链接..."

        # 获取链接
        clash_link=$(get_clash_link)

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}成功获取订阅链接:${NC}"
            echo "$clash_link"

            # 保存到文件
            echo "$clash_link" > "$OUTPUT_FILE"
            echo -e "${GREEN}已保存到文件: $OUTPUT_FILE${NC}"
        else
            echo -e "${RED}获取失败，将在$((INTERVAL / 60))分钟后重试${NC}"
        fi

        echo "----------------------------------------"
        echo "等待$((INTERVAL / 60))分钟后进行下一次获取..."
        echo ""

        # 等待指定时间
        sleep $INTERVAL
    done
}

# 处理Ctrl+C中断
trap 'echo -e "\n${YELLOW}检测到中断信号，脚本已终止${NC}"; exit 1' INT

# 启动脚本
main
