#!/bin/bash
# ============================================
# AI 朝廷 · 简化安装脚本
# 用法：bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/scripts/simple-install.sh)
# ============================================

set -e
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════╗${NC}"
echo -e "${CYAN}║   AI 朝廷 · 快速安装     ║${NC}"
echo -e "${CYAN}╚══════════════════════════╝${NC}"
echo ""

# 步骤 1: 检查 OpenClaw
echo -e "${BLUE}[1/3] 检查环境...${NC}"
if ! command -v openclaw &>/dev/null; then
  echo -e "${YELLOW}⚠ OpenClaw 未安装，正在安装...${NC}"
  npm install -g openclaw@latest
fi
echo -e "${GREEN}✓${NC} OpenClaw 已安装"

# 步骤 2: 选择制度
echo -e "${BLUE}[2/3] 选择制度...${NC}"
echo "  1) 明朝内阁制 (推荐)"
echo "  2) 唐朝三省制"
echo "  3) 现代企业制"
read -p "  请选择 [1-3]: " choice
case "$choice" in
  1) REGIME="ming-neige" ;;
  2) REGIME="tang-sansheng" ;;
  3) REGIME="modern-ceo" ;;
  *) echo -e "${RED}✗ 无效选择${NC}"; exit 1 ;;
esac

# 步骤 3: 安装配置
echo -e "${BLUE}[3/3] 安装配置...${NC}"

# 确保 HOME 变量有效
if [ -z "$HOME" ]; then
  HOME=$(getent passwd "$(id -un)" | cut -d: -f6)
  [ -z "$HOME" ] && HOME="/root"
  export HOME
fi

CONFIG_DIR="${CONFIG_DIR:-$HOME/.openclaw}"
WORKSPACE="${WORKSPACE:-$HOME/clawd}"

mkdir -p "$CONFIG_DIR" || {
  echo -e "${RED}✗ 无法创建配置目录${NC}"
  exit 1
}

mkdir -p "$WORKSPACE" || {
  echo -e "${RED}✗ 无法创建工作区${NC}"
  exit 1
}

cd "$WORKSPACE"

# 创建 SOUL.md
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
  cat > "$WORKSPACE/SOUL.md" << 'SOUL_EOF'
# SOUL.md - 朝廷行为准则

## 铁律
1. 废话不要多 — 说重点
2. 汇报要及时 — 做完就说
3. 做事要靠谱 — 先想后做
SOUL_EOF
  echo -e "${GREEN}✓${NC} SOUL.md 已创建"
fi

# 创建 IDENTITY.md
if [ ! -f "$WORKSPACE/IDENTITY.md" ]; then
  cat > "$WORKSPACE/IDENTITY.md" << 'ID_EOF'
# IDENTITY.md - 身份信息

- **Name:** AI 朝廷
- **Creature:** 大明朝廷 AI 集群
- **Vibe:** 忠诚干练
- **Emoji:** 🏛️
ID_EOF
  echo -e "${GREEN}✓${NC} IDENTITY.md 已创建"
fi

# 创建 USER.md
if [ ! -f "$WORKSPACE/USER.md" ]; then
  cat > "$WORKSPACE/USER.md" << 'USER_EOF'
# USER.md - 关于你

- **称呼:** （填你的称呼）
- **语言:** 中文
USER_EOF
  echo -e "${GREEN}✓${NC} USER.md 已创建"
fi

mkdir -p "$WORKSPACE/memory"

# 下载配置
TEMPLATE_URL="https://raw.githubusercontent.com/wanikua/danghuangshang/main/configs/$REGIME/openclaw.json"
echo -e "  ${CYAN}下载配置模板...${NC}"
if curl -fsSL "$TEMPLATE_URL" -o "$CONFIG_DIR/openclaw.json" 2>/dev/null; then
  echo -e "${GREEN}✓${NC} 配置已安装：$CONFIG_DIR/openclaw.json"
else
  echo -e "${RED}✗ 下载失败${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}╔══════════════════════════╗${NC}"
echo -e "${GREEN}║   安装完成！             ║${NC}"
echo -e "${GREEN}╚══════════════════════════╝${NC}"
echo ""
echo "下一步："
echo "  1. 编辑配置：nano $CONFIG_DIR/openclaw.json"
echo "  2. 填入 API Key 和 Token"
echo "  3. 启动：openclaw start"
echo ""
