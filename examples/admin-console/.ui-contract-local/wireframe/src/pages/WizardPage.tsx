/**
 * P2 向导页（批量导入）。layout.md §4.1 / §4.3。
 *
 * **这一页没有属性面板，而且是硬禁止的。** 想加也加不上：
 * `InspectorSlot` 的 page 参数类型是 `PageWithInspector`（只含 'list'），
 * 在这个文件里传 'wizard' 会直接类型报错。
 *
 * 需要在导入过程中查已有内容 → 开 overlay（临时）或另开一页（长期）。
 */
import { Badge, Btn, Card, StateBlock } from '../wire'
import { AnnotatedRegion } from '../inspect'
import { IMPORT_MAPPING, IMPORT_PREFLIGHT, WIZARD_STEPS } from '../fixtures'

export function WizardPage({
  step,
  setStep,
  failed,
}: {
  step: number
  setStep: (n: number) => void
  /** 演示 §8.1「当前步整区失败」 */
  failed: boolean
}) {
  const last = WIZARD_STEPS.length - 1
  const blocked = step === 1 && IMPORT_PREFLIGHT.error > 0

  return (
    <>
      <AnnotatedRegion
        id="main.pagehead"
        className="flex items-start justify-between gap-4 border-b border-[var(--wire-line)] bg-[var(--wire-surface)] px-5 py-3"
      >
        <div className="min-w-0">
          <h1 className="truncate text-base font-semibold text-[var(--wire-fg)]">批量导入</h1>
          <p className="mt-0.5 truncate text-xs text-[var(--wire-muted-fg)]">
            一次性流程，中途离开不保留进度
          </p>
        </div>
        <Btn weight="ghost">取消并退出</Btn>
      </AnnotatedRegion>

      {/* 进度指示器，不是导航：未完成的步骤不可点 */}
      <AnnotatedRegion
        id="main.steps"
        className="flex items-center gap-2 border-b border-[var(--wire-line)] bg-[var(--wire-surface)] px-5 py-3"
      >
        {WIZARD_STEPS.map((s, i) => (
          <div key={s} className="flex min-w-0 items-center gap-2">
            <span
              className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full border text-[10px] ${
                i < step
                  ? 'border-[var(--wire-line-contrast)] bg-[var(--wire-strong-2)] text-[var(--wire-strong-fg)]'
                  : i === step
                    ? 'border-[var(--wire-line-contrast)] text-[var(--wire-fg)]'
                    : 'border-[var(--wire-line-strong)] text-[var(--wire-faint-fg)]'
              }`}
            >
              {i < step ? '✓' : i + 1}
            </span>
            <span
              className={`truncate text-xs ${i === step ? 'font-medium text-[var(--wire-fg)]' : 'text-[var(--wire-muted-fg)]'}`}
            >
              {s}
            </span>
            {i < last && <span className="w-8 shrink-0 border-t border-[var(--wire-line-strong)]" />}
          </div>
        ))}
      </AnnotatedRegion>

      <AnnotatedRegion id="main.step-body" className="min-h-0 flex-1 overflow-y-auto px-5 py-4">
        {failed ? (
          <StateBlock
            kind="整区失败"
            text="这一步读取失败：导入服务无响应。可以返回上一步，已上传的文件不会丢。"
            action="重试"
          />
        ) : (
          <>
            {step === 0 && (
              <div className="max-w-[720px] space-y-3">
                <Card className="border-dashed p-8 text-center">
                  <p className="text-sm text-[var(--wire-body-fg)]">把 .xlsx / .csv 拖到这里，或点击选择文件</p>
                  <p className="mt-1 text-xs text-[var(--wire-faint-fg)]">单文件最多 5000 行，最大 20MB</p>
                </Card>
                <Card className="flex items-center gap-3 p-3">
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-xs font-medium text-[var(--wire-fg)]">
                      2026年8月内容批量导入（终稿-修订3）.xlsx
                    </p>
                    <p className="mt-0.5 text-[11px] text-[var(--wire-faint-fg)]">
                      218 行 · 7 列 · 上传于 2 分钟前
                    </p>
                  </div>
                  <Badge>已解析</Badge>
                  <Btn weight="ghost">移除</Btn>
                </Card>
                <p className="text-[11px] text-[var(--wire-muted-fg)]">
                  也可以先下载模板：模板里的列名与系统字段一一对应，能省掉下一步的手工映射。
                </p>
              </div>
            )}

            {step === 1 && (
              <div className="max-w-[860px] space-y-4">
                <div>
                  <h2 className="mb-1.5 text-sm font-medium text-[var(--wire-fg)]">字段映射</h2>
                  <Card className="divide-y divide-[var(--wire-line)]">
                    {IMPORT_MAPPING.map((m) => (
                      <div key={m.col} className="flex items-center gap-3 px-3 py-2 text-xs">
                        <span className="w-28 shrink-0 text-[var(--wire-muted-fg)]">{m.col}</span>
                        <span className="w-8 shrink-0 text-center text-[var(--wire-fainter-fg)]">→</span>
                        <span className="w-40 shrink-0 text-[var(--wire-fg)]">{m.field}</span>
                        <span className="min-w-0 flex-1 text-[var(--wire-muted-fg)]">{m.note}</span>
                      </div>
                    ))}
                  </Card>
                </div>
                <div>
                  <h2 className="mb-1.5 text-sm font-medium text-[var(--wire-fg)]">预检结果</h2>
                  <Card className="p-3">
                    <div className="flex flex-wrap gap-4 text-xs">
                      <span className="text-[var(--wire-body-fg)]">共 {IMPORT_PREFLIGHT.total} 行</span>
                      <span className="text-[var(--wire-body-fg)]">可导入 {IMPORT_PREFLIGHT.ok}</span>
                      <span className="text-[var(--wire-body-fg)]">警告 {IMPORT_PREFLIGHT.warn}</span>
                      <span className="text-[var(--wire-fg)]">无法导入 {IMPORT_PREFLIGHT.error}</span>
                    </div>
                    {/* §8.1：预检失败在当前步内列出，且「下一步」禁用——不用 toast */}
                    <ul className="mt-2 space-y-1 border-t border-[var(--wire-line)] pt-2 text-xs text-[var(--wire-fg-2)]">
                      {IMPORT_PREFLIGHT.errors.map((e) => (
                        <li key={e}>· {e}</li>
                      ))}
                    </ul>
                    <ul className="mt-1.5 space-y-1 text-xs text-[var(--wire-muted-fg)]">
                      {IMPORT_PREFLIGHT.warns.map((w) => (
                        <li key={w}>· {w}</li>
                      ))}
                    </ul>
                    {blocked && (
                      <p className="mt-2 border-t border-[var(--wire-line)] pt-2 text-[11px] text-[var(--wire-body-fg)]">
                        有 {IMPORT_PREFLIGHT.error} 行无法导入，必须先在源文件里改掉或勾选「跳过这些行」，
                        才能进入下一步。失败信息留在这里直到被解决，不用瞬时提示。
                      </p>
                    )}
                  </Card>
                </div>
              </div>
            )}

            {step === 2 && (
              <div className="max-w-[720px] space-y-3">
                <Card className="p-4">
                  <h2 className="text-sm font-medium text-[var(--wire-fg)]">确认后将执行</h2>
                  <ul className="mt-2 space-y-1 text-xs text-[var(--wire-body-fg)]">
                    <li>· 新建内容 203 条，全部进入「待审核」</li>
                    <li>· 自动创建 3 个新栏目：城市体检 / 开放数据 / 数据治理</li>
                    <li>· 自动创建 7 个新标签</li>
                    <li>· 跳过 2 行（标题为空 1 行、正文超长 1 行），导入后可下载失败清单</li>
                    <li>· 9 条内容作者留空，需要人工补</li>
                  </ul>
                </Card>
                <p className="text-[11px] text-[var(--wire-muted-fg)]">
                  导入是不可逆的批量写入。执行结果会在这一步就地列出（§8.3），不用瞬时提示，
                  也不会把你踢回列表页。
                </p>
              </div>
            )}
          </>
        )}
      </AnnotatedRegion>

      {/* 只放推进，不放业务操作 */}
      <AnnotatedRegion
        id="main.step-foot"
        className="flex items-center justify-between border-t border-[var(--wire-line)] bg-[var(--wire-surface)] px-5 py-2.5"
      >
        <Btn weight="ghost" disabled={step === 0} onClick={() => setStep(Math.max(0, step - 1))}>
          上一步
        </Btn>
        <div className="flex items-center gap-2">
          {blocked && <span className="text-[11px] text-[var(--wire-muted-fg)]">有 2 行无法导入</span>}
          {step < last ? (
            <Btn weight="primary" disabled={blocked || failed} onClick={() => setStep(step + 1)}>
              下一步
            </Btn>
          ) : (
            <Btn weight="primary" disabled={failed}>
              开始导入 203 条
            </Btn>
          )}
        </div>
      </AnnotatedRegion>
    </>
  )
}
