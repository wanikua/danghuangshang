const crypto = require('crypto');

/**
 * Webhook 签名验证工具
 * 
 * 用法：
 * const { verifySignature } = require('./webhook-verify');
 * 
 * // GitHub
 * const valid = verifySignature(payload, signature, secret, 'github');
 * 
 * // 飞书
 * const valid = verifySignature(payload, signature, secret, 'feishu');
 */

/**
 * 验证 Webhook 签名
 * @param {string|object} payload - 请求体（原始字符串或对象）
 * @param {string} signature - 签名头（如：sha256=abc123）
 * @param {string} secret - Webhook 密钥
 * @param {string} type - 类型：'github' | 'feishu' | 'generic'
 * @returns {boolean} 验证结果
 */
function verifySignature(payload, signature, secret, type = 'github') {
  if (!payload || !signature || !secret) {
    console.warn('[Webhook Verify] Missing required parameters');
    return false;
  }

  // 转换为字符串
  const body = typeof payload === 'string' ? payload : JSON.stringify(payload);

  try {
    switch (type) {
      case 'github':
        return verifyGitHubSignature(body, signature, secret);
      case 'feishu':
        return verifyFeishuSignature(body, signature, secret);
      case 'generic':
        return verifyGenericSignature(body, signature, secret);
      default:
        console.warn(`[Webhook Verify] Unknown type: ${type}`);
        return false;
    }
  } catch (error) {
    console.error('[Webhook Verify] Error:', error.message);
    return false;
  }
}

/**
 * GitHub Webhook 签名验证
 * GitHub 使用 HMAC-SHA256，签名头格式：sha256=<hex>
 */
function verifyGitHubSignature(body, signature, secret) {
  // 提取签名值
  const sigMatch = signature.match(/^sha256=([a-f0-9]+)$/i);
  if (!sigMatch) {
    console.warn('[Webhook Verify] Invalid GitHub signature format');
    return false;
  }

  const providedSig = sigMatch[1].toLowerCase();

  // 计算期望签名
  const expectedSig = crypto
    .createHmac('sha256', secret)
    .update(body, 'utf8')
    .digest('hex')
    .toLowerCase();

  // 常量时间比较（防止时序攻击）
  const valid = crypto.timingSafeEqual(
    Buffer.from(providedSig, 'hex'),
    Buffer.from(expectedSig, 'hex')
  );

  if (!valid) {
    console.warn('[Webhook Verify] GitHub signature mismatch');
  }

  return valid;
}

/**
 * 飞书 Webhook 签名验证
 * 飞书使用 HMAC-SHA256，签名头格式：X-Lark-Signature
 */
function verifyFeishuSignature(body, signature, secret) {
  // 飞书签名可能是 base64 或 hex
  let providedSig;
  try {
    // 尝试 hex
    if (/^[a-f0-9]+$/i.test(signature)) {
      providedSig = signature.toLowerCase();
    } else {
      // 尝试 base64
      providedSig = Buffer.from(signature, 'base64').toString('hex').toLowerCase();
    }
  } catch (e) {
    console.warn('[Webhook Verify] Invalid Feishu signature format');
    return false;
  }

  // 计算期望签名
  const expectedSig = crypto
    .createHmac('sha256', secret)
    .update(body, 'utf8')
    .digest('hex')
    .toLowerCase();

  // 常量时间比较
  const valid = crypto.timingSafeEqual(
    Buffer.from(providedSig, 'hex'),
    Buffer.from(expectedSig, 'hex')
  );

  if (!valid) {
    console.warn('[Webhook Verify] Feishu signature mismatch');
  }

  return valid;
}

/**
 * 通用签名验证（简单 HMAC-SHA256）
 */
function verifyGenericSignature(body, signature, secret) {
  const expectedSig = crypto
    .createHmac('sha256', secret)
    .update(body, 'utf8')
    .digest('hex')
    .toLowerCase();

  const providedSig = signature.toLowerCase();

  return crypto.timingSafeEqual(
    Buffer.from(providedSig, 'hex'),
    Buffer.from(expectedSig, 'hex')
  );
}

/**
 * 生成签名（用于测试）
 */
function generateSignature(payload, secret, type = 'github') {
  const body = typeof payload === 'string' ? payload : JSON.stringify(payload);
  const sig = crypto
    .createHmac('sha256', secret)
    .update(body, 'utf8')
    .digest('hex');

  return type === 'github' ? `sha256=${sig}` : sig;
}

module.exports = {
  verifySignature,
  verifyGitHubSignature,
  verifyFeishuSignature,
  verifyGenericSignature,
  generateSignature
};
