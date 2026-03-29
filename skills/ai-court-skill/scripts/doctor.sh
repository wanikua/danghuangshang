#!/bin/bash
# AI Court 安装验证脚本

echo "======================================"
echo "  AI Court 安装验证"
echo "======================================"

# 检查 OpenClaw
if command -v openclaw &>/dev/null; then
  echo "✅ OpenClaw 已安装"
else
  echo "❌ OpenClaw 未安装"
  exit 1
fi

# 检查配置文件
if [ -f "$HOME/.openclaw/openclaw.json" ]; then
  echo "✅ 配置文件存在"
  if jq empty "$HOME/.openclaw/openclaw.json" 2>/dev/null; then
    echo "✅ JSON 格式正确"
  else
    echo "❌ JSON 格式错误"
    exit 1
  fi
else
  echo "❌ 配置文件不存在"
  exit 1
fi

# 检查 Agent 人设
agent_count=$(jq '.agents.list | length' "$HOME/.openclaw/openclaw.json" 2>/dev/null)
persona_count=$(jq '[.agents.list[] | select(.identity.theme != null)] | length' "$HOME/.openclaw/openclaw.json" 2>/dev/null)
echo "✅ Agent 总数：$agent_count"
echo "✅ 已配置人设：$persona_count"

if [ "$agent_count" -eq "$persona_count" ]; then
  echo "✅ 所有 Agent 已配置人设"
else
  echo "❌ 有 $((agent_count - persona_count)) 个 Agent 缺少人设"
fi

# 检查 API Key
has_key=$(jq -r '[.models.providers[].apiKey // ""] | map(select(. != "" and . != "YOUR_LLM_API_KEY")) | length' "$HOME/.openclaw/openclaw.json" 2>/dev/null)
if [ "$has_key" -gt 0 ]; then
  echo "✅ API Key 已配置"
else
  echo "⚠️  请配置 API Key"
fi

# 检查飞书配置
has_feishu=$(jq '.channels.feishu.enabled // false' "$HOME/.openclaw/openclaw.json" 2>/dev/null)
if [ "$has_feishu" = "true" ]; then
  echo "✅ 飞书通道已启用"
fi

# 检查 Discord 配置
has_discord=$(jq '.channels.discord.enabled // false' "$HOME/.openclaw/openclaw.json" 2>/dev/null)
if [ "$has_discord" = "true" ]; then
  echo "✅ Discord 通道已启用"
fi

echo ""
echo "======================================"
echo "  验证完成！"
echo "======================================"
