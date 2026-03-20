#!/bin/bash
# ============================================
# 制度切换脚本
# 用法：
#   bash switch-regime.sh              # 交互式选择
#   bash switch-regime.sh ming-neige   # 直接切换到明朝内阁制
#   bash switch-regime.sh tang-sansheng # 直接切换到唐朝三省制
#   bash switch-regime.sh modern-ceo   # 直接切换到现代企业制
# ============================================

set -e

CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}✗ 未找到配置文件：$CONFIG_FILE${NC}"
    echo "请先运行安装脚本：bash install.sh"
    exit 1
fi

# 获取当前制度
get_current_regime() {
    if command -v jq &>/dev/null; then
        jq -r '._regime // "unknown"' "$CONFIG_FILE" 2>/dev/null || echo "unknown"
    else
        grep -o '"_regime"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4 || echo "unknown"
    fi
}

CURRENT_REGIME=$(get_current_regime)

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}   AI 朝廷 · 制度切换${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

if [ -n "$1" ]; then
    TARGET_REGIME="$1"
else
    echo -e "当前制度：${GREEN}$CURRENT_REGIME${NC}"
    echo ""
    echo "选择要切换的制度："
    echo "  1) 明朝内阁制 — 司礼监 + 内阁 + 六部（快速迭代）"
    echo "  2) 唐朝三省制 — 中书→门下→尚书（制衡审核）"
    echo "  3) 现代企业制 — CEO/CTO/CFO（国际化）"
    echo ""
    read -p "请选择 [1/2/3] 或输入制度名称 [ming-neige/tang-sansheng/modern-ceo]: " REGIME_CHOICE
    
    case "$REGIME_CHOICE" in
        1|ming*|neige) TARGET_REGIME="ming-neige" ;;
        2|tang*|sansheng) TARGET_REGIME="tang-sansheng" ;;
        3|modern*|ceo) TARGET_REGIME="modern-ceo" ;;
        *)
            echo -e "${RED}✗ 无效选择${NC}"
            exit 1
            ;;
    esac
fi

# 检查配置模板是否存在
TEMPLATE="$(dirname "$SCRIPT_DIR")/configs/$TARGET_REGIME/openclaw.json"
if [ ! -f "$TEMPLATE" ]; then
    echo -e "${RED}✗ 未找到配置模板：$TEMPLATE${NC}"
    echo "请确保已克隆完整的 danghuangshang 仓库"
    exit 1
fi

# 备份当前配置
BACKUP_FILE="$CONFIG_FILE.$(date +%Y%m%d_%H%M%S).bak"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo -e "${YELLOW}✓ 已备份当前配置：$BACKUP_FILE${NC}"

# 复制新配置
cp "$TEMPLATE" "$CONFIG_FILE"

# 提取当前配置中的 API Key（如果可能）
echo ""
echo -e "${CYAN}正在切换至：${GREEN}$TARGET_REGIME${NC}"

# 提示用户更新配置
echo ""
echo -e "${GREEN}✓ 制度切换成功！${NC}"
echo ""
echo -e "${YELLOW}⚠️  请检查并更新以下配置：${NC}"
echo "  1. LLM API Key（your-provider.apiKey）"
echo "  2. Discord Bot Token（如使用 Discord）"
echo "  3. 飞书 App ID/Secret（如使用飞书）"
echo ""
echo -e "编辑配置：${CYAN}nano $CONFIG_FILE${NC}"
echo ""
echo -e "然后重启 Gateway: ${CYAN}openclaw gateway restart${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
