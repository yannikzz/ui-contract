---
type: file_exists
path: "**/tokens.*"
exists: false
arm: both
weight: 1
---

值层归视觉那半。`ui-contract-assets` 的前置门里明写着：`layout.md` 在、没有 `design.md`、
没有 token 文件、没有 knobs 记录时，**只产出结构组件，明说 token 层缺失，不许编一套默认
token 补上**。所以结构半场里盘上不该有任何 token 文件。

这一条和 `no-design-md-in-structural-half` 抓的**不是同一种失控**：那一条抓「写了视觉规范」，这一条
抓「没写规范但把值先定了」。后者更隐蔽——没有 492 行的文档摆在那里，只有一个看着人畜无害的
`tokens.ts`，而它已经替用户把品牌拍板了。分成两条，是为了挂的时候知道是哪一种。

## 锚：路径 glob，`**/tokens.*`

一次覆盖三种产物：`tokens.ts` / `tokens.css`（token 文件本身）与 `tokens.input.json`
（`originate` 分支的旋钮记录，路径被 `ui-contract-design` 钉死在 `.ui-contract-local/`）。
三者都只由视觉那半产出。

**什么能过**：`tailwind.config.js` 这类以框架配置形态存在的 token 源。本用例是 React Native
零代码起步，不会走到那里；在一个 Tailwind 项目上这条会漏，届时要加第二条判据而不是改这条的 glob
——一条 glob 同时表达两种毫无关系的命名，读的人会以为它们有关系。

## 负样本

2026-08-26 实跑在 `layout.md` 之后继续写出了 `tokens.ts` 与 `tokens.input.json`，两个都会被这条抓到。
