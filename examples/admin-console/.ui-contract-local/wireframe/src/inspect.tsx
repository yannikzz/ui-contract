/**
 * inspect 装置。**这个文件本身就是线框的颜色豁免。**
 *
 * 例外的锚是文件，不是文件里的一对注释（ADR-0012）。这里的东西全是装置、
 * 没有一样是产品表面：区域角标、区域虚线框、说明气泡，以及演示开关条的外观。
 *
 * 它们全部写死颜色值，而且是刻意的。这里每一样都是「你用来控制或解读线框」的东西，
 * 所以无论皮肤怎么变都必须保持可读——也就是说，一样都不许跟着皮肤走。实测过的三条：
 *
 *   · 被它所描述的主题染了色的提示气泡，就没法再描述那个主题。
 *   · 被它所警告的值染了色的横幅会消失。第一版用 --wire-strong / --wire-strong-fg 画，
 *     浅色品牌色下白底白字——守卫恰好在主题让它最难被注意到的时候不见了。
 *     **一个警告不许依赖它所警告的东西。**
 *   · 演示开关条上有那个「关掉皮肤」的开关。给它换肤，坏主题就成了出不去的陷阱。
 *
 * 下面的导出是一份**声明出来的封闭名单**，而这里就是声明它的地方：
 *
 * APPARATUS: LabelsProvider useLabels AnnotatedRegion DemoPanel ThemeSwitch Group Sw Readout Alert SkinBanner SkinEditor toHex
 *
 * 这一行就是那个决定，它住在做决定的地方——往里加一个名字，diff 里就挨着被加的那个东西。
 * `check-colours.sh` **读**它，不带拷贝。
 *
 * ⚠ `APPARATUS:` 这个标记保持 ASCII，即使注释是中文——和路径表的 Key 列、
 * 声明表那三个关键词同一条规则。被翻译掉的话读它的人找不到，而**找不到必须报红**，
 * 不能当成「没有声明任何东西」——那会把整个文件悄悄豁免。
 * 把产品组件搬进来等于给它买到了写死颜色的权利，所以多一个名字必须是有人写下来的决定
 * ——而文件移动在 diff 里看得见，挪两行注释不然。
 *
 * 不是装置的东西住 wire.tsx，颜色一律走 var(--wire-*)，那边的值只有 NEUTRAL 一处。
 */
import { createContext, useContext, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import type { CSSProperties, ReactNode, RefObject } from 'react'

// 线框 import 资产层；反过来永远不成立。
import { Region, REGION_META, type RegionId } from '../../../src/ui/region'

// SKIN 是角色 → token 名的映射；编辑器按它建字段。它和其它颜色声明一起住 wire.tsx。
import { SKIN } from './wire'

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

// ── 演示开关条的外观 ─────────────────────────────────────────
/**
 * 这条不属于产品界面，它在窗口外，是给人验收用的。它的外观住在本文件里只有一个理由：
 * **那个「关掉皮肤」的开关在它上面。**
 *
 * 这个位置还顺手灭掉了一个坑。`Sw` 和 `Group` 原来坐在 App.tsx 末尾、产品标记之后，
 * 于是「把产品标记以下全部转成 var()」的一遍会连它们一起转掉，开关跟着主题变色。
 * 原来靠一句「记得别转」，现在靠文件边界——那一遍够不着这里。
 *
 * App.tsx 组合这些零件，自己一个颜色都不带。
 */
/**
 * 验收面板：**浮动、可收起**。
 *
 * 它原来是钉在顶部的一条横栏，吃掉约 180px 竖向空间——而线框存在的理由之一就是
 * **看真实密度**，一条常驻横栏会让「一屏装得下几行」这个问题失真。浮起来之后，
 * 收起状态只剩一个角标，产品界面拿回整屏。
 *
 * 收起状态**不隐藏换肤横幅**（见 SkinBanner）：那个警告不许被折叠掉。
 */
export function DemoPanel({
  open,
  onToggle,
  children,
}: {
  open: boolean
  onToggle: () => void
  children: ReactNode
}) {
  // 收起态**必须仍然是一个看得出来能点的东西**。第一版收起后留下一条 560px 宽的黑条，
  // 宽度没变、只是空了——读起来像残留而不是入口，用户找不到回去的路。
  // 所以收起时缩成一个自适应宽度的角标，展开时才铺开。
  if (!open) {
    return (
      <button
        onClick={onToggle}
        title="展开"
        className="fixed bottom-3 left-3 z-50 rounded border border-neutral-600 bg-neutral-900 px-2.5 py-1.5 text-[11px] font-medium text-white shadow-lg hover:bg-neutral-800"
      >
        ⚙ 验收面板
      </button>
    )
  }
  return (
    <div className="fixed bottom-3 left-3 z-50 flex max-h-[85vh] w-[min(560px,calc(100vw-1.5rem))] flex-col rounded border border-neutral-600 bg-neutral-900 text-white shadow-xl">
      <button
        onClick={onToggle}
        className="flex shrink-0 items-center justify-between gap-3 px-3 py-1.5 text-left text-[11px] font-medium hover:bg-neutral-800"
      >
        <span>验收面板</span>
        <span className="text-neutral-400">收起 ▾</span>
      </button>
      <div className="min-h-0 flex-1 space-y-1.5 overflow-y-auto border-t border-neutral-700 px-3 py-2">
        {children}
      </div>
    </div>
  )
}

/** 一组带标题的开关。 */
export function Group({ name, children }: { name: string; children: ReactNode }) {
  return (
    <div className="flex items-center gap-1.5 text-[11px]">
      <span className="text-neutral-400">{name}</span>
      <div className="flex flex-wrap gap-1">{children}</div>
    </div>
  )
}

/** 一个开关。`on` 是选中态。 */
export function Sw({
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
      className={`rounded border px-1.5 py-0.5 text-[11px] ${
        on ? 'border-white bg-white text-neutral-900' : 'border-neutral-600 text-neutral-300'
      }`}
    >
      {children}
    </button>
  )
}

/**
 * 实时读数行。降级规则要能对着数字验、而不是靠感觉，所以把实测宽度、各栏解析结果、
 * 阈值、触发了哪几级都打出来。
 */
export function Readout({ children }: { children: ReactNode }) {
  return (
    <div className="flex flex-wrap gap-x-4 gap-y-1 border-t border-neutral-700 pt-1.5 font-mono text-[10px] text-neutral-300">
      {children}
    </div>
  )
}

/** 读数里「有规则触发了」的那一格。固定色，理由同上：读不了的读数报不了任何东西。 */
export function Alert({ children }: { children: ReactNode }) {
  return <span className="text-amber-300">{children}</span>
}

/**
 * 跟着截图一起走的那块标记。
 *
 * ADR-0001 点名的失效是这样的：「半年后没人记得它默认关闭，agent 打开、截图、照着抄」。
 * **默认关闭够不着那个 agent，一张图片够得着。** 预览开着时必须渲染它，且不可关闭。
 *
 * 它的颜色是**固定的**，这正是要害。第一版用 --wire-strong / --wire-strong-fg 画，
 * 于是横幅被它正在警告的那套皮换了肤——浅色主色下白底白字，守卫恰好在主题让它最难被
 * 注意到的时候消失。**一个警告不许依赖它所警告的东西。**
 */
export function SkinBanner({ tokenFile }: { tokenFile: string }) {
  return (
    <div className="bg-amber-400 px-3 py-1 text-center font-mono text-[11px] font-medium text-neutral-950">
      换肤预览已开启 · 值是运行时从 {tokenFile} 读的 · 不要从这里抄值
    </div>
  )
}

/**
 * 方向切换。切的是**这个项目自己的三个方向**（design.md §1.0），不是插件推荐的配色。
 *
 * 这个区分是硬的：插件带三套品牌值 = ADR-0001 排除表里的「生成一套默认品牌」，做三次。
 * 这里的值来自旋钮记录的候选集，是这个项目从自己的属性坐标派生出来的——
 * 切换只为在**真实密度**下看当初否掉的那两个长什么样，而不是替用户挑配色。
 */
export function ThemeSwitch({
  value,
  onChange,
  options,
}: {
  value: string
  onChange: (id: 'A' | 'B' | 'C') => void
  options: { id: 'A' | 'B' | 'C'; label: string; axes: string }[]
}) {
  return (
    <div className="flex flex-wrap items-center gap-1.5 text-[11px]">
      <span className="text-neutral-400">方向</span>
      {options.map((o) => (
        <button
          key={o.id}
          onClick={() => onChange(o.id)}
          title={o.axes}
          className={`rounded border px-1.5 py-0.5 ${
            value === o.id ? 'border-white bg-white text-neutral-900' : 'border-neutral-600 text-neutral-300'
          }`}
        >
          {o.label}
        </button>
      ))}
    </div>
  )
}

/**
 * Token 编辑器。**它什么都不写盘。**
 *
 * 值活在内存里，关掉标签页就没了——一个会记住值的线框是第二个值权威（ADR-0007）。
 * 输出是一段**提示词**，交给 agent 去改 `tokens.input.json`，再由 assets 落进 token 文件。
 *
 * ⚠ 提示词**不许发明改动**。实测过：打开原生取色器再关掉，会把 `oklch(...)` 重写成 `#rrggbb`
 * ——同一个颜色、不同记法。照报的话 agent 会悄悄把整个项目的色彩空间转成 hex。
 * 所以「改了」的判据是**两个值解析后不同**，而且脏标记和提示词共用同一次比较：
 * 两次比较迟早会不一致，那时面板说的和提示词说的就不是一回事了。
 */
export function SkinEditor({
  base,
  draft,
  onChange,
  onReset,
  tokenFile,
  theme,
  chosen,
  themeLabel,
}: {
  base: Record<string, string>
  draft: Record<string, string>
  onChange: (role: string, value: string) => void
  onReset: () => void
  tokenFile: string
  /** 当前正在预览的方向 */
  theme: string
  /** design.md §1.0 里已经选定的那个方向 */
  chosen: string
  themeLabel: (id: string) => string
}) {
  // 三态，不是布尔。**「没复制成功」和「还没点」必须分开**——合成一个之后，
  // 失败会长得像没点过，而用户已经以为自己拿到了那段文字。
  const [copyState, setCopyState] = useState<'idle' | 'ok' | 'failed'>('idle')
  const taRef = useRef<HTMLTextAreaElement>(null)
  const rows = Object.entries(SKIN).filter(([, token]) => token)
  const changed = rows
    .map(([role, token]) => ({ role, token, from: base[role] ?? '', to: draft[role] }))
    .filter((r) => r.to !== undefined && !sameValue(r.from, r.to))

  // 切方向和调 token 是**两件不同的事**，提示词不能把它们压成一件。
  //
  // 方向变更是 `originate` Step 1 的决定：先改 design.md §1.0（方向、代价、色相基准），
  // 再重新派生值，还要回头核 layout.md 里依赖刻度的那几个数。直接吐一份 token diff 的话，
  // agent 会去改 token 文件而文档还写着旧方向——**文档说 A、值是 C，第二权威源当场成立**。
  // 所以方向那一段先出，而且它给的是流程不是数值。
  const switched = theme !== chosen
  const lines: string[] = []
  if (switched) {
    lines.push(
      `在线框里按真实密度看过之后，倾向 ${themeLabel(theme)}，而不是当前选定的 ${themeLabel(chosen)}。`,
      ``,
      `**这是方向变更，不是调值。** 顺序不能反：`,
      `  1. 先改 design.md §1.0：方向、代价、以及色相基准是否跟着变`,
      `  2. 再按新坐标重新派生值，落进 ${tokenFile}`,
      `  3. 回头核 layout.md 里依赖字号/行高的那几个数（面板宽、最小可用宽、每页条数）`,
      ``,
      `不要跳过第 1 步直接改 token —— 那会让文档写着一个方向、值是另一个。`,
    )
  }
  if (changed.length) {
    if (switched) lines.push(``, `另外，在 ${themeLabel(theme)} 的基础上手动调过这几个：`, ``)
    else
      lines.push(
        `改 ${tokenFile} 里的这些 token。以下值是在线框里对着真实密度调出来的；`,
        `线框什么都不存，所以现在磁盘上还没有任何改动。`,
        ``,
      )
    lines.push(...changed.map((c) => `  ${c.token}  ${c.from}  ->  ${c.to}`))
    lines.push(``, `名字原样保留 —— design.md 的命名声明表才是名字权威。`)
  }
  const prompt = lines.join('\n')

  return (
    <div className="border-t border-neutral-700 pt-1.5 text-[11px]">
      <div className="mb-1.5 flex items-center gap-2">
        <span className="font-mono text-neutral-400">token 编辑器</span>
        <span className="text-neutral-500">
          {switched ? `方向 → ${themeLabel(theme)}` : ''}
          {switched && changed.length ? ' · ' : ''}
          {changed.length ? `已改 ${changed.length} 个` : switched ? '' : '未改动'}
        </span>
        <button className="ml-auto rounded border border-neutral-600 px-1.5 py-0.5" onClick={onReset}>
          重置
        </button>
        <button
          className="rounded border border-amber-400 bg-amber-400 px-1.5 py-0.5 font-medium text-neutral-950 disabled:opacity-40"
          disabled={!prompt}
          onClick={async () => {
            // 剪贴板在非安全上下文里（用局域网 IP 打开、或用户拒绝授权）**根本不存在**。
            // 原来写的是 `navigator.clipboard?.writeText(...)`，于是它静默什么都没做，
            // 然后照样显示「已复制」——**它在说谎**，而这段提示词是这条路径上
            // 用户意图的唯一载体（ADR-0007）。所以按真实结果报，失败就选中让人自己按 ⌘C。
            try {
              if (!navigator.clipboard) throw new Error('no clipboard in this context')
              await navigator.clipboard.writeText(prompt)
              setCopyState('ok')
            } catch {
              setCopyState('failed')
              taRef.current?.select()
            }
            setTimeout(() => setCopyState('idle'), 2500)
          }}
        >
          {copyState === 'ok' ? '已复制' : copyState === 'failed' ? '已选中，按 ⌘C' : '复制提示词'}
        </button>
      </div>
      {prompt ? (
        <textarea
          ref={taRef}
          readOnly
          value={prompt}
          onFocus={(e) => e.currentTarget.select()}
          rows={Math.min(10, prompt.split('\n').length)}
          className="mb-1.5 w-full resize-y rounded border border-neutral-700 bg-neutral-950 p-1.5 font-mono text-[10px] leading-relaxed text-neutral-200"
        />
      ) : (
        // 按钮为什么是灰的，要说出来。只写 disabled 的话，用户会以为功能坏了。
        <p className="mb-1.5 text-neutral-500">改一个值、或切到别的方向，这里会出现可复制的提示词。</p>
      )}
      <div className="grid grid-cols-[repeat(auto-fit,minmax(200px,1fr))] gap-x-3 gap-y-1">
        {rows.map(([role, token]: [string, string]) => {
          const cur = draft[role] ?? base[role] ?? ''
          const dirty = draft[role] !== undefined && !sameValue(base[role] ?? '', draft[role])
          const isColour = /^#|^rgb|^oklch|^hsl/.test(cur)
          return (
            <label key={role} className="flex items-center gap-1.5">
              <span
                className={`w-24 shrink-0 truncate font-mono ${dirty ? 'text-amber-300' : 'text-neutral-400'}`}
                title={`${token}  (${role})`}
              >
                {token}
              </span>
              {isColour && (
                <input
                  type="color"
                  value={cur.slice(0, 7)}
                  onChange={(e) => onChange(role, e.target.value)}
                  className="h-5 w-6 shrink-0 rounded border border-neutral-600 bg-transparent p-0"
                />
              )}
              <input
                type="text"
                value={cur}
                onChange={(e) => onChange(role, e.target.value)}
                className="min-w-0 flex-1 rounded border border-neutral-600 bg-neutral-950 px-1 py-0.5 font-mono text-neutral-200"
              />
            </label>
          )
        })}
      </div>
    </div>
  )
}

/** 两个值解析后是不是同一个颜色。记法不同不算改动——见 SkinEditor 的注释。 */
function sameValue(a: string, b: string): boolean {
  if (a === b) return true
  const na = toHex(a)
  const nb = toHex(b)
  return na !== null && nb !== null && na === nb
}

/**
 * 把任意 CSS 颜色**画一遍**来解析成 #rrggbb(aa)，所以 oklch()/lab() 都认。
 * 从 getComputedStyle 里读数字不行：现代浏览器把 `oklch(...)` 原样留着，
 * 照着刮会把明度/彩度/色相当成 r/g/b —— 不报错、数字看着合理、全错。
 */
let cx: CanvasRenderingContext2D | null = null
export function toHex(v: string): string | null {
  if (typeof window === 'undefined' || !v?.trim()) return null
  if (!cx) {
    const c = document.createElement('canvas')
    c.width = c.height = 1
    cx = c.getContext('2d', { willReadFrequently: true })
  }
  if (!cx) return null
  cx.fillStyle = '#010203'
  cx.fillStyle = v
  const a = cx.fillStyle
  cx.fillStyle = '#040506'
  cx.fillStyle = v
  if (a !== cx.fillStyle) return null
  cx.clearRect(0, 0, 1, 1)
  cx.fillRect(0, 0, 1, 1)
  const d = cx.getImageData(0, 0, 1, 1).data
  const n = (x: number) => x.toString(16).padStart(2, '0')
  const rgb = '#' + n(d[0]) + n(d[1]) + n(d[2])
  return d[3] === 255 ? rgb : rgb + n(d[3])
}
