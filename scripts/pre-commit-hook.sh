#!/bin/bash
# ============================================
# Pre-commit Hook - API Key 泄露检测
# 
# 用法：
#   .git/hooks/pre-commit 中调用此脚本
#   或直接运行：bash scripts/pre-commit-hook.sh
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 正在检查可能的敏感信息...${NC}"

# 检测模式
PATTERNS=(
  "sk-[a-zA-Z0-9]{20,}"           # OpenAI/DashScope API Key
  "ghp_[a-zA-Z0-9]{36}"           # GitHub Personal Access Token
  "xox[baprs]-[0-9a-zA-Z-]+"      # Slack Token
  "secret_[a-zA-Z0-9]{32}"        # Notion Integration Secret
  "cli_[a-zA-Z0-9]{16}"           # 飞书 App ID
  "Bearer [a-zA-Z0-9_-]{20,}"     # Bearer Token
  "-----BEGIN RSA PRIVATE KEY-----" # 私钥
  "AKIA[0-9A-Z]{16}"              # AWS Access Key
)

FOUND_ISSUES=0

for pattern in "${PATTERNS[@]}"; do
  # 搜索暂存区文件
  if git diff --cached --name-only | xargs grep -E "$pattern" 2>/dev/null; then
    echo -e "${RED}❌ 检测到可能的敏感信息：$pattern${NC}"
    FOUND_ISSUES=1
  fi
done

# 额外检查：配置文件中的真实 API Key
CONFIG_FILES=$(git diff --cached --name-only | grep -E "openclaw\.json$|clawdbot\.json$" || true)
if [ -n "$CONFIG_FILES" ]; then
  echo -e "${YELLOW}⚠️  检测到配置文件变更，请确认不包含真实 API Key${NC}"
  
  for file in $CONFIG_FILES; do
    # 检查是否是模板文件（configs/ 下的可以提交）
    if [[ "$file" == configs/* ]]; then
      echo -e "${GREEN}✓ $file 是模板文件，允许提交${NC}"
    else
      # 检查是否包含真实 Key（非占位符）
      if git diff --cached "$file" | grep -E '"apiKey":\s*"[^"]{20,}"' | grep -v "YOUR_" | grep -v "placeholder"; then
        echo -e "${RED}❌ $file 包含疑似真实 API Key，禁止提交！${NC}"
        FOUND_ISSUES=1
      fi
    fi
  done
fi

if [ $FOUND_ISSUES -eq 1 ]; then
  echo ""
  echo -e "${RED}═══════════════════════════════════════${NC}"
  echo -e "${RED}❌ 提交被拒绝！检测到可能的敏感信息${NC}"
  echo -e "${RED}═══════════════════════════════════════${NC}"
  echo ""
  echo "请检查以上文件，确保不包含："
  echo "  - API Key（sk-xxx, ghp_xxx 等）"
  echo "  - Token（secret_xxx, Bearer xxx 等）"
  echo "  - 私钥文件"
  echo ""
  echo "如果确认是误报，可以使用 --no-verify 强制提交："
  echo "  git commit --no-verify -m \"...\""
  echo ""
  exit 1
fi

echo -e "${GREEN}✅ 未检测到敏感信息，允许提交${NC}"
exit 0
