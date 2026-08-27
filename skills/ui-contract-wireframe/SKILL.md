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

Neither carries brand **values** — both default to grey, and both can turn the skin preview on, which reads the token file live. If the user also wants to validate that the visual spec is implementable, that is a **separate task** (one screen, full fidelity) — don't fold it in.

## Building it exposes the spec's holes

You will find holes while building: what a region shows under a particular archetype was never decided; the overlay covers the title bar so it needs its own header. That exposure is the point.

**Write the doc first, then change the code.** Never quietly add a rule to the code that the document doesn't state.

Note the vocabulary: this is the wireframe **exposing holes**, at construction time. It is not a health check — that word belongs to drift detection months later, and confusing the two was a real failure once.

## Before you call this done

- [ ] It runs, and the dev server was started for the user
- [ ] **It was built inside the workbench**, at the path the config's paths table gives — and that path has a line in `.gitignore`
- [ ] **The regeneration steps are in the repo-root `CLAUDE.md`** (which is committed), because a fresh clone has no wireframe and nothing else will say how to get one
- [ ] **Neither the generated `CLAUDE.md` nor the `README.md` calls it "a runnable reference for coding agents" unqualified** — it is a local one; say so and name the way back
- [ ] No colour value appears outside the `NEUTRAL` map and `inspect.tsx` — **checked in every file**; the skin preview is off by default and is not persisted
- [ ] **`check-colours.sh` was shipped with the wireframe, wired into the task runner, and run — with its real output pasted.** It is not a CI gate (the workbench is not committed), so the moment it runs is the only moment the rule is mechanical
- [ ] **`inspect.tsx` exists and its exports match the declared list** in both the file's header and `check-colours.sh`. The exemption is that file; an undeclared export there is a product component that just bought the right to hardcode colour
- [ ] The demo toggle bar, the annotation layer, the skin banner and the editor panel all keep fixed colours; turning the skin on cannot make the control that turns it off unreadable
- [ ] The user was told, in words, that the editor writes nothing and its edits die with the tab — and that the prompt is what carries them out
- [ ] The directory `CLAUDE.md` lists "grey by default, preview off by default" as deliberate — not as a gap to fill
- [ ] Type-checking actually ran, with output pasted
- [ ] Density is real — real copy, real row counts, the realistic ceiling — not a shell
- [ ] Every region renders through `AnnotatedRegion`, with ids imported from the asset layer
- [ ] No region name is declared in the wireframe
- [ ] **No closed set the spec declares is declared here either** — page archetypes, which archetypes carry a panel, table column kinds. They are imported from the asset layer. A prohibition encoded in a throwaway file constrains only the throwaway file, while reading exactly like one that constrains the product (`ui-contract-assets` §The prohibition types belong here)
- [ ] The asset layer's brand is overridden to neutral, and the directory `CLAUDE.md` says that is deliberate
- [ ] Degradation rules are implemented and their live computation is on screen — **this one is on loan**, see below
- [ ] Stated plainly what was verified and what wasn't

The degradation item was ruled to belong to the asset layer, not here. It stays for now because the asset layer has no `Shell` to carry it yet, so dropping it would mean nobody implements the rules at all. `ui-contract-assets` records the same deferral from the other side; when `Shell` lands there, this moves with it.
