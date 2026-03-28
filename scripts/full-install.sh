#!/bin/bash
# ============================================
# danghuangshang 完整安装脚本（支持远程执行）
# 
# 用法：
#   bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/scripts/full-install.sh)
# ============================================

set -e

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
echo -e "${CYAN}║        完整安装向导                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 步骤 0: 克隆仓库（如果是远程执行）
# ============================================

echo -e "${BLUE}[0/6] 准备环境...${NC}"

INSTALL_DIR="$HOME/danghuangshang-installer"

if [ -d "$INSTALL_DIR" ]; then
  echo -e "  ${YELLOW}i${NC} 清理旧安装目录"
  rm -rf "$INSTALL_DIR"
fi

echo -e "  ${CYAN}正在克隆仓库...${NC}"
git clone --depth 1 https://github.com/wanikua/danghuangshang.git "$INSTALL_DIR"
echo -e "  ${GREEN}✓${NC} 仓库已克隆到：$INSTALL_DIR"

cd "$INSTALL_DIR"

# ============================================
# 步骤 1: 检查 OpenClaw
# ============================================

echo ""
echo -e "${BLUE}[1/6] 检查环境...${NC}"

if command -v openclaw &>/dev/null; then
  OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
  echo -e "  ${GREEN}✓${NC} OpenClaw 已安装：$OPENCLAW_VERSION"
else
  echo -e "  ${RED}✗${NC} OpenClaw 未安装"
  echo ""
  echo "  正在安装 OpenClaw..."
  npm install -g openclaw
  echo -e "  ${GREEN}✓${NC} OpenClaw 已安装"
fi

if ! command -v jq &>/dev/null; then
  echo -e "  ${YELLOW}⚠${NC} jq 未安装，正在安装..."
  if command -v apt &>/dev/null; then
    sudo apt update && sudo apt install -y jq
  elif command -v brew &>/dev/null; then
    brew install jq
  else
    echo -e "  ${RED}✗${NC} 请手动安装 jq"
    exit 1
  fi
  echo -e "  ${GREEN}✓${NC} jq 已安装"
else
  echo -e "  ${GREEN}✓${NC} jq 已安装"
fi

echo ""

# ============================================
# 步骤 2: 选择制度
# ============================================

echo -e "${BLUE}[2/6] 选择制度...${NC}"
echo ""

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

TEMPLATE_DIR="$INSTALL_DIR/configs/$TARGET_REGIME"
TEMPLATE_CONFIG="$TEMPLATE_DIR/openclaw.json"
AGENTS_DIR="$TEMPLATE_DIR/agents"

if [ ! -f "$TEMPLATE_CONFIG" ]; then
  echo -e "${RED}✗ 未找到配置模板：$TEMPLATE_CONFIG${NC}"
  exit 1
fi

echo -e "  ${GREEN}✓${NC} 制度选定：$TARGET_REGIME"
echo ""

# ============================================
# 步骤 3: 备份现有配置
# ============================================

echo -e "${BLUE}[3/6] 配置处理...${NC}"

CONFIG_DIR="$HOME/.openclaw"
CLAWDBOT_CONFIG="$HOME/.clawdbot/openclaw.json"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

# 检测配置目录
if [ -f "$CLAWDBOT_CONFIG" ] && [ ! -f "$CONFIG_FILE" ]; then
  CONFIG_DIR="$HOME/.clawdbot"
  CONFIG_FILE="$CLAWDBOT_CONFIG"
  echo -e "  ${YELLOW}i${NC} 使用 .clawdbot 配置目录"
elif [ -f "$CONFIG_FILE" ]; then
  echo -e "  ${YELLOW}i${NC} 使用 .openclaw 配置目录"
elif [ -f "$CLAWDBOT_CONFIG" ]; then
  CONFIG_DIR="$HOME/.clawdbot"
  CONFIG_FILE="$CLAWDBOT_CONFIG"
  echo -e "  ${YELLOW}i${NC} 使用 .clawdbot 配置目录"
else
  echo -e "  ${YELLOW}i${NC} 将创建新配置"
fi

if [ -f "$CONFIG_FILE" ]; then
  BACKUP_FILE="${CONFIG_FILE}.$(date +%Y%m%d_%H%M%S).bak"
  cp "$CONFIG_FILE" "$BACKUP_FILE"
  echo -e "  ${YELLOW}✓${NC} 已备份现有配置：$BACKUP_FILE"
  
  # 提取现有凭据
  EXISTING_KEYS=$(jq '{
    models_providers: .models.providers,
    discord_accounts: .channels.discord.accounts,
    signal: .channels.signal
  }' "$CONFIG_FILE" 2>/dev/null || echo "{}")
  echo -e "  ${GREEN}✓${NC} 已提取现有凭据（API Key / Token）"
else
  EXISTING_KEYS="{}"
fi

echo ""

# ============================================
# 步骤 4: 生成配置
# ============================================

echo -e "${BLUE}[4/6] 生成配置...${NC}"

# 原子操作：先复制到临时文件
TEMP_CONFIG="${CONFIG_FILE}.tmp.$$"
cp "$TEMPLATE_CONFIG" "$TEMP_CONFIG" || {
  echo -e "  ${RED}✗ 复制模板失败${NC}"
  exit 1
}
echo -e "  ${GREEN}✓${NC} 已复制配置模板（临时）"

# 保存原路径，后续操作在临时文件上
CONFIG_FILE_ORIG="$CONFIG_FILE"
CONFIG_FILE="$TEMP_CONFIG"

# 注入人设
if [ -d "$AGENTS_DIR" ]; then
  echo -e "  ${CYAN}正在从独立文件注入人设...${NC}"
  
  agent_count=$(jq '.agents.list | length' "$CONFIG_FILE")
  injected=0
  
  for ((i=0; i<agent_count; i++)); do
    agent_id=$(jq -r ".agents.list[$i].id" "$CONFIG_FILE")
    persona_file="$AGENTS_DIR/${agent_id}.md"
    
    if [ -f "$persona_file" ]; then
      persona=$(tail -n +3 "$persona_file")
      persona_escaped=$(echo "$persona" | jq -Rs '.')
      
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
  
  has_providers=$(echo "$EXISTING_KEYS" | jq '.models_providers != null' 2>/dev/null)
  if [ "$has_providers" = "true" ]; then
    jq --argjson providers "$(echo "$EXISTING_KEYS" | jq '.models_providers')" \
      '.models.providers = $providers' \
      "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "    ${GREEN}✓${NC} API Key 已恢复"
  fi
  
  has_discord=$(echo "$EXISTING_KEYS" | jq '.discord_accounts != null' 2>/dev/null)
  if [ "$has_discord" = "true" ]; then
    jq --argjson accounts "$(echo "$EXISTING_KEYS" | jq '.discord_accounts')" \
      '.channels.discord.accounts = $accounts' \
      "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo -e "    ${GREEN}✓${NC} Discord Token 已恢复"
  fi
  
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

# 验证临时配置
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo -e "  ${RED}✗ 配置验证失败${NC}"
  if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    echo -e "  ${YELLOW}✓${NC} 恢复原配置..."
    cp "$BACKUP_FILE" "$CONFIG_FILE_ORIG"
  fi
  rm -f "$CONFIG_FILE"
  exit 1
fi

# 原子提交：临时文件 → 正式配置
mv "$CONFIG_FILE" "$CONFIG_FILE_ORIG"
CONFIG_FILE="$CONFIG_FILE_ORIG"
echo -e "  ${GREEN}✓${NC} 配置已提交"

echo ""

# ============================================
# 步骤 5: 安装项目依赖
# ============================================

echo -e "${BLUE}[5/7] 安装依赖...${NC}"

echo -e "  ${CYAN}正在安装项目依赖...${NC}"
cd "$INSTALL_DIR"
if [ -f "package.json" ]; then
  npm install --loglevel=error
  echo -e "  ${GREEN}✓${NC} 项目依赖已安装"
else
  echo -e "  ${YELLOW}⚠${NC} package.json 不存在，跳过项目依赖安装"
  echo -e "  ${CYAN}提示：请检查仓库是否完整克隆${NC}"
fi

echo ""

# ============================================
# 步骤 6: 验证配置
# ============================================

echo -e "${BLUE}[6/7] 验证配置...${NC}"

if jq empty "$CONFIG_FILE" 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} JSON 格式正确"
else
  echo -e "  ${RED}✗${NC} JSON 格式错误！恢复备份..."
  if [ -f "$BACKUP_FILE" ]; then
    cp "$BACKUP_FILE" "$CONFIG_FILE"
  fi
  exit 1
fi

agent_total=$(jq '.agents.list | length' "$CONFIG_FILE")
persona_total=$(jq '[.agents.list[] | select(.identity.theme != null and .identity.theme != "")] | length' "$CONFIG_FILE")
echo -e "  Agent 总数：$agent_total"
echo -e "  已配置人设：$persona_total"

if [ "$agent_total" -eq "$persona_total" ]; then
  echo -e "  ${GREEN}✓${NC} 所有 Agent 已配置人设"
else
  echo -e "  ${YELLOW}⚠${NC} 有 $((agent_total - persona_total)) 个 Agent 缺少人设"
fi

has_real_key=$(jq -r '[.models.providers[].apiKey // "" | select(. != "" and . != "YOUR_LLM_API_KEY")] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)

if [ "$has_real_key" -gt 0 ]; then
  echo -e "  ${GREEN}✓${NC} API Key 已配置"
else
  echo -e "  ${YELLOW}⚠${NC} 请配置 LLM API Key"
  echo -e "     ${CYAN}nano $CONFIG_FILE${NC}"
fi

echo ""

# ============================================
# 步骤 7: 重启 Gateway
# ============================================

echo -e "${BLUE}[7/7] 重启服务...${NC}"

read -p "是否立即重启 Gateway？(y/n) " RESTART_CHOICE

if [ "$RESTART_CHOICE" = "y" ] || [ "$RESTART_CHOICE" = "Y" ]; then
  echo ""
  echo "正在重启 Gateway..."
  openclaw gateway restart 2>&1 || true
  echo -e "  ${GREEN}✓${NC} Gateway 已重启"
else
  echo -e "  ${YELLOW}i${NC} 请手动重启：${CYAN}openclaw gateway restart${NC}"
fi

echo ""

# ============================================
# 完成
# ============================================

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ 安装完成！${NC}"
echo ""
echo -e "  制度：${GREEN}$TARGET_REGIME${NC}"
echo -e "  配置：${CYAN}$CONFIG_FILE${NC}"
echo -e "  临时安装目录：${YELLOW}$INSTALL_DIR${NC}"
echo ""
read -p "是否删除临时安装目录？(y/n) " CLEANUP
if [ "$CLEANUP" = "y" ] || [ "$CLEANUP" = "Y" ]; then
  rm -rf "$INSTALL_DIR"
  echo -e "  ${GREEN}✓${NC} 已清理临时目录"
fi
echo ""
echo "后续操作:"
echo ""
echo "  查看状态：${CYAN}openclaw status${NC}"
echo "  切换制度：${CYAN}bash $INSTALL_DIR/scripts/switch-regime.sh${NC}"
echo "  恢复人设：${CYAN}bash $INSTALL_DIR/scripts/init-personas.sh${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
