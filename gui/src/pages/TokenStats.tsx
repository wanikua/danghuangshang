import { useState, useEffect } from "react"
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend,
} from "recharts"
import type { SystemStatus } from "../types"
import { useTheme } from "../theme"
import { getAuthToken } from '../auth'

interface Props { data: SystemStatus }

const COLORS = ["#d4a574", "#c9a96e", "#22c55e", "#3b82f6", "#ef4444", "#8b5cf6", "#f59e0b", "#ec4899"]

function fmt(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(2) + "M"
  if (n >= 1_000) return (n / 1_000).toFixed(1) + "K"
  return n.toString()
}

interface DeptTokens { department: string; tokens: number; cost: string }
interface TrendPoint { date: string; tokens: number }

export default function TokenStats({ data }: Props) {
  const { theme } = useTheme()
  const [deptTokens, setDeptTokens] = useState<DeptTokens[]>([])
  const [_trend, setTrend] = useState<TrendPoint[]>([])
  const [tokenPrice, setTokenPrice] = useState(0.3)
  const [totalApiTokens, setTotalApiTokens] = useState(0)
  const [loading, setLoading] = useState(true)
  const bg = theme === 'light' ? 'bg-white border border-gray-200' : 'bg-[#1a1a2e]'
  const sub = theme === 'light' ? 'text-gray-500' : 'text-[#a3a3a3]'

  useEffect(() => {
    fetch('/api/tokens', { headers: { Authorization: `Bearer ${getAuthToken()}` } })
      .then(r => r.json())
      .then(d => {
        setDeptTokens(d.byDepartment || [])
        setTrend(d.trend || [])
        setTokenPrice(d.tokenPrice || 0.3)
        setTotalApiTokens(d.totalTokens || 0)
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }, [])

  // Combine props data with API data
  const barData = data.botAccounts
    .map(b => ({
      name: b.displayName || b.name,
      input: b.inputTokens,
      output: b.outputTokens,
      total: b.totalTokens,
    }))
    .sort((a, b) => b.total - a.total)
    .filter(d => d.total > 0)

  const totalInput = data.botAccounts.reduce((s, b) => s + b.inputTokens, 0)
  const totalOutput = data.botAccounts.reduce((s, b) => s + b.outputTokens, 0)
  const totalTokens = totalInput + totalOutput

  // Use per-department data from API for pie chart
  const pieData = deptTokens.length > 0
    ? deptTokens.filter(d => d.tokens > 0).map(d => ({ name: d.department, value: d.tokens }))
    : [{ name: "Input", value: totalInput }, { name: "Output", value: totalOutput }]

  const totalCost = deptTokens.reduce((s, d) => s + parseFloat(d.cost || '0'), 0)

  const tooltipStyle = {
    backgroundColor: theme === 'light' ? '#fff' : '#1a1a2e',
    border: `1px solid ${theme === 'light' ? '#e5e7eb' : '#d4a574'}`,
    color: theme === 'light' ? '#374151' : '#e5e5e5',
    fontSize: 12,
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      {/* 导出 */}
      <div className="flex items-center justify-between">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          🔥 Token 消耗统计
        </h2>
        <button
          onClick={() => {
            const csv = [
              '部门,输入Token,输出Token,总Token,预估成本',
              ...data.botAccounts
                .sort((a, b) => b.totalTokens - a.totalTokens)
                .map(b => {
                  const cost = (b.totalTokens / 1000000 * tokenPrice).toFixed(4)
                  return `"${b.displayName || b.name}",${b.inputTokens},${b.outputTokens},${b.totalTokens},$${cost}`
                })
            ].join('\n')
            const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url; a.download = `token_stats_${new Date().toISOString().split('T')[0]}.csv`; a.click()
            URL.revokeObjectURL(url)
          }}
          className="px-3 py-1.5 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10 rounded cursor-pointer"
        >
          📥 导出CSV
        </button>
      </div>

      {/* 总量卡片 */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label: '总Token', value: fmt(totalTokens || totalApiTokens), icon: '🔥' },
          { label: '输入Token', value: fmt(totalInput), icon: '📥' },
          { label: '输出Token', value: fmt(totalOutput), icon: '📤' },
          { label: '预估成本', value: `$${totalCost.toFixed(3)}`, icon: '💰' },
        ].map(c => (
          <div key={c.label} className={`${bg} rounded-lg p-3 sm:p-4`}>
            <div className={`text-[10px] sm:text-xs uppercase ${sub}`}>{c.icon} {c.label}</div>
            <div className="font-mono text-lg sm:text-2xl text-[#d4a574] mt-1">{c.value}</div>
          </div>
        ))}
      </div>

      {/* 部门Token排行 - 柱状图 */}
      <div className={`${bg} rounded-lg p-3 sm:p-5`}>
        <h3 className={`text-xs sm:text-sm tracking-wider mb-4 uppercase ${sub}`}>各部门Token消耗</h3>
        <div className="h-64 sm:h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={barData} margin={{ top: 5, right: 10, bottom: 60, left: 10 }}>
              <XAxis dataKey="name" tick={{ fill: theme === 'light' ? '#6b7280' : '#a3a3a3', fontSize: 10 }} angle={-45} textAnchor="end" height={80} />
              <YAxis tick={{ fill: theme === 'light' ? '#6b7280' : '#a3a3a3', fontSize: 10 }} tickFormatter={v => fmt(v)} />
              <Tooltip contentStyle={tooltipStyle} formatter={(v: unknown) => [Number(v).toLocaleString(), 'tokens']} />
              <Bar dataKey="input" name="输入" fill="#d4a574" stackId="a" />
              <Bar dataKey="output" name="输出" fill="#c9a96e" stackId="a" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* 部门占比 - 饼图 */}
      <div className={`${bg} rounded-lg p-3 sm:p-5`}>
        <h3 className={`text-xs sm:text-sm tracking-wider mb-4 uppercase ${sub}`}>
          {deptTokens.length > 0 ? '各部门占比' : '输入 vs 输出'}
        </h3>
        <div className="h-56 sm:h-64">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie data={pieData} cx="50%" cy="50%" outerRadius={80} innerRadius={40} dataKey="value"
                label={({ name, percent }) => `${name}: ${((percent ?? 0) * 100).toFixed(1)}%`}
                labelLine={{ stroke: theme === 'light' ? '#9ca3af' : '#a3a3a3' }}>
                {pieData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip contentStyle={tooltipStyle} formatter={(v: unknown) => [fmt(Number(v)), 'tokens']} />
              <Legend wrapperStyle={{ color: theme === 'light' ? '#6b7280' : '#a3a3a3', fontSize: 12 }} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* 按部门明细表格 */}
      {deptTokens.length > 0 && (
        <div className={`${bg} rounded-lg overflow-hidden`}>
          <h3 className={`text-xs sm:text-sm tracking-wider p-3 sm:p-4 uppercase ${sub}`}>📋 部门明细</h3>
          <div className={`grid grid-cols-3 text-xs p-3 border-y ${theme === 'light' ? 'bg-gray-50 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'}`}>
            <div>部门</div><div className="text-right">Token消耗</div><div className="text-right">预估成本</div>
          </div>
          {deptTokens.sort((a, b) => b.tokens - a.tokens).map(d => (
            <div key={d.department} className={`grid grid-cols-3 text-xs sm:text-sm p-3 border-b ${theme === 'light' ? 'border-gray-100' : 'border-[#d4a574]/10'}`}>
              <div className="font-medium">{d.department}</div>
              <div className="text-right font-mono text-[#d4a574]">{fmt(d.tokens)}</div>
              <div className="text-right font-mono text-[#d4a574]">${d.cost}</div>
            </div>
          ))}
        </div>
      )}

      {loading && <div className={`text-center py-4 ${sub} text-sm animate-pulse`}>加载Token数据...</div>}
    </div>
  )
}
