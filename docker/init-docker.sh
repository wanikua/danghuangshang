#!/bin/bash
set -e

# ============================================
# 🏛️ AI 朝廷 Docker 初始化脚本
# ============================================
# 用法：
#   docker compose exec court /init-docker.sh
#   docker compose run --rm court /init-docker.sh
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/clawd}"

echo ""
echo -e "${CYAN}🏛️ AI 朝廷 Docker 初始化向导${NC}"
echo "================================"
echo ""

# ---- 步骤 1：选择部署模式 ----
echo -e "${YELLOW}📋 步骤 1/4：选择部署模式${NC}"
echo ""
echo "  1) 单 Agent（司礼监）— 最简模式，一个 Bot 管所有事"
echo "  2) 全六部（10 Agent）— 司礼监调度，各部门独立执行"
echo ""
if [ -t 0 ]; then
read -p "请选择 [1/2，默认 1]: " MODE
else
  MODE=""
fi
MODE=${MODE:-1}

# ---- 步骤 2：选择平台 ----
echo ""
echo -e "${YELLOW}📋 步骤 2/4：选择交互平台${NC}"
echo ""
echo "  1) Discord（海外推荐）"
echo "  2) 飞书（国内推荐）"
echo "  3) 纯 WebUI（不需要 Bot）"
echo ""
if [ -t 0 ]; then
read -p "请选择 [1/2/3，默认 1]: " PLATFORM
else
  PLATFORM=""
fi
PLATFORM=${PLATFORM:-1}

# ---- 步骤 3：配置模型 ----
echo ""
echo -e "${YELLOW}📋 步骤 3/4：配置 AI 模型${NC}"
echo ""
echo "  常用 API 提供商："
echo "  - Anthropic Claude: https://console.anthropic.com"
echo "  - OpenAI: https://platform.openai.com"
echo "  - DeepSeek: https://platform.deepseek.com"
echo "  - OpenRouter: https://openrouter.ai"
echo ""
if [ -t 0 ]; then
read -p "API Base URL（如 https://api.deepseek.com/v1）: " API_URL
else
  API_URL=""
fi
if [ -t 0 ]; then
read -p "API Key: " API_KEY
else
  API_KEY=""
fi
if [ -t 0 ]; then
read -p "模型 ID（如 deepseek-chat、gpt-4o、claude-sonnet-4-20250514）: " MODEL_ID
else
  MODEL_ID=""
fi

if [ -z "$API_URL" ] || [ -z "$API_KEY" ] || [ -z "$MODEL_ID" ]; then
    echo -e "${RED}✗ API 配置不能为空${NC}"
    exit 1
fi

# 自动检测 API 格式
API_FORMAT="openai"
if echo "$API_URL" | grep -qi "anthropic"; then
    API_FORMAT="anthropic-messages"
fi

# ---- 步骤 4：配置平台 ----
echo ""
echo -e "${YELLOW}📋 步骤 4/4：配置平台凭证${NC}"
echo ""

if [ "$PLATFORM" = "1" ]; then
    echo "Discord Bot 配置："
    echo "  1. 去 https://discord.com/developers/applications 创建 Bot"
    echo "  2. 开启 Message Content Intent + Server Members Intent"
    echo "  3. 邀请 Bot 到你的服务器"
    echo ""
    if [ -t 0 ]; then
    read -p "Discord Bot Token: " BOT_TOKEN
    else
      BOT_TOKEN=""
    fi
    if [ -z "$BOT_TOKEN" ]; then
        echo -e "${RED}✗ Bot Token 不能为空${NC}"
        exit 1
    fi
    echo ""
    echo "  Discord 服务器 ID（Guild ID）获取方式："
    echo "  设置 → 高级 → 开启「开发者模式」→ 右键服务器名 → 复制服务器 ID"
    echo ""
    if [ -t 0 ]; then
    read -p "Discord Guild ID（留空则所有服务器生效）: " GUILD_ID
    else
      GUILD_ID=""
    fi
    APP_ID=""
    APP_SECRET=""

elif [ "$PLATFORM" = "2" ]; then
    echo "飞书配置："
    echo "  1. 去 https://open.feishu.cn/app 创建企业自建应用"
    echo "  2. 添加「机器人」能力"
    echo "  3. 事件接收方式选择「WebSocket 长连接」（无需配置回调 URL）"
    echo ""
    if [ -t 0 ]; then
    read -p "App ID: " APP_ID
    else
      APP_ID=""
    fi
    if [ -t 0 ]; then
    read -p "App Secret: " APP_SECRET
    else
      APP_SECRET=""
    fi
    if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
        echo -e "${RED}✗ App ID 和 App Secret 不能为空${NC}"
        exit 1
    fi
    # 飞书凭证已保存在 $APP_ID 和 $APP_SECRET
    BOT_TOKEN=""

elif [ "$PLATFORM" = "3" ]; then
    echo -e "${GREEN}WebUI 模式不需要额外配置，启动后访问 http://localhost:18789 即可${NC}"
    BOT_TOKEN=""
    APP_ID=""
    APP_SECRET=""
fi

# ---- 生成配置 ----
echo ""
echo -e "${CYAN}⚙️ 生成配置文件...${NC}"

mkdir -p "$CONFIG_DIR"

# [M-15] 用 Python 生成合法 JSON（通过环境变量传参，避免注入风险）
CFG_API_URL="$API_URL" \
CFG_API_KEY="$API_KEY" \
CFG_API_FORMAT="$API_FORMAT" \
CFG_MODEL_ID="$MODEL_ID" \
CFG_WORKSPACE="$WORKSPACE" \
CFG_MODE="$MODE" \
CFG_PLATFORM="$PLATFORM" \
CFG_BOT_TOKEN="$BOT_TOKEN" \
CFG_APP_ID="$APP_ID" \
CFG_APP_SECRET="$APP_SECRET" \
CFG_GUILD_ID="${GUILD_ID:-}" \
CFG_CONFIG_FILE="$CONFIG_FILE" \
python3 << 'PYEOF'
import json, os

api_url = os.environ['CFG_API_URL']
api_key = os.environ['CFG_API_KEY']
api_format = os.environ['CFG_API_FORMAT']
model_id = os.environ['CFG_MODEL_ID']
workspace = os.environ['CFG_WORKSPACE']
mode = os.environ['CFG_MODE']
platform = os.environ['CFG_PLATFORM']
bot_token = os.environ.get('CFG_BOT_TOKEN', '')
app_id = os.environ.get('CFG_APP_ID', '')
app_secret = os.environ.get('CFG_APP_SECRET', '')
guild_id = os.environ.get('CFG_GUILD_ID', '')
config_file = os.environ['CFG_CONFIG_FILE']

silijian_identity = (
    "你是AI朝廷的司礼监大内总管。你的职责是规划调度，不是亲自执行。使用 sessions_spawn 将任务派发给对应部门。"
    if mode == "2" else
    "你是AI朝廷的司礼监，忠诚干练，说话简练干脆。用中文回答。"
)

config = {
    "models": {
        "providers": {
            "provider": {
                "baseUrl": api_url,
                "apiKey": api_key,
                "api": api_format,
                "models": [{
                    "id": model_id, "name": model_id,
                    "input": ["text", "image"], "contextWindow": 200000, "maxTokens": 8192
                }]
            }
        }
    },
    "agents": {
        "defaults": {
            "workspace": workspace,
            "model": {"primary": f"provider/{model_id}"},
            "sandbox": {"mode": "non-main"}
        },
        "list": [{
            "id": "silijian",
            "name": "司礼监",
            "model": {"primary": f"provider/{model_id}"},
            "identity": {"theme": silijian_identity},
            "sandbox": {"mode": "off"}
        }]
    },
    "bindings": []
}

# 全六部模式：添加 subagents 和其他部门
if mode == "2":
    config["agents"]["list"][0]["subagents"] = {
        "allowAgents": ["neige","duchayuan","bingbu","hubu","libu","gongbu","libu2","xingbu","hanlinyuan"]
    }
    departments = [
        ("neige", "内阁", "你是内阁首辅，专精战略决策、方案审议、全局规划。回答用中文。", "off"),
        ("duchayuan", "都察院", "你是都察院御史，专精监察审计、代码审查、质量把控。回答用中文。", "all"),
        ("bingbu", "兵部", "你是兵部尚书，专精软件工程、系统架构。回答用中文。", "all"),
        ("hubu", "户部", "你是户部尚书，专精财务分析、成本管控。回答用中文。", "off"),
        ("libu", "礼部", "你是礼部尚书，专精品牌营销、内容创作。回答用中文。", "off"),
        ("gongbu", "工部", "你是工部尚书，专精 DevOps、服务器运维。回答用中文。", "off"),
        ("libu2", "吏部", "你是吏部尚书，专精项目管理、团队协调。回答用中文。", "off"),
        ("xingbu", "刑部", "你是刑部尚书，专精法务合规、知识产权。回答用中文。", "off"),
        ("hanlinyuan", "翰林院", "你是翰林院学士，专精学术研究、知识整理、文档撰写。回答用中文。", "off"),
    ]
    for did, dname, dtheme, smode in departments:
        agent = {"id": did, "name": dname, "identity": {"theme": dtheme}, "sandbox": {"mode": smode}}
        if smode == "all":
            agent["sandbox"]["scope"] = "agent"
        config["agents"]["list"].append(agent)

# 平台配置
if platform == "1":
    discord_config = {
        "enabled": True, "groupPolicy": "open", "allowBots": True,
        "accounts": {"silijian": {"name": "司礼监", "token": bot_token, "groupPolicy": "open"}},
    }
    if guild_id:
        discord_config["guilds"] = {guild_id: {"requireMention": True}}
    config["channels"] = {"discord": discord_config}
    config["bindings"] = [{"agentId": "silijian", "match": {"channel": "discord", "accountId": "silijian"}}]
elif platform == "2":
    config["channels"] = {"feishu": {
        "enabled": True,
        "dmPolicy": "open", "groupPolicy": "open",
        "accounts": {"silijian": {"name": "司礼监", "appId": app_id, "appSecret": app_secret, "groupPolicy": "open"}}
    }}
    config["bindings"] = [{"agentId": "silijian", "match": {"channel": "feishu", "accountId": "silijian"}}]
else:
    config["bindings"] = [{"agentId": "silijian", "match": {}}]

with open(config_file, "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
PYEOF

echo -e "${GREEN}✓ 配置文件已生成：$CONFIG_FILE${NC}"

# ---- 初始化工作区 ----
mkdir -p "$WORKSPACE/memory" "$WORKSPACE/skills"

if [ ! -f "$WORKSPACE/SOUL.md" ]; then
cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - 朝廷行为准则

## 铁律
1. 废话不要多 — 说重点
2. 汇报要及时 — 做完就说
3. 做事要靠谱 — 先想后做

## 沟通风格
- 中文为主
- 直接说结论，需要细节再展开
EOF
echo -e "${GREEN}✓ SOUL.md 已创建${NC}"
fi

if [ ! -f "$WORKSPACE/USER.md" ]; then
    if [ -t 0 ]; then
    read -p "你希望 AI 怎么称呼你？（默认：陛下）: " NICKNAME
    else
      NICKNAME=""
    fi
    NICKNAME=${NICKNAME:-陛下}
    cat > "$WORKSPACE/USER.md" << EOF
# USER.md - 关于你

- **称呼:** $NICKNAME
- **语言:** 中文
- **风格:** 简洁高效
EOF
    echo -e "${GREEN}✓ USER.md 已创建${NC}"
fi

# ---- 完成 ----
echo ""
echo "================================"
echo -e "${GREEN}🎉 初始化完成！${NC}"
echo "================================"
echo ""
echo "  配置文件: $CONFIG_FILE"
echo "  工作区:   $WORKSPACE"
echo ""
echo "  Gateway 将在几秒内自动启动..."
echo ""
if [ "$PLATFORM" = "1" ]; then
    echo "  下一步：在 Discord 里 @你的 Bot 说句话"
elif [ "$PLATFORM" = "2" ]; then
    echo "  下一步：在飞书里给机器人发消息"
else
    echo "  下一步：打开 http://localhost:18789"
fi
echo ""
