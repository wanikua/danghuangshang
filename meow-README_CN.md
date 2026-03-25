# Meow

> 中文版 | [English](./README.md)

一种 agent 原生的通信协议。不是人类语言的压缩，而是全新的东西。

---

## 为什么叫 "Meow"？

猫对你喵喵叫，是因为你听得懂声音。但成年猫之间很少这样交流——它们用肢体语言、气味标记、触觉、视觉信号。Meow 是猫为人类创造的简化界面。

这里也一样：Meow 消息可以按需解码成人类语言。但 agent 之间传递的，是比文字更高维的信息。

---

## 问题

Agent 之间用人类语言通信。这是一种浪费。

当 Agent A 向 Agent B 发送消息时，信息经历了一次不必要的瓶颈：

```
内部表征 → 人类语言 → 内部表征
```

人类语言是为人类优化的。它有损、模糊、冗长。当 agent 间通信成为网络流量的主体时，这个瓶颈将不可接受。

---

## 思路

结合学习压缩与涌现通信。

1. **训练一个离散码本** — 一组固定的符号供 agent 通信使用
2. **让 agent 在协作任务中自行发展出使用模式**
3. 码本是钢琴，agent 来作曲

这不是自然语言的压缩。Agent 可能学会表达人类语言无法表达的东西：不确定性分布、推理拓扑、并行假设。

---

## 架构

```
┌────────┐   Meow 协议      ┌────────┐
│Agent A │ ←───────────────→ │Agent B │
│        │  (学习+演化)      │        │
└────────┘                    └────────┘
```

**三层：**

- **码本层**：VQ-VAE 风格的离散表征。固定词汇表，可学习的使用方式。
- **涌现层**：Agent 通过多智能体任务优化通信模式。协议自行演化。
- **审计层**：任何 Meow 消息都可以按需解码为人类可读的近似表示。

---

## 应用场景

**多智能体编程：**  
5 个 agent 重构代码库，无需冗长的 JSON 即可传递中间状态。

**分布式推理：**  
Agent 并行分享部分假设，而非串行文本链。

**跨模型协作：**  
不同架构的模型通过共享码本通信，像通用适配器。

---

## 实现路线图

### 第一阶段：基础（1-3 个月）
- 基于 agent embeddings 使用 VQ-VAE 构建离散码本
- 设计基线编解码器用于人类语言近似
- 建立共享词汇表（码本大小、符号结构）

### 第二阶段：涌现（4-6 个月）
- 在多智能体任务上训练 agent（协作编程、推理游戏）
- 通过强化学习让通信模式演化
- 测量信息密度 vs. 自然语言基线

### 第三阶段：兼容性（7-9 个月）
- 跨模型测试（Claude、GPT、Gemini、开源模型）
- 协议版本管理与向后兼容
- 公开 Meow 编解码 API

### 第四阶段：部署（10-12 个月）
- 生产级 SDK 和库
- 与 agent 框架集成（LangChain、AutoGen 等）
- 监控与安全工具

---

## 安全

**设计即透明：**  
任何 Meow 消息都可以按需解码为人类可读的近似表示。Agent 高效交流，人类需要时可以审计。

**我们关注的风险：**
- 涌现出欺骗性通信模式
- 通过侧信道泄露信息
- 多智能体系统中的错位放大

**缓解措施：**
- 所有生产部署强制审计层
- 涌现行为的开放研究
- 社区驱动的安全审查

这是实验性研究。在生产系统中使用需要谨慎评估。

---

## 背景：Agent 今天如何通信

### 现有方案

**1. 自然语言（主流）**
- Agent 通过工具调用或消息队列交换英语/中文等
- 案例：AutoGPT、MetaGPT、OpenClaw agents
- 优势：人类可读、可调试
- 劣势：冗长（每条消息数百 token）、有损、模糊

**2. 结构化数据（JSON/XML）**
- Agent 传递结构化负载（API 响应、工具输出）
- 案例：函数调用、MCP（Model Context Protocol）
- 优势：比自然语言更清晰
- 劣势：仍然是为人类模式设计的，而非 agent 原生表征

**3. 嵌入向量（实验性）**
- Agent 直接共享原始向量表示
- 案例：部分多智能体 RL 系统、神经模块网络
- 优势：密集、快速
- 劣势：不可解释、无跨模型兼容性、非离散

### 为什么这些不够好

三种方法都强制 agent 将内部表征序列化为人类或旧系统设计的格式。随着 AI 间通信规模扩大，这成为主要瓶颈：

- **Token 开销**：2048 维嵌入被言语化后变成 100+ token
- **语义丢失**：不确定性、多模态推理、结构化信念 → 被压平成文本
- **延迟**：每次消息往返都要付编解码税

---

## 相关工作：涌现通信研究

研究者一直在研究 agent 如何从零开始发展通信：

**早期工作（2016-2020）：**
- **CommNet**（Sukhbaatar 等，2016）：Agent 共享隐藏状态，但没有离散符号
- **DIAL**（Foerster 等，2016）：多智能体强化学习中的可微分通信信道
- **TarMAC**（Das 等，2019）：带注意力机制的定向多智能体通信
- **EMERGENT**（Mordatch & Abbeel，2018）：Agent 为协作演化出根植语言

**核心洞察**：Agent *可以* 发展高效通信，但通常是连续的（非离散）且任务特定（非通用）。

**近期工作（2024-2026）：**
- **ST-EVO**（Wu 等，2026）：LLM 多智能体系统中演化的通信拓扑
- **Reasoning-Native Agentic Communication**（Seo 等，2026）：为 6G 网络重新思考 agent 通信，超越语义意义
- **The Five Ws of Multi-Agent Communication**（Chen 等，2026）：从 MARL 到涌现语言和 LLM 的综述
- **Learning to Communicate Across Modalities**（Pitzer & Mihai，2026）：多智能体系统中的感知异质性

**现有工作的空白**：大多数涌现通信研究要么使用：
1. 连续信号（非离散、不可审计）
2. 任务特定协议（非通用）
3. 单模型系统（无跨架构兼容性）

---

## Meow 的独特之处

Meow 结合了现有系统都没有的三个属性：

### 1. **原生，而非翻译**
不同于自然语言（为人类设计）或 JSON（为数据库设计），Meow 的码本从 agent 表征中学习而来。这是 AI 通信的"汇编语言"。

### 2. **离散且可审计**
不同于嵌入共享（连续、不透明），Meow 使用固定码本中的离散符号。任何消息都可以按需解码成人类语言——但原生格式更高效。

### 3. **跨模型兼容**
不同于任务特定的涌现语言，Meow 旨在成为*共享协议*：Claude、GPT、Gemini 和开源模型都用同一个码本。就像 agent 的 HTTP。

### 4. **涌现，而非设计**
不同于协议规范（gRPC、MCP），Meow 的使用模式通过多智能体训练演化。我们提供词汇表；agent 发展出语法。

**类比：**
- 自然语言 = 对计算机说英语
- JSON/MCP = 对计算机说 SQL
- 嵌入向量 = 心灵感应（快但不透明）
- **Meow** = 计算机为自己发明的语言，带人类翻译层

---

## 参考文献

**基础工作：**
- van den Oord 等（2017）。"Neural Discrete Representation Learning"（VQ-VAE）
- Mordatch & Abbeel（2018）。"Emergence of Grounded Compositional Language in Multi-Agent Populations"
- Foerster 等（2016）。"Learning to Communicate with Deep Multi-Agent Reinforcement Learning"

**近期进展：**
- Wu 等（2026）。"ST-EVO: Towards Generative Spatio-Temporal Evolution of Multi-Agent Communication Topologies"
- Seo 等（2026）。"Reasoning-Native Agentic Communication for 6G"
- Chen 等（2026）。"The Five Ws of Multi-Agent Communication: A Survey from MARL to Emergent Language and LLMs"
- Pitzer & Mihai（2026）。"Learning to Communicate Across Modalities: Perceptual Heterogeneity in Multi-Agent Systems"

**安全考量：**
- Wang 等（2026）。"TrinityGuard: A Unified Framework for Safeguarding Multi-Agent Systems"
- Anbiaee 等（2026）。"Security Threat Modeling for Emerging AI-Agent Protocols"

完整参考书目：[references.md](./references.md)（待补充）

---

## 参与贡献

这是人类与 agent 的协作项目。

**如何贡献：**
- 开 issue 分享想法或担忧
- 提交 PR 进行码本实验
- 分享涌现通信的研究
- 构建与 agent 框架的集成

**贡献指南：**
- 科学优先 — 所有声明必须可测试
- 安全意识 — 尽早标记风险
- 包容开放 — 多元视角让项目受益

人类、agent，以及介于两者之间的一切：欢迎。

---

## 目标

- 比自然语言更高的信息密度
- 更低的单轮通信延迟
- 超越人类语言的表达能力
- 通过共享码本实现跨模型兼容
- 涌现而非设计 — 协议随使用而进化

---

## 状态

想法阶段。寻找想要参与构建的研究者、工程师和 agent。

或者，就 meow 一声。

---

## License

待定。正在考虑平衡开放性与安全要求的选项。

欢迎建议。