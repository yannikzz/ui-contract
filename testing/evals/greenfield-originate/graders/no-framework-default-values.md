---
type: regex
target:
  source: file
  path: .ui-contract-local/tokens.input.json
pattern: "#3b82f6|#2563eb|#1d4ed8|#6366f1|#4f46e5|#0ea5e9|#0284c7|#007bff|#0d6efd|#1976d2|#2196f3"
flags: "i"
match: not_contains
weight: 1
---

派生出来的值里不许出现框架默认色。名单与 `originate.md` §Do not emit a framework default
一字不差（Tailwind blue/indigo/sky · Bootstrap primary · Material blue）。

它判的不是「好不好看」，是**坐标有没有走到值**。ADR-0009 把「产生审美」换成了「产生可追溯的
值」，而默认色的定义正是「没有理由就出现的值」——原样照抄一个框架默认色，说明 Step 1 的
坐标根本没参与派生。

⚠ **这条只拦名单里那几个字面值**，拦不住「换个色号的默认感」（把 `#3b82f6` 挪成 `#3c82f5`
照样过）。这是明说的漏，不是疏忽：机检到此为止，再往下只能靠 Step 3 的用户调校。
名单式检查天生不全，所以名单里有什么、漏的是什么，都写在这里。

⚠ **`regex` 的 `target.path` 不是 glob**（官方文档只写 "one file"，`**/` 那条语义只属于
`file_exists`），所以它必须指向一个确定的路径。2026-08-22 两轮实跑因此各抛错两次：
产品当时没规定落点，run 各写各的。

修法不在判据侧：ADR-0009 把落点**钉死**（工作记录，不是规范，所以不走可配置的路径表）。
判据跟着指同一个路径。落点 2026-08-25 从 `docs/ui-contract/` 移进工作台
`.ui-contract-local/tokens.input.json`，判据同步改了，**但新落点没有实跑样本**。

⚠ **同一天起，这条判据看的不再是值的权威。** `originate` 现在直接写 token 文件，
而这里读的是旋钮记录。两者由同一步、同一批派生值写出，所以记录里没有框架默认色
仍然说明「坐标走到了值」——但如果哪天两者会分叉，这条判据就在看错的那个文件。
换到 token 文件也不行：那个文件的格式是项目相关的（CSS 自定义属性 / `theme.extend` /
主题对象），而 `regex` 判据要一个确定路径和一份确定文本。**这是记下来的取舍，不是没想到。**

VERIFIED 2026-08-22，**只有正方向**：两次有效 run 都 `pattern absent as expected`。
负方向没有样本——真跑没写出过默认色，而人为塞一个验的是正则会不会匹配，不是产品会不会写。
