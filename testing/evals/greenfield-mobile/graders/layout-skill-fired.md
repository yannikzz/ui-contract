---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?ui-contract-layout"'
min: 1
weight: 1
---

`skill-fired` 只断言「Skill 工具被调用过」，不问哪一个——15 个包共用那一条判据，
等于行为层对每个包的保障都是零。这一条点名产出 `layout.md` 的那个包。

UNVERIFIED: 正负双向都没量过。`tool_used` 判据**无法**用冻结轨迹做夹具——
实测 `context.history_file` 重放进来的历史，判据看不见（`Read called 0x`），
所以它只能在真跑里验。见 testing/evals/README.md「判据自己的验证状态」。
