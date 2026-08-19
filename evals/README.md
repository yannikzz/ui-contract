# Eval 场景

两条起点各一个，覆盖 `ui-contract` 的两大场景：

| 用例 | 起点 | 验的是 |
|---|---|---|
| `greenfield-mobile` | 0-1 线（一句话想法，无代码无稿） | 不把桌面端的骨架套到手机上；决策树是全函数 |
| `existing-admin` | 治熵线（有前端代码 + 已有 token） | 先跑 baseline 再写规范；不凭空发明区域树 |

跑：

```sh
CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
  --ablation with-without --scaffold --allow-tools Write Edit --max-cost-usd 20
```

四个开关缺一不可：

| 开关 | 为什么必须 |
|---|---|
| `CLAUDE_CODE_WALNUT_SPIRE=1` | `plugin eval` 被一个默认关闭、按组织灰度的 feature gate 挡着。这个变量是官方给收不到灰度的机器留的口子；**不要设在仓库的 `.claude/settings.json` 里**，committed 的值通常不生效 |
| `--scaffold` | `existing-admin` 靠 `scaffold_script` 造 fixture 仓库，默认**不跑**（它会以你的身份执行作者提供的 bash）。不加这个开关，治熵线用例面对的是空目录 |
| `--allow-tools Write Edit` | `Write` / `Edit` 是 gated tool，`allowed_tools` 里列了还不够。不给，agent 写不出规范文件 |
| `--max-cost-usd` | 单次 run 约 $0.6–3.7。两用例两臂共 8 次 run，实测总额 $10.4——给 $10 会被砍在半路，见第 11 条 |

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

**5. 默认 `timeout_seconds: 300` 对这条流程太短。**
带插件的那一臂要跑 setup → 访谈 → 写规范，实测被 300 秒砍在写文件之前，`file_exists` 判据因此必挂。写成 `timeout_seconds: 900`。

**6. `focus: files` 只给 judge 一份文件清单，不是文件内容。**
判内容要写成 `focus: {source: file, path: <path>}`。用 `files` 判内容会得到三票 FAIL——judge 看到的是一串路径，它没法从路径判断白名单有没有「禁止放」那一列。更坏的是它在**没有任何文件**时也可能空集通过，产生假阳性。

**7. `scaffold_script` 是 case 目录下的**路径**，不是内联脚本。**
写成内联会被当文件名去 `open()`，报 `ENAMETOOLONG`，且 $0.00 静默失败。另外有 `case.yaml` 时 `schema_version` 必须是 `"1.1"`。scaffold 有 2 分钟上限、最小化环境、无密钥。

**8. llm judge 在长输入上噪声很大。**
产物动辄一两万字符，harness 会在失败行后面主动注记 `long file (17165 chars); llm judges are noisy on long inputs, prefer a regex grader for large artifacts`。实测：同一份写得对的 `layout.md`，llm judge 三票 FAIL。

**凡是能机械判定的判据都用 `regex`**，`target: {source: file, path: …}`，`match: contains | not_contains | count:N`。只有真正需要语义判断的（决策树是不是全函数、区域描述是"放什么"还是"是什么"）才留给 llm——而那几条要接受它天然带噪。

这条和 `ui-contract-audit` 那边的教训是同一个：**能机械判的就别交给判断，能判断的就别硬凑正则。** audit 那边是反方向踩的——把尺寸值交给正则，四条命中全是误报。

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

**十二个坑的共同点**：这套 eval 是在 `plugin eval` 还被 gate 关着的时候盲写的，八个假设全错，而且**每一个都朝着惩罚插件的方向错**。这本身就是一条结论——盲写的 harness 不要用来判断质量，只能用来发现自己哪里写错了。后加的四条（9-12）是两次实跑量出来的，前两条**朝相反方向错**：一条让做对的臂扣分，一条让什么都没做的臂加分。

## 一条量出来的产品缺口（不是 harness 坑）

`decision-tree-total` 在 `greenfield-mobile` 的**两次实跑共六次 run 里全部不通过**——六次一致，不是噪声。查产物：决策树本身是像样的，兜底也确实是 stop 而不是某个真实区域（判据 1 满足），但 `layout.md` 里**没有任何追踪痕迹**，判据 2、3 判的正是"这棵树被敌意输入和普通输入追踪过"。

根因是 grader 与单元之间的契约没对齐：`ui-contract-layout` 的完工清单要求 agent **做**这两轮追踪，但没要求把结果**写进规范**；grader 的 focus 是文件，只能看见产物。

两边都能改，但把追踪写进产物更有价值：一棵"被敌意输入验过"的树，如果验证过程不留痕，下一个改它的人不知道哪些边界是刻意设计的——这和附录 B 要求记下被推翻的结论是同一个道理。**这个缺口不是拆包重构引入的，改它是一次独立的产品改动。**

另有一条量出来的**稳定性**数据，不是缺陷但值得记：`no-desktop-skeleton` 在六次 run 里挂过一次（第二次实跑的 run 1）。这条判据刻意严格到「连提都不能提」——手机端规范里出现「侧边栏」，哪怕是在否定它，也算参照系跑偏。所以 5/6 是这条纪律当前的实际稳定度，不是 6/6。

## 刻意没有覆盖的

只机械化了 2 个场景。以下三条**全程无人守**，是明确接受的代价：

- 「不把参考产品的具体 IA 写成普适真理」——本 plugin 自称最重要的一条
- 对非技术用户的表现（急性子、不懂技术的店主那类）
- 内容站 / 文档站形态

补它们要新增用例，成本随场景数线性涨。
