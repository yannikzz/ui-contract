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

UNVERIFIED: 正负双向都没量过。负样本容易造（往 `tokens.input.json` 里塞一个 `#2563eb`），
但那验的是正则会不会匹配，不是「产品会不会写出默认色」——后者只有真跑能说。
