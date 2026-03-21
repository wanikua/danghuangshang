#!/usr/bin/env node
/**
 * Context Compressor - 智能上下文压缩
 * 
 * @fileoverview 解决长任务链 context 爆炸问题
 * @version 1.0.0
 * @author 工部
 */
 * 
 * 解决长任务链 context 爆炸问题
 * - 保留关键决策、交付物、错误信息
 * - 压缩中间讨论、尝试过程
 * - 用 LLM 生成摘要
 * 
 * 用法：
 *   node context-compressor.js compress --input conversation.json --output compressed.json
 *   node context-compressor.js summarize --input long_text.txt --max-tokens 500
 */

const fs = require('fs');
const path = require('path');

// 配置
const Config = {
  // 保留的内容类型
  keep: [
    'decision',      // 关键决策
    'artifact',      // 交付物（代码、文档、截图链接）
    'error',         // 错误信息
    'approval',      // 用户确认
    'plan',          // 执行计划
    'result'         // 最终结果
  ],
  
  // 压缩的内容类型
  compress: [
    'discussion',    // 讨论过程
    'attempt',       // 尝试过程
    'brainstorm',    // 头脑风暴
    'clarification'  // 澄清问答（非关键）
  ],
  
  // 触发压缩的阈值
  thresholds: {
    messageCount: 20,      // 消息数超过 20 条开始压缩
    tokenCount: 4000,      // token 数超过 4000 开始压缩
    ageMinutes: 30         // 对话超过 30 分钟开始压缩
  },
  
  // 摘要配置
  summary: {
    maxTokens: 500,        // 摘要最大 token 数
    style: 'concise'       // 摘要风格：concise / detailed
  }
};

// 消息类型识别
function identifyMessageType(message) {
  const text = message.content?.toLowerCase() || '';
  const role = message.role || 'user';
  
  // 关键决策
  if (text.includes('决定') || text.includes('采用') || text.includes('选择') || text.includes('decided') || text.includes('adopt')) {
    return 'decision';
  }
  
  // 交付物
  if (text.includes('代码') || text.includes('文档') || text.includes('完成') || text.includes('提交') || 
      text.includes('code') || text.includes('document') || text.includes('completed') || text.includes('commit')) {
    return 'artifact';
  }
  
  // 错误信息
  if (text.includes('错误') || text.includes('失败') || text.includes('bug') || text.includes('error') || text.includes('failed')) {
    return 'error';
  }
  
  // 用户确认
  if (role === 'user' && (text.includes('确认') || text.includes('同意') || text.includes('批准') || text.includes('approve'))) {
    return 'approval';
  }
  
  // 执行计划
  if (text.includes('计划') || text.includes('步骤') || text.includes('plan') || text.includes('step')) {
    return 'plan';
  }
  
  // 结果
  if (text.includes('结果') || text.includes('完成') || text.includes('总结') || text.includes('result') || text.includes('summary')) {
    return 'result';
  }
  
  // 讨论过程
  if (text.includes('讨论') || text.includes('考虑') || text.includes('可能') || text.includes('discuss') || text.includes('consider')) {
    return 'discussion';
  }
  
  // 尝试过程
  if (text.includes('尝试') || text.includes('试试') || text.includes('attempt') || text.includes('try')) {
    return 'attempt';
  }
  
  return 'other';
}

// 压缩对话
function compressConversation(messages, options = {}) {
  const {
    keepTypes = Config.keep,
    compressTypes = Config.compress,
    maxMessages = options.maxMessages || 50
  } = options;
  
  // 识别每条消息的类型
  const messagesWithType = messages.map(msg => ({
    ...msg,
    messageType: identifyMessageType(msg)
  }));
  
  // 分类
  const kept = [];
  const toCompress = [];
  
  for (const msg of messagesWithType) {
    if (keepTypes.includes(msg.messageType)) {
      kept.push(msg);
    } else if (compressTypes.includes(msg.messageType)) {
      toCompress.push(msg);
    } else {
      // 其他消息，根据长度决定保留还是压缩
      if ((msg.content?.length || 0) < 100) {
        kept.push(msg);
      } else {
        toCompress.push(msg);
      }
    }
  }
  
  // 生成压缩摘要
  let compressedSummary = null;
  if (toCompress.length > 0) {
    compressedSummary = generateSummary(toCompress, options);
  }
  
  // 构建压缩后的上下文
  const compressed = {
    original: {
      messageCount: messages.length,
      tokenEstimate: estimateTokens(messages)
    },
    compressed: {
      messageCount: kept.length + (compressedSummary ? 1 : 0),
      tokenEstimate: estimateTokens(kept) + (compressedSummary ? estimateTokens([{ content: compressedSummary }]) : 0)
    },
    messages: kept,
    summary: compressedSummary,
    compressionRate: messages.length > 0 
      ? Math.round((1 - (kept.length + (compressedSummary ? 1 : 0)) / messages.length) * 100) 
      : 0
  };
  
  return compressed;
}

// 生成摘要（简单版本，实际可调用 LLM）
function generateSummary(messages, options = {}) {
  const { maxTokens = Config.summary.maxTokens, style = Config.summary.style } = options;
  
  // 提取关键信息
  const topics = new Set();
  const actions = [];
  const issues = [];
  
  for (const msg of messages) {
    const text = msg.content || '';
    
    // 提取主题
    if (text.length > 20) {
      const firstSentence = text.split(/[.。!?！？]/)[0];
      if (firstSentence.length > 10) {
        topics.add(firstSentence.slice(0, 50));
      }
    }
    
    // 提取动作
    if (text.includes('实现') || text.includes('write') || text.includes('create')) {
      actions.push(text.slice(0, 100));
    }
    
    // 提取问题
    if (text.includes('问题') || text.includes('issue') || text.includes('problem')) {
      issues.push(text.slice(0, 100));
    }
  }
  
  // 生成摘要文本
  let summary = '[讨论摘要] ';
  
  if (topics.size > 0) {
    summary += `涉及主题：${Array.from(topics).slice(0, 5).join('；')}。`;
  }
  
  if (actions.length > 0) {
    summary += `执行操作：${actions.slice(0, 3).join('；')}。`;
  }
  
  if (issues.length > 0) {
    summary += `遇到问题：${issues.slice(0, 3).join('；')}。`;
  }
  
  summary += `共 ${messages.length} 条消息已压缩为此摘要。`;
  
  return summary;
}

// 估算 token 数（简单估算：4 字符≈1 token）
function estimateTokens(messages) {
  const totalChars = messages.reduce((sum, msg) => sum + (msg.content?.length || 0), 0);
  return Math.round(totalChars / 4);
}

// 为下游 Agent 准备上下文
function prepareDownstreamContext(taskStore, taskId, stepId, options = {}) {
  const input = taskStore.getInput(taskId, stepId);
  if (!input) {
    return null;
  }
  
  const {
    compressThreshold = Config.thresholds.messageCount,
    includeSummary = true
  } = options;
  
  // 构建原始上下文
  const context = {
    task: input.task,
    agent: input.agent,
    stepInfo: {
      current: input.context.currentStep,
      total: input.context.totalSteps,
      originalTask: input.context.originalTask
    }
  };
  
  // 添加上游输出
  if (input.upstreamOutputs) {
    context.upstream = {};
    
    for (const [stepId, stepData] of Object.entries(input.upstreamOutputs)) {
      const output = stepData.output;
      
      // 如果输出包含对话历史，进行压缩
      if (output?.conversation && output.conversation.length > compressThreshold) {
        const compressed = compressConversation(output.conversation, options);
        context.upstream[stepId] = {
          agent: stepData.agent,
          task: stepData.task,
          result: output.result,
          artifacts: output.artifacts,
          conversationSummary: includeSummary ? compressed.summary : null,
          compressed: true,
          compressionRate: compressed.compressionRate
        };
      } else {
        context.upstream[stepId] = {
          agent: stepData.agent,
          task: stepData.task,
          output: output
        };
      }
    }
  }
  
  return context;
}

// CLI 主函数
function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  if (!command) {
    console.log(`
Context Compressor - 智能上下文压缩

用法：
  node context-compressor.js <command> [options]

命令：
  compress    压缩对话
  summarize   生成摘要
  prepare     为下游 Agent 准备上下文

示例：
  node context-compressor.js compress --input conversation.json --output compressed.json
  node context-compressor.js summarize --input long_text.txt --max-tokens 500
  node context-compressor.js prepare --task task_123 --step 2
`);
    return;
  }
  
  // 解析参数
  const params = {};
  for (let i = 1; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      const key = args[i].slice(2);
      const value = args[i + 1]?.startsWith('--') ? true : args[i + 1];
      params[key] = value;
      if (!args[i + 1]?.startsWith('--')) i++;
    }
  }
  
  switch (command) {
    case 'compress': {
      const messages = JSON.parse(fs.readFileSync(params.input, 'utf-8'));
      const compressed = compressConversation(messages, params);
      
      if (params.output) {
        fs.writeFileSync(params.output, JSON.stringify(compressed, null, 2), 'utf-8');
        console.log(`✅ 压缩完成：${params.output}`);
      } else {
        console.log(JSON.stringify(compressed, null, 2));
      }
      
      console.log(`\n压缩率：${compressed.compressionRate}%`);
      console.log(`原始：${compressed.original.messageCount} 条消息 (~${compressed.original.tokenEstimate} tokens)`);
      console.log(`压缩后：${compressed.compressed.messageCount} 条消息 (~${compressed.compressed.tokenEstimate} tokens)`);
      break;
    }
    
    case 'summarize': {
      const text = fs.readFileSync(params.input, 'utf-8');
      const messages = [{ content: text }];
      const summary = generateSummary(messages, { maxTokens: params.maxTokens });
      
      console.log(summary);
      break;
    }
    
    case 'prepare': {
      const taskStore = require('./task-store');
      const context = prepareDownstreamContext(taskStore, params.task, params.step);
      
      if (context) {
        console.log(JSON.stringify(context, null, 2));
      }
      break;
    }
    
    default:
      console.error(`❌ 未知命令：${command}`);
  }
}

// 导出
module.exports = {
  Config,
  identifyMessageType,
  compressConversation,
  generateSummary,
  estimateTokens,
  prepareDownstreamContext
};

// 运行 CLI
if (require.main === module) {
  main();
}
