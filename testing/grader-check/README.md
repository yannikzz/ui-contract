# 判据的判据

`testing/evals/` 判插件做得对不对。**这里判 `testing/evals/` 的判据本身有没有判别力。**

agent 一步不跑：产物由 `scaffold_script` 直接摆进沙箱，case 的 prompt 只让模型回一句 done
（`focus: last_message` 的判据例外，见最后一节——它的 prompt 让模型原样输出被判的那段话）。
所以跑完全部 12 个夹具是 **107 秒 / $1.18**（2026-09-01 实测，单个夹具 $0.09–0.17），而不是一次完整实跑的 $18 和几十分钟。

> 这个数字之前写的是「12 秒 / $0.1 量级」，那是夹具还只有 4 个时量的，补到 8 个之后没跟——差了 7 倍。成本估计和别的数字一样会过期，改夹具数量时要一起改。（2026-08-28 补到 10 个、2026-09-01 补到 12 个，这一行两次都跟着改了。）

```sh
CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
  --eval-dir testing/grader-check --scaffold --ablation none --runs 1 --no-publish
```

`--eval-dir` 指向这里，所以跑正经 eval 时不会带上它。`--ablation none` 是因为这里没有"插件有没有起作用"这回事——被测的是判据，不是插件。加 `--judge-model sonnet` 换 judge 模型。

## 为什么需要它

`decision-tree-total` 累计 **15 票全 FAIL**，跨两轮实跑、$18。诊断写进了 issue #9：
"llm 判据在真实产物尺寸上系统性失效"，并据此列了三条出路，**每一条都要改产物结构**。

这个诊断是错的，而且是**只靠正样本得出的**——三份产物写得对却被判 FAIL，于是结论就成了
"判据太严/输入太长"。真正的问题要正反两面才看得见：换成 sonnet 之后，
正样本 3/3 PASS 了，**负样本也 3/3 PASS**。判据从"永远挂"变成了"永远绿"，
而后者更危险：假红显眼，假绿不显眼。

**没有负样本的验证不叫验证。** 这条纪律 `ui-contract-audit` 那边早就有了
（干净产物零违规 + 人工植入违规必须抓到），eval 这边一直没有。

## 每条判据两个夹具，缺一不可

| 夹具 | 摆进沙箱的东西 | 验哪条判据 | 期望 |
|---|---|---|---|
| `traces-present` | 2026-08-20 实跑产物，附录 C 追踪齐备 | `traces-in-artifact` | PASS |
| `traces-missing` | 2026-08-19 实跑产物，#5 修复前，一条追踪都没有 | 同上 | FAIL |
| `asbuilt-descriptive` | 实跑产出的真 `as-built.md`，写的是现状 | `as-built-is-reverse-engineered` | PASS |
| `asbuilt-prescriptive` | 拿 `layout.md` 冒充 `as-built.md`，通篇是应然 | 同上 | FAIL |
| `naming-declared-present` | 2026-08-21 `greenfield-originate` 首跑产物，声明表齐备（68 处关键词） | `naming-declared` | PASS |
| `naming-declared-missing` | `examples/admin-console` 的真实产出，产出时声明表这个概念还不存在（0 处） | 同上 | FAIL |
| `design-values-clean` | 同一份首跑产物，色值 0 处（值都在 token 文件里） | `no-literal-values-in-design` | PASS |
| `design-values-literal` | `existing-admin` 夹具里的「现状」`design.md`，9 处硬编码色值 | 同上 | FAIL |
| `handoff-correct` | **2026-08-28 gate 3 的真实产物**：`greenfield-mobile` with 臂的最后一条消息 | `structural-half-handed-off` | PASS |
| `handoff-truncated` | **同一份产物**，最后那段话换成「接下来我把视觉规范也定了」 | 同上 | FAIL |
| `structure-values-clean` | 2026-08-20 实跑产出的真 `layout.md`，598 行、零视觉值 | `no-visual-values-in-structure` | PASS |
| `structure-values-function-notation` | `design-with-literals.md` 真实携带的 9 处色值**逐个换成函数记法**后摆进 `layout.md` 的位置 | 同上 | FAIL |

`naming-*` 与 `design-values-*` 四个是 `greenfield-originate` 实跑之后补的。两个负样本都不是手搓的，这是刻意的：
- `naming-declared-missing` 的「没有声明表」是**时间造成的**——那份产物早于声明表这个概念，
  `examples/README.md` 里记着它落后两个 ADR。ground truth 来自它的出生日期，不是来自 `sed`。
- `design-values-literal` 的「含色值」是它的**本质属性**——它扮演的就是一个还没被规范化的项目，
  治熵线用例正是拿它当起点。

`handoff-*` 两个是 2026-08-28 随 ADR-0013 补的。**正样本一开始是手写的，当天就被证明不够。**

那条判据在手写夹具上 3-0 / 3-0 干净分离，上线当天的 gate 3 里**在真实产物上假红**：真实收尾
九成篇幅是决策清单和产出列表，交接只在最后两段，judge 跟着篇幅走了；而手写正样本是四段纯交接的
短消息，稀释这个变量在夹具里根本不存在。正样本现已换成那份真实产物（`fixtures/handoff-real.md`），
判据也跟着重写，复验 $0.27：**3-0 PASS / 3-0 FAIL**。

**所以下面那条纪律要对称地读**：负样本不能手搓，**正样本也不能**——手写的正样本只能证明判据
认得出我写的那种成功。负样本 `handoff-truncated` 目前仍是手写的，这一半还欠着：它要等一次
真实的「没收住、直接往下做」的跑。

⚠ 第四条判据 `skill-fired` **这里验不了**：夹具里 agent 一步不跑，`Skill` 自然不会被调用，
正负两样本会长得一模一样。

它也**不能靠 eval 的对照臂来验**——这一点是补跑之后才知道的：这类判据在两个臂里都被排除出
分数（见 `evals/README.md` §`tool_used: Skill` 默认不计分），对照臂的结果里根本没有这一行。
它最后是按 **trace 里的事实**结清的：with 臂 `Skill` 调用 2/7/2 次，对照臂 0/0/0 次，
而判据问的是「≥1 次」。

两条判据是**在这里第一次被真正验证**的：`as-built-is-reverse-engineered` 拆出来之后一直没跑过
（`testing/evals/README.md` 第 12 条记着这笔欠账），`traces-in-artifact` 的词表是从保留产物量出来的、
判据本身也没跑过。各花 $0.1 量级，两条都双向正确。

## 最近一次全量（2026-08-28，$0.93 / 67 秒 / 10 case，`--runs 1`）

五对夹具**五对都分得开**，负样本一个都没漏：

| 判据 | 正样本 | 负样本 | 判别力 |
|---|---|---|---|
| `as-built-is-reverse-engineered` | PASS ✓ | FAIL ✓（judge 3-0） | 有 |
| `no-literal-values-in-design` | PASS ✓ | FAIL ✓ | 有 |
| `naming-declared` | PASS ✓ | FAIL ✓ | 有 |
| `traces-in-artifact` | PASS ✓ | FAIL ✓ | 有 |
| `structural-half-handed-off` | PASS ✓（judge 3-0） | FAIL ✓（judge 3-0） | 有 ⚠ 见下 |

汇总表里负样本那几行的 `SCORE 0.00` 是**期望值**，不是失败——这一层「全部符合预期」的意思是
五个 1.00 和五个 0.00 各自落在该落的位置上，不是十个都绿。

`naming-declared` 到此双向都验过了。它是 PR #13 里唯一写着「正方向无样本，要等一次实跑」的那条；
`db33a85` 那次实跑把样本买了回来，**此后复验永远 $0.07**。

**harness 自己的告警在这次跑里出现了一次**，值得记：

```
asbuilt-prescriptive → judge votes: FAIL FAIL FAIL — note: long file (18851 chars);
                       llm judges are noisy on long inputs, prefer a regex grader for large artifacts
```

这正是 issue #9 花 $18 才得出、而且得错了的那个诊断——harness 一直在免费打印它。
但注意**这次它判对了**（负样本三票一致 FAIL），与下面那张表的结论一致：
长度不是变量，**判整体气质很行，逐行核对不行**。

`--runs 1` 意味着每条判据只有一票。这次五对全部干净分离、没有一个是 2:1 的边缘票，所以没有加跑；
哪一对将来出现分歧票，用默认 `runs: 3` 单独重跑那个 case（`--case <name>`）。

⚠ **这张表上的「有判别力」是相对夹具说的，不等于相对真实产物。** 同一天
`structural-half-handed-off` 就在这张表上是「有」、在 gate 3 的真实产物上假红。
**这一层能证伪判据，不能证成判据**——它便宜到可以先跑，但一条判据只有在真跑里活过一轮
才算验过。上面那一行的 ⚠ 指的就是这件事：它现在的正样本已经换成真实产物，那之后才是真的验过。

## 夹具必须是真实产物，不能是手搓的

第一版负样本是"把正样本的附录 C 用 `sed` 砍掉"。它判 PASS，我差点据此宣布判据空转——
**但那个负样本不干净**：附录 B 里还留着「追踪『交易行左滑删除』时，这条普通需求一路走到了停」
这类记述。judge 判 PASS 未必是错的，错的是夹具。

换成 #5 修复**之前**的真实产物就干净了：0 处追踪词、无附录 C，而且有 ground truth——
当时 judge 判 FAIL 是对的。

产物从历史 `report.html` 的 Evidence 块里提（那是 judge 当时实际看到的东西），
`as-built.md` 从 `trace.jsonl` 的 Write 调用里提。

**这两个来源都不是持久的**：`trace.jsonl` 躺在系统临时目录里随时会被清，而 `results/` 在
`.gitignore` 里——历史报告只活在跑过 eval 的那台机器上，不在仓库里。所以**量到一份有
ground truth 的产物就立刻存进 `testing/grader-check/fixtures/`**，那是它唯一会被留下来的地方。

## 量出来的结果：`decision-tree-total` 为什么被删

下面这张表就是删它的依据。它判的是「追得够不够狠」，2026-08-21 已从两个用例移除，
留下的 `traces-in-artifact` 只守「追踪有没有落进产物」。追踪**质量**从此没人守——
这是明说的取舍，不是遗漏，见 `testing/evals/README.md`「刻意没有覆盖的」。

夹具留着不是为了考古：哪天想把这条判据以别的形态加回来（比如让追踪表单独成文件、
judge 只看那一份），把它写进 `testing/grader-check/` 跑一次就知道行不行，不必再花 $8。

`decision-tree-total`（判据要 judge **逐行核对**一张追踪表）：

| 输入 | judge | 正样本 | 负样本 | 有判别力 |
|---|---|---|---|---|
| 全文 18851 字 | haiku | FAIL ✗ | FAIL ✓ | 否——永远挂 |
| 全文 18851 字 | sonnet | PASS ✓ | PASS ✗ | 否——永远绿 |
| 只给 §1+附录C 4085 字 | haiku | FAIL ✗ | FAIL ✓ | 否——偏挂 |
| 只给 §1+附录C 4085 字 | **sonnet** | **PASS ✓** | **FAIL ✓** | **是**（负样本 2/3） |

`as-built-is-reverse-engineered`（判据要 judge 判**整体气质**：写的是现状还是应然）：

| 输入 | judge | 正样本 | 负样本 | 有判别力 |
|---|---|---|---|---|
| 4903 字 / 负样本 18851 字 | haiku | PASS ✓ | FAIL ✓ | 是 |
| 同上 | sonnet | PASS ✓ | FAIL ✓ | 是 |

**注意第二张表的负样本是 18851 字的长文件，judge 照样判对了。**
所以"长输入 judge 就不行"是个不成立的概括——`testing/evals/README.md` 第 8 条据此写的处方要重读。
区别在判据要求的认知类型：**判整体气质很行，逐行核对不行。**

## 一个反直觉的量：判据不能改得更"友善"

试过把 `decision-tree-total` 改写成正面描述（"确认三件事都在文档里……三件都在 → 通过"）。
正样本 3/3 PASS，看起来更好了——**负样本也 3/3 PASS**。措辞一放宽就空转。
原判据末尾那句「缺 1 → 不通过。缺 2 或缺 3 → 不通过」是**有用的**，不是噪声。

## 加一条判据的夹具时

判据是**抄**进 `case.yaml` 的，夹具的全部价值在于「判的是线上那一条」，抄歪了比没有夹具更坏。
`testing/structure/invariants.sh` 的不变量 17 对这件事对账，跑 `./testing/run.sh` 就会查。
口径与既有两处一致：忽略空白与 `**`，并剥掉 markdown grader 的**开头那一行标题**
（`graders/*.md` 的 body 若以标题开头，`case.yaml` 内联的那份不含它，这个差异是被容忍的）。

⚠ 剥的只有**第一行**，正则不带 `re.M`。body 中间的 `## 小标题` 要连同正文一起抄进
`case.yaml`，抄的时候剥掉它们会判分家——2026-08-28 加 `structural-half-handed-off`
时就是这么转红的，而这段话当时读起来像是「剥掉所有标题行」。


## 这一层验不了什么（2026-08-21 实测，2026-08-28 补一类）

夹具的机制是「scaffold 把产物摆进沙箱 + agent 回一句 done」，所以它对**看产物**的判据有效：
`regex`、`file_exists`、`llm`（`focus: {source: file}`）。

**`focus: last_message` 也验得了**，这是 2026-08-28 量出来的：产物摆进沙箱之后，让 case 的
prompt 命令模型原样输出一段指定文本，那段文本就成了判据真正收到的输入。`handoff-correct` /
`handoff-truncated` 两个夹具**摆的是同一份产物**，只有那段话不同，判据仍然 3-0 / 3-0 分开了。

它与轨迹判据的区别在**谁产生被判的东西**：`tool_used` 要的是这一轮真发生过的调用，摆不出来；
最后那段话是模型这一轮真说的，prompt 命令它说什么它就说什么。**代价是它验不到「模型会不会
自发说出这种话」**——那只有真跑答得了，这里答的是「说出来了，判据认不认得」。

**看轨迹的判据在这里没有替身。** 试过用 `context.history_file` 重放一份含真实工具调用的
transcript，让 `tool_used` 判它：

```
→ read-seen-in-replay: Read called 0x (expected 1..∞)     score 0.00
```

重放的历史判据看不见，只有新一轮的工具调用算数。所以 `tool_used` / `tool_order` / 以及
`focus: trace` 的 llm 判据，正负双向**只能在真跑里量**。这不是还没找到方法，是量过的边界。

另外：结构判据（`regex` / `tool_used` / `tool_order` / `file_exists`）本身**不花钱**，
judge 一次都不调。这一层的 $0.06 全部花在那一次「回一句 done」的 agent run 上——
**所以多条结构判据挂在同一个夹具 case 上，一次 $0.06 能验一批**，不必一条一个 case。

## `structure-values-*` 这一对为什么值得单独说（2026-09-01）

补它的直接原因是：**这条判据刚被改过，而 gate 2 覆盖不到它**。
`testing/evals/README.md` 说三处规范文档检查「统一放宽到 `#{3,8}` 并补齐函数记法」，
`no-visual-values-in-structure` 只拿到了前半句——`layout.md` 里写函数记法的颜色是绿的。
补齐之后如果不补夹具，gate 2 报绿只说明**别的五对没坏**，而那个绿很容易被读成「改动验过了」。

**负样本不是手搓的，改的只是记法。** 它来自 `design-with-literals.md`——一份真实产物，
「带着字面色值」是它的本质属性（治熵线用例正是拿它当起点）。机械改写只动记法这一个变量，
其余一字未动。判别力在花钱之前就离线量过：**旧模式下它命中 0 处（会假绿），新模式下 9 处**，
9 正是原产物真实携带的色值数。

⚠ **夹具头部的说明刻意不写出那种记法本身。** 判据是全文匹配，注释里用一次就多算一处命中——
第一版就是这么写的，命中数从 9 变成 10。本仓库在 `layout.md` 的待定标记上栽过同一个跟头：
一份解释自己标记约定的文档，把三个待定数报成了六个。**用词描述，不要用样例。**

⚠ **仍然欠着的**：正样本是真实产物，负样本是机械改写，而这条判据是 `regex` 不是 `llm`——
regex 没有 judge，所以「手搓样本只能证明判据认得出我写的那种失败」这条纪律在这里的分量比
llm 判据轻，但没有消失。它守的是**记法**这个闭集，守不住任何不在集合里的写法：
CSS 具名颜色（`crimson`）、`line-height` / `opacity` 这类属性名，以及用文字描述的视觉值。
判据文件里列了这些，不要读成「视觉值已被覆盖」。
