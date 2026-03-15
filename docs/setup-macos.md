# 🍎 路径 C：macOS 本地部署

> ⏱️ 预计耗时：10 分钟 | 支持 Intel 和 Apple Silicon (M1/M2/M3/M4)
>
> ← [返回 README](../README.md)

---

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-mac.sh)
```

自动通过 Homebrew 安装所有依赖。

## 配置

```bash
nano ~/.openclaw/openclaw.json   # 填 API Key + Bot Token
```

## 启动

```bash
openclaw gateway --verbose       # 启动（Mac 不用 systemd）
```

## 注意事项

- Mac 上 Agent 能访问你的本地文件系统，建议设置独立工作区目录
- `workspace` 推荐设为 `~/clawd`，**不要设为家目录**
- 建议给需要跑代码的 Agent 开启 sandbox 隔离
- 关闭终端 Gateway 会停止运行，建议使用 tmux 保持后台运行

## 后台运行（使用 tmux）

```bash
# 安装 tmux
brew install tmux

# 创建会话并启动
tmux new -s court
openclaw gateway --verbose
# Ctrl+B D 退出（Gateway 继续运行）

# 重新连接
tmux attach -t court
```

---

← [返回 README](../README.md)
