/**
 * 线框零件 + 区域白名单。
 *
 * `RegionId` 就是 layout.md §2 白名单的代码形态：
 * 想写一个不在表里的 data-region，TypeScript 会直接报错。
 * 新增区域的顺序：改 layout.md §2 → 改 RegionId 与 REGION_META → 写代码。顺序不能反。
 *
 * 视觉刻意保持中性：品牌视觉归 design.md，骨架里没有品牌视觉可抄，
 * 就不会在 design.md 改动后变成过期的第二权威源。
 */
import { createContext, useContext, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import type { CSSProperties, ReactNode, RefObject } from 'react'

// ── 区域白名单（= layout.md §2）────────────────────────────────
// 命名法：小写、连字符、点号分层（父.子），最多两层。
export type RegionId =
  // 外壳
  | 'app-shell'
  | 'nav'
  | 'nav.brand'
  | 'nav.groups'
  | 'nav.settings'
  | 'work'
  | 'stage'
  | 'overlay'
  // 主区
  | 'main'
  | 'main.pagehead'
  | 'main.filters'
  | 'main.bulkbar'
  | 'main.table'
  | 'main.pager'
  | 'main.steps'
  | 'main.step-body'
  | 'main.step-foot'
  | 'main.form'
  | 'main.grid'
  // 属性面板（聚焦槽）
  | 'inspector'
  | 'inspector.head'
  | 'inspector.tabs'
  | 'inspector.body'
  | 'inspector.foot'

// ── 区域元信息 ────────────────────────────────────────────────
/**
 * 人读名给人看，代码名给 Agent 用，desc 写清「**该放什么 / 不该放什么**」，
 * 不是「这是什么」——那个看界面就知道。
 * 说明写错比代码写错更危险，因为下一个 Agent 会照着它扩展。
 */
export const REGION_META: Record<RegionId, { cn: string; desc: string }> = {
  'app-shell': {
    cn: '应用外壳',
    desc: '只把导航与工作区并排。禁止直接承载任何内容或浮动元素。',
  },
  nav: {
    cn: '全局导航',
    desc: '只放三个子区（标识 / 工作流分组 / 系统段）。禁止放当前页面的内容、筛选条件、以及任何与「当前看的对象」有关的东西。固定 220，收起态 56（禁止收成 0）。',
  },
  'nav.brand': {
    cn: '产品标识',
    desc: '产品名 + 导航收起开关。禁止放用户头像、全局搜索、通知铃铛——这三个目前都没有落位，要放先走 layout.md §9。',
  },
  'nav.groups': {
    cn: '工作流去处',
    desc: '分组的导航项 + 队列型的数量角标。禁止放配置类去处（去 nav.settings）、禁止放动作型项（点了「发生一件事」的东西要去 main.pagehead）。库型项禁止带角标。',
  },
  'nav.settings': {
    cn: '系统段（贴底）',
    desc: '只放配置类去处。禁止带数量角标——配置不是队列，角标会被误读成待办。贴底以免导航变长后被滚走。',
  },
  work: {
    cn: '工作区',
    desc: '只放 stage。**禁止新增跨栏的标题栏/工具条**——跨栏栏是拓展规则的黑洞，所有「不知道放哪」的东西都会堆进去。页标题在 main.pagehead。',
  },
  stage: {
    cn: '舞台',
    desc: '只放 main / inspector / overlay 三者。禁止直接承载内容。',
  },
  overlay: {
    cn: '覆盖层',
    desc: '需要宽度的临时查看、需要打断的确认。必须自带标题与关闭入口（它盖住了 main.pagehead）。禁止叠第二层，禁止放常驻功能，禁止系统自动弹出，不盖 nav。',
  },
  main: {
    cn: '主区',
    desc: '当前页型的主体，子区按页型取用（见 layout.md §4.2 矩阵）。最小可用宽 640，低于则触发降级。',
  },
  'main.pagehead': {
    cn: '页头',
    desc: '页标题 + 该页唯一的页级主操作（新建、批量导入这类）。禁止放筛选控件（去 main.filters）、禁止放针对某一行的操作（去 inspector.foot）、禁止堆统计数字（去 P4 概览页）。',
  },
  'main.filters': {
    cn: '筛选条',
    desc: '**只放缩小结果范围的控件**。禁止放导出/新建/批量删除等不改变结果集范围的动作，禁止放结果数量之外的统计指标。属于 main，不跨到面板上方——所以「筛选范围 = 看到的表格」是结构保证的。',
  },
  'main.bulkbar': {
    cn: '批量操作条',
    desc: '已选条数 + 批量操作 + 取消选择。禁止放单行操作与筛选控件。**没有选中行时本区不渲染**（不是隐藏）。',
  },
  'main.table': {
    cn: '表格',
    desc: '列型只有 select / id / text / badge / meta 五种。**禁止操作按钮列与「更多」菜单列**——单行操作只在 inspector.foot（TableColumnKind 里没有 actions 是刻意的）。禁止行内展开编辑表单、禁止行内图表。',
  },
  'main.pager': {
    cn: '分页条',
    desc: '页码 + 总数 + 每页条数。禁止放批量操作、筛选、导出。用分页不用无限滚动：后台要能说「第 3 页第 5 行」。',
  },
  'main.steps': {
    cn: '步骤条',
    desc: '步骤名 + 当前步 + 已完成标记。禁止做成可跳到任意未完成步的导航（进度指示器不是导航），禁止放表单字段。',
  },
  'main.step-body': {
    cn: '当前步内容',
    desc: '当前一步需要的输入 / 上传 / 预检结果 / 结果汇总。一次只渲染一步，禁止渲染其它步的内容，禁止放推进按钮（去 main.step-foot）。',
  },
  'main.step-foot': {
    cn: '流程推进',
    desc: '上一步 / 下一步 / 完成 / 取消。禁止放与推进无关的业务操作。',
  },
  'main.form': {
    cn: '配置表单',
    desc: '分组字段 + 字段说明 + 保存/重置。禁止放表格与列表，禁止放与本组配置无关的其它模块入口。P3 没有空态：配置项固定，空了说明出错。',
  },
  'main.grid': {
    cn: '概览网格',
    desc: '12 列网格，卡片只能占 3/4/6/12 格。禁止放完整表格（只放短列表卡 + 「查看全部」链接），**禁止放筛选条**——需要筛选说明用户要的是列表页。',
  },
  inspector: {
    cn: '属性面板（聚焦槽）',
    desc: '当前选中的**一个**一等对象的切面。固定 360、不可拖拽、只在 P1 出现。禁止放集合视图、禁止放与选中对象无关的全局信息、禁止同时放第二个对象。新增类型要过 layout.md §5.4 的一等对象三条判据。',
  },
  'inspector.head': {
    cn: '面板头',
    desc: '对象标识 + 对象类型 + 关闭。作用是让面板自给自足地说清「你在看谁」，不能依赖用户记得自己点了哪行。禁止放 tab 与操作按钮。',
  },
  'inspector.tabs': {
    cn: '切面 tab',
    desc: '只在**同一个对象**的多个切面之间切换。禁止跳到别的对象、禁止跳到别的页面。',
  },
  'inspector.body': {
    cn: '面板主体',
    desc: '字段键值、关联对象的引用行、过程事件流。禁止放需要宽度才能读的内容（长正文、全文日志、大图 → 走 overlay），禁止放集合表格。',
  },
  'inspector.foot': {
    cn: '面板操作区',
    desc: '**单行/单对象操作的唯一宿主**——表格里没有操作列，所有针对这一个对象的操作都在这里。禁止放批量操作（去 main.bulkbar）与页级操作（去 main.pagehead）。无可用操作时不渲染。',
  },
}

// ── 其它交给类型系统把关的硬规则 ────────────────────────────────

/** 页型枚举。layout.md §4.1 */
export type PageKind = 'list' | 'wizard' | 'form' | 'overview'

/**
 * 允许出现属性面板的页型。**只有 list**。
 * 这个窄联合是 layout.md §4.3 的编译期形态：向导页想渲染 InspectorSlot 会直接类型报错。
 * 缺少 'wizard' / 'form' / 'overview' 是**刻意的，不是漏了**——
 * 向导页的结构承诺是「当前这一步就是全部上下文」，一旦开了侧栏它会长成带侧栏的工作台。
 */
export type PageWithInspector = Extract<PageKind, 'list'>

/**
 * 属性面板的类型枚举。layout.md §5.1。
 * 现在只有 1 型是**刻意的**：一等对象由本产品决定，不由 Agent 的记忆决定。
 * 新增一型必须先过 §5.4 三条判据并写进 layout.md §5.1，不要复用 content-item 硬塞。
 */
export type InspectorKind = 'content-item'

/**
 * 表格列型。layout.md §6.2。
 * **这里没有 'actions' 是刻意的，不是漏了**：单行操作的唯一宿主是 inspector.foot。
 * 想加操作列 → 类型报错 → 去读 layout.md §10-1。
 */
export type TableColumnKind = 'select' | 'id' | 'text' | 'badge' | 'meta'

/** 表格列定义。列优先级 = 数组顺序，宽度不足时从最右开始滚出（layout.md §4.6） */
export type TableColumn = {
  kind: TableColumnKind
  label: string
  /** 结构参数：列的基准宽度。id 列与 select 列永不滚出 */
  width: number
}

// ── 区域标注开关 ─────────────────────────────────────────────
const LabelsCtx = createContext(false)
export const LabelsProvider = LabelsCtx.Provider
export const useLabels = () => useContext(LabelsCtx)

const TIP_W = 320

/**
 * 区域角标。说明框走 portal 挂到 body 上、用 fixed 定位：
 * 祖先的 overflow-hidden 裁不到它，也不参与原型内部的 z 层级竞争
 * ——用 z-index 修不干净，因为裁切不看 z。
 * 上下翻转与左右钳制按实际视口空间算，不维护手工白名单。
 */
function RegionLabel({ id, text, desc }: { id: RegionId; text: string; desc: string }) {
  const ref = useRef<HTMLSpanElement>(null)
  const [tip, setTip] = useState<{ left: number; top: number; up: boolean } | null>(null)

  const show = () => {
    const el = ref.current
    if (!el) return
    const r = el.getBoundingClientRect()
    const up = r.bottom + 8 + 160 > window.innerHeight
    setTip({
      left: Math.min(Math.max(8, r.left), Math.max(8, window.innerWidth - TIP_W - 8)),
      top: up ? r.top - 4 : r.bottom + 4,
      up,
    })
  }

  return (
    <span
      ref={ref}
      onMouseEnter={show}
      onMouseLeave={() => setTip(null)}
      className="absolute -top-px left-0 z-10 cursor-help rounded-br bg-sky-600/85 px-1 text-[10px] leading-[15px] font-medium whitespace-nowrap text-white hover:bg-sky-700"
    >
      {text}
      {tip &&
        createPortal(
          <div
            style={{
              position: 'fixed',
              left: tip.left,
              top: tip.top,
              width: TIP_W,
              transform: tip.up ? 'translateY(-100%)' : undefined,
              zIndex: 9999,
            }}
            className="pointer-events-none rounded-lg border border-neutral-700 bg-neutral-900 p-2.5 shadow-xl"
          >
            <p className="font-mono text-[10px] break-all text-sky-300">data-region="{id}"</p>
            {/* whitespace-normal 是必须的：角标上的 nowrap 会继承下来导致文字溢出 */}
            <p className="mt-1 text-[11px] leading-relaxed font-normal break-words whitespace-normal text-neutral-200">
              {desc}
            </p>
          </div>,
          document.body,
        )}
    </span>
  )
}

/** 结构容器。标注模式下描虚线边并浮出人读模块名。 */
export function Region({
  id,
  children,
  className = '',
  style,
  label,
  elRef,
}: {
  id: RegionId
  children?: ReactNode
  className?: string
  style?: CSSProperties
  /** 覆盖角标上的人读名（例如某个区域的收起形态） */
  label?: string
  elRef?: RefObject<HTMLDivElement | null>
}) {
  const on = useLabels()
  const meta = REGION_META[id]
  return (
    <div
      ref={elRef}
      data-region={id}
      style={style}
      className={`${className} ${on ? 'relative outline-1 outline-dashed outline-sky-500/50' : ''}`}
    >
      {on && <RegionLabel id={id} text={label ?? meta.cn} desc={meta.desc} />}
      {children}
    </div>
  )
}

// ── 中性线框零件 ─────────────────────────────────────────────
/** 状态标签。只表达「这里有个状态标签」，颜色语义归 design.md §9.3。 */
export function Badge({ children }: { children: ReactNode }) {
  return (
    <span className="shrink-0 rounded border border-neutral-400 px-1 text-[10px] leading-[14px] font-semibold whitespace-nowrap text-neutral-600">
      {children}
    </span>
  )
}

/** 胶囊：筛选 chip、计数角标。`on` 表示选中态。方角标签 vs 胶囊的语义差别见 design.md §9.4。 */
export function Pill({
  children,
  on = false,
  className = '',
}: {
  children: ReactNode
  on?: boolean
  className?: string
}) {
  return (
    <span
      className={`inline-flex shrink-0 items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs whitespace-nowrap ${
        on
          ? 'border-neutral-800 bg-neutral-800 font-medium text-white'
          : 'border-neutral-300 bg-white text-neutral-600'
      } ${className}`}
    >
      {children}
    </span>
  )
}

/** 按钮。`weight` 对应 design.md §9.2 的按钮层级，线框只用灰阶深浅区分。 */
export function Btn({
  children,
  weight = 'secondary',
  className = '',
  disabled = false,
  onClick,
}: {
  children: ReactNode
  weight?: 'primary' | 'secondary' | 'outline' | 'ghost'
  className?: string
  disabled?: boolean
  onClick?: () => void
}) {
  const style = {
    primary: 'bg-neutral-800 text-white border-neutral-800 font-medium',
    secondary: 'bg-neutral-100 text-neutral-700 border-neutral-200',
    outline: 'bg-white text-neutral-700 border-neutral-400',
    ghost: 'bg-transparent text-neutral-500 border-transparent',
  }[weight]
  return (
    <button
      disabled={disabled}
      onClick={onClick}
      className={`shrink-0 rounded border px-3 py-1.5 text-xs whitespace-nowrap ${style} ${disabled ? 'opacity-40' : ''} ${className}`}
    >
      {children}
    </button>
  )
}

/** 内容块：白底 + hairline。 */
export function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`rounded-lg border border-neutral-300 bg-white ${className}`}>{children}</div>
  )
}

/** 头像/图标占位。线框不画图形，只占位。 */
export function Tile({ size = 28, round = false }: { size?: number; round?: boolean }) {
  return (
    <span
      className={`shrink-0 bg-neutral-200 ${round ? 'rounded-full' : 'rounded-md'}`}
      style={{ width: size, height: size }}
    />
  )
}

/** 导航行 / 列表行 */
export function NavRow({
  children,
  on = false,
  indent = 0,
  right,
  onClick,
}: {
  children: ReactNode
  on?: boolean
  indent?: number
  right?: ReactNode
  onClick?: () => void
}) {
  return (
    <div
      onClick={onClick}
      className={`flex cursor-pointer items-center gap-2 rounded py-1.5 pr-2 text-sm ${
        on ? 'bg-neutral-200/80 font-medium text-neutral-900' : 'text-neutral-600'
      }`}
      style={{ paddingLeft: 10 + indent }}
    >
      <span className="flex-1 truncate">{children}</span>
      {right}
    </div>
  )
}

/** 分组小标题 */
export function GroupLabel({ children }: { children: ReactNode }) {
  return (
    <div className="px-2.5 pt-4 pb-1 text-[11px] font-medium tracking-wide text-neutral-400">
      {children}
    </div>
  )
}

/** 键值行。面板与表单共用。 */
export function Field({ k, v }: { k: string; v: ReactNode }) {
  return (
    <div className="flex gap-2 py-1.5 text-xs">
      <span className="w-20 shrink-0 text-neutral-400">{k}</span>
      <span className="min-w-0 flex-1 break-words text-neutral-700">{v}</span>
    </div>
  )
}

/** 非常态：统一居中一句说明 + 一个动作。落位规则见 layout.md §8。 */
export function StateBlock({
  kind,
  text,
  action,
}: {
  kind: '空' | '加载' | '局部失败' | '整区失败'
  text: string
  action?: string
}) {
  return (
    <div className="flex h-full min-h-[160px] flex-col items-center justify-center gap-2 p-6 text-center">
      <span className="rounded border border-neutral-300 px-1.5 py-0.5 font-mono text-[10px] text-neutral-500">
        {kind}态
      </span>
      <p className="max-w-[280px] text-xs text-neutral-500">{text}</p>
      {action && <Btn weight="outline">{action}</Btn>}
    </div>
  )
}
