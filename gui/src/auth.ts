/**
 * 动态获取认证令牌
 *
 * 避免在模块顶层静态读取 localStorage，因为用户登录后
 * token 才写入 localStorage，但模块加载在登录之前就完成了，
 * 导致所有后续请求带着空 token 发出，返回 401。
 *
 * 用法：将原来的
 *   const AUTH_TOKEN = localStorage.getItem('boluo_auth_token') || ''
 * 替换为
 *   import { getAuthToken } from '../auth'
 *   // 在需要时调用 getAuthToken()
 */

export function getAuthToken(): string {
  return localStorage.getItem('boluo_auth_token') || ''
}
