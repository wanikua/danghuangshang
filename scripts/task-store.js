#!/usr/bin/env node
/**
 * Task Store - 任务状态共享存储
 * 
 * @fileoverview 解决多 Agent 协作中的信息孤岛问题
 * @version 1.0.0
 * @author 工部
 */
 * 
 * 解决多 Agent 协作中的信息孤岛问题
 * - 任务创建、状态更新、输出收集
 * - 依赖管理、自动注入上游输出
 * - 支持 SQLite 持久化
 * 
 * 用法：
 *   node task-store.js create --id task_123 --plan plan.json
 *   node task-store.js update --task task_123 --step 1 --status completed
 *   node task-store.js get-input --task task_123 --step 2
 *   node task-store.js status --task task_123
 */

const fs = require('fs');
const path = require('path');

// 配置
const TASK_STORE_DIR = process.env.TASK_STORE_DIR || path.join(process.env.HOME, '.clawd', 'task-store');
const DB_FILE = path.join(TASK_STORE_DIR, 'tasks.json');

// 确保目录存在
if (!fs.existsSync(TASK_STORE_DIR)) {
  fs.mkdirSync(TASK_STORE_DIR, { recursive: true });
}

// 任务状态枚举
const TaskState = {
  PENDING: 'pending',
  RUNNING: 'running',
  SUCCESS: 'success',
  FAILED: 'failed',
  RETRYING: 'retrying',
  CANCELLED: 'cancelled',
  REVISION_REQUIRED: 'revision_required'
};

// 错误类型枚举
const ErrorType = {
  TRANSIENT: 'transient',    // 临时错误（网络、限流）
  PERMANENT: 'permanent',    // 永久错误（bug、逻辑错误）
  REJECTED: 'rejected'       // 审查驳回
};

// 读取数据库
function readDB() {
  try {
    if (fs.existsSync(DB_FILE)) {
      return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
    }
  } catch (e) {
    console.error('读取数据库失败:', e.message);
  }
  return { tasks: {}, metadata: { version: '1.0.0', createdAt: new Date().toISOString() } };
}

// 写入数据库
function writeDB(db) {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf-8');
}

// 创建任务
function createTask(taskId, plan) {
  const db = readDB();
  
  const task = {
    id: taskId,
    plan: plan,
    steps: plan.steps?.map((step, idx) => ({
      id: step.id || idx + 1,
      agent: step.agent,
      task: step.task,
      dependencies: step.dependencies || [],
      status: TaskState.PENDING,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      output: null,
      error: null,
      retryCount: 0,
      revisionReason: null
    })) || [],
    status: TaskState.PENDING,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    completedAt: null
  };
  
  db.tasks[taskId] = task;
  writeDB(db);
  
  console.log(`✅ 任务已创建：${taskId}`);
  console.log(`   步骤数：${task.steps.length}`);
  return task;
}

// 更新步骤状态
function updateStep(taskId, stepId, updates) {
  const db = readDB();
  const task = db.tasks[taskId];
  
  if (!task) {
    console.error(`❌ 任务不存在：${taskId}`);
    return null;
  }
  
  const step = task.steps.find(s => s.id === stepId || s.agent === stepId);
  if (!step) {
    console.error(`❌ 步骤不存在：${stepId}`);
    return null;
  }
  
  // 更新字段
  Object.assign(step, updates, { updatedAt: new Date().toISOString() });
  
  // 更新任务状态
  task.status = calculateTaskStatus(task.steps);
  task.updatedAt = new Date().toISOString();
  
  if (task.status === TaskState.SUCCESS) {
    task.completedAt = new Date().toISOString();
  }
  
  writeDB(db);
  
  console.log(`✅ 步骤已更新：${taskId} #${step.id}`);
  console.log(`   状态：${step.status}`);
  return step;
}

// 计算任务整体状态
function calculateTaskStatus(steps) {
  const allCompleted = steps.every(s => s.status === TaskState.SUCCESS);
  const hasFailed = steps.some(s => s.status === TaskState.FAILED && s.retryCount >= 3);
  const hasRunning = steps.some(s => s.status === TaskState.RUNNING);
  const hasPending = steps.some(s => s.status === TaskState.PENDING);
  
  if (allCompleted) return TaskState.SUCCESS;
  if (hasFailed) return TaskState.FAILED;
  if (hasRunning) return TaskState.RUNNING;
  if (hasPending) return TaskState.PENDING;
  return TaskState.RUNNING;
}

// 获取步骤的输入（自动聚合上游输出）
function getInput(taskId, stepId) {
  const db = readDB();
  const task = db.tasks[taskId];
  
  if (!task) {
    console.error(`❌ 任务不存在：${taskId}`);
    return null;
  }
  
  const stepIndex = task.steps.findIndex(s => s.id === stepId || s.agent === stepId);
  if (stepIndex === -1) {
    console.error(`❌ 步骤不存在：${stepId}`);
    return null;
  }
  
  const step = task.steps[stepIndex];
  
  // 获取依赖的步骤
  const dependencies = step.dependencies.length > 0 
    ? step.dependencies 
    : task.steps.slice(0, stepIndex).map(s => s.id);
  
  // 聚合上游输出
  const upstreamOutputs = {};
  for (const depId of dependencies) {
    const depStep = task.steps.find(s => s.id === depId);
    if (depStep) {
      if (depStep.status !== TaskState.SUCCESS) {
        console.error(`⚠️  依赖步骤未完成：${depId} (状态：${depStep.status})`);
        return null;
      }
      upstreamOutputs[depId] = {
        agent: depStep.agent,
        task: depStep.task,
        output: depStep.output,
        completedAt: depStep.completedAt
      };
    }
  }
  
  return {
    taskId,
    stepId: step.id,
    agent: step.agent,
    task: step.task,
    upstreamOutputs: Object.keys(upstreamOutputs).length > 0 ? upstreamOutputs : null,
    context: {
      originalTask: task.plan.description || task.plan.task || '未命名任务',
      totalSteps: task.steps.length,
      currentStep: stepIndex + 1
    }
  };
}

// 获取任务状态
function getTaskStatus(taskId) {
  const db = readDB();
  const task = db.tasks[taskId];
  
  if (!task) {
    console.error(`❌ 任务不存在：${taskId}`);
    return null;
  }
  
  return {
    id: task.id,
    status: task.status,
    progress: `${task.steps.filter(s => s.status === TaskState.SUCCESS).length}/${task.steps.length}`,
    steps: task.steps.map(s => ({
      id: s.id,
      agent: s.agent,
      task: s.task,
      status: s.status,
      duration: s.completedAt 
        ? Math.round((new Date(s.completedAt) - new Date(s.createdAt)) / 1000) + 's'
        : null,
      error: s.error ? s.error.message : null
    })),
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    completedAt: task.completedAt
  };
}

// 列出所有任务
function listTasks(limit = 10) {
  const db = readDB();
  const tasks = Object.values(db.tasks)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, limit);
  
  return tasks.map(t => ({
    id: t.id,
    status: t.status,
    progress: `${t.steps.filter(s => s.status === TaskState.SUCCESS).length}/${t.steps.length}`,
    createdAt: t.createdAt
  }));
}

// CLI 主函数
function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  if (!command) {
    console.log(`
Task Store - 任务状态共享存储

用法：
  node task-store.js <command> [options]

命令：
  create    创建任务
  update    更新步骤状态
  get-input 获取步骤输入（自动聚合上游输出）
  status    查看任务状态
  list      列出所有任务
  delete    删除任务

示例：
  node task-store.js create --id task_123 --plan plan.json
  node task-store.js update --task task_123 --step 1 --status completed --output output.json
  node task-store.js get-input --task task_123 --step 2
  node task-store.js status --task task_123
  node task-store.js list --limit 20
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
    case 'create': {
      const plan = params.plan ? JSON.parse(fs.readFileSync(params.plan, 'utf-8')) : { steps: [] };
      createTask(params.id || `task_${Date.now()}`, plan);
      break;
    }
    
    case 'update': {
      const output = params.output ? JSON.parse(fs.readFileSync(params.output, 'utf-8')) : null;
      const error = params.error ? { message: params.error, type: params.errorType || ErrorType.PERMANENT } : null;
      updateStep(params.task, params.step, {
        status: params.status,
        output,
        error,
        retryCount: params.retryCount ? parseInt(params.retryCount) : 0,
        revisionReason: params.revisionReason || null,
        completedAt: params.status === TaskState.SUCCESS ? new Date().toISOString() : null
      });
      break;
    }
    
    case 'get-input': {
      const input = getInput(params.task, params.step);
      if (input) {
        console.log(JSON.stringify(input, null, 2));
      }
      break;
    }
    
    case 'status': {
      const status = getTaskStatus(params.task);
      if (status) {
        console.log(JSON.stringify(status, null, 2));
      }
      break;
    }
    
    case 'list': {
      const tasks = listTasks(parseInt(params.limit) || 10);
      console.log(JSON.stringify(tasks, null, 2));
      break;
    }
    
    case 'delete': {
      const db = readDB();
      delete db.tasks[params.task];
      writeDB(db);
      console.log(`✅ 任务已删除：${params.task}`);
      break;
    }
    
    default:
      console.error(`❌ 未知命令：${command}`);
  }
}

// 导出供其他模块使用
module.exports = {
  TaskState,
  ErrorType,
  createTask,
  updateStep,
  getInput,
  getTaskStatus,
  listTasks,
  readDB,
  writeDB
};

// 运行 CLI
if (require.main === module) {
  main();
}
