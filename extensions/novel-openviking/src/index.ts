import { readFileSync } from "fs";
import { resolve, dirname } from "path";

export default function register(api: any) {
  const pluginDir = dirname(dirname(new URL(import.meta.url).pathname));
  const config = api.getConfig?.() ?? {};
  const vikingScript = config.vikingScript ?? "skills/openviking/scripts/viking.sh";

  // 注册 viking 语义搜索工具 — 供翰林院 agent 调用
  api.registerTool({
    name: "novel_viking_search",
    description:
      "语义搜索小说设定和前文内容（通过 OpenViking）。" +
      "当 grep 关键词搜索不够精确时使用，支持模糊语义匹配。",
    parameters: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "搜索查询，例如「林晓的性格特征」「青铜匕首的来历」",
        },
      },
      required: ["query"],
    },
    async execute({ query }: { query: string }) {
      const { execSync } = await import("child_process");
      try {
        const result = execSync(`bash ${vikingScript} search "${query}"`, {
          encoding: "utf-8",
          timeout: 30_000,
        });
        return result;
      } catch {
        return "OpenViking 未安装或不可用，请回退到文件搜索（grep）。";
      }
    },
  });

  // 注册索引工具 — 归档后自动同步到 OpenViking
  api.registerTool({
    name: "novel_viking_index",
    description:
      "将小说设定文件或章节摘要索引到 OpenViking。" +
      "在 novel-archiving 归档流程完成后调用，保持语义索引同步。",
    parameters: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "要索引的文件或目录路径",
        },
        recursive: {
          type: "boolean",
          description: "是否递归索引目录",
          default: false,
        },
      },
      required: ["path"],
    },
    async execute({ path, recursive }: { path: string; recursive?: boolean }) {
      const { execSync } = await import("child_process");
      const cmd = recursive ? "add-dir" : "add";
      try {
        const result = execSync(`bash ${vikingScript} ${cmd} ${path}`, {
          encoding: "utf-8",
          timeout: 60_000,
        });
        return result;
      } catch {
        return "OpenViking 索引失败，文件系统记忆不受影响。";
      }
    },
  });

  // 注入 SKILL.md 作为 agent 指令
  const skillPath = resolve(pluginDir, "SKILL.md");
  try {
    const skillContent = readFileSync(skillPath, "utf-8");
    api.registerHook?.("session:start", (_ctx: any) => {
      // SKILL.md 内容会被 OpenClaw 的 skill 自动发现机制加载
      // 这里仅确保插件安装时 skill 可被检测到
    });
  } catch {
    // SKILL.md 不存在时静默降级
  }
}
