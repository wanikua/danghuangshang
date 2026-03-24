#!/bin/bash
# ============================================
# AI 朝廷 — macOS 本地安装脚本
# 适用于 macOS (Intel / Apple Silicon)
# 用法:
#   bash install-mac.sh              # 交互式安装
#   bash install-mac.sh --no-gui     # 跳过 Dashboard Web UI
#   bash install-mac.sh --with-gui   # 包含 Dashboard Web UI
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
echo -e "${BLUE}🏛️ AI 朝廷 — macOS 本地安装${NC}"
echo "================================"
echo ""

# ---- 检测系统 ----
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}✗ 此脚本仅适用于 macOS${NC}"
    echo "  Linux 用户请使用 install.sh"
    exit 1
fi

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo -e "  ${GREEN}✓ Apple Silicon (M系列芯片)${NC}"
else
    echo -e "  ${GREEN}✓ Intel Mac${NC}"
fi

echo -e "  macOS $(sw_vers -productVersion)"
echo ""

# ---- 1. Homebrew ----
echo -e "${YELLOW}[1/6] 检查 Homebrew...${NC}"
if command -v brew &>/dev/null; then
    echo -e "  ${GREEN}✓ Homebrew 已安装${NC}"
else
    echo -e "  ${CYAN}→ 安装 Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to PATH for Apple Silicon
    if [[ "$ARCH" == "arm64" ]]; then
        # SEC-28: 检查是否已存在，避免重复追加
        if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    echo -e "  ${GREEN}✓ Homebrew 安装完成${NC}"
fi

# ---- 2. Node.js ----
echo -e "${YELLOW}[2/6] 检查 Node.js...${NC}"
if command -v node &>/dev/null; then
    NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
    if [ "$NODE_MAJOR" -ge 22 ] 2>/dev/null; then
        echo -e "  ${GREEN}✓ Node.js $(node -v) 已安装${NC}"
    else
        echo -e "  ${YELLOW}⚠ Node.js $(node -v) 版本过低，升级中...${NC}"
        brew install node@22
        brew link --overwrite node@22 2>/dev/null || true
        echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
    fi
else
    echo -e "  ${CYAN}→ 安装 Node.js 22...${NC}"
    brew install node@22
    brew link --overwrite node@22 2>/dev/null || true
    echo -e "  ${GREEN}✓ Node.js $(node -v) 安装完成${NC}"
fi

# ---- 3. OpenClaw ----
echo -e "${YELLOW}[3/6] 检查 OpenClaw...${NC}"
CLI_CMD=""
CONFIG_DIR=""
CONFIG_FILE=""

if command -v openclaw &>/dev/null; then
    CLI_CMD="openclaw"
    CONFIG_DIR="$HOME/.openclaw"
    CONFIG_FILE="openclaw.json"
    echo -e "  ${GREEN}✓ OpenClaw $(openclaw --version 2>/dev/null) 已安装${NC}"
else
    echo -e "  ${CYAN}→ 安装 OpenClaw...${NC}"
    npm install -g openclaw 2>/dev/null
    if command -v openclaw &>/dev/null; then
        CLI_CMD="openclaw"
        CONFIG_DIR="$HOME/.openclaw"
        CONFIG_FILE="openclaw.json"
    else
        echo -e "  ${RED}✗ 安装失败，请手动运行: npm install -g openclaw${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}✓ $CLI_CMD 安装完成${NC}"
fi

# ---- 4. 初始化工作区 ----
echo -e "${YELLOW}[4/6] 初始化工作区...${NC}"
WORKSPACE="$HOME/clawd"
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="openclaw.json"
mkdir -p "$WORKSPACE/memory"
cd "$WORKSPACE"

# ---- 安装项目依赖 ----
echo ""
echo -e "${YELLOW}[5/6] 安装项目依赖...${NC}"
echo -e "  ${CYAN}正在安装主项目依赖...${NC}"
npm install --loglevel=error
echo -e "  ${GREEN}✓${NC} 项目依赖已安装"

# ---- 安装默认 Skill: self-improving ----
echo ""
echo -e "${YELLOW}安装默认 Skill...${NC}"
if ! command -v clawdhub &>/dev/null; then
  npm install -g clawdhub 2>/dev/null || true
fi
if command -v clawdhub &>/dev/null; then
  # 主工作区
  clawdhub install self-improving --workdir "$WORKSPACE" --force 2>/dev/null && \
    echo -e "  ${GREEN}✓ self-improving 已安装到主工作区${NC}" || \
    echo -e "  ${YELLOW}⚠ 主工作区 skill 安装失败，可稍后手动安装：clawdhub install self-improving${NC}"
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
  echo -e "  ${YELLOW}⚠ clawdhub 未安装，跳过 skill 安装。安装后运行：clawdhub install self-improving${NC}"
fi

# 创建各 agent 独立工作区的函数（配置生成后调用）
create_agent_workspaces() {
  local config_file="$CONFIG_DIR/$CONFIG_FILE"
  if [ -f "$config_file" ] && command -v jq &>/dev/null; then
    local workspaces
    workspaces=$(jq -r '.agents.list[]? | "\(.id):\(.workspace // empty)"' "$config_file" 2>/dev/null)
    for entry in $workspaces; do
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



# SOUL.md
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
cat > "$WORKSPACE/SOUL.md" << 'SOUL_EOF'
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
echo -e "  ${GREEN}✓ SOUL.md 已创建${NC}"
fi

# ---- 安装默认 Skill: self-improving ----
echo ""
echo -e "${YELLOW}安装默认 Skill...${NC}"
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

# IDENTITY.md
if [ ! -f "$WORKSPACE/IDENTITY.md" ]; then
cat > "$WORKSPACE/IDENTITY.md" << 'ID_EOF'
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
fi

# USER.md
if [ ! -f "$WORKSPACE/USER.md" ]; then
cat > "$WORKSPACE/USER.md" << 'USER_EOF'
# 皇帝档案

- **称呼：** 皇上
- **语言：** 中文
- **偏好：** 简洁高效，直接给方案
USER_EOF
echo -e "  ${GREEN}✓ USER.md 已创建${NC}"
fi

# ---- 5. 生成配置文件 ----
echo -e "${YELLOW}[5/6] 生成配置文件...${NC}"
mkdir -p "$CONFIG_DIR"

echo ""
echo -e "${CYAN}选择部署模式：${NC}"
echo "  1) Discord 多Bot模式（完整六部，需要创建 Discord Bot）"
echo "  2) 飞书单Bot模式（只需 1 个飞书应用，sessions_spawn 后台调度）"
echo "  3) 纯 WebUI 模式（不需要 Discord/飞书，浏览器直接用）"
echo ""
if [ -t 0 ]; then
    read -p "请选择 [1/2/3]（默认1）: " DEPLOY_MODE
else
    DEPLOY_MODE=""
fi
DEPLOY_MODE=${DEPLOY_MODE:-1}

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
    echo -e "  ${YELLOW}⚠ 配置文件已存在，跳过 ($CONFIG_DIR/$CONFIG_FILE)${NC}"
else
    case "$DEPLOY_MODE" in
        3) CONFIG_MODE="webui" ;;
        2) CONFIG_MODE="feishu" ;;
        *) CONFIG_MODE="discord" ;;
    esac
    generate_config_from_template "$CONFIG_MODE" "$CONFIG_DIR/$CONFIG_FILE"
fi



# ---- 可选：安装 Dashboard Web UI ----
echo ""
echo -e "${YELLOW}[6/6] Dashboard Web UI...${NC}"
if [ "$INSTALL_GUI" = "yes" ]; then
    REPO_URL="https://github.com/wanikua/danghuangshang"
    GUI_DIR="$WORKSPACE/gui"
    if [ -d "$GUI_DIR" ]; then
        echo -e "  ${GREEN}✓ gui/ 目录已存在，跳过克隆${NC}"
    else
        echo -e "  ${CYAN}正在下载 Dashboard...${NC}"
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

echo ""
echo "================================"
echo -e "${GREEN}🎉 macOS 安装完成！${NC}"
echo "================================"
echo ""
echo "接下来："
echo ""
echo -e "  ${YELLOW}1. 配置 LLM API Key${NC}"
echo "     编辑 $CONFIG_DIR/$CONFIG_FILE"
echo "     把 YOUR_LLM_API_KEY 替换成你的 API Key"
echo ""
if [ "$DEPLOY_MODE" = "2" ]; then
echo -e "  ${YELLOW}2. 创建飞书应用（只需 1 个：司礼监）${NC}"
echo "     a) 访问 https://open.feishu.cn/app"
echo "     b) 创建应用（如「AI朝廷-司礼监」）→ 复制 App ID 和 App Secret"
echo "     c) 权限管理 → 添加 im:message 等 8 个权限"
echo "     d) 开启机器人能力，添加 im.message.receive_v1 事件"
echo "     e) 事件接收选择 WebSocket 长连接"
echo "     f) 把 appId/appSecret 填到配置文件的 silijian 位置"
echo "     g) 创建版本并发布应用"
echo ""
echo -e "     📖 详细指南: ${CYAN}https://github.com/wanikua/danghuangshang/blob/main/飞书配置指南.md${NC}"
elif [ "$DEPLOY_MODE" = "3" ]; then
echo -e "  ${YELLOW}2. 无需配置 Bot${NC}"
echo "     WebUI 模式直接通过浏览器访问即可"
else
echo -e "  ${YELLOW}2. 创建 Discord Bot${NC}"
echo "     a) 访问 https://discord.com/developers/applications"
echo "     b) 每个部门创建一个 Bot → 复制 Token"
echo "     c) 填入配置文件对应位置"
echo "     d) 每个 Bot 开启 Message Content Intent"
echo "     e) 邀请所有 Bot 到你的 Discord 服务器"
echo "     f) 服务器设置 → 角色 → @everyone → 关闭「提及 @everyone」（防止 Bot 回复 ping 全员）"
fi
echo ""
echo -e "  ${YELLOW}3. 启动朝廷${NC}"
echo "     $CLI_CMD gateway --verbose"
echo ""
echo -e "  ${YELLOW}4. 验证${NC}"
echo "     $CLI_CMD status"
if [ "$DEPLOY_MODE" = "2" ]; then
echo "     在飞书里给机器人发消息试试"
elif [ "$DEPLOY_MODE" = "3" ]; then
echo "     浏览器打开 http://localhost:18789"
else
echo "     在 Discord @你的Bot 说话试试"
fi
echo ""
echo -e "  ${YELLOW}5. 后台运行（可选）${NC}"
echo "     # 使用 launchd 开机自启："
echo "     $CLI_CMD gateway install"
echo "     # 或用 tmux/screen 保持后台运行："
echo "     tmux new -d -s court '$CLI_CMD gateway'"
echo ""
echo -e "  ${YELLOW}6. 添加定时任务（可选）${NC}"
echo "     $CLI_CMD cron add --name '每日简报' \\"
echo "       --agent silijian --cron '0 22 * * *' --tz Asia/Shanghai \\"
echo "       --message '生成今日简报' --session isolated"
echo ""
echo -e "💡 Mac 用户提示："
echo "  • 合上盖子会休眠，建议在「系统设置 → 电池 → 选项」里关闭自动休眠"
echo "  • 或者用 caffeinate -d 命令防止休眠"
echo "  • 长期运行建议使用云服务器"
echo ""
# 创建各 agent 独立工作区
create_agent_workspaces

echo -e "完整教程：${BLUE}https://github.com/wanikua/danghuangshang${NC}"
