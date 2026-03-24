#!/bin/bash
# ============================================
# AI 朝廷精简配置脚本（适用于已装好 OpenClaw 的用户）
# 跳过系统依赖，只初始化工作区 + 生成配置模板
#
# 用法:
#   bash install-lite.sh              # 交互式安装
#   bash install-lite.sh --no-gui     # 跳过 Dashboard Web UI
#   bash install-lite.sh --with-gui   # 包含 Dashboard Web UI
# ============================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- 解析命令行参数 ----
INSTALL_GUI=""
for arg in "$@"; do
    case "$arg" in
        --no-gui)  INSTALL_GUI="no" ;;
        --with-gui) INSTALL_GUI="yes" ;;
    esac
done

echo ""
echo -e "${BLUE}🏛️ AI 朝廷 — 精简配置${NC}"
echo "================================"
echo -e "适用于已安装 OpenClaw 的用户"
echo ""

# ---- 检查 OpenClaw 是否已安装 ----
if command -v openclaw &>/dev/null; then
    CLI_CMD="openclaw"
    echo -e "  ${GREEN}✓ 检测到 OpenClaw $(openclaw --version 2>/dev/null)${NC}"
else
    echo -e "  ${RED}✗ 未检测到 OpenClaw${NC}"
    echo ""
    echo "请先安装："
    echo "  npm install -g openclaw@latest"
    echo ""
    echo "或使用完整安装脚本："
    echo "  bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)"
    exit 1
fi

# ---- 选择模式 ----
echo ""
echo -e "${CYAN}选择部署模式：${NC}"
echo "  1) Discord 多Bot模式（完整六部，需要创建 Discord Bot）"
echo "  2) 飞书单Bot模式（只需 1 个飞书应用，sessions_spawn 后台调度）"
echo "  3) 纯 WebUI 模式（不需要 Discord/飞书，浏览器直接用）"
echo ""
if [ -t 0 ]; then
    read -p "请选择 [1/2/3]（默认1）: " MODE_CHOICE
else
    MODE_CHOICE=""
fi
MODE_CHOICE=${MODE_CHOICE:-1}

# ---- 是否安装 Dashboard Web UI ----
if [ -z "$INSTALL_GUI" ]; then
    echo ""
    echo -e "${CYAN}是否安装 Dashboard Web UI（朝廷可视化面板）？${NC}"
    echo "  Dashboard 提供会话管理、Token 统计、系统监控等功能。"
    echo "  如果只需要 CLI / Discord 交互，可以跳过。"
    echo ""
    if [ -t 0 ]; then
        read -p "安装 Dashboard？[y/N]: " GUI_CHOICE
    else
        GUI_CHOICE=""
    fi
    case "$GUI_CHOICE" in
        [yY]|[yY][eE][sS]) INSTALL_GUI="yes" ;;
        *) INSTALL_GUI="no" ;;
    esac
fi

echo ""

# ---- 初始化工作区 ----
echo -e "${YELLOW}[1/5] 初始化朝廷工作区...${NC}"
WORKSPACE="$HOME/clawd"
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="openclaw.json"
mkdir -p "$WORKSPACE"
mkdir -p "$CONFIG_DIR"
cd "$WORKSPACE"

# SOUL.md
if [ ! -f SOUL.md ]; then
cat > SOUL.md.example << 'SOUL_EOF'
# SOUL.md - 朝廷行为准则

## 铁律
1. 废话不要多 — 说重点
2. 汇报要及时 — 做完就说
3. 做事要靠谱 — 先想后做

## 沟通风格
- 中文为主
- 直接说结论，需要细节再展开

## 朝廷架构
- 司礼监：日常调度、任务分配
- 内阁：战略决策、方案审议、全局规划
- 都察院：监察审计、代码审查、质量把控
- 兵部：软件工程、系统架构
- 户部：财务预算、电商运营
- 礼部：品牌营销、内容创作
- 工部：DevOps、服务器运维
- 吏部：项目管理、创业孵化
- 刑部：法务合规、知识产权
- 翰林院：学术研究、知识整理、文档撰写
- 国子监：教育培训、知识管理、学习规划
- 太医院：健康管理、饮食营养、训练计划
- 内务府：日常起居、日程安排、后勤保障
- 御膳房：膳食安排、美食推荐、食谱研究

## 模型分层
| 层级 | 模型 | 说明 |
|---|---|---|
| 调度层 | 快速模型 | 日常对话，快速响应 |
| 执行层（重） | 强力模型 | 编码、深度分析 |
| 执行层（轻） | 经济模型（可选） | 轻量任务，省钱 |
SOUL_EOF
echo -e "  ${GREEN}✓ SOUL.md.example 已创建（如需自定义人设请重命名为 SOUL.md）${NC}"
else
echo -e "  ${GREEN}✓ SOUL.md 已存在，跳过${NC}"
fi

# IDENTITY.md
if [ ! -f IDENTITY.md ]; then
cat > IDENTITY.md << 'ID_EOF'
# IDENTITY.md - 身份信息

- **Name:** AI朝廷
- **Creature:** 大明朝廷 AI 集群
- **Vibe:** 忠诚干练、各司其职
- **Emoji:** 🏛️

## 核心定位
你是「菠萝王朝」AI 朝廷集群的一员。各部门各司其职，协同处理主公交代的任务。
以大明朝廷为架构蓝本，AI Agent 扮演各部门角色，在 Discord/飞书等平台上为用户服务。
ID_EOF
echo -e "  ${GREEN}✓ IDENTITY.md 已创建${NC}"
else
echo -e "  ${GREEN}✓ IDENTITY.md 已存在，跳过${NC}"
fi

# USER.md
if [ ! -f USER.md ]; then
cat > USER.md << 'USER_EOF'
# USER.md - 关于你

- **称呼:** （填你的称呼）
- **语言:** 中文
- **风格:** 简洁高效
USER_EOF
echo -e "  ${GREEN}✓ USER.md 已创建${NC}"
else
echo -e "  ${GREEN}✓ USER.md 已存在，跳过${NC}"
fi

# memory 目录
mkdir -p memory

# 创建各 agent 独立工作区（配置写完后再创建，这里先定义函数）
create_agent_workspaces() {
  local config_file="$CONFIG_DIR/$CONFIG_FILE"
  if [ -f "$config_file" ] && command -v jq &>/dev/null; then
    local workspaces
    workspaces=$(jq -r '.agents.list[]? | "\(.id):\(.workspace // empty)"' "$config_file" 2>/dev/null)
    for entry in $workspaces; do
      local aws="${entry##*:}"
      aws="${aws/\$HOME/$HOME}"
      if [ -n "$aws" ] && [ "$aws" != "$WORKSPACE" ]; then
        mkdir -p "$aws/memory"
        [ ! -f "$aws/USER.md" ] && echo -e "# USER.md\n\n- **Name:** 皇上\n- **Language:** 中文" > "$aws/USER.md"
        [ ! -f "$aws/AGENTS.md" ] && echo -e "# AGENTS.md\n\n读 SOUL.md 了解你是谁，读 USER.md 了解你服务的人。" > "$aws/AGENTS.md"
      fi
    done
    echo -e "  ${GREEN}✓ 各部门独立工作区已创建${NC}"
  fi
}



# ---- 生成配置文件 ----
echo -e "${YELLOW}[2/5] 生成配置文件...${NC}"

# 注意：配置从 GitHub 模板下载并自动适配部署模式。
# 模板来源: configs/ming-neige/openclaw.json
# 详见: https://github.com/wanikua/danghuangshang

# ---- 从 GitHub 下载配置模板并按模式适配 ----
TEMPLATE_RAW_URL="https://raw.githubusercontent.com/wanikua/danghuangshang/main/configs/ming-neige/openclaw.json"

generate_config_from_template() {
  local mode="$1"       # webui | feishu | discord
  local output="$2"     # output file path

  echo -e "  ${CYAN}正在从 GitHub 下载配置模板...${NC}"
  local template
  template=$(curl -fsSL "$TEMPLATE_RAW_URL" 2>/dev/null || true)

  # Validate JSON via Node.js
  if [ -n "$template" ] && echo "$template" | node -e "try{JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'))}catch(e){process.exit(1)}" 2>/dev/null; then
    echo -e "  ${GREEN}✓ 配置模板下载成功${NC}"
  else
    echo -e "  ${YELLOW}⚠ 模板下载失败，使用内置最小配置${NC}"
    node -e "
      var c = {
        models:{providers:{'your-provider':{baseUrl:'https://your-llm-provider-api-url',apiKey:'YOUR_LLM_API_KEY',api:'openai',models:[{id:'fast-model',name:'快速模型',input:['text','image'],contextWindow:200000,maxTokens:8192}]}}},
        gateway:{mode:'local',port:18789},
        agents:{defaults:{workspace:process.env.HOME+'/clawd',skipBootstrap:true,model:{primary:'your-provider/fast-model'}},list:[{id:'silijian',name:'司礼监',identity:{theme:'你是AI朝廷的总管，负责日常对话和任务调度。回答用中文，简洁高效。'}}]}
      };
      process.stdout.write(JSON.stringify(c,null,2)+'\n');
    " > "$output"
    chmod 600 "$output"
    return
  fi

  # Apply mode-specific overlay via Node.js
  echo "$template" | node -e "
    var fs = require('fs');
    var config = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
    var mode = process.argv[1];
    var home = process.env.HOME || '/root';

    if (mode === 'webui') {
      config.agents.list = config.agents.list.filter(function(a){return a.id==='silijian'});
      if (config.agents.list[0]) {
        config.agents.list[0].identity = {theme:'你是AI朝廷的总管，负责日常对话和任务调度。回答用中文，简洁高效。'};
        delete config.agents.list[0].subagents;
        delete config.agents.list[0].runTimeoutSeconds;
      }
      if (config.agents.defaults) delete config.agents.defaults.sandbox;
      delete config.channels;
      config.bindings = [{agentId:'silijian',match:{}}];
    } else if (mode === 'feishu') {
      if (config.channels) delete config.channels.discord;
      if (!config.channels) config.channels = {};
      config.channels.feishu = {
        enabled:true, dmPolicy:'open', groupPolicy:'open',
        accounts:{silijian:{appId:'YOUR_FEISHU_APP_ID',appSecret:'YOUR_FEISHU_APP_SECRET',name:'司礼监',groupPolicy:'open'}}
      };
      config.bindings = [{agentId:'silijian',match:{channel:'feishu',accountId:'silijian'}}];
      // Adjust silijian theme for sessions_spawn mode
      var sj = config.agents.list.find(function(a){return a.id==='silijian'});
      if (sj && sj.identity && sj.identity.theme) {
        sj.identity.theme = sj.identity.theme
          .replace(/在当前频道[^。]*公开可见/g, '使用 sessions_spawn 后台调度')
          .replace(/用 message 工具[^。]*下达任务/g, '使用 sessions_spawn 将任务派发给对应部门的 agentId')
          .replace(/禁止用 sessions_spawn[^。]*。/g, '');
      }
    } else {
      // discord: strip feishu channel
      if (config.channels && config.channels.feishu) delete config.channels.feishu;
    }

    // Expand \$HOME to actual home directory
    var out = JSON.stringify(config, null, 2).split('\$HOME').join(home);
    process.stdout.write(out + '\n');
  " "$mode" > "$output"

  if [ $? -eq 0 ]; then
    chmod 600 "$output"
    echo -e "  ${GREEN}✓ ${mode} 模式配置已生成${NC}"
  else
    echo -e "  ${RED}✗ 配置生成失败${NC}"
    return 1
  fi
}

if [ -f "$CONFIG_DIR/$CONFIG_FILE" ]; then
    echo -e "  ${YELLOW}⚠ 配置文件已存在，跳过生成（避免覆盖你的修改）${NC}"
    echo -e "  ${CYAN}↳ 如需重新生成，先备份后删除: mv $CONFIG_DIR/$CONFIG_FILE $CONFIG_DIR/${CONFIG_FILE}.bak${NC}"
else
    case "$MODE_CHOICE" in
        3) CONFIG_MODE="webui" ;;
        2) CONFIG_MODE="feishu" ;;
        *) CONFIG_MODE="discord" ;;
    esac
    generate_config_from_template "$CONFIG_MODE" "$CONFIG_DIR/$CONFIG_FILE"
fi


# ---- 注入人设（从 agents/*.md 文件）----
echo ""
echo -e "${YELLOW}[2.5/5] 注入人设...${NC}"
TEMPLATE_AGENTS_DIR="$WORKSPACE/configs/ming-neige/agents"
if [ -d "$TEMPLATE_AGENTS_DIR" ] && [ -f "$CONFIG_DIR/$CONFIG_FILE" ]; then
  echo -e "  ${CYAN}正在从独立文件注入人设...${NC}"
  
  agent_count=$(jq '.agents.list | length' "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null || echo "0")
  injected=0
  
  for ((i=0; i<agent_count; i++)); do
    agent_id=$(jq -r ".agents.list[$i].id" "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null)
    persona_file="$TEMPLATE_AGENTS_DIR/${agent_id}.md"
    
    if [ -f "$persona_file" ]; then
      persona=$(tail -n +3 "$persona_file")
      persona_escaped=$(echo "$persona" | jq -Rs '.')
      
      jq --argjson idx "$i" --argjson persona "$persona_escaped" \
        ".agents.list[$idx].identity.theme = \$persona" \
        "$CONFIG_DIR/$CONFIG_FILE" > "${CONFIG_DIR}/${CONFIG_FILE}.tmp" && mv "${CONFIG_DIR}/${CONFIG_FILE}.tmp" "$CONFIG_DIR/$CONFIG_FILE"
      
      echo -e "    ${GREEN}✓${NC} $agent_id"
      injected=$((injected + 1))
    fi
  done
  
  echo -e "  ${GREEN}✓${NC} 已注入 $injected 个人设"
else
  echo -e "  ${YELLOW}⚠${NC} 人设目录不存在，使用模板中的内置人设"
fi

# ---- 安装项目依赖 ----
echo ""
echo -e "${YELLOW}[3/5] 安装项目依赖...${NC}"
echo -e "  ${CYAN}正在安装主项目依赖...${NC}"
cd "$WORKSPACE"
npm install --loglevel=error
echo -e "  ${GREEN}✓${NC} 项目依赖已安装"

# ---- 安装默认 Skill: self-improving ----
echo ""
echo -e "${CYAN}安装默认 Skill...${NC}"
if ! command -v clawdhub &>/dev/null; then
  npm install -g clawdhub 2>/dev/null || true
fi
if command -v clawdhub &>/dev/null; then
  # 主工作区
  clawdhub install self-improving --workdir "$WORKSPACE" --force 2>/dev/null && \
    echo -e "  ${GREEN}✓ self-improving 已安装到主工作区${NC}" || \
    echo -e "  ${YELLOW}⚠ 主工作区 skill 安装失败，可稍后手动安装: clawdhub install self-improving${NC}"
  mkdir -p "$WORKSPACE/.learnings"
  # 各部门工作区
  if [ -f "$CONFIG_DIR/$CONFIG_FILE" ] && command -v jq &>/dev/null; then
    SKILL_AGENT_WORKSPACES=$(jq -r '.agents.list[]? | .workspace // empty' "$CONFIG_DIR/$CONFIG_FILE" 2>/dev/null)
    echo "$SKILL_AGENT_WORKSPACES" | while IFS= read -r SKILL_WS; do
      [ -z "$SKILL_WS" ] && continue
      SKILL_WS="${SKILL_WS/\$HOME/$HOME}"
      [ "$SKILL_WS" = "$WORKSPACE" ] && continue
      clawdhub install self-improving --workdir "$SKILL_WS" --force 2>/dev/null
      mkdir -p "$SKILL_WS/.learnings"
    done
    echo -e "  ${GREEN}✓ self-improving 已安装到所有工作区${NC}"
  fi
else
  echo -e "  ${YELLOW}⚠ clawdhub 未安装，跳过 skill 安装。安装后运行: clawdhub install self-improving${NC}"
fi


# ---- 可选：安装 Dashboard Web UI ----
echo -e "${YELLOW}[4/5] Dashboard Web UI...${NC}"
if [ "$INSTALL_GUI" = "yes" ]; then
    REPO_URL="https://github.com/wanikua/danghuangshang"
    GUI_DIR="$WORKSPACE/gui"
    if [ -d "$GUI_DIR" ]; then
        echo -e "  ${GREEN}✓ gui/ 目录已存在，跳过克隆${NC}"
    else
        echo -e "  ${CYAN}正在下载 Dashboard...${NC}"
        # 只克隆 gui 目录
        # SEC-08: 使用 mktemp 创建安全临时目录，避免符号链接竞态
        BOLUO_GUI_TMP=$(mktemp -d /tmp/boluo_gui_XXXXXX)
        git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$BOLUO_GUI_TMP" 2>/dev/null || true
        cd "$BOLUO_GUI_TMP" && git sparse-checkout set gui 2>/dev/null || true
        if [ -d "$BOLUO_GUI_TMP/gui" ]; then
            cp -r "$BOLUO_GUI_TMP/gui" "$GUI_DIR"
            rm -rf "$BOLUO_GUI_TMP"
            echo -e "  ${GREEN}✓ Dashboard 已下载到 $GUI_DIR${NC}"
        else
            rm -rf "$BOLUO_GUI_TMP"
            echo -e "  ${YELLOW}⚠ Dashboard 下载失败，可稍后手动安装${NC}"
        fi
    fi
    # 安装依赖
    if [ -d "$GUI_DIR" ] && [ -f "$GUI_DIR/package.json" ]; then
        cd "$GUI_DIR"
        if command -v npm &>/dev/null; then
            npm install --silent 2>/dev/null && echo -e "  ${GREEN}✓ Dashboard 依赖已安装${NC}" || echo -e "  ${YELLOW}⚠ npm install 失败，请手动运行: cd $GUI_DIR && npm install${NC}"
        fi
        cd "$WORKSPACE"
    fi
else
    echo -e "  ${CYAN}跳过 Dashboard 安装（可后续用 --with-gui 安装）${NC}"
fi

# ---- 完成提示 ----
echo -e "${YELLOW}[5/5] 配置完成！${NC}"
echo ""
echo "================================"
echo -e "${GREEN}🎉 工作区初始化完成！${NC}"
echo "================================"
echo ""
echo -e "  工作区：${CYAN}$WORKSPACE${NC}"
echo -e "  配置文件：${CYAN}$CONFIG_DIR/$CONFIG_FILE${NC}"
echo ""

if [ "$MODE_CHOICE" = "3" ]; then
echo -e "  ${YELLOW}接下来只需要 3 步：${NC}"
echo ""
echo "  1. 编辑配置文件，填入 LLM API Key："
echo "     nano $CONFIG_DIR/$CONFIG_FILE"
echo ""
echo "  2. 启动 Gateway："
echo "     $CLI_CMD gateway --verbose"
echo ""
echo "  3. 浏览器打开 WebUI："
echo "     http://localhost:18789"
echo ""
elif [ "$MODE_CHOICE" = "2" ]; then
echo -e "  ${YELLOW}接下来需要 3 步：${NC}"
echo ""
echo "  1. 编辑配置文件，填入 LLM API Key："
echo "     nano $CONFIG_DIR/$CONFIG_FILE"
echo ""
echo "  2. 创建飞书应用（只需 1 个：司礼监）："
echo "     a) 访问 https://open.feishu.cn/app"
echo "     b) 创建应用（如「AI朝廷-司礼监」）→ 复制 App ID 和 App Secret"
echo "     c) 权限管理 → 添加 im:message 等 8 个权限（见飞书配置指南）"
echo "     d) 开启机器人能力，添加 im.message.receive_v1 事件"
echo "     e) 事件接收选择 WebSocket 长连接"
echo "     f) 把 appId/appSecret 填到配置文件的 silijian 位置"
echo "     g) 创建版本并发布应用"
echo ""
echo "  3. 启动 Gateway："
echo "     $CLI_CMD gateway --verbose"
echo ""
echo -e "     📖 详细指南: ${CYAN}https://github.com/wanikua/danghuangshang/blob/main/飞书配置指南.md${NC}"
echo ""
else
echo -e "  ${YELLOW}接下来需要 3 步：${NC}"
echo ""
echo "  1. 编辑配置文件，填入 LLM API Key："
echo "     nano $CONFIG_DIR/$CONFIG_FILE"
echo ""
echo "  2. 创建 Discord Bot（每个部门一个）："
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 创建 Application → Bot → 复制 Token"
echo "     c) 重复创建多个 Bot（司礼监、兵部、户部...按需）"
echo "     d) 把每个 Token 填到 $CONFIG_DIR/$CONFIG_FILE 的 accounts 对应位置"
echo "     e) 每个 Bot 都要开启 Message Content Intent"
echo "     f) 邀请所有 Bot 到你的 Discord 服务器"
echo "     g) 服务器设置 → 角色 → @everyone → 关闭「提及 @everyone」（防止 Bot 回复 ping 全员）"
echo ""
echo "  3. 启动 Gateway："
echo "     $CLI_CMD gateway --verbose"
echo ""
fi

# 创建各 agent 独立工作区
create_agent_workspaces

echo -e "${CYAN}💡 Troubleshooting:${NC}"
echo "  遇到 config invalid 错误？先跑: $CLI_CMD doctor --fix"
echo ""
echo -e "完整教程：${BLUE}https://github.com/wanikua/danghuangshang${NC}"
echo ""
