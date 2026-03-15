# 🌐 路径 E：纯 WebUI 部署

> ⏱️ 预计耗时：5 分钟 | 不需要 Bot，Gateway 自带 WebChat
>
> ← [返回 README](../README.md)

---

## 1. 安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh)
# 选择：纯 WebUI 模式
```

## 2. 填 LLM API Key

```bash
nano ~/.openclaw/openclaw.json
# 只需填 models.providers 里的 API Key
# channels 部分可以留空或不配
```

## 3. 启动

```bash
openclaw gateway --verbose
# 或用系统服务：systemctl --user start openclaw-gateway
```

## 4. 打开浏览器

访问 `http://你的服务器IP:18789`，进入 Gateway 自带的 Control UI → Chat 标签页，直接对话。

> ✅ **完全不需要 Discord Bot Token 或飞书 App ID。** Gateway 启动只需要 LLM API Key。
>
> 💡 后续想接 Discord 或飞书？随时在 `openclaw.json` 里加 channel 配置，重启 Gateway 即可。

---

← [返回 README](../README.md)
