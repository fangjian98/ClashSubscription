#!/bin/bash

# Clash订阅内容自动获取并同步到Gist脚本
# 功能：从GitHub页面获取Clash订阅链接，下载订阅内容，定时同步到Gist供Windows端使用

# ========== 配置变量 ==========
SOURCE_URL="https://raw.githubusercontent.com/tolinkshare2/tolinkshare2.github.io/main/README.md"
OUTPUT_FILE="clash_subscription.txt"
LOG_FILE="clash_getter.log"
INTERVAL=300  # 5分钟（单位：秒）

# Gist配置（从环境变量读取）
GIST_ID="${GIST_ID}"
GIST_FILENAME="${GIST_FILENAME:-clash.yaml}"
GIST_TOKEN="${GIST_TOKEN}"

# ========== 获取Clash订阅链接 ==========
get_clash_link() {
    local content=$(curl -s --connect-timeout 10 "$SOURCE_URL")

    if [ $? -ne 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：无法连接到源页面" >> "$LOG_FILE"
        return 1
    fi

    # 提取Clash订阅链接
    local clash_link=$(echo "$content" | sed -n '/免费Clash订阅链接/,/免费v2rayN订阅链接/p' | grep '^https' | head -1)

    if [ -z "$clash_link" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：未找到Clash订阅链接" >> "$LOG_FILE"
        return 1
    fi

    echo "$clash_link"
    return 0
}

# ========== 获取订阅内容 ==========
get_subscription_content() {
    local link="$1"
    local content=$(curl -s --connect-timeout 30 "$link")

    if [ $? -ne 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：无法获取订阅内容" >> "$LOG_FILE"
        return 1
    fi

    if [ -z "$content" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：订阅内容为空" >> "$LOG_FILE"
        return 1
    fi

    echo "$content"
    return 0
}

# ========== 上传订阅内容到Gist ==========
upload_to_gist() {
    local content="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # 清理内容中的特殊字符（防止JSON转义问题）
    # 将双引号转义，移除控制字符
    local escaped_content=$(echo "$content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g' | tr -d '\r')

    # 构建JSON payload
    local json_data="{\"description\": \"Clash订阅内容 - 更新时间: $timestamp\", \"public\": false, \"files\": {\"$GIST_FILENAME\": {\"content\": \"$escaped_content\"}}}"

    # 发送PUT请求更新Gist
    local response=$(curl -s -X PUT \
        -H "Authorization: token $GIST_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$json_data" \
        "https://api.github.com/gists/$GIST_ID")

    # 检查是否成功
    if echo "$response" | grep -q '"error"'; then
        echo "[$timestamp] Gist上传失败" >> "$LOG_FILE"
        return 1
    else
        echo "[$timestamp] Gist上传成功" >> "$LOG_FILE"
        return 0
    fi
}

# ========== 执行一次同步 ==========
do_sync() {
    echo ""
    echo "=========================================="
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始同步Clash订阅..."
    echo "=========================================="

    # 第一步：获取订阅链接
    clash_link=$(get_clash_link)
    if [ $? -ne 0 ]; then
        echo "获取订阅链接失败"
        return 1
    fi
    echo "获取订阅链接成功: $clash_link"

    # 第二步：获取订阅内容
    subscription_content=$(get_subscription_content "$clash_link")
    if [ $? -ne 0 ]; then
        echo "获取订阅内容失败"
        return 1
    fi
    echo "获取订阅内容成功，内容长度: ${#subscription_content} 字符"
    echo "获取订阅内容成功，内容: ${subscription_content}"

    # 保存订阅链接到本地文件
    temp_file=$(mktemp)
    echo -e "$(date '+%Y-%m-%d %H:%M:%S')\n$clash_link\n" > "$temp_file"
    if [ -f "$OUTPUT_FILE" ]; then
        cat "$OUTPUT_FILE" >> "$temp_file"
    fi
    mv "$temp_file" "$OUTPUT_FILE"
    echo "订阅链接已保存到本地: $OUTPUT_FILE"

    # 第三步：上传订阅内容到Gist
    if [ -n "$GIST_TOKEN" ] && [ -n "$GIST_ID" ]; then
        echo "正在上传订阅内容到Gist..."
        if upload_to_gist "$subscription_content"; then
            echo "上传成功！Windows端可直接从Gist获取订阅配置"
        else
            echo "上传失败，请检查Gist配置"
            return 1
        fi
    else
        echo "未配置Gist信息，跳过上传"
        echo "订阅内容预览（前500字符）:"
        echo "${subscription_content:0:500}"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 本次同步完成"
    return 0
}

# ========== 主循环 ==========
echo "=========================================="
echo "Clash订阅内容自动同步脚本"
echo "源页面: $SOURCE_URL"
echo "同步间隔: $((INTERVAL / 60)) 分钟"
echo "=========================================="
echo "按 Ctrl+C 停止脚本"
echo ""

# 检查Gist配置
if [ -z "$GIST_TOKEN" ] || [ -z "$GIST_ID" ]; then
    echo "警告：未配置Gist信息，脚本将仅保存到本地文件"
    echo "请设置以下环境变量："
    echo "  GIST_ID: 你的Gist ID"
    echo "  GIST_TOKEN: 你的GitHub Personal Token"
    echo ""
fi

while true; do
    # 执行一次同步
    do_sync

    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 等待 $((INTERVAL / 60)) 分钟后进行下一次同步..."
    echo ""

    # 等待指定时间
    sleep $INTERVAL
done
