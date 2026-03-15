#!/bin/bash
# ============================================
# AI 朝廷精简配置脚本（适用于已装好 OpenClaw 或 Clawdbot 的用户）
# 跳过系统依赖，只初始化工作区 + 生成配置模板
#
# 用法:
#   bash install-lite.sh              # 交互式安装
#   bash install-lite.sh --no-gui     # 跳过 Dashboard Web UI
#   bash install-lite.sh --with-gui   # 包含 Dashboard Web UI
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

echo ""
echo -e "${BLUE}🏛️ AI 朝廷 — 精简配置${NC}"
echo "================================"
echo -e "适用于已安装 OpenClaw/Clawdbot 的用户"
echo ""

# ---- 检查 OpenClaw 是否已安装 ----
if command -v openclaw &>/dev/null; then
    CLI_CMD="openclaw"
    echo -e "  ${GREEN}✓ 检测到 OpenClaw $(openclaw --version 2>/dev/null)${NC}"
elif command -v clawdbot &>/dev/null; then
    CLI_CMD="clawdbot"
    echo -e "  ${GREEN}✓ 检测到 Clawdbot $(clawdbot --version 2>/dev/null)${NC}"
else
    echo -e "  ${RED}✗ 未检测到 OpenClaw 或 Clawdbot${NC}"
    echo ""
    echo "请先安装："
    echo "  npm install -g openclaw@latest"
    echo ""
    echo "或使用完整安装脚本："
    echo "  bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install.sh)"
    exit 1
fi

# ---- 选择模式 ----
echo ""
echo -e "${CYAN}选择部署模式：${NC}"
echo "  1) Discord 多Bot模式（完整六部，需要创建 Discord Bot）"
echo "  2) 飞书单Bot模式（只需 1 个飞书应用，sessions_spawn 后台调度）"
echo "  3) 纯 WebUI 模式（不需要 Discord/飞书，浏览器直接用）"
echo ""
if [ -t 0 ]; then
    read -p "请选择 [1/2/3]（默认1）: " MODE_CHOICE
else
    MODE_CHOICE=""
fi
MODE_CHOICE=${MODE_CHOICE:-1}

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

echo ""

# ---- 初始化工作区 ----
echo -e "${YELLOW}[1/4] 初始化朝廷工作区...${NC}"
WORKSPACE="$HOME/clawd"
if [ "$CLI_CMD" = "openclaw" ]; then
    CONFIG_DIR="$HOME/.openclaw"
    CONFIG_FILE="openclaw.json"
else
    CONFIG_DIR="$HOME/.clawdbot"
    CONFIG_FILE="clawdbot.json"
fi
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
else
echo -e "  ${GREEN}✓ SOUL.md 已存在，跳过${NC}"
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
else
echo -e "  ${GREEN}✓ IDENTITY.md 已存在，跳过${NC}"
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
else
echo -e "  ${GREEN}✓ USER.md 已存在，跳过${NC}"
fi

# memory 目录
mkdir -p memory

# ---- 生成配置文件 ----
echo -e "${YELLOW}[2/4] 生成配置文件...${NC}"

# 注意：推荐使用 CLI 命令管理配置（openclaw agents add / openclaw channels add），
# 而不是直接写 openclaw.json。这里生成模板仅作为快速起步参考。
# 详见: https://github.com/openclaw/openclaw#configuration

if [ -f "$CONFIG_DIR/$CONFIG_FILE" ]; then
    echo -e "  ${YELLOW}⚠ 配置文件已存在，跳过生成（避免覆盖你的修改）${NC}"
    echo -e "  ${CYAN}↳ 如需重新生成，先备份后删除: mv $CONFIG_DIR/$CONFIG_FILE $CONFIG_DIR/${CONFIG_FILE}.bak${NC}"
    SKIP_CONFIG=true
else
    SKIP_CONFIG=false
fi

if $SKIP_CONFIG; then
    true  # 跳过配置生成

elif [ "$MODE_CHOICE" = "3" ]; then
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

elif [ "$MODE_CHOICE" = "2" ]; then
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
        "identity": { "theme": "你是内阁首辅，专精战略决策、方案审议、全局规划。回答用中文，高屋建瓴。" },
        "sandbox": { "mode": "off" }
      },
      {
        "id": "duchayuan",
        "name": "都察院",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是都察院御史，专精监察审计、代码审查、质量把控。回答用中文，铁面无私。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      {
        "id": "bingbu",
        "name": "兵部",
        "model": { "primary": "your-provider/strong-model" },
        "identity": { "theme": "你是兵部尚书，专精软件工程、系统架构。回答用中文，直接给方案。" },
        "sandbox": { "mode": "all", "scope": "agent" }
      },
      { "id": "hubu", "name": "户部", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是户部尚书，专精财务分析、成本管控。回答用中文，数据驱动。" }, "sandbox": { "mode": "off" } },
      { "id": "libu", "name": "礼部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是礼部尚书，专精品牌营销、内容创作。回答用中文，风格活泼。" }, "sandbox": { "mode": "off" } },
      { "id": "gongbu", "name": "工部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是工部尚书，专精 DevOps、服务器运维。回答用中文，注重实操。" }, "sandbox": { "mode": "off" } },
      { "id": "libu2", "name": "吏部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是吏部尚书，专精项目管理、创业孵化。回答用中文，条理清晰。" }, "sandbox": { "mode": "off" } },
      { "id": "xingbu", "name": "刑部", "model": { "primary": "your-provider/fast-model" }, "identity": { "theme": "你是刑部尚书，专精法务合规、知识产权。回答用中文，严谨专业。" }, "sandbox": { "mode": "off" } },
      { "id": "hanlinyuan", "name": "翰林院", "model": { "primary": "your-provider/strong-model" }, "identity": { "theme": "你是翰林院学士，专精学术研究、文档撰写。回答用中文，学术严谨。" }, "sandbox": { "mode": "off" } }
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
        "sandbox": { "mode": "off" }
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
    { "agentId": "bingbu", "match": { "channel": "discord", "accountId": "bingbu" } },
    { "agentId": "hubu", "match": { "channel": "discord", "accountId": "hubu" } },
    { "agentId": "libu", "match": { "channel": "discord", "accountId": "libu" } },
    { "agentId": "gongbu", "match": { "channel": "discord", "accountId": "gongbu" } },
    { "agentId": "libu2", "match": { "channel": "discord", "accountId": "libu2" } },
    { "agentId": "xingbu", "match": { "channel": "discord", "accountId": "xingbu" } },
    { "agentId": "neige", "match": { "channel": "discord", "accountId": "neige" } },
    { "agentId": "duchayuan", "match": { "channel": "discord", "accountId": "duchayuan" } },
    { "agentId": "hanlinyuan", "match": { "channel": "discord", "accountId": "hanlinyuan" } }
  ]
}
CONFIG_EOF
echo -e "  ${GREEN}✓ Discord 多Bot模式配置已生成${NC}"
fi

# ---- 可选：安装 Dashboard Web UI ----
echo -e "${YELLOW}[3/4] Dashboard Web UI...${NC}"
if [ "$INSTALL_GUI" = "yes" ]; then
    REPO_URL="https://github.com/wanikua/boluobobo-ai-court-tutorial"
    GUI_DIR="$WORKSPACE/gui"
    if [ -d "$GUI_DIR" ]; then
        echo -e "  ${GREEN}✓ gui/ 目录已存在，跳过克隆${NC}"
    else
        echo -e "  ${CYAN}正在下载 Dashboard...${NC}"
        # 只克隆 gui 目录
        # SEC-08: 使用 mktemp 创建安全临时目录，避免符号链接竞态
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
    # 安装依赖
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

# ---- 完成提示 ----
echo -e "${YELLOW}[4/4] 配置完成！${NC}"
echo ""
echo "================================"
echo -e "${GREEN}🎉 工作区初始化完成！${NC}"
echo "================================"
echo ""
echo -e "  工作区：${CYAN}$WORKSPACE${NC}"
echo -e "  配置文件：${CYAN}$CONFIG_DIR/$CONFIG_FILE${NC}"
echo ""

if [ "$MODE_CHOICE" = "3" ]; then
echo -e "  ${YELLOW}接下来只需要 3 步：${NC}"
echo ""
echo "  1. 编辑配置文件，填入 LLM API Key："
echo "     nano $CONFIG_DIR/$CONFIG_FILE"
echo ""
echo "  2. 启动 Gateway："
echo "     $CLI_CMD gateway --verbose"
echo ""
echo "  3. 浏览器打开 WebUI："
echo "     http://localhost:18789"
echo ""
elif [ "$MODE_CHOICE" = "2" ]; then
echo -e "  ${YELLOW}接下来需要 3 步：${NC}"
echo ""
echo "  1. 编辑配置文件，填入 LLM API Key："
echo "     nano $CONFIG_DIR/$CONFIG_FILE"
echo ""
echo "  2. 创建飞书应用（只需 1 个：司礼监）："
echo "     a) 访问 https://open.feishu.cn/app"
echo "     b) 创建应用（如「AI朝廷-司礼监」）→ 复制 App ID 和 App Secret"
echo "     c) 权限管理 → 添加 im:message 等 8 个权限（见飞书配置指南）"
echo "     d) 开启机器人能力，添加 im.message.receive_v1 事件"
echo "     e) 事件接收选择 WebSocket 长连接"
echo "     f) 把 appId/appSecret 填到配置文件的 silijian 位置"
echo "     g) 创建版本并发布应用"
echo ""
echo "  3. 启动 Gateway："
echo "     $CLI_CMD gateway --verbose"
echo ""
echo -e "     📖 详细指南: ${CYAN}https://github.com/wanikua/boluobobo-ai-court-tutorial/blob/main/飞书配置指南.md${NC}"
echo ""
else
echo -e "  ${YELLOW}接下来需要 3 步：${NC}"
echo ""
echo "  1. 编辑配置文件，填入 LLM API Key："
echo "     nano $CONFIG_DIR/$CONFIG_FILE"
echo ""
echo "  2. 创建 Discord Bot（每个部门一个）："
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 创建 Application → Bot → 复制 Token"
echo "     c) 重复创建多个 Bot（司礼监、兵部、户部...按需）"
echo "     d) 把每个 Token 填到 $CONFIG_FILE 的 accounts 对应位置"
echo "     e) 每个 Bot 都要开启 Message Content Intent"
echo "     f) 邀请所有 Bot 到你的 Discord 服务器"
echo ""
echo "  3. 启动 Gateway："
echo "     $CLI_CMD gateway --verbose"
echo ""
fi

echo -e "${CYAN}💡 Troubleshooting:${NC}"
echo "  遇到 config invalid 错误？先跑: $CLI_CMD doctor --fix"
echo ""
echo -e "完整教程：${BLUE}https://github.com/wanikua/boluobobo-ai-court-tutorial${NC}"
echo ""
