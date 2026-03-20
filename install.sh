#!/bin/bash
# ============================================
# danghuangshang 安装脚本
# 
# 功能：
#   1. 选择制度
#   2. 生成 openclaw.json（结构 + 人设）
#   3. 提示用户填写 API Key 和 Token
#   4. 重启 Gateway
#
# 用法：
#   bash install.sh              # 交互式安装
#   bash install.sh ming-neige   # 指定制度安装
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DANGHUANGSHANG_ROOT="$SCRIPT_DIR"
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
CLAWDBOT_CONFIG="$HOME/.clawdbot/openclaw.json"  # legacy fallback

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    🏯 AI 朝廷 · danghuangshang      ║${NC}"
echo -e "${CYAN}║        安装 / 重装向导               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 步骤 0: 检查 OpenClaw
# ============================================

echo -e "${BLUE}[1/5] 检查环境...${NC}"

if command -v openclaw &>/dev/null; then
  OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
  echo -e "  ${GREEN}✓${NC} OpenClaw 已安装: $OPENCLAW_VERSION"
else
  echo -e "  ${RED}✗${NC} OpenClaw 未安装"
  echo ""
  echo "  请先安装 OpenClaw:"
  echo "  npm install -g openclaw"
  echo ""
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo -e "  ${RED}✗${NC} jq 未安装"
  echo ""
  echo "  Ubuntu/Debian: sudo apt install jq"
  echo "  macOS: brew install jq"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} jq 已安装"

# 检测配置目录
# Config dir detection (CONFIG_FILE is updated if .clawdbot is found)
if [ -f "$CLAWDBOT_CONFIG" ] && [ ! -f "$CONFIG_FILE" ]; then

  CONFIG_FILE="$CLAWDBOT_CONFIG"
  echo -e "  ${YELLOW}i${NC} 使用 .clawdbot 配置目录"
elif [ -f "$CONFIG_FILE" ]; then
  echo -e "  ${YELLOW}i${NC} 使用 .openclaw 配置目录"
elif [ -f "$CLAWDBOT_CONFIG" ]; then

  CONFIG_FILE="$CLAWDBOT_CONFIG"
  echo -e "  ${YELLOW}i${NC} 使用 .clawdbot 配置目录"
else
  echo -e "  ${YELLOW}i${NC} 将创建新配置"
fi

echo ""

# ============================================
# 步骤 1: 选择制度
# ============================================

echo -e "${BLUE}[2/5] 选择制度...${NC}"
echo ""

if [ -n "$1" ]; then
  TARGET_REGIME="$1"
  echo -e "  使用指定制度: ${GREEN}$TARGET_REGIME${NC}"
else
  echo "  可用制度:"
  echo ""
  echo -e "  ${BOLD}1)${NC} 明朝内阁制 (ming-neige)"
  echo "     司礼监调度 → 内阁优化 → 六部执行"
  echo "     适合：快速迭代、创业团队"
  echo ""
  echo -e "  ${BOLD}2)${NC} 唐朝三省制 (tang-sansheng)"
  echo "     中书起草 → 门下审核 → 尚书执行"
  echo "     适合：严谨流程、企业级应用"
  echo ""
  echo -e "  ${BOLD}3)${NC} 现代企业制 (modern-ceo)"
  echo "     CEO/CTO/CFO 分工协作"
  echo "     适合：国际化团队"
  echo ""
  read -p "  请选择 [1/2/3]: " REGIME_CHOICE
  
  case "$REGIME_CHOICE" in
    1|ming*) TARGET_REGIME="ming-neige" ;;
    2|tang*) TARGET_REGIME="tang-sansheng" ;;
    3|modern*) TARGET_REGIME="modern-ceo" ;;
    *)
      echo -e "${RED}✗ 无效选择${NC}"
      exit 1
      ;;
  esac
fi

TEMPLATE_DIR="$DANGHUANGSHANG_ROOT/configs/$TARGET_REGIME"
TEMPLATE_CONFIG="$TEMPLATE_DIR/openclaw.json"
AGENTS_DIR="$TEMPLATE_DIR/agents"

if [ ! -f "$TEMPLATE_CONFIG" ]; then
  echo -e "${RED}✗ 未找到配置模板：$TEMPLATE_CONFIG${NC}"
  exit 1
fi

echo -e "  ${GREEN}✓${NC} 制度选定: $TARGET_REGIME"
echo ""

# ============================================
# 步骤 2: 备份现有配置
# ============================================

echo -e "${BLUE}[3/5] 配置处理...${NC}"

if [ -f "$CONFIG_FILE" ]; then
  BACKUP_FILE="${CONFIG_FILE}.$(date +%Y%m%d_%H%M%S).bak"
  cp "$CONFIG_FILE" "$BACKUP_FILE"
  echo -e "  ${YELLOW}✓${NC} 已备份现有配置: $BACKUP_FILE"
  
  # 提取现有 API Key 和 Token（以便恢复）
  EXISTING_KEYS=$(jq '{
    models_providers: .models.providers,
    discord_accounts: .channels.discord.accounts,
    signal: .channels.signal
  }' "$CONFIG_FILE" 2>/dev/null || echo "{}")
  echo -e "  ${GREEN}✓${NC} 已提取现有凭据（API Key / Token）"
else
  echo -e "  ${YELLOW}i${NC} 无现有配置，将创建新配置"
  EXISTING_KEYS="{}"
fi

echo ""

# ============================================
# 步骤 3: 生成配置（结构 + 人设注入）
# ============================================

echo -e "${BLUE}[4/5] 生成配置...${NC}"

# 复制模板
cp "$TEMPLATE_CONFIG" "$CONFIG_FILE"
echo -e "  ${GREEN}✓${NC} 已复制配置模板"

# 注入人设
if [ -d "$AGENTS_DIR" ]; then
  echo -e "  ${CYAN}正在从独立文件注入人设...${NC}"
  
  agent_count=$(jq '.agents.list | length' "$CONFIG_FILE")
  injected=0
  
  for ((i=0; i<agent_count; i++)); do
    agent_id=$(jq -r ".agents.list[$i].id" "$CONFIG_FILE")
    persona_file="$AGENTS_DIR/${agent_id}.md"
    
    if [ -f "$persona_file" ]; then
      # 读取人设内容（跳过第一行标题）
      persona=$(tail -n +3 "$persona_file")
      
      # 跳过骨架文件（<200字符 = 只有 Agent ID/定位等元信息，无实质人设）
      persona_len=${#persona}
      if [ "$persona_len" -lt 200 ]; then
        echo -e "    ${YELLOW}⚠${NC} $agent_id (人设文件太短，保留模板内置人设)"
        continue
      fi
      
      persona_escaped=$(echo "$persona" | jq -Rs '.')
      
      # 注入到配置
      jq --argjson idx "$i" --argjson persona "$persona_escaped" \
        '.agents.list[$idx].identity.theme = $persona' \
        "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
      
      echo -e "    ${GREEN}✓${NC} $agent_id"
      injected=$((injected + 1))
    else
      echo -e "    ${YELLOW}⚠${NC} $agent_id (无独立人设文件)"
    fi
  done
  
  echo -e "  ${GREEN}✓${NC} 已注入 $injected 个人设"
else
  echo -e "  ${YELLOW}i${NC} 使用模板中的内置人设"
fi

# 恢复凭据
if [ "$EXISTING_KEYS" != "{}" ]; then
  echo -e "  ${CYAN}正在恢复凭据...${NC}"
  
  # 恢复 models providers（保留 API Key）
  has_providers=$(echo "$EXISTING_KEYS" | jq '.models_providers != null' 2>/dev/null)
  if [ "$has_providers" = "true" ]; then
    jq --argjson providers "$(echo "$EXISTING_KEYS" | jq '.models_providers')" \
      '.models.providers = $providers' \
      "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "    ${GREEN}✓${NC} API Key 已恢复"
  fi
  
  # 恢复 Discord accounts（保留 Token）
  has_discord=$(echo "$EXISTING_KEYS" | jq '.discord_accounts != null' 2>/dev/null)
  if [ "$has_discord" = "true" ]; then
    jq --argjson accounts "$(echo "$EXISTING_KEYS" | jq '.discord_accounts')" \
      '.channels.discord.accounts = $accounts' \
      "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "    ${GREEN}✓${NC} Discord Token 已恢复"
  fi
  
  # 恢复 Signal 配置
  has_signal=$(echo "$EXISTING_KEYS" | jq '.signal != null' 2>/dev/null)
  if [ "$has_signal" = "true" ]; then
    jq --argjson signal "$(echo "$EXISTING_KEYS" | jq '.signal')" \
      '.channels.signal = $signal' \
      "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "    ${GREEN}✓${NC} Signal 配置已恢复"
  fi
fi

# 标记制度
jq --arg regime "$TARGET_REGIME" '._regime = $regime' \
  "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# 保护配置文件权限（含 Token 等敏感信息）
chmod 600 "$CONFIG_FILE"

echo ""

# ============================================
# 步骤 4: 验证 + 重启
# ============================================

echo -e "${BLUE}[5/5] 验证配置...${NC}"

# 验证 JSON 格式
if jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} JSON 格式正确"
else
  echo -e "  ${RED}✗${NC} JSON 格式错误！恢复备份..."
  if [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" "$CONFIG_FILE"
  fi
  exit 1
fi

# 验证 agent 数量
agent_total=$(jq '.agents.list | length' "$CONFIG_FILE")
persona_total=$(jq '[.agents.list[] | select(.identity.theme != null and .identity.theme != "")] | length' "$CONFIG_FILE")
echo -e "  Agent 总数: $agent_total"
echo -e "  已配置人设: $persona_total"

if [ "$agent_total" -eq "$persona_total" ]; then
  echo -e "  ${GREEN}✓${NC} 所有 Agent 已配置人设"
else
  echo -e "  ${YELLOW}⚠${NC} 有 $((agent_total - persona_total)) 个 Agent 缺少人设"
fi

# 检查凭据
provider_count=$(jq '.models.providers | keys | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
has_real_key=$(jq -r '[.models.providers[].apiKey // "" | select(. != "" and . != "YOUR_LLM_API_KEY")] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)

if [ "$has_real_key" -gt 0 ]; then
  echo -e "  ${GREEN}✓${NC} API Key 已配置"
else
  echo -e "  ${YELLOW}⚠${NC} 请配置 LLM API Key"
  echo -e "     ${CYAN}nano $CONFIG_FILE${NC}"
fi

echo ""

# 询问是否重启
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ 安装完成！${NC}"
echo ""
echo -e "  制度: ${GREEN}$TARGET_REGIME${NC}"
echo -e "  配置: ${CYAN}$CONFIG_FILE${NC}"
echo ""

read -p "是否立即重启 Gateway？(y/n) " RESTART_CHOICE

if [ "$RESTART_CHOICE" = "y" ] || [ "$RESTART_CHOICE" = "Y" ]; then
  echo ""
  echo "正在重启 Gateway..."
  openclaw gateway restart 2>&1 || true
  echo ""
  echo -e "${GREEN}✓ Gateway 已重启${NC}"
else
  echo ""
  echo -e "请手动重启: ${CYAN}openclaw gateway restart${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
echo "后续操作:"
echo ""
echo "  查看状态:   openclaw status"
echo "  切换制度:   bash scripts/switch-regime.sh"
echo "  恢复人设:   bash scripts/init-personas.sh"
echo "  提取人设:   bash scripts/extract-personas.sh"
echo ""
echo -e "  ${YELLOW}⚠️  Discord 建议：${NC}服务器设置 → 角色 → @everyone → 关闭「提及 @everyone」（防止 Bot 回复 ping 全员）"
echo ""
