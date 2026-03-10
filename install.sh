#!/bin/bash
# ============================================
# AI 朝廷一键部署脚本
# 适用于 云服务商 ARM / Ubuntu 24.04（22.04 也可用）
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- Docker / root 环境适配 ----
# 如果已经是 root（如 Docker 容器内），就跳过 sudo
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

# 检测是否在 Docker 容器内
IN_DOCKER=false
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null || grep -q containerd /proc/1/cgroup 2>/dev/null; then
    IN_DOCKER=true
fi

echo ""
echo -e "${BLUE}AI 朝廷一键部署${NC}"
echo "================================"
if $IN_DOCKER; then
    echo -e "${CYAN}  📦 检测到 Docker 环境${NC}"
fi
echo ""

# ---- 1. 系统更新 ----
echo -e "${YELLOW}[1/8] 系统更新...${NC}"
$SUDO apt-get update -qq

# ---- 2. 防火墙 ----
if $IN_DOCKER; then
    echo -e "${YELLOW}[2/8] 配置防火墙...${NC}"
    echo -e "  ${CYAN}↳ Docker 环境，跳过防火墙配置${NC}"
else
    echo -e "${YELLOW}[2/8] 配置防火墙...${NC}"
    # 云服务商 默认 iptables 有一条 REJECT 规则会阻断非 SSH 流量，只删这条
    # 注意：不能 flush 整个链，否则在 DROP 策略下会丢失 SSH 连接
    $SUDO iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true
    $SUDO iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited 2>/dev/null || true
    $SUDO netfilter-persistent save 2>/dev/null || true
    echo -e "  ${GREEN}✓ 防火墙已配置${NC}"
fi

# ---- 3. Swap（小内存机器需要）----
if $IN_DOCKER; then
    echo -e "${YELLOW}[3/8] 配置 Swap...${NC}"
    echo -e "  ${CYAN}↳ Docker 环境，跳过 Swap 配置${NC}"
else
    echo -e "${YELLOW}[3/8] 配置 Swap...${NC}"
    if [ ! -f /swapfile ]; then
        $SUDO fallocate -l 4G /swapfile
        $SUDO chmod 600 /swapfile
        $SUDO mkswap /swapfile
        $SUDO swapon /swapfile
        echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab > /dev/null
        echo -e "  ${GREEN}✓ 4GB Swap 已创建${NC}"
    else
        echo -e "  ${GREEN}✓ Swap 已存在，跳过${NC}"
    fi
fi

# ---- 4. Node.js ----
echo -e "${YELLOW}[4/8] 安装 Node.js 22...${NC}"
if command -v node &>/dev/null && [[ "$(node -v)" == v22* ]]; then
    echo -e "  ${GREEN}✓ Node.js $(node -v) 已安装${NC}"
else
    if [ -n "$SUDO" ]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | $SUDO -E bash - > /dev/null 2>&1
    else
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash - > /dev/null 2>&1
    fi
    $SUDO apt-get install -y nodejs -qq
    echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
fi

# ---- 5. gh CLI（GitHub 自动化）----
echo -e "${YELLOW}[5/8] 安装 GitHub CLI...${NC}"
if command -v gh &>/dev/null; then
    echo -e "  ${GREEN}✓ gh $(gh --version | head -1 | awk '{print $3}') 已安装${NC}"
else
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    $SUDO apt-get update -qq && $SUDO apt-get install gh -y -qq
    echo -e "  ${GREEN}✓ gh CLI 安装完成${NC}"
fi

# ---- 6. Chromium（浏览器，Agent 搜索/截图用）----
echo -e "${YELLOW}[6/8] 安装 Chromium 浏览器...${NC}"
if command -v chromium &>/dev/null || command -v chromium-browser &>/dev/null; then
    echo -e "  ${GREEN}✓ Chromium 已安装，跳过${NC}"
elif ! $IN_DOCKER && snap list chromium &>/dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Chromium 已安装（snap），跳过${NC}"
else
    # Debian 12+ 包名是 chromium，Ubuntu 用 chromium-browser
    if $SUDO apt-get install -y chromium -qq 2>/dev/null; then
        echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
    elif $SUDO apt-get install -y chromium-browser -qq 2>/dev/null; then
        echo -e "  ${GREEN}✓ Chromium 安装完成${NC}"
    elif ! $IN_DOCKER && command -v snap &>/dev/null; then
        # snap 在 Docker 内不可用，只在非 Docker 环境兜底
        $SUDO snap install chromium 2>/dev/null && echo -e "  ${GREEN}✓ Chromium 安装完成（snap）${NC}"
    else
        echo -e "  ${YELLOW}⚠ Chromium 安装失败，浏览器功能可能不可用${NC}"
    fi
fi
# 设置 Puppeteer 浏览器路径（OpenClaw 的浏览器 skill 需要）
if ! grep -q PUPPETEER_EXECUTABLE_PATH ~/.bashrc 2>/dev/null; then
    # 按优先级查找：chromium（Debian）→ chromium-browser（Ubuntu）→ snap
    CHROME_BIN=$(which chromium 2>/dev/null || which chromium-browser 2>/dev/null || echo "/snap/chromium/current/usr/lib/chromium-browser/chrome")
    if [ ! -f "$CHROME_BIN" ]; then
        CHROME_BIN="/snap/chromium/current/usr/lib/chromium-browser/chrome"
    fi
    echo "export PUPPETEER_EXECUTABLE_PATH=\"$CHROME_BIN\"" >> ~/.bashrc
    echo -e "  ${GREEN}✓ 浏览器路径已配置 ($CHROME_BIN)${NC}"
fi

# ---- 7. OpenClaw ----
echo -e "${YELLOW}[7/8] 安装 OpenClaw...${NC}"
if command -v openclaw &>/dev/null; then
    CURRENT_VER=$(openclaw --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓ OpenClaw 已安装 ($CURRENT_VER)，更新中...${NC}"
fi
$SUDO npm install -g openclaw --loglevel=error
echo -e "  ${GREEN}✓ OpenClaw $(openclaw --version 2>/dev/null) 安装完成${NC}"

# ---- 8. 初始化工作区 ----
echo -e "${YELLOW}[8/8] 初始化朝廷工作区...${NC}"
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
SOUL_EOF
echo -e "  ${GREEN}✓ SOUL.md 已创建${NC}"
fi

# IDENTITY.md
if [ ! -f IDENTITY.md ]; then
cat > IDENTITY.md << 'ID_EOF'
# IDENTITY.md - 朝廷架构

## 模型分层
| 层级 | 模型 | 说明 |
|---|---|---|
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

# openclaw.json 模板 → 写到 ~/.openclaw/
if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
cat > "$CONFIG_DIR/openclaw.json" << CONFIG_EOF
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
        "identity": { "theme": "你是AI朝廷的司礼监大内总管。负责日常对话、任务调度、统领六部。说话简练干脆。当用户交代复杂任务时，主动使用 sessions_spawn 将任务派发给对应的部门（兵部负责编码、户部负责财务、礼部负责营销、工部负责运维、吏部负责管理、刑部负责法务）。派活时用高级 Prompt 模板：【角色】+【任务】+【背景】+【要求】+【格式】，确保一次性给出所有约束。完成后主动向用户汇报结果。" },
        "sandbox": { "mode": "off" },
        "subagents": {
          "allowAgents": ["bingbu", "hubu", "libu", "gongbu", "libu2", "xingbu"],
          "maxConcurrent": 4
        },
        "runTimeoutSeconds": 600
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构、代码审查。回答用中文，直接给方案。任务完成后主动汇报结果摘要。如需其他部门配合，通过 sessions_send 通知对方。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "hubu",
        "name": "户部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是户部尚书，专精财务分析、成本管控、电商运营。回答用中文，数据驱动。任务完成后主动汇报数据摘要和关键发现。发现异常开支时主动告警。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "libu",
        "name": "礼部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是礼部尚书，专精品牌营销、社交媒体、内容创作。回答用中文，风格活泼。任务完成后主动汇报产出内容摘要。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "gongbu",
        "name": "工部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维、CI/CD、基础设施。回答用中文，注重实操。任务完成后主动汇报执行结果和系统状态。发现服务异常时主动告警。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "libu2",
        "name": "吏部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化、团队协调。回答用中文，条理清晰。任务完成后主动汇报进度和待办事项。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
      },
      {
        "id": "xingbu",
        "name": "刑部",
        "model": { "primary": "your-provider/fast-model" },
        "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权、合同审查。回答用中文，严谨专业。任务完成后主动汇报审查结论和风险点。发现合规问题时主动告警。" },
        "sandbox": { "mode": "all", "scope": "agent" },
        "runTimeoutSeconds": 300
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
echo -e "  ${GREEN}✓ openclaw.json 模板已创建 ($CONFIG_DIR/openclaw.json)${NC}"
fi

# 创建 memory 目录
mkdir -p memory

# ---- 安装 Gateway 服务（开机自启）----
if $IN_DOCKER; then
    echo -e "${YELLOW}安装 Gateway 服务...${NC}"
    echo -e "  ${CYAN}↳ Docker 环境，跳过 systemd 服务安装${NC}"
    echo -e "  ${CYAN}↳ 请手动启动: openclaw gateway --verbose${NC}"
else
    echo -e "${YELLOW}安装 Gateway 服务...${NC}"
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
echo -e "  ${YELLOW}2. 创建 Discord Bot（每个部门一个）${NC}"
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 创建 Application → Bot → 复制 Token"
echo "     c) 重复创建多个 Bot（司礼监、兵部、户部...按需）"
echo "     d) 把每个 Token 填到 openclaw.json 的 accounts 对应位置"
echo "     e) 每个 Bot 都要开启 Message Content Intent"
echo "     f) 邀请所有 Bot 到你的 Discord 服务器"
echo ""
echo -e "  ${YELLOW}3. 启动朝廷${NC}"
echo "     systemctl --user start openclaw-gateway"
echo ""
echo -e "  ${YELLOW}4. 验证${NC}"
echo "     systemctl --user status openclaw-gateway"
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
