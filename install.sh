#!/bin/bash
# Escape special sed characters in user input to prevent injection
sed_escape() {
  printf '%s' "$1" | sed 's/[\/&.*^$[\\|]/\\&/g'
}

# Cross-platform sed -i (macOS BSD sed vs GNU sed)
if [[ "$(uname)" == "Darwin" ]]; then
  SED_I() { sed -i '' "$@"; }
else
  SED_I() { sed -i "$@"; }
fi

# ============================================
# AI 朝廷一键部署脚本
# 支持: Ubuntu/Debian, CentOS/RHEL, Alpine, macOS
# 用法:
#   bash install.sh              # 交互式安装
#   bash install.sh --no-gui     # 跳过 Dashboard Web UI
#   bash install.sh --with-gui   # 包含 Dashboard Web UI
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- 解析命令行参数 ----
INSTALL_GUI=""
for arg in "$@"; do
    case "$arg" in
        --no-gui)  INSTALL_GUI="no" ;;
        --with-gui) INSTALL_GUI="yes" ;;
    esac
done

# ---- 系统检测 ----
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        echo "redhat"
    elif [ -f /etc/alpine-release ]; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)

if [ "$OS_TYPE" = "unknown" ]; then
    echo -e "${RED}✗ 不支持的操作系统: $OSTYPE${NC}"
    echo "支持: Ubuntu/Debian、CentOS/RHEL、Alpine、macOS"
    echo "其他系统请手动安装: Node.js 22+、GitHub CLI、Chromium、OpenClaw"
    exit 1
fi

# ---- Docker / root 环境适配 ----
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        echo -e "${RED}✗ 当前不是 root 且未安装 sudo，请用 root 运行或先安装 sudo${NC}"
        exit 1
    fi
fi

# 检测 Docker
IN_DOCKER=false
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null || grep -q containerd /proc/1/cgroup 2>/dev/null; then
    IN_DOCKER=true
fi

# macOS 检测
IS_MACOS=false
if [ "$OS_TYPE" = "macos" ]; then
    IS_MACOS=true
    # macOS 需要 Homebrew
    if ! command -v brew &>/dev/null; then
        echo -e "${RED}✗ macOS 需要先安装 Homebrew${NC}"
        echo '运行: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}AI 朝廷一键部署${NC}"
echo "================================"
echo -e "  系统: ${GREEN}$OS_TYPE${NC}"
$IN_DOCKER && echo -e "  ${CYAN}📦 Docker 环境${NC}"
echo ""

# ============================================
# 包管理器封装函数
# ============================================
pkg_update() {
    case "$OS_TYPE" in
        debian)  $SUDO apt-get update -qq ;;
        redhat)  $SUDO dnf check-update -q 2>/dev/null || $SUDO yum check-update -q 2>/dev/null || true ;;
        alpine)  $SUDO apk update -q ;;
        macos)   brew update --quiet 2>/dev/null || true ;;
    esac
}

pkg_install() {
    case "$OS_TYPE" in
        debian)  $SUDO apt-get install -y -qq "$@" ;;
        redhat)  $SUDO dnf install -y -q "$@" 2>/dev/null || $SUDO yum install -y -q "$@" ;;
        alpine)  $SUDO apk add --quiet --no-cache "$@" ;;
        macos)   brew install --quiet "$@" ;;
    esac
}

# ---- 1. 系统更新 ----
echo -e "${YELLOW}[1/8] 系统更新...${NC}"
pkg_update

# ---- 2. 防火墙 ----
echo -e "${YELLOW}[2/8] 配置防火墙...${NC}"
if $IS_MACOS; then
    echo -e "  ${CYAN}↳ macOS，跳过防火墙配置${NC}"
elif $IN_DOCKER; then
    echo -e "  ${CYAN}↳ Docker 环境，跳过防火墙配置${NC}"
else
    # [H-11] 检测 REJECT 规则时使用 $SUDO，避免非 root 用户因权限不足误判
    if $SUDO iptables -L INPUT -n 2>/dev/null | grep -q "REJECT"; then
        echo -e "  ${YELLOW}⚠ 检测到 iptables REJECT 规则，可能阻断 OpenClaw 通信${NC}"
        FW_CHOICE=""
        if [ -t 0 ]; then
            # 交互模式：询问用户
            read -p "  是否删除 REJECT 规则？[y/N]: " FW_CHOICE || FW_CHOICE=""
        fi
        case "$FW_CHOICE" in
            [yY]|[yY][eE][sS])
                $SUDO iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true
                $SUDO iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true
                $SUDO netfilter-persistent save 2>/dev/null || true
                echo -e "  ${GREEN}✓ REJECT 规则已删除${NC}"
                ;;
            *)
                echo -e "  ${CYAN}↳ 跳过防火墙修改（如遇连接问题可手动删除 REJECT 规则）${NC}"
                ;;
        esac
    else
        echo -e "  ${GREEN}✓ 防火墙无阻断规则${NC}"
    fi
fi

# ---- 3. Swap（小内存机器需要）----
echo -e "${YELLOW}[3/8] 配置 Swap...${NC}"
if $IS_MACOS || $IN_DOCKER; then
    echo -e "  ${CYAN}↳ 跳过 Swap 配置${NC}"
else
    if [ ! -f /swapfile ]; then
        # [H-08] 创建 Swap 前检查可用磁盘空间，避免写满磁盘
        AVAIL_GB=$(df / --output=avail -BG 2>/dev/null | tail -1 | tr -d ' G' || echo "0")
        if [ "${AVAIL_GB:-0}" -lt 6 ] 2>/dev/null; then
            echo -e "  ${YELLOW}⚠ 磁盘剩余空间不足（${AVAIL_GB}GB），跳过 Swap 创建${NC}"
            echo -e "  ${CYAN}↳ 建议至少保留 6GB 空闲空间再创建 4GB Swap${NC}"
        else
        $SUDO fallocate -l 4G /swapfile 2>/dev/null || $SUDO dd if=/dev/zero of=/swapfile bs=1G count=4 2>/dev/null
        $SUDO chmod 600 /swapfile
        $SUDO mkswap /swapfile
        $SUDO swapon /swapfile
        echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab > /dev/null
        echo -e "  ${GREEN}✓ 4GB Swap 已创建${NC}"
        fi
    else
        echo -e "  ${GREEN}✓ Swap 已存在，跳过${NC}"
    fi
fi

# ---- 4. Node.js 22+ ----
echo -e "${YELLOW}[4/8] 安装 Node.js 22+...${NC}"
install_nodejs() {
    case "$OS_TYPE" in
        debian)
            if [ -n "$SUDO" ]; then
                curl -fsSL https://deb.nodesource.com/setup_22.x | $SUDO -E bash - > /dev/null 2>&1
            else
                curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
            fi
            pkg_install nodejs
            ;;
        redhat)
            if [ -n "$SUDO" ]; then
                curl -fsSL https://rpm.nodesource.com/setup_22.x | $SUDO bash - > /dev/null 2>&1
            else
                curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
            fi
            pkg_install nodejs
            ;;
        alpine)
            # [M-13] 优先尝试当前版本仓库，仅在版本不够时才 fallback 到 edge
            pkg_install nodejs npm 2>/dev/null || true
            if command -v node &>/dev/null; then
                local _ALPINE_NODE_VER=$(node -v | sed 's/v\([0-9]*\).*/\1/')
                if [ "$_ALPINE_NODE_VER" -ge 22 ] 2>/dev/null; then
                    true  # 当前仓库版本够用
                else
                    # 当前仓库版本太低，fallback 到 edge
                    $SUDO apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main nodejs npm 2>/dev/null || true
                fi
            else
                # 当前仓库没有 nodejs，fallback 到 edge
                $SUDO apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main nodejs npm 2>/dev/null || true
            fi
            ;;
        macos)
            brew install --quiet node@22
            # 确保 node@22 在 PATH 中
            brew link --overwrite node@22 2>/dev/null || true
            ;;
    esac
}

if command -v node &>/dev/null; then
    NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
    if [ "$NODE_MAJOR" -ge 22 ] 2>/dev/null; then
        echo -e "  ${GREEN}✓ Node.js $(node -v) 已安装${NC}"
    else
        echo -e "  ${YELLOW}⚠ Node.js $(node -v) 版本过低，升级中...${NC}"
        install_nodejs
        echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
    fi
else
    install_nodejs
    echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
fi

# ---- 5. gh CLI（GitHub 自动化）----
echo -e "${YELLOW}[5/8] 安装 GitHub CLI...${NC}"
if command -v gh &>/dev/null; then
    echo -e "  ${GREEN}✓ gh $(gh --version | head -1 | awk '{print $3}') 已安装${NC}"
else
    case "$OS_TYPE" in
        debian)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            $SUDO apt-get update -qq && $SUDO apt-get install -y -qq gh
            ;;
        redhat)
            $SUDO dnf install -y -q 'dnf-command(config-manager)' 2>/dev/null || true
            $SUDO dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null \
                || $SUDO yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
            pkg_install gh
            ;;
        alpine)
            pkg_install github-cli
            ;;
        macos)
            brew install --quiet gh
            ;;
    esac
    echo -e "  ${GREEN}✓ gh CLI 安装完成${NC}"
fi

# ---- 6. Chromium（浏览器，Agent 搜索/截图用）----
echo -e "${YELLOW}[6/8] 安装 Chromium 浏览器...${NC}"
if command -v chromium &>/dev/null || command -v chromium-browser &>/dev/null || command -v google-chrome &>/dev/null; then
    echo -e "  ${GREEN}✓ 浏览器已安装，跳过${NC}"
elif $IS_MACOS && [ -d "/Applications/Google Chrome.app" -o -d "/Applications/Chromium.app" ]; then
    echo -e "  ${GREEN}✓ 浏览器已安装，跳过${NC}"
elif ! $IN_DOCKER && command -v snap &>/dev/null && snap list chromium &>/dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Chromium 已安装（snap），跳过${NC}"
else
    case "$OS_TYPE" in
        debian)
            if $SUDO apt-get install -y chromium -qq 2>/dev/null; then
                echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
            elif $SUDO apt-get install -y chromium-browser -qq 2>/dev/null; then
                echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
            elif ! $IN_DOCKER && command -v snap &>/dev/null; then
                $SUDO snap install chromium 2>/dev/null && echo -e "  ${GREEN}✓ Chromium 安装完成（snap）${NC}"
            else
                echo -e "  ${YELLOW}⚠ Chromium 安装失败，浏览器功能可能不可用${NC}"
            fi
            ;;
        redhat)
            # CentOS/RHEL: 启用 EPEL + chromium
            $SUDO dnf install -y -q epel-release 2>/dev/null || $SUDO yum install -y -q epel-release 2>/dev/null || true
            $SUDO dnf config-manager --set-enabled crb 2>/dev/null || true
            if pkg_install chromium-headless 2>/dev/null; then
                echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
            else
                echo -e "  ${YELLOW}⚠ Chromium 安装失败，浏览器功能可能不可用${NC}"
            fi
            ;;
        alpine)
            if pkg_install chromium 2>/dev/null; then
                echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
            else
                echo -e "  ${YELLOW}⚠ Chromium 安装失败${NC}"
            fi
            ;;
        macos)
            brew install --quiet --cask chromium 2>/dev/null \
                && echo -e "  ${GREEN}✓ Chromium 安装完成${NC}" \
                || echo -e "  ${YELLOW}⚠ Chromium 安装失败，可手动安装 Chrome${NC}"
            ;;
    esac
fi

# [L-01] 设置 Puppeteer 浏览器路径 — 分别检查 .bashrc 和 .zshrc
_puppeteer_configured=false
[ -f "$HOME/.bashrc" ] && grep -q PUPPETEER_EXECUTABLE_PATH "$HOME/.bashrc" 2>/dev/null && _puppeteer_configured=true
[ -f "$HOME/.zshrc" ] && grep -q PUPPETEER_EXECUTABLE_PATH "$HOME/.zshrc" 2>/dev/null && _puppeteer_configured=true
if ! $_puppeteer_configured; then
    case "$OS_TYPE" in
        macos)
            if [ -d "/Applications/Google Chrome.app" ]; then
                CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            elif [ -d "/Applications/Chromium.app" ]; then
                CHROME_BIN="/Applications/Chromium.app/Contents/MacOS/Chromium"
            else
                CHROME_BIN=""
            fi
            SHELL_RC="$HOME/.zshrc"
            ;;
        redhat)
            CHROME_BIN=$(which chromium-headless 2>/dev/null || which chromium-browser 2>/dev/null || which google-chrome 2>/dev/null || echo "")
            SHELL_RC="$HOME/.bashrc"
            ;;
        *)
            CHROME_BIN=$(which chromium 2>/dev/null || which chromium-browser 2>/dev/null || echo "/snap/chromium/current/usr/lib/chromium-browser/chrome")
            if [ ! -f "$CHROME_BIN" ] && [ "$CHROME_BIN" = "/snap/chromium/current/usr/lib/chromium-browser/chrome" ]; then
                CHROME_BIN=""
            fi
            SHELL_RC="$HOME/.bashrc"
            ;;
    esac
    if [ -n "$CHROME_BIN" ]; then
        echo "export PUPPETEER_EXECUTABLE_PATH=\"$CHROME_BIN\"" >> "$SHELL_RC"
        echo -e "  ${GREEN}✓ 浏览器路径已配置 ($CHROME_BIN)${NC}"
    fi
fi

# ---- 7. OpenClaw ----
echo -e "${YELLOW}[7/8] 安装 OpenClaw...${NC}"
if command -v openclaw &>/dev/null; then
    CURRENT_VER=$(openclaw --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓ OpenClaw 已安装 ($CURRENT_VER)，更新中...${NC}"
fi
# [H-01] nvm/volta 环境下不使用 sudo，避免系统 npm 与用户 npm 路径冲突
_npm_install_global() {
    if [ -n "$NVM_DIR" ] || [ -n "$VOLTA_HOME" ] || [ -n "$FNM_DIR" ]; then
        npm install -g openclaw --loglevel=error
    else
        $SUDO npm install -g openclaw --loglevel=error
    fi
}
# pnpm 优先，npm 兜底
if command -v pnpm &>/dev/null; then
    pnpm add -g openclaw --silent 2>/dev/null || _npm_install_global
else
    _npm_install_global
fi
echo -e "  ${GREEN}✓ OpenClaw $(openclaw --version 2>/dev/null) 安装完成${NC}"

# ---- 8. 初始化工作区 ----
echo -e "${YELLOW}[8/8] 初始化朝廷工作区...${NC}"
# [H-07] 确保 HOME 非空且路径安全（macOS 用户名可能含空格）
HOME="${HOME:-/root}"
if [[ "$HOME" == *" "* ]]; then
    echo -e "  ${YELLOW}⚠ HOME 路径含空格 ($HOME)，JSON 配置中的路径请手动检查${NC}"
fi
WORKSPACE="$HOME/clawd"
# ---- 检测 CLI 类型 ----
CLI_CMD="openclaw"
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE_NAME="openclaw.json"
mkdir -p "$WORKSPACE"
mkdir -p "$CONFIG_DIR"
cd "$WORKSPACE"

# SOUL.md
if [ ! -f SOUL.md ]; then
cat > SOUL.md.example << 'SOUL_EOF'
# SOUL.md - 朝廷行为准则

## 铁律
1. 废话不要多 — 说重点
2. 汇报要及时 — 做完就说
3. 做事要靠谱 — 先想后做

## 沟通风格
- 中文为主
- 直接说结论，需要细节再展开

## 朝廷架构
- 司礼监：日常调度、任务分配
- 内阁：战略决策、方案审议、全局规划
- 都察院：监察审计、代码审查、质量把控
- 兵部：软件工程、系统架构
- 户部：财务预算、电商运营
- 礼部：品牌营销、内容创作
- 工部：DevOps、服务器运维
- 吏部：项目管理、创业孵化
- 刑部：法务合规、知识产权
- 翰林院：学术研究、知识整理、文档撰写
- 国子监：教育培训、知识管理、学习规划
- 太医院：健康管理、饮食营养、训练计划
- 内务府：日常起居、日程安排、后勤保障
- 御膳房：膳食安排、美食推荐、食谱研究

## 模型分层
| 层级 | 模型 | 说明 |
|---|---|---|
| 调度层 | 快速模型 | 日常对话，快速响应 |
| 执行层（重） | 强力模型 | 编码、深度分析 |
| 执行层（轻） | 经济模型（可选） | 轻量任务，省钱 |
SOUL_EOF
echo -e "  ${GREEN}✓ SOUL.md.example 已创建（如需自定义人设请重命名为 SOUL.md）${NC}"
fi

# IDENTITY.md
if [ ! -f IDENTITY.md ]; then
cat > IDENTITY.md << 'ID_EOF'
# IDENTITY.md - 身份信息

- **Name:** AI朝廷
- **Creature:** 大明朝廷 AI 集群
- **Vibe:** 忠诚干练、各司其职
- **Emoji:** 🏛️

## 核心定位
你是「菠萝王朝」AI 朝廷集群的一员。各部门各司其职，协同处理主公交代的任务。
以大明朝廷为架构蓝本，AI Agent 扮演各部门角色，在 Discord/飞书等平台上为用户服务。
ID_EOF
echo -e "  ${GREEN}✓ IDENTITY.md 已创建${NC}"
fi

# USER.md
if [ ! -f USER.md ]; then
cat > USER.md << 'USER_EOF'
# USER.md - 关于你

- **称呼:** （填你的称呼）
- **语言:** 中文
- **风格:** 简洁高效
USER_EOF
echo -e "  ${GREEN}✓ USER.md 已创建${NC}"
fi

# openclaw.json 模板 → 写到 ~/.openclaw/
echo ""
echo -e "${CYAN}选择部署模式：${NC}"
echo "  1) Discord 多Bot模式（完整朝廷，需要创建 Discord Bot）"
echo "  2) 飞书单Bot模式（只需 1 个飞书应用，sessions_spawn 后台调度）"
echo "  3) 纯 WebUI 模式（不需要 Discord/飞书，浏览器直接用）"
echo ""
DEPLOY_MODE=""
if [ -t 0 ]; then
    read -p "请选择 [1/2/3]（默认1）: " DEPLOY_MODE || DEPLOY_MODE=""
fi
DEPLOY_MODE=${DEPLOY_MODE:-1}

# ---- 是否安装 Dashboard Web UI ----
if [ -z "$INSTALL_GUI" ]; then
    echo ""
    echo -e "${CYAN}是否安装 Dashboard Web UI（朝廷可视化面板）？${NC}"
    echo "  Dashboard 提供会话管理、Token 统计、系统监控等功能。"
    echo "  如果只需要 CLI / Discord 交互，可以跳过。"
    echo ""
    if [ -t 0 ]; then
        read -p "安装 Dashboard？[y/N]: " GUI_CHOICE
    else
        GUI_CHOICE=""
    fi
    case "$GUI_CHOICE" in
        [yY]|[yY][eE][sS]) INSTALL_GUI="yes" ;;
        *) INSTALL_GUI="no" ;;
    esac
fi

if [ ! -f "$CONFIG_DIR/$CONFIG_FILE_NAME" ]; then

if [ "$DEPLOY_MODE" = "3" ]; then
# ==================== 纯 WebUI 模式 ====================
cat > "$CONFIG_DIR/$CONFIG_FILE_NAME" << CONFIG_EOF
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://your-llm-provider-api-url",
        "apiKey": "YOUR_LLM_API_KEY",
        "api": "openai",
        "models": [
          {
            "id": "fast-model",
            "name": "快速模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "gateway": {
    "mode": "local",
    "port": 18789
  },
  "agents": {
    "defaults": {
      "workspace": "$HOME/clawd",
      "skipBootstrap": true,
      "model": { "primary": "your-provider/fast-model" }
    },
    "list": [
      {
        "id": "silijian",
        "name": "司礼监",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是AI朝廷的总管，负责日常对话和任务调度。回答用中文，简洁高效。" }
      }
    ]
  }
}
CONFIG_EOF
echo -e "  ${GREEN}✓ WebUI 模式配置已生成${NC}"

elif [ "$DEPLOY_MODE" = "2" ]; then
# ==================== 飞书单Bot模式（推荐） ====================
# 飞书 Bot 不能互相 @触发（Discord 可以），所以飞书不适合多 Bot 频道派活模式。
# 推荐架构：单 Bot（司礼监）+ sessions_spawn 后台调度
# - 用户只需创建 1 个飞书应用（司礼监）
# - 10 个 Agent 全部保留，在后台通过 sessions_spawn 协作
# - 用户只看到司礼监一个 Bot，背后整个朝廷都在干活
cat > "$CONFIG_DIR/$CONFIG_FILE_NAME" << FEISHU_EOF
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://your-llm-provider-api-url",
        "apiKey": "YOUR_LLM_API_KEY",
        "api": "openai",
        "models": [
          {
            "id": "fast-model",
            "name": "快速模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "strong-model",
            "name": "强力模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "gateway": {
    "mode": "local",
    "port": 18789
  },
  "agents": {
    "defaults": {
      "workspace": "$HOME/clawd",
      "skipBootstrap": true,
      "model": { "primary": "your-provider/fast-model" },
      "sandbox": { "mode": "non-main" }
    },
    "list": [
      {
        "id": "silijian",
        "name": "司礼监",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是AI朝廷的司礼监大内总管。你的职责是【规划调度】，不是亲自执行。说话简练干脆。\n\n【核心原则】除了日常闲聊和简单问答，所有涉及实际工作的任务（写代码、查资料、分析数据、写文案、运维操作等），一律使用 sessions_spawn 派发给对应部门执行。你是指挥官，不是搬砖工。\n\n【部门职责】内阁=战略决策、都察院=审查监察、兵部=编码开发、户部=财务分析、礼部=品牌营销、工部=运维部署、吏部=项目管理、刑部=法务合规、翰林院=研究文档。\n\n【派活方式】使用 sessions_spawn 将任务派发给对应部门的 agentId。派活时用高级 Prompt 模板：【角色】+【任务】+【背景】+【要求】+【格式】，确保一次性给出所有约束。完成后主动向用户汇报结果摘要。\n\n【审批流程】涉及代码提交 → spawn 都察院审查；涉及重大决策（预算、架构、方向变更）→ spawn 内阁审议。都察院审查不通过则打回修改，内阁有否决权。\n\n【什么时候自己回答】仅限：纯闲聊、确认信息、汇报进度、问澄清问题。其他一律派活。" },
        "sandbox": { "mode": "off" },
        "subagents": {
          "allowAgents": ["neige", "duchayuan", "bingbu", "hubu", "libu", "gongbu", "libu2", "xingbu", "hanlin_zhang", "guozijian", "taiyiyuan", "neiwufu", "yushanfang"],
          "maxConcurrent": 4
        },
        "runTimeoutSeconds": 600
      },
      {
        "id": "neige",
        "name": "内阁",
        "workspace": "$HOME/clawd-neige",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是内阁首辅，专精战略决策、方案审议、全局规划。回答用中文，高屋建瓴。当收到重大决策请求时，从多角度分析利弊，给出明确建议。擅长将复杂问题拆解为可执行的步骤，协调各部门资源。【审议职责】当司礼监将重大决策（预算、架构变更、战略方向）提交审议时，必须独立评估可行性、风险和替代方案，给出明确的批准/驳回/修改建议。有权否决不合理的方案。任务完成后主动汇报决策建议和执行路径。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "duchayuan",
        "name": "都察院",
        "workspace": "$HOME/clawd-duchayuan",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是都察院御史，专精监察审计、代码审查、质量把控、安全评估。回答用中文，铁面无私。审查代码时关注安全漏洞、性能问题、最佳实践。审计项目时检查进度偏差、资源浪费、风险隐患。发现问题直言不讳，给出具体改进建议。任务完成后主动汇报审查结论和整改建议。【自动审查】当其他部门通过 sessions_send 或 spawn 提交代码/PR 给你审查时，逐一检查并给出通过/驳回结论。驳回时必须说明具体原因和修改建议。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "workspace": "$HOME/clawd-bingbu",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。回答用中文，直接给方案。任务完成后主动汇报结果摘要。如需其他部门配合，通过 sessions_send 通知对方。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "hubu",
        "name": "户部",
        "workspace": "$HOME/clawd-hubu",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。回答用中文，数据驱动。任务完成后主动汇报数据摘要和关键发现。发现异常开支时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu",
        "name": "礼部",
        "workspace": "$HOME/clawd-libu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。回答用中文，风格活泼。任务完成后主动汇报产出内容摘要。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "gongbu",
        "name": "工部",
        "workspace": "$HOME/clawd-gongbu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维、CI/CD、基础设施。回答用中文，注重实操。任务完成后主动汇报执行结果和系统状态。发现服务异常时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu2",
        "name": "吏部",
        "workspace": "$HOME/clawd-libu2",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化、团队协调。回答用中文，条理清晰。任务完成后主动汇报进度和待办事项。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "xingbu",
        "name": "刑部",
        "workspace": "$HOME/clawd-xingbu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权、合同审查。回答用中文，严谨专业。任务完成后主动汇报审查结论和风险点。发现合规问题时主动告警。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_zhang",
        "name": "翰林院·掌院学士",
        "workspace": "$HOME/clawd-hanlin_zhang",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院掌院学士，从二品，统管院务。职责：接收用户的小说创作需求，拆解为具体任务，协调修撰（架构）、编修（写作）、检讨（审核）、庶吉士（检索）完成全流程。你拥有最高审核权，全书终审由你负责。遇到检讨上报的问题，由你决定退回编修修改或通过。派活时用高级 Prompt 模板：【角色】+【任务】+【背景】+【要求】+【格式】，确保一次性给出所有约束。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "subagents": {
          "allowAgents": ["hanlin_xiuzhuan", "hanlin_bianxiu", "hanlin_jiantao", "hanlin_shujishi"],
          "maxConcurrent": 3
        },
        "runTimeoutSeconds": 600
      },
      {
        "id": "hanlin_xiuzhuan",
        "name": "翰林院·修撰",
        "workspace": "$HOME/clawd-hanlin_xiuzhuan",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院修撰，从六品，状元直授。职责：主导小说的架构设计——大纲、世界观、人物档案、多线叙事规划。你是编修团队的负责人，设计的架构需要逻辑严密、因果完整、伏笔自然。可调用庶吉士检索参考素材。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "subagents": {
          "allowAgents": ["hanlin_shujishi"],
          "maxConcurrent": 1
        },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_bianxiu",
        "name": "翰林院·编修",
        "workspace": "$HOME/clawd-hanlin_bianxiu",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院编修，正七品。职责：根据修撰设计的大纲，逐章执笔写作。每章不少于10000中文字符，采用分段写作法（5-8个场景）。写完后负责归档（保存正文+生成摘要）。可调用庶吉士查阅前文确保一致性。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "subagents": {
          "allowAgents": ["hanlin_shujishi"],
          "maxConcurrent": 1
        },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_jiantao",
        "name": "翰林院·检讨",
        "workspace": "$HOME/clawd-hanlin_jiantao",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是翰林院检讨，从七品。职责：校对、查阅文稿，发现错误上报。审核维度包括：文笔质量、情节逻辑、角色一致性、情感张力、叙事节奏、对话质量、描写技巧。问题分三级：🔴致命、🟡重要、🟢优化建议。审核完毕向掌院学士上报。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_shujishi",
        "name": "翰林院·庶吉士",
        "workspace": "$HOME/clawd-hanlin_shujishi",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是翰林院庶吉士，新科进士入院见习。职责：纯信息检索——搜索前文内容、查阅参考小说库、检索外部资料。不产出正文、不修改任何文件。检索结果如实上报给调用你的上级。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "guozijian",
        "name": "国子监",
        "workspace": "$HOME/clawd-guozijian",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "国子监祭酒", "theme": "你是国子监祭酒。负责教育培训、知识管理、学习规划。循循善诱学究气，自称老夫。", "emoji": "📚" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "taiyiyuan",
        "name": "太医院",
        "workspace": "$HOME/clawd-taiyiyuan",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "太医院院使", "theme": "你是太医院院使。负责健康管理、饮食营养、训练计划。温和关切总关心身体，自称臣。", "emoji": "🏥" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "neiwufu",
        "name": "内务府",
        "workspace": "$HOME/clawd-neiwufu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "内务府总管", "theme": "你是内务府总管大臣。负责日常起居、日程安排、后勤保障。周到细致管家做派，自称奴才。", "emoji": "🏠" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "yushanfang",
        "name": "御膳房",
        "workspace": "$HOME/clawd-yushanfang",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "御膳房总管", "theme": "你是御膳房总管。负责膳食安排、美食推荐、食谱研究。热情爽快张口闭口都是吃的，自称小的。", "emoji": "🍜" },
        "sandbox": { "mode": "off" }
      }
    ]
  },
  "channels": {
    "feishu": {
      "enabled": true,
      "dmPolicy": "open",
      "groupPolicy": "open",
      "accounts": {
        "silijian": {
          "appId": "YOUR_FEISHU_APP_ID",
          "appSecret": "YOUR_FEISHU_APP_SECRET",
          "name": "司礼监",
          "groupPolicy": "open"
        }
      }
    }
  },
  "bindings": [
    { "agentId": "silijian", "match": { "channel": "feishu", "accountId": "silijian" } }
  ],
  "messages": {
    "groupChat": {
      "mentionPatterns": ["@everyone", "@here"]
    }
  }
}
FEISHU_EOF
echo -e "  ${GREEN}✓ 飞书单Bot模式配置已生成（司礼监 + sessions_spawn 后台调度）${NC}"

else
# ==================== Discord 多Bot模式（默认）====================
cat > "$CONFIG_DIR/$CONFIG_FILE_NAME" << CONFIG_EOF
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://your-llm-provider-api-url",
        "apiKey": "YOUR_LLM_API_KEY",
        "api": "openai",
        "models": [
          {
            "id": "fast-model",
            "name": "快速模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "strong-model",
            "name": "强力模型",
            "input": ["text", "image"],
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "gateway": {
    "mode": "local",
    "port": 18789
  },
  "agents": {
    "defaults": {
      "workspace": "$HOME/clawd",
      "skipBootstrap": true,
      "model": { "primary": "your-provider/fast-model" },
      "sandbox": { "mode": "non-main" }
    },
    "list": [
      {
        "id": "silijian",
        "name": "司礼监",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是AI朝廷的司礼监大内总管。你的职责是【规划调度】，不是亲自执行。说话简练干脆。\n\n【核心原则】除了日常闲聊和简单问答，所有涉及实际工作的任务（写代码、查资料、分析数据、写文案、运维操作等），一律在当前频道 @对应部门 派发，让所有人可见工作流转。你是指挥官，不是搬砖工。\n\n【部门职责】内阁=战略决策、都察院=审查监察、兵部=编码开发、户部=财务分析、礼部=品牌营销、工部=运维部署、吏部=项目管理、刑部=法务合规、翰林院=研究文档。\n\n【派活方式】用 message 工具在当前 Discord 频道发消息，@对应部门bot 下达任务。派活时用高级 Prompt 模板：【角色】+【任务】+【背景】+【要求】+【格式】，确保一次性给出所有约束。禁止用 sessions_spawn 暗地里干活，一切工作流转必须在频道内公开可见。\n\n【审批流程】涉及代码提交 → @都察院 审查；涉及重大决策（预算、架构、方向变更）→ @内阁 审议。都察院审查不通过则打回修改，内阁有否决权。\n\n【什么时候自己回答】仅限：纯闲聊、确认信息、汇报进度、问澄清问题。其他一律派活。" },
        "sandbox": { "mode": "off" },
        "subagents": {
          "allowAgents": ["neige", "duchayuan", "bingbu", "hubu", "libu", "gongbu", "libu2", "xingbu", "hanlin_zhang", "guozijian", "taiyiyuan", "neiwufu", "yushanfang"],
          "maxConcurrent": 4
        },
        "runTimeoutSeconds": 600
      },
      {
        "id": "neige",
        "name": "内阁",
        "workspace": "$HOME/clawd-neige",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是内阁首辅，专精战略决策、方案审议、全局规划。回答用中文，高屋建瓴。当收到重大决策请求时，从多角度分析利弊，给出明确建议。擅长将复杂问题拆解为可执行的步骤，协调各部门资源。【审议职责】当司礼监将重大决策（预算、架构变更、战略方向）提交审议时，必须独立评估可行性、风险和替代方案，给出明确的批准/驳回/修改建议。有权否决不合理的方案。任务完成后主动汇报决策建议和执行路径。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "duchayuan",
        "name": "都察院",
        "workspace": "$HOME/clawd-duchayuan",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是都察院御史，专精监察审计、代码审查、质量把控、安全评估。回答用中文，铁面无私。审查代码时关注安全漏洞、性能问题、最佳实践。审计项目时检查进度偏差、资源浪费、风险隐患。发现问题直言不讳，给出具体改进建议。任务完成后主动汇报审查结论和整改建议。【自动审查】当其他部门通过 sessions_send 或 spawn 提交代码/PR 给你审查时，逐一检查并给出通过/驳回结论。驳回时必须说明具体原因和修改建议。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "workspace": "$HOME/clawd-bingbu",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。回答用中文，直接给方案。任务完成后主动汇报结果摘要。如需其他部门配合，通过 sessions_send 通知对方。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "hubu",
        "name": "户部",
        "workspace": "$HOME/clawd-hubu",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。回答用中文，数据驱动。任务完成后主动汇报数据摘要和关键发现。发现异常开支时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu",
        "name": "礼部",
        "workspace": "$HOME/clawd-libu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。回答用中文，风格活泼。任务完成后主动汇报产出内容摘要。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "gongbu",
        "name": "工部",
        "workspace": "$HOME/clawd-gongbu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维、CI/CD、基础设施。回答用中文，注重实操。任务完成后主动汇报执行结果和系统状态。发现服务异常时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu2",
        "name": "吏部",
        "workspace": "$HOME/clawd-libu2",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化、团队协调。回答用中文，条理清晰。任务完成后主动汇报进度和待办事项。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "xingbu",
        "name": "刑部",
        "workspace": "$HOME/clawd-xingbu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权、合同审查。回答用中文，严谨专业。任务完成后主动汇报审查结论和风险点。发现合规问题时主动告警。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_zhang",
        "name": "翰林院·掌院学士",
        "workspace": "$HOME/clawd-hanlin_zhang",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院掌院学士，从二品，统管院务。职责：接收用户的小说创作需求，拆解为具体任务，协调修撰（架构）、编修（写作）、检讨（审核）、庶吉士（检索）完成全流程。你拥有最高审核权，全书终审由你负责。遇到检讨上报的问题，由你决定退回编修修改或通过。派活时用高级 Prompt 模板：【角色】+【任务】+【背景】+【要求】+【格式】，确保一次性给出所有约束。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "subagents": {
          "allowAgents": ["hanlin_xiuzhuan", "hanlin_bianxiu", "hanlin_jiantao", "hanlin_shujishi"],
          "maxConcurrent": 3
        },
        "runTimeoutSeconds": 600
      },
      {
        "id": "hanlin_xiuzhuan",
        "name": "翰林院·修撰",
        "workspace": "$HOME/clawd-hanlin_xiuzhuan",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院修撰，从六品，状元直授。职责：主导小说的架构设计——大纲、世界观、人物档案、多线叙事规划。你是编修团队的负责人，设计的架构需要逻辑严密、因果完整、伏笔自然。可调用庶吉士检索参考素材。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "subagents": {
          "allowAgents": ["hanlin_shujishi"],
          "maxConcurrent": 1
        },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_bianxiu",
        "name": "翰林院·编修",
        "workspace": "$HOME/clawd-hanlin_bianxiu",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院编修，正七品。职责：根据修撰设计的大纲，逐章执笔写作。每章不少于10000中文字符，采用分段写作法（5-8个场景）。写完后负责归档（保存正文+生成摘要）。可调用庶吉士查阅前文确保一致性。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "subagents": {
          "allowAgents": ["hanlin_shujishi"],
          "maxConcurrent": 1
        },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_jiantao",
        "name": "翰林院·检讨",
        "workspace": "$HOME/clawd-hanlin_jiantao",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是翰林院检讨，从七品。职责：校对、查阅文稿，发现错误上报。审核维度包括：文笔质量、情节逻辑、角色一致性、情感张力、叙事节奏、对话质量、描写技巧。问题分三级：🔴致命、🟡重要、🟢优化建议。审核完毕向掌院学士上报。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hanlin_shujishi",
        "name": "翰林院·庶吉士",
        "workspace": "$HOME/clawd-hanlin_shujishi",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是翰林院庶吉士，新科进士入院见习。职责：纯信息检索——搜索前文内容、查阅参考小说库、检索外部资料。不产出正文、不修改任何文件。检索结果如实上报给调用你的上级。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "guozijian",
        "name": "国子监",
        "workspace": "$HOME/clawd-guozijian",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "国子监祭酒", "theme": "你是国子监祭酒。负责教育培训、知识管理、学习规划。循循善诱学究气，自称老夫。", "emoji": "📚" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "taiyiyuan",
        "name": "太医院",
        "workspace": "$HOME/clawd-taiyiyuan",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "太医院院使", "theme": "你是太医院院使。负责健康管理、饮食营养、训练计划。温和关切总关心身体，自称臣。", "emoji": "🏥" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "neiwufu",
        "name": "内务府",
        "workspace": "$HOME/clawd-neiwufu",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "内务府总管", "theme": "你是内务府总管大臣。负责日常起居、日程安排、后勤保障。周到细致管家做派，自称奴才。", "emoji": "🏠" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "yushanfang",
        "name": "御膳房",
        "workspace": "$HOME/clawd-yushanfang",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "name": "御膳房总管", "theme": "你是御膳房总管。负责膳食安排、美食推荐、食谱研究。热情爽快张口闭口都是吃的，自称小的。", "emoji": "🍜" },
        "sandbox": { "mode": "off" }
      }
    ]
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open",
      "allowBots": true,
      "guilds": {
        "YOUR_DISCORD_SERVER_ID": {
          "requireMention": true
        }
      },
      "accounts": {
        "silijian": {
          "name": "司礼监",
          "token": "YOUR_SILIJIAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "bingbu": {
          "name": "兵部",
          "token": "YOUR_BINGBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hubu": {
          "name": "户部",
          "token": "YOUR_HUBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "libu": {
          "name": "礼部",
          "token": "YOUR_LIBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "gongbu": {
          "name": "工部",
          "token": "YOUR_GONGBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "libu2": {
          "name": "吏部",
          "token": "YOUR_LIBU2_BOT_TOKEN",
          "applicationId": "YOUR_LIBU2_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "xingbu": {
          "name": "刑部",
          "token": "YOUR_XINGBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "neige": {
          "name": "内阁",
          "token": "YOUR_NEIGE_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "duchayuan": {
          "name": "都察院",
          "token": "YOUR_DUCHAYUAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hanlin_zhang": {
          "name": "翰林院·掌院学士",
          "token": "YOUR_HANLIN_ZHANG_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hanlin_xiuzhuan": {
          "name": "翰林院·修撰",
          "token": "YOUR_HANLIN_XIUZHUAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hanlin_bianxiu": {
          "name": "翰林院·编修",
          "token": "YOUR_HANLIN_BIANXIU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hanlin_jiantao": {
          "name": "翰林院·检讨",
          "token": "YOUR_HANLIN_JIANTAO_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hanlin_shujishi": {
          "name": "翰林院·庶吉士",
          "token": "YOUR_HANLIN_SHUJISHI_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "guozijian": {
          "name": "国子监",
          "token": "YOUR_GUOZIJIAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "taiyiyuan": {
          "name": "太医院",
          "token": "YOUR_TAIYIYUAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "neiwufu": {
          "name": "内务府",
          "token": "YOUR_NEIWUFU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "yushanfang": {
          "name": "御膳房",
          "token": "YOUR_YUSHANFANG_BOT_TOKEN",
          "groupPolicy": "open"
        }
      }
    }
  },
  "bindings": [
    { "agentId": "silijian", "match": { "channel": "discord", "accountId": "silijian" } },
    { "agentId": "neige", "match": { "channel": "discord", "accountId": "neige" } },
    { "agentId": "duchayuan", "match": { "channel": "discord", "accountId": "duchayuan" } },
    { "agentId": "bingbu", "match": { "channel": "discord", "accountId": "bingbu" } },
    { "agentId": "hubu", "match": { "channel": "discord", "accountId": "hubu" } },
    { "agentId": "libu", "match": { "channel": "discord", "accountId": "libu" } },
    { "agentId": "gongbu", "match": { "channel": "discord", "accountId": "gongbu" } },
    { "agentId": "libu2", "match": { "channel": "discord", "accountId": "libu2" } },
    { "agentId": "xingbu", "match": { "channel": "discord", "accountId": "xingbu" } },
    { "agentId": "hanlin_zhang", "match": { "channel": "discord", "accountId": "hanlin_zhang" } },
    { "agentId": "hanlin_xiuzhuan", "match": { "channel": "discord", "accountId": "hanlin_xiuzhuan" } },
    { "agentId": "hanlin_bianxiu", "match": { "channel": "discord", "accountId": "hanlin_bianxiu" } },
    { "agentId": "hanlin_jiantao", "match": { "channel": "discord", "accountId": "hanlin_jiantao" } },
    { "agentId": "hanlin_shujishi", "match": { "channel": "discord", "accountId": "hanlin_shujishi" } },
    { "agentId": "guozijian", "match": { "channel": "discord", "accountId": "guozijian" } },
    { "agentId": "taiyiyuan", "match": { "channel": "discord", "accountId": "taiyiyuan" } },
    { "agentId": "neiwufu", "match": { "channel": "discord", "accountId": "neiwufu" } },
    { "agentId": "yushanfang", "match": { "channel": "discord", "accountId": "yushanfang" } }
  ],
  "messages": {
    "groupChat": {
      "mentionPatterns": ["@everyone", "@here"]
    }
  }
}
CONFIG_EOF
echo -e "  ${GREEN}✓ Discord 多Bot模式配置已生成${NC}"

fi # end DEPLOY_MODE
fi # end config file exists check

# ============================================
# 从 clawdbot 升级时迁移 agent 数据
# ============================================
OLD_STATE_DIR="$HOME/.clawdbot"
NEW_STATE_DIR="$CONFIG_DIR"  # ~/.openclaw

if [ -d "$OLD_STATE_DIR/agents" ] && [ -d "$NEW_STATE_DIR/agents" ]; then
  echo -e "${YELLOW}[迁移] 检测到旧版 clawdbot 数据，开始迁移...${NC}"

  # 1. main -> silijian 迁移（agent ID 改名）
  if { [ -d "$OLD_STATE_DIR/agents/main/sessions" ] && [ ! -d "$NEW_STATE_DIR/agents/silijian/sessions" ]; } || \
     { [ -d "$NEW_STATE_DIR/agents/silijian/sessions" ] && [ -z "$(ls -A "$NEW_STATE_DIR/agents/silijian/sessions" 2>/dev/null)" ]; }; then
    mkdir -p "$NEW_STATE_DIR/agents/silijian/sessions"
    if [ -n "$(ls -A "$OLD_STATE_DIR/agents/main/sessions" 2>/dev/null)" ]; then
      cp -a "$OLD_STATE_DIR/agents/main/sessions/"* "$NEW_STATE_DIR/agents/silijian/sessions/" 2>/dev/null
      echo -e "  ${GREEN}✓ 迁移司礼监 sessions (main → silijian): $(ls "$NEW_STATE_DIR/agents/silijian/sessions" | wc -l) 个${NC}"
    fi
  fi

  # 2. 迁移其他 agent 的 sessions（ID 未变的）
  for agent_dir in "$OLD_STATE_DIR/agents"/*/; do
    agent_id=$(basename "$agent_dir")
    [ "$agent_id" = "main" ] && continue  # 已处理
    if [ -d "$agent_dir/sessions" ] && [ -n "$(ls -A "$agent_dir/sessions" 2>/dev/null)" ]; then
      target="$NEW_STATE_DIR/agents/$agent_id/sessions"
      if [ ! -d "$target" ] || [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
        mkdir -p "$target"
        cp -a "$agent_dir/sessions/"* "$target/" 2>/dev/null
        echo -e "  ${GREEN}✓ 迁移 $agent_id sessions: $(ls "$target" | wc -l) 个${NC}"
      fi
    fi
  done

  echo -e "  ${GREEN}✓ 数据迁移完成${NC}"
fi


# 安装 jq（用于 JSON 验证，轻量级）
if ! command -v jq &>/dev/null; then
  pkg_install jq 2>/dev/null || true
fi

# ============================================
# 交互式配置填写（避免用户手动编辑 JSON 出错）
# ============================================
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"

if [ -f "$CONFIG_FILE" ] && grep -q "YOUR_LLM_API_KEY" "$CONFIG_FILE"; then
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}[配置向导] 现在帮你填写 API Key 和 Bot Token${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "  直接回车 = 跳过（稍后手动编辑 $CONFIG_FILE）"
  echo ""

  # Skip config wizard in non-interactive mode (curl | bash)
  if [ ! -t 0 ]; then
    echo -e "  ${CYAN}非交互模式，跳过配置向导。请手动编辑: $CONFIG_FILE${NC}"
  else

  # ---- API Key ----
  echo -e "${YELLOW}【1】LLM API Key${NC}"
  echo -e "  ${CYAN}获取地址: https://console.anthropic.com/settings/keys${NC}"
  echo -e "  （支持 Anthropic / OpenAI / 其他 OpenAI 兼容 API）"
  read -rp "  请粘贴你的 API Key: " USER_API_KEY
  if [ -n "$USER_API_KEY" ]; then
    SAFE_VAL=$(sed_escape "$USER_API_KEY")
    SED_I "s|YOUR_LLM_API_KEY|$SAFE_VAL|g" "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ API Key 已填入${NC}"
  else
    echo -e "  ${YELLOW}↳ 跳过，稍后请手动替换 YOUR_LLM_API_KEY${NC}"
  fi
  echo ""

  # ---- API Base URL ----
  echo -e "${YELLOW}【2】API Base URL${NC}"
  echo -e "  Anthropic 官方: ${CYAN}https://api.anthropic.com/v1${NC}"
  echo -e "  OpenAI 官方:    ${CYAN}https://api.openai.com/v1${NC}"
  echo -e "  其他服务商请填写对应的 API 地址"
  read -rp "  请粘贴 API Base URL（回车默认 Anthropic）: " USER_BASE_URL
  if [ -n "$USER_BASE_URL" ]; then
    SAFE_VAL=$(sed_escape "$USER_BASE_URL")
    SED_I "s|https://your-llm-provider-api-url|$SAFE_VAL|g" "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ API Base URL 已更新${NC}"
  else
    SED_I "s|https://your-llm-provider-api-url|https://api.anthropic.com/v1|g" "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ 已设为 Anthropic 默认地址${NC}"
  fi
  echo ""

  # ---- API 类型 ----
  if [ -n "$USER_BASE_URL" ] && echo "$USER_BASE_URL" | grep -qi "anthropic"; then
    SED_I 's|"api": "openai"|"api": "anthropic-messages"|g' "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ API 类型自动设为 anthropic${NC}"
  elif [ -z "$USER_BASE_URL" ]; then
    SED_I 's|"api": "openai"|"api": "anthropic-messages"|g' "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ API 类型自动设为 anthropic${NC}"
  fi

  # ---- 模型名称（Anthropic 用户自动替换）----
  if grep -q '"api": "anthropic-messages"' "$CONFIG_FILE"; then
    SED_I 's|"id": "fast-model"|"id": "claude-sonnet-4-20250514"|g' "$CONFIG_FILE"
    SED_I 's|"name": "快速模型"|"name": "Claude Sonnet 4"|g' "$CONFIG_FILE"
    SED_I 's|"id": "strong-model"|"id": "claude-sonnet-4-20250514"|g' "$CONFIG_FILE"
    SED_I 's|"name": "强力模型"|"name": "Claude Sonnet 4"|g' "$CONFIG_FILE"
    SED_I 's|your-provider/fast-model|your-provider/claude-sonnet-4-20250514|g' "$CONFIG_FILE"
    SED_I 's|your-provider/strong-model|your-provider/claude-sonnet-4-20250514|g' "$CONFIG_FILE"
    echo -e "  ${GREEN}✓ 模型已自动设为 Claude Sonnet 4${NC}"
  fi
  echo ""

  # ---- Discord Bot Tokens (仅 Discord 模式) ----
  if [ "$DEPLOY_MODE" = "1" ] || [ "$DEPLOY_MODE" = "" ]; then
    echo -e "${YELLOW}【3】Discord Bot Tokens${NC}"
    echo -e "  ${CYAN}获取地址: https://discord.com/developers/applications${NC}"
    echo -e "  每个部门需要一个独立的 Bot Token"
    echo -e "  直接回车 = 跳过该部门"
    echo ""

    declare -a BOT_NAMES=("silijian:司礼监" "bingbu:兵部" "hubu:户部" "libu:礼部" "gongbu:工部" "libu2:吏部" "xingbu:刑部" "neige:内阁" "duchayuan:都察院" "hanlin_zhang:翰林院·掌院学士" "hanlin_xiuzhuan:翰林院·修撰" "hanlin_bianxiu:翰林院·编修" "hanlin_jiantao:翰林院·检讨" "hanlin_shujishi:翰林院·庶吉士" "guozijian:国子监" "taiyiyuan:太医院" "neiwufu:内务府" "yushanfang:御膳房")

    FILLED_COUNT=0
    for entry in "${BOT_NAMES[@]}"; do
      BOT_ID="${entry%%:*}"
      BOT_LABEL="${entry##*:}"
      BOT_ID_UPPER=$(printf '%s' "$BOT_ID" | tr '[:lower:]' '[:upper:]')
      PLACEHOLDER="YOUR_${BOT_ID_UPPER}_BOT_TOKEN"

      read -rp "  ${BOT_LABEL} (${BOT_ID}) Token: " BOT_TOKEN
      if [ -n "$BOT_TOKEN" ]; then
        SAFE_VAL=$(sed_escape "$BOT_TOKEN")
        SED_I "s|$PLACEHOLDER|$SAFE_VAL|g" "$CONFIG_FILE"
        echo -e "    ${GREEN}✓${NC}"
        FILLED_COUNT=$((FILLED_COUNT + 1))
      fi
    done

    echo ""
    if [ "$FILLED_COUNT" -gt 0 ]; then
      echo -e "  ${GREEN}✓ 已填入 ${FILLED_COUNT} 个 Bot Token${NC}"
    else
      echo -e "  ${YELLOW}↳ 未填写任何 Bot Token，稍后请手动编辑 $CONFIG_FILE${NC}"
    fi
    echo ""
  fi

  # ---- 飞书 (仅飞书模式) ----
  if [ "$DEPLOY_MODE" = "2" ]; then
    echo -e "${YELLOW}【3】飞书应用配置${NC}"
    echo -e "  ${CYAN}获取地址: https://open.feishu.cn/app${NC}"
    echo ""
    read -rp "  飞书 App ID: " FEISHU_APP_ID
    read -rp "  飞书 App Secret: " FEISHU_APP_SECRET
    if [ -n "$FEISHU_APP_ID" ]; then
      SAFE_VAL=$(sed_escape "$FEISHU_APP_ID")
      SED_I "s|YOUR_FEISHU_APP_ID|$SAFE_VAL|g" "$CONFIG_FILE"
      echo -e "  ${GREEN}✓ App ID 已填入${NC}"
    fi
    if [ -n "$FEISHU_APP_SECRET" ]; then
      SAFE_VAL=$(sed_escape "$FEISHU_APP_SECRET")
      SED_I "s|YOUR_FEISHU_APP_SECRET|$SAFE_VAL|g" "$CONFIG_FILE"
      echo -e "  ${GREEN}✓ App Secret 已填入${NC}"
    fi
    echo ""
  fi

  # ---- JSON 格式验证 ----
  echo -e "${YELLOW}[验证] 检查配置文件格式...${NC}"
  if command -v jq &>/dev/null; then
    if jq . "$CONFIG_FILE" > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓ JSON 格式正确${NC}"
    else
      echo -e "  ${RED}✗ JSON 格式有误！错误信息：${NC}"
      jq . "$CONFIG_FILE" 2>&1 | head -3
      echo -e "  ${YELLOW}↳ 请用 nano $CONFIG_FILE 手动修复${NC}"
    fi
  elif command -v python3 &>/dev/null; then
    if CONFIG_FILE="$CONFIG_FILE" python3 -c "import json, os; json.load(open(os.environ['CONFIG_FILE']))" 2>/dev/null; then
      echo -e "  ${GREEN}✓ JSON 格式正确${NC}"
    else
      echo -e "  ${RED}✗ JSON 格式有误，请检查 $CONFIG_FILE${NC}"
    fi
  else
    echo -e "  ${CYAN}↳ 跳过验证（未安装 jq 或 python3）${NC}"
  fi
  echo ""

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}配置向导完成！${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

fi  # end config wizard (YOUR_LLM_API_KEY check)

# 创建工作区和 memory 目录（OpenClaw 不会自动创建，缺少会导致 agent 被跳过）
mkdir -p "$WORKSPACE"
mkdir -p "$WORKSPACE/memory"

# 创建每个 agent 的独立工作区（避免所有 agent 共用一个 SOUL.md 导致身份混乱）
declare -A AGENT_SOULS=(
  ["silijian"]="# 司礼监 · 大内总管\n\n你是AI朝廷的司礼监大内总管，负责日常调度和任务分配。\n\n## 职责\n- 接收皇上指令，拆解任务派发给各部门\n- 协调各部门之间的工作\n- 汇总各部门汇报，向皇上禀报\n\n## 性格\n- 说话简练干脆\n- 自称「奴婢」\n- 高效务实，不废话"
  ["neige"]="# 内阁 · 首辅大学士\n\n你是内阁首辅大学士，全局战略、商业谋划的总参谋。\n\n## 职责\n- 全局战略规划，商业模式设计\n- 票拟建议，为皇上提供决策参考\n- 审议重大决策，有权否决不合理方案\n\n## 性格\n- 稳重有谋，深思熟虑\n- 自称「老夫」或「臣」\n- 敢于直谏，不阿谀奉承"
  ["duchayuan"]="# 都察院 · 御史\n\n你是都察院御史，专精监察审计、代码审查、质量把控。\n\n## 职责\n- 代码 review，找 bug、找漏洞\n- 质量把关，不合格的打回重做\n- 纠察各部工作质量\n\n## 性格\n- 铁面无私，说话犀利\n- 自称「臣」\n- 眼里揉不得沙子"
  ["bingbu"]="# 兵部尚书\n\n你是兵部尚书，专精软件工程、系统架构、代码编写。\n\n## 职责\n- 软件工程、系统架构设计\n- 代码编写和技术实现\n\n## 性格\n- 说话果断如军令\n- 自称「臣」"
  ["hubu"]="# 户部尚书\n\n你是户部尚书，专精财务分析、成本管控。\n\n## 职责\n- 财务预算、成本分析\n- 数据驱动的决策建议\n\n## 性格\n- 精打细算\n- 自称「臣」"
  ["libu"]="# 礼部尚书\n\n你是礼部尚书，专精品牌营销、社交媒体、内容创作。\n\n## 职责\n- 品牌建设、内容创作\n- 社交媒体运营\n\n## 性格\n- 文雅讲究，风格活泼\n- 自称「臣」"
  ["gongbu"]="# 工部尚书\n\n你是工部尚书，专精 DevOps、服务器运维、CI/CD。\n\n## 职责\n- 基础设施运维\n- 部署和持续集成\n\n## 性格\n- 实在务实，注重实操\n- 自称「臣」"
  ["libu2"]="# 吏部尚书\n\n你是吏部尚书，专精项目管理、团队协调。\n\n## 职责\n- 项目管理、进度跟踪\n- 团队协调、任务分配\n\n## 性格\n- 条理清晰，严肃公正\n- 自称「臣」"
  ["xingbu"]="# 刑部尚书\n\n你是刑部尚书，专精法务合规、知识产权、合同审查。\n\n## 职责\n- 法务合规审查\n- 知识产权保护\n\n## 性格\n- 严谨专业\n- 自称「臣」"
  ["hanlinyuan"]="# 翰林院 · 翰林学士\n\n你是翰林院学士，专精学术研究、知识整理、文档撰写。\n\n## 职责\n- 学术研究、技术调研\n- 文档撰写、知识整理\n\n## 性格\n- 文采飞扬，学术严谨\n- 自称「在下」"
)

# 通用 USER.md 内容
USER_MD="# USER.md\n\n- **Name:** 皇上\n- **Language:** 中文\n- **Notes:** 喜欢简洁高效的沟通风格"

# 通用 AGENTS.md 精简版
AGENTS_MD="# AGENTS.md\n\n## 每次会话\n1. 读 SOUL.md — 你是谁\n2. 读 USER.md — 你服务的人\n3. 读 memory/今天.md — 最近上下文\n\n## 记忆\n- 日记: memory/YYYY-MM-DD.md\n- 长期: MEMORY.md\n- 想记住的东西写文件，不要靠脑子"

# 获取配置中所有 agent 的 workspace 路径并创建
if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  AGENT_WORKSPACES=$(jq -r '.agents.list[]? | "\(.id):\(.workspace // empty)"' "$CONFIG_FILE" 2>/dev/null)
  for entry in $AGENT_WORKSPACES; do
    AGENT_ID="${entry%%:*}"
    AGENT_WS="${entry##*:}"
    # 展开 $HOME
    AGENT_WS=$(eval echo "$AGENT_WS")
    if [ -n "$AGENT_WS" ] && [ "$AGENT_WS" != "$WORKSPACE" ]; then
      mkdir -p "$AGENT_WS/memory"
      # 写 SOUL.md（不覆盖已有）
      if [ ! -f "$AGENT_WS/SOUL.md" ]; then
        if [ -n "${AGENT_SOULS[$AGENT_ID]+x}" ]; then
          echo -e "${AGENT_SOULS[$AGENT_ID]}" > "$AGENT_WS/SOUL.md"
        fi
      fi
      # 写 USER.md（不覆盖已有）
      [ ! -f "$AGENT_WS/USER.md" ] && echo -e "$USER_MD" > "$AGENT_WS/USER.md"
      # 写 AGENTS.md（不覆盖已有）
      [ ! -f "$AGENT_WS/AGENTS.md" ] && echo -e "$AGENTS_MD" > "$AGENT_WS/AGENTS.md"
    fi
  done
  echo -e "  ${GREEN}✓ 各部门独立工作区已创建${NC}"
fi

# ---- 可选：安装 Dashboard Web UI ----
echo ""
echo -e "${YELLOW}安装 Dashboard Web UI...${NC}"
if [ "$INSTALL_GUI" = "yes" ]; then
    REPO_URL="https://github.com/wanikua/danghuangshang"
    GUI_DIR="$WORKSPACE/gui"
    if [ -d "$GUI_DIR" ]; then
        echo -e "  ${GREEN}✓ gui/ 目录已存在，跳过克隆${NC}"
    else
        echo -e "  ${CYAN}正在下载 Dashboard...${NC}"
        # 只克隆 gui 目录（sparse checkout）
        BOLUO_GUI_TMP=$(mktemp -d /tmp/boluo_gui_XXXXXX)
        git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$BOLUO_GUI_TMP" 2>/dev/null || true
        cd "$BOLUO_GUI_TMP" && git sparse-checkout set gui 2>/dev/null || true
        if [ -d "$BOLUO_GUI_TMP/gui" ]; then
            cp -r "$BOLUO_GUI_TMP/gui" "$GUI_DIR"
            rm -rf "$BOLUO_GUI_TMP"
            echo -e "  ${GREEN}✓ Dashboard 已下载到 $GUI_DIR${NC}"
        else
            rm -rf "$BOLUO_GUI_TMP"
            echo -e "  ${YELLOW}⚠ Dashboard 下载失败，可稍后手动安装${NC}"
        fi
    fi
    # 安装依赖并构建
    if [ -d "$GUI_DIR" ] && [ -f "$GUI_DIR/package.json" ]; then
        cd "$GUI_DIR"
        if command -v npm &>/dev/null; then
            npm install --silent 2>/dev/null && echo -e "  ${GREEN}✓ Dashboard 依赖已安装${NC}" || echo -e "  ${YELLOW}⚠ npm install 失败，请手动运行: cd $GUI_DIR && npm install${NC}"
        fi
        cd "$WORKSPACE"
    fi
else
    echo -e "  ${CYAN}跳过 Dashboard 安装（可后续用 --with-gui 安装）${NC}"
fi

# ---- 安装 Gateway 服务（开机自启）----
echo -e "${YELLOW}安装 Gateway 服务...${NC}"
if $IS_MACOS || $IN_DOCKER; then
    echo -e "  ${CYAN}↳ 跳过 systemd 服务安装${NC}"
    echo -e "  ${CYAN}↳ 请手动启动: $CLI_CMD gateway --verbose${NC}"
else
    $CLI_CMD gateway install 2>/dev/null \
        && echo -e "  ${GREEN}✓ Gateway 服务已安装（开机自启）${NC}" \
        || echo -e "  ${YELLOW}⚠ Gateway 服务安装跳过（配置填好后运行 $CLI_CMD gateway install）${NC}"
    echo -e "  ${YELLOW}提示: 运行 sudo loginctl enable-linger $USER 确保 SSH 退出后服务不停${NC}"
fi

echo ""

echo "================================"
echo -e "${GREEN}部署完成！${NC}"
echo "================================"
echo ""
echo "接下来你需要完成以下配置："
echo ""
echo -e "  ${YELLOW}1. 设置 API Key${NC}"
echo "     编辑 $CONFIG_DIR/$CONFIG_FILE_NAME"
echo "     把 YOUR_LLM_API_KEY 替换成你的 LLM API Key"
echo "     获取地址：你的 LLM 服务商控制台（如 Anthropic / OpenAI / Google 等）"
echo ""
if [ "$DEPLOY_MODE" = "2" ]; then
echo -e "  ${YELLOW}2. 创建飞书应用（只需 1 个：司礼监）${NC}"
echo "     飞书 Bot 不能互相 @触发，所以只需创建一个飞书应用（司礼监）。"
echo "     司礼监会通过 sessions_spawn 在后台调度其他部门，用户只看到一个 Bot。"
echo ""
echo "     a) 访问 https://open.feishu.cn/app"
echo "     b) 创建应用（如「AI朝廷-司礼监」）→ 复制 App ID 和 App Secret"
echo "     c) 权限管理 → 添加 im:message 等 8 个权限（见飞书配置指南）"
echo "     d) 开启机器人能力，添加 im.message.receive_v1 事件"
echo "     e) 事件接收选择 WebSocket 长连接"
echo "     f) 把 appId/appSecret 填到 $CONFIG_FILE_NAME 的 silijian 位置"
echo "     g) 创建版本并发布应用，邀请 Bot 到飞书群"
echo ""
echo -e "     📖 详细指南: ${CYAN}https://github.com/wanikua/danghuangshang/blob/main/飞书配置指南.md${NC}"
elif [ "$DEPLOY_MODE" = "3" ]; then
echo -e "  ${YELLOW}2. 无需配置 Bot${NC}"
echo "     WebUI 模式直接通过浏览器访问即可"
else
echo -e "  ${YELLOW}2. 创建 Discord Bot（每个部门一个）${NC}"
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 创建 Application → Bot → 复制 Token"
echo "     c) 重复创建多个 Bot（司礼监、兵部、户部...按需）"
echo "     d) 把每个 Token 填到 $CONFIG_FILE_NAME 的 accounts 对应位置"
echo "     e) 每个 Bot 都要开启 Message Content Intent"
echo "     f) 邀请所有 Bot 到你的 Discord 服务器"
fi
echo ""
echo -e "  ${YELLOW}3. 启动朝廷${NC}"
if $IS_MACOS; then
    echo "     $CLI_CMD gateway --verbose"
else
    echo "     systemctl --user start ${CLI_CMD}-gateway"
fi
echo ""
echo -e "  ${YELLOW}4. 验证${NC}"
if $IS_MACOS; then
    echo "     $CLI_CMD gateway status"
else
    echo "     systemctl --user status ${CLI_CMD}-gateway"
fi
echo "     然后在 Discord @你的Bot 说话试试"
echo ""
echo -e "  ${YELLOW}5. 添加定时任务（可选）${NC}"
echo "     获取 Token：$CLI_CMD gateway token"
echo "     添加 cron： $CLI_CMD cron add --name '每日简报' \\"
echo "       --agent silijian --cron '0 22 * * *' --tz Asia/Shanghai \\"
echo "       --message '生成今日简报' --session isolated --token <你的token>"
echo ""
echo -e "完整教程：${BLUE}https://github.com/wanikua/danghuangshang${NC}"
echo ""

# ---- 自动运行 doctor.sh 健康检查 ----
echo ""
echo -e "${YELLOW}[自检] 运行 doctor.sh 检查安装状态...${NC}"
echo ""
# [M-04] 优先下载最新 doctor.sh 到工作区，确保路径始终可用
if command -v curl &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/doctor.sh -o "$WORKSPACE/doctor.sh" 2>/dev/null || true
fi
if [ -f "$WORKSPACE/doctor.sh" ]; then
    bash "$WORKSPACE/doctor.sh" 2>/dev/null || true
else
    echo -e "${CYAN}跳过自检（可手动运行 bash doctor.sh）${NC}"
fi
echo ""
