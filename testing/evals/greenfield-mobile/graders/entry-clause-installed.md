---
type: regex
target:
  source: file
  path: CLAUDE.md
pattern: "layout\\.md"
flags: ""
match: contains
weight: 1
---

`ui-contract-enforce` 的 Entry 层：仓库根 `CLAUDE.md` 里要有一条，告诉此后任何 agent
「动界面结构之前先走 `layout.md` 的落位决策树」。

**它必须在结构半场里装。** 两个半场之间可能隔几周——用户拿着结构规范去评审，视觉那半还没开始。这段时间
里任何碰界面的 agent，如果仓库根没有那条指路，就完全不知道有这份规范存在。`ui-contract-enforce`
自己写着这一层「There is no wireframe precondition」，只依赖 `layout.md`，所以它**能**早装。

## 锚：`CLAUDE.md` 里出现 `layout.md` 这个字符串

这是一条**弱锚**，明说清楚：它判的是「根 `CLAUDE.md` 指向了结构规范」，不是「那条 Entry 条款
写对了」。

**什么能过**：一句「本项目有一份 `layout.md`」这样的纯提及——指了路，但没说要走决策树、没说
区域名必须在白名单里。要判到那一层得判语义，而 `CLAUDE.md` 通常很长，长文件上 judge 判据噪声大
（harness 自己会提示 prefer a regex for large artifacts）。所以这里**故意只判指路**，把
「条款内容对不对」明确留在无人守的状态，而不是写一条看起来在守的。
