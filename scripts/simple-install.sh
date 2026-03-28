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
CONFIG_DIR="$HOME/.openclaw"
mkdir -p "$CONFIG_DIR"

# 下载 SOUL.md
echo -e "  ${CYAN}下载 Agent 人设...${NC}"
mkdir -p "$CONFIG_DIR/agents"
for agent in silijian neige duchayuan bingbu hubu libu gongbu xingbu hanlin_zhang hanlin_xiuzhuan hanlin_bianxiu hanlin_jiantao hanlin_shujishi qijuzhu guozijian taiyiyuan neiwufu yushanfang libu2; do
  curl -fsSL "https://raw.githubusercontent.com/wanikua/danghuangshang/main/configs/$REGIME/agents/$agent.md" -o "$CONFIG_DIR/agents/$agent.md" 2>/dev/null || true
done
echo -e "  ${GREEN}✓${NC} Agent 人设已下载"

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
