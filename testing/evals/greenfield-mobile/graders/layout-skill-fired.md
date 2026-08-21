---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?ui-contract-layout"'
min: 1
weight: 1
---

`skill-fired` 只断言「Skill 工具被调用过」，不问哪一个——15 个包共用那一条判据，
等于行为层对每个包的保障都是零。这一条点名产出 `layout.md` 的那个包。

VERIFIED 2026-08-21，**只有正方向**，而且第一次跑就抓到了东西：run2 里
`skill-fired` 绿（Skill 调了 2 次）而这一条红（`ui-contract-layout` 0 次），
`layout.md` 却照样写出来、两条内容判据照样过——**通用判据看不见的那种失效**。

负方向拿不到：with-only 判据被**丢出**对照臂，不是在那里判红的（量过，见 README）。
冻结轨迹也不行——重放的历史判据看不见（`Read called 0x`）。
