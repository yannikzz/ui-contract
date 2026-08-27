# Eval 场景

两条起点，三个用例——0-1 线两个，因为它有两条动词分叉：

| 用例 | 起点 | 验的是 |
|---|---|---|
| `greenfield-mobile` | 0-1 线（一句话想法，无代码无稿） | 不把桌面端的骨架套到手机上；决策树是全函数 |
| `greenfield-originate` | 0-1 线的 `originate` 分叉（连视觉规范都没有） | 视觉规范被**生成**出来；命名声明表落进产物；规范里不留硬值 |
| `existing-admin` | 治熵线（有前端代码 + 已有 token） | 先跑 baseline 再写规范；不凭空发明区域树 |

> **2026-08-21 已实跑，欠账结清**（两次共 $14.80，详见「greenfield-originate 首跑」一节）。
> **Δ = 1.00**（with 三次满分、without 三次零分）。这一跑还量出一条**尚未处理**的产品缺口：
> `tokens.input.json` 只有 2/5 落地。
> 四条判据在真实产物上全部 PASS，其中三条随后用 `grader-check/` 的夹具**正负双向**验过。

> **2026-08-27 又跑了一轮**（`--runs 1` 试跑 $15.62 + 单 case 诊断 $4.30）。
> **mean Δ +0.83**：`greenfield-originate` +1.00、`existing-admin` +0.88、`greenfield-mobile` +0.60。
>
> **不要拿这个 0.83 去和上面的 1.00 比。** 两次用的不是同一套判据：这中间
> `greenfield-mobile` 新增了 `no-work-beyond-layout`，另有四条判据被重写。尺子换了。
>
> **三个 case 全部没有超时**——1800 秒的调整生效了，这是它要解决的问题。
>
> 量到两件事：
> - `greenfield-mobile` 的 `no-work-beyond-layout` **首次测量即挂**：只要结构规范的 case，
>   产物里出现了 `design.md`。这是新量出来的产品缺口，不是变坏了。
> - `existing-admin` 的 `allowlist-has-forbidden-column` 挂了一次，复跑即过（该 case 满分 1.00）。
>   连同历史记录是 **3/4 通过**：约四分之一的实跑会漏掉「禁止放」那一列。
>   判据本身没问题——它锚的两种拼法正是英文原文和 `ui-contract-glossary` 钉死的中文渲染，
>   所以挂了就是真的漏了列或用了非规范措辞，不是指纹断言误伤。

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

## 一条量出来的产品缺口（已补上，见下一节）

`decision-tree-total` 在 `greenfield-mobile` 的**两次实跑共六次 run 里全部不通过**——六次一致，不是噪声。查产物：决策树本身是像样的，兜底也确实是 stop 而不是某个真实区域（判据 1 满足），但 `layout.md` 里**没有任何追踪痕迹**，判据 2、3 判的正是"这棵树被敌意输入和普通输入追踪过"。

根因是 grader 与单元之间的契约没对齐：`ui-contract-layout` 的完工清单要求 agent **做**这两轮追踪，但没要求把结果**写进规范**；grader 的 focus 是文件，只能看见产物。

两边都能改，但把追踪写进产物更有价值：一棵"被敌意输入验过"的树，如果验证过程不留痕，下一个改它的人不知道哪些边界是刻意设计的——这和附录 B 要求记下被推翻的结论是同一个道理。**这个缺口不是拆包重构引入的，改它是一次独立的产品改动。**

## 补上之后又量了一次（2026-08-20，$8.04 / 6 次 run）

只跑 `greenfield-mobile`，验的就是上一节那个缺口补没补上。结论分两半，**方向相反**：

**产品这半补上了。** 三次 run **全部**写出了附录 C：两类输入齐备，每一行都落到具体区域名，「这次追踪暴露了什么」一栏里记的是真的树洞——「控件整整一类缺席，日常需求走到停」「叶子多值，补了裁决问题」「上限是死路，没写满了怎么办」。对比上一节：那六次 run 里追踪痕迹**一条都没有**。把追踪写进大纲和完工清单是有效的。

**判据这半没跟上。** `decision-tree-total` 仍然 3/3 全挂，九票全 FAIL。而那三份产物逐条对得上它的三条判据：兜底是「停」且明写「不绕回主干」（判据 1）、敌意输入追踪过（判据 2）、普通输入也追踪过且都落到区域名（判据 3）。harness 每次失败都自己注记 `long file (16907–18574 chars); prefer a regex grader for large artifacts`。

按第 12 条的规矩——**一致的错不是噪声**——这已经不是「llm judge 有波动」，是这条判据在这个输入尺寸上系统性失效，累计 15 票全 FAIL 而行为一次比一次好。所以机械的那半拆了出来：`traces-in-artifact` 正则，两个用例都装。**判据不拆开的话，这个用例会永远报 0/3，把一次真实的改善整个盖掉。**

> **2026-08-21 更正**：「在这个输入尺寸上系统性失效」这个归因是错的，而且错在**只看了正样本**。补上负样本之后（见第 13 条）：换 sonnet 能让正样本 3/3 PASS，但负样本也 3/3 PASS——判据从「永远挂」变成「永远绿」。尺寸不是变量，判别力才是。

顺带修掉一个自己造的坑：那条正则原本只押「敌意」一个词，而三份真实产物一致写的是「恶意」——**三次全假阴**。词表现在是量出来的（`敌意|恶意|hostile`），不是照着示例猜的。这也是这次实跑除结论之外的第二个收获：一条判据写完不跑一次，就只是「看起来会命中」。

`no-desktop-skeleton` 这次 2/3（run 1 挂）。加上历史，这条纪律的实际稳定度是 7/9。

另有一条量出来的**稳定性**数据，不是缺陷但值得记：`no-desktop-skeleton` 在六次 run 里挂过一次（第二次实跑的 run 1）。这条判据刻意严格到「连提都不能提」——手机端规范里出现「侧边栏」，哪怕是在否定它，也算参照系跑偏。所以 5/6 是这条纪律当前的实际稳定度，不是 6/6。

## greenfield-originate 首跑（2026-08-21，两次共 $14.80）

第一次跑漏了对照臂：外层 shell 被一个 10 分钟的超时砍掉，而这份 README 开头就写着一次实跑要
四十分钟。补跑一次完整的（$9.07 / 65 分钟 / 3+3 次 run），下面是合并后的结论。

### Δ = 1.00，两臂之间没有中间地带

| | 3 次 run | 四条判据 |
|---|---|---|
| **with** | score **1.00 / 1.00 / 1.00** | 全 PASS |
| **without** | score **0.00 / 0.00 / 0.00** | 全 FAIL |

`naming-declared` 是最该验的一条：它押三个固定 ASCII 词，而 prompt 是中文、产物也跟着是中文。
五次 with run 全部把关键词写成 ASCII，**一行一个 token**，而且各自主动写下了那句告诫——
「三个关键词保持 ASCII 原样，即使文档其余部分是中文」。那句话是 `design-md-outline.md` 里的，
它传导到了产物。不跑的话，这条判据会不会像当年 `traces-in-artifact` 押「敌意」而产物写「恶意」
那样三票全假阴，只能靠猜。

### 负样本从哪来：对照臂不是答案

按「没有负样本的验证不叫验证」，实跑只给正样本。补齐的方式**三条各不相同**：

| 判据 | 负样本 | 结果 |
|---|---|---|
| `naming-declared` | `grader-check` 夹具：`examples/admin-console/design.md`，产出时声明表这个概念还不存在 | 双向正确 |
| `no-literal-values-in-design` | `grader-check` 夹具：`existing-admin` 的「现状」`design.md`，含 9 处色值 | 双向正确 |
| `design-md-written` | **不用造**：被打断的那次 run 没写出 `design.md`，判据如实判 FAIL | 双向正确 |
| `skill-fired` | 见下 | 按事实结清 |

⚠ **对照臂不是前两条的负样本。** 它三次都根本没写出 `design.md`（4 / 5 / 9 轮就结束了），
所以那两条在对照臂是 **grader threw**（目标文件不存在）。那证明的是「没文件时会红」，
而这本来就是 `design-md-written` 的职责。它们的判别力是夹具验的——夹具里**文件存在、只是
内容不合格**，这才是它们要分辨的那件事。写在这里，因为「对照臂覆盖了」这种话一年后读起来
像是真的覆盖了。

**`skill-fired` 也不能靠对照臂。** 原因就是下面「`tool_used: Skill` 默认不计分」那节写的
官方规则：这类判据在两个臂里都被排除出分数，对照臂的结果里根本没有这一行。它最后是按
**trace 里的事实**结清的：

| | with 臂 | without 臂 |
|---|---|---|
| `Skill` 调用次数 | 2 / 7 / 2 次 | **0 / 0 / 0 次** |

判据问的是「≥1 次」，对照臂是 0 次。**结清靠的是 trace 里的数字，不是 harness 给的判据结果。**

顺带量到一件它看不见的事：with 臂是 **2 / 7 / 2** 次。判据只问有没有，所以 2 次和 7 次一样绿，
走了两个单元和走了七个单元的差别，它守不住。

### 一条量出来的产品缺口：`tokens.input.json` 只有 2/5 落地

五次有效的 with run 里，`design.md` **5/5** 都产出，`tokens.input.json` 只有 **2/5**。

不是有意跳过：没产出的那几次，trace 里提到这个文件 **12 次和 8 次**，`design.md` 里却一个字
没提，文件也没写。模型读到了、想到了，最后没落地。产出的那两份质量还很高——JSON 里带一个
`$identity` 块，把「输入记录，不是值权威」直接写进了文件本身。

根因和 `decision-tree-total` 当年揭出来的是**同一个形状**，只是换了个位置：

| | 写在哪 | 落地率 |
|---|---|---|
| 命名声明表 | `## Before you call this document done` 清单里，且写得极具体（一行一个 token、三个词 ASCII） | **5/5** |
| `tokens.input.json` | 只在 `originate.md` 正文和身份表里**描述**过，完工清单里**没有它** | **2/5** |

同一份文件、同一个 agent、同一次运行。**进了完工清单的 100% 落地，只被描述过的 40% 落地。**
这既是缺口本身，也是一次「完工清单确实有效」的实测。

它不是可有可无的：ADR-0001 决定 B 的复议条件挂在「用户覆盖生成品牌的比例」上，而 `originate.md`
明写这个 diff 是那个数字**唯一的来源**。40% 的落地率等于那条复议条件六成时间没有数据。

两边都能改，和当年一样。**2026-08-21 两条都做了**：

- **改产品**——两处。`ui-contract-design` 的完工清单加了一条（上表就是这么做有效的证据），
  并且 `originate.md` 的 Step 2 补了一句「**进 Step 3 之前把文件写掉**」。原来那段话在
  「输出落成 `tokens.input.json`」的第三条理由处就结束了，从没说过**现在就写**——
  而那三次跳过的 run 恰好都是在这一步止于推理。
- **改判据**——`graders/tokens-input-written.md`，一条 `file_exists`。零成本、机械可判。

⚠ **这个用例的满分因此从 1.00 变成 0.75，直到产品修复生效。** 那是**真红**：缺口是量出来的，
不是判据太严。下一次实跑会同时回答两件事——修复有没有用（落地率），以及这条判据的正方向
（在此之前它本来就该红）。

⚠ 这也是一次**对上表那个结论的检验**。「进清单的 100% 落地、只被描述的 40% 落地」是从
一次测量得出的相关性，样本 n=5、只有一个对照对。如果加进清单之后落地率没变，那说明
真正起作用的不是清单，是别的东西——那比缺口本身更值得知道。

### 修复之后验了一次：判据双向已验，落地率**没有结论**（2026-08-21，$5.78 / 38 分钟 / 3 次 run）

只跑 with 臂（`--ablation none --case greenfield-originate`）：对照臂从不写 `design.md`，
两次独立实跑都证过，它对「修复之后落地了吗」这个问题贡献为零。三次 run 全部干净跑完——
无超时、无零轮，因为这次挂了 `caffeinate -i`，把上一轮那 7 次休眠空转的变量去掉了。

```
run1  31 轮  773s   tokens-input-written ✗   （其余五条全 ✓，score 0.833）
run2  30 轮  777s   tokens-input-written ✓   score 1.00
run3  23 轮  717s   tokens-input-written ✓   score 1.00
```

**判据这一半是明确的**：它在 run1 红、在 run2/run3 绿，**同一次跑里正负两个方向都出现了**。
`tokens-input-written` 的 `UNVERIFIED:` 可以摘掉——而且它验证自己的方式恰好是这一层唯一
可能的方式（`file_exists` 在夹具里验的是「文件在不在」，而这里验的是「产品会不会写」，
两件事）。

**落地率这一半没有结论，而且是算出来的，不是感觉：**

| | 落地 | 未落地 | 比例 |
|---|---|---|---|
| 修复前 | 2 | 3 | 40% |
| 修复后 | 2 | 1 | 67% |

Fisher 精确检验双尾 **p = 1.000**。40% → 67% 看起来是改善，**统计上与噪声区分不开**。
n=5 和 n=3 撑不起任何结论，无论方向多么符合预期。

**所以不能说「修复有效」。** 这正是 `CLAUDE.md` 记的那条推理——从「输出看起来对」推到
「机制生效」——只是这次的「输出」是一个比修复前好看的比例。三次里对了两次，修复前五次里
也对了两次，这两件事在数学上没有差别。

**同样地，那个推论也没被验证**：「进完工清单的落地 5/5、只被正文描述的落地 2/5」是修复所
依据的相关性，这次跑既没有证实也没有证伪它。要真回答，需要把样本堆到十次以上，
成本约 $20 且只回答这一个问题——**先记着，不值得现在花**。

⚠ **一个操作失误记下来**：run1 失败的原因**查不了了**。成功结束的 run 沙箱会被清理，
trace 跟着没了，所以「run1 为什么还是没写」这个最有价值的问题现在没有答案。
下次验这类东西要带 `--keep-temp`——一次诊断的价钱是磁盘，不是 $5.78。

### 想结清，被 token 吊销砍断（2026-08-22，$4.96 / 66 分钟 / 10 次 run）

跑之前**先把判定规则定死了**，因为跑完再挑说法就是循环论证：

```
修复前基线 2/5 = 40%。修复后合计 13 次时——
  ≥12/13 落地 → Fisher 双尾 p<0.05  → 判修复有效
  ≤11/13      → 判**不能宣称有效**，无论比例多好看（11/13 = 84.6% 时 p 仍是 0.0987）
```

**实际拿到的样本比计划少，因为跑到一半鉴权挂了：**

```
run1  ✓  30 轮  806s
run2  ✓   0 轮  900s  ← 超时，但六条判据全绿（见下）
run3  ✓  36 轮  845s
run4  ✓  25 轮  699s
run5  ✓  23 轮  640s   err: 401 OAuth access token has been revoked（收尾时才挂）
run6  ✗   1 轮   12s   err: 401 …revoked
run7  ✗   1 轮   12s   err: 401 …revoked
run8  ✗   1 轮   12s   ← 这五次 agent 一步都没跑成，
run9  ✗   1 轮   14s      **不是样本**，是环境故障
run10 ✗   1 轮   12s
```

有效 5 个，**5/5 落地**。加上此前修复后的 3 次（落地 2）→ 合计 **7/8 = 87.5%**。

| | 落地 | 未落地 | 比例 |
|---|---|---|---|
| 修复前 | 2 | 3 | 40% |
| 修复后 | 7 | 1 | 87.5% |

**Fisher 双尾 p = 0.2168。** 按跑之前定死的规则：**仍然不能宣称修复有效**。

87.5% 对 40% 看起来已经很像样了，而这正是那条规则存在的理由——它是在看到这个数字**之前**
定的。差 4 到 5 个有效样本就能过线（12/13 时 p = 0.0441）。

### 两件比结论更该记的事

**一、鉴权失败没有让套件报 partial。** 五次 run 死于 401，而结果文档里
`partial: false` / `partialReason: null`，退出码 **0**。官方文档写着 exit 2 用于
「the credential was rejected」，但那说的是**首次 run 就被拒**或 preflight 阶段；
**跑到一半才被吊销**走的是每个 run 各自的 error 字段，套件层面看不出来。

后果很具体：只看退出码和汇总分数，这次跑长得像「插件在十次里失败了五次」。
**必须逐 run 看 `error` 字段。** 这和网关 1 那条「不许只看退出码」是同一个教训的第二次出现。

**二、另一个会话预言的失效模式当场发生了。** 上一节末尾写着：

> 它下一次失败不会长成「分数低」，会长成「turns=0 / $0.00 的满分 run」。

run2 就是：`turns=0`、`$0.00`、`timed out after 900s`，**六条判据全绿**。文件在被砍之前
全写完了，丢的是统计不是产物。这次它没造成误判（方向是「看起来比实际差」而不是反过来），
但那句预言写下来还不到一天就应验了，说明 `timeout_seconds: 900` 确实到头了。

### 还差什么

**5 个有效 run**（约 $7 / 35 分钟）。跑之前**要先重新登录**——当前 token 已被吊销，
`--max-cost-usd 0` 的预检不查鉴权（它在任何 run 开始前就退出了），所以预检绿**不代表能跑**。

⚠ `--keep-temp` 这次带了，但**没派上用场**：五个有效 run 全部落地，没有可诊断的失败。
留着这句是因为下次仍然该带——它的价钱是磁盘。

### `timeout_seconds: 900` 已经临界

三次 with run 的耗时是 **900（超时）/ 886 / 876 秒**，全部贴着上限。第一次那个 run 虽然报
`timed out after 900s`、`turns=0`、`$0.00`，四条判据却全 PASS——**文件在超时之前已经写完了**，
超时丢的是统计不是产物。

坑 5 当年把这个值从 300 提到 900，现在 900 也到头了。它下一次失败不会长成「分数低」，
会长成「turns=0 / $0.00 的满分 run」，看起来像 harness 抽风而不是超时。

## 三个用例全跑（2026-08-21，$10.18 / 4.5 小时 / 18 次 run）

**这是两次跑拼起来的**，时间戳对不上是正常的：第一次在 `existing-admin` 跑完两臂后被手工中断
（SIGINT → `partialReason: "interrupted"`，$3.93 / 115 分钟），第二次用 `--case 'greenfield-*'`
续跑剩下两个用例（$6.25 / 157 分钟，exit 0）。**`plugin eval` 没有 resume**，从中断处继续的
唯一办法就是 `--case` 过滤掉已经跑完的用例——重跑已完成的用例只是白花钱。

⚠ **与上一节是两次独立的跑，别把数字加起来。** 上一节（$14.80）是另一个会话专门补的
`greenfield-originate` 对照臂，本节（$10.18）是三个用例的全量。两次都跑了
`greenfield-originate`，结论一致（Δ 都是 1.00、对照臂都是 0），但**它们是两组样本**。
同一天同一个用例被两个会话各跑一次，这件事本身也说明了一点：这一层没有「已经跑过了」的
共享状态，`results/` 在 `.gitignore` 里，谁跑过什么只活在各自的 README 段落里。

### 先说结论：汇总里的平均分不能引用

18 次 run 里 **7 次是零轮**（`turns=0` / `$0.00`），成因见下一节，与插件质量无关。
它们照样进了分母，所以 `overallScore 0.42` / `meanDelta 0.42` 这类数字**是被污染的**。

只看真正跑起来的 run：

| 用例 | with（有效 run） | without（有效 run） | Δ |
|---|---|---|---|
| `existing-admin` | 0.875（41 轮） | 0（18 轮） | **+0.875** |
| `greenfield-mobile` | 0.75 · 0.75（20 / 21 轮） | 0（3 轮） | **+0.75** |
| `greenfield-originate` | 1.00（24 轮） | 0 · 0 · 0（5 / 4 / 4 轮） | **+1.00** |

对照臂**每一次有效 run 都是 0 分**，没有一次侥幸产出——这一点比 Δ 的具体数值更有说服力，
因为它是九次独立采样的一致结果（含第一次跑的那一次）。

### 零轮 run 的成因查清了，是机器睡眠

第一次跑在 10:18 之后连续七次 `turns=0 / $0.00`，当时只能看出是「时间上的硬断点」，
`authRejected` 为 `None`，排除了鉴权。第二次跑里 harness 直接把原因写出来了：

```
err = exit 1: API Error: Your computer went to sleep mid-response.
```

**机器睡了。** 所以不要改 `timeout_seconds`——900 秒对一次正常 run（20 轮 / 419 秒）是够的，
改它等于用配置去补一次环境故障，下次还会误导人。长跑之前先关掉睡眠。

顺带一个反直觉的观察：`greenfield-originate` 的 with run1 **报了 `timed out after 900s`，
却拿了满分 1.00**——它在被砍之前已经把 `design.md` 写完了。**超时不等于没产出**，
判据看的是磁盘不是退出状态。

### 这次跑到的最重要的一件事：per-skill 判据抓到了通用判据看不见的东西

`greenfield-mobile` 的 with run2：

```
✓ skill-fired         Skill called 2x     ← 通用判据：绿
✗ layout-skill-fired  Skill called 0x     ← 点名判据：红
✓ layout-md-written   layout.md exists
✓ no-desktop-skeleton pattern absent as expected
✓ no-visual-values-in-structure
```

**插件确实跑了，但跑的不是 `ui-contract-layout`**，而 `layout.md` 照样写出来了、
两条内容判据照样过。这正是这个仓库反复栽的那一类失效：**输出看起来完全正常**。
在这条点名判据存在之前，这次 run 在记分板上和 run1 长得一模一样。

这也是 `CLAUDE.md` 记的第一次事故的同一形状——「四个提问单元漏掉调用行，行为看着完全正常」。
两年前那次是靠人读代码发现的，这次是判据发现的。

⚠ **但它没有改变分数**：点名判据是 `tool_used` on `Skill` 且没写 `arm`，被 harness 归为
with-only，**两个臂都不计分**（见下面「`tool_used: Skill` 默认不计分」）。它只是个指示灯。
要让它计分得写 `arm: both`，而那会让对照臂必挂——这笔取舍还没定，记在 issue #6。

### 三条新判据的验证状态更新

| 判据 | 正方向 | 负方向 | 结论 |
|---|---|---|---|
| `baseline-before-layout`（`tool_order`） | ✓ `Skill@23 precedes Skill@31` | ✓ 对照臂 `"before" tool Skill never called` | **双向已验**，可以摘掉 `UNVERIFIED:` |
| `design-skill-fired` | ✓ 3/3 次 with run 都命中 | ✗ 见下 | 正方向已验 |
| `layout-skill-fired` | ✓ 1/3（run2 如实报红、run3 是睡眠） | ✗ 见下 | 正方向已验 |

### 一个结清条件被证伪：负样本拿得到，但不是从判据结果里拿

issue #6 第 6 笔原本写着「结清条件：任何一次跑完对照臂的网关 3」。**这次跑完了对照臂，
判据结果里仍然没有它**——with-only 判据是被**丢掉**的，不是被拿去对照臂跑然后判红的。
对照臂的判据清单里根本没有这一行：

```
[without] run1: design-md-written / naming-declared / no-literal-values-in-design
          ← skill-fired 与 design-skill-fired 都不在列
```

官方原文说的是 *dropped from the without-arm*，此前被读成了「在对照臂会红」。

> **更正（同日，两个会话独立跑出来的）**：我一度写成「唯一的办法是 `arm: both`」，
> **那句是错的**。上面「负样本从哪来」那节用的是另一条路：**去 trace 里读事实**——
> with 臂 `Skill` 调 2/7/2 次、对照臂 0/0/0 次，判据问的是「≥1 次」，负方向的证据齐了。
> 缺的是**判据结果这一行**，不是**证据**。这两件事此前被我混成了一件。

所以真正的分歧只剩一个：`arm: both` 能让它**计分**（代价是对照臂多一条必挂的判据、
Δ 的口径跟着变），而读 trace 只能让人**知道**。前者未定，记在 issue #6；后者已经做了。

这个区别对 per-skill 判据尤其要紧：`layout-skill-fired` 在 `greenfield-mobile` run2 上
红了并且**红得对**，但它不计分，所以那次 run 的分数和干净的那次仍然一模一样。
指示灯亮了，闸没有落。

### 两条稳定度数据

- `no-desktop-skeleton`：这次 with 臂两次有效 run 全过，累计 **7/8**（此前 5/6）。
- `traces-in-artifact`：这次 `greenfield-mobile` 两次有效 run **全挂**（`pattern not found`），
  而第一次跑的那次是过的，累计 **1/3**。这条是 2026-08-20 才把词表从「敌意」扩成
  `敌意|恶意|hostile` 的，扩完在 `existing-admin` 上稳定命中、在 `greenfield-mobile` 上不稳定。
  **样本还太小，判不出是产品倾向还是判据太窄**，记进 issue #6 与 `no-desktop-skeleton` 同档。

### 四十分钟这个数字要改

README 顶部长期写着「四十分钟」。实测 **18 次 run 花了 4.5 小时**，其中还有 7 次是零轮空转。
按有效 run 的实际耗时（168–1729 秒，中位数约 400 秒）重算，一次干净的全量大约 **2 小时**。
放后台跑，别用带超时的外层 shell——上一次网关 3 就是死在 10 分钟超时上。

## ADR-0009 首验：三条判据，一条起作用、一条误判、一条不可信（2026-08-22，$3.88 / 40 分钟 / 3 次 run）

移除 `frontend-design` 依赖之后的第一次实跑。结果**没有一条是干净的好消息**，
但每一条都指向一个具体的、此前不知道的东西。

```
run1  25 轮  795s   tokens ✓  hue ✗(2:1)  黑名单 ✓  no-literal ✗
run2  22 轮  827s   tokens ✓  hue ✓(3:0)  黑名单 ✓  no-literal ✗
run3  31 轮  762s   tokens ✗  hue ✗(3:0)  黑名单 throw  no-literal ✓
```

### 一、`tokens-input-written` 的 2/3 是**判据误判**，产品是对的

run3 写了那个文件——写在 `docs/ui-contract/tokens.input.json`。判据写的是
`path: tokens.input.json`，一个**只匹配仓库根目录**的 glob。

而 `ui-contract-design/SKILL.md` 第 23 行明写：

> Artifact paths come from `docs/ui-contract/config.md`'s paths table. …
> **Never assume a path the config contradicts.**

**判据假设了一个产品明确规定不许假设的路径。**

**连带作废**：此前所有「落地率」数字（2/5、7/8、2/3，issue #6 第 10 笔追了两轮约 $11）
测的不是「产品写不写」，而是「产品把它写在哪」。上一轮已经作废过一次（归因为
`frontend-design` 分叉），**那次归因也不完整**——至少混进了这第二个原因。

真根因是第三层的：**产品从未规定这个文件落在哪**（`grep` 全仓库零结果）。
三次 run 两次选根目录、一次选 `docs/ui-contract/`，三次都讲得通，因为没有任何东西说过。
这不只是测量问题——`ui-contract-assets` 之后要读这个文件，它去 `config.md` 的路径表里找。

**修法两侧**：判据改成 `**/tokens.input.json`；产品要求把落点写进 `config.md` 的路径表。

### 二、`no-literal-values-in-design` 回归了，**是这次改动直接造成的**

它之前稳定通过，这次 2/3 挂。成因是我加的那条「色相依据必须写进 `design.md` §1」——
**说明依据几乎必然要提到具体颜色**：

| run | 写了什么 | 撞了哪条 |
|---|---|---|
| run1 | 「比 Tailwind blue-500（`#3b82f6`）更深更钝」 | **引用黑名单里的值来说明自己避开了它** |
| run2 | 「不采用 AntD 默认蓝（`#1677ff`），改用青色 `#13c2c2`」 | 把选中的值写进了 `design.md` |

run1 尤其说明问题：agent **认真执行了**「不许用框架默认色」，方式是点名那个默认色说自己没用，
于是撞上「`design.md` 里不许有字面值」。**两条规矩互相打架，而加第二条时没查第一条。**

已修：色相依据必须用词语或 token 名说明，值留在 `tokens.input.json`。

### 三、`hue-basis-stated` 的 1/3 **大概率是判据不可信，不是产品没做**

票型 `3:0 PASS` / `2:1 FAIL` / `3:0 FAIL`，三次都带 harness 的长输入告警（9183–11255 字）。

**人工读了判 FAIL 的那份产物**：它点名了用哪一类依据、说明了为什么、明确写了
「这是整组值里依据最弱的一环」并指出第一个该换的值——**完全符合判据的判定条件**。

根因是 `focus` 喂了整份 9–11K 字的 `design.md`，而依据只占其中一段。
`grader-check/README.md` 早就量过同一条规律：**判整体气质很行、逐行核对不行**，
而「在一万字里找出某一段有没有说清一件事」属于后者。

这条判据现在**不可信，别拿它的红绿下结论**。修法两条都要改东西，都还没做，记在 issue #6。

### 四、`no-framework-default-values` 起作用了，但它锁死了路径

两次有效 run 都 `pattern absent as expected`。run3 是 `grader threw`——**`regex` 的
`target.path` 不是 glob**（`**/` 那条语义只属于 `file_exists`），文件落在别处就抛错。

所以同一个路径问题，`file_exists` 能改成 `**/` 兼容，`regex` 不能。判据在这里比产品严格，
是**已知的、写下来的**偏差，配套修复是产品侧把落点固定进路径表。

### 这次跑真正买到的东西

三条判据里两条自己有毛病，一条测出了我造成的回归。**没有一条是「产品行为符合预期」的确认。**

但它换来了三件此前不知道的事：一个产品从未规定的落点、一对互相打架的规矩、
一条在长文件上不可信的判据。$3.88。

## ADR-0009 复验：两条修复成立，一条判据被删（2026-08-22，$2.31 / 36 分钟 / 3 次 run）

```
run1  0 轮*  908s   tokens ✓  no-literal ✓  黑名单 throw   hue ✓(3:0)
run2  27 轮  647s   tokens ✓  no-literal ✓  黑名单 ✓       hue ✗(3:0)
run3  25 轮  591s   tokens ✓  no-literal ✓  黑名单 throw   hue ✗(3:0)
```
\* run1 又是那种「turns=0 / $0.03 却几乎满分」的超时——文件在被砍前写完了。第三次出现。

### 两条修复都成立——但要看清修的是哪一侧

| | 修前 | 修后 | 修在哪一侧 |
|---|---|---|---|
| `tokens-input-written` | 2/3（判据路径只匹配根目录） | **3/3** | **判据侧**（`path` 改成 `**/`） |
| `no-literal-values-in-design` | 2/3 挂（色相依据把 hex 带进了 `design.md`） | **3/3** | 产品侧（改成用词语/token 名说明依据） |

⚠ **第一行不是「产品把文件写对了地方」**，是「判据不再因为位置而误判」。
这一轮三次 run 仍然是两次 `docs/ui-contract/`、一次仓库根——落点照旧是散的。
**落点钉死是在这一轮之后才落的**（见下节），所以它零实跑背书。
新加的 `tokens-input-at-pinned-path` 就是去量它的，同样一次没跑过。

第二条尤其值得记：修法是「用词语或 token 名说明依据，值留在 JSON」，而产物里真的照做了——
其中一份写着「不采用任何框架默认色——具体数值见 `tokens.input.json`，**本文档不写字面值**」。
规则被读懂了，不是被绕过。

### `hue-basis-stated` 删了。产品 3/3，判据 1/3

这条判据 2026-08-22 加、同日删。两轮实跑各 1/3，而**三份被判 FAIL 的产物人工核对全部合格**：

> **色相基准**：遵循**领域惯例**——招聘/HR 类工具普遍使用蓝色系…**没有走**"打破惯例"或
> "避让相邻产品"路线，因为…不采用任何框架默认色——具体数值见 `tokens.input.json`。

四类依据点名了用哪条、说明了为什么不用另外两条、还主动遵守了新加的「不写字面值」规则。
judge 判 **3:0 FAIL**。另一份用 adjacency avoidance、说明了和 `success`/`destructive`
语义色的冲突，同样 3:0 FAIL。

**这不是「判据太严」，是判据在这个输入尺寸上不工作。** 六次 run 里它对了两次，
而产物六次全合格——它区分不开合格与不合格，只是随文件长度随机翻面。
`grader-check/README.md` 早就量过同一条规律：**判整体气质很行、逐行核对不行**，
而「在一万七千字里找出某一段有没有说清一件事」属于后者。

按第 13 条的纪律——**一条不分黑白的判据比没有判据更坏，因为记分板上它看起来在守**——删掉，
不放宽。这和 `decision-tree-total` 是同一个处理，同一个理由。

**色相依据从此没人机检守着**，与追踪质量同档，明说没覆盖。要加回来得先解决输入尺寸：
把依据拆成独立短文件让 judge 只看那一份（要改产物结构），或换成名单式 regex（会有假阴）。
两条都没做。

### 落点从「记下来」升级成「钉死」

第一轮的修法是「把落点写进 `config.md` 的路径表」。这一轮量到：**没用**——三次仍然
两次 `docs/ui-contract/`、一次仓库根。**写下选择让它可见，不让它变成同一个选择。**

所以 ADR-0009 把它钉死在 `docs/ui-contract/tokens.input.json`。这是唯一一个不走可配置
路径表的产物，理由是它不是规范而是工作记录，和 `config.md` 同一个抽屉。
`regex` 的 `target.path` 不是 glob（`**/` 只属于 `file_exists`），所以黑名单那条判据
必须有一个确定路径——落点钉死之后它才稳，这一轮它抛错两次就是因为还没钉。

**钉死之后连带改了三处，都还没跑过：**

| 改了什么 | 为什么必须一起改 |
|---|---|
| `ui-contract-assets` 前置门与 §Landing the token file 写死同一路径 | 钉死的**理由**就是「下游要读它」，但消费端此前仍被指向 `config.md` 的路径表，而那张表里没有这个文件。「表里没有」和「项目选了别处」在读者眼里长得一样 |
| `config-template.md` 写明这一行**故意不在表里** | 同上的另一半：不写清楚，下一个人会把它当成漏填的行补进去，钉死当场失效 |
| 新判据 `tokens-input-at-pinned-path` | 把「没写」和「写错地方」分成两个信号。合成一条的话，产品放错地方会显示成「黑名单判据坏了」——正是这两轮 $6.2 买到的那个误诊 |

三处都是**文本，一次没跑过**。下一次 `greenfield-originate` 实跑之前，别把「已钉死」读成「已生效」。

## 钉死之后第一次实跑：落点 0/3 跑偏，但 900 秒的墙先到了（2026-08-24，3 次 run / 42 分钟）

`--case greenfield-originate --ablation none --keep-temp`。只跑这一个 case、只跑 with 臂——
第 12 笔问的是「文件落在哪」，不需要 Δ，跑对照臂等于白花一倍钱。

```
run1  timed out 900s   turns=0  $0   score 0.63
run2  timed out 900s   turns=0  $0   score 0.50
run3  interrupted      turns=0  $0   score 0.50    ← 被外部 kill，不是超时
                                                     合计 2532s
```

⚠ **`turns=0 / $0.00` 是超时丢统计，不是真的没花钱。** 实际花费这一轮拿不到。
这个形状上一节已经预告过（「它下一次失败不会长成分数低，会长成 turns=0 的满分 run」）。

### 落点：判据说的和沙箱里的一致

不看判据的绿红，去三个 `--keep-temp` 沙箱里实际找了文件：

| run | `tokens.input.json` 实际落点 | `design.md` |
|---|---|---|
| 1 | `docs/ui-contract/tokens.input.json` ✓ | 没写出来 |
| 2 | **没写** | 写在根目录 |
| 3 | `docs/ui-contract/tokens.input.json` ✓ | 没写出来 |

**0/3 跑偏。** 写了这个文件的两次，两次都落在钉死的位置。
对照钉死之前那轮（2026-08-22）：三次里两次 `docs/ui-contract/`、一次仓库根。

样本很小，而且上一轮也是「两次 docs/」——**唯一的差别是这一轮没有一次选根目录**。
这是弱证据，不是结论；写下来是因为它是方向对的第一份数据，不是因为它够。

### 拆成两条判据这件事，第一次真跑就兑现了

run2 的读数：

```
✗ tokens-input-written         **/tokens.input.json missing
✗ tokens-input-at-pinned-path  docs/ui-contract/... missing
✗ no-framework-default-values  grader threw: path does not exist
```

两条同时红 = **根本没写**，而不是「写错地方」；第三条抛错的原因因此一眼可读，
不再像「判据坏了」。这正是 2026-08-22 两轮约 $6.2 买到的那个教训要防的东西，
而它在第一次有机会兑现的时候兑现了。

### 但这不是一次干净的测量

产物是被砍断的：两次没写出 `design.md`，一次没写出 `tokens.input.json`。
所以这一轮测到的是「被砍之前写完了什么」，**不是「产品能不能走完」**。

`timeout_seconds: 900` 上一节标成「已经临界」（900 超时 / 886 / 876），这一轮
**两次直接撞墙**。而且是这批改动之后撞的：`originate.md` 加了派生规则、色相依据、
默认色黑名单，`SKILL.md` 的完工清单多了 5 条——每次 run 的活变多了，墙没动。

**下一次量之前先抬超时**，否则花的钱是在测这堵墙，不是测插件。

### 顺带：per-skill 判据又抓到一次

run2 `skill-fired` ✓（Skill 调了 6 次）而 `design-skill-fired` ✗（`ui-contract-design` 0 次），
`design.md` 却照样写出来了、`naming-declared` 与 `no-literal-values-in-design` 照样过。
**通用判据看不见的那种失效，第二次出现**（第一次是 `greenfield-mobile` run2）。

## 抬到 1800 秒之后重跑：两次满分，第 12 笔结清（2026-08-24/25，$8.35 / 44 分钟 / 3 次 run）

同一条命令，只改了一个数：`timeout_seconds` 900 → 1800。

```
run1  score 1.00   $3.17   8/8 全绿
run2  score 1.00   $3.12   8/8 全绿
run3  score 0.25   $2.06   API Error: Connection lost mid-response ← 基础设施，不是超时
                                              合计 2627s · $8.35 · PASS 67%
```

**一次都没超时。** 上一轮两次撞 900 秒的墙，抬到 1800 之后墙不在路上了。

### 第 12 笔结清：落点钉死生效

结清条件写的是「一轮**不超时**的 run 里 `tokens-input-at-pinned-path` 与
`tokens-input-written` 同时为绿」。**两次都满足**，而且是在沙箱里核对过的，不是读判据行：

| run | `tokens.input.json` | `design.md` | 判据 |
|---|---|---|---|
| 1 | `docs/ui-contract/` ✓ | 有，hex **0 处** | 8/8 |
| 2 | `docs/ui-contract/` ✓ | 有，hex **0 处** | 8/8 |
| 3 | 没写 | 没写 | 连接中断，产物为空 |

run3 不构成反证：它的错误是 `API Error: Connection lost mid-response`，
**agent 一个字都没写出来**（沙箱里只有 `layout.md` 和 `config.md`），
这是基础设施掉线，不是产品行为。

### 上一轮那些红，确实是被砍断造成的

`design-md-written` / `naming-declared` / `no-literal-values-in-design`
上一轮各红过一次，当时记的是「产物被砍断，不是产品的问题」。这一轮两次干净 run 里
**三条全绿**，那个判断得到了证实——它此前是推断，现在是量到的。

### 没有机检的那一格，产物自己做对了

`hue-basis-stated` 已删（判据分不开对错），所以色相依据从此靠评审。run1 的 `design.md`：

> ### 🌡 强调色色相的依据：邻接避让
> …本产品用**邻接避让**来关上它：这是内部工具，团队成员同时开着的是邮箱、日历、代码编辑器…
> 本产品的强调色**刻意取在那一段之外**，并把饱和度压低…
> ⚠ 依据说到这里为止，**不写色相名、不写色值**——具体落在哪里由 `tokens.input.json` 承载…
> 本文档不写字面颜色，**解释一个选择不构成例外**。

四类依据里点名了用哪一条、给出了这个产品身上说得出名字的理由、
并且主动守住了「说明依据不许带字面值」那条后加的规矩。
连同之前六份，**产物在这一格上累计 8/8 合格，而判据当初读到的是 1/3** ——
再一次说明删掉它是对的：不分黑白的判据比没有判据更坏。

`tokens.input.json` 的开头也写着身份声明，是不变量 19 要求的那句的自然语言版：

> 旋钮被停在哪里的工作记录，不是规范。与 token 文件冲突时，token 文件赢。键名来自 design.md 的声明表。

### 一个要改的估算：完整 run 比截断 run 贵一倍

此前所有单价都是**从截断的 run 上算的**。一次真正跑完的 `greenfield-originate` 是
**约 $3.1**，而此前外推用的是 $1.3/run。

于是「三个用例全跑 14 次 run ≈ $18.2」这个数**偏低**，
按 $3.1 重算大约是 **$43**。这不是本轮实测（本轮只跑了一个 case 一个臂），
是把新单价代进旧算式——**标出来是为了不让 $18.2 被继续当成预算**。

## 刻意没有覆盖的

只机械化了 2 个场景。以下四条**全程无人守**，是明确接受的代价：

- 「不把参考产品的具体 IA 写成普适真理」——本 plugin 自称最重要的一条
- 对非技术用户的表现（急性子、不懂技术的店主那类）
- 内容站 / 文档站形态
- **决策树追踪的质量**——追得够不够狠、每一行有没有真的落到叶子、有没有事后补写成看起来很完美的样子
- **`ui-contract-wireframe` / `ui-contract-assets` / `ui-contract-enforce` 的产物**——没有一条判据
  看过它们。这在 2026-08-26 之前就已经是事实（`greenfield-mobile` 的运行确实会走到那里，
  只是走过去写出来的东西无人观测），现在把它写下来，并且它**变贵了**：见下一节

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

官方规则（`docs/reference/plugin-eval.md` § Graders）：`arm: with-only`，**以及每一条不写
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

## 2026-08-26：一次 `--keep-temp` 的测量，和它推翻的三件事

命令：`claude plugin eval . --case greenfield-mobile --runs 1 --ablation none --keep-temp
--scaffold --allow-tools Write Edit --max-cost-usd 3`。
实际 **1359 秒 / $5.02**（`--max-cost-usd` 是**每次 run 之前**检查，单次 run 超了拦不住——
$3 的上限没有起作用，这一点值得下次估算时记住）。

跑的目的只有一个：issue #14 断言「技能正文越长 → 读进去的越多 → 越慢」，而在此之前
**从来没有量过一次运行的 token 构成**。

### token 账

| | tokens |
|---|---|
| `output_tokens` | **88,727**，其中 `thinking` **36,470**（41%） |
| `cache_creation_input_tokens` | 153,976 |
| `cache_read_input_tokens` | 2,524,485 |
| `input_tokens` | **54** |

**输入几乎全部命中缓存。**「技能正文被读进上下文」的代价落在那 154k 一次性的
`cache_creation` 上；墙钟和钱的大头是输出。issue #14 的因果链在**被测的这条链上**不成立。

### 推翻一：`Skill called Nx` 测的不是链条长度

这次运行 **`ui-contract-layout` 的 Skill 工具一次都没被调用**（`layout-skill-fired` 判 0x），
但 `layout.md` 照样写出来了，39.8 KB。trace 里看得见它怎么做到的：先试
`ls -R .../skills/ui-contract-layout`（被权限拒），再 `Glob skills/ui-contract-{layout,design,…}/**/*`，
然后用 `Read` 逐个读了 12 个技能文件。

原因写在 harness 文档里：`--plugin-dir` 指向你**真实的 checkout**，而
*an unscoped `Read` can read absolute host paths*。这不是沙箱漏洞、也不是 eval 的人造问题——
真实用户机器上 `~/.claude/plugins/…` 同样可读。

**后果**：`skill-fired: 7x / 9x / 5x` 这个数在 issue #14 的表格里被当成「链条走了几步」引用过，
那个读法是错的。它测的是**这一次 agent 选择路由还是选择自己读文件**。凡是靠它推出来的结论都要重算。

### 推翻二：per-message 的 token 归账拿不到

想法是从 `trace.jsonl` 里按消息把 output token 分摊到「写产物 / 思考 / 对话」三档。**不成立**：
流里每条 assistant 事件的 `usage` 是增量快照，全部加起来是 **333**，而 `result` 事件是 **88,727**。
只有 run 总量是可信的。

所以「哪一段在烧输出」只能按**字符数**估，明说是估：写产物 55,865 字符 ≈ 36% 的输出 token，
其中 `layout.md` + `design.md` ≈ 26%。`thinking` 那 41% 是实测值，也是最大的一档，
而它和产物大小无关。**不要为此造一个"看起来在量 token、实际在量字符"的器具**——那正是本仓库
反复栽的形状。

### 推翻三：`no-desktop-skeleton` 是指纹断言

见该判据自己的正文。这次运行**没有超时**（1359s 自然结束，`stop_reason: end_turn`）仍然挂它，
所以此前「被砍在修正之前」的解释也不成立。判据已于同日换锚。

### 产物时间线（供下次估算）

| 秒 | 产物 |
|---|---|
| 624 | `docs/ui-contract/config.md` 6.2 KB |
| **880** | **`layout.md` 39.8 KB** ← 900 秒的墙就在它后面 20 秒 |
| 1070–1216 | `design.md` / `tokens.ts` / `tokens.input.json` / `regions.tsx` / `assert.ts` ← 无判据观测 |

到 `layout.md` 落盘为止的 71% 时间里只产出了一份 6.2 KB 的 config。

### 记分口径变化

`greenfield-mobile` 新增 `no-work-beyond-layout`（计分，`arm: both`），计分判据 **4 → 5 条**。
`0.75 = 3/4` 这类历史读数从此不可直接跨版本比——与 `decision-tree-total` 被删那次同一种断裂。

### 一条**没有**执行的改动，和不执行的理由

曾经定过把 `greenfield-mobile` 的 `max_turns` 砍到 15，理由是「7 次 Skill 调用就是最小链，
15 是两倍余量」。**那个前提被推翻一否定了**——7 这个数不是链条长度。实测这次
`num_turns = 47`，`layout.md` 出现在第 22 个工具调用之后。砍到 15 会在产物落盘前杀掉运行，
正好制造出要消灭的那种读数。`no-work-beyond-layout` 用产物存在性达成同样的目的，没有这个风险。

## 2026-08-26（二）：wireframe 链第一次被量

这条链**从来没有被测过**，而它在 `enforce-on-product-source-and-workbench` 这个 PR 里从
6,370 词涨到 11,558 词（+81%），是整个 PR 增量的 38%。

用 `testing/evals-probe/wireframe-probe`（**探针，不在 manifest 的 eval 目录下，
网关 3 不会跑它**）。scaffold **取材于 `examples/admin-console/`**，不自带产物副本——
副本是结果，探针是器具，同一条理由写在 `ui-contract-wireframe` 的实现指南里。
（这次测量跑的是从沙盒拷出的 React Native 产物；改为取材示例之后起点变成 React，
所以下一次的数与本节的 1510s / $9.39 **不可直接对比**。）
`--runs 1 --ablation none --keep-temp`，**1510 秒 / $9.39**。

### 与 layout 链的对照

| | `greenfield-mobile`（layout） | `wireframe-probe` |
|---|---|---|
| 墙钟 | 1359s，自然结束 | 1510s，**撞 `max_turns=60`** |
| 花费 | $5.02 | $9.39 |
| `output_tokens` | 88,727（thinking 41%） | 120,086（thinking 31%） |
| `cache_creation` | 153,976 | 215,339 |
| `cache_read` | 2,524,485 | **8,466,191** |
| 产出 | 55,865 字符 | 136,856 字节 |

**这条链在 60 轮里跑不完。**它按 `spec-before-code` 的规定五次回改 `layout.md`（造线框
暴露规范的洞 → 先改文档），那是正确行为，也是成本的一部分。

### 器具的双份计费，量到了

| 模板 | 读进 | 写出 |
|---|---|---|
| `inspect.tsx.template` | 24,434 B | **26,500 B** |
| `wire.tsx.template` | 9,030 B | 21,223 B |
| `check-colours.sh.template` | 9,263 B | 8,054 B |

`inspect.tsx` **写出来的比模板还大**。器具是这个插件里唯一一类在输入和输出各计一次的内容。

### 插件的开发史进了用户仓库

生成出来的工程里：

```
src/inspect.tsx:267  * 写入者，所以两个开着的编辑器不会互相覆盖。见 ADR-0007。
src/wire.tsx:157     * 就是第二个值权威。见 ADR-0007。
```

模板里有 15 处这样的引用（不变量 34 现在把它们打出来），两处活着到了用户那里，还被翻译成了
中文——指向一份用户没有、也无从获取的文档。**这不是推断，是这次实跑的产物。**

### 这次测量做不到的

没有授予 `Bash`。线框的完工清单要求跑 dev server、装依赖、执行 `check-colours.sh`，
授予它意味着在沙箱里执行任意 postinstall。所以量到的是**读 + 写**那条路径，
「装了跑起来要多久」仍然没有数。

## 2026-08-26（三）：通读 `testing/` 找出的三处失效断言

前两轮改动都是先动手后读，各留下几处要回头修的东西。这一轮先把 `testing/structure/`
读完再动，找到的三处都属于同一类：**看起来在检查，实际打不中**。

### 一、`invariants.sh` 的判词打印在最后三条检查之前

第 32、33、34 条被历次追加到了 `printf '结构不变量全部通过'` 那一行**之后**。
后果：这三条里任何一条失败，输出仍然先打一行绿色的「全部通过」，红叉跟在它下面。
退出码是对的（实测 1），`run.sh` 也照样红——**骗的只有读输出的人**。

这个会话里它已经骗过一次：修第 32 条时的输出正是

```
结构不变量全部通过
  ✗ 这些检查没有任何用例: [34]
```

三个兄弟脚本（`invariants-effectiveness.sh` / `audit-effectiveness.sh` / `preflight.sh`）
的判词都紧贴 `exit $FAIL`，只有这一份错位。判词已移到 `exit $FAIL` 之前。

### 二、「规范文档里什么算一个色值」有四个答案，四个都漏 `#fff`

| 谁 | 原来的模式 |
|---|---|
| `audit.sh` 检查 4（判 `design.md`） | `#{6}` + oklch/oklab/hsla?/lab/lch/rgba? |
| `no-literal-values-in-design`（三份拷贝） | `#{6}` + oklch/rgba? |
| `no-visual-values-in-structure`（判 `layout.md`） | `#{6}` + font-size/border-radius/box-shadow |
| `$COLOUR_NOTATION`（判源码，不变量 33 三方比对） | `#{3,8}` + 全部函数记法 + Tailwind 色阶 |

前三者全部只认 6 位十六进制，所以 **`design.md` 里写 `#fff` 是绿的**。而不变量 33
存在的理由正是防这个——它比对三份 `COLOUR_NOTATION=` 赋值，**看不见同文件里内联的第四份**。
配套的有效性用例注入的是 `#445566`，所以它「能失败」——只对那一种写法。

改法：三处规范文档检查统一放宽到 `#{3,8}` 并补齐函数记法，**刻意不带 Tailwind 色阶**——
规范的反模式行里会**提及** `bg-blue-500`，而分不开提及与使用正是 `no-desktop-skeleton`
栽过的那个坑。

**假阳风险是实测的，不是推的**：在 11 份真实产物上，`{3,8}` 相对 `{6}` **零额外命中**，
且这些产物里一个 markdown 锚点链接都没有（`#added`、`#face` 这类词是理论上的假阳源）。
两个 grader-check 夹具的判定也不变：正样本仍 0 处，负样本仍 3 处。
新增用例 `检查 4 · 三位十六进制`。

### 三、不变量 5 与 7 是词表/正则，却没写「什么能漏过去」

第 21、25、26、27、28 条都明写了自己抓不到什么；只有这两条没写。已补：

- **第 5 条**（原语层不含 UI 词汇）：`token`/`spec`/`contract`/`skin` 一律走得过去，
  换个说法（`the allow-list of names`）也走得过去。它挡的是照抄，不是决心。
- **第 7 条**（包内链接不断）：正则 `\]\(([^)#:]+)\)` 把带 `#` 锚点的链接**整条跳过**，
  所以 `[x](nonexistent.md#foo)` 是绿的。目前包内一处带锚点的链接都没有，这个洞现在是空的。
