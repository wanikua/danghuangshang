const express = require('express');
const { verifySignature } = require('../webhook-verify');

/**
 * Webhook 安全中间件
 * 
 * 用法：
 * const { createWebhookMiddleware } = require('./middleware/webhook');
 * app.use('/webhooks/github', createWebhookMiddleware('github'));
 */

/**
 * 创建 Webhook 验证中间件
 * @param {string} type - 'github' | 'feishu' | 'generic'
 * @returns {Function} Express 中间件
 */
function createWebhookMiddleware(type) {
  return (req, res, next) => {
    // 跳过验证（开发环境）
    if (process.env.WEBHOOK_VERIFY_DISABLED === 'true') {
      console.warn('[Webhook] Verification disabled (dev mode)');
      return next();
    }

    // 获取签名头
    let signature;
    switch (type) {
      case 'github':
        signature = req.headers['x-hub-signature-256'];
        break;
      case 'feishu':
        signature = req.headers['x-lark-signature'];
        break;
      default:
        signature = req.headers['x-webhook-signature'];
    }

    if (!signature) {
      console.warn('[Webhook] Missing signature header');
      return res.status(401).json({
        error: 'Missing signature',
        message: 'Webhook signature required'
      });
    }

    // 获取请求体（需要 body-parser 先处理）
    const body = req.rawBody || JSON.stringify(req.body);

    // 获取密钥
    const secret = getWebhookSecret(type);
    if (!secret) {
      console.error('[Webhook] No secret configured');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'Webhook secret not configured'
      });
    }

    // 验证签名
    const valid = verifySignature(body, signature, secret, type);

    if (!valid) {
      console.warn('[Webhook] Invalid signature from', req.ip);
      return res.status(401).json({
        error: 'Invalid signature',
        message: 'Webhook signature verification failed'
      });
    }

    console.log('[Webhook] Signature verified:', type);
    next();
  };
}

/**
 * 获取 Webhook 密钥
 * 从环境变量读取
 */
function getWebhookSecret(type) {
  const envVar = `WEBHOOK_${type.toUpperCase()}_SECRET`;
  return process.env[envVar];
}

/**
 * 日志记录中间件
 */
function webhookLogger(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[Webhook] ${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
  });
  next();
}

module.exports = {
  createWebhookMiddleware,
  webhookLogger
};
