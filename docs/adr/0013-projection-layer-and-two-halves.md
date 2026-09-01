# ADR-0013 · 线框是每一半末尾重建的投影层，视觉半场是另一条链

| | |
|---|---|
| **状态** | **Accepted**（2026-08-27 定案） |
| **日期** | 2026-08-27 |
| **相关** | [ADR-0001](0001-plugin-positioning-and-architecture.md)（依赖图：`wireframe` 依赖 `assets`）· [ADR-0010](0010-asset-layer-ports-audit-does-not.md)（资产层）· [ADR-0011](0011-workbench-and-originate-writes-the-token-file.md)（排练进工作台）· [ADR-0012](0012-colour-exemption-is-a-file.md)（颜色豁免的锚是文件） |
| **取代** | 无。ADR-0001 的依赖图不变——本记录重新解释 `wireframe → assets` 那条边的**性质**，不改它的方向 |

> 本 ADR 记录**为什么这么选、排除了什么、代价是什么、什么条件下复议**。
> 规则落地后住各包 `SKILL.md` 与 `skills/ui-contract-glossary/SKILL.md`，本文件只指向，不复述。

---

## 背景：一次实测里，490 行没人要过的视觉规范

issue #16。`greenfield-mobile` 的用户只说了一件事——「先把界面结构的规范定下来再动手」。
2026-08-27 带插件那一臂交回的产物里，除了 `layout.md`，还有一份 **`design.md`，
29,801 字节 / 492 行**。判据 `no-work-beyond-layout` 首次测量即挂。

**真正的问题不是「多做了事」，是那 492 行的依据不存在。**
`skills/ui-contract-design/originate.md` 的准入条件点名了「你挑吧」这种输入，要求的是访谈定
品牌方向、并且**明确不许直接给一套默认色板**——理由写在那里：用户橡皮图章过的色板不再是他的
规范，而这正是整套方法要防的失败。那次跑没有任何访谈。所以交回去的不是好意，是**一批没有授权
的品牌决策被写成了规范**。「无人观测」不是伤害本身，是它至今没被发现的原因。

**排除掉的一种解释：不是「Skill 工具调多了」。** 2026-08-26 的实测里 agent **没有调用**
`ui-contract-design` 的 Skill 工具，而是用 `Glob` + `Read` 直接读了那个包的
`SKILL.md`、`originate.md`、`design-md-outline.md`，然后照样写了出来。它**读到了那张
precondition 表的全文**——包括不许给默认色板那一行——然后走了过去。

这条实测是本记录几乎每一个决定的根据：**一道下游的门，拦不住一个读得懂它的 agent。**

---

## 决策一：线框是**投影层**，不是链条上的一站

`skills/ui-contract-glossary/SKILL.md` 现在把线框描述成「可运行的低保真参考实现」——那是在
说**精度**。精度说明不了它什么时候该被重建，于是它被当成了 `assets` 之后的下一站。

> 线框是 `layout.md`、`design.md` 及两者 ADR 的**投影层**，随时可以重建。

它不站在 `layout → design` 那条线上，它架在两份规范**底下**。任一已接入的源变了就重投一次。

这条不是新概念，只是词汇表没收录：`skills/ui-contract-audit/SKILL.md` 的 exit 3 定义里
已经写着「`workbench` is excluded on purpose — **never having built a wireframe is a normal
state**」。体检单元一直按投影层在写，只有词汇表不知道。

## 决策二：投影的**唯一必需输入是 `layout.md`**，资产层是载体不是源

`design.md` 与相关 ADR 是**可选输入**：接上就一起投进去，没接上投影照样成立。

**关键推论：没有 `design.md` 的那个灰投影是完整的，不是半成品。** 灰不是风格选择，是可选源
没接上的直接结果；它是一个完整源的完整投影。半场划分能不能成立全在这一条——用户在交接时点头，
点的是成品，不是预览。

`skills/ui-contract-wireframe/SKILL.md` 的前置条件要求资产层存在，照字面与上一段冲突。解法是
**资产层根本不算一份源**：它是 `layout.md` §2 的编译期载体，投影经它读白名单，纯粹是为了不
产生第二份白名单。

> **约束（本记录新立）：资产层里不得存在任何 `layout.md` 没有条款支撑的东西。**

写成约束而不是记成现状，是因为本记录**亲手安排了一件将来会打破它的事**——决策七那笔借用的
到期条件是「`Shell` 落地即收回」，而 `Shell` 要装降级规则的实现。今天资产层确实干净，但那是
因为 `Shell` 还没写，不是因为有东西拦着。从「今天看起来对」推到「机制在工作」，这个推论在本
仓库错过三次（`CLAUDE.md` §What the invariants are protecting）。

## 决策三：两个半场是**两条链**，视觉半场**没有入边**

「交付 wireframe」这个说法作废。被提交、被评审、被点头的是 `layout.md` 一个东西；投影是**看它
的取景器**。这不是措辞洁癖：说「验收线框」会让用户去评审一个可丢弃物，而它下一次重建就换了样子。

**分隔不靠禁令实现，靠链条上没有那条边。** `skills/ui-contract/SKILL.md` 的箭头图里，
`design` 不再是任何东西的下一站，只能从路由表重新进入。根据就是背景里那条实测：**禁令能被
走过去，缺路不能。**

**「视觉那半」指的是 `originate`，不是 `align`。** 这一条是落地时量出来的，不是设计时想到的：
第一次实现把门一刀切在 `ui-contract-design` 入口，跑 gate 3 时才发现它会挡住 `existing-admin`
的 `existing-spec-slimmed-not-rewritten`——那个用例仓库里本来就有 `design.md`，要做的是**边界
对齐**（结构内容搬出去、留一行指针），而那件事早就有自己的授权：`setup` 第 1 问「已有的视觉
规范可以改吗」。两个分支要的是两种许可：

| 分支 | 对用户材料做什么 | 由什么授权 |
|---|---|---|
| `align` | 精简一份他已经有的文档 | 「已有视觉规范可以改吗」——它动别人的文件，但不发明任何品牌决策 |
| `originate` | 从无到有产出方向、尺度、值 | **范围授权**——这些决定得有人负责 |

拿范围授权去挡 `align`，挡掉的是结构那半本来就需要的清理：已有视觉规范几乎总混着结构内容，
不搬走就是两套词汇，而那正是 `align` 要防的失败，和半场划分要防的那个毫无关系。

配套两问，落 `skills/ui-contract-setup/config-template.md`（该包从四问变五问）：

| 问 | 问什么 | 为什么不能合并 |
|---|---|---|
| 范围授权 | 这次做哪半 | `greenfield-originate` 的用户「两份都要」…… |
| 交接对象 | 交接之后谁接手 | ……但视觉那半得他自己答，队里没有设计师 |

合并会造出一个洞：拿到「两半都做」的授权，却不知道视觉那半该问谁，于是 agent 自己替他答——
**那正是背景里那 492 行的成因**。

## 决策四：资产层在结构半场里落工作台，点头后再迁生产树

`skills/ui-contract-assets/SKILL.md` 开头写着它产出的是 **production code**、「maintained for
as long as the product lives」。资产是资产，投影是投影，两者性质相反：投影可以丢掉重生，资产
不能。所以把资产层写进用户的生产树**需要授权**，而结构半场里没有拿到。

结构半场结束时被提交的因此只有 `layout.md` 一个文件，其余全在 `.ui-contract-local/`。

代价核过：`skills/constraint-by-types/SKILL.md` 那层「编译期挡住违规」只有在**有业务代码可挡**
时才兑现，而结构半场结束时一行业务代码都没有，所以暂缓进生产树不损失任何已经存在的约束力。

## 决策五：`enforce` 拆两趟

`skills/ui-contract-enforce/SKILL.md` 自己写着「There is no wireframe precondition」，所以
Entry 层（repo-root `CLAUDE.md`）只依赖 `layout.md`，结构半场里就装；Compile 层与资产边界要求
「installed on **the product source tree**」，等迁进生产树之后。

**两个半场之间隔得越久，Entry 层越该早装**：用户可能几周不回来，这期间任何 agent 碰界面都得有东西告诉它
先读 `layout.md`。

## 决策六：⏳ 仍归 `design`，投影带着未结算的 ⏳ 先建

`skills/ui-contract-layout/SKILL.md` 标 ⏳ 的那些数（面板固定宽、最小可用宽）仍由视觉那半结算。
投影可再生，所以在 ⏳ 未结算时先建它**成本接近零**——数改了重投一次即可。

方向永远是 `spec → 投影`，从不反过来。投影可以**暴露** ⏳ 的数不成立（那是
`skills/spec-before-code/SKILL.md` 已有的纪律），但它不是那个数的出处，也不是证据；答案连同
理由回 `layout.md`。⏳ 那一行要换标记：「等视觉给数」和「视觉给的方向被结构否了」对下游是不同
信息，同一个标记扛两种意思，`design` 就分不清该填一个数还是重谈一个方向。

`ui-contract-design` 的 ⏳ 一节**保留结算职责**，改的是另一件事：原来那张「同一个人 → 把 ⏳ 折进
这次访谈 / 不同的人 → ⏳ 变成交接单」的二分表**塌成一支**。两个访谈分属两个半场，折不进去，所以
⏳ 列表**永远**是带进视觉访谈的一份清单；软交接与硬交接的区别只在**什么时候**开始那场访谈，不在
怎么开。（`testing/evals/greenfield-originate` 的 scaffold 会交一份 ⏳ **已结算**的 `layout.md`，
那是为了把该用例限定在视觉起源上，是夹具的性质，不是 `design` 的契约。）

## 决策七：两笔具名豁免，各带到期条件

| # | 豁免 | 到期条件 |
|---|---|---|
| 1 | 降级规则的实现借住线框——它被判定属于资产层，只因为资产层还没有 `Shell` 来装 | **`Shell` 落地即收回。** 收回时必须先在 `layout.md` 里有对应条款（决策二的约束） |
| 2 | 「投影 ADR」这次只做**不许违反**（ADR 记为排除的形态不得出现在投影上），不做**必须显示** | 标注层能读 `docs/ui-contract/adr/` 时收回。届时线框目录 `CLAUDE.md` 里那张「刻意的取舍」表**改为从 ADR 推导**——它今天是手写的，等于线框对「什么是刻意的」持有第二份真相 |

**不建集中欠账表。** 一张手工维护的清单摆在说同一件事的技能文本旁边，就是第二个真相来源，
`CLAUDE.md` 开篇点的正是这个形状。两笔各自在所在包**双向记**（`assets` 与 `wireframe` 已经
在为第 1 笔这么做），到期条件住这里。

---

## 排除的备选

| 排除的 | 为什么 |
|---|---|
| **把「不许往下走」写成 `ui-contract-wireframe` 的一条完工项** | 下游单元自我克制，背景里那条实测已经证伪过一次。同一种赌注不下第二次 |
| **加强 `ui-contract-design` 的 precondition 措辞** | 同上。agent 读过全文才走过去的，问题不在措辞强度 |
| **把「design 在投影之后」写成 precondition（线框不在盘上 → 停）** | **不可能成立。** 线框默认在 `.ui-contract-local/wireframe/`，而 `ui-contract-setup` 要求为该目录加 `.gitignore` 行——于是**任何一次全新 clone 之后盘上必然没有线框**，这道门会对每一个正常项目误挡。正是 `CLAUDE.md` 记的第二类事故（一道门少写一个限定词，永久挡死一整类正常项目） |
| **把结构半场砍到只剩 `layout.md`，`assets` 与投影一并归第二条链** | 那样交接时交回的只有一份 Markdown，用户没有可看的东西；投影是他判断结构成不成立的唯一手段 |
| **资产层直接进生产树，理由是「它是 `layout.md` 的机械投影」** | 这个理由站不住：资产层是长期维护的资产，投影是可丢弃的。两者性质相反，把它们混成一类是本次讨论里最贵的一次纠正 |
| **Compile 层装在工作台的资产层上** | 本仓库量过：`admin-console` 例子里 `PageWithInspector`、`TableColumnKind`、`InspectorKind`、`PageKind` 全声明在线框里，每一个都是 `layout.md` 的条款，**没有一个到达过一行生产代码**。装在工作台上的编译期约束会绿得很好看，守的是一个下周就删掉的目录 |
| **把密度用的真实文案写进 `layout.md`** | 内容不是结构；`layout.md` 只装换皮不变的东西。改记成一份**输入记录**（照 `tokens.input.json` 的形状：不提交、不是权威、冲突时不算数），让重投可复现 |
| **`design.md` 落地后由 `design` 自己回去接资产层** | 破坏分工：资产层消费值不产出值，`design` 产出值不碰资产层，两边各自都明写过。改为 `design` 完工清单加一条**指路**，由 `ui-contract-assets` 再跑一趟——它的门里已有「`layout.md` 和 token 文件都在 → 正常路径，消费 token 文件」那一行，不用新机制 |
| **靠 `ui-contract-audit` 报出「资产层还没接 token」** | 体检是「几个月后测漂移」，用它报「这一步还没做完」会把两个概念混成一件事，而 glossary 里专门有一节讲这两个被混过一次 |

---

## 知道要付的代价

1. **尺子又换了，读数跨不过这次改动。** `testing/evals/greenfield-mobile/graders/` 从 7 条判据
   长到约 11 条：判据 `no-work-beyond-layout` 作废（名字已不成立——「beyond layout」的东西现在
   有一半是**该做的**），换成三条禁令（`design.md` / token 文件 / 资产层进 `src/`）加四条达成
   （资产层在工作台、投影已生成、Entry 条款进了 repo-root `CLAUDE.md`、`.gitignore` 有那一行）。
   `testing/evals/README.md` 里 2026-08-27 的读数因此作废，要重测。**口径**：$2.60 是**单次
   run** 的价，不是一轮——`--runs 1 --ablation with-without` 是 3 用例 × 2 臂 = 6 次 run，
   实测 $15.62 / 4410 秒；全量约 $36。
2. **`.gitignore` 那条判据必须用 `regex`，不能用 `file_exists`。** 后者只数本次跑**新建**的
   文件，而往一个已存在的 `.gitignore` 里加一行是 `Edit`——判据会**绿着**永远抓不到。这正是
   `ui-contract-setup` 点名过的那个事故（「填了工作台那一格记的是意图，`.gitignore` 才是执行」），
   现在连守它的判据都会踩同一个坑。
3. **「有没有正确地在结构半场收尾」是行为不是产物，只能由 judge 判据守，而它可能分不开。** 一次正确的收尾，和一次正好
   在写 `design.md` 之前撞上 `timeout_seconds` 的跑，留在盘上的东西可以完全一样——这不是假想，
   `testing/evals/greenfield-originate/prompt.md` 的注释里记着三次 run 两次撞墙、产物被砍断。
   用 `regex` 匹配收尾话术是**锚在措辞上的判据**，换个拼法就绿着失效。所以用 `llm`，**但先花
   $0.74 过 `testing/grader-check/` 的正负夹具再决定是否上**：前车之鉴是判据 `decision-tree-total`
   分不开「追了」和「没追」，在记分板上看起来守了三个月。
4. **`.ui-contract-local/` 现在装三样东西**（资产层、投影、输入记录）。工作台从「排练场」变成
   「结构半场的全部产出」，是本次唯一真正变复杂的地方。
5. **`config.md` 的 `asset-layer` 一格从「事实」变成「事实 + 待办」**（暂驻工作台 + 目标路径）。
6. **`design: none yet` 从过渡态变成一半项目的稳态，脚本已经接得住，但它自己写明的漏口跟着变
   常见。** `skills/ui-contract-audit/assets/audit.sh.template` 里 `none yet` 已经是合法值、
   不触发 exit 3——所以**不需要补哨兵**。变的是风险等级：那段注释自己写着「**What gets through:
   a translated placeholder** —— 写 暂无 而不是 `none yet`，它会被当成路径、不存在、于是 exit 3
   指着那一格」，而 paths 表**按交付语言书写**。改动之前这一格几分钟后就被真路径填掉；现在它
   要在那儿留几周甚至永远，写的人正好是母语非英语的那一位。要做的是两件小事：
   `skills/ui-contract-audit/SKILL.md` 的「deliberately **not** exit 3」那张表补上 `none yet`
   一行（今天文档的覆盖面比脚本窄），以及 `skills/ui-contract-setup/config-template.md` 里把
   「这一格是 ASCII 的 `none yet`，不翻译」写成硬要求而不是默认值说明。
7. **`greenfield-originate` 要加一份 scaffold**（照 `testing/evals/existing-admin/scaffold.sh`
   的形状），只 scaffold `layout.md` 且带一份**已结算**的 ⏳。不加的话它要走四站，而 1800s 的墙
   已经是抬过一次的。加了它才名副其实地只测视觉起源。

---

## 复议条件

- **`Shell` / `Slot` 落地** → 第 1 笔豁免到期，同时检验决策二那条约束是否真的被遵守。若 `Shell`
  带进了 `layout.md` 没有条款支撑的东西，决策二失效，投影「只投 `layout.md`」这句话跟着失效，
  半场划分、重建、灰投影完整性三件事的共同前提一起松动——那时要新立记录，不是改这一份。
- **`llm` 判据在 `testing/grader-check/` 上分不开正负夹具** → 决策三的核心行为回到无人守状态。
  那时必须在 `testing/evals/README.md` 里明说这条无人守，而不是留一条看起来在守的判据。
- **实测出现「交接之后用户再也不回来」成为多数** → 说明视觉半场的重新进入门槛过高，
  决策三的「画断链条」要换成别的形状。
- **有人报告资产层留在工作台期间被误删/被遗忘** → 决策四的分级要重新权衡。
