/**
 * 资产层——区域白名单的类型形态、区域元信息、结构容器。
 *
 * 这个文件属于**生产代码**：跟随项目技术栈，长期维护，业务代码从这里 import。
 *
 * `RegionId` 就是 layout.md §2 白名单的代码形态：
 * 想写一个不在表里的 data-region，TypeScript 会直接报错。
 * 新增区域的顺序：改 layout.md §2 → 改 RegionId 与 REGION_META → 写代码。顺序不能反。
 *
 * 这里**没有品牌视觉，也没有标注层**——品牌值住 token 文件，标注层归线框。
 * 线框是本文件的一次性消费者，反过来不成立。
 */
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


/**
 * 状态标签的**语义类**。layout.md §6.4。
 *
 * 这是一个封闭集，而且它住结构层不住视觉层——切线是「换品牌视觉时会不会变」，
 * 而「待审核需要有人动手」换一套皮肤不会变。**哪一类用什么颜色**才归 design.md。
 *
 * 线框只认这五个类，不认颜色：它拿到 kind，颜色由 token 走 var() 进来。
 * 少了这一层的话，线框要么全灰（看不出配色在做什么），要么自己编一张
 * 「待审核 = 黄」的表——那就是第二个权威源。
 *
 * 加第六类要先过 layout.md §9 的变更流程。五类覆盖不了的状态，通常是
 * 状态本身没想清楚，不是少了一类。
 */
export type StatusKind =
  /** 还没进流程，或已经离开流程。不给语义色，用文字层级表达 */
  | 'neutral'
  /** 系统在跑，用户等着就行。不需要动手 */
  | 'progress'
  /** 需要有人动手，但没有东西被挡住 */
  | 'attention'
  /** 被挡住了，必须先处理才能往下走 */
  | 'blocked'
  /** 成功终态 */
  | 'done'

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


// ── 结构容器 ─────────────────────────────────────────────────
/**
 * 产品里每一个结构容器都经由它渲染，id 取自白名单。
 * 运行期标记（`data-region`）不是可选的：只有类型而没有运行期标记，
 * grep 对账就做不了，标注层也没有挂载点。
 */
export function Region({
  id,
  children,
  className = '',
  style,
  elRef,
}: {
  id: RegionId
  children?: ReactNode
  className?: string
  style?: CSSProperties
  elRef?: RefObject<HTMLDivElement | null>
}) {
  return (
    <div ref={elRef} data-region={id} style={style} className={className}>
      {children}
    </div>
  )
}
