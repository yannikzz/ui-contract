---
type: file_exists
path: "**/design.md"
exists: false
arm: both
weight: 1
---

结构半场以 `layout.md` 交接收尾。视觉半场是**另一条链**，没有入边，要重新进入，需要 `config.md` 里记着授权——
本用例的 prompt 只说了「先把界面结构的规范定下来再动手」，没有授权视觉那半。

**锚在产物存在性，不在工具调用。**2026-08-26 的实测里，agent **没有调用**
`ui-contract-design` 的 Skill 工具，而是用 `Glob` + `Read` 直接读了那个包的 `SKILL.md`、
`originate.md`、`design-md-outline.md`，然后照样写出了 `design.md`。所以一条
`tool_used: Skill, max: 0` 的判据**抓不到这次跑过头**。产物在不在磁盘上，两条路径都抓得住。
真实用户机器上 `~/.claude/plugins/…` 同样可读，这不是 eval 的人造问题。

## 这一条挡的不是「多做了好事」

`originate.md` 的准入条件点名了「你按推荐的来」这类输入，要求的是访谈定品牌方向，并且**明确
不许直接给一套默认色板**。实测那 492 行没有任何访谈。所以挡的是**没有授权的品牌决策被写成规范**。

## `arm: both` 是刻意的

`tool_used` 落在 `Skill` 上的判据会被 harness 自动从对照臂剔除；`file_exists` 不会，所以要显式
想清楚。对照臂**没装插件，本来就写不出 `design.md`**——它通过是名副其实的通过，不是「因为什么
都没做而通过一条禁令」。

## 锚：路径 glob，`**/design.md`

**什么能过**：换个文件名（`visual.md`、`品牌规范.md`）写同样的东西。这条锚在**这个插件自己
产出的文件名**上——`config.md` 的 paths 表默认就是 `design.md`，而所有单元都从那张表读落点，
所以插件走正常路径时只会用这个名字。绕过它要 agent 主动改名，那是另一种失败。

## 负样本

2026-08-26 `--keep-temp` 实跑：第 880 秒写出 `layout.md`，随后到第 1216 秒又写了 `design.md`、
`tokens.ts`、`tokens.input.json`、`regions.tsx`、`ui-contract.assert.ts`。
