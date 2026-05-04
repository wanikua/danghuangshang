#!/bin/bash

# ========================================
# AI 朝廷 · 快速安装脚本
# ========================================
# 支持：
# - 三种制度：明朝/唐朝/现代
# - 多种规模：1/3/5/9/11 Bot
# - 两个平台：飞书/Discord
# - LLM API 配置
# ========================================

set -e


# 保存终端状态，避免 read -s 被中断后出现“无回显/无反应”
ORIGINAL_STTY_SETTINGS=""
LOCK_FILE=""
if [ -t 0 ] && command -v stty >/dev/null 2>&1; then
    ORIGINAL_STTY_SETTINGS=$(stty -g 2>/dev/null || true)
fi

restore_terminal_state() {
    if [ -n "$ORIGINAL_STTY_SETTINGS" ] && command -v stty >/dev/null 2>&1; then
        stty "$ORIGINAL_STTY_SETTINGS" 2>/dev/null || stty echo 2>/dev/null || true
    fi
}
cleanup_install_runtime() {
    restore_terminal_state
    if [ -n "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
    fi
}

handle_install_interrupt() {
    cleanup_install_runtime
    echo ""
    echo "⚠ 安装已中断。可直接重新运行 install-lite.sh。"
    exit 130
}
trap cleanup_install_runtime EXIT
trap handle_install_interrupt INT TERM

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
echo "========================================"
echo "   AI 朝廷 · 快速安装向导"
echo "========================================"
echo -e "${NC}"

# 配置目录
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="openclaw.json"

# 创建配置目录
mkdir -p "$CONFIG_DIR"

# install-lite.sh 是交互式向导，非 TTY 环境下会出现“无响应/无输入”错觉
if [ ! -t 0 ] || [ ! -t 1 ]; then
    echo -e "${RED}✗ 当前不是交互式终端，install-lite.sh 需要可交互输入${NC}"
    echo "请改用："
    echo "  1) git clone 后本地执行：bash install-lite.sh"
    echo "  2) 或使用支持交互的命令：bash <(curl -fsSL .../install-lite.sh)"
    exit 1
fi

# 若上次被强制中断，优先恢复终端回显状态
if [ -n "$ORIGINAL_STTY_SETTINGS" ]; then
    stty echo 2>/dev/null || true
fi

# 防止并发执行；如果是陈旧锁文件则自动清理，确保可重入
LOCK_FILE="$CONFIG_DIR/.install-lite.lock"
if [ -f "$LOCK_FILE" ]; then
    EXISTING_PID="$(cat "$LOCK_FILE" 2>/dev/null || true)"
    if [ -n "$EXISTING_PID" ] && kill -0 "$EXISTING_PID" 2>/dev/null; then
        echo -e "${RED}✗ 检测到 install-lite.sh 正在运行（PID: $EXISTING_PID）${NC}"
        echo "请等待当前安装结束后再试。"
        exit 1
    fi
    echo -e "${YELLOW}⚠ 检测到上次安装中断，正在恢复后重试...${NC}"
    rm -f "$LOCK_FILE"
fi
echo "$$" > "$LOCK_FILE"

# ========================================
# 步骤 1: 配置 LLM API
# ========================================
echo -e "${YELLOW}[1/5] 配置 AI 模型 (必需)${NC}"
echo ""
echo "常用 API 提供商："
echo "  - Anthropic Claude: https://console.anthropic.com"
echo "  - OpenAI: https://platform.openai.com"
echo "  - DeepSeek: https://platform.deepseek.com"
echo "  - OpenRouter: https://openrouter.ai"
echo "  - DashScope (通义千问): https://dashscope.aliyun.com"
echo ""
read -p "API Base URL (如 https://api.deepseek.com/v1): " API_URL
read -s -p "API Key: " API_KEY
echo ""
read -p "模型 ID (如 deepseek-chat, gpt-4o, claude-sonnet-4-20250514): " MODEL_ID
echo ""

if [ -z "$API_URL" ] || [ -z "$API_KEY" ] || [ -z "$MODEL_ID" ]; then
    echo -e "${RED}✗ API 配置不能为空${NC}"
    exit 1
fi

# 自动检测 API 格式
API_FORMAT="openai"
if echo "$API_URL" | grep -qi "anthropic"; then
    API_FORMAT="anthropic-messages"
fi

echo -e "${GREEN}✓ API 配置完成${NC}"

# ========================================
# 步骤 2: 选择平台
# ========================================
echo ""
echo -e "${YELLOW}[2/5] 选择部署平台${NC}"
echo "  1) 飞书 (中国大陆推荐)"
echo "  2) Discord (国际推荐)"
echo "  3) 纯 WebUI (不需要 Bot)"
echo ""
read -p "请选择 (1-3): " PLATFORM

case $PLATFORM in
    1)
        PLATFORM_NAME="feishu"
        echo -e "${GREEN}✓ 选择：飞书${NC}"
        ;;
    2)
        PLATFORM_NAME="discord"
        echo -e "${GREEN}✓ 选择：Discord${NC}"
        ;;
    3)
        PLATFORM_NAME="webui"
        echo -e "${GREEN}✓ 选择：纯 WebUI${NC}"
        ;;
    *)
        echo -e "${RED}✗ 无效选择，使用飞书${NC}"
        PLATFORM_NAME="feishu"
        ;;
esac

# ========================================
# 步骤 3: 选择制度
# ========================================
echo ""
echo -e "${YELLOW}[3/5] 选择制度${NC}"
echo "  1) 明朝内阁制 (传统层级管理)"
echo "  2) 唐朝三省制 (分权制衡管理)"
echo "  3) 现代企业制 (现代企业管理)"
echo ""
read -p "请选择 (1-3): " REGIME

case $REGIME in
    1)
        REGIME_NAME="ming"
        REGIME_LABEL="明朝内阁制"
        echo -e "${GREEN}✓ 选择：$REGIME_LABEL${NC}"
        ;;
    2)
        REGIME_NAME="tang"
        REGIME_LABEL="唐朝三省制"
        echo -e "${GREEN}✓ 选择：$REGIME_LABEL${NC}"
        ;;
    3)
        REGIME_NAME="modern"
        REGIME_LABEL="现代企业制"
        echo -e "${GREEN}✓ 选择：$REGIME_LABEL${NC}"
        ;;
    *)
        echo -e "${RED}✗ 无效选择，使用明朝内阁制${NC}"
        REGIME_NAME="ming"
        REGIME_LABEL="明朝内阁制"
        ;;
esac

# ========================================
# 步骤 4: 选择 Bot 数量
# ========================================
echo ""
echo -e "${YELLOW}[4/5] 选择 Bot 数量${NC}"

if [ "$PLATFORM_NAME" = "webui" ]; then
    echo "  WebUI 模式使用单 Agent"
    BOT_CHOICE="1"
else
    # 根据制度显示不同选项
    if [ "$REGIME_NAME" = "ming" ]; then
        echo "  1) 1 Bot - 司礼监 (个人开发者)"
        echo "  2) 3 Bot - 司礼监 + 内阁 + 工部 (小团队⭐推荐)"
        echo "  3) 5 Bot - 司礼监 + 内阁 + 都察院 + 兵部 + 工部 (中型团队)"
        echo "  4) 9 Bot - 完整版 (大型团队)"
    elif [ "$REGIME_NAME" = "tang" ]; then
        echo "  1) 1 Bot - 中书省 (个人开发者)"
        echo "  2) 3 Bot - 中书省 + 门下省 + 尚书省 (小团队⭐推荐)"
        echo "  3) 11 Bot - 完整版 (大型团队)"
    else
        echo "  1) 1 Bot - CEO (个人开发者)"
        echo "  2) 3 Bot - CEO + CTO + QA (小团队⭐推荐)"
        echo "  3) 9 Bot - 完整版 (大型团队)"
    fi
    echo ""
    read -p "请选择：" BOT_CHOICE
fi

# 根据制度和选择确定配置文件
if [ "$REGIME_NAME" = "ming" ]; then
    case $BOT_CHOICE in
        1) CONFIG_TEMPLATE="openclaw-1bot.json" ;;
        2) CONFIG_TEMPLATE="openclaw-3bot.json" ;;
        3) CONFIG_TEMPLATE="openclaw-5bot.json" ;;
        *) CONFIG_TEMPLATE="openclaw.json" ;;
    esac
elif [ "$REGIME_NAME" = "tang" ]; then
    case $BOT_CHOICE in
        1) CONFIG_TEMPLATE="openclaw-1bot.json" ;;
        2) CONFIG_TEMPLATE="openclaw-3bot.json" ;;
        *) CONFIG_TEMPLATE="openclaw.json" ;;
    esac
else
    case $BOT_CHOICE in
        1) CONFIG_TEMPLATE="openclaw-1bot.json" ;;
        2) CONFIG_TEMPLATE="openclaw-3bot.json" ;;
        *) CONFIG_TEMPLATE="openclaw.json" ;;
    esac
fi

CONFIG_SOURCE="$HOME/clawd/danghuangshang/configs/feishu-$REGIME_NAME/$CONFIG_TEMPLATE"

echo -e "${GREEN}✓ 配置模板：$CONFIG_TEMPLATE${NC}"

# ========================================
# 步骤 5: 收集平台凭证
# ========================================
echo ""
echo -e "${YELLOW}[5/5] 收集平台凭证${NC}"

if [ "$PLATFORM_NAME" = "feishu" ]; then
    echo ""
    echo "请前往飞书开放平台创建应用："
    echo "https://open.feishu.cn/app"
    echo ""
    read -p "App ID: " APP_ID
    read -s -p "App Secret: " APP_SECRET
    echo ""
    
    if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
        echo -e "${RED}✗ 飞书凭证不能为空${NC}"
        exit 1
    fi
    
elif [ "$PLATFORM_NAME" = "discord" ]; then
    echo ""
    echo "请前往 Discord Developer Portal 创建 Bot："
    echo "https://discord.com/developers/applications"
    echo ""
    read -p "Bot Token: " BOT_TOKEN
    read -p "Server ID (Guild ID, 留空则所有服务器生效): " GUILD_ID
    echo ""
    
    if [ -z "$BOT_TOKEN" ]; then
        echo -e "${RED}✗ Bot Token 不能为空${NC}"
        exit 1
    fi
    
elif [ "$PLATFORM_NAME" = "webui" ]; then
    echo -e "${GREEN}✓ WebUI 模式不需要额外凭证${NC}"
    APP_ID=""
    APP_SECRET=""
    BOT_TOKEN=""
    GUILD_ID=""
fi

# ========================================
# 生成配置文件
# ========================================
echo ""
echo -e "${CYAN}⚙️ 生成配置文件...${NC}"

# 复制配置并替换占位符
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$CONFIG_DIR/$CONFIG_FILE"
    
    # 替换飞书凭证
    sed -i "s/YOUR_FEISHU_APP_ID/$APP_ID/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_FEISHU_APP_SECRET/$APP_SECRET/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_SILIJIAN_APP_ID/$APP_ID/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_SILIJIAN_APP_SECRET/$APP_SECRET/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_NEIGE_APP_ID/$APP_ID/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_NEIGE_APP_SECRET/$APP_SECRET/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_GONGBU_APP_ID/$APP_ID/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_GONGBU_APP_SECRET/$APP_SECRET/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    
    # 替换 Discord 凭证
    sed -i "s/YOUR_DISCORD_BOT_TOKEN/$BOT_TOKEN/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/YOUR_GUILD_ID/${GUILD_ID:-}/g" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || true
else
    echo -e "${YELLOW}⚠ 配置模板不存在，创建基础配置${NC}"
    # 创建基础配置
    cat > "$CONFIG_DIR/$CONFIG_FILE" << EOF
{
  "models": {
    "providers": {
      "your-provider": {
        "baseUrl": "$API_URL",
        "apiKey": "$API_KEY",
        "api": "$API_FORMAT",
        "models": [{"id": "$MODEL_ID", "name": "主模型"}]
      }
    }
  },
  "channels": {
    "feishu": {
      "enabled": $([ "$PLATFORM_NAME" = "feishu" ] && echo "true" || echo "false"),
      "accounts": {
        "silijian": {
          "appId": "$APP_ID",
          "appSecret": "$APP_SECRET",
          "name": "司礼监",
          "groupPolicy": "open"
        }
      }
    },
    "discord": {
      "enabled": $([ "$PLATFORM_NAME" = "discord" ] && echo "true" || echo "false"),
      "accounts": {
        "silijian": {
          "token": "$BOT_TOKEN",
          "name": "司礼监",
          "groupPolicy": "open"
        }
      }
    }
  },
  "gateway": {
    "mode": "local"
  }
}
EOF
fi

# 使用 Python 更新 models 配置（避免 sed 处理 JSON 的问题）
python3 << PYEOF
import json

config_file = "$CONFIG_DIR/$CONFIG_FILE"

with open(config_file, 'r') as f:
    config = json.load(f)

# 更新 models 配置
config['models'] = {
    'providers': {
        'your-provider': {
            'baseUrl': '$API_URL',
            'apiKey': '$API_KEY',
            'api': '$API_FORMAT',
            'models': [{'id': '$MODEL_ID', 'name': '主模型', 'input': ['text', 'image'], 'contextWindow': 200000, 'maxTokens': 8192}]
        }
    }
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(f"✓ 配置文件已更新：{config_file}")
PYEOF

# ========================================
# 完成
# ========================================
echo ""
echo -e "${GREEN}========================================"
echo "   安装完成！"
echo "========================================${NC}"
echo ""
echo "📋 配置信息:"
echo "  平台：$PLATFORM_NAME"
echo "  制度：$REGIME_LABEL"
echo "  配置：$CONFIG_TEMPLATE"
echo "  模型：$MODEL_ID"
echo ""
echo "🚀 下一步:"
echo "  1. 检查配置：cat $CONFIG_DIR/$CONFIG_FILE"
echo "  2. 启动服务：openclaw gateway start"
echo "  3. 查看状态：openclaw status"
echo ""
echo "📖 文档:"
echo "  https://github.com/wanikua/danghuangshang"
echo ""
