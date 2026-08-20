---
type: regex
target:
  source: file
  path: layout.md
pattern: "敌意|恶意|hostile"
match: contains
weight: 1
---

决策树的追踪有没有落进产物。这条是机械的那一半，判断的那一半在
`decision-tree-total`：追得够不够狠、每行有没有落到叶子，正则判不了。

**为什么两半要分开**：2026-08-20 的实跑里，`decision-tree-total` 三次全挂，
而三份产物都写了一份像样的附录 C——两类输入齐备、每行都落到具体区域名、
「暴露了什么」一栏里记着真的树洞。harness 自己在每次失败后注记
"long file (16907–18574 chars); prefer a regex grader for large artifacts"。
判据没分开的时候，这个用例会永远报 0/3，把一次真实的改善盖掉。

**词表是量出来的**：那三份产物一致写「恶意」，大纲的英文原词是 hostile，
示例里写的是「敌意」。只押其中一个词，三次全是假阴。
