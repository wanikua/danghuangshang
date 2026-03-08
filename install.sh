#!/bin/bash
# ============================================
# AI 朝廷一键部署脚本
# 支持 Ubuntu/Debian、CentOS/RHEL、macOS、Alpine
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}AI 朝廷一键部署${NC}"
echo "================================"
echo ""

# ============================================
# 检测操作系统和包管理器
# ============================================
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        elif [ -f /etc/alpine-release ]; then
            echo "alpine"
        else
            echo "linux_unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_os)
echo -e "${GREEN}✓ 检测到系统: $OS_TYPE${NC}"

# 设置包管理器命令
case "$OS_TYPE" in
    debian)
        PKG_UPDATE="sudo apt-get update -qq"
        PKG_INSTALL="sudo apt-get install -y -qq"
        PKG_EXISTS="dpkg -l"
        ;;
    redhat)
        PKG_UPDATE="sudo dnf check-update -qq || sudo yum check-update -qq || true"
        PKG_INSTALL="sudo dnf install -y -q || sudo yum install -y -q"
        PKG_EXISTS="rpm -q"
        ;;
    alpine)
        PKG_UPDATE="sudo apk update"
        PKG_INSTALL="sudo apk add --quiet --no-cache"
        PKG_EXISTS="apk info -e"
        ;;
    macos)
        if ! command -v brew &>/dev/null; then
            echo -e "${RED}✗ macOS 系统需要先安装 Homebrew${NC}"
            echo "请运行: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        PKG_UPDATE="brew update > /dev/null 2>&1 || true"
        PKG_INSTALL="brew install --quiet"
        PKG_EXISTS="brew list"
        ;;
    *)
        echo -e "${RED}✗ 不支持的操作系统: $OSTYPE${NC}"
        echo "本脚本仅支持: Ubuntu/Debian、CentOS/RHEL、macOS、Alpine"
        echo "其他系统请手动安装: Node.js 22+、GitHub CLI、Chromium"
        exit 1
        ;;
esac

# ---- 1. 系统更新 ----
echo -e "${YELLOW}[1/8] 系统更新...${NC}"
eval "$PKG_UPDATE"

# ---- 2. 防火墙（仅 Linux） ----
echo -e "${YELLOW}[2/8] 配置防火墙...${NC}"
if [[ "$OS_TYPE" != "macos" ]]; then
    # 云服务商 默认 iptables 有一条 REJECT 规则会阻断非 SSH 流量，只删这条
    sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true
    sudo iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true
    sudo netfilter-persistent save 2>/dev/null || true
    echo -e "  ${GREEN}✓ 防火墙已配置${NC}"
else
    echo -e "  ${YELLOW}⚠ macOS 跳过防火墙配置${NC}"
fi

# ---- 3. Swap（小内存机器需要，仅 Linux） ----
echo -e "${YELLOW}[3/8] 配置 Swap...${NC}"
if [[ "$OS_TYPE" != "macos" ]]; then
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 4G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1G count=4 2>/dev/null
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
        echo -e "  ${GREEN}✓ 4GB Swap 已创建${NC}"
    else
        echo -e "  ${GREEN}✓ Swap 已存在，跳过${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ macOS 跳过 Swap 配置${NC}"
fi

# ---- 4. Node.js ----
echo -e "${YELLOW}[4/8] 安装 Node.js 22...${NC}"
if command -v node &>/dev/null && [[ "$(node -v)" == v22* ]]; then
    echo -e "  ${GREEN}✓ Node.js $(node -v) 已安装${NC}"
else
    case "$OS_TYPE" in
        debian)
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - > /dev/null 2>&1
            sudo apt-get install -y nodejs -qq
            ;;
        redhat)
            curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - > /dev/null 2>&1
            sudo dnf install -y nodejs || sudo yum install -y nodejs
            ;;
        alpine)
            sudo apk add --no-cache nodejs npm
            ;;
        macos)
            brew install node@22
            ;;
    esac
    echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
fi

# ---- 5. gh CLI（GitHub 自动化） ----
echo -e "${YELLOW}[5/8] 安装 GitHub CLI...${NC}"
if command -v gh &>/dev/null; then
    echo -e "  ${GREEN}✓ gh $(gh --version | head -1 | awk '{print $3}') 已安装${NC}"
else
    case "$OS_TYPE" in
        debian)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update -qq && sudo apt-get install gh -y -qq
            ;;
        redhat)
            sudo dnf install 'dnf-command(config-manager)' || sudo yum install 'yum-plugin-config-manager'
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo || sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install gh || sudo yum install gh
            ;;
        alpine)
            sudo apk add --no-cache gh
            ;;
        macos)
            brew install gh
            ;;
    esac
    echo -e "  ${GREEN}✓ gh CLI 安装完成${NC}"
fi

# ---- 6. Chromium（浏览器，Agent 搜索/截图用） ----
echo -e "${YELLOW}[6/8] 安装 Chromium 浏览器...${NC}"
if command -v chromium-browser &>/dev/null || command -v chromium &>/dev/null || snap list chromium &>/dev/null 2>&1 || [ -d "/Applications/Chromium.app" ]; then
    echo -e "  ${GREEN}✓ Chromium 已安装，跳过${NC}"
else
    case "$OS_TYPE" in
        debian)
            sudo snap install chromium 2>/dev/null || sudo apt-get install -y chromium-browser -qq
            ;;
        redhat)
            sudo dnf install chromium || sudo yum install chromium
            ;;
        alpine)
            sudo apk add --no-cache chromium
            ;;
        macos)
            brew install --cask chromium
            ;;
    esac
    echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
fi

# 设置 Puppeteer 浏览器路径（Clawdbot 的浏览器 skill 需要）
if ! grep -q PUPPETEER_EXECUTABLE_PATH ~/.bashrc 2>/dev/null; then
    case "$OS_TYPE" in
        macos)
            CHROME_BIN="/Applications/Chromium.app/Contents/MacOS/Chromium"
            ;;
        debian|redhat|alpine)
            CHROME_BIN="/snap/chromium/current/usr/lib/chromium-browser/chrome"
            if [ ! -f "$CHROME_BIN" ]; then
                CHROME_BIN=$(which chromium-browser 2>/dev/null || which chromium 2>/dev/null || echo "/snap/chromium/current/usr/lib/chromium-browser/chrome")
            fi
            ;;
    esac
    echo "export PUPPETEER_EXECUTABLE_PATH=\"$CHROME_BIN\"" >> ~/.bashrc
    echo -e "  ${GREEN}✓ 浏览器路径已配置 ($CHROME_BIN)${NC}"
fi

# ---- 7. Clawdbot ----
echo -e "${YELLOW}[7/8] 安装 Clawdbot...${NC}"
if command -v clawdbot &>/dev/null; then
    CURRENT_VER=$(clawdbot --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓ Clawdbot 已安装 ($CURRENT_VER)，更新中...${NC}"
fi
sudo npm install -g clawdbot --loglevel=error
echo -e "  ${GREEN}✓ Clawdbot $(clawdbot --version 2>/dev/null) 安装完成${NC}"

# ---- 8. 初始化工作区 ----
echo -e "${YELLOW}[8/8] 初始化朝廷工作区...${NC}"
WORKSPACE="$HOME/clawd"
CONFIG_DIR="$HOME/.clawdbot"
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
SOUL_EOF
echo -e "  ${GREEN}✓ SOUL.md 已创建${NC}"
fi

# IDENTITY.md
if [ ! -f IDENTITY.md ]; then
cat > IDENTITY.md << 'ID_EOF'
# IDENTITY.md - 朝廷架构

## 模型分层
| 层级 | 模型 | 说明 |
|---||---|
| 调度层 | 快速模型 | 日常对话，快速响应 |
| 执行层（重） | 强力模型 | 编码、深度分析 |
| 执行层（轻） | 经济模型（可选） | 轻量任务，省钱 |

## 六部
- 兵部：软件工程、系统架构
- 户部：财务预算、电商运营
- 礼部：品牌营销、内容创作
- 工部：DevOps、服务器运维
- 吏部：项目管理、创业孵化
- 刑部：法务合规、知识产权
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

# clawdbot.json 模板 → 写到 ~/.clawdbot/
if [ ! -f "$CONFIG_DIR/clawdbot.json" ]; then
cat > "$CONFIG_DIR/clawdbot.json" << CONFIG_EOF
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "https://your-llm-provider-api-url",
        "apiKey": "YOUR_LLM_API_KEY",
        "api": "your-api-format",
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
        "id": "main",
        "name": "司礼监",
        "model": { "primary": "your-provider/fast-model" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。回答用中文，直接给方案。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "hubu",
        "name": "户部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。回答用中文，数据驱动。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "libu",
        "name": "礼部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。回答用中文，风格活泼。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "gongbu",
        "name": "工部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维、CI/CD、基础设施。回答用中文，注重实操。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "libu2",
        "name": "吏部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化、团队协调。回答用中文，条理清晰。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "xingbu",
        "name": "刑部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权、合同审查。回答用中文，严谨专业。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      }
    ]
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open",
      "allowBots": true,
      "accounts": {
        "main": {
          "name": "司礼监",
          "token": "YOUR_MAIN_BOT_TOKEN",
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
          "groupPolicy": "open"
        },
        "xingbu": {
          "name": "刑部",
          "token": "YOUR_XINGBU_BOT_TOKEN",
          "groupPolicy": "open"
        }
      }
    }
  },
  "bindings": [
    { "agentId": "main", "match": { "channel": "discord", "accountId": "main" } },
    { "agentId": "bingbu", "match": { "channel": "discord", "accountId": "bingbu" } },
    { "agentId": "hubu", "match": { "channel": "discord", "accountId": "hubu" } },
    { "agentId": "libu", "match": { "channel": "discord", "accountId": "libu" } },
    { "agentId": "gongbu", "match": { "channel": "discord", "accountId": "gongbu" } },
    { "agentId": "libu2", "match": { "channel": "discord", "accountId": "libu2" } },
    { "agentId": "xingbu", "match": { "channel": "discord", "accountId": "xingbu" } }
  ]
}
CONFIG_EOF
echo -e "  ${GREEN}✓ clawdbot.json 模板已创建 ($CONFIG_DIR/clawdbot.json)${NC}"
fi

# 创建 memory 目录
mkdir -p memory

# ---- 安装 Gateway 服务（开机自启，仅 Linux） ----
echo -e "${YELLOW}安装 Gateway 服务...${NC}"
if [[ "$OS_TYPE" != "macos" ]]; then
    clawdbot gateway install 2>/dev/null \
        && echo -e "  ${GREEN}✓ Gateway 服务已安装（开机自启）${NC}" \
        || echo -e "  ${YELLOW}⚠ Gateway 服务安装跳过（配置填好后运行 clawdbot gateway install）${NC}"
else
    echo -e "  ${YELLOW}⚠ macOS 跳过 Gateway 服务安装${NC}"
fi

echo ""
echo "================================"
echo -e "${GREEN}部署完成！${NC}"
echo "================================"
echo ""
echo "接下来你需要完成以下配置："
echo ""
echo -e "  ${YELLOW}1. 设置 API Key${NC}"
echo "     编辑 ~/.clawdbot/clawdbot.json"
echo "     把 YOUR_LLM_API_KEY 替换成你的 LLM API Key"
echo "     获取地址：https://你的LLM服务商控制台"
echo ""
echo -e "  ${YELLOW}2. 创建 Discord Bot（每个部门一个）${NC}"
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 创建 Application → Bot → 复制 Token"
echo "     c) 重复创建多个 Bot（司礼监、兵部、户部...按需）"
echo "     d) 把每个 Token 填到 clawdbot.json 的 accounts 对应位置"
echo "     e) 每个 Bot 都要开启 Message Content Intent"
echo "     f) 邀请所有 Bot 到你的 Discord 服务器"
echo ""
echo -e "  ${YELLOW}3. 启动朝廷${NC}"
if [[ "$OS_TYPE" != "macos" ]]; then
    echo "     systemctl --user start clawdbot-gateway"
else
    echo "     clawdbot gateway start"
fi
echo ""
echo -e "  ${YELLOW}4. 验证${NC}"
if [[ "$OS_TYPE" != "macos" ]]; then
    echo "     systemctl --user status clawdbot-gateway"
else
    echo "     clawdbot gateway status"
fi
echo "     然后在 Discord @你的Bot 说话试试"
echo ""
echo -e "  ${YELLOW}5. 添加定时任务（可选）${NC}"
echo "     获取 Token：clawdbot gateway token"
echo "     添加 cron： clawdbot cron add --name '每日简报' \\"
echo "       --agent main --cron '0 22 * * *' --tz Asia/Shanghai \\"
echo "       --message '生成今日简报' --session isolated --token <你的token>"
echo ""
echo -e "完整教程：${BLUE}https://github.com/wanikua/boluobobo-ai-court-tutorial${NC}"
echo ""
