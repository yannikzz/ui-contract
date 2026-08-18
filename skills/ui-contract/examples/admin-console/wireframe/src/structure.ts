/**
 * 结构参数的唯一来源 + 降级判定纯函数。
 *
 * 这些常量对应 layout.md §3.2。**改这些常量等于改规范**，必须同步文档。
 * 这里不出现任何视觉值（颜色/字号/圆角/间距）——那些在 design.md。
 */

export const STRUCT = {
  /** 导航展开宽。layout.md §3.2 */
  navWidth: 220,
  /** 导航收起后的图标条宽。**不允许收成 0**：会把队列角标信号彻底埋掉。layout.md §3.4 */
  navRailWidth: 56,
  /** 属性面板宽，固定不可拖拽。layout.md §3.2 / §10-7 */
  inspectorWidth: 360,
  /** 主区最小可用宽，降级触发阈值。layout.md §3.4 */
  mainMinWidth: 640,
  /** 「内容管理」段条数上限，作用是逼人做合并决策。layout.md §7.3 */
  navGroupMaxItems: 7,
  /** 属性面板类型枚举上限。layout.md §5.1 */
  inspectorKindMax: 5,
  /** 表格默认每页条数。用分页不用无限滚动：后台要能说「第 3 页第 5 行」 */
  tablePageSize: 20,
  /** P4 概览页网格列数。卡片只能占 3/4/6/12 格。layout.md §4.4 */
  gridColumns: 12,
} as const

/**
 * 三态偏好。不用布尔——布尔表达不了「跟随自动降级」。
 * `open` / `closed` 是用户的明确操作，**双向覆盖自动降级**（layout.md §3.4）：
 * 手动收起后窗口变宽也保持收起，手动展开后窄屏也不自动收。
 */
export type Pref = 'auto' | 'open' | 'closed'

export type NavMode = 'full' | 'rail'
/** 面板三态：inline = 在文档流内挤窄主区；overlay = 覆盖在主区上（窄屏降级后） */
export type InspectorMode = 'inline' | 'overlay' | 'closed'

export type ShellLayout = {
  nav: NavMode
  navWidth: number
  inspector: InspectorMode
  /** 主区实际宽度（不小于 mainMinWidth；触底后主区溢出，靠横向滚动） */
  mainWidth: number
  /** 触底：可用宽已低于 mainMinWidth，不再继续降级 */
  atFloor: boolean
  /** 本次实际触发的降级级次，用于在演示条上显示，让规则能被对着数字验证 */
  triggered: string[]
}

/**
 * 降级判定。**纯函数**：输入宽度 + 用户偏好 → 输出各栏状态与主区实宽。
 *
 * 纯函数才能一眼看懂级联顺序，也才能被规范审查。
 * 触发条件用「主区可用宽度」而不是视口断点：断点不知道其它栏的状态，
 * 会在空间其实够的时候误收（layout.md §10-8）。
 *
 * 级联顺序见 layout.md §3.4：
 *   1  可用宽 < 640 → 导航 220 → 56 图标条（角标保留）
 *   2  仍 < 640    → 面板由挤窄改为覆盖，主区恢复全宽
 *   3  仍 < 640    → 触底，不再降级，表格横向滚动
 */
export function resolveShell(input: {
  /** app-shell 的实测宽度（ResizeObserver 得来，不是视口宽） */
  shellWidth: number
  navPref: Pref
  /** 用户是否选中了某一行（面板内容跟用户明确点击，layout.md §5.5） */
  inspectorRequested: boolean
}): ShellLayout {
  const { shellWidth, navPref, inspectorRequested } = input
  const triggered: string[] = []

  // 首帧 ResizeObserver 还没回调，宽度是 0。此时按「不降级」返回，
  // 否则界面会先闪一次图标条 —— 这是实测方案（而非断点方案）必须处理的边界。
  if (shellWidth <= 0) {
    return {
      nav: navPref === 'closed' ? 'rail' : 'full',
      navWidth: navPref === 'closed' ? STRUCT.navRailWidth : STRUCT.navWidth,
      inspector: inspectorRequested ? 'inline' : 'closed',
      mainWidth: STRUCT.mainMinWidth,
      atFloor: false,
      triggered: ['（首帧未测量）'],
    }
  }

  let nav: NavMode = navPref === 'closed' ? 'rail' : 'full'
  let inspector: InspectorMode = inspectorRequested ? 'inline' : 'closed'

  const avail = () => shellWidth - (nav === 'full' ? STRUCT.navWidth : STRUCT.navRailWidth) - (inspector === 'inline' ? STRUCT.inspectorWidth : 0)

  // 级 1：先牺牲导航——它有图标条兜底，面板没有等价的降级形态
  if (avail() < STRUCT.mainMinWidth && nav === 'full' && navPref === 'auto') {
    nav = 'rail'
    triggered.push('级1 导航 → 图标条')
  }

  // 级 2：再牺牲面板的「不遮挡」性质，但保留面板可用
  if (avail() < STRUCT.mainMinWidth && inspector === 'inline') {
    inspector = 'overlay'
    triggered.push('级2 属性面板 → 覆盖')
  }

  // 级 3：触底。不再降级，主区保持最小宽，表格横向滚动（列优先级见 layout.md §4.6）
  const atFloor = avail() < STRUCT.mainMinWidth
  if (atFloor) triggered.push('级3 触底（表格横向滚动）')

  return {
    nav,
    navWidth: nav === 'full' ? STRUCT.navWidth : STRUCT.navRailWidth,
    inspector,
    mainWidth: Math.max(avail(), STRUCT.mainMinWidth),
    atFloor,
    triggered,
  }
}
