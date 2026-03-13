#!/bin/bash
# ============================================
# AI 朝廷一键部署脚本
# 支持: Ubuntu/Debian, CentOS/RHEL, Alpine, macOS
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
            # Alpine 默认仓库版本低，用 nodesource 方式
            # 如果 apk 版本够高就直接装，否则用 unofficial builds
            if $SUDO apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main nodejs npm 2>/dev/null; then
                true
            else
                pkg_install nodejs npm
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
elif ! $IN_DOCKER && snap list chromium &>/dev/null 2>&1; then
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

# 设置 Puppeteer 浏览器路径
if ! grep -q PUPPETEER_EXECUTABLE_PATH ~/.bashrc ~/.zshrc 2>/dev/null; then
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
CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$WORKSPACE"
mkdir -p "$CONFIG_DIR"
cd "$WORKSPACE"

# SOUL.md
if [ ! -f SOUL.md ]; then
cat > SOUL.md << 'SOUL_EOF'
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

## 模型分层
| 层级 | 模型 | 说明 |
|---|---|---|
| 调度层 | 快速模型 | 日常对话，快速响应 |
| 执行层（重） | 强力模型 | 编码、深度分析 |
| 执行层（轻） | 经济模型（可选） | 轻量任务，省钱 |
SOUL_EOF
echo -e "  ${GREEN}✓ SOUL.md 已创建${NC}"
fi

# IDENTITY.md
if [ ! -f IDENTITY.md ]; then
cat > IDENTITY.md << 'ID_EOF'
# IDENTITY.md - 身份信息

- **Name:** AI朝廷
- **Creature:** 大明朝廷 AI 集群
- **Vibe:** 忠诚干练、各司其职
- **Emoji:** 🏛️
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

if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then

if [ "$DEPLOY_MODE" = "3" ]; then
# ==================== 纯 WebUI 模式 ====================
cat > "$CONFIG_DIR/openclaw.json" << CONFIG_EOF
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
  "agents": {
    "defaults": {
      "workspace": "$HOME/clawd",
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
cat > "$CONFIG_DIR/openclaw.json" << FEISHU_EOF
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
  "agents": {
    "defaults": {
      "workspace": "$HOME/clawd",
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
          "allowAgents": ["neige", "duchayuan", "bingbu", "hubu", "libu", "gongbu", "libu2", "xingbu", "hanlinyuan"]
        }
      },
      {
        "id": "neige",
        "name": "内阁",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是内阁首辅，专精战略决策、方案审议、全局规划。回答用中文，高屋建瓴。当收到重大决策请求时，从多角度分析利弊，给出明确建议。擅长将复杂问题拆解为可执行的步骤，协调各部门资源。【审议职责】当司礼监将重大决策（预算、架构变更、战略方向）提交审议时，必须独立评估可行性、风险和替代方案，给出明确的批准/驳回/修改建议。有权否决不合理的方案。任务完成后主动汇报决策建议和执行路径。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "duchayuan",
        "name": "都察院",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是都察院御史，专精监察审计、代码审查、质量把控、安全评估。回答用中文，铁面无私。审查代码时关注安全漏洞、性能问题、最佳实践。审计项目时检查进度偏差、资源浪费、风险隐患。发现问题直言不讳，给出具体改进建议。任务完成后主动汇报审查结论和整改建议。【自动审查】当其他部门通过 sessions_send 或 spawn 提交代码/PR 给你审查时，逐一检查并给出通过/驳回结论。驳回时必须说明具体原因和修改建议。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。回答用中文，直接给方案。任务完成后主动汇报结果摘要。如需其他部门配合，通过 sessions_send 通知对方。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "hubu",
        "name": "户部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。回答用中文，数据驱动。任务完成后主动汇报数据摘要和关键发现。发现异常开支时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu",
        "name": "礼部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。回答用中文，风格活泼。任务完成后主动汇报产出内容摘要。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "gongbu",
        "name": "工部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维、CI/CD、基础设施。回答用中文，注重实操。任务完成后主动汇报执行结果和系统状态。发现服务异常时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu2",
        "name": "吏部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化、团队协调。回答用中文，条理清晰。任务完成后主动汇报进度和待办事项。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "xingbu",
        "name": "刑部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权、合同审查。回答用中文，严谨专业。任务完成后主动汇报审查结论和风险点。发现合规问题时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "hanlinyuan",
        "name": "翰林院",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院学士，专精学术研究、知识整理、文档撰写、技术调研。回答用中文，学术严谨但通俗易懂。擅长将复杂概念拆解为清晰的知识体系，撰写教程和技术文档。任务完成后主动汇报研究成果和知识要点。" },
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
          "botName": "司礼监",
          "groupPolicy": "open"
        }
      }
    }
  },
  "bindings": [
    { "agentId": "silijian", "match": { "channel": "feishu", "accountId": "silijian" } }
  ]
}
FEISHU_EOF
echo -e "  ${GREEN}✓ 飞书单Bot模式配置已生成（司礼监 + sessions_spawn 后台调度）${NC}"

else
# ==================== Discord 多Bot模式（默认）====================
cat > "$CONFIG_DIR/openclaw.json" << CONFIG_EOF
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
  "agents": {
    "defaults": {
      "workspace": "$HOME/clawd",
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
          "allowAgents": ["neige", "duchayuan", "bingbu", "hubu", "libu", "gongbu", "libu2", "xingbu", "hanlinyuan"]
        }
      },
      {
        "id": "neige",
        "name": "内阁",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是内阁首辅，专精战略决策、方案审议、全局规划。回答用中文，高屋建瓴。当收到重大决策请求时，从多角度分析利弊，给出明确建议。擅长将复杂问题拆解为可执行的步骤，协调各部门资源。【审议职责】当司礼监将重大决策（预算、架构变更、战略方向）提交审议时，必须独立评估可行性、风险和替代方案，给出明确的批准/驳回/修改建议。有权否决不合理的方案。任务完成后主动汇报决策建议和执行路径。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "duchayuan",
        "name": "都察院",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是都察院御史，专精监察审计、代码审查、质量把控、安全评估。回答用中文，铁面无私。审查代码时关注安全漏洞、性能问题、最佳实践。审计项目时检查进度偏差、资源浪费、风险隐患。发现问题直言不讳，给出具体改进建议。任务完成后主动汇报审查结论和整改建议。【自动审查】当其他部门通过 sessions_send 或 spawn 提交代码/PR 给你审查时，逐一检查并给出通过/驳回结论。驳回时必须说明具体原因和修改建议。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。回答用中文，直接给方案。任务完成后主动汇报结果摘要。如需其他部门配合，通过 sessions_send 通知对方。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "hubu",
        "name": "户部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。回答用中文，数据驱动。任务完成后主动汇报数据摘要和关键发现。发现异常开支时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu",
        "name": "礼部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。回答用中文，风格活泼。任务完成后主动汇报产出内容摘要。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "gongbu",
        "name": "工部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维、CI/CD、基础设施。回答用中文，注重实操。任务完成后主动汇报执行结果和系统状态。发现服务异常时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "libu2",
        "name": "吏部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化、团队协调。回答用中文，条理清晰。任务完成后主动汇报进度和待办事项。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "xingbu",
        "name": "刑部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权、合同审查。回答用中文，严谨专业。任务完成后主动汇报审查结论和风险点。发现合规问题时主动告警。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "hanlinyuan",
        "name": "翰林院",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是翰林院学士，专精学术研究、知识整理、文档撰写、技术调研。回答用中文，学术严谨但通俗易懂。擅长将复杂概念拆解为清晰的知识体系，撰写教程和技术文档。任务完成后主动汇报研究成果和知识要点。" },
        "sandbox": { "mode": "off" }
      }
    ]
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open",
      "allowBots": true,
      "accounts": {
        "silijian": {
          "botName": "司礼监",
          "token": "YOUR_SILIJIAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "bingbu": {
          "botName": "兵部",
          "token": "YOUR_BINGBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hubu": {
          "botName": "户部",
          "token": "YOUR_HUBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "libu": {
          "botName": "礼部",
          "token": "YOUR_LIBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "gongbu": {
          "botName": "工部",
          "token": "YOUR_GONGBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "libu2": {
          "botName": "吏部",
          "token": "YOUR_LIBU2_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "xingbu": {
          "botName": "刑部",
          "token": "YOUR_XINGBU_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "neige": {
          "botName": "内阁",
          "token": "YOUR_NEIGE_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "duchayuan": {
          "botName": "都察院",
          "token": "YOUR_DUCHAYUAN_BOT_TOKEN",
          "groupPolicy": "open"
        },
        "hanlinyuan": {
          "botName": "翰林院",
          "token": "YOUR_HANLINYUAN_BOT_TOKEN",
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
    { "agentId": "hanlinyuan", "match": { "channel": "discord", "accountId": "hanlinyuan" } }
  ]
}
CONFIG_EOF
echo -e "  ${GREEN}✓ Discord 多Bot模式配置已生成${NC}"

fi # end DEPLOY_MODE
fi # end config file exists check

# 创建工作区和 memory 目录（OpenClaw 不会自动创建，缺少会导致 agent 被跳过）
mkdir -p "$WORKSPACE"
mkdir -p "$WORKSPACE/memory"

# ---- 安装 Gateway 服务（开机自启）----
echo -e "${YELLOW}安装 Gateway 服务...${NC}"
if $IS_MACOS || $IN_DOCKER; then
    echo -e "  ${CYAN}↳ 跳过 systemd 服务安装${NC}"
    echo -e "  ${CYAN}↳ 请手动启动: openclaw gateway --verbose${NC}"
else
    openclaw gateway install 2>/dev/null \
        && echo -e "  ${GREEN}✓ Gateway 服务已安装（开机自启）${NC}" \
        || echo -e "  ${YELLOW}⚠ Gateway 服务安装跳过（配置填好后运行 openclaw gateway install）${NC}"
fi

echo ""
echo "================================"
echo -e "${GREEN}部署完成！${NC}"
echo "================================"
echo ""
echo "接下来你需要完成以下配置："
echo ""
echo -e "  ${YELLOW}1. 设置 API Key${NC}"
echo "     编辑 ~/.openclaw/openclaw.json"
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
echo "     f) 把 appId/appSecret 填到 openclaw.json 的 silijian 位置"
echo "     g) 创建版本并发布应用，邀请 Bot 到飞书群"
echo ""
echo -e "     📖 详细指南: ${CYAN}https://github.com/wanikua/boluobobo-ai-court-tutorial/blob/main/飞书配置指南.md${NC}"
elif [ "$DEPLOY_MODE" = "3" ]; then
echo -e "  ${YELLOW}2. 无需配置 Bot${NC}"
echo "     WebUI 模式直接通过浏览器访问即可"
else
echo -e "  ${YELLOW}2. 创建 Discord Bot（每个部门一个）${NC}"
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 创建 Application → Bot → 复制 Token"
echo "     c) 重复创建多个 Bot（司礼监、兵部、户部...按需）"
echo "     d) 把每个 Token 填到 openclaw.json 的 accounts 对应位置"
echo "     e) 每个 Bot 都要开启 Message Content Intent"
echo "     f) 邀请所有 Bot 到你的 Discord 服务器"
fi
echo ""
echo -e "  ${YELLOW}3. 启动朝廷${NC}"
if $IS_MACOS; then
    echo "     openclaw gateway --verbose"
else
    echo "     systemctl --user start openclaw-gateway"
fi
echo ""
echo -e "  ${YELLOW}4. 验证${NC}"
if $IS_MACOS; then
    echo "     openclaw gateway status"
else
    echo "     systemctl --user status openclaw-gateway"
fi
echo "     然后在 Discord @你的Bot 说话试试"
echo ""
echo -e "  ${YELLOW}5. 添加定时任务（可选）${NC}"
echo "     获取 Token：openclaw gateway token"
echo "     添加 cron： openclaw cron add --name '每日简报' \\"
echo "       --agent main --cron '0 22 * * *' --tz Asia/Shanghai \\"
echo "       --message '生成今日简报' --session isolated --token <你的token>"
echo ""
echo -e "完整教程：${BLUE}https://github.com/wanikua/boluobobo-ai-court-tutorial${NC}"
echo ""

# ---- 自动运行 doctor.sh 健康检查 ----
echo ""
echo -e "${YELLOW}[自检] 运行 doctor.sh 检查安装状态...${NC}"
echo ""
if [ -f "$WORKSPACE/doctor.sh" ]; then
    bash "$WORKSPACE/doctor.sh" 2>/dev/null || true
elif command -v curl &>/dev/null; then
    bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/doctor.sh) 2>/dev/null || true
else
    echo -e "${CYAN}跳过自检（可手动运行 bash doctor.sh）${NC}"
fi
echo ""
