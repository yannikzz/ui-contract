/**
 * 聚焦槽：属性面板。layout.md §5。
 *
 * 关键约束都在类型上：
 * - `page: PageWithInspector` 只接受 'list'，向导页/表单页/概览页想渲染它会直接类型报错（§4.3）
 * - `kind: InspectorKind` 现在只有 'content-item' 一型，新增一型要先过 §5.4 三条判据
 */
import { useState } from 'react'
import { Badge, Btn, Field, Region, StateBlock } from './wire'
import type { InspectorKind, PageWithInspector } from './wire'
import type { InspectorMode } from './structure'
import { STRUCT } from './structure'
import {
  INSPECTOR_ACTIONS,
  INSPECTOR_HISTORY,
  INSPECTOR_RELATIONS,
  INSPECTOR_SUMMARY,
  INSPECTOR_TABS,
} from './fixtures'
import type { Row } from './fixtures'

export type InspectorState = '正常' | '加载' | '整区失败'

export function InspectorSlot({
  page,
  kind,
  row,
  mode,
  state,
  onClose,
}: {
  /** 只有 P1 列表页能渲染面板。这个类型是 layout.md §4.3 的编译期形态 */
  page: PageWithInspector
  kind: InspectorKind
  row: Row
  mode: Exclude<InspectorMode, 'closed'>
  state: InspectorState
  onClose: () => void
}) {
  const [tab, setTab] = useState<string>(INSPECTOR_TABS[0])
  // page / kind 目前只有单一取值；显式引用一次，避免「参数没用到」被下一个 Agent 删掉——
  // 它们的存在本身就是约束（见文件头注释）。
  void page
  void kind

  return (
    <Region
      id="inspector"
      className={
        mode === 'overlay'
          ? /* 覆盖态用一条更重的左边界表示「浮在表格上方」。
               线框不用真实阴影——阴影刻度归 design.md，抄进骨架会变成第二权威源 */
            'absolute top-0 right-0 bottom-0 z-20 flex flex-col border-l-2 border-neutral-500 bg-white'
          : 'flex shrink-0 flex-col border-l border-neutral-300 bg-white'
      }
      label={mode === 'overlay' ? '属性面板（覆盖态）' : undefined}
      style={{ width: STRUCT.inspectorWidth }}
    >
      {/* 自给自足：面板必须自己说清「你在看谁」，不能依赖用户记得点了哪一行 */}
      <Region
        id="inspector.head"
        className="flex items-start gap-2 border-b border-neutral-200 px-4 py-3"
      >
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="font-mono text-[10px] text-neutral-400">内容条目</span>
            <Badge>{row.status}</Badge>
          </div>
          <p className="mt-1 line-clamp-2 text-sm font-semibold text-neutral-800">{row.title}</p>
          <p className="mt-0.5 font-mono text-[10px] text-neutral-400">{row.id}</p>
        </div>
        <Btn weight="ghost" onClick={onClose}>
          关闭
        </Btn>
      </Region>

      <Region id="inspector.tabs" className="flex gap-1 border-b border-neutral-200 px-3">
        {INSPECTOR_TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`-mb-px border-b-2 px-2 py-2 text-xs ${
              tab === t
                ? 'border-neutral-700 font-medium text-neutral-900'
                : 'border-transparent text-neutral-500'
            }`}
          >
            {t}
          </button>
        ))}
      </Region>

      <Region id="inspector.body" className="min-h-0 flex-1 overflow-y-auto px-4 py-2">
        {state === '加载' && (
          /* §8.1：面板内加载，但 inspector.head 的对象标识先出——用户已经知道自己点了谁 */
          <StateBlock kind="加载" text="正在读取这条内容的属性" />
        )}
        {state === '整区失败' && (
          /* §8.1：禁止自动关闭面板——关掉了用户就不知道刚才失败在哪 */
          <StateBlock kind="整区失败" text="属性读取失败：审核服务无响应。面板不会自动关闭。" action="重试" />
        )}
        {state === '正常' && tab === '概要' && (
          <div className="divide-y divide-neutral-100">
            {INSPECTOR_SUMMARY.map((f) => (
              <Field key={f.k} k={f.k} v={f.v} />
            ))}
          </div>
        )}
        {state === '正常' && tab === '关联' && (
          <div className="divide-y divide-neutral-100">
            {INSPECTOR_RELATIONS.map((f) => (
              <Field key={f.k} k={f.k} v={f.v} />
            ))}
            <div className="pt-2 text-[11px] text-neutral-400">
              关联对象只放引用行。点进去是换对象，不是在本面板里嵌第二个对象（§5.5）。
            </div>
          </div>
        )}
        {state === '正常' && tab === '变更历史' && (
          <div className="py-1">
            {/* 过程性事件的落位：一天几十条，进主区会把主线冲散（§1.1 短路 4） */}
            {INSPECTOR_HISTORY.map((h, i) => (
              <div key={i} className="flex gap-2 border-l border-neutral-200 py-1.5 pl-3 text-xs">
                <span className="w-14 shrink-0 text-neutral-400">{h.t}</span>
                <span className="min-w-0 flex-1 text-neutral-600">
                  <span className="text-neutral-800">{h.who}</span> {h.what}
                </span>
              </div>
            ))}
          </div>
        )}
      </Region>

      {/* 单对象操作的唯一宿主。表格里没有操作列，所以这里是唯一能操作这一条的地方 */}
      {state === '正常' && (
        <Region
          id="inspector.foot"
          className="flex flex-wrap gap-1.5 border-t border-neutral-200 bg-neutral-50 px-3 py-2.5"
        >
          {INSPECTOR_ACTIONS.map((a, i) => (
            <Btn key={a} weight={i === 0 ? 'primary' : 'secondary'}>
              {a}
            </Btn>
          ))}
        </Region>
      )}
    </Region>
  )
}
