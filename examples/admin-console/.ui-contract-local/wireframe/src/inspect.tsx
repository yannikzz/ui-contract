/**
 * inspect 装置。**这个文件本身就是线框的颜色豁免。**
 *
 * 例外的锚是文件，不是文件里的一对注释。这里的东西全是装置、没有一样是产品表面：
 * 区域角标、区域虚线框、说明气泡、换肤横幅、换肤编辑器，以及整个浏览器外观——
 * 页框、视口、角落、面板、区、样张墙。
 *
 * 它们全部写死颜色值，而且是刻意的。这里每一样都是「你用来控制或解读线框」的东西，
 * 所以无论皮肤怎么变都必须保持可读——也就是说，一样都不许跟着皮肤走。实测过的三条：
 *
 *   · 被它所描述的主题染了色的提示气泡，就没法再描述那个主题。
 *   · 被它所警告的值染了色的横幅会消失。第一版用 --wire-strong / --wire-strong-fg 画，
 *     浅色品牌色下白底白字——守卫恰好在主题让它最难被注意到的时候不见了。
 *     **一个警告不许依赖它所警告的东西。**
 *   · 面板上有那个「关掉皮肤」的开关。给它换肤，坏主题就成了出不去的陷阱。
 *
 * 投影周围的浏览器分四个部位，落位判据只有一条，而且判据由下面的组件执行，不靠谁的判断：
 *
 *   Browser    页框：白底，装着视口那一列和面板。App.tsx 不带颜色，所以页框的白住这里
 *   Viewport   视口：浅灰圆角那块，投影在它里面
 *   Corners    角落：视口内，只放**作用在视口上**的（视图切换、镜头、适应、画布底色）。
 *              封闭集，由 Viewport 自己渲染
 *   Panel      面板：视口外，只放**作用在原型上**的。它只收 Zone；Zone 必须声明区；
 *              Panel 负责排序。App.tsx 不决定任何控件放哪
 *   Wall       样张墙：视口的第二种视图，每个页型 × 状态 × 宽度档。
 *              **不画箭头**——墙上不许有任何在 layout.md 里没有条款的东西
 *
 * 下面的导出是一份**声明出来的封闭名单**，而这里就是声明它的地方：
 *
 * APPARATUS: LabelsProvider useLabels AnnotatedRegion SkinBanner SkinEditor toHex ViewMode PanelZone Browser Viewport Panel Zone Choice Readout Alert Wall
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
import { Children, createContext, isValidElement, useContext, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import type { CSSProperties, ReactElement, ReactNode, RefObject } from 'react'

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
    <div className="text-[11px] text-neutral-800">
      <div className="mb-1.5 flex items-center gap-2">
        <span className="font-mono text-neutral-500">token 编辑器</span>
        <span className="text-neutral-500">
          {switched ? `方向 → ${themeLabel(theme)}` : ''}
          {switched && changed.length ? ' · ' : ''}
          {changed.length ? `已改 ${changed.length} 个` : switched ? '' : '未改动'}
        </span>
        <button className="ml-auto rounded border border-neutral-300 px-1.5 py-0.5 hover:bg-neutral-100" onClick={onReset}>
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
          className="mb-1.5 w-full resize-y rounded border border-neutral-200 bg-neutral-50 p-1.5 font-mono text-[10px] leading-relaxed text-neutral-800"
        />
      ) : (
        // 按钮为什么是灰的，要说出来。只写 disabled 的话，用户会以为功能坏了。
        <p className="mb-1.5 text-neutral-500">改一个值、或切到别的方向，这里会出现可复制的提示词。</p>
      )}
      <div className="grid grid-cols-1 gap-y-1">
        {rows.map(([role, token]: [string, string]) => {
          const cur = draft[role] ?? base[role] ?? ''
          const dirty = draft[role] !== undefined && !sameValue(base[role] ?? '', draft[role])
          const isColour = /^#|^rgb|^oklch|^hsl/.test(cur)
          return (
            <label key={role} className="flex items-center gap-1.5">
              <span
                className={`w-24 shrink-0 truncate font-mono ${dirty ? 'text-amber-700' : 'text-neutral-500'}`}
                title={`${token}  (${role})`}
              >
                {token}
              </span>
              {isColour && (
                <input
                  type="color"
                  value={cur.slice(0, 7)}
                  onChange={(e) => onChange(role, e.target.value)}
                  className="h-5 w-6 shrink-0 rounded border border-neutral-300 bg-transparent p-0"
                />
              )}
              <input
                type="text"
                value={cur}
                onChange={(e) => onChange(role, e.target.value)}
                className="min-w-0 flex-1 rounded border border-neutral-300 bg-white px-1 py-0.5 font-mono text-neutral-800"
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

// ── 浏览器外观 ─────────────────────────────────────────────────
/**
 * 四个部位，一条判据：改变「怎么看」的控件进角落，改变「看什么」的控件进面板。
 * 判据住在这些组件里——Viewport 自己渲染角落，Panel 只收 Zone，Zone 必须声明区，
 * Choice 自己挑形状——所以 App.tsx 只负责组合，不做任何落位决定。
 *
 * 这些全是装置：浅色、固定色、永不跟随皮肤。判据唯一的封闭例外是面板自身的收起/展开：
 * 它是操作，但必须常驻可见，否则没有回去的入口。
 */

/** 视口能显示的两种视图。 */
export type ViewMode = 'proto' | 'wall'

/**
 * 面板的区，按控件改变什么来分。**封闭联合类型**：哪个区都放不下的控件，
 * 就是作用在视口上的控件，它属于角落。
 */
export type PanelZone = 'screen' | 'condition' | 'view' | 'output'
const ZONE_ORDER: readonly PanelZone[] = ['screen', 'condition', 'view', 'output']
// 区标题两个字，没有副标题。
const ZONE_TITLE: Record<PanelZone, string> = {
  screen: '选屏',
  condition: '条件',
  view: '视图',
  output: '输出',
}

const ZOOM_MIN = 0.1
const ZOOM_MAX = 3
const clampZoom = (z: number) => Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, +z.toFixed(3)))

function CornerBtn({
  on,
  mono,
  title,
  onClick,
  children,
}: {
  on?: boolean
  mono?: boolean
  title?: string
  onClick: () => void
  children: ReactNode
}) {
  return (
    <button
      title={title}
      onClick={onClick}
      className={`inline-flex h-6 min-w-6 items-center justify-center rounded-[5px] px-1.5 text-[11px] hover:bg-neutral-100 hover:text-neutral-900 ${
        on ? 'bg-neutral-100 font-medium text-neutral-900' : 'text-neutral-500'
      } ${mono ? 'min-w-11 font-mono' : ''}`}
    >
      {children}
    </button>
  )
}

/**
 * 页框。白底、固定色：它是装置，而 App.tsx 不许带自己的颜色。
 * `children` 是视口那一列（横幅在上，视口在下）；`panel` 在右侧、视口之外，
 * 两者之间不画线——视口的灰边就是分界。
 */
export function Browser({ panel, children }: { panel: ReactNode; children: ReactNode }) {
  return (
    <div className="flex h-screen bg-white font-sans text-neutral-900">
      <div className="flex min-w-0 flex-1 flex-col gap-2.5 p-3.5">{children}</div>
      {panel}
    </div>
  )
}

/**
 * 视口：投影在它里面，面板在它外面。
 *
 * 它拥有镜头和角落。镜头用的是 CSS `zoom`，它在布局层缩放盒子——所以滚动跟着它走、
 * 锚点算式只有一行，而**实测宽不动**：`offsetWidth` 和 ResizeObserver 报的都是未缩放的
 * 布局像素。**永远不要用 getBoundingClientRect 除以镜头倍率反推外壳宽。** 实测过：
 * 给镜头加过渡、再从视觉矩形反推，每次捏合都在上一次动画走到一半时量，外壳宽跟着抖，
 * 降级判定跟着翻。镜头不做过渡，理由相同。
 *
 * 捏合与 ⌘+滚轮被拦下，浏览器不会缩放页面。墙模式下缩放以光标为锚，画布靠拖动平移。
 * 没有滚动条；滚轮和拖动负责移动画布。
 */
export function Viewport({
  mode,
  onMode,
  zoom,
  onZoom,
  clamp = 0,
  wall,
  children,
}: {
  mode: ViewMode
  onMode: (m: ViewMode) => void
  zoom: number
  onZoom: (z: number) => void
  /** 原型被钳到的宽度档；0 = 自适应 */
  clamp?: number
  /** 样张墙。不传就不渲染视图切换——空的角落不渲染 */
  wall?: ReactNode
  children: ReactNode
}) {
  const vp = useRef<HTMLDivElement>(null)
  const sc = useRef<HTMLDivElement>(null)
  const wallEl = useRef<HTMLDivElement>(null)
  const stageEl = useRef<HTMLDivElement>(null)
  const [dark, setDark] = useState(false)
  const [dragging, setDragging] = useState(false)
  // 给下面那些非 React 的监听器用的最新值，监听器只挂一次。
  const live = useRef({ mode, zoom, onZoom })
  live.current = { mode, zoom, onZoom }
  // 缩放时要留在原地的那一点：(ax, ay) 是它在锚元素自己的未缩放坐标里的位置，
  // (cx, cy) 是它在屏幕上的位置。React 按新倍率重绘之后，量锚元素**实际落在哪**再修正滚动——
  // 所以原型放大到超出视口、从居中退成顶对齐的那一刻，什么都不会跳。
  // 这里的 getBoundingClientRect 读的是**位置**，永远不是宽度。
  const anchorEl = () => (live.current.mode === 'wall' ? wallEl.current : stageEl.current)
  const pendingAnchor = useRef<{ ax: number; ay: number; cx: number; cy: number } | null>(null)
  const zoomTo = (next: number, cx: number, cy: number) => {
    const { zoom, onZoom } = live.current
    if (next === zoom) return
    const el = anchorEl()
    if (el) {
      const r = el.getBoundingClientRect()
      pendingAnchor.current = { ax: (cx - r.left) / zoom, ay: (cy - r.top) / zoom, cx, cy }
    }
    onZoom(next)
  }
  const zoomToRef = useRef(zoomTo)
  zoomToRef.current = zoomTo
  // 按钮没有光标，所以以视口中心为锚——原型放得下时，视口中心就是原型中心。
  const zoomAtCentre = (next: number) => {
    const el = vp.current
    if (!el) return
    const r = el.getBoundingClientRect()
    zoomTo(next, r.left + el.clientWidth / 2, r.top + el.clientHeight / 2)
  }

  useLayoutEffect(() => {
    const a = pendingAnchor.current
    const s = sc.current
    const el = anchorEl()
    if (!a || !s || !el) return
    const r = el.getBoundingClientRect()
    s.scrollLeft += r.left + a.ax * live.current.zoom - a.cx
    s.scrollTop += r.top + a.ay * live.current.zoom - a.cy
    pendingAnchor.current = null
  })

  useEffect(() => {
    const el = vp.current
    const s = sc.current
    if (!el || !s) return
    // 两种模式都以光标为锚。
    const zoomAt = (factor: number, cx: number, cy: number) =>
      zoomToRef.current(clampZoom(live.current.zoom * factor), cx, cy)
    // 触控板捏合以 wheel + ctrlKey 的形式到达；鼠标上的 ⌘+滚轮是同一个手势。
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey && !e.metaKey) return
      e.preventDefault()
      zoomAt(Math.exp(-e.deltaY * 0.01), e.clientX, e.clientY)
    }
    // Safari 另有 gesture 事件；不拦的话它会缩放页面。
    type GestureEvt = Event & { scale?: number; clientX?: number; clientY?: number }
    let last = 1
    const onGestureStart = (e: Event) => {
      e.preventDefault()
      last = 1
    }
    const onGestureChange = (e: GestureEvt) => {
      e.preventDefault()
      const scale = e.scale ?? 1
      zoomAt(scale / last, e.clientX ?? 0, e.clientY ?? 0)
      last = scale
    }
    const onGestureEnd = (e: Event) => e.preventDefault()
    el.addEventListener('wheel', onWheel, { passive: false })
    el.addEventListener('gesturestart', onGestureStart, { passive: false })
    el.addEventListener('gesturechange', onGestureChange, { passive: false })
    el.addEventListener('gestureend', onGestureEnd, { passive: false })
    return () => {
      el.removeEventListener('wheel', onWheel)
      el.removeEventListener('gesturestart', onGestureStart)
      el.removeEventListener('gesturechange', onGestureChange)
      el.removeEventListener('gestureend', onGestureEnd)
    }
  }, [])

  // 按住拖动平移，仅墙模式。挂在 window 上，拖快了也不会脱手。
  useEffect(() => {
    const s = sc.current
    if (!s) return
    let drag: { x: number; y: number; l: number; t: number } | null = null
    const down = (e: MouseEvent) => {
      if (live.current.mode !== 'wall' || e.button !== 0) return
      drag = { x: e.clientX, y: e.clientY, l: s.scrollLeft, t: s.scrollTop }
      setDragging(true)
    }
    const move = (e: MouseEvent) => {
      if (!drag) return
      s.scrollLeft = drag.l - (e.clientX - drag.x)
      s.scrollTop = drag.t - (e.clientY - drag.y)
    }
    const up = () => {
      drag = null
      setDragging(false)
    }
    s.addEventListener('mousedown', down)
    window.addEventListener('mousemove', move)
    window.addEventListener('mouseup', up)
    return () => {
      s.removeEventListener('mousedown', down)
      window.removeEventListener('mousemove', move)
      window.removeEventListener('mouseup', up)
    }
  }, [])

  const fit = () => {
    const el = vp.current
    if (!el) return
    if (mode === 'wall' && wallEl.current) {
      // 整面墙塞进一屏：按更紧的那个轴。
      const w = wallEl.current.offsetWidth
      const h = wallEl.current.offsetHeight
      zoomAtCentre(clampZoom(Math.min(1, el.clientWidth / w, el.clientHeight / h)))
    } else {
      const avail = el.clientWidth - 40
      zoomAtCentre(clampZoom(Math.min(1, avail / (clamp || avail))))
    }
  }

  const corner =
    'absolute bottom-3 z-10 flex h-8 items-center gap-0.5 rounded-lg border border-neutral-200 bg-white p-[3px] text-neutral-900 shadow-[0_1px_2px_rgba(0,0,0,.06),0_4px_12px_rgba(0,0,0,.06)]'

  return (
    <div
      ref={vp}
      data-canvas={dark ? 'dark' : 'light'}
      className={`group relative min-h-0 flex-1 overflow-hidden rounded-xl border ${
        dark ? 'border-neutral-700 bg-neutral-800' : 'border-neutral-200 bg-neutral-100'
      }`}
    >
      <div
        ref={sc}
        className={`absolute inset-0 overflow-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden ${
          mode === 'wall' ? (dragging ? 'cursor-grabbing select-none' : 'cursor-grab') : ''
        }`}
      >
        {mode === 'proto' ? (
          <div className="flex min-h-full p-5 pb-16" style={{ justifyContent: 'safe center', alignItems: 'safe center' }}>
            <div ref={stageEl} className="shrink-0" style={{ width: clamp || '100%', zoom }}>
              {children}
            </div>
          </div>
        ) : (
          <div ref={wallEl} className="w-max p-6 pb-20" style={{ zoom }}>
            {wall}
          </div>
        )}
      </div>

      {wall !== undefined && (
        <div className={`${corner} left-3`}>
          <CornerBtn on={mode === 'proto'} onClick={() => onMode('proto')}>
            原型
          </CornerBtn>
          <CornerBtn on={mode === 'wall'} onClick={() => onMode('wall')}>
            样张墙
          </CornerBtn>
        </div>
      )}
      <div className={`${corner} right-3`}>
        <CornerBtn title="缩小" onClick={() => zoomAtCentre(clampZoom(zoom - 0.1))}>
          −
        </CornerBtn>
        <CornerBtn mono title="回到 100%" onClick={() => zoomAtCentre(1)}>
          {Math.round(zoom * 100)}%
        </CornerBtn>
        <CornerBtn title="放大" onClick={() => zoomAtCentre(clampZoom(zoom + 0.1))}>
          +
        </CornerBtn>
        <CornerBtn title="适应窗口" onClick={fit}>
          适应
        </CornerBtn>
        <span className="mx-0.5 h-4 w-px bg-neutral-200" />
        <CornerBtn on={dark} title="画布底色" onClick={() => setDark(!dark)}>
          ◐
        </CornerBtn>
      </div>
    </div>
  )
}

type ZoneProps = { zone: PanelZone; children?: ReactNode }

/**
 * 面板的一个区。`zone` 必填且封闭，所以放一个控件必须先说它改变什么。
 * 空区不渲染——向导步的控件随向导页一起消失，不会留下一个空标题。
 *
 * 输出区刻意隔开：它是唯一产出会流回项目的区（编辑器的 prompt）。其余全部随标签页消失。
 */
export function Zone({ zone, children }: ZoneProps) {
  if (Children.toArray(children).length === 0) return null
  const out = zone === 'output'
  return (
    <section className={`border-t border-neutral-200 px-3.5 pt-3 pb-3.5 ${out ? 'bg-neutral-50' : ''}`}>
      <div className={`mb-2.5 text-[11px] font-semibold ${out ? 'text-amber-700' : 'text-neutral-900'}`}>
        {ZONE_TITLE[zone]}
      </div>
      {children}
    </section>
  )
}

/**
 * 面板。只收 Zone，别的一概不收，而且由它排序——App.tsx 没法把一个控件放到最前、
 * 最后、或区外。墙模式下丢掉选屏和条件两区（它们成了墙的坐标轴），读数块也丢掉
 * （没有「当前」一屏）。
 *
 * 收起态必须仍然是一个看得出能点的东西。第一版收起后留下一条 560px 的空条——宽度没变、
 * 只是空了——读起来像残留，用户找不到回去的路。
 */
export function Panel({
  open,
  onToggle,
  mode,
  title,
  readout,
  children,
}: {
  open: boolean
  onToggle: () => void
  mode: ViewMode
  /** 面板的名字 */
  title: string
  /** 读数块；墙模式下隐藏 */
  readout?: ReactNode
  children?: ReactNode
}) {
  if (!open) {
    return (
      <button
        onClick={onToggle}
        className="fixed top-1/2 right-0 z-50 -translate-y-1/2 rounded-l-lg border border-r-0 border-neutral-200 bg-white px-2 py-2.5 text-[11px] tracking-widest text-neutral-900 shadow-md [writing-mode:vertical-rl] hover:bg-neutral-100"
      >
        ⚙ {title}
      </button>
    )
  }
  const kids = Children.toArray(children)
  for (const z of kids) {
    if (!isValidElement(z) || z.type !== Zone) {
      // 刻意报得响。TypeScript 判不了 JSX 子元素的组件身份，
      // 所以「面板里没有东西在区外」这条在这里、在渲染时守。
      throw new Error('Panel accepts <Zone> children only — a control outside a zone has no place')
    }
  }
  const zones = kids as ReactElement<ZoneProps>[]
  const hidden: readonly PanelZone[] = mode === 'wall' ? ['screen', 'condition'] : []
  const ordered = ZONE_ORDER.filter((k) => !hidden.includes(k)).flatMap((k) =>
    zones.filter((z) => z.props.zone === k),
  )
  return (
    <aside className="flex w-[288px] shrink-0 flex-col bg-white pr-1 text-neutral-900">
      <div className="flex shrink-0 items-center justify-between px-3.5 pt-3 pb-2.5">
        <span className="text-xs font-semibold">{title}</span>
        <button
          onClick={onToggle}
          title="收起"
          className="inline-flex h-[26px] w-[26px] items-center justify-center rounded-md border border-neutral-200 text-xs text-neutral-500 hover:bg-neutral-100 hover:text-neutral-900"
        >
          ›
        </button>
      </div>
      {/* 读数块在滚动区之外：四区滚动时它不动 */}
      {mode === 'proto' && <div className="shrink-0">{readout}</div>}
      <div className="min-h-0 flex-1 overflow-y-auto">{ordered}</div>
    </aside>
  )
}

type ChoiceBool = {
  label: string
  value: boolean
  onChange: (v: boolean) => void
  options?: undefined
}
type ChoiceOne<T extends string | number> = {
  label: string
  options: readonly T[]
  value: T
  onChange: (v: T) => void
  labelOf?: (v: T) => string
}

/**
 * 唯一的控件。形状是数据的函数，调用方从不挑：布尔是开关，≤ 4 个互斥项是分段控件，
 * ≥ 5 项是下拉。「可以挑」就是不一致的入口；这里把挑的机会拿掉，和 Panel 拿掉排序一样。
 */
export function Choice<T extends string | number>(p: ChoiceBool | ChoiceOne<T>) {
  let widget: ReactNode
  if (p.options === undefined) {
    widget = (
      <button
        role="switch"
        aria-checked={p.value}
        onClick={() => p.onChange(!p.value)}
        className={`relative h-[18px] w-[30px] rounded-full transition-colors ${p.value ? 'bg-neutral-900' : 'bg-neutral-300'}`}
      >
        <span
          className={`absolute top-0.5 h-3.5 w-3.5 rounded-full bg-white shadow-sm transition-[left] ${p.value ? 'left-[14px]' : 'left-0.5'}`}
        />
      </button>
    )
  } else if (p.options.length <= 4) {
    const { options, value, onChange, labelOf } = p
    widget = (
      <div className="inline-flex max-w-full gap-0.5 rounded-[7px] bg-neutral-100 p-0.5">
        {options.map((o) => (
          <button
            key={o}
            onClick={() => onChange(o)}
            className={`rounded-[5px] px-2 py-[3px] text-[11px] whitespace-nowrap ${
              o === value ? 'bg-white font-medium text-neutral-900 shadow-[0_1px_2px_rgba(0,0,0,.08)]' : 'text-neutral-500'
            }`}
          >
            {labelOf ? labelOf(o) : o}
          </button>
        ))}
      </div>
    )
  } else {
    const { options, value, onChange, labelOf } = p
    widget = (
      <select
        value={value}
        onChange={(e) => onChange(options[e.target.selectedIndex])}
        className="rounded-md border border-neutral-200 bg-white px-2 py-[3px] text-[11px] text-neutral-900"
      >
        {options.map((o) => (
          <option key={o} value={o}>
            {labelOf ? labelOf(o) : o}
          </option>
        ))}
      </select>
    )
  }
  return (
    <div className="mb-2 flex min-h-[26px] items-center gap-2.5 last:mb-0">
      <label className="w-[60px] shrink-0 text-[11px] text-neutral-500">{p.label}</label>
      <div className="min-w-0 flex-1">{widget}</div>
    </div>
  )
}

/**
 * 读数块：实测的数字，固定在四区之上。降级规则要能对着数字验证，不靠感觉，
 * 所以打印实测宽、镜头倍率、各栏的判定态、阈值、触发了哪几级。数值用 <b> 包起来。
 */
export function Readout({ children }: { children: ReactNode }) {
  return (
    <div className="mx-3.5 mb-1.5 grid grid-cols-2 gap-x-3 gap-y-1 rounded-lg bg-neutral-100 px-3 py-2 font-mono text-[10.5px] leading-normal text-neutral-500 [&_b]:font-semibold [&_b]:text-neutral-900">
      {children}
    </div>
  )
}

/**
 * 表示「有规则触发了」的读数。固定色，理由和这里其它东西一样：
 * 在当前皮肤下读不出来的读数，就报告不了这个皮肤。
 */
export function Alert({ children }: { children: ReactNode }) {
  return <span className="col-span-2 font-semibold text-amber-700">{children}</span>
}

/**
 * 样张墙：每个页型 × 每种状态 × 每档宽度，并排铺开。行列由调用方给——它们来自
 * layout.md §4、§8 与 §3.4——`render` 是外壳在那一列宽度下的样子。**不画箭头。**
 * layout.md 没有「用户怎么从一屏到另一屏」的条款，墙上一条连线就是线框在发明结构。
 *
 * 每张样张是外壳按真实宽度布局、再经 CSS zoom 显示，所以样张上的密度就是那一档的密度。
 */
export function Wall({
  rows,
  cols,
  scale = 0.28,
  tileHeight = 640,
  render,
  caption,
}: {
  rows: readonly { id: string; label: string; sub?: string }[]
  cols: readonly { id: string; label: string; sub?: string; width: number }[]
  scale?: number
  /** 样张里外壳的高度，布局像素 */
  tileHeight?: number
  render: (rowId: string, colId: string, width: number) => ReactNode
  caption?: (rowId: string, colId: string) => string
}) {
  const tpl = `120px ${cols.map((c) => Math.round(c.width * scale) + 'px').join(' ')}`
  return (
    <div className="text-neutral-900 group-data-[canvas=dark]:text-neutral-100">
      <div className="mb-2 grid items-end gap-5" style={{ gridTemplateColumns: tpl }}>
        <div />
        {cols.map((c) => (
          <div key={c.id} className="font-mono text-[10px] font-semibold tracking-wider text-neutral-500 uppercase group-data-[canvas=dark]:text-neutral-400">
            {c.label}
            {c.sub && <small className="mt-0.5 block font-normal tracking-normal text-neutral-400 normal-case">{c.sub}</small>}
          </div>
        ))}
      </div>
      {rows.map((r) => (
        <div key={r.id} className="mb-7 grid items-start gap-5" style={{ gridTemplateColumns: tpl }}>
          <div className="sticky left-0 text-xs font-semibold">
            {r.label}
            {r.sub && <small className="block text-[10px] font-normal text-neutral-400">{r.sub}</small>}
          </div>
          {cols.map((c) => (
            <div key={c.id}>
              <div className="overflow-hidden" style={{ width: c.width, height: tileHeight, zoom: scale }}>
                {render(r.id, c.id, c.width)}
              </div>
              {caption && <div className="mt-1.5 font-mono text-[10px] text-neutral-400">{caption(r.id, c.id)}</div>}
            </div>
          ))}
        </div>
      ))}
    </div>
  )
}
