#!/bin/bash
# ============================================
# 仓库清理脚本
# 
# 清理无关文件，明确项目边界
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    仓库清理脚本                      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo -e "${YELLOW}⚠️  此脚本将清理以下文件：${NC}"
echo ""
echo "  - *.tar.gz（教程包）"
echo "  - boluobobo-ai-court-tutorial/（独立仓库）"
echo "  - thinking-skills/（独立仓库）"
echo "  - meow/（独立仓库）"
echo "  - guangqi-sentinel/（独立仓库）"
echo "  - *.bak（备份文件）"
echo "  - *.log（日志文件）"
echo ""

read -p "是否继续？[y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}已取消${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}开始清理...${NC}"

# 备份重要文件
BACKUP_DIR="$HOME/clawd-backup-$(date +%Y%m%d)"
echo "创建备份目录：$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 移动文件到备份（不直接删除）
FILES_TO_MOVE=(
  "*.tar.gz"
  "boluobobo-ai-court-tutorial"
  "thinking-skills"
  "meow"
  "guangqi-sentinel"
)

for file in "${FILES_TO_MOVE[@]}"; do
  if [ -e "$file" ]; then
    echo "  移动：$file → $BACKUP_DIR/"
    mv "$file" "$BACKUP_DIR/" 2>/dev/null || true
  fi
done

# 删除备份文件
echo "删除旧备份文件（*.bak）..."
find . -maxdepth 1 -name "*.bak" -type f -delete

# 删除日志文件
echo "删除日志文件（*.log）..."
find . -maxdepth 2 -name "*.log" -type f -delete

echo ""
echo -e "${GREEN}✓ 清理完成！${NC}"
echo ""
echo "备份位置：$BACKUP_DIR"
echo "如需恢复，从备份目录复制回来即可。"
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "  git add -A"
echo "  git commit -m 'chore: 清理仓库，明确项目边界'"
echo "  git push"
echo ""
