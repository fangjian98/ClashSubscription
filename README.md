明白了！问题是 **GitHub 页面上的订阅链接本身会定期变化**，你需要：

1. **从 GitHub 页面提取最新的订阅链接**
2. **自动更新到 Clash Verge**

我帮你创建一个完整方案，通过 **GitHub Gist** 作为中转，这样 Linux 和 Windows 都能同步：

## 整体架构

```
GitHub页面 → Linux脚本(提取) → GitHub Gist(存储) → Windows脚本(更新Clash Verge)
```

---

## 第一步：创建 GitHub Gist

1. 登录 GitHub → 点击右上角 **+** → **New gist**
2. **Description**: `Clash Subscription URL`
3. **Filename**: `clash_url.txt`
4. **内容**: 暂时留空
5. 点击 **Create public gist**
6. **复制 Gist 的 URL**，格式类似：
   `https://gist.githubusercontent.com/你的用户名/xxx/raw/clash_url.txt`

---

## 第二步：Linux 端脚本（提取并上传到 Gist）

让我修改脚本：



<think duration="1994" >
The user is asking how to update the Clash Verge subscription URL every 5 minutes. The issue is that the subscription URL extracted from the GitHub page changes periodically, so they need an automated way to:

1. Extract the latest subscription URL from the GitHub page (Linux side)
2. Store it somewhere accessible
3. Have Windows Clash Verge automatically use the latest URL

The solution I proposed is to use GitHub Gist as a middleman:

- Linux script extracts URL from GitHub and uploads to Gist
- Windows script downloads from Gist and updates Clash Verge

Now I need to update the Linux script to also upload the extracted URL to GitHub Gist. Let me write the updated script.

The response should be in Simplified Chinese (based on the user's language). I'll write a comprehensive solution.

</think>



现在为你提供完整配置指南：

## 第一步：准备 GitHub Gist

### 1.1 创建 Personal Token

1. 登录 GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. 点击 **Generate new token (classic)**
3. **Note**: `Clash Gist Token`
4. **Expiration**: 选择 `No expiration`（或 30 天）
5. **Select scopes**: 勾选 **`gist`** ✅
6. 点击 **Generate token**
7. **复制并保存 token**（只显示一次！）

### 1.2 创建 Gist

1. 访问 https://gist.github.com
2. **Description**: `Clash Subscription URL`
3. **Filename**: `clash_url.txt`
4. 任意输入内容（如 `test`）
5. 点击 **Create public gist**
6. **浏览器地址栏复制 Gist ID**（最后的字符串）：
   - URL: `https://gist.github.com/你的用户名/`**`abc123def456...`**
   - Gist ID 就是: **`abc123def456...`**

---

## 第二步：配置 Linux 脚本


修改脚本中的配置（第 13-15 行）：

```bash
GIST_ID="你的Gist_ID"           # 例如：abc123def456...
GIST_FILENAME="clash_url.txt"
GIST_TOKEN="你的GitHub_Personal_Token"  # 例如：ghp_xxxxxxxxxxxx...
```

然后运行脚本：

```bash
chmod +x /workspace/get_clash_link.sh
nohup /workspace/get_clash_link.sh > /dev/null 2>&1 &
```

---

## 第三步：Windows 端脚本

在 Windows 上创建 `update_clash_verge.bat`：

```batch
@echo off
chcp 65001 >nul

REM ========== 配置 ==========
set "GIST_RAW_URL=https://gist.githubusercontent.com/你的用户名/你的Gist_ID/raw/clash_url.txt"
set "CLASH_PROFILES_DIR=%USERPROFILE%\.config\clash-verge\profiles"
set "BACKUP_DIR=%USERPROFILE%\.config\clash-verge\profiles\backup"

REM 创建目录
if not exist "%CLASH_PROFILES_DIR%" mkdir "%CLASH_PROFILES_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM 备份当前配置
echo [%date% %time%] 正在更新Clash Verge订阅...
for /f "tokens=*" %%a in ('dir /b /o-n "%CLASH_PROFILES_DIR%\*.yaml" 2^>nul') do (
    set "LATEST_PROFILE=%CLASH_PROFILES_DIR%\%%a"
    goto got_profile
)
echo 未找到现有配置文件，将创建新文件
set "LATEST_PROFILE=%CLASH_PROFILES_DIR%\auto.yaml"
:got_profile

if exist "%LATEST_PROFILE%" (
    for /f "tokens=*" %%t in ('powershell -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TIMESTAMP=%%t"
    copy "%LATEST_PROFILE%" "%BACKUP_DIR%\profile_%TIMESTAMP%.yaml" >nul
)

REM 从Gist获取最新订阅链接
for /f "tokens=*" %%u in ('curl -s --connect-timeout 10 "%GIST_RAW_URL%"') do set "SUBSCRIPTION_URL=%%u"

if not defined SUBSCRIPTION_URL (
    echo [%date% %time%] 错误：无法从Gist获取订阅链接
    echo [%date% %time%] 错误：无法从Gist获取订阅链接 >> "%~dp0clash_update.log"
    exit /b 1
)

REM 下载订阅文件
curl -s --connect-timeout 10 "%SUBSCRIPTION_URL%" -o "%LATEST_PROFILE%"

if %errorlevel% equ 0 (
    echo [%date% %time%] 订阅更新成功
    echo [%date% %time%] 新链接: %SUBSCRIPTION_URL%
) else (
    echo [%date% %time%] 下载订阅失败
    echo [%date% %time%] 下载订阅失败 >> "%~dp0clash_update.log"
    exit /b 1
)
```

**保存为** `C:\Scripts\update_clash_verge.bat`

---

## 第四步：设置 Windows 定时任务

**方法一：使用计划任务（推荐）**

1. **以管理员身份运行 PowerShell**：

```powershell
$action = New-ScheduledTaskAction -Execute "C:\Scripts\update_clash_verge.bat"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName "ClashVerge自动更新" -Action $action -Trigger $trigger -RunLevel Highest -Description "每5分钟自动更新Clash Verge订阅"
```

2. **立即运行一次测试**：

```powershell
Start-ScheduledTask -TaskName "ClashVerge自动更新"
```

**方法二：手动创建计划任务**

1. 按 `Win + R` → 输入 `taskschd.msc` → 回车
2. **操作** → **创建任务**
3. **常规**：
   - 名称：`ClashVerge自动更新`
   - 勾选「使用最高权限运行」
4. **触发器**：
   - 新建 → 「按预定时间」→ 「每 5 分钟」
5. **操作**：
   - 新建 → 「启动程序」→ 浏览选择 `update_clash_verge.bat`
6. **条件**：
   - 勾选「只有在计算机交流电源时才启动此任务」（取消勾选）
   - 勾选「如果改成电池供电模式，则停止」

---

## 完整流程图

```
┌─────────────────────────────────────────────────────────────┐
│                    Linux 服务器                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 每5分钟执行 get_clash_link.sh                       │   │
│  │ 1. 从 tolink页面提取最新Clash订阅链接               │   │
│  │ 2. 保存到本地 clash_subscription.txt               │   │
│  │ 3. 上传到 GitHub Gist                               │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Gist（中转存储）                    │
│  存储格式：                                                  │
│  https://dxMCfu.tosslk.xyz/833c1ff294497bee55221948f3b369bf │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Windows PC                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 计划任务：每5分钟执行 update_clash_verge.bat        │   │
│  │ 1. 从 Gist raw URL 获取最新订阅链接                 │   │
│  │ 2. 下载订阅文件到 Clash Verge 配置目录              │   │
│  │ 3. Clash Verge 自动加载新配置                       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 验证测试

**Linux 端**：

```bash
# 查看日志
cat clash_getter.log

# 查看本地记录
cat clash_subscription.txt

# 访问Gist确认上传成功
# https://gist.github.com/你的用户名/你的Gist_ID
```

**Windows 端**：

```batch
# 手动运行测试
C:\Scripts\update_clash_verge.bat

# 查看日志
type C:\Scripts\clash_update.log

# 在Clash Verge中手动刷新配置
```

这样就实现了完整的自动化流程：Linux 每 5 分钟提取最新链接并上传到 Gist，Windows 每 5 分钟从 Gist 获取并更新到 Clash Verge，完全无需手动操作！