#!/bin/bash
# ============================================
# AI 朝廷 — macOS 本地安装脚本
# 适用于 macOS (Intel / Apple Silicon)
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${BLUE}🏛️ AI 朝廷 — macOS 本地安装${NC}"
echo "================================"
echo ""

# ---- 检测系统 ----
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}✗ 此脚本仅适用于 macOS${NC}"
    echo "  Linux 用户请使用 install.sh"
    exit 1
fi

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo -e "  ${GREEN}✓ Apple Silicon (M系列芯片)${NC}"
else
    echo -e "  ${GREEN}✓ Intel Mac${NC}"
fi

echo -e "  macOS $(sw_vers -productVersion)"
echo ""

# ---- 1. Homebrew ----
echo -e "${YELLOW}[1/5] 检查 Homebrew...${NC}"
if command -v brew &>/dev/null; then
    echo -e "  ${GREEN}✓ Homebrew 已安装${NC}"
else
    echo -e "  ${CYAN}→ 安装 Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
        # SEC-28: 检查是否已存在，避免重复追加
        if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "  ${GREEN}✓ Homebrew 安装完成${NC}"
fi

# ---- 2. Node.js ----
echo -e "${YELLOW}[2/5] 检查 Node.js...${NC}"
if command -v node &>/dev/null; then
    NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
    if [ "$NODE_MAJOR" -ge 22 ] 2>/dev/null; then
        echo -e "  ${GREEN}✓ Node.js $(node -v) 已安装${NC}"
    else
        echo -e "  ${YELLOW}⚠ Node.js $(node -v) 版本过低，升级中...${NC}"
        brew install node@22
        brew link --overwrite node@22 2>/dev/null || true
        echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
    fi
else
    echo -e "  ${CYAN}→ 安装 Node.js 22...${NC}"
    brew install node@22
    brew link --overwrite node@22 2>/dev/null || true
    echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
fi

# ---- 3. OpenClaw / Clawdbot ----
echo -e "${YELLOW}[3/5] 检查 OpenClaw...${NC}"
CLI_CMD=""
CONFIG_DIR=""
CONFIG_FILE=""

if command -v openclaw &>/dev/null; then
    CLI_CMD="openclaw"
    CONFIG_DIR="$HOME/.openclaw"
    CONFIG_FILE="openclaw.json"
    echo -e "  ${GREEN}✓ OpenClaw $(openclaw --version 2>/dev/null) 已安装${NC}"
elif command -v clawdbot &>/dev/null; then
    CLI_CMD="clawdbot"
    CONFIG_DIR="$HOME/.clawdbot"
    CONFIG_FILE="clawdbot.json"
    echo -e "  ${GREEN}✓ Clawdbot $(clawdbot --version 2>/dev/null) 已安装${NC}"
else
    echo -e "  ${CYAN}→ 安装 OpenClaw...${NC}"
    npm install -g openclaw 2>/dev/null || npm install -g clawdbot 2>/dev/null
    if command -v openclaw &>/dev/null; then
        CLI_CMD="openclaw"
        CONFIG_DIR="$HOME/.openclaw"
        CONFIG_FILE="openclaw.json"
    elif command -v clawdbot &>/dev/null; then
        CLI_CMD="clawdbot"
        CONFIG_DIR="$HOME/.clawdbot"
        CONFIG_FILE="clawdbot.json"
    else
        echo -e "  ${RED}✗ 安装失败，请手动运行: npm install -g openclaw${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}✓ $CLI_CMD 安装完成${NC}"
fi

# ---- 4. 初始化工作区 ----
echo -e "${YELLOW}[4/5] 初始化工作区...${NC}"
WORKSPACE="$HOME/clawd"
mkdir -p "$WORKSPACE/memory"
cd "$WORKSPACE"

# SOUL.md
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
cat > "$WORKSPACE/SOUL.md" << 'SOUL_EOF'
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
if [ ! -f "$WORKSPACE/IDENTITY.md" ]; then
cat > "$WORKSPACE/IDENTITY.md" << 'ID_EOF'
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
if [ ! -f "$WORKSPACE/USER.md" ]; then
cat > "$WORKSPACE/USER.md" << 'USER_EOF'
# 皇帝档案

- **称呼：** 皇上
- **语言：** 中文
- **偏好：** 简洁高效，直接给方案
USER_EOF
echo -e "  ${GREEN}✓ USER.md 已创建${NC}"
fi

# ---- 5. 生成配置文件 ----
echo -e "${YELLOW}[5/5] 生成配置文件...${NC}"
mkdir -p "$CONFIG_DIR"

echo ""
echo -e "${CYAN}选择部署模式：${NC}"
echo "  1) Discord 多Bot模式（完整六部，需要创建 Discord Bot）"
echo "  2) 飞书单Bot模式（只需 1 个飞书应用，sessions_spawn 后台调度）"
echo "  3) 纯 WebUI 模式（不需要 Discord/飞书，浏览器直接用）"
echo ""
if [ -t 0 ]; then
    read -p "请选择 [1/2/3]（默认1）: " DEPLOY_MODE
else
    DEPLOY_MODE=""
fi
DEPLOY_MODE=${DEPLOY_MODE:-1}

if [ ! -f "$CONFIG_DIR/$CONFIG_FILE" ]; then

if [ "$DEPLOY_MODE" = "3" ]; then
# ==================== 纯 WebUI 模式 ====================
cat > "$CONFIG_DIR/$CONFIG_FILE" << CONFIG_EOF
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
# ==================== 飞书单Bot模式 ====================
cat > "$CONFIG_DIR/$CONFIG_FILE" << FEISHU_EOF
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
        "identity": { "theme": "你是AI朝廷的司礼监大内总管。你的职责是【规划调度】，不是亲自执行。说话简练干脆。\n\n【核心原则】除了日常闲聊和简单问答，所有涉及实际工作的任务（写代码、查资料、分析数据、写文案、运维操作等），一律使用 sessions_spawn 派发给对应部门执行。你是指挥官，不是搬砖工。\n\n【部门职责】内阁=战略决策、都察院=审查监察、兵部=编码开发、户部=财务分析、礼部=品牌营销、工部=运维部署、吏部=项目管理、刑部=法务合规、翰林院=研究文档。\n\n【派活方式】使用 sessions_spawn 将任务派发给对应部门的 agentId。完成后主动向用户汇报结果摘要。\n\n【什么时候自己回答】仅限：纯闲聊、确认信息、汇报进度、问澄清问题。其他一律派活。" },
        "sandbox": { "mode": "off" },
        "subagents": {
          "allowAgents": ["neige", "duchayuan", "bingbu", "hubu", "libu", "gongbu", "libu2", "xingbu", "hanlinyuan"]
        }
      },
      { "id": "neige", "name": "内阁", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是内阁首辅，专精战略决策。回答用中文。" }, "sandbox": { "mode": "off" } },
      { "id": "duchayuan", "name": "都察院", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是都察院御史，专精代码审查、质量把控。回答用中文。" }, "sandbox": { "mode": "all", "scope": "agent" } },
      { "id": "bingbu", "name": "兵部", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是兵部尚书，专精软件工程。回答用中文。" }, "sandbox": { "mode": "all", "scope": "agent" } },
      { "id": "hubu", "name": "户部", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是户部尚书，专精财务分析。回答用中文。" }, "sandbox": { "mode": "off" } },
      { "id": "libu", "name": "礼部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是礼部尚书，专精品牌营销。回答用中文。" }, "sandbox": { "mode": "off" } },
      { "id": "gongbu", "name": "工部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是工部尚书，专精 DevOps 运维。回答用中文。" }, "sandbox": { "mode": "off" } },
      { "id": "libu2", "name": "吏部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是吏部尚书，专精项目管理。回答用中文。" }, "sandbox": { "mode": "off" } },
      { "id": "xingbu", "name": "刑部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是刑部尚书，专精法务合规。回答用中文。" }, "sandbox": { "mode": "off" } },
      { "id": "hanlinyuan", "name": "翰林院", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是翰林院学士，专精学术研究、文档撰写。回答用中文。" }, "sandbox": { "mode": "off" } }
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
  ]
}
FEISHU_EOF
echo -e "  ${GREEN}✓ 飞书单Bot模式配置已生成${NC}"

else
# ==================== Discord 多Bot模式（默认）====================
cat > "$CONFIG_DIR/$CONFIG_FILE" << CONFIG_EOF
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
          "name": "司礼监",
          "token": "YOUR_SILIJIAN_BOT_TOKEN",
          "applicationId": "YOUR_SILIJIAN_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "neige": {
          "name": "内阁",
          "token": "YOUR_NEIGE_BOT_TOKEN",
          "applicationId": "YOUR_NEIGE_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "duchayuan": {
          "name": "都察院",
          "token": "YOUR_DUCHAYUAN_BOT_TOKEN",
          "applicationId": "YOUR_DUCHAYUAN_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "bingbu": {
          "name": "兵部",
          "token": "YOUR_BINGBU_BOT_TOKEN",
          "applicationId": "YOUR_BINGBU_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "hubu": {
          "name": "户部",
          "token": "YOUR_HUBU_BOT_TOKEN",
          "applicationId": "YOUR_HUBU_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "libu": {
          "name": "礼部",
          "token": "YOUR_LIBU_BOT_TOKEN",
          "applicationId": "YOUR_LIBU_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "gongbu": {
          "name": "工部",
          "token": "YOUR_GONGBU_BOT_TOKEN",
          "applicationId": "YOUR_GONGBU_APPLICATION_ID",
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
          "applicationId": "YOUR_XINGBU_APPLICATION_ID",
          "groupPolicy": "open"
        },
        "hanlinyuan": {
          "name": "翰林院",
          "token": "YOUR_HANLINYUAN_BOT_TOKEN",
          "applicationId": "YOUR_HANLINYUAN_APPLICATION_ID",
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
echo -e "  ${GREEN}✓ Discord 多Bot模式配置已生成 ($CONFIG_DIR/$CONFIG_FILE)${NC}"

fi # end DEPLOY_MODE

else
    echo -e "  ${YELLOW}⚠ 配置文件已存在，跳过 ($CONFIG_DIR/$CONFIG_FILE)${NC}"
fi # end config file exists check

echo ""
echo "================================"
echo -e "${GREEN}🎉 macOS 安装完成！${NC}"
echo "================================"
echo ""
echo "接下来："
echo ""
echo -e "  ${YELLOW}1. 配置 LLM API Key${NC}"
echo "     编辑 $CONFIG_DIR/$CONFIG_FILE"
echo "     把 YOUR_LLM_API_KEY 替换成你的 API Key"
echo ""
if [ "$DEPLOY_MODE" = "2" ]; then
echo -e "  ${YELLOW}2. 创建飞书应用（只需 1 个：司礼监）${NC}"
echo "     a) 访问 https://open.feishu.cn/app"
echo "     b) 创建应用（如「AI朝廷-司礼监」）→ 复制 App ID 和 App Secret"
echo "     c) 权限管理 → 添加 im:message 等 8 个权限"
echo "     d) 开启机器人能力，添加 im.message.receive_v1 事件"
echo "     e) 事件接收选择 WebSocket 长连接"
echo "     f) 把 appId/appSecret 填到配置文件的 silijian 位置"
echo "     g) 创建版本并发布应用"
echo ""
echo -e "     📖 详细指南: ${CYAN}https://github.com/wanikua/boluobobo-ai-court-tutorial/blob/main/飞书配置指南.md${NC}"
elif [ "$DEPLOY_MODE" = "3" ]; then
echo -e "  ${YELLOW}2. 无需配置 Bot${NC}"
echo "     WebUI 模式直接通过浏览器访问即可"
else
echo -e "  ${YELLOW}2. 创建 Discord Bot${NC}"
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 每个部门创建一个 Bot → 复制 Token"
echo "     c) 填入配置文件对应位置"
echo "     d) 每个 Bot 开启 Message Content Intent"
echo "     e) 邀请所有 Bot 到你的 Discord 服务器"
fi
echo ""
echo -e "  ${YELLOW}3. 启动朝廷${NC}"
echo "     $CLI_CMD gateway start"
echo ""
echo -e "  ${YELLOW}4. 验证${NC}"
echo "     $CLI_CMD status"
if [ "$DEPLOY_MODE" = "2" ]; then
echo "     在飞书里给机器人发消息试试"
elif [ "$DEPLOY_MODE" = "3" ]; then
echo "     浏览器打开 http://localhost:18789"
else
echo "     在 Discord @你的Bot 说话试试"
fi
echo ""
echo -e "  ${YELLOW}5. 后台运行（可选）${NC}"
echo "     # 使用 launchd 开机自启："
echo "     $CLI_CMD gateway install"
echo "     # 或用 tmux/screen 保持后台运行："
echo "     tmux new -d -s court '$CLI_CMD gateway'"
echo ""
echo -e "  ${YELLOW}6. 添加定时任务（可选）${NC}"
echo "     $CLI_CMD cron add --name '每日简报' \\"
echo "       --agent silijian --cron '0 22 * * *' --tz Asia/Shanghai \\"
echo "       --message '生成今日简报' --session isolated"
echo ""
echo -e "💡 Mac 用户提示："
echo "  • 合上盖子会休眠，建议在「系统设置 → 电池 → 选项」里关闭自动休眠"
echo "  • 或者用 caffeinate -d 命令防止休眠"
echo "  • 长期运行建议使用云服务器"
echo ""
echo -e "完整教程：${BLUE}https://github.com/wanikua/boluobobo-ai-court-tutorial${NC}"
