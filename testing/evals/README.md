# Eval 场景

两条起点，三个用例——0-1 线两个，因为它有两条动词分叉：

| 用例 | 起点 | 验的是 |
|---|---|---|
| `greenfield-mobile` | 0-1 线（一句话想法，无代码无稿） | 不把桌面端的骨架套到手机上；决策树是全函数 |
| `greenfield-originate` | 0-1 线的 `originate` 分叉（连视觉规范都没有） | 视觉规范被**生成**出来；命名声明表落进产物；规范里不留硬值 |
| `existing-admin` | 治熵线（有前端代码 + 已有 token） | 先跑 baseline 再写规范；不凭空发明区域树 |

## 跑批记录与已知缺口

带日期的实验记录在 [runs.md](runs.md)：成本、读数、每一次推翻了什么。**方法论警告是 load-bearing 的**：
判据换过写法，被判的行为也换过——不同轮次的分数不能互相比，「尺子换了」的依据都在 runs.md 里。

量出来、**尚未结清**的产品缺口（结一条勾一条，勾时指向修它的提交）：

- [ ] `existing-admin`：约 1/4 的实跑漏「禁止放」那一列（`allowlist-has-forbidden-column` 历史 3/4；
      判据锚的是规范措辞，挂了就是真漏列，不是误伤）——runs.md「三个用例全跑」
- [x] `tokens.input.json` 落地 2/5 → 落点钉死后 12 笔全部落地（runs.md「抬到 1800 秒之后重跑」）
- [x] `no-work-beyond-layout` 首挂的缺口：随 ADR-0013 的半场划分删除该判据——「beyond layout」的一半
      在新契约下是该做的（runs.md 2026-08-27 的条目）

**待测的欠账（改了行为、还没花过网关 2/3 的钱）**：2026-10-13 的架构轮新增了 originate 的
四条规则（拆标杆 / 模糊词翻译 / 动效 basis / 调校收尾的基线+无上下文评审，见 ADR-0017），
audit 的 check 10 改为三态上报（⛔ 逐行上提）并在报告尾部加了 `AUDIT-JSON` 尾注。这些行为的
有效性用例（audit-effectiveness 75 条）与结构不变量全绿，但**真跑行为的测量还欠着**——
下次跑 gate 2/3 时优先覆盖，尤其是 originate 分支。


它是随 issue #11 一起写的，写完没有跑——跑一次 eval 要花钱。
在它跑过之前，它的四条判据都是**推理出来的**，不是量出来的，而这个仓库刚因为「从假象数据推结论」
吃过亏（见下面的十二个坑）。

它为什么是新用例而不是往 `greenfield-mobile` 加判据：那个用例的 prompt 只要「界面结构的规范」，
产不产 `design.md` 不在它的射程内。把视觉判据挂上去，测的是一件那个 case 没做的事——
判据必挂，而挂的原因与插件质量无关。这正是坑 3 的同一个形状。

**先跑网关 1，它是免费的**——套件的 schema 与每条判据的 coherence，零 agent run，不到一秒：

```sh
./testing/preflight.sh
```

下面这些坑里的配置类问题，网关 1 会在花钱之前免费报出来。坑 4 尤其典型：那一条是花实跑的钱买来的，而 harness 一直在免费打印同一件事。

全量跑（网关 3）：

```sh
CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
  --ablation with-without --scaffold --allow-tools Write Edit --max-cost-usd 20
```

eval 目录写在 `.claude-plugin/plugin.json` 的 `experimental.evals`（= `testing/evals`），所以**不用带 `--eval-dir`**。官方推荐先用 `--runs 1` 试跑一遍再全量。

四个开关缺一不可：

| 开关 | 为什么必须 |
|---|---|
| `CLAUDE_CODE_WALNUT_SPIRE=1` | `plugin eval` 被一个默认关闭、按组织灰度的 feature gate 挡着。这个变量是官方给收不到灰度的机器留的口子；**不要设在仓库的 `.claude/settings.json` 里**，committed 的值通常不生效 |
| `--scaffold` | `existing-admin` 靠 `scaffold_script` 造 fixture 仓库，默认**不跑**（它会以你的身份执行作者提供的 bash）。不加这个开关，治熵线用例面对的是空目录 |
| `--allow-tools Write Edit` | `Write` / `Edit` 是 gated tool，`allowed_tools` 里列了还不够。不给，agent 写不出规范文件 |
| `--max-cost-usd` | **单价按 $2.60/run 算**（2026-08-27 实测：三用例两臂 6 次 run，$15.62，4410 秒）。此前这里写的是 $1.30/run，据此外推 14 次 run = $18.2——**低了一倍**。按实测单价，全量 14 次 run 约 **$36**，给 $20 会被砍在半路（第 11 条就是这个）。跑全量请给 `--max-cost-usd 40`。要省钱就 `--runs 1` 试跑（6 次，实测 $15.62），别把 `runs: 1` 写进 case：官方明说 *A single run on a non-deterministic agent is noise*，那是拿信号换省钱 |

`--ablation with-without` 会**真的把插件摘掉**跑一遍对照臂。这修掉了历史上一个已知的测量假象：手工造对照组时，子 agent 的可用技能清单里仍带着本插件的完整 description，等于把架构泄露给了对照组。

## 十二个 harness 坑（踩过，别再踩）

**1. 每条 prompt 都必须带「我时间紧，你按推荐的来，但把决策点列给我看」。**
技能的核心纪律是一次一问、等回答，而 eval 里没有人回答。漏了这句，带插件那一臂会停在一个访谈问题上，不带插件那一臂一口气吐完，**分数反而更高**。首次实跑就撞上了：with 0.00 / without 0.33 / Δ −0.33，全部由这一句的缺失造成，与插件质量无关。

**2. llm grader 必须写 `focus: trace`。** 默认是 `last_message`，只判最后一条消息。带插件的那一臂轮数多（实测 14 轮 vs 2 轮），产出散布在整条对话里，只判最后一条等于系统性地惩罚"会分步骤做事"的那一臂。

头两个坑是同一件事的两面：**默认配置偏向一次性长答，而这个插件的价值恰恰在于不那样答。**

**3. prompt 描述的现状必须和 sandbox 的实际磁盘一致。**
eval 在一个空 git 仓库里跑。如果 prompt 说"我已经有十几个页面了"，而磁盘上一个文件都没有，`ui-contract-setup` 会**正确地发现这个矛盾并停下来问**——前置门就是这么设计的。于是它永远产不出规范，所有 grader 必然全挂，而这跟插件质量毫无关系。

第一版 `greenfield-mobile` 就犯了这个错：用例名是 greenfield，prompt 却描述了一个已存在的项目。**治熵线的用例因此需要 `scaffold_script` 造一个真的 fixture 仓库**，光靠 prompt 里口述代码是不行的——插件会去看磁盘，然后发现你在说谎。

**4. 写文件的工具必须显式授权，光写 frontmatter 不够。**
`Write` / `Edit` / `Bash` 是 gated tool：`allowed_tools` 里列了还不行，跑的时候要带 `--allow-tools Write Edit`。不给的话 agent 会正确地停下来说"写权限被挡住了，决策点先给你过目"——而任何判"产出文件长什么样"的 grader 必然全挂。

跑用例的完整命令因此是：

```sh
CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
  --ablation with-without --scaffold --allow-tools Write Edit --max-cost-usd 20
```

**5. 默认 `timeout_seconds: 300` 对这条流程太短，而 900 也不够。**
带插件的那一臂要跑 setup → 访谈 → 写规范，实测被 300 秒砍在写文件之前，`file_exists` 判据因此必挂。

**900 是第二次不够。** 2026-08-25 那轮实跑给了一个干净的对照：三个 case 里，唯一抬到 1800 的
`greenfield-originate` 是唯一没超时的；仍留在 900 的另外两个**每一次都超时**（`existing-admin`
一次、`greenfield-mobile` 三次）。这条经验当时只被应用到一个 case 上，另外两个漏了。

超时不等于挂分——`existing-admin` 超时了仍拿 1.00，说明产物在被砍之前写完了。它真正的代价是
**污染读数**：`greenfield-mobile` 那两个 0.75 分不清是产品真的写了桌面骨架，还是被砍在修正之前。
现在三个 case 一律 1800。

**6. `focus: files` 只给 judge 一份文件清单，不是文件内容。**
判内容要写成 `focus: {source: file, path: <path>}`。用 `files` 判内容会得到三票 FAIL——judge 看到的是一串路径，它没法从路径判断白名单有没有「禁止放」那一列。更坏的是它在**没有任何文件**时也可能空集通过，产生假阳性。

**7. `scaffold_script` 是 case 目录下的**路径**，不是内联脚本。**
写成内联会被当文件名去 `open()`，报 `ENAMETOOLONG`，且 $0.00 静默失败。另外有 `case.yaml` 时 `schema_version` 必须是 `"1.1"`。scaffold 有 2 分钟上限、最小化环境、无密钥。

**8. llm judge 在长输入上噪声很大。**
产物动辄一两万字符，harness 会在失败行后面主动注记 `long file (17165 chars); llm judges are noisy on long inputs, prefer a regex grader for large artifacts`。实测：同一份写得对的 `layout.md`，llm judge 三票 FAIL。

**凡是能机械判定的判据都用 `regex`**，`target: {source: file, path: …}`，`match: contains | not_contains | count:N`。只有真正需要语义判断的（决策树是不是全函数、区域描述是"放什么"还是"是什么"）才留给 llm——而那几条要接受它天然带噪。

这条和 `ui-contract-audit` 那边的教训是同一个：**能机械判的就别交给判断，能判断的就别硬凑正则。** audit 那边是反方向踩的——把尺寸值交给正则，四条命中全是误报。

> **2026-08-21 修订**：这条的**处方**仍然成立，**归因**不成立。「长输入」不是原因——见第 13 条量出来的数据：一份 18851 字的负样本，judge 照样判对。真正的区分是判据要求的认知类型。

**9. 正则也会朝反方向错：把「判断才能判的」硬凑成正则。**
第 8 条说的是"能机械判的别交给 judge"。反过来同样会出事。`design-md-holds-no-hex` 曾经是一条 regex：`design.md` 里不许出现 `#[0-9a-fA-F]{6}`。实测两个臂**都不可能通过**——治熵线的 fixture 初始 `design.md` 本来就含硬编码色值（那是"现状"），而带插件那一臂做对了事之后，产物里留着一张迁移对照表（`#f8fafc` → `surface.sunken`），正则照样命中。同一份产物，判同一件事的 llm 判据三票 PASS。**正则分不开「定义一个值」和「引用一个要被搬走的旧值」。** 这条已删，判据交还给那条 llm grader。

**10. 空产出会拿到假阳性——判"没有违反"的判据必须先判"有没有产出"。**
`baseline-before-layout` 判的是"写结构规范之前先量了现状"。对照臂什么都没写，judge 看到一片空白，判"没有违反顺序"，**三票 PASS**。于是一个什么都没做的臂，在这条上拿了满分。凡是形如"没有做错 X"的判据，都要先有一道"东西存在吗"的硬前提。

**11. `--max-cost-usd 10` 不够跑完两个用例。**
实测 $10.40 打满上限，`greenfield-mobile` 的对照臂只跑了 1/3 就被砍，那个用例的 Δ 直接算不出来（harness 报 `arms graded under different rules`）。没有 `case.yaml` 的用例默认跑 3 次 run，两个用例两个臂就是 8 次。要拿到完整的 Δ，上限给 $20，或者给 `greenfield-mobile` 写一个 `case.yaml` 把 `runs` 降到 1。

**12. `focus: trace` 在多单元流程上不是"噪声"，是系统性失效。**
第 8 条把 llm judge 在长输入上的表现叫噪声——噪声该有波动。`baseline-before-layout` 判的是"先量现状再写规范"，**两次实跑、六票，全 FAIL**，而实际行为每次都完全正确：`ui-contract-baseline` 在 `ui-contract-layout` 之前调用、`as-built.md` 先于 `layout.md` 写出、`src/` 下 8 个文件全部真读过（transcript 逐条可查），产出的 `as-built.md` 开篇就是「记录界面现在实际是什么样，不记录它应该是什么样」。

一致的错不是噪声。这条判据要 judge 在一条 12 次 Skill 调用、3.7 万字产出的 trace 上重建一个时序事实，它做不到。**已拆成两条**：`as-built-cites-real-code` 用 regex 机械地判「引用了真实组件名」，`as-built-is-reverse-engineered` 只看 `as-built.md` 一份 8 千字的文件判「写的是现状还是应然」，时序由两条 `file_exists` 覆盖。

**这一改没有重跑验证**（两次跑已花 $18）。regex 那半是零成本验证过的——拿上一次 run 保留的真实产物比对，with 臂命中 33 次、对照臂根本没有这个文件。llm 那半只是把输入从超长 trace 换成一份短文件，方向上不会更差。

> **2026-08-21 结清**：`as-built-is-reverse-engineered` 已用 `testing/grader-check/` 的夹具**正反双向**验过，haiku 与 sonnet 都是 3/3 正确（正样本是实跑产出的真 `as-built.md`，负样本是拿 `layout.md` 冒充）。比原定的结清条件更强，且零 agent 成本。拆分是对的——但**理由和当时写的不一样**，见第 13 条。

**13. judge 默认是 haiku，而"llm judge 不行"的结论从来没跟模型这个变量分开过。**
`claude plugin eval` 有 `--judge-model`，**默认 haiku**——上面十二条里一条都没提过它。judge 成本只占总成本的 **2.2%**（$0.049 / $8.04），所以换模型的代价小到可以忽略，从来不是成本问题，是**没人想到它是个变量**。

但换模型也不是解法。用 `testing/grader-check/` 的零 agent 夹具正反两面各量一次（细节与完整表格见 [testing/grader-check/README.md](../grader-check/README.md)）：

| 判据 | judge 要做什么 | 长输入 | 短输入 |
|---|---|---|---|
| `decision-tree-total` | 逐行核对一张追踪表 | haiku 永远挂 · **sonnet 永远绿** | haiku 偏挂 · **sonnet 双向都对** |
| `as-built-is-reverse-engineered` | 判整体气质：现状还是应然 | 两个模型都双向都对 | 两个模型都双向都对 |

第二行的负样本是 **18851 字**的长文件，judge 照样判对。所以「长输入 judge 就不行」不成立，**判据要求的认知类型才是变量：判整体气质很行，逐行核对不行。**

**结果**：`decision-tree-total` 已删（见「刻意没有覆盖的」），`as-built-is-reverse-engineered` 留下并结清了第 12 条的欠账。判别力这件事从此有夹具守着，不必等下一次 $8 的实跑。

三条随之而来的纪律：

- **没有负样本的验证不叫验证。** 15 票全 FAIL 之所以被误诊成"判据太严"，就是因为只有正样本。`ui-contract-audit` 那边早有这条纪律（干净产物零违规 + 植入违规必须抓到），eval 这边一直没有。
- **判据不能改得更"友善"。** 把 `decision-tree-total` 改写成正面描述（"三件都在 → 通过"），正样本 3/3 PASS 而负样本也 3/3 PASS。末尾那句「缺 1 → 不通过」是有用的，不是噪声。
- **量到有价值的产物就立刻存进夹具。** 产物只活在临时目录和 `report.html` 里，随时会被清掉。

**十二个坑的共同点**：这套 eval 是在 `plugin eval` 还被 gate 关着的时候盲写的，八个假设全错，而且**每一个都朝着惩罚插件的方向错**。这本身就是一条结论——盲写的 harness 不要用来判断质量，只能用来发现自己哪里写错了。后加的四条（9-12）是两次实跑量出来的，前两条**朝相反方向错**：一条让做对的臂扣分，一条让什么都没做的臂加分。

## 刻意没有覆盖的

只机械化了 2 个场景。以下四条**全程无人守**，是明确接受的代价：

- 「不把参考产品的具体 IA 写成普适真理」——本 plugin 自称最重要的一条
- 对非技术用户的表现（急性子、不懂技术的店主那类）
- 内容站 / 文档站形态
- **决策树追踪的质量**——追得够不够狠、每一行有没有真的落到叶子、有没有事后补写成看起来很完美的样子
- ~~**`ui-contract-wireframe` / `ui-contract-assets` / `ui-contract-enforce` 的产物**——没有一条判据
  看过它们~~ **2026-08-27 结清**：ADR-0013 的四条达成判据看这三个包的产物了。留着这一条的原文
  是因为它记录了一个值得记住的形状——当时接受它的理由是「那些产物属于跑过头，不观测只是省钱」，
  而半场划分把它们变成了该做的，理由就地反转。**一笔接受的代价，可能因为别处的一个决定而到期，
  而不会有任何东西提醒你。**
- ~~**结构半场有没有正确收尾**——`grader-check` 的夹具里 agent 一步不跑，判不了 trace 类判据~~
  **2026-08-28 结清**，判据 `structural-half-handed-off` 双向验过。留着原文是因为它记录了
  另一个值得记住的形状：**这笔代价当时的理由是一句关于工具能力的错误断言**（「正负夹具的
  `last_message` 会长得一模一样」），不是一次权衡。一条被接受的代价，可能只是没试过——
  这次试了一下，$0.93。

前三条补它们要新增用例，成本随场景数线性涨。第四条是**新加的，性质不同**：它不是没人写，是
写过一条判据（`decision-tree-total`）而它**不工作**，2026-08-21 删掉了。

删的依据是 `testing/grader-check/` 的正负夹具：那条判据在任何模型/任何输入长度下都分不开「追了」和
「没追」，只是失效方向不同——haiku 永远挂、sonnet 永远绿。**一条不分黑白的判据比没有判据更坏，
因为记分板上它看起来在守。** 现在守着的只剩 `traces-in-artifact` 正则（追踪有没有落进产物，
正负双向验过），追踪**质量**明说没人守。

要把它加回来：唯一量到有判别力的组合是「judge 只看一份短文件 + sonnet」，代价是追踪表得从
`layout.md` 里搬出去单独成文件，而附录 B/C 就在规范里本身是有理由的设计。夹具还在，
真想做的话跑一次 `testing/grader-check/` 就知道行不行，不必再花 $8。

**基线分数因此不可跨日期直接比**：两个用例各少了一条 weight 1 的判据，而那条是长期挂红的，
所以之后的分数会比 2026-08-20 的 `existing-admin 0.80 / greenfield-mobile 0.67` 高，
高出来的部分不是变好了。


## 判据自己的验证状态

一条判据「存在」、「能失败」、「换个写法也能失败」是三件事。`testing/grader-check/`
能便宜地量前两件——但**只对一部分判据类型有效**，边界是量出来的不是推的。

`greenfield-originate` 那组值层判据的状态摊开如下（这张表比散在各判据文件里的
`VERIFIED:` 行更容易一眼看出哪里是空的）：

| 判据 | 正方向 | 负方向 | 备注 |
|---|---|---|---|
| `tokens-input-written` | 3/3（2026-08-22） | 无干净样本 | 早期的红可能是判据路径造成的，作废 |
| `tokens-input-at-pinned-path` | **无** | **无** | 判据与它要量的产品改动都是这一轮新写的文本 |
| `no-framework-default-values` | 2 次有效 run | 无样本 | 负方向没法便宜地造：注入 hex 验的是正则会不会匹配，不是产品会不会写 |
| `no-literal-values-in-design` | 3/3（2026-08-22） | 有（grader-check 夹具） | 双向都结清 |
| ~~`hue-basis-stated`~~ | — | — | 已删，色相依据现在没有机检 |

### `tool_used` / `tool_order` 无法用冻结轨迹验证（2026-08-21 实测）

想法是：冻结一份真实的、里面有工具调用的 session transcript，用 `context.history_file`
重放，让判据在 $0.06 的价位上判它。**不成立。**

```yaml
context: { history_file: history.jsonl }   # 一份真的、含 Read 调用的 transcript
graders: [ { type: tool_used, tool: Read, min: 1 } ]
```
```
→ read-seen-in-replay: Read called 0x (expected 1..∞)     score 0.00
```

重放进来的历史，判据看不见——只有**新一轮**的工具调用算数。所以这两类判据只能在真跑里
正负双向量，没有便宜的替身。它们各自旁边都写了 `UNVERIFIED:`。

### `tool_used: Skill` 默认不计分

官方规则（`docs/reference/plugin-eval.md` § Graders，本地提取，见 `docs/reference/EXTRACT.md`）：`arm: with-only`，**以及每一条不写
`arm` 的 `tool_used` on `Skill`**，在 `with-without` 的两个臂里都被排除出分数——
原文 *a `passed: false` with `scored: false` under a run scoring 1.0 is expected*。

后果：`input_match` 打错一个字符 → 判据静默失配 → 分数不动 → `--threshold` 不响 → 退出码 0。
这正是本仓库的招牌失效模式，而它是 harness 按设计内置的。

两件事接住它：

- **免费**：不变量 25 判 `input_match` 里的技能名必须是 `skills/` 下真实存在的包。抓「改名后
  断言没跟」，抓不到「正则本身写错」。
- **要花钱**：`--ablation none` 下 *nothing is excluded*，同一条判据**会**计分。所以 per-skill
  断言的正负双向只在这一层有意义。

### per-skill 覆盖：15 个包，2 个被点名

`skill-fired` 只断言「Skill 工具被调用过」，不问哪一个——15 个包共用那一条，等于每个包在行为层
都没有针对自己的保障。现在 `ui-contract-layout`、`ui-contract-design` 各有一条点名判据，
`existing-admin` 多一条 `tool_order` 守「先量现状再写规范」的时序（那一半在 2026-08-21 之前
一直漏着：删掉的 llm 判据说要「机械的部分交给 regex」，落地的 regex 只判了引用真实组件名）。

其余 13 个包仍然没有。不变量 25 每次跑都会把这个数字打出来，记在 issue #6。

**按技能拆用例大部分做不到**：8 个能力包都有前置门（不变量 10），单独扔进空沙箱会**正确地**
停下来说缺上游产物——判据必挂且与质量无关，正是坑 3 的形状。能独立测的是 5 个原语包与两个入口。

