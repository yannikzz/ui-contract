# 判据的判据

`testing/evals/` 判插件做得对不对。**这里判 `testing/evals/` 的判据本身有没有判别力。**

agent 一步不跑：产物由 `scaffold_script` 直接摆进沙箱，case 的 prompt 只让模型回一句 done。
所以一次验证是 **12 秒 / $0.1 量级**，而不是一次完整实跑的 $8 和四十分钟。

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

后四个是 `greenfield-originate` 实跑之后补的，八个 case 一起跑 **$0.73 / 44 秒**，全部符合预期。
两个负样本都不是手搓的，这是刻意的：
- `naming-declared-missing` 的「没有声明表」是**时间造成的**——那份产物早于声明表这个概念，
  `examples/README.md` 里记着它落后两个 ADR。ground truth 来自它的出生日期，不是来自 `sed`。
- `design-values-literal` 的「含色值」是它的**本质属性**——它扮演的就是一个还没被规范化的项目，
  治熵线用例正是拿它当起点。

⚠ 第四条判据 `skill-fired` **这里验不了**：夹具里 agent 一步不跑，`Skill` 自然不会被调用，
正负两样本会长得一模一样。它的负样本只能来自 eval 的对照臂。

两条判据都是**在这里第一次被真正验证**的：`as-built-is-reverse-engineered` 拆出来之后一直没跑过
（`testing/evals/README.md` 第 12 条记着这笔欠账），`traces-in-artifact` 的词表是从保留产物量出来的、
判据本身也没跑过。各花 $0.1 量级，两条都双向正确。

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
口径与既有两处一致：忽略空白与 `**`，并剥掉 markdown grader 的标题行
（`graders/*.md` 的 body 含标题、`case.yaml` 内联的不含，这个差异是被容忍的）。


## 这一层验不了什么（2026-08-21 实测）

夹具的机制是「scaffold 把产物摆进沙箱 + agent 回一句 done」，所以它只对**看产物**的判据有效：
`regex`、`file_exists`、`llm`（`focus: {source: file}`）。

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
