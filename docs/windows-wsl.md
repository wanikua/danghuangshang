# 🪟 Windows 用户指南 — 通过 WSL2 运行 AI 朝廷

> OpenClaw 是 Node.js 应用，原生运行在 Linux/macOS 上。Windows 用户推荐通过 **WSL2（Windows Subsystem for Linux）** 运行。

## 前置要求

- Windows 10 (版本 2004+) 或 Windows 11
- 管理员权限

## 安装步骤

### 1. 安装 WSL2

打开 **PowerShell（管理员）**，运行：

```powershell
wsl --install
```

这会自动安装 WSL2 和 Ubuntu。安装完成后重启电脑。

### 2. 初始化 Ubuntu

重启后，打开 **Ubuntu** 应用（从开始菜单），设置用户名和密码。

### 3. 更新系统

```bash
sudo apt update && sudo apt upgrade -y
```

### 4. 安装 Node.js 22+

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v  # 确认 >= 22
```

### 5. 安装 OpenClaw

```bash
sudo npm install -g openclaw@latest
openclaw --version
```

### 6. 一键部署 AI 朝廷

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/boluobobo-ai-court-tutorial/main/install-lite.sh)
```

然后按提示填入 LLM API Key 和 Discord Bot Token 即可。

### 7. 启动

```bash
openclaw gateway --verbose
```

## 常见问题

### Q: WSL2 里怎么访问 WebUI？
浏览器直接访问 `http://localhost:18789`，WSL2 会自动转发端口到 Windows。

### Q: 怎么让 Gateway 后台运行？
```bash
# 方法 1: 使用 tmux
sudo apt install -y tmux
tmux new -s court
openclaw gateway --verbose
# Ctrl+B 然后按 D 分离

# 方法 2: 使用 systemd（WSL2 支持）
openclaw gateway install
```

### Q: 文件在 Windows 资源管理器里怎么找？
在资源管理器地址栏输入 `\\wsl$\Ubuntu\home\你的用户名\clawd`

### Q: 网络连不上？
确保 Windows 防火墙没有阻止 WSL2 的网络访问。可以临时关闭防火墙测试。

## 推荐工具

- **Windows Terminal** — 比默认终端好用很多（Microsoft Store 免费下载）
- **VS Code + Remote WSL 扩展** — 在 Windows 上用 VS Code 编辑 WSL 里的文件
