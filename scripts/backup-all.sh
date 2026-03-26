#!/bin/bash
# ============================================
# 全量备份脚本
# 
# 备份内容:
# - openclaw.json (配置)
# - clawdbot.json (核心配置)
# - credentials/ (凭据)
# - memory/ (会话记忆)
# - agents/*/ (Agent 工作空间)
#
# 用法:
#   bash scripts/backup-all.sh              # 备份到默认位置
#   bash scripts/backup-all.sh --full       # 完整备份（含工作空间）
#   bash scripts/backup-all.sh --dry-run    # 仅显示将备份什么
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DANGHUANGSHANG_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$DANGHUANGSHANG_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 配置目录（自动检测）
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
  CONFIG_DIR="$HOME/.openclaw"
elif [ -f "$HOME/.clawdbot/openclaw.json" ]; then
  CONFIG_DIR="$HOME/.clawdbot"
elif [ -f "$HOME/.openclaw/openclaw.json" ]; then
  CONFIG_DIR="$HOME/.openclaw"
else
  echo "错误：未找到配置目录"
  exit 1
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    🛡️  AI 朝廷 · 数据备份            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# 解析参数
FULL_BACKUP=false
DRY_RUN=false

for arg in "$@"; do
  case $arg in
    --full)
      FULL_BACKUP=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
  esac
done

# 创建备份目录
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$BACKUP_DIR/configs"
  mkdir -p "$BACKUP_DIR/memory"
  if [ "$FULL_BACKUP" = true ]; then
    mkdir -p "$BACKUP_DIR/agents"
  fi
fi

# 备份计数器
backed_up=0
skipped=0
errors=0

backup_file() {
  local src="$1"
  local desc="$2"
  local dest_dir="$3"
  
  if [ ! -e "$src" ]; then
    echo -e "  ${YELLOW}⊘${NC} $desc (不存在)"
    skipped=$((skipped + 1))
    return 0
  fi
  
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${BLUE}◐${NC} $desc → $dest_dir/$(basename "$src").$TIMESTAMP"
    return 0
  fi
  
  local dest
  dest="$dest_dir/$(basename "$src").$TIMESTAMP"

  if cp -p "$src" "$dest" 2>/dev/null; then
    chmod 600 "$dest"
    echo -e "  ${GREEN}✓${NC} $desc → $dest"
    backed_up=$((backed_up + 1))
  else
    echo -e "  ${RED}✗${NC} $desc (失败)"
    errors=$((errors + 1))
  fi
}

backup_dir() {
  local src="$1"
  local desc="$2"
  local dest_dir="$3"
  
  if [ ! -d "$src" ]; then
    echo -e "  ${YELLOW}⊘${NC} $desc (不存在)"
    skipped=$((skipped + 1))
    return 0
  fi
  
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${BLUE}◐${NC} $desc → $dest_dir/$(basename "$src").$TIMESTAMP.tar.gz"
    return 0
  fi
  
  local dest
  dest="$dest_dir/$(basename "$src").$TIMESTAMP.tar.gz"

  if tar -czf "$dest" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null; then
    chmod 600 "$dest"
    echo -e "  ${GREEN}✓${NC} $desc → $dest"
    backed_up=$((backed_up + 1))
  else
    echo -e "  ${RED}✗${NC} $desc (失败)"
    errors=$((errors + 1))
  fi
}

# ============================================
# 开始备份
# ============================================

echo -e "${BLUE}配置目录:${NC} $CONFIG_DIR"
echo ""

echo -e "${CYAN}[1/5] 核心配置...${NC}"
backup_file "$CONFIG_DIR/openclaw.json" "OpenClaw 配置" "$BACKUP_DIR/configs"
backup_file "$CONFIG_DIR/clawdbot.json" "Clawdbot 配置" "$BACKUP_DIR/configs"
backup_file "$CONFIG_DIR/clawdbot.json.backup" "Clawdbot 备份" "$BACKUP_DIR/configs"
echo ""

echo -e "${CYAN}[2/5] 凭据文件...${NC}"
if [ -d "$CONFIG_DIR/credentials" ]; then
  backup_dir "$CONFIG_DIR/credentials" "凭据目录" "$BACKUP_DIR"
else
  echo -e "  ${YELLOW}⊘${NC} 凭据目录 (不存在)"
  skipped=$((skipped + 1))
fi
echo ""

echo -e "${CYAN}[3/5] 会话记忆...${NC}"
if [ -d "$CONFIG_DIR/memory" ]; then
  backup_dir "$CONFIG_DIR/memory" "记忆目录" "$BACKUP_DIR"
else
  echo -e "  ${YELLOW}⊘${NC} 记忆目录 (不存在)"
  skipped=$((skipped + 1))
fi
echo ""

echo -e "${CYAN}[4/5] 设备信息...${NC}"
backup_file "$CONFIG_DIR/devices/devices.json" "设备列表" "$BACKUP_DIR/configs"
echo ""

if [ "$FULL_BACKUP" = true ]; then
  echo -e "${CYAN}[5/5] Agent 工作空间...${NC}"
  if [ -d "$CONFIG_DIR/agents" ]; then
    backup_dir "$CONFIG_DIR/agents" "Agent 工作空间" "$BACKUP_DIR"
  else
    echo -e "  ${YELLOW}⊘${NC} Agent 工作空间 (不存在)"
    skipped=$((skipped + 1))
  fi
  echo ""
else
  echo -e "${YELLOW}跳过 Agent 工作空间（使用 --full 包含）${NC}"
  echo ""
fi

# ============================================
# 清理旧备份
# ============================================

echo -e "${CYAN}清理旧备份...${NC}"

if [ "$DRY_RUN" = false ]; then
  # 保留最近 30 天的配置备份
  find "$BACKUP_DIR/configs" -name "*.json.*" -mtime +30 -delete 2>/dev/null || true
  
  # 保留最近 7 天的完整备份
  find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
  
  echo -e "  ${GREEN}✓${NC} 已清理过期备份"
else
  echo -e "  ${BLUE}◐${NC} 将清理 30 天前的配置备份和 7 天前的完整备份"
fi
echo ""

# ============================================
# 生成备份清单
# ============================================

if [ "$DRY_RUN" = false ]; then
  MANIFEST="$BACKUP_DIR/backup-manifest.$TIMESTAMP.json"
  
  cat > "$MANIFEST" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "date": "$(date -Iseconds)",
  "config_dir": "$CONFIG_DIR",
  "backup_type": "$([ "$FULL_BACKUP" = true ] && echo "full" || echo "standard")",
  "stats": {
    "backed_up": $backed_up,
    "skipped": $skipped,
    "errors": $errors
  },
  "files": [
EOF
  
  find "$BACKUP_DIR" -name "*.$TIMESTAMP*" -type f | while read -r file; do
    echo "    \"$file\"," >> "$MANIFEST"
  done
  
  cat >> "$MANIFEST" <<EOF
  ]
}
EOF
  
  echo -e "${GREEN}✓ 备份清单：$MANIFEST${NC}"
  echo ""
fi

# ============================================
# 汇总
# ============================================

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

if [ "$errors" -gt 0 ]; then
  echo -e "${RED}✗ 备份完成，但有 $errors 个错误${NC}"
elif [ "$backed_up" -gt 0 ]; then
  echo -e "${GREEN}✓ 备份成功！${NC}"
else
  echo -e "${YELLOW}⚠ 没有可备份的内容${NC}"
fi

echo ""
echo "  已备份：$backed_up 项"
echo "  已跳过：$skipped 项"
echo "  错误：$errors 项"
echo ""
echo -e "备份目录：${CYAN}$BACKUP_DIR${NC}"
echo ""

if [ "$DRY_RUN" = false ] && [ "$backed_up" -gt 0 ]; then
  echo -e "${YELLOW}提示：${NC}"
  echo "  - 查看备份：ls -la $BACKUP_DIR"
  echo "  - 恢复配置：cp $BACKUP_DIR/configs/openclaw.json.* ~/.openclaw/openclaw.json"
  echo "  - 恢复记忆：tar -xzf $BACKUP_DIR/memory.*.tar.gz -C ~/.openclaw/"
  echo ""
fi

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# 返回错误码
if [ "$errors" -gt 0 ]; then
  exit 1
fi
