/**
 * 外壳 + 页型路由 + 降级实算 + 演示开关条。
 *
 * 区域树见 layout.md §3.1，页型×部件矩阵见 §4.2，降级见 §3.4。
 * 演示开关条不属于产品界面，它在窗口外（README 里有「开关 → 验什么」的表）。
 */
import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import { Badge, Btn, GroupLabel, LabelsProvider, NavRow, Region, Tile } from './wire'
import type { PageKind } from './wire'
import { STRUCT, resolveShell } from './structure'
import type { Pref } from './structure'
import { NAV_GROUPS, NAV_SETTINGS, ROWS } from './fixtures'
import { InspectorSlot } from './Inspector'
import type { InspectorState } from './Inspector'
import { ListPage } from './pages/ListPage'
import type { DataState } from './pages/ListPage'
import { WizardPage } from './pages/WizardPage'
import { FormPage } from './pages/FormPage'
import { OverviewPage } from './pages/OverviewPage'

const PAGE_LABEL: Record<PageKind, string> = {
  list: 'P1 列表页',
  wizard: 'P2 向导页',
  form: 'P3 设置表单页',
  overview: 'P4 概览页',
}

/**
 * 演示用的几档窗口宽度，用来验降级链。每一档对应 resolveShell 的一个结果：
 *  1440 不降级 / 1180 触发级1 / 1024 触发级1+级2 / 900 同上 / 680 触底（级3）
 */
const CLAMPS = [0, 1440, 1180, 1024, 900, 680] as const

export default function App() {
  const [labels, setLabels] = useState(true)
  const [page, setPage] = useState<PageKind>('list')
  const [navPref, setNavPref] = useState<Pref>('auto')
  const [clamp, setClamp] = useState<number>(0)
  const [dataState, setDataState] = useState<DataState>('正常')
  const [inspectorState, setInspectorState] = useState<InspectorState>('正常')
  const [overlay, setOverlay] = useState(false)
  const [selected, setSelected] = useState<string[]>([])
  // §5.5：P1 的初始状态是面板**关闭**（没有选中行，主区全宽）。
  // 不常驻一个空面板——那会白占 360 宽只为放一句话（附录 B-5）
  const [activeId, setActiveId] = useState<string | null>(null)
  const [wizardStep, setWizardStep] = useState(0)

  // ── 降级实算：ResizeObserver 实测 app-shell 宽度，不用视口断点（§3.4 / §10-8）
  const shellRef = useRef<HTMLDivElement>(null)
  const [shellWidth, setShellWidth] = useState(0)
  useLayoutEffect(() => {
    const el = shellRef.current
    if (!el) return
    const ro = new ResizeObserver(([e]) => setShellWidth(Math.round(e.contentRect.width)))
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  const inspectorRequested = page === 'list' && activeId !== null
  const shell = resolveShell({ shellWidth, navPref, inspectorRequested })

  // §5.5 切换规则：切换导航去处（这里等价于换页型）时，面板重置为关闭
  useEffect(() => {
    setActiveId(null)
    setSelected([])
  }, [page])

  // §5.6 键盘：Esc 一次只关一层 —— overlay → 面板 → 清空选中
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return
      if (overlay) setOverlay(false)
      else if (activeId) setActiveId(null)
      else setSelected([])
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [overlay, activeId])

  const row = ROWS.find((r) => r.id === activeId) ?? ROWS[0]

  return (
    <LabelsProvider value={labels}>
      <div className="flex h-screen flex-col bg-neutral-200 font-sans text-neutral-900">
        {/* ── 演示开关条（不属于产品界面）──────────────────────────── */}
        <div className="shrink-0 space-y-1.5 border-b border-neutral-400 bg-neutral-800 px-3 py-2 text-white">
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-[11px]">
            <Group name="页型">
              {(Object.keys(PAGE_LABEL) as PageKind[]).map((p) => (
                <Sw key={p} on={page === p} onClick={() => setPage(p)}>
                  {PAGE_LABEL[p]}
                </Sw>
              ))}
            </Group>
            <Group name="窗口宽">
              {CLAMPS.map((c) => (
                <Sw key={c} on={clamp === c} onClick={() => setClamp(c)}>
                  {c === 0 ? '自适应' : c}
                </Sw>
              ))}
            </Group>
            <Group name="导航偏好">
              {(['auto', 'open', 'closed'] as Pref[]).map((p) => (
                <Sw key={p} on={navPref === p} onClick={() => setNavPref(p)}>
                  {p}
                </Sw>
              ))}
            </Group>
            <Group name="标注">
              <Sw on={labels} onClick={() => setLabels(!labels)}>
                区域标注
              </Sw>
              <Sw on={overlay} onClick={() => setOverlay(!overlay)}>
                覆盖层
              </Sw>
            </Group>
          </div>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-[11px]">
            <Group name={page === 'list' ? '列表状态' : '页面状态'}>
              {(['正常', '空', '筛选后空', '加载', '局部失败', '整区失败'] as DataState[]).map((s) => (
                <Sw key={s} on={dataState === s} onClick={() => setDataState(s)}>
                  {s}
                </Sw>
              ))}
            </Group>
            <Group name="面板状态">
              {(['正常', '加载', '整区失败'] as InspectorState[]).map((s) => (
                <Sw key={s} on={inspectorState === s} onClick={() => setInspectorState(s)}>
                  {s}
                </Sw>
              ))}
            </Group>
            {page === 'wizard' && (
              <Group name="向导步">
                {[0, 1, 2].map((n) => (
                  <Sw key={n} on={wizardStep === n} onClick={() => setWizardStep(n)}>
                    第 {n + 1} 步
                  </Sw>
                ))}
              </Group>
            )}
          </div>
          {/* 实时数据行：降级规则能被对着数字验证，而不是靠感觉 */}
          <div className="flex flex-wrap gap-x-4 gap-y-1 border-t border-neutral-700 pt-1.5 font-mono text-[10px] text-neutral-300">
            <span>外壳实测 {shellWidth}</span>
            <span>导航 {shell.navWidth}（{shell.nav}）</span>
            <span>面板 {shell.inspector}</span>
            <span>
              主区 {shell.mainWidth} / 阈值 {STRUCT.mainMinWidth}
            </span>
            <span>偏好 nav={navPref}</span>
            <span className={shell.triggered.length ? 'text-amber-300' : ''}>
              降级：{shell.triggered.length ? shell.triggered.join(' · ') : '未触发'}
            </span>
            {shell.atFloor && <span className="text-amber-300">已触底，表格横向滚动</span>}
          </div>
        </div>

        {/* ── 产品界面 ─────────────────────────────────────────── */}
        <div className="flex min-h-0 flex-1 justify-center overflow-hidden p-3">
          <Region
            id="app-shell"
            elRef={shellRef}
            className="flex min-h-0 w-full overflow-hidden rounded border border-neutral-400 bg-neutral-50"
            style={clamp ? { maxWidth: clamp } : undefined}
          >
            {/* ── nav ───────────────────────────────────────── */}
            <Region
              id="nav"
              className="flex shrink-0 flex-col border-r border-neutral-300 bg-neutral-100"
              label={shell.nav === 'rail' ? '全局导航（图标条）' : undefined}
              style={{ width: shell.navWidth }}
            >
              <Region
                id="nav.brand"
                className="flex items-center gap-2 border-b border-neutral-200 px-2.5 py-2.5"
              >
                <Tile size={22} />
                {shell.nav === 'full' && (
                  <span className="flex-1 truncate text-xs font-semibold text-neutral-700">
                    内容管理后台
                  </span>
                )}
                <button
                  title="收起 / 展开（手动优先，双向生效）"
                  onClick={() => setNavPref(shell.nav === 'full' ? 'closed' : 'open')}
                  className="shrink-0 rounded border border-neutral-300 px-1 text-[10px] text-neutral-500"
                >
                  {shell.nav === 'full' ? '«' : '»'}
                </button>
              </Region>

              <Region id="nav.groups" className="min-h-0 flex-1 overflow-y-auto px-1.5 pb-2">
                {NAV_GROUPS.map((g) => (
                  <div key={g.group}>
                    {shell.nav === 'full' ? (
                      <GroupLabel>{g.group}</GroupLabel>
                    ) : (
                      <div className="mx-2 mt-3 mb-1 border-t border-neutral-300" />
                    )}
                    {g.items.map((it) => (
                      <NavRow
                        key={it.label}
                        on={
                          (page === 'list' && it.label === '全部内容') ||
                          (page === 'wizard' && it.label === '批量导入') ||
                          (page === 'overview' && it.label === '概览')
                        }
                        right={
                          /* 队列型才带角标；库型禁止带（§7.1）。收起后角标必须保留（§3.4 级1） */
                          it.count ? (
                            <span className="shrink-0 rounded-full border border-neutral-400 px-1.5 text-[10px] leading-[15px] text-neutral-600">
                              {it.count}
                            </span>
                          ) : undefined
                        }
                        onClick={() => {
                          if (it.label === '批量导入') setPage('wizard')
                          else if (it.label === '概览') setPage('overview')
                          else setPage('list')
                        }}
                      >
                        {shell.nav === 'full' ? it.label : <Tile size={18} />}
                      </NavRow>
                    ))}
                  </div>
                ))}
              </Region>

              {/* 配置类去处贴底独立成段：导航变长也不会被滚走，且禁止带角标 */}
              <Region id="nav.settings" className="border-t border-neutral-200 px-1.5 pt-1 pb-2">
                {NAV_SETTINGS.map((g) => (
                  <div key={g.group}>
                    {shell.nav === 'full' ? (
                      <GroupLabel>{g.group}</GroupLabel>
                    ) : (
                      <div className="mx-2 mt-1 mb-1" />
                    )}
                    {g.items.map((it) => (
                      <NavRow
                        key={it.label}
                        on={page === 'form' && it.label === '站点参数'}
                        onClick={() => setPage('form')}
                      >
                        {shell.nav === 'full' ? it.label : <Tile size={18} />}
                      </NavRow>
                    ))}
                  </div>
                ))}
              </Region>
            </Region>

            {/* ── work ──────────────────────────────────────── */}
            <Region id="work" className="flex min-w-0 flex-1 flex-col">
              <Region id="stage" className="relative flex min-h-0 min-w-0 flex-1">
                {/* main：最小可用宽 640，触底后横向滚动 */}
                <Region
                  id="main"
                  className="flex min-w-0 flex-1 flex-col overflow-hidden bg-neutral-50"
                  style={{ minWidth: STRUCT.mainMinWidth }}
                >
                  {page === 'list' && (
                    <ListPage
                      state={dataState}
                      selected={selected}
                      activeId={activeId}
                      onToggle={(id) =>
                        setSelected((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]))
                      }
                      onOpenRow={setActiveId}
                      onClearSelection={() => setSelected([])}
                    />
                  )}
                  {page === 'wizard' && (
                    <WizardPage
                      step={wizardStep}
                      setStep={setWizardStep}
                      failed={dataState === '整区失败'}
                    />
                  )}
                  {page === 'form' && <FormPage failed={dataState === '整区失败'} />}
                  {page === 'overview' && (
                    <OverviewPage failed={dataState === '局部失败' || dataState === '整区失败'} />
                  )}
                </Region>

                {/*
                  面板只在 P1 出现。这里的 page="list" 是字面量：
                  换成 'wizard' 会因为 PageWithInspector 类型报错（layout.md §4.3）。
                */}
                {page === 'list' && shell.inspector !== 'closed' && (
                  <InspectorSlot
                    page="list"
                    kind="content-item"
                    row={row}
                    mode={shell.inspector}
                    state={inspectorState}
                    onClose={() => setActiveId(null)}
                  />
                )}

                {/* 覆盖层：盖住 stage 全部（含面板），不盖 nav；必须自带头部 */}
                {overlay && (
                  <Region
                    id="overlay"
                    className="absolute inset-0 z-30 flex flex-col bg-white/98 backdrop-blur-[1px]"
                  >
                    <div className="flex items-center justify-between border-b border-neutral-300 px-5 py-3">
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-neutral-800">
                          正文全文预览 · {row.id}
                        </p>
                        <p className="mt-0.5 truncate text-[11px] text-neutral-500">
                          覆盖层自带头部：它盖住了页头，不自带头部用户就不知道自己在哪
                        </p>
                      </div>
                      <Btn weight="ghost" onClick={() => setOverlay(false)}>
                        关闭（Esc）
                      </Btn>
                    </div>
                    <div className="min-h-0 flex-1 space-y-3 overflow-y-auto px-8 py-5">
                      <h2 className="text-base font-semibold text-neutral-800">{row.title}</h2>
                      <div className="flex gap-2">
                        <Badge>{row.status}</Badge>
                        <span className="text-[11px] text-neutral-400">
                          {row.author} · {row.updated}
                        </span>
                      </div>
                      {[
                        '一、总体情况。7 月纳入统计的 12 座城市轨道交通累计客运量 41.7 亿人次，环比增长 3.2%，同比增长 8.6%。其中 5 座城市创下开通以来单月新高。',
                        '二、口径说明。本期起，市域快轨客运量计入总量，与 2025 年同期数据不可直接比较；同比数据已按新口径回溯调整，回溯范围见附件二。',
                        '三、数据缺口。B 市 7 月 18—20 日自动售票系统升级，期间数据由人工闸机计数补录；C 市未提供分线路数据，本期以全网合计呈现。',
                        '四、准点率与投诉。全网平均准点率 99.2%，较上月下降 0.1 个百分点；每百万人次投诉量 2.4 件，主要集中在早高峰限流与空调温度两类。',
                      ].map((p, i) => (
                        <p key={i} className="max-w-[70ch] text-xs leading-relaxed text-neutral-700">
                          {p}
                        </p>
                      ))}
                      <p className="text-[11px] text-neutral-400">
                        这类内容需要宽度，所以它在覆盖层而不是 360 的面板里（§1.1 短路 3）。
                        禁止在这上面再叠第二层覆盖层。
                      </p>
                    </div>
                  </Region>
                )}
              </Region>
            </Region>
          </Region>
        </div>
      </div>
    </LabelsProvider>
  )
}

function Group({ name, children }: { name: string; children: ReactNode }) {
  return (
    <div className="flex items-center gap-1.5">
      <span className="text-neutral-400">{name}</span>
      <div className="flex flex-wrap gap-1">{children}</div>
    </div>
  )
}

function Sw({
  on,
  onClick,
  children,
}: {
  on: boolean
  onClick: () => void
  children: ReactNode
}) {
  return (
    <button
      onClick={onClick}
      className={`rounded border px-1.5 py-0.5 ${
        on ? 'border-white bg-white text-neutral-900' : 'border-neutral-600 text-neutral-300'
      }`}
    >
      {children}
    </button>
  )
}
