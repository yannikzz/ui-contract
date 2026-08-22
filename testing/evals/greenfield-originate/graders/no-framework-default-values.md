---
type: regex
target:
  source: file
  path: tokens.input.json
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

⚠ **这条判据锁死了文件在仓库根目录，而产品说落点可配置。** `regex` 的 `target.path`
**不是 glob**（官方文档只写 "one file"，`**/` 那条语义只属于 `file_exists`），所以文件一旦
落在别处，这条报的是 `grader threw`，不是「有默认色」。2026-08-22 就发生过一次：
run3 把文件写在 `docs/ui-contract/`，这条直接抛错。

修不了，只能记着：`file_exists` 那条已经改成 `**/` 兼容任意位置，这条做不到同样的事。
配套的产品侧修复是**要求把落点写进 `config.md` 的路径表**——落点定了，这条才稳。
判据在这里比产品严格，是已知的、写下来的偏差。

VERIFIED 2026-08-22，**只有正方向**：两次有效 run 都 `pattern absent as expected`。
负方向没有样本——真跑没写出过默认色，而人为塞一个验的是正则会不会匹配，不是产品会不会写。
