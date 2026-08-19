/**
 * P4 概览页（工作台）。layout.md §4.1 / §4.4。
 *
 * ⚠️ 这一页**没有设计稿**，结构是从「工作台必然需要一屏概览」推断的，
 * 见 DECISIONS-TO-CONFIRM.md E2。12 列网格 + 卡片只能占 3/4/6/12 格是为了
 * 让 Agent 加新卡时有据可依，不是我知道你们工作台长什么样。
 *
 * 硬规则：**概览页不放筛选条**（需要筛选说明用户要的是 P1 列表页），
 * 不放完整表格（只放短列表卡 + 「查看全部」）。
 */
import { Btn, Card, AnnotatedRegion, StateBlock } from '../wire'
import { OVERVIEW_CARDS } from '../fixtures'
import { STRUCT } from '../structure'

export function OverviewPage({ failed }: { failed: boolean }) {
  return (
    <>
      <AnnotatedRegion
        id="main.pagehead"
        className="flex items-start justify-between gap-4 border-b border-neutral-200 bg-white px-5 py-3"
      >
        <div className="min-w-0">
          <h1 className="truncate text-base font-semibold text-neutral-800">概览</h1>
          <p className="mt-0.5 truncate text-xs text-neutral-500">
            截至 2026-08-17 09:45 · 数据每 5 分钟更新
          </p>
        </div>
      </AnnotatedRegion>

      <AnnotatedRegion id="main.grid" className="min-h-0 flex-1 overflow-y-auto px-5 py-4">
        <div
          className="grid gap-3"
          style={{ gridTemplateColumns: `repeat(${STRUCT.gridColumns}, minmax(0, 1fr))` }}
        >
          {OVERVIEW_CARDS.map((c, i) => (
            /* 占格只能是 3/4/6/12（layout.md §4.4）。类型上 span 已经限死这四个值 */
            <div key={c.title} style={{ gridColumn: `span ${c.span}` }}>
            <Card className="h-full p-3">
              <div className="flex items-start justify-between gap-2">
                <h2 className="truncate text-xs font-medium text-neutral-700">{c.title}</h2>
                {c.kind === 'list' && <Btn weight="ghost">查看全部</Btn>}
              </div>
              {/* §8.1：每张卡各自空/加载/失败，一张卡出问题不影响别的卡 */}
              {failed && i === 3 ? (
                <StateBlock kind="局部失败" text="这张卡的数据源不可用" action="重试" />
              ) : c.kind === 'metric' ? (
                <>
                  <p className="mt-1 text-2xl font-semibold text-neutral-800">{c.body[0]}</p>
                  <p className="text-[11px] text-neutral-400">{c.body[1]}</p>
                </>
              ) : c.kind === 'chart' ? (
                <div className="mt-2 flex h-28 items-end gap-1">
                  {[38, 52, 30, 61, 44, 70, 55, 48, 66, 33, 58, 72, 41, 63].map((h, j) => (
                    <span key={j} className="flex-1 bg-neutral-200" style={{ height: `${h}%` }} />
                  ))}
                </div>
              ) : (
                <ul className="mt-1.5 divide-y divide-neutral-100">
                  {c.body.map((b) => (
                    <li key={b} className="truncate py-1.5 text-xs text-neutral-600">
                      {b}
                    </li>
                  ))}
                </ul>
              )}
            </Card>
            </div>
          ))}
        </div>
        <p className="mt-3 text-[11px] text-neutral-400">
          新指标卡放哪、占几格归 layout.md §4.4；卡片里图表长什么样归 design.md。
        </p>
      </AnnotatedRegion>
    </>
  )
}
