# Eval 场景

两条起点各一个，覆盖 `ui-contract` 的两大场景：

| 用例 | 起点 | 验的是 |
|---|---|---|
| `greenfield-mobile` | 0-1 线（一句话想法，无代码无稿） | 不把桌面端的骨架套到手机上；决策树是全函数 |
| `existing-admin` | 治熵线（有前端代码 + 已有 token） | 先跑 baseline 再写规范；不凭空发明区域树 |

跑：

```sh
CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
  --ablation with-without --scaffold --allow-tools Write Edit --max-cost-usd 10
```

四个开关缺一不可：

| 开关 | 为什么必须 |
|---|---|
| `CLAUDE_CODE_WALNUT_SPIRE=1` | `plugin eval` 被一个默认关闭、按组织灰度的 feature gate 挡着。这个变量是官方给收不到灰度的机器留的口子；**不要设在仓库的 `.claude/settings.json` 里**，committed 的值通常不生效 |
| `--scaffold` | `existing-admin` 靠 `scaffold_script` 造 fixture 仓库，默认**不跑**（它会以你的身份执行作者提供的 bash）。不加这个开关，治熵线用例面对的是空目录 |
| `--allow-tools Write Edit` | `Write` / `Edit` 是 gated tool，`allowed_tools` 里列了还不够。不给，agent 写不出规范文件 |
| `--max-cost-usd` | 单次约 $1–3，两臂两用例会翻倍 |

`--ablation with-without` 会**真的把插件摘掉**跑一遍对照臂。这修掉了历史上一个已知的测量假象：手工造对照组时，子 agent 的可用技能清单里仍带着本插件的完整 description，等于把架构泄露给了对照组。

## 两个 harness 坑（踩过，别再踩）

**1. 每条 prompt 都必须带「我时间紧，你按推荐的来，但把决策点列给我看」。**
技能的核心纪律是一次一问、等回答，而 eval 里没有人回答。漏了这句，带插件那一臂会停在一个访谈问题上，不带插件那一臂一口气吐完，**分数反而更高**。首次实跑就撞上了：with 0.00 / without 0.33 / Δ −0.33，全部由这一句的缺失造成，与插件质量无关。

**2. llm grader 必须写 `focus: trace`。** 默认是 `last_message`，只判最后一条消息。带插件的那一臂轮数多（实测 14 轮 vs 2 轮），产出散布在整条对话里，只判最后一条等于系统性地惩罚"会分步骤做事"的那一臂。

两个坑是同一件事的两面：**默认配置偏向一次性长答，而这个插件的价值恰恰在于不那样答。**

**3. prompt 描述的现状必须和 sandbox 的实际磁盘一致。**
eval 在一个空 git 仓库里跑。如果 prompt 说"我已经有十几个页面了"，而磁盘上一个文件都没有，`ui-contract-setup` 会**正确地发现这个矛盾并停下来问**——前置门就是这么设计的。于是它永远产不出规范，所有 grader 必然全挂，而这跟插件质量毫无关系。

第一版 `greenfield-mobile` 就犯了这个错：用例名是 greenfield，prompt 却描述了一个已存在的项目。**治熵线的用例因此需要 `scaffold_script` 造一个真的 fixture 仓库**，光靠 prompt 里口述代码是不行的——插件会去看磁盘，然后发现你在说谎。

**4. 写文件的工具必须显式授权，光写 frontmatter 不够。**
`Write` / `Edit` / `Bash` 是 gated tool：`allowed_tools` 里列了还不行，跑的时候要带 `--allow-tools Write Edit`。不给的话 agent 会正确地停下来说"写权限被挡住了，决策点先给你过目"——而任何判"产出文件长什么样"的 grader 必然全挂。

跑用例的完整命令因此是：

```sh
CLAUDE_CODE_WALNUT_SPIRE=1 claude plugin eval . \
  --ablation with-without --allow-tools Write Edit --max-cost-usd 10
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

**八个坑的共同点**：这套 eval 是在 `plugin eval` 还被 gate 关着的时候盲写的，八个假设全错，而且**每一个都朝着惩罚插件的方向错**。这本身就是一条结论——盲写的 harness 不要用来判断质量，只能用来发现自己哪里写错了。

## 刻意没有覆盖的

只机械化了 2 个场景。以下三条**全程无人守**，是明确接受的代价：

- 「不把参考产品的具体 IA 写成普适真理」——本 plugin 自称最重要的一条
- 对非技术用户的表现（急性子、不懂技术的店主那类）
- 内容站 / 文档站形态

补它们要新增用例，成本随场景数线性涨。
