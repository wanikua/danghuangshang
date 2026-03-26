#!/bin/bash
# ============================================
# 从 openclaw.json 提取人设到独立文件
# 
# 用法：bash extract-personas.sh [regime]
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DANGHUANGSHANG_ROOT="$(dirname "$SCRIPT_DIR")"

REGIME="${1:-ming-neige}"
CONFIG_FILE="$DANGHUANGSHANG_ROOT/configs/$REGIME/openclaw.json"
AGENTS_DIR="$DANGHUANGSHANG_ROOT/configs/$REGIME/agents"

GREEN='\033[0;32m'
NC='\033[0m'

if [ ! -f "$CONFIG_FILE" ]; then
  echo "未找到配置文件：$CONFIG_FILE"
  exit 1
fi

mkdir -p "$AGENTS_DIR"

echo "正在从 $CONFIG_FILE 提取人设..."
echo ""

# 获取 agent 数量
agent_count=$(jq '.agents.list | length' "$CONFIG_FILE")

# 提取每个 agent 的人设
for ((i=0; i<agent_count; i++)); do
  agent_id=$(jq -r ".agents.list[$i].id" "$CONFIG_FILE")
  agent_name=$(jq -r ".agents.list[$i].name" "$CONFIG_FILE")
  persona=$(jq -r ".agents.list[$i].identity.theme // \"\"" "$CONFIG_FILE")
  
  if [ -n "$persona" ]; then
    output_file="$AGENTS_DIR/${agent_id}.md"
    
    # 写入文件（保留换行符）
    {
      echo "# $agent_name"
      echo ""
      echo "$persona"
    } > "$output_file"
    
    echo -e "${GREEN}✓${NC} $agent_id → $output_file"
  fi
done

echo ""
echo "提取完成！"
ls -la "$AGENTS_DIR"
