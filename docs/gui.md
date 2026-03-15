# 🖥️ GUI 管理界面

AI 朝廷提供三层 GUI：**Web Dashboard** 看系统状态 → **Discord** 下达指令 → **Notion** 查看报表。

---

## Web 管理后台（菠萝王朝 Dashboard）

本项目内置 Web 管理后台（`gui/` 目录），基于 React + TypeScript + Vite 构建。

<p align="center">
  <img src="../images/gui-court.png" alt="朝堂总览" width="90%" />
  <br/><em>朝堂总览 — 御座、六部、诸院，在线状态一目了然</em>
</p>

<p align="center">
  <img src="../images/gui-sessions.png" alt="会话管理" width="90%" />
  <br/><em>会话管理 — 88 个会话、9008 条消息、87.34M Token 消耗实时追踪</em>
</p>

### 功能

- **仪表盘**：实时查看各部门状态、Token 消耗、系统负载
- **朝堂**：直接在 Web 端与各部门 Bot 对话
- **会话管理**：查看所有历史会话、消息详情、Token 统计
- **定时任务**：可视化管理 Cron 任务（启用/禁用/手动触发）
- **Token 统计**：按部门、按日期的 Token 消耗分析
- **系统健康**：CPU/内存/磁盘监控、Gateway 状态

### 启动方式

```bash
# 1. 进入教程仓库
cd danghuangshang

# 2. 构建前端
cd gui && npm install && npm run build

# 3. 安装后端依赖并启动
cd server && npm install
BOLUO_AUTH_TOKEN=你的密码 node index.js
```

访问：`http://你的服务器IP:18795`

> ⚠️ **登录密码**：通过 `BOLUO_AUTH_TOKEN` 环境变量设置。
>
> 💡 生产环境建议 Nginx 反向代理 + HTTPS。长期运行用 `pm2`：
> ```bash
> BOLUO_AUTH_TOKEN=你的密码 pm2 start server/index.js --name boluo-gui
> ```

---

## Discord 作为 GUI

Discord 本身就是最佳的 GUI 管理界面：

- **手机 + 电脑**同步，随时随地管理
- **频道分类**天然对应各部门
- **消息历史**永久保存，自带搜索
- **权限管理**精细控制
- **@mention** 即可调用任意 Agent，零学习成本

---

## Notion 作为数据可视化补充

通过 Notion Skill 集成，朝廷数据自动同步到 Notion：

- **起居注（日报）**、**朔望录（周报）**自动生成
- **食货表（财务）**自动记录 API 消耗
- **列传（项目）**追踪各项目进展
- Notion 看板、日历、表格视图提供丰富的数据可视化

> 📖 配置方法见 [Notion 接入指南](./notion-setup.md)

---

← [返回 README](../README.md)
