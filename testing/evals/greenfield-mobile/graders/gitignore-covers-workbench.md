---
type: regex
target:
  source: file
  path: .gitignore
pattern: "ui-contract-local"
flags: ""
match: contains
weight: 1
---

`ui-contract-setup` 有一节专门讲这件事：*The workbench needs an ignore rule, and writing the
path down is not one*——填了配置表里的工作台那一格记的是**意图**，`.gitignore` 才是**执行**。
不加那一行，一次性的排练树被提交进仓库，而配置文件还在声称它没被提交。**这个状态下项目看起来
一切正常，文件就是在那儿。**

半场划分把这条从「顺手」变成「必须」：结构半场结束时工作台里装着三样东西（资产层、投影、密度输入记录），
不是从前那一份线框。

## 这条判据不能用 `file_exists`，原因值得写成通则

`file_exists` 的 `path` 是**本次跑里新建文件**的 glob——参考文档原话：*Only files created
during the run count*，且明确排除 scaffold 造的和仅被**修改**的文件。

本用例是零代码 greenfield，`.gitignore` 由 agent 新建，所以 `file_exists` 在这里**会**命中。
问题在别处：真实用户项目和 `existing-admin` 那种带 fixture 的用例里，`.gitignore` 早就存在，
往里加一行是 `Edit`。用 `file_exists` 写这条，它会**在 eval 里永远绿、在真实项目里永远瞎**——
一条只在测不到的地方失效的判据，比一条到处失效的更难发现。

**通则**：任何守「已有文件被加了一行」的判据都不能用 `file_exists`，要判文件内容。

## 锚：`.gitignore` 内容里出现 `ui-contract-local`

**什么能过**：注释掉的那一行、或者写在一个被更后面的 `!` 规则反选掉的位置。判 `.gitignore`
的真实语义要跑 git，判据做不到。
