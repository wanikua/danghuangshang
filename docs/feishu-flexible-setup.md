# 飞书 Bot 灵活配置指南

## 🎯 核心原则

**所有 Bot 都是可选的！** 用户可以根据需求自由选择配置几个 Bot。

---

## 📦 Bot 配置方案

### 方案 1: 单 Bot 基础版（最小配置）

**只需 1 个 Bot** - 司礼监

```json
{
  "channels": {
    "feishu": {
      "accounts": {
        "silijian": {
          "appId": "xxx",
          "appSecret": "xxx"
        }
      }
    }
  },
  "bindings": [
    {"agentId": "silijian", "match": {"channel": "feishu", "account": "silijian"}}
  ]
}
```

**适用场景**：
- ✅ 快速部署
- ✅ 个人使用
- ✅ 测试环境

---

### 方案 2: 3 Bot 核心版（推荐）

**配置 3 个核心 Bot**：

| Bot | 职责 | 必要性 |
|-----|------|--------|
| 司礼监 | 调度中心 | ⭐⭐⭐ 必需 |
| 内阁 | 优化中心 | ⭐⭐⭐ 必需 |
| 工部 | 执行代表 | ⭐⭐ 推荐 |

```json
{
  "channels": {
    "feishu": {
      "accounts": {
        "silijian": {"appId": "xxx", "appSecret": "xxx"},
        "neige": {"appId": "xxx", "appSecret": "xxx"},
        "gongbu": {"appId": "xxx", "appSecret": "xxx"}
      }
    }
  },
  "bindings": [
    {"agentId": "silijian", "match": {"channel": "feishu", "account": "silijian"}},
    {"agentId": "neige", "match": {"channel": "feishu", "account": "neige"}},
    {"agentId": "gongbu", "match": {"channel": "feishu", "account": "gongbu"}}
  ]
}
```

**适用场景**：
- ✅ 小团队使用
- ✅ 核心功能完整
- ✅ 配置 manageable

---

### 方案 3: 6 Bot 标准版

**配置 6 个常用 Bot**：

| Bot | 职责 |
|-----|------|
| 司礼监 | 调度 |
| 内阁 | 优化 |
| 都察院 | 审查 |
| 兵部 | 开发 |
| 户部 | 财务 |
| 工部 | 运维 |

**适用场景**：
- ✅ 中型团队
- ✅ 功能较完整

---

### 方案 4: 9+ Bot 完整版

**配置所有 Bot** - 适合大型团队

---

## 🔧 灵活配置示例

### 添加任意 Bot

在 `accounts` 中添加：

```json
{
  "channels": {
    "feishu": {
      "accounts": {
        "silijian": {"appId": "xxx", "appSecret": "xxx"},
        // 按需添加以下 Bot
        "neige": {"appId": "xxx", "appSecret": "xxx"},
        "bingbu": {"appId": "xxx", "appSecret": "xxx"},
        "hubu": {"appId": "xxx", "appSecret": "xxx"},
        // ... 任意组合
      }
    }
  }
}
```

### 对应添加 Bindings

```json
{
  "bindings": [
    {"agentId": "silijian", "match": {"channel": "feishu", "account": "silijian"}},
    {"agentId": "neige", "match": {"channel": "feishu", "account": "neige"}},
    // 与 accounts 一一对应
  ]
}
```

---

## 📋 Bot 列表（按需选择）

### 明朝内阁制

| Bot | 职责 | 推荐度 |
|-----|------|--------|
| 司礼监 | 调度中心 | ⭐⭐⭐ 必需 |
| 内阁 | Prompt 优化 | ⭐⭐⭐ 必需 |
| 都察院 | 代码审查 | ⭐⭐ 推荐 |
| 兵部 | 编码开发 | ⭐⭐ 推荐 |
| 户部 | 财务分析 | ⭐ 可选 |
| 礼部 | 品牌营销 | ⭐ 可选 |
| 工部 | 运维部署 | ⭐⭐ 推荐 |
| 吏部 | 项目管理 | ⭐ 可选 |
| 刑部 | 法务合规 | ⭐ 可选 |

### 唐朝三省制

| Bot | 职责 | 推荐度 |
|-----|------|--------|
| 中书省 | 起草诏令 | ⭐⭐⭐ 必需 |
| 门下省 | 审核封驳 | ⭐⭐⭐ 必需 |
| 尚书省 | 派发执行 | ⭐⭐⭐ 必需 |
| 御史台 | 监察审计 | ⭐⭐ 推荐 |
| 史官 | 记录朝政 | ⭐ 可选 |
| 六部 | 执行部门 | ⭐⭐ 按需 |

### 现代企业制

| Bot | 职责 | 推荐度 |
|-----|------|--------|
| CEO | 决策调度 | ⭐⭐⭐ 必需 |
| Board | 战略审议 | ⭐⭐ 推荐 |
| QA | 质量审查 | ⭐⭐ 推荐 |
| CTO | 技术执行 | ⭐⭐⭐ 必需 |
| CFO | 财务分析 | ⭐ 可选 |
| CMO | 品牌营销 | ⭐ 可选 |
| COO | 运营部署 | ⭐⭐ 推荐 |
| CLO | 法务合规 | ⭐ 可选 |
| CoS | 项目协调 | ⭐ 可选 |

---

## 🎯 推荐配置

### 个人开发者
```
司礼监 + 内阁 + 工部（3 Bot）
```

### 小团队（3-5 人）
```
司礼监 + 内阁 + 都察院 + 兵部 + 工部（5 Bot）
```

### 中型团队（5-10 人）
```
司礼监 + 内阁 + 都察院 + 六部（9 Bot）
```

### 大型团队（10+ 人）
```
全部 Bot（9-11 Bot）
```

---

## 💡 核心原则

1. **最少 1 个 Bot** 即可运行
2. **推荐 3 个 Bot** 核心功能完整
3. **按需添加** 其他 Bot
4. **每个 Bot 对应一个 bindings 路由**

---

## 🚀 快速开始

1. 从单 Bot 开始
2. 根据需要逐步添加
3. 每添加一个 Bot，记得添加对应的 bindings

**配置是渐进式的，不是一次性的！**
