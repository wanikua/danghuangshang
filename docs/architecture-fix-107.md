# 架构层修复方案 - Discord 消息循环问题

**Issue**: #107  
**优先级**: P0  
**预计工时**: 1 天  
**状态**: 🟡 设计中

---

## 📋 问题回顾

### 当前问题

1. **机器人消息循环** - 机器人互相@导致无限响应
2. **@everyone 雪崩** - 触发所有机器人同时响应
3. **会话历史污染** - LLM 无法区分用户指令 vs 机器人协调

### 根因

OpenClaw Discord 通道缺少：
- 消息来源鉴别（human vs bot）
- 响应深度限制
- 会话状态管理
- @everyone 防护

---

## 🏗️ 架构设计

### 核心组件

```
┌─────────────────────────────────────────────────────────┐
│                    Discord Gateway                       │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              MessageMetadataExtractor                    │
│  - 提取 authorType (human|bot)                           │
│  - 计算响应深度 depth                                    │
│  - 检测@everyone / @here                                 │
│  - 生成 threadId / sessionId                             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              ResponseRuleEngine                          │
│  - 规则 1: 只响应用户的直接@                             │
│  - 规则 2: 机器人@限制 depth < 3                         │
│  - 规则 3: 会话处理中时排队                              │
│  - 规则 4: 禁止@everyone 触发                            │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              SessionStateManager                         │
│  - 追踪每个频道的处理状态                                │
│  - 消息队列管理                                          │
│  - 超时清理                                              │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              CleanHistoryManager                         │
│  - 过滤历史中的机器人消息                                │
│  - 只保留用户指令上下文                                  │
│  - 标注消息类型                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 📐 数据结构

### MessageMetadata

```typescript
interface MessageMetadata {
  // 基础信息
  id: string;              // 消息 ID
  channelId: string;       // 频道 ID
  authorId: string;        // 作者 ID
  authorType: 'human' | 'bot';  // 作者类型
  timestamp: number;       // 时间戳
  
  // 上下文追踪
  threadId: string;        // 会话线程 ID
  depth: number;           // 响应深度（0=用户直接@）
  inReplyTo: string | null; // 回复的消息 ID
  
  // 标记
  flags: {
    isEveryone: boolean;   // 是否@everyone
    isHere: boolean;       // 是否@here
    isBotMention: boolean; // 是否@机器人
    isDirectMention: boolean; // 是否直接@我
  };
  
  // 原始消息（用于处理）
  content: string;
  mentions: string[];      // 提及的用户 ID 列表
}
```

### SessionState

```typescript
interface SessionState {
  channelId: string;
  isProcessing: boolean;   // 是否正在处理
  currentDepth: number;    // 当前响应深度
  lastActivity: number;    // 最后活动时间戳
  messageQueue: Message[]; // 排队消息
  history: CleanMessage[]; // 过滤后的历史
}

interface CleanMessage {
  id: string;
  authorType: 'human' | 'bot';
  content: string;
  role: 'user' | 'assistant';  // LLM 角色
  metadata?: {
    isCoordination: boolean;  // 是否是机器人协调消息
    targetAgent?: string;     // 协调目标 Agent
  };
}
```

---

## 🔧 核心实现

### 1. MessageMetadataExtractor

```typescript
// packages/openclaw/src/providers/discord/MessageMetadataExtractor.ts

import { Message } from 'discord.js';

export class MessageMetadataExtractor {
  private botUserId: string;
  
  constructor(botUserId: string) {
    this.botUserId = botUserId;
  }
  
  extract(message: Message): MessageMetadata {
    const isBot = message.author.bot;
    const mentionsEveryone = message.mentions.everyone;
    const mentionsHere = message.content.includes('@here');
    const mentionsMe = message.mentions.has(this.botUserId);
    
    // 计算响应深度
    const depth = this.calculateDepth(message);
    
    // 生成/获取线程 ID
    const threadId = this.getThreadId(message);
    
    return {
      id: message.id,
      channelId: message.channelId,
      authorId: message.author.id,
      authorType: isBot ? 'bot' : 'human',
      timestamp: message.createdTimestamp,
      threadId,
      depth,
      inReplyTo: message.reference?.messageId ?? null,
      flags: {
        isEveryone: mentionsEveryone,
        isHere: mentionsHere,
        isBotMention: mentionsMe && isBot,
        isDirectMention: mentionsMe && !isBot,
      },
      content: message.content,
      mentions: message.mentions.users.map(u => u.id),
    };
  }
  
  private calculateDepth(message: Message): number {
    // 通过回复链计算深度
    let depth = 0;
    let current = message;
    
    while (current.reference?.messageId && depth < 10) {
      depth++;
      // 这里需要获取引用的消息（可能需要缓存）
      // 简化实现：通过上下文估算
      current = null; // 实际需要 fetch
    }
    
    return depth;
  }
  
  private getThreadId(message: Message): string {
    // 使用频道 ID + 根消息 ID 作为线程 ID
    if (message.reference?.messageId) {
      return `${message.channelId}:${message.reference.messageId}`;
    }
    return `${message.channelId}:${message.id}`;
  }
}
```

---

### 2. ResponseRuleEngine

```typescript
// packages/openclaw/src/providers/discord/ResponseRuleEngine.ts

import { MessageMetadata } from './MessageMetadataExtractor';
import { SessionState } from './SessionStateManager';

export interface RuleConfig {
  maxDepth: number;              // 最大响应深度
  ignoreBots: boolean;           // 忽略机器人消息
  blockEveryone: boolean;        // 禁止@everyone 触发
  blockHere: boolean;            // 禁止@here 触发
  requireDirectMention: boolean; // 需要直接@
  queueWhenBusy: boolean;        // 忙时排队
}

export class ResponseRuleEngine {
  private config: RuleConfig;
  private botUserId: string;
  
  constructor(botUserId: string, config: RuleConfig) {
    this.botUserId = botUserId;
    this.config = config;
  }
  
  shouldRespond(
    metadata: MessageMetadata,
    sessionState?: SessionState
  ): { allowed: boolean; reason?: string } {
    // 规则 0: @everyone / @here 直接禁止
    if (this.config.blockEveryone && metadata.flags.isEveryone) {
      return { allowed: false, reason: 'Blocked @everyone' };
    }
    if (this.config.blockHere && metadata.flags.isHere) {
      return { allowed: false, reason: 'Blocked @here' };
    }
    
    // 规则 1: 忽略机器人消息（可配置）
    if (this.config.ignoreBots && metadata.authorType === 'bot') {
      // 例外：如果是任务派发且深度未超限
      if (metadata.flags.isBotMention && metadata.depth < this.config.maxDepth) {
        // 允许有限的机器人协作
      } else {
        return { allowed: false, reason: 'Ignored bot message' };
      }
    }
    
    // 规则 2: 必须被@才响应（可配置）
    if (this.config.requireDirectMention && !metadata.flags.isDirectMention) {
      // 例外：机器人协作@
      if (metadata.authorType === 'bot' && metadata.flags.isBotMention) {
        // 允许
      } else {
        return { allowed: false, reason: 'Not directly mentioned' };
      }
    }
    
    // 规则 3: 深度限制
    if (metadata.depth >= this.config.maxDepth) {
      return { 
        allowed: false, 
        reason: `Max depth exceeded (${metadata.depth} >= ${this.config.maxDepth})` 
      };
    }
    
    // 规则 4: 会话状态检查
    if (sessionState?.isProcessing && this.config.queueWhenBusy) {
      return { allowed: false, reason: 'Session busy, queueing' };
    }
    
    // 通过所有检查
    return { allowed: true };
  }
}
```

---

### 3. SessionStateManager

```typescript
// packages/openclaw/src/providers/discord/SessionStateManager.ts

export class SessionStateManager {
  private sessions: Map<string, SessionState> = new Map();
  private readonly IDLE_TIMEOUT = 5 * 60 * 1000; // 5 分钟
  
  getState(channelId: string): SessionState {
    if (!this.sessions.has(channelId)) {
      this.sessions.set(channelId, {
        channelId,
        isProcessing: false,
        currentDepth: 0,
        lastActivity: Date.now(),
        messageQueue: [],
        history: [],
      });
    }
    return this.sessions.get(channelId)!;
  }
  
  startProcessing(channelId: string): boolean {
    const state = this.getState(channelId);
    if (state.isProcessing) {
      return false; // 已在处理
    }
    state.isProcessing = true;
    state.lastActivity = Date.now();
    return true;
  }
  
  finishProcessing(channelId: string): void {
    const state = this.getState(channelId);
    state.isProcessing = false;
    state.currentDepth = 0;
    state.lastActivity = Date.now();
    
    // 处理排队消息
    this.processQueue(channelId);
  }
  
  addToHistory(channelId: string, message: CleanMessage): void {
    const state = this.getState(channelId);
    state.history.push(message);
    
    // 限制历史长度
    if (state.history.length > 50) {
      state.history = state.history.slice(-50);
    }
  }
  
  getCleanHistory(channelId: string): CleanMessage[] {
    const state = this.getState(channelId);
    // 可选：过滤掉机器人协调消息
    return state.history.filter(m => 
      m.authorType === 'human' || !m.metadata?.isCoordination
    );
  }
  
  private processQueue(channelId: string): void {
    const state = this.getState(channelId);
    if (state.messageQueue.length > 0) {
      // 触发下一个排队消息
      const next = state.messageQueue.shift();
      if (next) {
        // 重新处理消息
        this.handleMessage(next);
      }
    }
  }
  
  // 定期清理空闲会话
  cleanup(): void {
    const now = Date.now();
    for (const [channelId, state] of this.sessions.entries()) {
      if (now - state.lastActivity > this.IDLE_TIMEOUT) {
        this.sessions.delete(channelId);
      }
    }
  }
}
```

---

### 4. CleanHistoryManager

```typescript
// packages/openclaw/src/providers/discord/CleanHistoryManager.ts

export class CleanHistoryManager {
  /**
   * 过滤 Discord 消息历史，生成适合 LLM 的上下文
   */
  filterMessages(
    messages: MessageMetadata[],
    options: {
      keepBotCoordination?: boolean;
      maxMessages?: number;
    } = {}
  ): CleanMessage[] {
    const { keepBotCoordination = false, maxMessages = 20 } = options;
    
    return messages
      .slice(-maxMessages)
      .map(msg => this.toCleanMessage(msg, keepBotCoordination))
      .filter(msg => msg !== null) as CleanMessage[];
  }
  
  private toCleanMessage(
    msg: MessageMetadata,
    keepBotCoordination: boolean
  ): CleanMessage | null {
    // 用户消息：总是保留
    if (msg.authorType === 'human') {
      return {
        id: msg.id,
        authorType: 'human',
        content: msg.content,
        role: 'user',
      };
    }
    
    // 机器人消息：区分协调消息和普通回复
    const isCoordination = this.isCoordinationMessage(msg.content);
    
    if (isCoordination && !keepBotCoordination) {
      // 协调消息且不保留 → 过滤掉
      return null;
    }
    
    return {
      id: msg.id,
      authorType: 'bot',
      content: msg.content,
      role: 'assistant',
      metadata: {
        isCoordination,
        targetAgent: this.extractTargetAgent(msg.content),
      },
    };
  }
  
  private isCoordinationMessage(content: string): boolean {
    // 检测是否是机器人协调消息
    const patterns = [
      /@\w+\s+(你来 | 你处理 | 你负责 | 请处理)/,
      /交给\s*@\w+/,
      /派发给\s*@\w+/,
    ];
    return patterns.some(p => p.test(content));
  }
  
  private extractTargetAgent(content: string): string | undefined {
    const match = content.match(/@(\w+)/);
    return match?.[1];
  }
}
```

---

### 5. 集成到 Discord Provider

```typescript
// packages/openclaw/src/providers/discord/index.ts

import { MessageMetadataExtractor } from './MessageMetadataExtractor';
import { ResponseRuleEngine, RuleConfig } from './ResponseRuleEngine';
import { SessionStateManager } from './SessionStateManager';
import { CleanHistoryManager } from './CleanHistoryManager';

export class DiscordProvider {
  private metadataExtractor: MessageMetadataExtractor;
  private ruleEngine: ResponseRuleEngine;
  private sessionManager: SessionStateManager;
  private historyManager: CleanHistoryManager;
  
  constructor(client: Client, config: DiscordConfig) {
    this.metadataExtractor = new MessageMetadataExtractor(client.user.id);
    this.ruleEngine = new ResponseRuleEngine(client.user.id, {
      maxDepth: config.maxDepth ?? 3,
      ignoreBots: config.ignoreBots ?? true,
      blockEveryone: config.blockEveryone ?? true,
      blockHere: config.blockHere ?? true,
      requireDirectMention: config.requireDirectMention ?? true,
      queueWhenBusy: config.queueWhenBusy ?? true,
    });
    this.sessionManager = new SessionStateManager();
    this.historyManager = new CleanHistoryManager();
    
    // 定期清理空闲会话
    setInterval(() => this.sessionManager.cleanup(), 60 * 1000);
  }
  
  private async onMessageCreate(message: Message) {
    // 1. 提取元数据
    const metadata = this.metadataExtractor.extract(message);
    
    // 2. 获取会话状态
    const sessionState = this.sessionManager.getState(message.channelId);
    
    // 3. 规则引擎判断
    const result = this.ruleEngine.shouldRespond(metadata, sessionState);
    
    if (!result.allowed) {
      this.logger.debug(`Message blocked: ${result.reason}`, metadata);
      
      // 如果需要排队
      if (result.reason?.includes('queueing')) {
        sessionState.messageQueue.push(message);
      }
      return;
    }
    
    // 4. 开始处理
    const canStart = this.sessionManager.startProcessing(message.channelId);
    if (!canStart) {
      sessionState.messageQueue.push(message);
      return;
    }
    
    try {
      // 5. 获取过滤后的历史
      const history = this.sessionManager.getCleanHistory(message.channelId);
      
      // 6. 调用 LLM
      const response = await this.generateResponse(metadata, history);
      
      // 7. 发送回复
      await this.sendResponse(message, response);
      
      // 8. 更新历史
      this.sessionManager.addToHistory(message.channelId, {
        id: message.id,
        authorType: metadata.authorType,
        content: message.content,
        role: metadata.authorType === 'human' ? 'user' : 'assistant',
      });
      
    } finally {
      // 9. 完成处理
      this.sessionManager.finishProcessing(message.channelId);
    }
  }
}
```

---

## 📝 配置变更

### openclaw.json 新增字段

```json
{
  "channels": {
    "discord": {
      "accounts": { ... },
      
      // 新增：消息过滤配置
      "messageFilter": {
        "ignoreBots": true,
        "blockEveryone": true,
        "blockHere": true,
        "requireDirectMention": true,
        "maxDepth": 3,
        "queueWhenBusy": true
      },
      
      // 新增：会话管理配置
      "sessionManagement": {
        "enabled": true,
        "idleTimeoutMinutes": 5,
        "maxHistoryLength": 50,
        "filterBotCoordination": true
      }
    }
  }
}
```

---

## 🧪 测试计划

### 单元测试

```typescript
describe('ResponseRuleEngine', () => {
  it('should block bot messages when ignoreBots=true', () => {
    const engine = new ResponseRuleEngine('bot-123', { ignoreBots: true });
    const metadata = createMetadata({ authorType: 'bot' });
    expect(engine.shouldRespond(metadata).allowed).toBe(false);
  });
  
  it('should block @everyone', () => {
    const engine = new ResponseRuleEngine('bot-123', { blockEveryone: true });
    const metadata = createMetadata({ flags: { isEveryone: true } });
    expect(engine.shouldRespond(metadata).allowed).toBe(false);
  });
  
  it('should block when depth >= maxDepth', () => {
    const engine = new ResponseRuleEngine('bot-123', { maxDepth: 3 });
    const metadata = createMetadata({ depth: 3 });
    expect(engine.shouldRespond(metadata).allowed).toBe(false);
  });
});
```

### 集成测试

1. **循环防护测试** - 模拟 10 个机器人互相@
2. **@everyone 雪崩测试** - 模拟@everyone 触发
3. **深度限制测试** - 验证 depth=3 时停止
4. **会话状态测试** - 验证忙时排队

---

## 📅 实施时间线

| 阶段 | 任务 | 工时 |
|------|------|------|
| **设计** | 架构设计 + API 定义 | 2h |
| **实现** | MessageMetadataExtractor | 2h |
| **实现** | ResponseRuleEngine | 2h |
| **实现** | SessionStateManager | 2h |
| **实现** | CleanHistoryManager | 2h |
| **集成** | Discord Provider 集成 | 2h |
| **测试** | 单元测试 + 集成测试 | 3h |
| **文档** | 更新文档 + 迁移指南 | 1h |
| **总计** | | **16h** |

---

## ⚠️ 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 破坏现有功能 | 高 | 充分测试 + 灰度发布 |
| 性能开销 | 中 | 基准测试 + 优化 |
| 配置复杂 | 低 | 提供默认配置 + 迁移脚本 |

---

## 📚 相关文档

- [Issue #107](https://github.com/wanikua/danghuangshang/issues/107)
- [Discord.js Message API](https://discord.js.org/#/docs/discord.js/main/class/Message)
- [OpenClaw Provider Architecture](./architecture.md)

---

**下一步**: 王 Sir 批准后开始实现
