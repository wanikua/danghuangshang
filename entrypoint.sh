#!/bin/sh
# AI Court 入口脚本
# 支持连接外部 OpenClaw 服务

set -e

echo "======================================"
echo "  AI Court 启动"
echo "======================================"

# 检查是否使用外部 OpenClaw
if [ "$ENABLE_EXTERNAL_CLAW" = "true" ] || [ "$ENABLE_INTERNAL_CLAW" = "false" ]; then
    echo "📡 模式：连接外部 OpenClaw 服务"
    echo ""
    
    # 验证外部 OpenClaw 配置
    if [ -z "$OPENCLAW_HOST" ]; then
        OPENCLAW_HOST="host.docker.internal"
        echo "⚠️  OPENCLAW_HOST 未设置，使用默认值：$OPENCLAW_HOST"
    fi
    
    if [ -z "$OPENCLAW_PORT" ]; then
        OPENCLAW_PORT="18789"
        echo "⚠️  OPENCLAW_PORT 未设置，使用默认值：$OPENCLAW_PORT"
    fi
    
    echo "外部 OpenClaw 地址：http://$OPENCLAW_HOST:$OPENCLAW_PORT"
    
    # 验证连接
    echo "正在测试连接..."
    if curl -f -s --connect-timeout 5 "http://$OPENCLAW_HOST:$OPENCLAW_PORT/health" > /dev/null 2>&1; then
        echo "✅ 成功连接到外部 OpenClaw 服务"
    else
        echo "❌ 无法连接到外部 OpenClaw 服务"
        echo "   请检查："
        echo "   - OPENCLAW_HOST 是否正确"
        echo "   - OPENCLAW_PORT 是否正确"
        echo "   - 网络是否可达"
        echo ""
        echo "⚠️  继续启动 GUI（仅 GUI 模式）..."
    fi
    
    # 设置环境变量供 GUI 使用
    export CLAW_SERVER_URL="http://$OPENCLAW_HOST:$OPENCLAW_PORT"
    
    if [ -n "$OPENCLAW_API_TOKEN" ]; then
        export CLAW_API_TOKEN="$OPENCLAW_API_TOKEN"
    fi
    
    echo ""
    echo "启动 GUI 服务器..."
    echo "======================================"
    
    # 只启动 GUI，不启动内部 OpenClaw
    cd /opt/gui
    exec node server/index.js
    
else
    echo "🏠 模式：使用内部 OpenClaw 服务"
    echo ""
    
    # 启动内部 OpenClaw Gateway
    echo "启动 OpenClaw Gateway..."
    openclaw gateway --verbose &
    GATEWAY_PID=$!
    
    # 等待 Gateway 启动
    echo "等待 Gateway 就绪..."
    for i in $(seq 1 30); do
        if curl -f -s "http://localhost:18789/health" > /dev/null 2>&1; then
            echo "✅ Gateway 已就绪"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ Gateway 启动超时"
            exit 1
        fi
        sleep 1
    done
    
    echo ""
    echo "启动 GUI 服务器..."
    echo "======================================"
    
    # 启动 GUI
    cd /opt/gui
    exec node server/index.js
fi
