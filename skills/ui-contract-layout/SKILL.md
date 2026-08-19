---
name: ui-contract-layout
description: Produce layout.md, the structural spec - a total placement decision tree, a region-name allowlist where every row states what it must not hold, extension rules, content routing and degradation rules. Everything that does not change when the brand skin changes. Use when a project needs written rules for where a new feature goes.
---

# Structural spec — `layout.md`

Produces one artifact: `layout.md`. Skeleton and per-chapter requirements are in [layout-md-outline.md](layout-md-outline.md). The question bank is [interview-layout.md](interview-layout.md). **Read both.**

For the interview discipline, call the Skill tool with "decision-interview".
For which document a thing belongs in, call the Skill tool with "ui-contract-glossary".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".
For handling change requests once something is running, call the Skill tool with "spec-before-code".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


Check these **before asking anything**. All three are hard stops, not warnings.

| Condition | Action |
|---|---|
| The repo has frontend code, **and** there is no `as-built.md`, **and** `layout.md` does not yet exist | **Stop.** Call the Skill tool with "ui-contract-baseline" first |
| A wireframe, a `RegionId` type, or region markers already exist in code, but `layout.md` does not | **Stop and say so.** The spec would be written by reading the code, which makes it a description of what exists rather than a constraint on what comes next. Run `ui-contract-baseline` to record the as-built state honestly, then write the spec against it |
| All you have is a product idea or a paragraph — **no enumerable feature list**, and no code or mockups to read one off | **Stop and say why.** This plugin constrains where interface structure goes; it does not do product discovery and does not make feature tradeoffs. Ask for the feature list — roughly, what a user can *do* — and come back. Say plainly that you are declining a step, not failing at one |

The first row's third clause matters: **once `layout.md` exists, this gate must not fire again.** Without it, every later maintenance edit on an existing project is blocked forever.

The third row is the upstream boundary from ADR-0001, and it is narrow on purpose. It fires on *nothing to place*, not on *vague*: a rough list of features is workable input, and sharpening it is what the interview is for. A product that has not decided what it does yet cannot have a region tree, and inventing one produces a spec that constrains nothing — every later feature lands outside it, so the placement tree sends everything to §9 and the contract degrades into a permission queue.

## Three things decide whether this document is useful at all

**1. The placement decision tree goes first (§1), and it has to be total.**

It is the entry point: an agent takes a new requirement, walks the tree, implements directly if it lands — and **stops if it doesn't**. Total means every input reaches exactly one region name or the explicit stop, never zero and never two.

A tree with a hole is worse than no tree: agents don't halt at a hole, they improvise past it **with the document's authority behind them**.

The fallback must be the explicit **stop → §9**, never some real region, and it must not route back into the tree.

**2. Every row of the region allowlist (§2) needs a "must not hold" cell.**

Listing only what goes in a region is documentation; stating what must *not* go in is a spec. The forbidden entries come from every "don't make it X" conclusion in the interview. This column is also the only thing the compile-time layer can act on later.

**3. Every anti-pattern carries a reason and a replacement.**

"Don't do X" gets worked around. "Don't do X, because it causes Y, do Z instead" gets followed.

## No visual values

`layout.md` contains **no color values, font sizes, radii, or spacing values** — only structural parameters (column widths, minimum sizes, region counts, grid columns). Where a value is needed, write "see `design.md` §X".

Region **descriptions** say **what goes here / what must not** — never "what this is", which is visible from the screen. A wrong description is more dangerous than wrong code, because the next agent extends from it.

## Before you call this document done

- [ ] No color / font-size / radius / spacing values anywhere
- [ ] Traced the decision tree with **hostile** inputs — a one-off action belonging to no object, something that fits two regions, something arriving at a full cap, something that plainly doesn't belong — and each landed on exactly one region name or the explicit stop
- [ ] The fallback is *stop → §9*, not a real region, and it doesn't route back into the tree
- [ ] Traced three or four **ordinary** requirements and watched each land on a region name (stopping on everything passes the hostile traces too — and turns the contract into a permission queue)
- [ ] Every allowlist row has a "must not hold" cell, none of them empty
- [ ] Every anti-pattern has a reason and a replacement
- [ ] Every region description says "what goes here / what must not", not "what this is"
