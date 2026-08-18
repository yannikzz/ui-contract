/**
 * 假数据。**这不是规格。**
 *
 * 字段名、状态名、条目名全部是为了把密度拉到真实上限而编的，
 * 不代表业务上真的有这些字段。业务字段见需求文档（layout.md 附录 A）。
 *
 * 密度是刻意拉满的：长到会被截断的标题、5 种状态、20 行满页、
 * 筛选条上 6 个控件、面板里字段名长短不一。
 * 空界面会让任何布局看起来都不错，密数据才暴露列宽放不下、长文案撑破。
 */
import type { TableColumn } from './wire'

// ── 导航 ──────────────────────────────────────────────────────
/** 段的性质。layout.md §7.2 三条性质测出来的：queue 带角标，library 禁止带角标 */
export type NavItemKind = 'queue' | 'library' | 'overview' | 'config'

export type NavItem = { label: string; kind: NavItemKind; count?: number }

export const NAV_GROUPS: { group: string; items: NavItem[] }[] = [
  {
    group: '工作台',
    items: [{ label: '概览', kind: 'overview' }],
  },
  {
    // 上限 7 条（STRUCT.navGroupMaxItems）。现在 6 条，第 8 条时必须先做合并决策
    group: '内容管理',
    items: [
      { label: '全部内容', kind: 'library' },
      { label: '待审核', kind: 'queue', count: 12 },
      { label: '被驳回待修改', kind: 'queue', count: 3 },
      { label: '专题与合集', kind: 'library' },
      { label: '标签词库', kind: 'library' },
      { label: '批量导入', kind: 'library' },
    ],
  },
]

export const NAV_SETTINGS: { group: string; items: NavItem[] }[] = [
  {
    group: '系统',
    items: [
      { label: '成员与角色', kind: 'config' },
      { label: '站点参数', kind: 'config' },
      { label: '审核流配置', kind: 'config' },
      // 设计稿里「回收站」出现了两次 → 判定为复制粘贴，只保留这一处。
      // 页内用 tab 分对象类型，不为每类对象各加一条导航项（layout.md §7.4 / 附录 B-1）
      { label: '回收站', kind: 'config' },
    ],
  },
]

// ── P1 列表页 ──────────────────────────────────────────────────
/** 列优先级 = 数组顺序。宽度不足时从最右开始横向滚出；select 与 id 永不滚出（layout.md §4.6） */
export const TABLE_COLUMNS: TableColumn[] = [
  { kind: 'select', label: '', width: 36 },
  { kind: 'id', label: '标题', width: 300 },
  { kind: 'badge', label: '状态', width: 90 },
  { kind: 'text', label: '栏目', width: 110 },
  { kind: 'text', label: '作者', width: 90 },
  { kind: 'meta', label: '更新时间', width: 130 },
  { kind: 'meta', label: '操作人', width: 90 },
]

export type Row = {
  id: string
  title: string
  status: string
  channel: string
  author: string
  updated: string
  operator: string
}

export const ROWS: Row[] = [
  { id: 'C-20418', title: '2026 年第三季度城市轨道交通运营数据月报（含 12 城对比与同比口径说明）', status: '待审核', channel: '数据月报', author: '周霖', updated: '2026-08-17 09:42', operator: '周霖' },
  { id: 'C-20417', title: '关于调整会员积分抵扣规则的公告', status: '已发布', channel: '公告', author: '林晓一', updated: '2026-08-17 08:15', operator: '审核机器人' },
  { id: 'C-20416', title: '新版控制台上手指引', status: '草稿', channel: '帮助中心', author: '陈默', updated: '2026-08-16 22:03', operator: '陈默' },
  { id: 'C-20415', title: '供应商准入材料清单（2026 修订版，替换 2024 版全部附件）', status: '被驳回', channel: '制度文件', author: '吴桐', updated: '2026-08-16 19:28', operator: '张一鸣' },
  { id: 'C-20414', title: '八月运营活动复盘', status: '待审核', channel: '运营', author: '赵星', updated: '2026-08-16 17:50', operator: '赵星' },
  { id: 'C-20413', title: '首页轮播图 A/B 实验结论与后续投放建议', status: '已发布', channel: '运营', author: '赵星', updated: '2026-08-16 16:11', operator: '林晓一' },
  { id: 'C-20412', title: '客服话术库更新：退款场景第 3 版', status: '处理中', channel: '客服', author: '钱多', updated: '2026-08-16 15:04', operator: '同步任务' },
  { id: 'C-20411', title: '数据合规自查报告（内部）', status: '已归档', channel: '制度文件', author: '吴桐', updated: '2026-08-16 11:37', operator: '吴桐' },
  { id: 'C-20410', title: '关于国庆假期值班安排的通知', status: '草稿', channel: '公告', author: '林晓一', updated: '2026-08-15 20:22', operator: '林晓一' },
  { id: 'C-20409', title: '移动端 5.2 版本发版说明', status: '已发布', channel: '产品动态', author: '陈默', updated: '2026-08-15 18:45', operator: '陈默' },
  { id: 'C-20408', title: '专题页「智慧城市」内容排期与稿件缺口盘点', status: '待审核', channel: '专题', author: '周霖', updated: '2026-08-15 14:09', operator: '周霖' },
  { id: 'C-20407', title: '广告位报价单', status: '被驳回', channel: '商务', author: '钱多', updated: '2026-08-15 10:56', operator: '张一鸣' },
  { id: 'C-20406', title: '关键词库季度清洗结果', status: '处理中', channel: '标签', author: '同步任务', updated: '2026-08-15 09:30', operator: '同步任务' },
  { id: 'C-20405', title: '用户调研访谈记录汇总（14 位受访者，含逐字稿链接）', status: '已发布', channel: '研究', author: '赵星', updated: '2026-08-14 21:18', operator: '赵星' },
  { id: 'C-20404', title: '内容安全审核标准 v7', status: '已发布', channel: '制度文件', author: '张一鸣', updated: '2026-08-14 17:02', operator: '张一鸣' },
  { id: 'C-20403', title: '合作媒体转载授权说明', status: '已归档', channel: '商务', author: '钱多', updated: '2026-08-14 15:40', operator: '钱多' },
  { id: 'C-20402', title: '七月站内搜索无结果词 Top 100 分析', status: '待审核', channel: '研究', author: '周霖', updated: '2026-08-14 12:25', operator: '周霖' },
  { id: 'C-20401', title: '帮助中心图片资源批量替换说明', status: '草稿', channel: '帮助中心', author: '陈默', updated: '2026-08-13 23:11', operator: '陈默' },
  { id: 'C-20400', title: '会员权益页文案微调', status: '已发布', channel: '运营', author: '林晓一', updated: '2026-08-13 19:07', operator: '林晓一' },
  { id: 'C-20399', title: '旧版帮助中心下线检查清单（含 42 个待处理跳转）', status: '处理中', channel: '帮助中心', author: '同步任务', updated: '2026-08-13 16:33', operator: '同步任务' },
]

/** 筛选条上的控件。刻意放满 6 个，看它在面板打开后（宽度 -360）会不会换行 */
export const FILTERS = ['搜索标题 / 正文', '状态：全部', '栏目：全部', '作者：全部', '更新时间：近 30 天', '标签：全部']

// ── 属性面板（content-item 这一型）─────────────────────────────
export const INSPECTOR_TABS = ['概要', '关联', '变更历史'] as const

export const INSPECTOR_SUMMARY: { k: string; v: string }[] = [
  { k: '内容 ID', v: 'C-20418' },
  { k: '状态', v: '待审核（已提交 2 小时 18 分）' },
  { k: '栏目', v: '数据月报' },
  { k: '作者', v: '周霖（内容组）' },
  { k: '创建时间', v: '2026-08-16 14:02' },
  { k: '最后更新', v: '2026-08-17 09:42 by 周霖' },
  { k: '字数', v: '4,182' },
  { k: '附件', v: '3 个（xlsx 2 / pdf 1）' },
  { k: '摘要', v: '汇总 12 座城市 7 月轨道交通客运量、准点率与投诉量，并说明同比口径与两处数据缺口的处理方式。' },
]

export const INSPECTOR_RELATIONS: { k: string; v: string }[] = [
  { k: '所属专题', v: '智慧城市（2026 秋季）' },
  { k: '引用内容', v: 'C-20388 六月运营数据月报' },
  { k: '标签', v: '轨道交通 / 月报 / 公开数据' },
  { k: '审核流', v: '数据类内容三级审核' },
]

export const INSPECTOR_HISTORY: { t: string; who: string; what: string }[] = [
  { t: '09:42', who: '周霖', what: '补充第 4 节两处数据缺口的说明，替换附件《7月客运量.xlsx》' },
  { t: '09:31', who: '周霖', what: '修改标题' },
  { t: '09:30', who: '系统', what: '自动保存草稿' },
  { t: '08:58', who: '周霖', what: '提交审核' },
  { t: '08:57', who: '校验任务', what: '格式预检通过（12 项检查，2 项警告）' },
  { t: '昨天 21:14', who: '张一鸣', what: '驳回：口径说明缺失' },
  { t: '昨天 20:40', who: '周霖', what: '提交审核' },
  { t: '昨天 16:02', who: '周霖', what: '创建内容' },
]

/** 单对象操作。全部在 inspector.foot——表格里没有操作列（layout.md §6.3） */
export const INSPECTOR_ACTIONS = ['通过', '驳回', '编辑', '预览', '移入回收站']

// ── P2 向导页（批量导入）───────────────────────────────────────
export const WIZARD_STEPS = ['上传文件', '字段映射与预检', '确认导入'] as const

export const IMPORT_MAPPING: { col: string; field: string; note: string }[] = [
  { col: 'A 标题', field: '标题', note: '必填，已匹配' },
  { col: 'B 正文', field: '正文（Markdown）', note: '已匹配' },
  { col: 'C 栏目名', field: '栏目', note: '3 个栏目名在系统中不存在，将自动创建' },
  { col: 'D 作者邮箱', field: '作者', note: '2 行的邮箱不属于任何成员，将留空并标记' },
  { col: 'E 发布时间', field: '计划发布时间', note: '格式 2026/8/1 已识别' },
  { col: 'F 标签', field: '标签', note: '以「;」分隔，共 41 个标签，其中 7 个为新标签' },
  { col: 'G 备注', field: '（未映射）', note: '本列将被忽略' },
]

export const IMPORT_PREFLIGHT = {
  total: 218,
  ok: 203,
  warn: 13,
  error: 2,
  errors: [
    '第 47 行：标题为空，无法导入',
    '第 152 行：正文超过单篇上限（80,000 字符），无法导入',
  ],
  warns: [
    '第 12、19、23…（共 9 行）：作者邮箱未匹配到成员，导入后作者留空',
    '第 88、90…（共 4 行）：计划发布时间早于当前时间，将立即进入待审核',
  ],
}

// ── P3 设置表单页 ─────────────────────────────────────────────
export const FORM_GROUPS: { group: string; fields: { k: string; v: string; note?: string }[] }[] = [
  {
    group: '基本信息',
    fields: [
      { k: '站点名称', v: '城市数据发布平台' },
      { k: '站点域名', v: 'data.example.gov.cn' },
      { k: '默认语言', v: '简体中文' },
    ],
  },
  {
    group: '内容默认值',
    fields: [
      { k: '默认栏目', v: '未分类', note: '新建内容未指定栏目时使用' },
      { k: '默认审核流', v: '两级审核' },
      { k: '正文最大长度', v: '80000', note: '超过此长度的导入行会被拒绝' },
    ],
  },
  {
    group: '回收站',
    fields: [
      { k: '保留天数', v: '30', note: '超期自动清除，不可恢复' },
      { k: '谁可以彻底删除', v: '仅超级管理员' },
    ],
  },
]

// ── P4 概览页 ─────────────────────────────────────────────────
/** span 只能是 3 / 4 / 6 / 12（layout.md §4.4） */
export const OVERVIEW_CARDS: { title: string; span: 3 | 4 | 6 | 12; kind: 'metric' | 'chart' | 'list'; body: string[] }[] = [
  { title: '待审核', span: 3, kind: 'metric', body: ['12', '较昨日 +4'] },
  { title: '今日已发布', span: 3, kind: 'metric', body: ['27', '较昨日 -3'] },
  { title: '被驳回待修改', span: 3, kind: 'metric', body: ['3', '持平'] },
  { title: '导入任务失败', span: 3, kind: 'metric', body: ['2', '需处理'] },
  { title: '近 14 天发布量', span: 6, kind: 'chart', body: ['（图表占位）'] },
  { title: '审核耗时分布', span: 6, kind: 'chart', body: ['（图表占位）'] },
  {
    title: '等我处理的',
    span: 6,
    kind: 'list',
    body: [
      '2026 年第三季度城市轨道交通运营数据月报…  待审核 2h18m',
      '专题页「智慧城市」内容排期与稿件缺口盘点  待审核 19h',
      '八月运营活动复盘  待审核 1d',
      '七月站内搜索无结果词 Top 100 分析  待审核 3d',
    ],
  },
  {
    title: '最近的批量任务',
    span: 6,
    kind: 'list',
    body: [
      '内容导入 218 行  处理中 · 93%',
      '关键词库清洗  已完成 · 41 个标签合并',
      '旧版帮助中心跳转检查  处理中 · 42 个待处理',
      '图片资源批量替换  已完成',
    ],
  },
]
