# AI 朝廷 Windows PowerShell 一键安装脚本
# 支持：Windows 10/11 原生运行（无需 WSL）
# 用法：以管理员身份打开 PowerShell，运行：
#       powershell -ExecutionPolicy Bypass -File install.ps1

param(
    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host @"
AI 朝廷 Windows 安装脚本

用法:
  .\install.ps1              # 交互式安装
  .\install.ps1 -Help        # 显示帮助

要求:
  - Windows 10/11
  - 管理员权限 (PowerShell 以管理员身份运行)
  - 网络连接

安装内容:
  - Node.js 22 LTS
  - OpenClaw CLI
  - AI 朝廷配置文件

"@
    exit 0
}

# ============================================
# 颜色输出函数
# ============================================
function Write-Info  { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "[⚠] $args" -ForegroundColor Yellow }
function Write-Error-Custom { Write-Host "[✗] $args" -ForegroundColor Red }

# ============================================
# 管理员权限检查
# ============================================
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error-Custom "请以管理员身份运行此脚本"
    Write-Info "右键点击 PowerShell → 以管理员身份运行"
    exit 1
}
Write-Success "管理员权限检查通过"

# ============================================
# 系统信息检测
# ============================================
Write-Info "系统信息:"
Write-Host "  OS: $($env:COMPUTERNAME)"
Write-Host "  Windows: $([System.Environment]::OSVersion.VersionString)"
Write-Host "  PowerShell: $($PSVersionTable.PSVersion)"
Write-Host ""

# ============================================
# Node.js 检查与安装
# ============================================
function Test-NodeJs {
    try {
        $nodeVersion = node --version 2>&1
        if ($nodeVersion -match 'v(\d+)\.') {
            $majorVersion = [int]$matches[1]
            if ($majorVersion -ge 22) {
                return $true
            } else {
                Write-Warn "Node.js 版本过低：$nodeVersion (需要 v22+)"
                return $false
            }
        }
    } catch {
        return $false
    }
    return $false
}

if (Test-NodeJs) {
    Write-Success "Node.js 已安装：$(node --version)"
} else {
    Write-Info "正在安装 Node.js 22 LTS..."
    
    # 下载 Node.js 22 LTS 安装器
    $installerUrl = "https://nodejs.org/dist/v22.14.0/node-v22.14.0-x64.msi"
    $installerPath = "$env:TEMP\node-installer.msi"
    
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        Write-Info "正在运行安装器..."
        Start-Process msiexec.exe -Wait -ArgumentList "/i `"$installerPath`" /quiet /norestart"
        Remove-Item $installerPath -Force
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Success "Node.js 安装完成"
    } catch {
        Write-Error-Custom "Node.js 安装失败：$_"
        Write-Info "请手动安装：https://nodejs.org/"
        exit 1
    }
}

# ============================================
# OpenClaw 安装
# ============================================
Write-Info "正在安装 OpenClaw CLI..."
try {
    npm install -g openclaw@latest --loglevel=error 2>&1 | Out-Null
    Write-Success "OpenClaw 安装完成：$(openclaw --version 2>&1)"
} catch {
    Write-Error-Custom "OpenClaw 安装失败：$_"
    exit 1
}

# ============================================
# 创建工作区目录
# ============================================
$workspacePath = Join-Path $env:USERPROFILE "clawd"
if (-not (Test-Path $workspacePath)) {
    New-Item -ItemType Directory -Path $workspacePath | Out-Null
    Write-Success "创建工作区：$workspacePath"
} else {
    Write-Info "工作区已存在：$workspacePath"
}

# ============================================
# 下载 AI 朝廷配置文件
# ============================================
Write-Info "正在下载 AI 朝廷配置..."

$configDir = Join-Path $env:USERPROFILE ".openclaw"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir | Out-Null
}

$configUrl = "https://raw.githubusercontent.com/wanikua/danghuangshang/main/openclaw.example.json"
$configPath = Join-Path $configDir "openclaw.json"

try {
    Invoke-WebRequest -Uri $configUrl -OutFile $configPath -UseBasicParsing
    Write-Success "配置文件已下载：$configPath"
} catch {
    Write-Warn "配置文件下载失败，生成最小配置模板"
    $wsPathJson = $workspacePath -replace '\\', '/'
    $minimalConfig = @"
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://your-llm-provider-api-url",
        "apiKey": "YOUR_LLM_API_KEY",
        "api": "openai",
        "models": [{ "id": "fast-model", "name": "快速模型", "contextWindow": 200000, "maxTokens": 8192 }]
      }
    }
  },
  "gateway": { "mode": "local", "port": 18789 },
  "agents": {
    "defaults": { "workspace": "$wsPathJson", "skipBootstrap": true, "model": { "primary": "your-provider/fast-model" } },
    "list": [{ "id": "silijian", "name": "司礼监", "identity": { "theme": "你是AI朝廷的总管，负责日常对话和任务调度。回答用中文，简洁高效。" } }]
  }
}
"@
    $minimalConfig | Out-File -FilePath $configPath -Encoding UTF8
    Write-Success "最小配置模板已生成：$configPath"
}

# ============================================
# 下载学习文档
# ============================================
$docsPath = Join-Path $workspacePath "docs"
if (-not (Test-Path $docsPath)) {
    New-Item -ItemType Directory -Path $docsPath | Out-Null
}

$docFiles = @(
    "tutorial-basics.md",
    "setup-discord.md",
    "faq.md"
)

foreach ($doc in $docFiles) {
    try {
        $docUrl = "https://raw.githubusercontent.com/wanikua/danghuangshang/main/docs/$doc"
        $docPath = Join-Path $docsPath $doc
        Invoke-WebRequest -Uri $docUrl -OutFile $docPath -UseBasicParsing
    } catch {
        Write-Warn "文档 $doc 下载失败"
    }
}

# ============================================
# 生成快速开始指南
# ============================================
$quickStartPath = Join-Path $workspacePath "WINDOWS-QUICKSTART.md"
@"
# 🪟 Windows 快速开始指南

## 安装完成！✅

Node.js 和 OpenClaw 已安装到你的系统。

## 下一步

### 1. 获取 Discord Bot Token

1. 访问 https://discord.com/developers/applications
2. 点击 "New Application"
3. 在 "Bot" 页面点击 "Reset Token" 复制 Token
4. 在 "OAuth2 → URL Generator" 中选择 `bot` 和 `applications.commands` 范围
5. 复制生成的 URL 到浏览器，邀请 Bot 到你的服务器

### 2. 编辑配置文件

用记事本或 VS Code 打开：
\`$configPath\`

找到并修改以下内容：

\`\`\`json
{
  "models": {
    "providers": {
      "your-provider": {
        "apiKey": "YOUR_LLM_API_KEY"  // ← 填入你的 LLM API Key（如 Anthropic、OpenAI）
      }
    }
  },
  "accounts": {
    "discord": [
      {
        "name": "silijian",
        "token": "YOUR_DISCORD_BOT_TOKEN"  // ← 填入 Discord Bot Token
      }
    ]
  }
}
\`\`\`

### 3. 启动 Gateway

打开 PowerShell（不需要管理员），运行：
\`\`\`powershell
openclaw gateway --verbose
\`\`\`

### 4. 在 Discord 测试

在你的 Discord 服务器里 \`@司礼监\` 打个招呼，比如：
> \`@司礼监 你好，介绍一下你自己\`

## 遇到问题？

### Gateway 启动失败
\`\`\`powershell
openclaw doctor
\`\`\`

### 查看日志
\`\`\`powershell
Get-Content $env:APPDATA\..\Local\openclaw\logs\gateway.log -Tail 50
\`\`\`

### 需要帮助？
- 📚 完整文档：https://github.com/wanikua/danghuangshang/tree/main/docs
- 💬 Discord 社区：https://discord.gg/clawd
- 🐛 提交 Issue：https://github.com/wanikua/danghuangshang/issues

## 可选：安装完整 AI 朝廷配置

如果想安装完整的朝廷配置（司礼监 + 内阁 + 六部），有两种方式：

**方式 A：使用 WSL2（推荐）**
\`\`\`powershell
wsl bash -c "`$(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh)"
\`\`\`

**方式 B：使用 Git Bash**
安装 Git for Windows 后，在 Git Bash 中运行：
\`\`\`bash
bash -c "`$(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh)"
\`\`\`

> 详细说明见 [docs/windows-wsl.md](https://github.com/wanikua/danghuangshang/blob/main/docs/windows-wsl.md)

---

祝你玩得开心！👑
"@ | Out-File -FilePath $quickStartPath -Encoding UTF8

Write-Success "快速开始指南：$quickStartPath"

# ============================================
# 完成
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  AI 朝廷 Windows 安装完成！🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Info "下一步："
Write-Host "  1. 编辑配置文件：$configPath"
Write-Host "  2. 阅读快速开始：$quickStartPath"
Write-Host "  3. 运行 Gateway: openclaw gateway --verbose"
Write-Host ""
Write-Info "提示：Gateway 可以用普通用户权限运行（不需要管理员）"
