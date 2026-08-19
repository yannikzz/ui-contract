/**
 * P1 列表页。layout.md §4.1。
 * 部件取用：pagehead / filters /（bulkbar，有选中时）/ table / pager + inspector。
 *
 * 这一页承载了三条最容易被违反的规则，看代码就能验：
 * - 表格里**没有任何按钮**（列型枚举里没有 actions）
 * - 筛选条里只有缩小结果范围的控件，导出/新建都不在这里
 * - 批量操作条在没有选中时**不渲染**，不是隐藏
 */
import { Badge, Btn, Card, Pill, AnnotatedRegion, StateBlock } from '../wire'
import { FILTERS, ROWS, TABLE_COLUMNS } from '../fixtures'
import { STRUCT } from '../structure'

export type DataState = '正常' | '空' | '筛选后空' | '加载' | '局部失败' | '整区失败'

/** select 与 id 列永不滚出（layout.md §4.6）：用 sticky 实现，不是靠祈祷宽度够 */
const STICKY_LEFT = [0, TABLE_COLUMNS[0].width]

export function ListPage({
  state,
  selected,
  onToggle,
  onOpenRow,
  activeId,
  onClearSelection,
}: {
  state: DataState
  selected: string[]
  onToggle: (id: string) => void
  onOpenRow: (id: string) => void
  activeId: string | null
  onClearSelection: () => void
}) {
  const rows = state === '空' || state === '筛选后空' ? [] : ROWS

  return (
    <>
      <AnnotatedRegion
        id="main.pagehead"
        className="flex items-start justify-between gap-4 border-b border-neutral-200 bg-white px-5 py-3"
      >
        <div className="min-w-0">
          <h1 className="truncate text-base font-semibold text-neutral-800">全部内容</h1>
          <p className="mt-0.5 truncate text-xs text-neutral-500">
            共 {rows.length ? 1284 : 0} 条 · 当前筛选命中 {rows.length ? 218 : 0} 条
          </p>
        </div>
        {/* 页级操作在这里。禁止下沉到筛选条，也禁止在表格行尾出现 */}
        <div className="flex gap-1.5">
          <Btn weight="secondary">导出当前筛选</Btn>
          <Btn weight="primary">新建内容</Btn>
        </div>
      </AnnotatedRegion>

      {/* 只放「缩小结果范围」的控件。刻意放满 6 个，看面板打开后（宽度 -360）会不会换行 */}
      <AnnotatedRegion
        id="main.filters"
        className="flex flex-wrap items-center gap-1.5 border-b border-neutral-200 bg-white px-5 py-2.5"
      >
        {FILTERS.map((f) => (
          <Pill key={f}>{f}</Pill>
        ))}
        <button className="ml-1 text-[11px] text-neutral-500 underline">清除全部条件</button>
      </AnnotatedRegion>

      {/* 没有选中行时本区不渲染（不是 hidden）。这是 §2.2 白名单里写死的 */}
      {selected.length > 0 && (
        <AnnotatedRegion
          id="main.bulkbar"
          className="flex items-center gap-2 border-b border-neutral-200 bg-neutral-100 px-5 py-2"
        >
          <span className="text-xs font-medium text-neutral-700">已选 {selected.length} 条</span>
          <Btn weight="secondary">批量通过</Btn>
          <Btn weight="secondary">批量改栏目</Btn>
          <Btn weight="secondary">批量加标签</Btn>
          <Btn weight="outline">移入回收站</Btn>
          <Btn weight="ghost" onClick={onClearSelection}>
            取消选择
          </Btn>
        </AnnotatedRegion>
      )}

      <AnnotatedRegion id="main.table" className="min-h-0 flex-1 overflow-auto bg-white">
        {state === '加载' && (
          /* §8.1：表头保留可见，只有行区在加载。禁止整区骨架屏 */
          <>
            <TableHead />
            <StateBlock kind="加载" text="正在读取内容列表（表头先渲染，减少布局跳动）" />
          </>
        )}
        {state === '整区失败' && (
          <>
            <TableHead />
            <StateBlock
              kind="整区失败"
              text="内容列表读取失败：网关超时。筛选条仍然可用，改条件会重新请求。"
              action="重试"
            />
          </>
        )}
        {state === '空' && (
          <StateBlock kind="空" text="这个栏目下还没有任何内容。导入一批，或者新建第一条。" action="批量导入" />
        )}
        {state === '筛选后空' && (
          /* 「一条都没有」和「筛选后没有」是两种空态，动作不同（§8.1） */
          <StateBlock kind="空" text="当前 6 个筛选条件下没有命中内容。放宽条件再看看？" action="清除全部条件" />
        )}
        {(state === '正常' || state === '局部失败') && (
          <table className="w-full border-collapse text-left" style={{ minWidth: 846 }}>
            <thead className="sticky top-0 z-10">
              <tr className="bg-neutral-100">
                {TABLE_COLUMNS.map((c, i) => (
                  <th
                    key={c.label + i}
                    style={{
                      width: c.width,
                      minWidth: c.width,
                      left: i < 2 ? STICKY_LEFT[i] : undefined,
                    }}
                    className={`border-b border-neutral-300 px-3 py-2 text-[11px] font-normal text-neutral-500 ${
                      i < 2 ? 'sticky z-10 bg-neutral-100' : ''
                    }`}
                  >
                    {c.kind === 'select' ? <input type="checkbox" /> : c.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((r, ri) => {
                const on = selected.includes(r.id)
                const active = activeId === r.id
                const broken = state === '局部失败' && ri === 3
                return (
                  <tr
                    key={r.id}
                    onClick={() => onOpenRow(r.id)}
                    className={`cursor-pointer border-b border-neutral-100 ${
                      active ? 'bg-neutral-200/70' : 'hover:bg-neutral-50'
                    }`}
                  >
                    <td
                      style={{ left: STICKY_LEFT[0] }}
                      className={`sticky z-[1] px-3 py-2 ${active ? 'bg-neutral-200/70' : 'bg-white'}`}
                    >
                      <input
                        type="checkbox"
                        checked={on}
                        onClick={(e) => e.stopPropagation()}
                        onChange={() => onToggle(r.id)}
                      />
                    </td>
                    {/* id 列：点击即在面板打开该对象。这是表格里唯一的入口 */}
                    <td
                      style={{ left: STICKY_LEFT[1], width: TABLE_COLUMNS[1].width }}
                      className={`sticky z-[1] px-3 py-2 ${active ? 'bg-neutral-200/70' : 'bg-white'}`}
                    >
                      <div className="truncate text-xs font-medium text-neutral-800">{r.title}</div>
                      {broken && (
                        /* §8.1 局部失败：出错的那一行原地标出，其它行照常可用 */
                        <div className="mt-0.5 text-[10px] text-neutral-500">
                          这一行的审核状态读取失败 · 重试
                        </div>
                      )}
                    </td>
                    <td className="px-3 py-2">
                      <Badge>{broken ? '未知' : r.status}</Badge>
                    </td>
                    <td className="px-3 py-2 text-xs text-neutral-600">{r.channel}</td>
                    <td className="px-3 py-2 text-xs text-neutral-600">{r.author}</td>
                    <td className="px-3 py-2 text-xs whitespace-nowrap text-neutral-400">{r.updated}</td>
                    <td className="px-3 py-2 text-xs text-neutral-400">{r.operator}</td>
                    {/* 这里没有第 8 列。TableColumnKind 里没有 'actions'，写不出来 —— 刻意的 */}
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </AnnotatedRegion>

      <AnnotatedRegion
        id="main.pager"
        className="flex items-center justify-between border-t border-neutral-200 bg-white px-5 py-2"
      >
        <span className="text-[11px] text-neutral-500">
          第 1–{Math.min(STRUCT.tablePageSize, rows.length)} 条 / 共 {rows.length ? 218 : 0} 条
        </span>
        <div className="flex items-center gap-1.5">
          <span className="text-[11px] text-neutral-500">每页 {STRUCT.tablePageSize} 条</span>
          <Btn weight="outline" disabled>
            上一页
          </Btn>
          <Card className="px-2 py-1 text-xs">1</Card>
          <Btn weight="outline">下一页</Btn>
        </div>
      </AnnotatedRegion>
    </>
  )
}

function TableHead() {
  return (
    <div className="flex bg-neutral-100 text-[11px] text-neutral-500">
      {TABLE_COLUMNS.map((c, i) => (
        <div
          key={c.label + i}
          style={{ width: c.width, minWidth: c.width }}
          className="border-b border-neutral-300 px-3 py-2"
        >
          {c.kind === 'select' ? '' : c.label}
        </div>
      ))}
    </div>
  )
}
