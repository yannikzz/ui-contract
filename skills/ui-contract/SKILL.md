---
name: ui-contract
description: Establish a project's UI contract by interview: layout.md (structural spec - placement decision tree, region-name allowlist, extension rules), design.md (visual spec; the token file holds values), an asset layer in the production tree, a low-fidelity wireframe, and enforcement that stops agents putting features in the wrong place. Use when the user wants a design system or design spec, a layout or structure spec, information architecture (IA), a module or region breakdown, rules for where a new feature goes, a way to stop a team or an AI agent from drifting the interface structure, to turn Figma mockups into something developers can build against, or an interface skeleton / wireframe for team alignment. Also triggers on: "new features keep landing in random places", "our UI gets messier every sprint", "make the AI stop restructuring my frontend". Chinese: 界面规范/布局规范/结构规范/信息架构/设计规范/设计系统/线框图/界面骨架/新功能该放哪/界面越改越乱.
compatibility: Works in any agent with filesystem access. The asset layer and wireframe need Node and a TypeScript toolchain; without TypeScript the compile-time allowlist cannot be enforced and degrades to an honor-system rule.
metadata:
  author: yannikzz
  version: "0.2.0"
---

# UI contract — orchestration

This unit **routes**. It produces no artifacts of its own; every artifact belongs to one of the units below.

For what each artifact owns and the one cut between them, call the Skill tool with "ui-contract-glossary".

## Identify where the project already is

Read the disk before asking anything. Each unit's output is the next one's input, so the starting point is whatever is already on disk — never whatever the conversation happens to remember.

| Already on disk | Enter at |
|---|---|
| Nothing | `ui-contract-setup` |
| `docs/ui-contract/config.md`, and the repo has frontend code | `ui-contract-baseline` |
| `config.md`, greenfield | `ui-contract-layout` |
| `layout.md` | `ui-contract-design`, or straight to `ui-contract-assets` / `ui-contract-enforce` |
| `layout.md` + `design.md` | `ui-contract-assets` |
| Asset layer exists | `ui-contract-wireframe` / `ui-contract-enforce` |
| Everything exists, and the question is whether it still holds | `ui-contract-audit` |

**Entering in the middle is normal, not an exception.** In a real product the person who writes the information architecture and the person who does the visual work are usually different people, with a review in between; the frontend engineer picks it up weeks after both are done. Each unit reads its inputs from disk and must not re-ask questions an earlier unit already answered.

## The order

```
setup ─┬─ (existing project) baseline ─┐
       └─ (greenfield) ────────────────┴─→ layout ─→ design ─→ assets ─→ wireframe
                                                        └────────────────→ enforce
                                                                          audit
```

Both starting points run the same units; the only difference is whether `baseline` runs.

**Do not reverse the order.** Wireframe first, spec second, and the spec degrades into a description of existing code rather than a constraint on future code.

That rule can no longer be enforced from here, because any unit can be entered directly. Each capability unit therefore carries its own precondition gate — that is where "don't reverse the order" actually lives now. Those gates catch a **missing** upstream artifact; they cannot catch an upstream artifact that was written afterwards by reading the code. If you can see that has happened, say so.

## The units

| Layer | Unit | Produces |
|---|---|---|
| Primitive | `decision-interview` · `spec-before-code` · `constraint-by-types` · `decision-record` · `deliverable-language` | — |
| Vocabulary | `ui-contract-glossary` | — |
| Fact | `ui-contract-setup` | `docs/ui-contract/config.md` |
| Fact | `ui-contract-baseline` | `as-built.md` |
| Capability | `ui-contract-layout` | `layout.md` |
| Capability | `ui-contract-design` | `design.md` + token references |
| Capability | `ui-contract-assets` | Asset layer in the production tree |
| Capability | `ui-contract-wireframe` | Runnable wireframe |
| Capability | `ui-contract-enforce` | Repo-root `CLAUDE.md` + type-layer constraints |
| Capability | `ui-contract-audit` | Health-check script + difference report |

Invoke each by calling the Skill tool with its name.

## Where decisions get recorded

| | Records | Lives in |
|---|---|---|
| Rule | What is currently correct | `layout.md` / `design.md` clauses — the single authority |
| Decision | Why it was chosen, what was excluded, when to revisit | `docs/ui-contract/adr/layout/` or `docs/ui-contract/adr/design/` |

Which of the two ADR directories a decision goes in uses **the same cut, with no new vocabulary**: changes when the brand skin changes → `adr/design/`; doesn't → `adr/layout/`.

A repo's existing `docs/adr/` is the code and architecture namespace. **Do not merge into it** — different category, separate numbering.

## Before you tell the user it's done

- [ ] The user can say what each artifact owns, and which one to open first next time they add a feature

That last one is the easiest to skip. Tell them in plain language **what you did / why / where it may differ from what they expected**, and be explicit about what you verified and what you didn't. You usually cannot verify rendered output — say so, and let them look.
