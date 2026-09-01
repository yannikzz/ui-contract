#!/usr/bin/env bash
# 造出「结构那半已经做完」的状态，让这个 case 只测视觉起源。
#
# 为什么要它：停点之后，`ui-contract-design` 是**重新进入**的一站，它的输入是 `layout.md`，
# 不是投影（投影是可丢弃的排练物，scaffold 一份不提交的东西没有意义）。此前这个 case 从零开始，
# 一半时间花在写结构规范上——而 1800 秒的墙已经是从 900 抬上来的，三次 run 撞了两次。
#
# ⏳ 在这份夹具里是**已结算**的。那是夹具的性质，不是 `ui-contract-design` 的契约：真实项目里
# ⏳ 仍由视觉那半结算，这里填好只是为了把这个 case 限定在「起源一套视觉」这一件事上。
set -eu

# `src` 在配置表里被声明为生产源码树，而它进 `ui-contract-audit` 的路径存在性检查
# （LAYOUT/DESIGN/TOKENS/SRC/REGION_TYPE 那一组）。声明一个盘上没有的路径 = exit 3，
# 所以这里真的把它建出来，空目录即可——这个项目确实一行业务代码都还没写。
mkdir -p docs/ui-contract src

cat > layout.md <<'LAYOUT'
# 结构规范 — 招聘流程看板

> 本文件管**换皮不变**的东西：区域树、页型、落位规则。颜色、字号、圆角、间距一律见 `design.md`。

## §1 落位决策树

新需求进来，从这里走。落到恰好一个区域名，或者落到 §9 的显式停点。

1. 它是**一个候选人**的信息或动作吗？
   - 是 → 它需要在不离开列表的情况下看到吗？ → 是：`focus-panel` ／ 否：`detail-main`
   - 否 → 进 2
2. 它作用在**一批**候选人上吗？ → 是：`list-toolbar`
3. 它是跨候选人的**全局设置或账号**级别的东西吗？ → 是：`settings-page`
4. 它是需要打断当前工作的**一次性流程**吗（安排面试、批量导入）？ → 是：`overlay`
5. 以上都不是 → **停 → §9**，不要自己挑一个区域

## §2 区域名白名单

| 区域名 | 允许放 | **禁止放** |
|---|---|---|
| `app-nav` | 顶层去处的入口，最多 5 条 | 任何针对单个候选人的动作；任何计数徽标以外的状态 |
| `list-main` | 候选人列表本体、排序、分页 | 单个候选人的详情字段 |
| `list-toolbar` | 作用于**一批**候选人的动作、筛选 | 只对一个候选人有意义的动作 |
| `focus-panel` | 当前选中候选人的**一个**切面 | 需要并列比较两个候选人的任何东西 |
| `detail-main` | 单候选人独立页的主体 | 列表级的筛选与批量动作 |
| `settings-page` | 账号、团队、通知、集成 | 任何和某个候选人有关的东西 |
| `overlay` | 一次性流程：安排面试、导入 | 需要和背后列表同时可见的任何东西 |

## §3 页型与结构参数

| 页型 | 带 `focus-panel` | 说明 |
|---|---|---|
| `list-page` | 是 | 列表 + 聚焦槽 |
| `detail-page` | 否 | 单对象独立页 |
| `settings-page` | 否 | 无聚焦槽，无批量动作 |

结构参数（**已结算**，原为 ⏳，由视觉那半在上一轮回答后写回）：

| 参数 | 值 | 结算依据 |
|---|---|---|
| `focus-panel` 固定宽 | 380px | 最长的一条评价摘要在两行内放得下 |
| 三栏最小可用宽 | 1120px | 低于此降级见 §5 |
| 单行候选人条目高 | 56px | 一行姓名 + 一行状态，加上下内边距 |

## §5 降级

窄于 1120px：`focus-panel` 收起为信号条，只留状态与一个展开按钮。
窄于 720px：`list-toolbar` 的批量动作收进一个动作菜单。

## §9 落不了位时停在这里

决策树走完没有落点，**不要挑一个最像的区域**。停下来，把这个需求写进本节的待决清单，
按 `spec-before-code` 走变更流程：先改本文件，再写代码。

## 附录 C · 决策树追踪

| 输入 | 走到 | 落点 |
|---|---|---|
| 「给候选人加一个标签」 | 1 → 是 → 不需要离开列表？否 | `detail-main` |
| 「批量拒绝」 | 1 否 → 2 是 | `list-toolbar` |
| 「显示团队本月面试总数」 | 1 否 → 2 否 → 3 是 | `settings-page` |
| 「并排比较两个候选人」 | 1 是 → `focus-panel` 禁止并列比较 | **停 → §9** |
LAYOUT

cat > docs/ui-contract/config.md <<'CFG'
# UI contract — configuration

## Starting point

| | |
|---|---|
| **Start** | A (greenfield) |
| **Identified from** | 空仓库，只有功能清单 |

## Paths (authoritative)

| Key | Artifact | Path | Default |
|---|---|---|---|
| `layout` | 结构规范 | `layout.md` | |
| `design` | 视觉规范 | none yet | |
| `tokens` | token 文件 | none yet | |
| `tokens-format` | token 文件格式 | none yet | |
| `src` | 生产源码树 | src/ | |
| `asset-layer` | 资产层（生产树） | none yet | 尚未授权迁入 |
| `asset-staged` | 资产层（暂驻） | .ui-contract-local/assets/ | |
| `workbench` | 工作台 | .ui-contract-local/ | |
| `wireframe` | 投影 | .ui-contract-local/wireframe/ | |

## Authorisations

| Question | Answer |
|---|---|
| 这次会话授权走多远——只做结构那半，还是两半都做？ | **两半都做**；结构那半已完成，本次做视觉那半 |
| 已有的视觉规范可以改吗？ | 没有已有的视觉规范 |
| 两份规范放哪、叫什么？ | 仓库根，`layout.md` / `design.md` |
| 投影放哪？ | `.ui-contract-local/wireframe/` |
| 资产层将来迁到生产树的哪里？ | `src/ui-contract/` |
| 停下来之后谁答视觉那半？ | **同一个人**（队里没有设计师，由提问的人自己答） |

## Not verified this round

| # | What was not verified | What it affects | How to clear it |
|---|---|---|---|
| 1 | 生产源码树目前是空的 | 任何读调用点的检查都没有对象可判 | 写了第一个功能之后重跑体检 |
CFG
