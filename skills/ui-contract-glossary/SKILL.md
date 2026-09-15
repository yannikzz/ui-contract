---
name: ui-contract-glossary
description: The vocabulary of a UI contract - what the structural spec, the visual spec and the wireframe each own, the single cut between them (does it change when the brand skin changes), how to mark the few genuine coupling points, and the canonical term renderings. Use when another ui-contract skill needs to decide which document a piece of content belongs in.
---

# UI contract — vocabulary

This skill decides **which document a thing belongs in**. It produces no artifacts of its own.

**Any unit that would explain one of the terms below explains it by calling this one instead.** A definition restated in a consuming unit reads perfectly well and costs nothing until the two drift — and then nothing is comparing them. Terms may be *used* freely; what belongs here is what a term *means*, and which artifact owns the thing it names.

Nothing mechanical enforces that. Six of the ten `ui-contract` units currently wire to this one; the four that do not (`setup`, `baseline`, `enforce`, `audit`) have not been checked against the rule, so a blanket assertion would be guarding violations nobody has measured.

## What the artifacts own

Two dimensions, not one. **Owns** says what content belongs there; **Kind** says whether the
thing can be thrown away and rebuilt. Getting the second one wrong is how a rehearsal gets
treated as an authority, and how an asset gets written into somebody's product without asking.

| Artifact | Owns | Kind | Test |
|---|---|---|---|
| `layout.md` | **Structure**: region tree, column widths, page archetypes, extension-slot enumerations, content routing, switching rules | **Source — the single source of truth.** Not regenerable | Things that **do not** change when you swap the brand skin |
| `design.md` | **Visual**: type, color, shadow, radius, spacing scale, interaction-state styling, component variants — **as rules, not as values** | Source. Not regenerable | Things that **do** change when you swap the brand skin |
| `adr/layout/` · `adr/design/` | **Why** a rule was chosen, what was excluded, when to revisit — **never the rules themselves** | Decision source. Not regenerable | The same cut decides which of the two directories |
| Token file | The **values** those rules refer to. The single value authority in code | Source of values. Not regenerable | — |
| Asset layer | The allowlist as a type, the structural container, every other closed set the spec declares | **Asset** — production code, maintained for as long as the product lives. Not regenerable, and **writing it into somebody's tree needs their say-so** | — |
| Wireframe | **Nothing of its own.** It is the projection layer over the sources above | **Projection — rebuildable at any time**, and rebuilt whenever a source changes | — |

For what a decision record may and may not contain, call the Skill tool with "decision-record".

## The wireframe is a projection layer

Saying "low-fidelity reference implementation" describes its **fidelity**. That is not the
thing you need in order to know when it should be rebuilt, and without it the wireframe gets
treated as a station on a chain — something you arrive at, deliver, and leave behind.

> The wireframe is the **projection layer** over `layout.md`, `design.md` and their decision
> records. It can be rebuilt at any time, and is rebuilt whenever any connected source changes.

**The only required input is `layout.md`.** `design.md` and the decision records are *optional*
inputs: connected, they get projected too; absent, the projection still stands.

**So the grey projection is complete, not half-finished.** Grey is not a style choice and not a
placeholder — it is what a projection of a complete source looks like when an optional source
is not connected yet. This matters at exactly one moment: when the user is asked to sign off on
the structural spec, what they are looking at is a finished thing, not a preview.

**The asset layer is a conduit, not a source.** The wireframe reads the allowlist through it so
that no second allowlist comes into existence — that is the whole reason for the dependency, and
it does not make the asset layer an input to the projection. This holds only under one constraint,
and the constraint is the load-bearing one:

> **The asset layer must contain nothing that has no clause behind it in `layout.md`.**

If that ever stops being true, "the projection projects `layout.md`" stops being true with it,
and rebuildability goes with that.

## The one cut

**"Does this change when the brand skin changes?"** Changes → `design.md`. Doesn't → `layout.md`.

There is exactly one cut. Do not invent a second dimension to resolve a hard case — take the hard case back to this question. The same value living in two places is a drift source.

One consequence people miss: `design.md` holds **rules**, the token file holds **values**. `design.md` must not contain color values or size values; it writes "see the token file". This is the same shape as `layout.md` holding no visual values at all — the cut hasn't moved, there is just one more hop.

## Zero overlap, but don't claim absolute zero

Aim for zero overlap. **Do not claim it.** There are usually one or two genuine coupling points — a spacing value that determines how many grid columns fit, say; change one and you must revisit the other.

Handle those by **marking them explicitly on both sides**:

> ⚠ Changing this requires revisiting §X of the other spec — this is the only place the two specs are coupled.

Naming a coupling is far safer than declaring zero overlap and letting it drift silently.

## Do not copy someone else's information architecture

This is the most important thing here. These skills teach a **method**, not any product's answers. The region tree, the page archetypes, the slot enumeration, the nav segments — every project answers those **for itself**.

If any of these thoughts show up, you are already contaminating the user's product:

| Thought | Reality |
|---|---|
| "Products like this always use three columns" | Three columns was some other product's answer. Ask how many this product needs, and why |
| "A sidebar is standard here" | Standard for whom? Derive it from this product's own objects |
| "I'll start from the usual admin-console skeleton" | The skeleton encodes decisions this product never made |
| "The reference implementation does it this way" | The reference implementation is one product's instance, not a template |

Reference material is for seeing **what a finished shape looks like**, never for copying a specific tree.

## Two different things are both called "exam"

Keep these apart; they are unrelated jobs with different owners.

| Phrase | Means | Owner |
|---|---|---|
| **The wireframe exposes the spec's holes** | Building it surfaces questions the spec never answered. Happens at construction time | `ui-contract-wireframe` / `spec-before-code` |
| **Health check** (体检) | Detecting drift between the specs and the code, months later. Happens at maintenance time | `ui-contract-audit` |

Never call the first one a health check. It was called that once, and the two concepts blurred immediately.

## Canonical term renderings

The skill bodies are in English; deliverables follow the user's language — for that discipline, call the Skill tool with "deliverable-language". This table is the UI-specific half: it pins the rendering so the same concept doesn't get translated differently on every run.

When producing deliverables in a language **not** listed here, pick one rendering per concept, write the choices into a glossary section of `layout.md`, and stay consistent.

| English | 中文 | Notes |
|---|---|---|
| UI contract | UI 契约 | The two specs + wireframe taken together |
| structural spec (`layout.md`) | 结构规范 | Never 布局文档 — it is a contract, not a description |
| visual spec (`design.md`) | 视觉规范 | |
| token file | token 文件 | The single value authority in code |
| single authority | 唯一权威 | Exactly one artifact owns a kind of claim. **Which artifact depends on the kind**: values → the token file; names → `design.md`'s declaration table and `layout.md` §2; rules → the spec clauses themselves. One shape, three owners — not three concepts |
| a second authority | 第二权威 | What the row above forbids. **Never 第二数据源 / 双重来源** — the failure is about *who decides*, not about data sitting in more than one place, and the mistranslation loses exactly that. The primitive layer (`decision-interview`, `decision-record`) states this rule in its own words and is **deliberately not bound by this table**: a primitive has to stand on its own outside UI work, so wiring one to this unit would break that — do not "fix" the difference |
| the swappability line | 切线 | The one cut: does it change when the brand skin changes? |
| pending number (⏳) | 待定数 | A number `layout.md` cannot settle alone, waiting on the visual scale |
| refuted number (⛔) | 已证伪 | Never 待定 — the direction is dead, not waiting. Defined in `ui-contract-layout`'s outline §3 |
| placement decision tree | 落位决策树 | Never 归属判定树 / 放置流程 |
| to place something (a new need) | 落位 | Verb. 「走一遍决策树落位」 |
| region | 区域 | A structural container with a name |
| region-name allowlist | 区域名白名单 | |
| must hold / must not hold (table columns) | 允许放 / **禁止放** | The 禁止放 column is what makes it a spec |
| page archetype | 页型 | Never 页面类型 — too easily confused with a route |
| focus slot | 聚焦槽 | The single slot that shows one object's facet at a time |
| first-class object | 一等对象 | Has identity, can be opened alone, has a lifecycle |
| facet (of an object) | 切面 | What a focus-slot panel shows |
| content routing | 内容分流 | Which class of content lands where |
| nav admission rules | 导航准入 | |
| action / queue / library (nav segments) | 动作 / 队列 / 全局库 | Only if the project's own test produces these three |
| degradation (on narrowing) | 降级 | Never 响应式 — this is a structural cascade, not breakpoints |
| signal rail | 信号条 | What a collapsed column must leave behind |
| overlay | 覆盖层 | The orthogonal full-screen layer |
| low-fidelity wireframe | 低保真线框 | Never 原型图 alone — fidelity is the point |
| projection layer | 投影层 | What the wireframe **is**. Never 参考实现 alone — that names its fidelity, not what it derives from |
| source (of a projection) | 源 | `layout.md` is required; `design.md` and the decision records are optional |
| the handover | 交接 | Where the structural half ends. The visual half is a separate engagement with no arrow into it — never call this a 停点 or draw it as a step |
| annotation layer | 区域标注层 | The inspect mode over the wireframe |
| prototype browser | 原型浏览器 | The apparatus around the projection, as a whole: viewport + corners + panel + wall. Never 控制台 for the whole — that word is the panel's |
| viewport | 视口 | The light-grey rounded area the projection lives in. The panel is outside it |
| corner controls | 角落控制 | Inside the viewport; only what acts on the viewport itself (view switch, lens, canvas background) |
| panel | 控制面板 | Outside the viewport; only what acts on the prototype. Never 演示条 / 开关条 |
| zone (of the panel) | 区 | 选屏 / 条件 / 视图 / 输出 — by what the control changes. Fixed order, closed set |
| readout block | 读数块 | The measured numbers, pinned above the zones |
| choice | 选择器 | The one control; its shape follows the data (开关 / 分段 / 下拉) and is never picked by hand |
| wall | 样张墙 | Every archetype × state × width tier laid out at once. Never 流程图 — it draws no arrows |
| lens | 镜头 | The viewport's zoom. It changes the scale, never the measured width |
| asset layer | 资产层 | Token file + structural components, in the project's production tree |
| deliberate tradeoffs | 刻意的取舍 | The list that stops the next agent from "fixing" them |
| anti-pattern | 反模式 | |
| overturned decisions | 被推翻的 | Appendix that must never be deleted from |
| non-happy-path states | 非常态 | empty / loading / partial failure / whole-region failure |
| cost (of an option) | 代价 | Every interview option needs one |
| enforcement | 强制机制 | The three layers plus the asset boundary |
| health check | 体检 | Drift detection, months later — **not** the wireframe |

## Completion criteria owned here

- [ ] Zero overlap between the two specs; every value lives in exactly one place
- [ ] The few genuine coupling points are marked "⚠ revisit §X of the other spec" **on both sides**
- [ ] No reference product's specific information architecture was written in as universal truth
