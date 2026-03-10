# OpenViking Skill

OpenViking 上下文数据库集成 — 给 AI 朝廷加上长期记忆和知识库。

## 什么是 OpenViking

OpenViking 是火山引擎开源的 AI Agent 上下文数据库，用文件系统范式统一管理记忆、资源和技能。
相比 OpenClaw 默认的 qmd 记忆后端，OpenViking 在大规模文档场景下更强：

| 能力 | qmd（默认） | OpenViking |
|------|-----------|------------|
| 语义搜索 | 基础向量匹配 | 目录递归 + 语义融合 |
| 自动摘要 | ❌ | ✅ L0/L1/L2 三层 |
| 结构化浏览 | ❌ | ✅ 虚拟文件系统 |
| Token 节省 | ❌ | ✅ 按需加载 |

## 安装

### 1. 安装 Python 包

```bash
pip install openviking
```

### 2. 获取 Embedding API Key

推荐使用免费的 NVIDIA NIM API：

1. 访问 https://build.nvidia.com/
2. 登录 → API Keys → 生成 Key
3. 保存 key（以 `nvapi-` 开头）

也可以用火山引擎、OpenAI 等其他 provider。

### 3. 创建配置文件

```bash
mkdir -p ~/.openviking
cat > ~/.openviking/ov.conf << 'EOF'
{
  "embedding": {
    "dense": {
      "api_base": "https://integrate.api.nvidia.com/v1",
      "api_key": "YOUR_NVIDIA_API_KEY",
      "provider": "openai",
      "dimension": 4096,
      "model": "nvidia/nv-embed-v1"
    }
  },
  "vlm": {
    "api_base": "https://integrate.api.nvidia.com/v1",
    "api_key": "YOUR_NVIDIA_API_KEY",
    "provider": "openai",
    "model": "meta/llama-3.3-70b-instruct"
  }
}
EOF
```

### 4. 设置环境变量

```bash
echo 'export OPENVIKING_CONFIG_FILE=~/.openviking/ov.conf' >> ~/.bashrc
source ~/.bashrc
```

## 使用方式

Agent 通过 exec 调用 `scripts/viking.sh` 脚本：

```bash
# 查看状态
bash skills/openviking/scripts/viking.sh info

# 索引文件
bash skills/openviking/scripts/viking.sh add ./my-document.md

# 批量索引目录
bash skills/openviking/scripts/viking.sh add-dir ./docs/

# 语义搜索
bash skills/openviking/scripts/viking.sh search "某个话题"

# 浏览已索引的文件
bash skills/openviking/scripts/viking.sh list

# 读取文件摘要
bash skills/openviking/scripts/viking.sh summary <file-path>
```

## 朝廷集成建议

- **兵部**：索引代码仓库，搜索相关代码片段
- **户部**：索引财务报表，查询历史数据
- **礼部**：索引品牌素材和营销案例
- **工部**：索引运维文档和 runbook
- **刑部**：索引法律法规和合同模板

建议保留 qmd 做日常轻量记忆，OpenViking 做大规模知识库。
