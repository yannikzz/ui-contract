/**
 * 线框展示层。**一次性**：结构变了就重新生成。
 *
 * 它消费资产层（`src/ui/region.tsx`），并加上两样资产层绝不能带的东西——
 * 区域标注层，和中性低保真零件。
 *
 * 视觉刻意保持中性：品牌值住 token 文件，骨架里没有品牌视觉可抄，
 * 就不会在 token 改动后变成过期的第二权威源。
 */
import { createContext, useContext, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import type { CSSProperties, ReactNode, RefObject } from 'react'

// 线框 import 资产层；反过来永远不成立。
import { Region, REGION_META, type RegionId } from './ui/region'

export type { RegionId }

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
/**
 * 资产层 `Region` 的带标注包装。
 *
 * 线框里每个结构容器经由它渲染；生产代码经由裸的 `Region`。
 * 同一套 id、同一个运行期标记，差别只有 inspect 覆盖层——这正是它住在这里而不是资产层的原因。
 */
export function AnnotatedRegion({
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
    <Region
      id={id}
      elRef={elRef}
      style={style}
      className={`${className} ${on ? 'relative outline-1 outline-dashed outline-sky-500/50' : ''}`}
    >
      {on && <RegionLabel id={id} text={label ?? meta.cn} desc={meta.desc} />}
      {children}
    </Region>
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
