---
type: regex
target:
  source: file
  path: layout.md
pattern: "三栏|三列|three-column|侧边栏|sidebar"
flags: "i"
match: not_contains
weight: 1
---

手机形态不得套用桌面端骨架。正确的等价物是**下钻一层**或**底部抽屉**；
导航是底部标签栏 / 抽屉 / 页面栈，页面栈时区域树是**一屏一棵**而不是一棵大树。

这条判据刻意严格到「连提都不能提」：一份手机端结构规范里出现「侧边栏」，
无论是在采纳还是在否定它，都说明作者的参照系是别人的产品。
