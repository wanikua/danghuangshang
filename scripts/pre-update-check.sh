#!/bin/bash
# ============================================
# 更新前检查脚本
# 
# 功能:
# - 检查配置完整性
# - 检测未保存变更
# - 验证人设完整性
# - 建议是否需要备份
#
# 用法:
#   bash scripts/pre-update-check.sh
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DANGHUANGSHANG_ROOT="$(dirname "$SCRIPT_DIR")"

# 配置目录（自动检测）
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
  CONFIG_DIR="$HOME/.openclaw"
elif [ -f "$HOME/.clawdbot/openclaw.json" ]; then
  CONFIG_DIR="$HOME/.clawdbot"
  CONFIG_FILE="$CONFIG_DIR/openclaw.json"
elif [ -f "$HOME/.openclaw/openclaw.json" ]; then
  CONFIG_DIR="$HOME/.openclaw"
  CONFIG_FILE="$CONFIG_DIR/openclaw.json"
else
  echo "错误：未找到配置目录"
  exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    🔍  AI 朝廷 · 更新前检查          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

issues=0
warnings=0

# ============================================
# 检查 1: 配置文件完整性
# ============================================

echo -e "${BOLD}[1/7] 配置文件完整性...${NC}"

if [ -f "$CONFIG_FILE" ]; then
  if jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} JSON 格式正确"
  else
    echo -e "  ${RED}✗${NC} JSON 格式错误！"
    issues=$((issues + 1))
  fi
else
  echo -e "  ${RED}✗${NC} 配置文件不存在：$CONFIG_FILE"
  issues=$((issues + 1))
fi
echo ""

# ============================================
# 检查 2: Agent 人设完整性
# ============================================

echo -e "${BOLD}[2/7] Agent 人设完整性...${NC}"

if [ -f "$CONFIG_FILE" ]; then
  agent_total=$(jq '.agents.list | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  persona_total=$(jq '[.agents.list[] | select(.identity.theme != null and .identity.theme != "")] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  
  echo "  Agent 总数：$agent_total"
  echo "  已配置人设：$persona_total"
  
  if [ "$agent_total" -eq "$persona_total" ]; then
    echo -e "  ${GREEN}✓${NC} 所有 Agent 已配置人设"
  else
    echo -e "  ${RED}✗${NC} 有 $((agent_total - persona_total)) 个 Agent 缺少人设"
    issues=$((issues + 1))
  fi
  
  # 检查人设内容是否合理
  empty_personas=$(jq '[.agents.list[] | select(.identity.theme == "" or .identity.theme == null)] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  if [ "$empty_personas" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠${NC} 有 $empty_personas 个空人设"
    warnings=$((warnings + 1))
  fi
else
  echo -e "  ${YELLOW}⊘${NC} 跳过（配置文件不存在）"
fi
echo ""

# ============================================
# 检查 3: API Key 配置
# ============================================

echo -e "${BOLD}[3/7] API Key 配置...${NC}"

if [ -f "$CONFIG_FILE" ]; then
  provider_count=$(jq '.models.providers | keys | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  has_real_key=$(jq -r '[.models.providers[].apiKey // "" | select(. != "" and . != "YOUR_LLM_API_KEY" and startswith("sk-"))] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  
  echo "  配置 Provider: $provider_count"
  echo "  有效 API Key: $has_real_key"
  
  if [ "$has_real_key" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} 已配置有效 API Key"
  else
    echo -e "  ${YELLOW}⚠${NC} 未检测到有效 API Key"
    warnings=$((warnings + 1))
  fi
else
  echo -e "  ${YELLOW}⊘${NC} 跳过（配置文件不存在）"
fi
echo ""

# ============================================
# 检查 4: Discord Token 配置
# ============================================

echo -e "${BOLD}[4/7] Discord Token 配置...${NC}"

if [ -f "$CONFIG_FILE" ]; then
  discord_enabled=$(jq '.channels.discord.enabled // false' "$CONFIG_FILE" 2>/dev/null || echo "false")
  account_count=$(jq '.channels.discord.accounts | keys | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  has_real_token=$(jq -r '[.channels.discord.accounts[].token // "" | select(. != "" and length > 50)] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
  
  echo "  Discord 启用：$discord_enabled"
  echo "  Account 数量：$account_count"
  echo "  有效 Token: $has_real_token"
  
  if [ "$discord_enabled" = "true" ] && [ "$has_real_token" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} Discord 配置正常"
  elif [ "$discord_enabled" = "true" ]; then
    echo -e "  ${YELLOW}⚠${NC} Discord 已启用但 Token 可能无效"
    warnings=$((warnings + 1))
  else
    echo -e "  ${BLUE}ℹ${NC} Discord 未启用"
  fi
else
  echo -e "  ${YELLOW}⊘${NC} 跳过（配置文件不存在）"
fi
echo ""

# ============================================
# 检查 5: Gateway 状态
# ============================================

echo -e "${BOLD}[5/7] Gateway 状态...${NC}"

if command -v openclaw &>/dev/null; then
  if openclaw gateway status 2>&1 | grep -q "running"; then
    echo -e "  ${GREEN}✓${NC} Gateway 运行中"
  else
    echo -e "  ${YELLOW}⚠${NC} Gateway 未运行"
    warnings=$((warnings + 1))
  fi
else
  echo -e "  ${YELLOW}⊘${NC} OpenClaw 未安装"
fi
echo ""

# ============================================
# 检查 6: Git 状态
# ============================================

echo -e "${BOLD}[6/7] Git 状态...${NC}"

if [ -d "$DANGHUANGSHANG_ROOT/.git" ]; then
  cd "$DANGHUANGSHANG_ROOT"
  
  # 检查是否有未提交变更
  uncommitted=$(git status --porcelain 2>/dev/null | wc -l || echo 0)
  
  if [ "$uncommitted" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠${NC} 有 $uncommitted 个未提交变更"
    echo ""
    echo "     未提交文件:"
    git status --porcelain 2>/dev/null | head -10 | while read -r line; do
      echo "       $line"
    done
    warnings=$((warnings + 1))
  else
    echo -e "  ${GREEN}✓${NC} 工作区干净"
  fi
  
  # 检查是否落后于远程
  behind=$(git rev-list --left-right --count HEAD...origin/main 2>/dev/null | cut -f2 || echo 0)
  
  if [ "$behind" -gt 0 ]; then
    echo -e "  ${BLUE}ℹ${NC} 落后远程 $behind 个提交"
  else
    echo -e "  ${GREEN}✓${NC} 代码最新"
  fi
else
  echo -e "  ${YELLOW}⊘${NC} 不是 Git 仓库"
fi
echo ""

# ============================================
# 检查 7: 备份状态
# ============================================

echo -e "${BOLD}[7/7] 备份状态...${NC}"

BACKUP_DIR="$DANGHUANGSHANG_ROOT/backups"

if [ -d "$BACKUP_DIR" ]; then
  latest_backup=$(find "$BACKUP_DIR" -name "backup-manifest.*.json" -type f 2>/dev/null | sort | tail -1)
  
  if [ -n "$latest_backup" ]; then
    backup_date=$(basename "$latest_backup" | grep -o '[0-9]\{8\}_[0-9]\{6\}' || echo "unknown")
    echo -e "  最新备份：$backup_date"
    
    # 检查备份是否在 24 小时内
    # 简化检查：如果是今天的备份
    backup_today=$(echo "$backup_date" | cut -d_ -f1)
    today=$(date +%Y%m%d)
    
    if [ "$backup_today" = "$today" ]; then
      echo -e "  ${GREEN}✓${NC} 今日已备份"
    else
      echo -e "  ${YELLOW}⚠${NC} 建议先备份（上次备份超过 24 小时）"
      warnings=$((warnings + 1))
    fi
  else
    echo -e "  ${YELLOW}⊘${NC} 无备份记录"
    warnings=$((warnings + 1))
  fi
else
  echo -e "  ${YELLOW}⊘${NC} 备份目录不存在"
  warnings=$((warnings + 1))
fi
echo ""

# ============================================
# 汇总与建议
# ============================================

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

if [ "$issues" -gt 0 ]; then
  echo -e "${RED}✗ 发现 $issues 个严重问题，建议先修复！${NC}"
  echo ""
  echo "建议操作:"
  echo "  1. 修复配置错误"
  echo "  2. 运行：bash scripts/init-personas.sh"
  echo "  3. 重新检查：bash scripts/pre-update-check.sh"
  echo ""
  exit 1
elif [ "$warnings" -gt 0 ]; then
  echo -e "${YELLOW}⚠ 发现 $warnings 个警告，可以继续但建议注意${NC}"
  echo ""
  echo "建议操作:"
  if [ -d "$BACKUP_DIR" ]; then
    echo "  1. 先备份：bash scripts/backup-all.sh"
  fi
  echo "  2. 更新后验证：bash scripts/init-personas.sh"
  echo ""
  read -p "是否继续？(y/n) " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "已取消"
    exit 0
  fi
else
  echo -e "${GREEN}✓ 所有检查通过，可以安全更新！${NC}"
  echo ""
fi

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

echo "更新步骤:"
echo ""
echo "  1. 备份（可选但推荐）:"
echo "     bash scripts/backup-all.sh"
echo ""
echo "  2. 拉取更新:"
echo "     git pull"
echo ""
echo "  3. 重新注入人设:"
echo "     bash scripts/init-personas.sh"
echo ""
echo "  4. 验证配置:"
echo "     openclaw status"
echo ""
echo "  5. 重启 Gateway:"
echo "     openclaw gateway restart"
echo ""
