/**
 * P3 设置表单页。layout.md §4.1。
 *
 * 与 P1 结构相似、语义不同（§4.1 的对照表）：这里是**固定配置**，不增不减、不会归零，
 * 有底部保存语义。**没有空态**——配置项固定，空了说明出错，按整区失败处理。
 * 无属性面板（矩阵 §4.2）。
 */
import { Btn, Card, AnnotatedRegion, StateBlock } from '../wire'
import { FORM_GROUPS } from '../fixtures'

export function FormPage({ failed }: { failed: boolean }) {
  return (
    <>
      <AnnotatedRegion
        id="main.pagehead"
        className="flex items-start justify-between gap-4 border-b border-neutral-200 bg-white px-5 py-3"
      >
        <div className="min-w-0">
          <h1 className="truncate text-base font-semibold text-neutral-800">站点参数</h1>
          <p className="mt-0.5 truncate text-xs text-neutral-500">改完保存，不影响已发布内容</p>
        </div>
      </AnnotatedRegion>

      <AnnotatedRegion id="main.form" className="min-h-0 flex-1 overflow-y-auto px-5 py-4">
        {failed ? (
          /* §8.1：整区失败时**禁止把已填内容清掉** */
          <StateBlock
            kind="整区失败"
            text="配置读取失败：配置服务无响应。已修改但未保存的内容仍保留在本地。"
            action="重试"
          />
        ) : (
          <div className="max-w-[720px] space-y-5">
            {FORM_GROUPS.map((g) => (
              <div key={g.group}>
                <h2 className="mb-1.5 text-sm font-medium text-neutral-800">{g.group}</h2>
                <Card className="divide-y divide-neutral-100">
                  {g.fields.map((f) => (
                    <div key={f.k} className="flex items-start gap-3 px-3 py-2.5">
                      <span className="w-32 shrink-0 pt-1 text-xs text-neutral-500">{f.k}</span>
                      <div className="min-w-0 flex-1">
                        <div className="rounded border border-neutral-300 px-2 py-1 text-xs text-neutral-800">
                          {f.v}
                        </div>
                        {f.note && (
                          <p className="mt-1 text-[11px] text-neutral-400">{f.note}</p>
                        )}
                      </div>
                    </div>
                  ))}
                </Card>
              </div>
            ))}
            {/* 保存在表单内，不新增一个跨栏的底部操作条（那会变成外壳部件，改变矩阵） */}
            <div className="flex gap-2 border-t border-neutral-200 pt-3">
              <Btn weight="primary">保存</Btn>
              <Btn weight="secondary">重置为默认值</Btn>
              <span className="self-center text-[11px] text-neutral-400">
                有 2 项已修改未保存
              </span>
            </div>
          </div>
        )}
      </AnnotatedRegion>
    </>
  )
}
