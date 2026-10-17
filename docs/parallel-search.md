# Hermes 接入 Parallel 网页搜索（可选）

> ← [文档索引](./README.md) · [Hermes 接入指南](../EXTERNAL_HERMES.md)
>
> 适用版本：Hermes Agent v2026.9.24 的远程 HTTP MCP 配置。仅适用于 Hermes 路线。

[Parallel Search MCP](https://docs.parallel.ai/integrations/mcp/search-mcp) 提供网页搜索和页面内容提取，适合让户部查找最新行业资料、礼部核对公开信息，或让翰林院整理带来源的研究摘要。匿名搜索使用 Fast 模式，不需要注册账户或 Parallel API Key。

这是手动启用的外部工具，不会修改本项目的配置模板、模型选择或已有搜索设置。搜索词和待抓取的 URL 会发送到 Parallel 服务。免费匿名服务适合探索和轻量使用，有额度限制；更高额度的接入方式见 [Parallel 文档](https://docs.parallel.ai/integrations/mcp/search-mcp)。

## 1. 合并配置

先按 [Hermes 接入指南](../EXTERNAL_HERMES.md) 完成安装和模型配置，并确认当前 Hermes 安装包含 MCP 支持。

备份当前 profile 的 `config.yaml`，再将下面的配置合并到文件顶层。默认 profile 使用 `~/.hermes/config.yaml`；如果通过 `HERMES_HOME` 指定了其他 profile，应编辑那个目录下的 `config.yaml`。

```yaml
mcp_servers:
  parallel_search:
    url: "https://search.parallel.ai/mcp"
    headers:
      User-Agent: "danghuangshang/parallel-search"
    timeout: 60
```

如果文件已经有 `mcp_servers:`，只在其下新增 `parallel_search:`，保留已有服务器。不要重复添加顶层键，也不要用这个片段覆盖整个配置文件。这里不需要 `Authorization` 请求头，也不需要在 `.env` 中添加 Parallel 凭证。

## 2. 启动并使用

退出已有 CLI 会话后重新启动，让 Hermes 发现新工具：

```bash
hermes
```

如果使用消息网关，则在同一个 profile 下重启网关：

```bash
hermes gateway restart
```

Hermes 会为远程工具加上服务器名前缀：

| 工具名 | 用途 |
|--------|------|
| `mcp__parallel_search__web_search` | 搜索当前网页，返回来源 URL 和相关摘录 |
| `mcp__parallel_search__web_fetch` | 从指定 URL 提取与任务相关的页面内容 |

在 Hermes 对话中试试：

```text
请使用 mcp__parallel_search__web_search 查找 Hermes Agent 的 HTTP MCP 配置方法，
优先使用官方文档。总结配置步骤，并给出来源链接。
```

已有摘录足够时直接总结；需要核对原文或阅读指定页面时，再抓取：

```text
请使用 mcp__parallel_search__web_fetch 阅读
https://docs.parallel.ai/integrations/mcp/search-mcp，
总结匿名接入方式，并附上来源链接。
```

检查回复中的工具调用记录：应出现对应的 `mcp__parallel_search__*` 工具和返回的来源内容。只看到模型回复不代表已调用搜索工具。

## 3. 排查与停用

- **没有出现工具**：检查 YAML 缩进、是否编辑了当前 profile，以及是否重启了 CLI 或网关。旧版或精简安装缺少 MCP 支持时，按 [Hermes MCP 文档](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp) 补齐安装。
- **连接失败或超时**：确认运行 Hermes 的机器能访问 `https://search.parallel.ai/mcp`；本例的工具调用超时为 60 秒。
- **提示额度限制**：按服务返回的信息稍后重试，或使用 Parallel 文档中的认证接入方式。工具失败时，不应把模型已有知识当作实时搜索结果。
- **停用**：在已有的 `parallel_search:` 配置下添加 `enabled: false`，再重启 CLI 或网关。保留其他 MCP 服务器和原有搜索配置。

## 参考

- [Hermes MCP 配置与工具命名](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp)
- [Hermes Agent v2026.9.24](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.9.24)
- [该版本的 MCP 工具命名](https://github.com/NousResearch/hermes-agent/blob/f97608f178d1ffeca59860195ab7da295f7c8e5f/tools/mcp_tool_schema.py)
- [Parallel Search MCP](https://docs.parallel.ai/integrations/mcp/search-mcp)
