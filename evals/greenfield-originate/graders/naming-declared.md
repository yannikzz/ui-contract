---
type: regex
target:
  source: file
  path: design.md
pattern: "borrowed|this project|not used"
match: contains
weight: 1
---

命名声明表有没有落进产物。

`design.md` 是**名字权威**，而这件事在输出里看不出来：无论名字是自己发明的、
还是照一套外部规范起的，生成出来的 token 文件长得一模一样。声明表是唯一的分别，
也是体检脚本抽白名单的唯一来源——没有它，`audit` 的检查 7 直接降级成不检查。

判的是**三个来源关键词**而不是表头。关键词是固定 ASCII（`borrowed` / `this project` /
`not used`），正因为产物要跟着用户的语言走：押表头的话，规范写成中文当场全假阴。
这与 `traces-in-artifact` 押类型词而不是押「附录 C」是同一个手法。

漏网诚实记着：这三个词落在正文散文里也会命中。声明表的**形状**（一行一个 token）没人守。
