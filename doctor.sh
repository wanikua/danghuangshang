#!/bin/bash
# ============================================
# AI 朝廷配置诊断脚本（doctor.sh）
# 检查常见配置问题，帮助排查故障
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; ((PASS++)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; ((WARN++)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL++)); }
info() { echo -e "  ${CYAN}ℹ${NC} $1"; }

echo ""
echo -e "${BLUE}🏥 AI 朝廷配置诊断${NC}"
echo "================================"
echo ""

# ---- 检测 CLI ----
echo -e "${YELLOW}[1/8] 检查安装...${NC}"

if command -v openclaw &>/dev/null; then
    CLI_CMD="openclaw"
    CLI_VER=$(openclaw --version 2>/dev/null || echo "unknown")
    pass "OpenClaw 已安装 ($CLI_VER)"
elif command -v clawdbot &>/dev/null; then
    CLI_CMD="clawdbot"
    CLI_VER=$(clawdbot --version 2>/dev/null || echo "unknown")
    pass "Clawdbot 已安装 ($CLI_VER)"
else
    fail "未检测到 OpenClaw 或 Clawdbot — 请先安装: npm install -g openclaw@latest"
    CLI_CMD=""
fi

NODE_VER=$(node -v 2>/dev/null || echo "none")
if [[ "$NODE_VER" == v22* ]] || [[ "$NODE_VER" == v23* ]] || [[ "$NODE_VER" == v24* ]]; then
    pass "Node.js $NODE_VER"
elif [[ "$NODE_VER" == "none" ]]; then
    fail "Node.js 未安装"
else
    warn "Node.js $NODE_VER — 推荐 v22+"
fi

# ---- 检测配置文件 ----
echo ""
echo -e "${YELLOW}[2/8] 检查配置文件...${NC}"

# 查找配置文件
CONFIG_FILE=""
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
    CONFIG_FILE="$HOME/.openclaw/openclaw.json"
elif [ -f "$HOME/.clawdbot/clawdbot.json" ]; then
    CONFIG_FILE="$HOME/.clawdbot/clawdbot.json"
fi

if [ -z "$CONFIG_FILE" ]; then
    fail "配置文件不存在 — 请运行 $CLI_CMD onboard 或手动创建"
    echo ""
    echo -e "${RED}配置文件缺失，后续检查无法进行${NC}"
    echo ""
    exit 1
fi

pass "配置文件: $CONFIG_FILE"

# 检查JSON格式
if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
    pass "JSON 格式正确"
elif node -e "require('$CONFIG_FILE')" 2>/dev/null; then
    pass "JSON 格式正确"
else
    fail "JSON 格式错误 — 请检查语法（多余逗号、缺少引号等）"
    info "用这个工具检查: https://jsonlint.com"
fi

# ---- 检测 API Key ----
echo ""
echo -e "${YELLOW}[3/8] 检查模型配置...${NC}"

# 检查是否有placeholder
if grep -q "YOUR_LLM_API_KEY\|YOUR_API_KEY\|your-api-key\|sk-xxx\|your-provider" "$CONFIG_FILE" 2>/dev/null; then
    fail "API Key 未填写 — 配置文件中仍有占位符"
    info "编辑 $CONFIG_FILE，把 YOUR_LLM_API_KEY 替换成真实的 Key"
else
    pass "API Key 已填写（未检测到占位符）"
fi

# 检查 providers 是否存在
if grep -q '"providers"' "$CONFIG_FILE" 2>/dev/null; then
    PROVIDER_COUNT=$(grep -o '"baseUrl"' "$CONFIG_FILE" | wc -l)
    pass "模型 Provider 已配置（$PROVIDER_COUNT 个）"
else
    fail "未找到 models.providers 配置"
fi

# ---- 检测 Discord 配置 ----
echo ""
echo -e "${YELLOW}[4/8] 检查 Discord 配置...${NC}"

if grep -q '"discord"' "$CONFIG_FILE" 2>/dev/null; then
    # 检查是否启用
    if grep -q '"enabled": true' "$CONFIG_FILE" 2>/dev/null || grep -q '"enabled":true' "$CONFIG_FILE" 2>/dev/null; then
        pass "Discord 已启用"
    else
        warn "Discord 可能未启用 — 检查 channels.discord.enabled"
    fi

    # 检查 Bot Token 占位符
    BOT_PLACEHOLDER=$(grep -c "YOUR_.*BOT_TOKEN\|YOUR_.*_TOKEN" "$CONFIG_FILE" 2>/dev/null)
    if [ "$BOT_PLACEHOLDER" -gt 0 ]; then
        fail "有 $BOT_PLACEHOLDER 个 Bot Token 未填写"
        info "去 https://discord.com/developers/applications 创建 Bot 并复制 Token"
    else
        BOT_COUNT=$(grep -c '"token":' "$CONFIG_FILE" 2>/dev/null || echo 0)
        pass "Bot Token 已填写（$BOT_COUNT 个 Bot）"
    fi

    # 检查 allowBots
    if grep -q '"allowBots": true\|"allowBots":true' "$CONFIG_FILE" 2>/dev/null; then
        pass "allowBots: true（Bot 之间可以互相触发）"
    else
        warn "allowBots 未开启 — Bot 之间无法互相对话"
        info "在 channels.discord 中添加 \"allowBots\": true"
    fi

    # 检查 groupPolicy
    if grep -q '"groupPolicy": "open"\|"groupPolicy":"open"' "$CONFIG_FILE" 2>/dev/null; then
        pass "groupPolicy: open（群聊消息已放行）"
    else
        warn "groupPolicy 可能不是 open — @everyone 可能不触发"
        info "确保 channels.discord.groupPolicy 和每个 account 的 groupPolicy 都设为 \"open\""
    fi

    echo ""
    echo -e "${CYAN}  📋 Discord @everyone 不触发？逐项检查：${NC}"
    echo -e "     1. Discord Developer Portal → 每个 Bot 开启 ${YELLOW}Message Content Intent${NC}"
    echo -e "     2. Discord Developer Portal → 每个 Bot 开启 ${YELLOW}Server Members Intent${NC}"
    echo -e "     3. Discord Developer Portal → 每个 Bot 开启 ${YELLOW}Presence Intent${NC}（可选）"
    echo -e "     4. 服务器设置 → 每个 Bot 角色有 ${YELLOW}View Channels${NC} 权限"
    echo -e "     5. 配置文件 → channels.discord.${YELLOW}groupPolicy: \"open\"${NC}"
    echo -e "     6. 配置文件 → 每个 account 的 ${YELLOW}groupPolicy: \"open\"${NC}"
    echo -e "     7. 配置文件 → channels.discord.${YELLOW}\"allowBots\": true${NC}（Bot互触发需要）"
    echo ""
else
    info "Discord 未配置（如果不用 Discord 可忽略）"
fi

# ---- 检测 Docker / Sandbox 权限 ----
echo ""
echo -e "${YELLOW}[5/8] 检查 Docker / Sandbox 权限...${NC}"

if command -v docker &>/dev/null; then
    pass "Docker 已安装"
    # 检查当前用户是否有 docker.sock 权限
    if docker info &>/dev/null 2>&1; then
        pass "Docker 权限正常（可以连接 docker.sock）"
    else
        if [ "$(id -u)" -eq 0 ]; then
            fail "Docker 已安装但无法连接 — 检查 Docker daemon 是否启动: systemctl start docker"
        else
            fail "Docker 权限不足 — 非 root 用户无法连接 docker.sock"
            info "修复方法: sudo usermod -aG docker \$USER && newgrp docker"
            info "或重新登录后生效"
            info "这会导致 sandbox 模式（子代理沙箱）无法工作"
        fi
    fi
else
    # 检查配置中是否用了 sandbox
    if grep -q '"sandbox"' "$CONFIG_FILE" 2>/dev/null; then
        SANDBOX_MODE=$(grep -o '"mode": "[^"]*"' "$CONFIG_FILE" | head -1 | sed 's/"mode": "//;s/"//')
        if [ "$SANDBOX_MODE" = "off" ]; then
            info "Docker 未安装，sandbox 已关闭，无影响"
        else
            warn "Docker 未安装但配置了 sandbox — 子代理沙箱将无法工作"
            info "安装 Docker: curl -fsSL https://get.docker.com | sh"
            info "或关闭 sandbox: 把 agents.defaults.sandbox.mode 设为 \"off\""
        fi
    else
        info "Docker 未安装（sandbox 未配置，可忽略）"
    fi
fi

# ---- 检测 Agents 配置 ----
echo ""
echo -e "${YELLOW}[6/8] 检查 Agent 配置...${NC}"

AGENT_COUNT=$(grep -c '"id":' "$CONFIG_FILE" 2>/dev/null || echo 0)
if [ "$AGENT_COUNT" -gt 0 ]; then
    pass "已配置 $AGENT_COUNT 个 Agent"
else
    warn "未检测到 Agent 配置"
fi

# 检查 bindings
BINDING_COUNT=$(grep -c '"agentId":' "$CONFIG_FILE" 2>/dev/null || echo 0)
if [ "$BINDING_COUNT" -gt 0 ]; then
    pass "已配置 $BINDING_COUNT 条 Binding 路由"
else
    warn "未检测到 Binding 路由 — Agent 可能收不到消息"
fi

# 检查 agent 数量是否和 binding 数量匹配
if [ "$AGENT_COUNT" -gt 0 ] && [ "$BINDING_COUNT" -gt 0 ]; then
    if [ "$AGENT_COUNT" -ne "$BINDING_COUNT" ]; then
        warn "Agent 数量（$AGENT_COUNT）和 Binding 数量（$BINDING_COUNT）不一致 — 部分 Agent 可能没有绑定"
    fi
fi

# ---- 检测工作区 ----
echo ""
echo -e "${YELLOW}[7/8] 检查工作区...${NC}"

# 查找工作区路径
WORKSPACE=$(grep -o '"workspace": "[^"]*"' "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/"workspace": "//;s/"//' | sed "s|\$HOME|$HOME|;s|~|$HOME|")
if [ -z "$WORKSPACE" ]; then
    WORKSPACE="$HOME/clawd"
fi

if [ -d "$WORKSPACE" ]; then
    pass "工作区目录存在: $WORKSPACE"
else
    fail "工作区目录不存在: $WORKSPACE"
    info "运行: mkdir -p $WORKSPACE"
fi

[ -f "$WORKSPACE/SOUL.md" ] && pass "SOUL.md ✓" || warn "SOUL.md 不存在 — Agent 缺少行为准则"
[ -f "$WORKSPACE/USER.md" ] && pass "USER.md ✓" || warn "USER.md 不存在 — Agent 不了解用户信息"
[ -d "$WORKSPACE/memory" ] && pass "memory/ ✓" || warn "memory/ 目录不存在 — 运行: mkdir -p $WORKSPACE/memory"

# ---- 检测 Notion ----
echo ""
echo -e "${YELLOW}[8/8] 检查可选集成...${NC}"

if [ -f "$HOME/.config/notion/api_key" ]; then
    NOTION_KEY=$(cat "$HOME/.config/notion/api_key" 2>/dev/null)
    if [[ "$NOTION_KEY" == ntn_* ]] || [[ "$NOTION_KEY" == secret_* ]]; then
        pass "Notion API Key 已配置"
    else
        warn "Notion API Key 格式异常（应以 ntn_ 或 secret_ 开头）"
    fi
else
    info "Notion 未配置（可选，跳过）"
fi

# 检查 Gateway 服务状态
if systemctl --user is-active openclaw-gateway &>/dev/null; then
    pass "Gateway 服务运行中（openclaw-gateway）"
elif systemctl --user is-active clawdbot-gateway &>/dev/null; then
    pass "Gateway 服务运行中（clawdbot-gateway）"
else
    info "Gateway 服务未运行 — 可手动启动: $CLI_CMD gateway --verbose"
fi

# ---- 运行 OpenClaw 自带的 doctor ----
echo ""
if [ -n "$CLI_CMD" ]; then
    echo -e "${YELLOW}运行 $CLI_CMD doctor...${NC}"
    $CLI_CMD doctor 2>/dev/null || info "$CLI_CMD doctor 执行失败（可忽略）"
fi

# ---- 汇总 ----
echo ""
echo "================================"
echo -e "诊断完成：${GREEN}$PASS 通过${NC}  ${YELLOW}$WARN 警告${NC}  ${RED}$FAIL 错误${NC}"
echo "================================"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}有 $FAIL 个错误需要修复，请按提示操作。${NC}"
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}配置基本正确，有 $WARN 个警告建议检查。${NC}"
else
    echo -e "${GREEN}🎉 配置完美！所有检查通过。${NC}"
fi

echo ""
echo -e "如果 @everyone 仍然不触发，请确认 Discord Developer Portal 中"
echo -e "每个 Bot 都开启了 ${YELLOW}Message Content Intent${NC} 和 ${YELLOW}Server Members Intent${NC}"
echo ""
echo -e "需要帮助？${BLUE}https://discord.gg/clawd${NC}"
echo ""
