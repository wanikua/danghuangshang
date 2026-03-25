# 🏯 菠萝王朝项目家族

## 主仓库 (danghuangshang)

**定位**: 教程 + 安装包 + GUI 安装

**内容**:
- 📦 安装脚本 (install-lite.sh, install-mac.sh, install.ps1)
- 📚 教程文档 (docs/, boluobobo-ai-court-tutorial/)
- 🖥️ GUI 安装 (Dockerfile, docker-compose.yml, gui/, projects/boluo-gui/)
- ⚙️ 配置模板 (configs/, openclaw.example.json)

**快速开始**:
```bash
git clone https://github.com/wanikua/danghuangshang.git
cd danghuangshang
bash install-lite.sh
```

---

## 独立项目

以下项目已移至独立仓库或本地存储：

### 光启哨兵 (guangqi-sentinel)
- **类型**: 独立监控项目
- **大小**: 367MB
- **位置**: ~/repos/danghuangshang-extras/guangqi-sentinel

### 实验项目
- **meow** - 实验性项目
- **melonclaw** - 衍生项目
- **art-of-war-skill** - 孙子兵法技能包
- **thinking-skills** - 思维技能包

### 网站项目
- **boluobobo-site** - 官方网站
- **likuanwang.com** - 个人网站

### 商业项目
- **shangpu-manager** - 商户管理
- **veno-ventures** - 风投项目

### 其他
- **wanikua** - 个人项目集合

---

## 相关仓库

| 仓库 | 用途 | 链接 |
|------|------|------|
| **boluobobo-ai-court-tutorial** | 详细教程 | [查看](./boluobobo-ai-court-tutorial/) |
| **projects/boluo-gui** | GUI 界面 | [查看](./projects/boluo-gui/) |
| **OpenClaw** | 底层框架 | https://github.com/openclaw/openclaw |

---

## 仓库结构

```
danghuangshang/
├── 📦 安装包
│   ├── install-lite.sh
│   ├── install-mac.sh
│   ├── install.ps1
│   └── scripts/
│
├── 📚 教程文档
│   ├── docs/
│   ├── README.md
│   └── boluobobo-ai-court-tutorial/
│
├── 🖥️ GUI 安装
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── gui/
│   └── projects/boluo-gui/
│
└── ⚙️ 配置模板
    ├── configs/
    └── openclaw.example.json
```

---

**最后更新**: 2026-03-25  
**维护者**: 工部
