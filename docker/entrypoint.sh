#!/bin/bash
set -e

WORKSPACE="/root/clawd"
CONFIG_DIR="/root/.openclaw"

# ---- 初始化工作区模板（仅首次）----
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
cat > "$WORKSPACE/SOUL.md" << 'EOF'
# SOUL.md - 朝廷行为准则

## 铁律
1. 废话不要多 — 说重点
2. 汇报要及时 — 做完就说
3. 做事要靠谱 — 先想后做

## 沟通风格
- 中文为主
- 直接说结论，需要细节再展开
EOF
echo "✓ SOUL.md 已创建"
fi

if [ ! -f "$WORKSPACE/IDENTITY.md" ]; then
cat > "$WORKSPACE/IDENTITY.md" << 'EOF'
# IDENTITY.md - 朝廷架构

## 六部
- 兵部：软件工程、系统架构
- 户部：财务预算、电商运营
- 礼部：品牌营销、内容创作
- 工部：DevOps、服务器运维
- 吏部：项目管理、创业孵化
- 刑部：法务合规、知识产权
EOF
echo "✓ IDENTITY.md 已创建"
fi

if [ ! -f "$WORKSPACE/USER.md" ]; then
cat > "$WORKSPACE/USER.md" << 'EOF'
# USER.md - 关于你

- **称呼:** （填你的称呼）
- **语言:** 中文
- **风格:** 简洁高效
EOF
echo "✓ USER.md 已创建"
fi

mkdir -p "$WORKSPACE/memory"

# ---- OpenViking 初始化（如果配置了）----
if [ -f "/root/.openviking/ov.conf" ] || [ -n "$OPENVIKING_CONFIG_FILE" ]; then
    echo "✓ OpenViking 配置已检测到"
    # 确保 OpenViking 数据目录存在
    mkdir -p /root/.openviking/data
fi

# ---- 提示信息 ----
if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
    echo ""
    echo "================================"
    echo "⚠ 配置文件不存在"
    echo "================================"
    echo ""
    echo "请挂载配置文件或设置环境变量："
    echo ""
    echo "  方式一：挂载配置文件"
    echo "    docker run -v ./openclaw.json:/root/.openclaw/openclaw.json ..."
    echo ""
    echo "  方式二：交互式配置"
    echo "    docker exec -it <容器名> openclaw onboard"
    echo ""
    echo "  方式三：添加单个渠道"
    echo "    docker exec -it <容器名> openclaw channels add"
    echo ""
fi

echo ""
echo "🏛️ AI 朝廷 Docker 启动中..."
echo "  工作区: $WORKSPACE"
echo "  配置: $CONFIG_DIR/openclaw.json"
echo "  WebUI: http://localhost:18789"
echo ""

exec "$@"
