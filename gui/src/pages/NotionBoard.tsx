import { useState, useEffect } from "react"
import { useTheme } from "../theme"
import {
import { getAuthToken } from '../auth'
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
} from "recharts"

type NotionTab = 'daily' | 'finance' | 'personnel'

interface DailyEntry {
  id: string
  title: string
  date: string
  summary: string
  author: string
  status: string
}

interface FinanceEntry {
  id: string
  category: string
  income: number
  expense: number
  period: string
  balance: number
}

interface PersonnelEntry {
  id: string
  name: string
  title: string
  department: string
  status: string
  tenure: string
}

const CHART_COLORS = ['#d4a574', '#22c55e', '#ef4444', '#3b82f6', '#f59e0b', '#8b5cf6', '#ec4899', '#14b8a6']

function formatNumber(n: number): string {
  return n.toLocaleString()
}

export default function NotionBoard() {
  const [activeTab, setActiveTab] = useState<NotionTab>('daily')
  const [dailyData, setDailyData] = useState<DailyEntry[]>([])
  const [financeData, setFinanceData] = useState<FinanceEntry[]>([])
  const [personnelData, setPersonnelData] = useState<PersonnelEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [filterDept, setFilterDept] = useState('all')
  const { theme } = useTheme()

  const fetchData = async () => {
    setLoading(true)
    try {
      const [dailyRes, financeRes, personnelRes] = await Promise.all([
        fetch('/api/notion/data?type=daily', { headers: { 'Authorization': `Bearer ${getAuthToken()}` } }),
        fetch('/api/notion/data?type=finance', { headers: { 'Authorization': `Bearer ${getAuthToken()}` } }),
        fetch('/api/notion/data?type=personnel', { headers: { 'Authorization': `Bearer ${getAuthToken()}` } })
      ])
      
      const [daily, finance, personnel] = await Promise.all([
        dailyRes.json(),
        financeRes.json(),
        personnelRes.json()
      ])
      
      setDailyData(daily.data || [])
      setFinanceData(finance.data || [])
      setPersonnelData(personnel.data || [])
    } catch (e) {
      console.error('Failed to fetch Notion data:', e)
    }
    setLoading(false)
  }

  useEffect(() => {
    fetchData()
  }, [])

  // 过滤数据
  const filteredDaily = filterDept === 'all' 
    ? dailyData 
    : dailyData.filter(d => d.author === filterDept)
  
  const filteredFinance = filterDept === 'all'
    ? financeData
    : financeData.filter(f => f.category === filterDept)

  // 图表数据
  const expenseChartData = financeData.map(f => ({
    name: f.category,
    支出: f.expense,
    收入: f.income
  }))

  const pieData = financeData.map(f => ({
    name: f.category,
    value: f.expense || 1
  }))

  const tabs = [
    { key: 'daily', label: '起居注', icon: '📜' },
    { key: 'finance', label: '食货表', icon: '💰' },
    { key: 'personnel', label: '臣工表', icon: '👥' }
  ]

  // 获取部门列表用于筛选
  const depts = [...new Set(dailyData.map(d => d.author).filter(Boolean))]

  if (loading) {
    return <div className="text-[#a3a3a3]">加载中...</div>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <h2 className={`text-lg font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
          奏章板
        </h2>
        <div className="flex items-center gap-2">
          {/* 筛选器 */}
          {activeTab !== 'personnel' && depts.length > 1 && (
            <select
              value={filterDept}
              onChange={(e) => setFilterDept(e.target.value)}
              className={`px-2 py-1 text-xs border rounded ${
                theme === 'light' 
                  ? 'bg-white border-gray-300' 
                  : 'bg-[#16213e] border-[#d4a574]/30'
              }`}
            >
              <option value="all">全部部门</option>
              {depts.map(d => (
                <option key={d} value={d}>{d}</option>
              ))}
            </select>
          )}
          <button
            onClick={fetchData}
            className="px-3 py-1 text-xs border border-[#d4a574] text-[#d4a574] hover:bg-[#d4a574]/10"
          >
            刷新
          </button>
        </div>
      </div>

      {/* Tab 切换 */}
      <div className="flex gap-2 border-b border-[#d4a574]/30 pb-2">
        {tabs.map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key as NotionTab)}
            className={`px-4 py-2 text-sm rounded-t transition-all ${
              activeTab === tab.key
                ? 'bg-[#d4a574]/20 text-[#d4a574] border-b-2 border-[#d4a574]'
                : 'text-[#a3a3a3] hover:text-[#e5e5e5]'
            }`}
          >
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      {/* 起居注 - 日报 */}
      {activeTab === 'daily' && (
        <div className="space-y-4">
          {filteredDaily.map(entry => (
            <div
              key={entry.id}
              className={`p-4 rounded-lg border ${
                theme === 'light' 
                  ? 'bg-white border-gray-200 hover:shadow-md' 
                  : 'bg-[#1a1a2e] border-[#d4a574]/20 hover:border-[#d4a574]/40'
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className={`font-medium ${theme === 'light' ? 'text-gray-800' : 'text-[#d4a574]'}`}>
                  {entry.title}
                </h3>
                <span className={`px-2 py-0.5 text-xs rounded ${
                  entry.status === 'published' 
                    ? 'bg-green-500/20 text-green-500' 
                    : 'bg-yellow-500/20 text-yellow-500'
                }`}>
                  {entry.status === 'published' ? '已发布' : '草稿'}
                </span>
              </div>
              <p className={`text-sm ${theme === 'light' ? 'text-gray-600' : 'text-[#a3a3a3]'}`}>
                {entry.summary}
              </p>
              <div className={`text-xs mt-2 ${theme === 'light' ? 'text-gray-400' : 'text-[#a3a3a3]/60'}`}>
                {entry.date} · {entry.author}
              </div>
            </div>
          ))}
          {filteredDaily.length === 0 && (
            <div className="text-center text-[#a3a3a3] py-8">暂无数据</div>
          )}
        </div>
      )}

      {/* 食货表 - 财务 + 图表 */}
      {activeTab === 'finance' && (
        <div className="space-y-6">
          {/* 图表区域 */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* 支出饼图 */}
            <div className={`p-4 rounded-lg border ${theme === 'light' ? 'bg-white border-gray-200' : 'bg-[#1a1a2e] border-[#d4a574]/20'}`}>
              <h3 className={`text-sm font-medium mb-4 ${theme === 'light' ? 'text-gray-700' : 'text-[#d4a574]'}`}>
                支出分布
              </h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={pieData}
                      cx="50%"
                      cy="50%"
                      innerRadius={40}
                      outerRadius={70}
                      paddingAngle={2}
                      dataKey="value"
                    >
                      {pieData.map((_entry, index) => (
                        <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#1a1a2e', border: '1px solid #d4a574/30' }}
                    />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* 收支柱状图 */}
            <div className={`p-4 rounded-lg border ${theme === 'light' ? 'bg-white border-gray-200' : 'bg-[#1a1a2e] border-[#d4a574]/20'}`}>
              <h3 className={`text-sm font-medium mb-4 ${theme === 'light' ? 'text-gray-700' : 'text-[#d4a574]'}`}>
                收支对比
              </h3>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={expenseChartData}>
                    <XAxis 
                      dataKey="name" 
                      tick={{ fontSize: 10, fill: theme === 'light' ? '#666' : '#a3a3a3' }}
                    />
                    <YAxis tick={{ fontSize: 10, fill: theme === 'light' ? '#666' : '#a3a3a3' }} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: '#1a1a2e', border: '1px solid #d4a574/30' }}
                    />
                    <Legend />
                    <Bar dataKey="收入" fill="#22c55e" />
                    <Bar dataKey="支出" fill="#ef4444" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          {/* 数据表格 */}
          <div className={`rounded-lg overflow-hidden ${theme === 'light' ? 'bg-white' : 'bg-[#1a1a2e]'}`}>
            <div className={`grid grid-cols-5 text-xs p-3 border-b ${
              theme === 'light' ? 'bg-gray-100 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'
            }`}>
              <div>类别</div>
              <div>收入</div>
              <div>支出</div>
              <div>结余</div>
              <div>期间</div>
            </div>
            {filteredFinance.map(entry => (
              <div 
                key={entry.id}
                className={`grid grid-cols-5 text-sm p-3 border-b ${
                  theme === 'light' ? 'border-gray-100' : 'border-[#d4a574]/10'
                }`}
              >
                <div className="font-medium">{entry.category}</div>
                <div className="font-mono text-green-500">+{formatNumber(entry.income)}</div>
                <div className="font-mono text-red-500">-{formatNumber(entry.expense)}</div>
                <div className="font-mono text-[#d4a574]">{formatNumber(entry.balance)}</div>
                <div className="text-[#a3a3a3]">{entry.period}</div>
              </div>
            ))}
            {/* 汇总行 */}
            <div className={`grid grid-cols-5 text-sm p-3 font-medium ${
              theme === 'light' ? 'bg-gray-50' : 'bg-[#16213e]'
            }`}>
              <div>合计</div>
              <div className="font-mono text-green-500">
                +{formatNumber(filteredFinance.reduce((s, d) => s + d.income, 0))}
              </div>
              <div className="font-mono text-red-500">
                -{formatNumber(filteredFinance.reduce((s, d) => s + d.expense, 0))}
              </div>
              <div className="font-mono text-[#d4a574]">
                {formatNumber(filteredFinance.reduce((s, d) => s + d.balance, 0))}
              </div>
              <div>-</div>
            </div>
          </div>
        </div>
      )}

      {/* 臣工表 - 人脉 */}
      {activeTab === 'personnel' && (
        <div className={`rounded-lg overflow-hidden ${theme === 'light' ? 'bg-white' : 'bg-[#1a1a2e]'}`}>
          <div className={`grid grid-cols-5 text-xs p-3 border-b ${
            theme === 'light' ? 'bg-gray-100 border-gray-200' : 'bg-[#16213e] border-[#d4a574]/20'
          }`}>
            <div>姓名</div>
            <div>官职</div>
            <div>部门</div>
            <div>状态</div>
            <div>任期</div>
          </div>
          {personnelData.map(person => (
            <div 
              key={person.id}
              className={`grid grid-cols-5 text-sm p-3 border-b items-center ${
                theme === 'light' ? 'border-gray-100' : 'border-[#d4a574]/10'
              }`}
            >
              <div className="font-medium">{person.name}</div>
              <div>{person.title}</div>
              <div className="text-[#d4a574]">{person.department}</div>
              <div>
                <span className="px-2 py-0.5 text-xs rounded bg-green-500/20 text-green-500">
                  {person.status === 'active' ? '在任' : '离任'}
                </span>
              </div>
              <div className="text-[#a3a3a3]">{person.tenure}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
