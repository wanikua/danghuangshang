import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Settings {
  refreshInterval: number
  theme: 'dark' | 'light'
  weatherLocation: string
  tokenAlertThreshold: number
}

const DEFAULT_SETTINGS: Settings = {
  refreshInterval: 30000, theme: 'dark', weatherLocation: 'Beijing', tokenAlertThreshold: 2000000
}

const INTERVAL_OPTIONS = [
  { value: 15000, label: '15秒' }, { value: 30000, label: '30秒' },
  { value: 60000, label: '1分钟' }, { value: 300000, label: '5分钟' }
]

export default function Settings() {
  const [settings, setSettings] = useState<Settings>(DEFAULT_SETTINGS)
  const [saved, setSaved] = useState(false)
  const [gatewayConfig, setGatewayConfig] = useState<Record<string, unknown> | null>(null)
  const [configLoading, setConfigLoading] = useState(true)
  const { theme: currentTheme, setTheme } = useTheme()
  const bg = currentTheme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = currentTheme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  useEffect(() => {
    const saved = localStorage.getItem('boluo_settings')
    if (saved) try { setSettings({ ...DEFAULT_SETTINGS, ...JSON.parse(saved) }) } catch { }

    // Fetch gateway config
    fetch('/api/config', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      .then(r => r.json())
      .then(d => { setGatewayConfig(d.config || d); setConfigLoading(false) })
      .catch(() => setConfigLoading(false))
  }, [])

  const handleSave = () => {
    localStorage.setItem('boluo_settings', JSON.stringify(settings))
    setTheme(settings.theme)
    setSaved(true); setTimeout(() => setSaved(false), 2000)
  }

  const handleReset = () => {
    setSettings(DEFAULT_SETTINGS)
    localStorage.removeItem('boluo_settings')
    setTheme('dark')
    setSaved(true); setTimeout(() => setSaved(false), 2000)
  }

  // Render config value
  const renderValue = (val: unknown, depth = 0): React.ReactNode => {
    if (val === null || val === undefined) return <span className={sub}>null</span>
    if (typeof val === 'string') {
      // Mask tokens/secrets
      if (val.length > 20 && (depth > 1)) return <span className="text-green-400">"{val.substring(0, 8)}...{val.substring(val.length - 4)}"</span>
      return <span className="text-green-400">"{val}"</span>
    }
    if (typeof val === 'number') return <span className="text-[#d4a574]">{val}</span>
    if (typeof val === 'boolean') return <span className="text-blue-400">{val.toString()}</span>
    if (Array.isArray(val)) {
      if (val.length === 0) return <span className={sub}>[]</span>
      return (
        <div className="ml-4">
          {val.map((item, i) => (
            <div key={i} className="flex items-start gap-1">
              <span className={sub}>-</span> {renderValue(item, depth + 1)}
            </div>
          ))}
        </div>
      )
    }
    if (typeof val === 'object') {
      const entries = Object.entries(val as Record<string, unknown>)
      if (entries.length === 0) return <span className={sub}>{'{}'}</span>
      return (
        <div className={depth > 0 ? 'ml-4' : ''}>
          {entries.map(([k, v]) => {
            const isSecret = /token|secret|key|password/i.test(k)
            return (
              <div key={k} className="flex items-start gap-1">
                <span className="text-[#d4a574] flex-shrink-0">{k}:</span>
                {isSecret && typeof v === 'string'
                  ? <span className="text-red-400/60">{"••••••••"}</span>
                  : renderValue(v, depth + 1)
                }
              </div>
            )
          })}
        </div>
      )
    }
    return <span>{String(val)}</span>
  }

  return (
    <div className="max-w-2xl mx-auto space-y-4 sm:space-y-6">
      <h2 className={`text-lg font-medium ${currentTheme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
        🔧 系统设置
      </h2>

      {/* 刷新间隔 */}
      <div className={`${bg} p-4 sm:p-5 rounded-lg`}>
        <h3 className={`text-xs uppercase tracking-wider mb-3 ${sub}`}>数据刷新间隔</h3>
        <select value={settings.refreshInterval} onChange={e => setSettings(s => ({ ...s, refreshInterval: Number(e.target.value) }))}
          className={`w-full px-4 py-2 rounded border text-sm ${currentTheme === 'light' ? 'bg-gray-50 border-gray-300' : 'bg-[#0d0d1a] border-[#d4a574]/30 text-[#e5e5e5]'}`}>
          {INTERVAL_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
      </div>

      {/* 主题 */}
      <div className={`${bg} p-4 sm:p-5 rounded-lg`}>
        <h3 className={`text-xs uppercase tracking-wider mb-3 ${sub}`}>默认主题</h3>
        <div className="flex gap-3">
          {[{ key: 'dark', icon: '🌙', label: '深色' }, { key: 'light', icon: '☀️', label: '浅色' }].map(t => (
            <button key={t.key} onClick={() => setSettings(s => ({ ...s, theme: t.key as 'dark' | 'light' }))}
              className={`flex-1 py-3 rounded border cursor-pointer transition-all ${
                settings.theme === t.key ? 'border-[#d4a574] bg-[#d4a574]/10' : `border-[#d4a574]/30 ${sub}`
              }`}>
              <div className="text-xl mb-1">{t.icon}</div>
              <div className="text-sm">{t.label}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Token告警 */}
      <div className={`${bg} p-4 sm:p-5 rounded-lg`}>
        <h3 className={`text-xs uppercase tracking-wider mb-3 ${sub}`}>Token告警阈值</h3>
        <input type="number" value={settings.tokenAlertThreshold}
          onChange={e => setSettings(s => ({ ...s, tokenAlertThreshold: Number(e.target.value) }))}
          className={`w-full px-4 py-2 rounded border text-sm ${currentTheme === 'light' ? 'bg-gray-50 border-gray-300' : 'bg-[#0d0d1a] border-[#d4a574]/30 text-[#e5e5e5]'}`}
          min={0} step={100000} />
        <p className={`text-xs mt-2 ${sub}`}>超过 {(settings.tokenAlertThreshold / 1000000).toFixed(1)}M 时首页显示警告</p>
      </div>

      {/* 保存 */}
      <div className="flex gap-3">
        <button onClick={handleSave}
          className="flex-1 py-3 bg-[#d4a574] text-[#0d0d1a] font-medium rounded hover:bg-[#c49464] cursor-pointer transition-all">
          {saved ? '✅ 已保存' : '保存设置'}
        </button>
        <button onClick={handleReset}
          className={`px-6 py-3 border border-[#d4a574]/30 ${sub} rounded hover:border-[#d4a574] cursor-pointer transition-all`}>
          重置
        </button>
      </div>

      {/* Gateway 配置（只读） */}
      <div className={`${bg} p-4 sm:p-5 rounded-lg`}>
        <div className="flex items-center justify-between mb-3">
          <h3 className={`text-xs uppercase tracking-wider ${sub}`}>⚙️ Gateway 配置（只读）</h3>
          {configLoading && <span className={`text-xs animate-pulse ${sub}`}>加载中...</span>}
        </div>
        {gatewayConfig ? (
          <div className={`font-mono text-[10px] sm:text-xs p-3 rounded max-h-96 overflow-auto ${
            currentTheme === 'light' ? 'bg-gray-50' : 'bg-[#0d0d1a]'
          }`}>
            {renderValue(gatewayConfig)}
          </div>
        ) : !configLoading ? (
          <div className={`text-xs ${sub} text-center py-4`}>无法加载配置</div>
        ) : null}
      </div>

      <p className={`text-xs text-center ${sub}`}>
        前端设置保存在浏览器本地存储 · Gateway配置为只读展示
      </p>
    </div>
  )
}
