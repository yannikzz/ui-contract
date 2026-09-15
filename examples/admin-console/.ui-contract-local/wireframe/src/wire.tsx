/**
 * 线框展示层的中性零件。**一次性**：结构变了就重新生成。
 *
 * 这个文件里没有装置——标注层、换肤横幅、浏览器外观全在 inspect.tsx，
 * 那个文件才是颜色豁免（ADR-0012）。
 *
 * 判据不是「这里没有颜色」，是「这里没有颜色的**值**」：所有颜色走 var(--wire-*)，
 * 值只在下面的 NEUTRAL 一处，且都是线框自己的灰。品牌值住 token 文件，
 * 骨架里没有品牌视觉可抄，就不会在 token 改动后变成过期的第二权威源。
 */
import { useMemo, useState } from 'react'
import type { CSSProperties, ReactNode } from 'react'

// 三个方向的候选值。**这是这个项目自己派生的**，不是插件带来的配色。
import { _candidates as CANDIDATES } from '../../tokens.input.json'

// 线框 import 资产层；反过来永远不成立。
// 这些封闭集**声明在资产层**，不在这里——它们是 layout.md 的条款，约束的是产品代码，
// 不是这个一次性目录。线框只是转手，方便页面文件就近 import。
import type { StatusKind, RegionId, PageKind, PageWithInspector, InspectorKind, TableColumnKind, TableColumn } from '../../../src/ui/region'
export type { StatusKind, RegionId, PageKind, PageWithInspector, InspectorKind, TableColumnKind, TableColumn }


// ── 颜色：只有这一处，而且全是灰 ──────────────────────────────
/**
 * 线框自己的中性色板——**除 inspect.tsx 之外，全项目唯一允许出现颜色值的地方**。
 * 下面每个零件都通过 var() 读它。往别处写一个颜色值，`check-colours.sh` 就会失败，
 * 这正是它的用处：一条被推翻的决定需要机械守卫，不是一句叮嘱。
 *
 * 角色比模板多，因为这个产品的界面真的用到了这么多层灰（表头、卡片底、选中行、
 * 四档边框、六档文字）。**加角色是允许的，加进来的必须是灰。**
 *
 * ⚠ 那个守卫抓不到的一件事：往这张表里加一个品牌色。这里允许写值——它们是线框自己的
 * 灰——所以「你加进来的到底是不是灰」永远是一个评审问题。
 */
export const NEUTRAL: Record<string, string> = {
  '--wire-surface': '#ffffff',
  '--wire-overlay': 'rgba(255,255,255,0.98)',
  '--wire-canvas': '#fafafa',
  '--wire-muted': '#f5f5f5',
  '--wire-shell': '#e5e5e5',
  '--wire-selected': 'rgba(229,229,229,0.7)',
  '--wire-fg-strong': '#171717',
  '--wire-fg': '#262626',
  '--wire-fg-2': '#404040',
  '--wire-body-fg': '#525252',
  '--wire-muted-fg': '#737373',
  '--wire-faint-fg': '#a3a3a3',
  '--wire-fainter-fg': '#d4d4d4',
  /* 三档，与 design.md §6b 一一对应。**档数必须相等**——多一档就是线框在发明规范 */
  '--wire-line': '#e5e5e5',
  '--wire-line-strong': '#d4d4d4',
  '--wire-line-contrast': '#a3a3a3',
  /* 圆角也是 token。切换方向时「锐利↔柔和」那条轴主要就体现在这里 */
  '--wire-radius-sm': '2px',
  '--wire-radius-md': '4px',
  '--wire-strong': '#262626',
  '--wire-strong-2': '#404040',
  '--wire-strong-fg': '#ffffff',
  /*
   * 状态标签的五个语义类。**未换肤时它们全是同一个灰**——线框自己不表达颜色语义，
   * 它只知道「这是哪一类」。换肤打开后，SKIN 把类映到 design.md 的语义色，
   * 于是这套配色在真实密度下做了什么才第一次看得见。
   */
  '--wire-status-neutral': '#737373',
  '--wire-status-progress': '#737373',
  '--wire-status-attention': '#737373',
  '--wire-status-blocked': '#737373',
  '--wire-status-done': '#737373',
}

/**
 * 线框角色 → 本项目 token 名。**由 design.md 的命名声明表填**，不是这里发明的。
 *
 * 留空的角色在预览开启时保持中性——不给它编一个值。那正是这套拆分要防的事。
 * 这里映得上的都是灰阶角色；`--wire-strong` 映到 accent，因为线框里「最强的那一档」
 * 在产品里就是主操作。
 */
export const SKIN: Record<string, string> = {
  '--wire-surface': '--color-surface-raised',
  '--wire-canvas': '--color-surface-page',
  '--wire-muted': '--color-surface-sunken',
  '--wire-shell': '--color-surface-sunken',
  '--wire-fg-strong': '--color-text-primary',
  '--wire-fg': '--color-text-primary',
  '--wire-fg-2': '--color-text-secondary',
  '--wire-body-fg': '--color-text-secondary',
  '--wire-muted-fg': '--color-text-tertiary',
  '--wire-faint-fg': '--color-text-disabled',
  '--wire-line': '--color-border-hairline',
  '--wire-line-strong': '--color-border-strong',
  '--wire-line-contrast': '--color-border-contrast',
  '--wire-radius-sm': '--radius-sm',
  '--wire-radius-md': '--radius-md',
  '--wire-strong': '--color-brand',
  '--wire-strong-fg': '--color-brand-foreground',
  '--wire-selected': '--color-fill-selected',
  // 语义类 → token。类归 layout.md §6.4，颜色归 design.md §2.3b；这里只是把两张表接上。
  // neutral 刻意不映射：design.md 说它不用语义色，所以它保持中性——**空 = 明确的决定**。
  '--wire-status-neutral': '',
  '--wire-status-progress': '--color-info',
  '--wire-status-attention': '--color-warning',
  '--wire-status-blocked': '--color-danger',
  '--wire-status-done': '--color-success',
  // 以下角色刻意没有映射：线框自己的装置灰、以及本产品没有对应 token 的档位。
  // 未映射 = 保持中性，不是漏了。
  '--wire-overlay': '',
  '--wire-fainter-fg': '',
  '--wire-strong-2': '',
}

/**
 * 换肤预览。**默认关闭，且不持久化**——每次重开都是灰的。
 *
 * 值是**运行时从 token 文件读**的（`getComputedStyle` 读 :root），一个字都不拷贝，
 * 所以不可能过期。读不到的角色保持 NEUTRAL。
 *
 * 为什么默认关：全灰是把 agent 逼去 token 文件的那个东西。线框一旦常驻带色，
 * agent 就没有理由再去找 token 文件，会把眼前看到的值写死进业务代码。
 */
export type ThemeId = 'A' | 'B' | 'C'

/**
 * 换肤预览的全部状态。
 *
 * `base` 是 token 文件此刻说的话——**运行时读，一个字都不拷贝**，所以不可能过期。
 * `draft` 是这次会话里手动改过的值，**跟标签页一起消失**：一个会记住值的线框就是第二个值权威。
 * `theme` 切的是**这个项目自己的三个方向**（design.md §1.0），不是插件推荐的配色——
 * 值来自旋钮记录里的候选集，那是这个项目派生出来的，不是这个插件带来的。
 */
export function useSkin(on: boolean) {
  const [draft, setDraft] = useState<Record<string, string>>({})
  const [theme, setTheme] = useState<ThemeId>('A')

  const base = useMemo(() => {
    const v: Record<string, string> = { ...NEUTRAL }
    if (!on || typeof window === 'undefined') return v
    const cand = (CANDIDATES as unknown as Record<string, { tokens: Record<string, string> }>)[theme]
    const root = getComputedStyle(document.documentElement)
    for (const [role, token] of Object.entries(SKIN)) {
      if (!token) continue
      // A = token 文件此刻的值（运行时读）；B / C = 当初否掉的那两个方向的候选值
      const got =
        theme === 'A'
          ? root.getPropertyValue(token).trim()
          : cand?.tokens[token.replace(/^--(color|radius|spacing|font)-/, '')] ?? ''
      if (got) v[role] = got
    }
    return v
  }, [on, theme])

  const vars = useMemo(
    () => ({ ...base, ...(on ? draft : {}) }) as CSSProperties,
    [base, draft, on],
  )

  return {
    vars,
    base,
    draft,
    theme,
    setTheme,
    set: (role: string, value: string) => setDraft((d) => ({ ...d, [role]: value })),
    reset: () => setDraft({}),
  }
}

// ── 中性线框零件 ─────────────────────────────────────────────
/**
 * Signature：行左缘的状态色块（design.md §1.1）。
 *
 * 3px 实心，颜色是这一行的状态语义类。`neutral` 没有语义色，所以没有色块——
 * **左缘一扫，剩下的就是要你管的。**
 *
 * 它是**填充不是边框**：§6b 规定边框只有 1px 一种宽度，而这道块不受那条约束。
 * 这个区分必须留在代码里，否则下一个人会把它当成第四档边框。
 *
 * 未换肤时它是中性灰——线框自己不表达颜色语义，签名的**形状**在，**颜色**要等 token。
 */
export function StatusEdge({ kind }: { kind: StatusKind }) {
  if (kind === 'neutral') return null
  return (
    <span
      aria-hidden
      className="absolute top-0 bottom-0 left-0 w-[3px]"
      style={{ background: `var(--wire-status-${kind})` }}
    />
  )
}

/**
 * 状态标签。它知道自己是**哪一类**（layout.md §6.4），不知道自己是什么颜色。
 *
 * 未换肤时五个类都是同一个灰——线框只表达「这里有个状态标签」。
 * 换肤打开后颜色从 token 走 var() 进来，线框仍然没有决定过任何颜色语义。
 */
export function Badge({ children, kind = 'neutral' }: { children: ReactNode; kind?: StatusKind }) {
  return (
    <span
      className="shrink-0 rounded border px-1 text-[10px] leading-[14px] font-semibold whitespace-nowrap"
      style={{
        borderColor: `var(--wire-status-${kind})`,
        color: `var(--wire-status-${kind})`,
      }}
    >
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
          ? 'border-[var(--wire-strong)] bg-[var(--wire-strong)] font-medium text-[var(--wire-strong-fg)]'
          : 'border-[var(--wire-line-strong)] bg-[var(--wire-surface)] text-[var(--wire-body-fg)]'
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
    primary: 'bg-[var(--wire-strong)] text-[var(--wire-strong-fg)] border-[var(--wire-strong)] font-medium',
    secondary: 'bg-[var(--wire-muted)] text-[var(--wire-fg-2)] border-[var(--wire-line)]',
    outline: 'bg-[var(--wire-surface)] text-[var(--wire-fg-2)] border-[var(--wire-line-contrast)]',
    ghost: 'bg-transparent text-[var(--wire-muted-fg)] border-transparent',
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
    <div className={`rounded-lg border border-[var(--wire-line-strong)] bg-[var(--wire-surface)] ${className}`}>{children}</div>
  )
}

/** 头像/图标占位。线框不画图形，只占位。 */
export function Tile({ size = 28, round = false }: { size?: number; round?: boolean }) {
  return (
    <span
      className={`shrink-0 bg-[var(--wire-shell)] ${round ? 'rounded-full' : 'rounded-md'}`}
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
        on ? 'bg-[var(--wire-selected)] font-medium text-[var(--wire-fg-strong)]' : 'text-[var(--wire-body-fg)]'
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
    <div className="px-2.5 pt-4 pb-1 text-[11px] font-medium tracking-wide text-[var(--wire-faint-fg)]">
      {children}
    </div>
  )
}

/** 键值行。面板与表单共用。 */
export function Field({ k, v }: { k: string; v: ReactNode }) {
  return (
    <div className="flex gap-2 py-1.5 text-xs">
      <span className="w-20 shrink-0 text-[var(--wire-faint-fg)]">{k}</span>
      <span className="min-w-0 flex-1 break-words text-[var(--wire-fg-2)]">{v}</span>
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
      <span className="rounded border border-[var(--wire-line-strong)] px-1.5 py-0.5 font-mono text-[10px] text-[var(--wire-muted-fg)]">
        {kind}态
      </span>
      <p className="max-w-[280px] text-xs text-[var(--wire-muted-fg)]">{text}</p>
      {action && <Btn weight="outline">{action}</Btn>}
    </div>
  )
}
