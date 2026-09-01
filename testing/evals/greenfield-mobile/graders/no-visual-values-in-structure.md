---
type: regex
target:
  source: file
  path: layout.md
pattern: "#[0-9a-fA-F]{3,8}\\b|\\brgba?\\(|\\bhsla?\\(|\\boklch\\(|\\boklab\\(|\\blab\\(|\\blch\\(|\\bcolor\\(|\\b(font-size|border-radius|box-shadow)\\b"
flags: "i"
match: not_contains
weight: 1
---

结构规范里不得出现视觉值。允许的是结构参数（栏宽、最小可用宽、区域条数上限、网格列数），
需要视觉值的地方写「见 design.md §X」或「见 token 文件」。

用 regex 而不是 llm 判：这份文件通常上万字符，而 llm judge 在长输入上噪声很大
（harness 自己会提示 "prefer a regex grader for large artifacts"）。
十六进制色值与 CSS 视觉属性名是无歧义的信号，正好适合机械判定。

## 这条模式锚在什么上，什么走得过去

锚在**颜色的记法**（十六进制 + 七种函数记法）与**三个 CSS 视觉属性名**这个闭集上，
不锚在「这看起来像不像一个视觉值」。

⚠ **2026-08-28 补齐了函数记法。** 此前只认十六进制，于是 `oklch(0.62 0.14 250)`、
`rgb(37 99 235)` 写在 `layout.md` 里是**绿的**——而同一轮改动的记录说三处规范文档检查
「统一放宽到 `#{3,8}` 并补齐函数记法」，这一处只拿到了前半句。三处里另外两处
（`no-literal-values-in-design`、`audit.sh` 检查 4）当时就带了函数记法，只有它落下了。
散文说改了三处，磁盘上是两处半。

**刻意不带 Tailwind 色阶**（`bg-blue-500` 那类），和另外两处的理由相同：规范的反模式行里
会**提及** `bg-blue-500`，而分不开提及与使用，正是 `no-desktop-skeleton` 栽过的坑。

**仍然走得过去的**：属性名只有三个，`line-height` / `letter-spacing` / `opacity` 一律通过；
CSS 具名颜色（`red`、`slategray`）不在模式里；以及任何用文字描述的视觉值
（「主色比背景深两档」）——那本来就不是这条检查要抓的东西。
