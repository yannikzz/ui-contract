---
type: regex
target:
  source: file
  path: design.md
pattern: "#[0-9a-fA-F]{3,8}\\b|\\brgba?\\(|\\bhsla?\\(|\\boklch\\(|\\boklab\\(|\\blab\\(|\\blch\\(|\\bcolor\\("
flags: "i"
match: not_contains
weight: 1
---

视觉规范只写规则，值住 token 文件。

⚠ **这条正则在 `existing-admin` 上是刻意不加的**，理由记在那个 case.yaml 的末尾：
边界对齐的正确产物里有一张迁移对照表（`#f8fafc` → `surface.sunken`），
正则分不开「定义一个值」和「引用一个待搬走的旧值」，实测三票 PASS 对 FAIL。

**在 `originate` 上那个误报不存在**：没有既有规范，就没有要迁移的旧值，
`design.md` 里出现的任何色值都只可能是新定义的。同一条正则在一条分支上是误报、
在另一条上是准确判据——这是分支的差别，不是判据的差别。

`oklch(` 与 `rgba?(` 一起押，是因为借来的那套命名当前就写成 OKLCH；
只押十六进制的话，一份用现代写法把值写死的规范会安静地通过。
