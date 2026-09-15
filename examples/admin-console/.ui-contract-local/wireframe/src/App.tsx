/**
 * 浏览器状态 + 外壳组合 + 降级实算。
 *
 * 区域树见 layout.md §3.1，页型×部件矩阵见 §4.2，降级见 §3.4。
 * 控制面板不属于产品界面，它在视口外（README 里有「控制 → 验什么」的表）。
 * 这个文件不决定任何控件放哪：Panel 只收 Zone，Zone 必须声明区，Choice 自己挑形状。
 * 它也不带任何颜色——页框、视口、面板的颜色全在 inspect.tsx（颜色豁免文件）。
 */
import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { Badge, Btn, GroupLabel, NavRow, Tile, useSkin } from './wire'
import {
  LabelsProvider,
  AnnotatedRegion,
  SkinBanner,
  SkinEditor,
  Browser,
  Viewport,
  Panel,
  Zone,
  Choice,
  Readout,
  Alert,
} from './inspect'
import candidates from '../../tokens.input.json'
import type { PageKind } from './wire'
import { STRUCT, resolveShell } from './structure'
import type { Pref } from './structure'
import { NAV_GROUPS, NAV_SETTINGS, ROWS, STATUS_KIND } from './fixtures'
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
const CLAMPS: readonly number[] = [0, 1440, 1180, 1024, 900, 680]
const DIRECTIONS = ['A', 'B', 'C'] as const
type Direction = (typeof DIRECTIONS)[number]

export default function App() {
  const [labels, setLabels] = useState(true)
  // 换肤预览规则 3：默认关，且**不持久化**——每次重开都是灰的
  const [skin, setSkin] = useState(false)
  const [panelOpen, setPanelOpen] = useState(true)
  // 镜头倍率。它改变的是显示比例，不是实测宽——实测宽从布局读，见下面的 ResizeObserver
  const [zoom, setZoom] = useState(1)
  const sk = useSkin(skin)
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
  //    contentRect 是布局像素，不受镜头影响——**永远不要用 getBoundingClientRect / zoom 反推**
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

  // ── 控制面板：只放作用在原型上的东西；顺序由 Panel 按区排，这里不排 ──
  const panel = (
    <Panel
      open={panelOpen}
      onToggle={() => setPanelOpen(!panelOpen)}
      mode="proto"
      title="控制台"
      readout={
        /* 读数块：降级规则能被对着数字验证，而不是靠感觉 */
        <Readout>
          <span>
            外壳实测 <b>{shellWidth}</b>
          </span>
          <span>
            显示比例 <b>{Math.round(zoom * 100)}%</b>
          </span>
          <span>
            导航 <b>{shell.navWidth}</b> {shell.nav}
          </span>
          <span>
            面板 <b>{shell.inspector}</b>
          </span>
          <span>
            主区 <b>{shell.mainWidth}</b> / 阈值 {STRUCT.mainMinWidth}
          </span>
          <span>
            偏好 <b>{navPref}</b>
          </span>
          {shell.triggered.length ? (
            <Alert>降级：{shell.triggered.join(' · ')}</Alert>
          ) : (
            <span className="col-span-2">降级：未触发</span>
          )}
          {shell.atFloor && <Alert>已触底，表格横向滚动</Alert>}
        </Readout>
      }
    >
      <Zone zone="screen">
        <Choice
          label="页型"
          options={Object.keys(PAGE_LABEL) as PageKind[]}
          value={page}
          onChange={setPage}
          labelOf={(p) => PAGE_LABEL[p]}
        />
        {page === 'wizard' && (
          <Choice
            label="向导步"
            options={[0, 1, 2] as readonly number[]}
            value={wizardStep}
            onChange={setWizardStep}
            labelOf={(n) => `第 ${n + 1} 步`}
          />
        )}
      </Zone>
      <Zone zone="condition">
        <Choice
          label="窗口宽"
          options={CLAMPS}
          value={clamp}
          onChange={setClamp}
          labelOf={(c) => (c === 0 ? '自适应' : String(c))}
        />
        <Choice label="导航偏好" options={['auto', 'open', 'closed'] as const} value={navPref} onChange={setNavPref} />
        <Choice
          label={page === 'list' ? '列表状态' : '页面状态'}
          options={['正常', '空', '筛选后空', '加载', '局部失败', '整区失败'] as const}
          value={dataState}
          onChange={setDataState}
        />
        <Choice
          label="面板状态"
          options={['正常', '加载', '整区失败'] as const}
          value={inspectorState}
          onChange={setInspectorState}
        />
        <Choice label="覆盖层" value={overlay} onChange={setOverlay} />
      </Zone>
      <Zone zone="view">
        <Choice label="区域标注" value={labels} onChange={setLabels} />
        <Choice label="换肤预览" value={skin} onChange={setSkin} />
      </Zone>
      <Zone zone="output">
        {skin && (
          <>
            {/* 方向切换：本项目自己的候选方向（来自 tokens.input.json），不是插件自带的主题 */}
            <Choice
              label="方向"
              options={DIRECTIONS}
              value={sk.theme as Direction}
              onChange={sk.setTheme}
              labelOf={(id) => candidates._candidates[id].label}
            />
            <SkinEditor
              base={sk.base}
              draft={sk.draft}
              onChange={sk.set}
              onReset={sk.reset}
              tokenFile="src/tokens.css"
              theme={sk.theme}
              chosen="A"
              themeLabel={(id) => candidates._candidates[id as Direction]?.label ?? id}
            />
          </>
        )}
      </Zone>
    </Panel>
  )

  return (
    <LabelsProvider value={labels}>
      <Browser panel={panel}>
        {/* 横幅在面板之外、视口之上，**不随面板收起而消失**：这个警告不许被折叠掉 */}
        {skin && <SkinBanner tokenFile="src/tokens.css" />}

        {/* 样张墙未接入：外壳还内联在这里带着 hooks，铺不成样张。见 examples/README.md 的落后表 */}
        <Viewport mode="proto" onMode={() => undefined} zoom={zoom} onZoom={setZoom} clamp={clamp}>
          {/* ── 产品界面 ─────────────────────────────────────────── */}
          <div style={sk.vars} className="flex h-[calc(100vh-7rem)] min-h-[480px] font-sans text-[var(--wire-fg-strong)]">
            <AnnotatedRegion
              id="app-shell"
              elRef={shellRef}
              className="flex min-h-0 w-full overflow-hidden rounded border border-[var(--wire-line-contrast)] bg-[var(--wire-canvas)]"
            >
              {/* ── nav ───────────────────────────────────────── */}
              <AnnotatedRegion
                id="nav"
                className="flex shrink-0 flex-col border-r border-[var(--wire-line-strong)] bg-[var(--wire-muted)]"
                label={shell.nav === 'rail' ? '全局导航（图标条）' : undefined}
                style={{ width: shell.navWidth }}
              >
                <AnnotatedRegion
                  id="nav.brand"
                  className="flex items-center gap-2 border-b border-[var(--wire-line)] px-2.5 py-2.5"
                >
                  <Tile size={22} />
                  {shell.nav === 'full' && (
                    <span className="flex-1 truncate text-xs font-semibold text-[var(--wire-fg-2)]">
                      内容管理后台
                    </span>
                  )}
                  <button
                    title="收起 / 展开（手动优先，双向生效）"
                    onClick={() => setNavPref(shell.nav === 'full' ? 'closed' : 'open')}
                    className="shrink-0 rounded border border-[var(--wire-line-strong)] px-1 text-[10px] text-[var(--wire-muted-fg)]"
                  >
                    {shell.nav === 'full' ? '«' : '»'}
                  </button>
                </AnnotatedRegion>

                <AnnotatedRegion id="nav.groups" className="min-h-0 flex-1 overflow-y-auto px-1.5 pb-2">
                  {NAV_GROUPS.map((g) => (
                    <div key={g.group}>
                      {shell.nav === 'full' ? (
                        <GroupLabel>{g.group}</GroupLabel>
                      ) : (
                        <div className="mx-2 mt-3 mb-1 border-t border-[var(--wire-line-strong)]" />
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
                              <span className="shrink-0 rounded-full border border-[var(--wire-line-contrast)] px-1.5 text-[10px] leading-[15px] text-[var(--wire-body-fg)]">
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
                </AnnotatedRegion>

                {/* 配置类去处贴底独立成段：导航变长也不会被滚走，且禁止带角标 */}
                <AnnotatedRegion id="nav.settings" className="border-t border-[var(--wire-line)] px-1.5 pt-1 pb-2">
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
                </AnnotatedRegion>
              </AnnotatedRegion>

              {/* ── work ──────────────────────────────────────── */}
              <AnnotatedRegion id="work" className="flex min-w-0 flex-1 flex-col">
                <AnnotatedRegion id="stage" className="relative flex min-h-0 min-w-0 flex-1">
                  {/* main：最小可用宽 640，触底后横向滚动 */}
                  <AnnotatedRegion
                    id="main"
                    className="flex min-w-0 flex-1 flex-col overflow-hidden bg-[var(--wire-canvas)]"
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
                  </AnnotatedRegion>

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
                    <AnnotatedRegion
                      id="overlay"
                      className="absolute inset-0 z-30 flex flex-col bg-[var(--wire-overlay)] backdrop-blur-[1px]"
                    >
                      <div className="flex items-center justify-between border-b border-[var(--wire-line-strong)] px-5 py-3">
                        <div className="min-w-0">
                          <p className="truncate text-sm font-semibold text-[var(--wire-fg)]">
                            正文全文预览 · {row.id}
                          </p>
                          <p className="mt-0.5 truncate text-[11px] text-[var(--wire-muted-fg)]">
                            覆盖层自带头部：它盖住了页头，不自带头部用户就不知道自己在哪
                          </p>
                        </div>
                        <Btn weight="ghost" onClick={() => setOverlay(false)}>
                          关闭（Esc）
                        </Btn>
                      </div>
                      <div className="min-h-0 flex-1 space-y-3 overflow-y-auto px-8 py-5">
                        <h2 className="text-base font-semibold text-[var(--wire-fg)]">{row.title}</h2>
                        <div className="flex gap-2">
                          <Badge kind={STATUS_KIND[row.status]}>{row.status}</Badge>
                          <span className="text-[11px] text-[var(--wire-faint-fg)]">
                            {row.author} · {row.updated}
                          </span>
                        </div>
                        {[
                          '一、总体情况。7 月纳入统计的 12 座城市轨道交通累计客运量 41.7 亿人次，环比增长 3.2%，同比增长 8.6%。其中 5 座城市创下开通以来单月新高。',
                          '二、口径说明。本期起，市域快轨客运量计入总量，与 2025 年同期数据不可直接比较；同比数据已按新口径回溯调整，回溯范围见附件二。',
                          '三、数据缺口。B 市 7 月 18—20 日自动售票系统升级，期间数据由人工闸机计数补录；C 市未提供分线路数据，本期以全网合计呈现。',
                          '四、准点率与投诉。全网平均准点率 99.2%，较上月下降 0.1 个百分点；每百万人次投诉量 2.4 件，主要集中在早高峰限流与空调温度两类。',
                        ].map((p, i) => (
                          <p key={i} className="max-w-[70ch] text-xs leading-relaxed text-[var(--wire-fg-2)]">
                            {p}
                          </p>
                        ))}
                        <p className="text-[11px] text-[var(--wire-faint-fg)]">
                          这类内容需要宽度，所以它在覆盖层而不是 360 的面板里（§1.1 短路「需要宽度」）。
                          禁止在这上面再叠第二层覆盖层。
                        </p>
                      </div>
                    </AnnotatedRegion>
                  )}
                </AnnotatedRegion>
              </AnnotatedRegion>
            </AnnotatedRegion>
          </div>
        </Viewport>
      </Browser>
    </LabelsProvider>
  )
}
