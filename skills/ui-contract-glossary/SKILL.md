---
name: ui-contract-glossary
description: The vocabulary of a UI contract - what the structural spec, the visual spec and the wireframe each own, the single cut between them (does it change when the brand skin changes), how to mark the few genuine coupling points, and the canonical term renderings. Use when another ui-contract skill needs to decide which document a piece of content belongs in.
---

# UI contract — vocabulary

This skill decides **which document a thing belongs in**. It produces no artifacts of its own.

## What the artifacts own

| Artifact | Owns | Test |
|---|---|---|
| `layout.md` | **Structure**: region tree, column widths, page archetypes, extension-slot enumerations, content routing, switching rules | Things that **do not** change when you swap the brand skin |
| `design.md` | **Visual**: type, color, shadow, radius, spacing scale, interaction-state styling, component variants — **as rules, not as values** | Things that **do** change when you swap the brand skin |
| Token file | The **values** those rules refer to. The single value authority in code | — |
| Wireframe | The runnable, low-fidelity reference implementation, **deliberately carrying no brand visuals** | Agents copy structure instead of guessing it |

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
| the swappability line | 切线 | The one cut: does it change when the brand skin changes? |
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
| annotation layer | 区域标注层 | The inspect mode over the wireframe |
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
