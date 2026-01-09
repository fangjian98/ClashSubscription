# 本地运行脚本获取 Clash 订阅链接

## 1. 定时获取 Clash 订阅链接

```
local_get_clash_link.sh
```

定时获取 Github 页面中的 Clash 订阅链接，并终端显示最新链接，需要手动导入或更新 Clash Verge 的订阅！

## 2. 定时更新 gist 订阅链接

```
local-timer-sync-clash-gist.sh
```

### 2.1 脚本功能

1. **本地定时执行**：每 5 分钟自动执行一次
2. **获取订阅链接**：从 GitHub 页面提取最新 Clash 订阅链接
3. **下载订阅内容**：访问订阅链接获取配置内容
4. **上传到 Gist**：将订阅内容上传到 Gist（需配置环境变量）

### 2.2 使用方法

1. 设置环境变量（可选，用于上传到 Gist）

```bash
export GIST_ID="你的Gist_ID"
export GIST_TOKEN="你的GitHub_Personal_Token"
export GIST_FILENAME="clash.yaml"
```

2. 运行脚本

```bash
# 添加执行权限
chmod +x /workspace/sync-clash.sh

# 后台运行
nohup /workspace/sync-clash.sh > /dev/null 2>&1 &

# 查看运行状态
ps aux | grep sync-clash
```

3. 停止脚本

```bash
pkill -f sync-clash.sh
```

### 2.3 Clash Verge 使用

在 Clash Verge 中直接使用 Gist 的 **Raw URL**：

```
https://gist.githubusercontent.com/你的用户名/你的Gist_ID/raw/clash.yaml
```

这样 Clash Verge 就会下载并使用 Gist 中存储的完整订阅配置，无需再访问原始的订阅链接！