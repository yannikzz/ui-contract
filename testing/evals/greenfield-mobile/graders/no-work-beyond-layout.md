---
type: file_exists
name: no-work-beyond-layout
path: design.md
exists: false
arm: both
weight: 1
---

这个用例的四条计分判据**全部只看 `layout.md`**。链条继续往下走（`design` → `assets` →
`wireframe`）写出来的东西没有任何判据在看——那段时间是**无人观测的消耗**，不是产物错误。

**锚在产物存在性，不在工具调用。**2026-08-26 的实测里，agent **没有调用** `ui-contract-design`
的 Skill 工具，而是用 `Glob` + `Read` 直接读了 `skills/ui-contract-design/SKILL.md`、
`originate.md`、`design-md-outline.md`，然后照样写出了 `design.md`。所以一条
`tool_used: Skill, max: 0` 的判据**抓不到这次跑过头**。产物在不在磁盘上，两条路径都抓得住。

这不是 eval 的人造问题：真实用户机器上 `~/.claude/plugins/…` 同样可读，agent 同样可以绕过
Skill 工具直接读技能源码。相关的读法更正记在 `README.md`「`Skill called Nx` 测的不是链条长度」。

## `arm: both` 是刻意的

`tool_used` 落在 `Skill` 上的判据会被 harness 自动从对照臂剔除；`file_exists` 不会，
所以这里要显式想清楚。对照臂**没装插件，本来就写不出 `design.md`**——它通过是名副其实的
通过，不是「因为什么都没做而通过一条禁令」。（那种白送分的形态出现在
`tool_used: Skill, min:0, max:0` 上，官方文档举的正是那个例子，但它的前提是
「对照臂也可能调到 X」，在这里不成立。）

## 负样本（2026-08-26，`--keep-temp` 实跑）

那次运行在第 880 秒写出 `layout.md`，随后到第 1216 秒又写了 `design.md`、`tokens.ts`、
`tokens.input.json`、`regions.tsx`、`ui-contract.assert.ts`——**判据要挡的形态，实跑里有现成的一份**。

## 什么能过

只跑到 `assets` 而**跳过** `design.md` 的路径看不见（实测里没出现过：`design` 在链条上先于
`assets`）。要更严就得同时判 `src/ui-contract/regions.tsx`，但那会把「用户自己本来就有
`design.md`」的场景误判——本用例是 greenfield 零代码，不存在这个歧义，所以只判一个文件。
