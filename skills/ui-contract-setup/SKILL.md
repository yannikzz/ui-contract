---
name: ui-contract-setup
description: Survey what a repo already has before any UI contract work starts - existing visual specs, token sources, structural docs, frontend stack and agent instructions - classify the starting point, and ask only the authorisations that cannot be derived from disk. Writes docs/ui-contract/config.md plus a pointer line in the repo-root CLAUDE.md.
---

# Setup — survey and authorisations

Produces `docs/ui-contract/config.md` (template: [config-template.md](config-template.md)) and one pointer line in the repo-root `CLAUDE.md`.

For the interview discipline, call the Skill tool with "decision-interview".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Look things up yourself

**Do not ask the user anything you can find.** Glob and grep for:

- Existing `design.md` / `DESIGN.md` / `design-system.md` / `tokens.css` / `tailwind.config.*` / `theme.*`
- Existing `layout.md` / `IA.md` / `architecture.md` / any doc that already describes structure
- Existing prototype or frontend code: stack, component layout, whether TypeScript is in use
- `CLAUDE.md` / `AGENTS.md` at the repo root and in subdirectories
- `docs/adr/` — note it, but **do not merge into it**. That directory is the code and architecture namespace; interface-structure and visual decisions are a different category and get their own

## Classify the start

| Start | Looks like | Approach |
|---|---|---|
| **A — greenfield** | A feature list; no mockups, no docs | Spend an extra interview round on form factor and first-class objects — there is nothing to reverse-engineer. **If there is no feature list either — just an idea — say so now**: that is `ui-contract-layout`'s third precondition and it will stop there anyway. This plugin does not do product discovery |
| **B — mockups exist** | Figma screenshots, design images, competitor screenshots; no docs | Reverse-engineer first, then interview |
| **C — visual spec exists, structural spec missing** | A `design.md` or token system exists, but nobody ever wrote down where new features go | **The most common case.** Focus on cutting the boundary and moving structural content out of the existing doc |

Whichever artifact already exists, **do not rebuild it** — but do align the boundary. An existing visual spec almost always has structural content mixed in.

Tell the user which start you identified and what you found, then proceed.

## Ask only what cannot be derived

Three things, and nothing else:

1. **May the existing visual spec be edited?** Aligning the boundary means slimming that document — structural content moves out. That is somebody's document; ask before touching it.
2. **Where do the files go and what are they called?** **Default: both specs at the repo root**, side by side, so they apply across sub-projects. `docs/ui-contract/` holds the config and the decision records — **not the specs**. The wireframe gets its own directory.

   Only move the specs elsewhere if the user says so, and **record the chosen paths in the config file's paths table**. Every later unit reads that table instead of guessing: the root `CLAUDE.md` entry clause points at the structural spec by path, the capability units gate on its existence, and the health-check script greps it. A spec that quietly lands somewhere else silently breaks all three at once.
3. **Where does the asset layer live** in the production tree?

Everything else waits. In particular, **do not ask about legacy strategy here** — freeze line, migrate first, hybrid. That question cannot be answered before the gap has been measured, and asking it early only produces a guess. It belongs to `ui-contract-baseline`, which writes its answer into the same config file.

## Writing discipline

- If a config file already exists, **update it in place**; do not create a second one
- **Skip sections that are already settled** — don't re-ask what the file already answers
- The repo-root `CLAUDE.md` gets **one pointer line**, not a copy of the config
- Fill in **Not verified this round** before you say you are done. Anything reached by inference rather than by reading it off the disk or off a design goes there — it is the one section that tells the next reader which conclusions have evidence behind them. Skipping it is what makes a guess indistinguishable from a measurement six months later
