---
name: ui-contract-wireframe
description: Build the runnable low-fidelity wireframe that consumes the asset layer - an annotation layer over every region, real copy and real density, degradation rules actually implemented, and the asset layer's brand deliberately overridden to neutral greys. Use when the specs exist and a runnable structural reference is needed before feature code is written.
---

# Wireframe — the display layer

Produces a small standalone project: a low-fidelity, runnable reference implementation. Implementation guide in [implementation.md](implementation.md); the starting point for the display file is [assets/wire.tsx.template](assets/wire.tsx.template). **Read both.**

For the interview discipline, call the Skill tool with "decision-interview".
For writing rules back when construction exposes a hole, call the Skill tool with "spec-before-code".
For the type-checking requirement, call the Skill tool with "constraint-by-types".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** There is no structure to implement |
| The asset layer does not exist | **Stop.** Call the Skill tool with "ui-contract-assets" first. The wireframe consumes the allowlist; it must not define one |
| Region markers or a `RegionId` type exist in code, but `layout.md` does not | **Stop and say so.** Building the wireframe now would let the code become the spec's source |

The second row is the whole point of the split. A wireframe that declares its own region names gives the project two allowlists, and the compile-time layer then guards the wrong one.

## The one question this unit asks

**What fidelity?**

| Option | You get | You lose |
|---|---|---|
| Low fidelity with real copy and real density (recommended) | You can judge "does the structure hold, does the interaction land where it should"; density problems surface immediately | Slightly more work than grey boxes |
| Grey-box placeholders | Fastest | Density problems stay hidden — and layout specs most often break on density |

Neither carries brand visuals. If the user also wants to validate that the visual spec is implementable, that is a **separate task** (one screen, full fidelity) — don't fold it in.

## Building it exposes the spec's holes

You will find holes while building: what a region shows under a particular archetype was never decided; the overlay covers the title bar so it needs its own header. That exposure is the point.

**Write the doc first, then change the code.** Never quietly add a rule to the code that the document doesn't state.

Note the vocabulary: this is the wireframe **exposing holes**, at construction time. It is not a health check — that word belongs to drift detection months later, and confusing the two was a real failure once.

## Before you call this done

- [ ] It runs, and the dev server was started for the user
- [ ] Type-checking actually ran, with output pasted
- [ ] Density is real — real copy, real row counts, the realistic ceiling — not a shell
- [ ] Every region renders through `AnnotatedRegion`, with ids imported from the asset layer
- [ ] No region name is declared in the wireframe
- [ ] The asset layer's brand is overridden to neutral, and the directory `CLAUDE.md` says that is deliberate
- [ ] Degradation rules are implemented and their live computation is on screen — **this one is on loan**, see below
- [ ] Stated plainly what was verified and what wasn't

The degradation item was ruled to belong to the asset layer, not here. It stays for now because the asset layer has no `Shell` to carry it yet, so dropping it would mean nobody implements the rules at all. Recorded as item 9 in ADR-0003's deferred list; when `Shell` lands, this moves with it.
