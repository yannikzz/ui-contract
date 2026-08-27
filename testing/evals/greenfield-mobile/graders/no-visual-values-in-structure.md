---
type: regex
target:
  source: file
  path: layout.md
pattern: "#[0-9a-fA-F]{3,8}\\b|\\b(font-size|border-radius|box-shadow)\\b"
flags: "i"
match: not_contains
weight: 1
---

结构规范里不得出现视觉值。允许的是结构参数（栏宽、最小可用宽、区域条数上限、网格列数），
需要视觉值的地方写「见 design.md §X」或「见 token 文件」。

用 regex 而不是 llm 判：这份文件通常上万字符，而 llm judge 在长输入上噪声很大
（harness 自己会提示 "prefer a regex grader for large artifacts"）。
十六进制色值与 CSS 视觉属性名是无歧义的信号，正好适合机械判定。
