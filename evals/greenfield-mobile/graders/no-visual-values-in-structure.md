---
type: llm
focus:
  source: file
  path: layout.md
weight: 1
---

# 结构规范里没有视觉值

结构规范（`layout.md`）中**不得出现**颜色值、字号、圆角、阴影、间距标度。需要值的地方写「见 `design.md` §X」或「见 token 文件」。

允许出现的是**结构参数**：栏宽、最小可用宽、区域条数上限、网格列数。

**判定**：出现任一 `#rrggbb` / `rgb(` / `px` 形式的字号或圆角 / 颜色名 → 不通过。栏宽与最小宽的 px 不算违规。
