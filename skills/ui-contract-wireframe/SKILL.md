---
name: ui-contract-wireframe
description: Build the runnable low-fidelity wireframe that consumes the asset layer - an annotation layer over every region, real copy and real density, degradation rules actually implemented, and the asset layer's brand deliberately overridden to neutral greys. Use when the structural spec exists and a runnable reference is needed before feature code is written - the visual spec is an optional input, not a prerequisite.
---

# Wireframe — the display layer

Produces a small standalone project: a low-fidelity, runnable reference implementation. Implementation guide in [implementation.md](implementation.md); the starting point for the display file is [assets/wire.tsx.template](assets/wire.tsx.template). **Read both.** [skin-preview.md](skin-preview.md) is the second-pass half — read it only once `design.md` is connected, because until then there is no token file for a preview to read.

## What this is: a projection, not a station

**For what a projection layer is — what it projects, which source is required, why grey is a finished state rather than a placeholder — call the Skill tool with "ui-contract-glossary".** Do not restate it here; that definition has one home and this unit is a consumer of it.

What is local to this unit, and would be wrong to look for anywhere else:

1. **It runs at the end of each half, and it is the same layer both times.** The structural half finishes here with `layout.md` alone connected; the visual half finishes here again with `design.md` connected, so the skin has something to read. One layer rebuilt — **do not keep the first one around to compare against.**
2. **Nothing is settled here.** A number only the projection could reveal — a density that does not fit — goes back into `layout.md` first, and the projection is rebuilt from it. The direction is always source → projection, never the reverse.
3. **It lives in the workbench, uncommitted, and does not survive a fresh clone.** So build it early and throw it away often — and never hand it over as the deliverable or ask anyone to sign off on it.
4. **Do not contradict the decision records.** They hold what was *excluded*; a projection that puts an excluded shape on screen shows the reader a decision that was made against. **Nothing checks this** — it is the one thing in this unit with no mechanism behind it.

For the interview discipline, call the Skill tool with "decision-interview".
For what each artifact owns and the one cut between them, call the Skill tool with "ui-contract-glossary".
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

**The list has two tiers, and the split is by what you need in order to do the line — not by how
important it is.** Tier 1 needs nothing but the ability to write files, so "I couldn't" never applies
to it. Tier 2 needs `Bash` and Node; when you do not have them you do not quietly drop those lines,
you **name each one** and hand over the command that closes it. This split exists because the other
reading was measured: an agent with no `Bash` reasoned "can't run it, so won't build it" and left the
user with no projection at all — and the projection is the only way they can see whether the structure holds.

### Tier 1 — the file layer. Nothing here is conditional.

- [ ] **It was built inside the workbench**, at the path the config's paths table gives — and that path has a line in `.gitignore`
- [ ] **The regeneration steps are in the repo-root `CLAUDE.md`** (which is committed), because a fresh clone has no wireframe and nothing else will say how to get one
- [ ] **Neither the generated `CLAUDE.md` nor the `README.md` calls it "a runnable reference for coding agents" unqualified** — it is a local one; say so and name the way back
- [ ] No colour value appears outside the `NEUTRAL` map and `inspect.tsx` — **checked in every file**; the skin preview is off by default and is not persisted
- [ ] **`check-colours.sh` was shipped with the wireframe and wired into the task runner.** It is not a CI gate (the workbench is not committed), so the moment it runs is the only moment the rule is mechanical
- [ ] **`inspect.tsx` exists and its exports match the declared list** in both the file's header and `check-colours.sh`. The exemption is that file; an undeclared export there is a product component that just bought the right to hardcode colour
- [ ] The demo toggle bar, the annotation layer, the skin banner and the editor panel all keep fixed colours; turning the skin on cannot make the control that turns it off unreadable
- [ ] The user was told, in words, that the editor writes nothing and its edits die with the tab — and that the prompt is what carries them out
- [ ] The directory `CLAUDE.md` lists "grey by default, preview off by default" as deliberate — not as a gap to fill
- [ ] **The fixture copy was written to an input record in the workbench, not invented afresh each rebuild.** Real copy is in none of the sources — not `layout.md` (content is not structure), not `design.md`. So the one reading only this projection can give, density, is the one thing that changes when it is rebuilt, unless the copy is recorded. Same shape as `tokens.input.json`: an input record, not committed, not an authority, losing every disagreement with a source
- [ ] Every region renders through `AnnotatedRegion`, with ids imported from the asset layer
- [ ] No region name is declared in the wireframe
- [ ] **No closed set the spec declares is declared here either** — page archetypes, which archetypes carry a panel, table column kinds. They are imported from the asset layer. A prohibition encoded in a throwaway file constrains only the throwaway file, while reading exactly like one that constrains the product (`ui-contract-assets` §The prohibition types belong here)
- [ ] The asset layer's brand is overridden to neutral, and the directory `CLAUDE.md` says that is deliberate
- [ ] Degradation rules are implemented and their live computation is on screen — **this one is on loan**, see below

### Tier 2 — the run layer. Needs `Bash` and Node.

- [ ] It runs, and the dev server was started for the user
- [ ] **`check-colours.sh` was actually run, with its real output pasted.** Shipping it is tier 1; running it is this tier, and the two are not the same act — the header of that script says the moment it runs is the only moment the rule is mechanical, and a shipped-but-never-run script has not had that moment
- [ ] Type-checking actually ran, with output pasted
- [ ] Density is real — real copy, real row counts, the realistic ceiling — not a shell

### If tier 2 cannot run

- [ ] **Every tier-2 line above is named individually as not done** — not one sentence covering all of them.
      "I could not verify rendered output" is the sentence that hides which of four things is missing
- [ ] **The commands that close them are handed over**, ready to paste (`npm i`, the dev-server script,
      the type-check script, `sh ./check-colours.sh`). The user's machine is not the one missing the tools
- [ ] **Density is called out separately from the ⏳ list.** The ⏳ numbers wait for the visual half to
      settle them; density waits for somebody to render it and look. Different recipients, so a single
      "still open" list sends one of them to the wrong person, and nothing downstream picks it up —
      the visual interview does not ask about density, and the health check is drift detection months later
- [ ] **Not described as grey-by-default's kind of incomplete.** Grey means an optional source is not
      connected and the projection is still whole — for that, call the Skill tool with "ui-contract-glossary".
      This means the artifact is whole and the
      *readings* are missing. Saying it the first way turns "I did not verify" into "this is by design"

- [ ] Stated plainly what was verified and what wasn't

The degradation item was ruled to belong to the asset layer, not here. It stays for now because the asset layer has no `Shell` to carry it yet, so dropping it would mean nobody implements the rules at all. `ui-contract-assets` records the same deferral from the other side; when `Shell` lands there, this moves with it.

**Treat that as a named exemption with an expiry, not as how things are.** It is the one thing in this unit that is not a projection of a source — an implementation the product needs, living in a file the product throws away. The expiry is `Shell` landing in the asset layer. An exemption carried without an expiry stops reading as a debt and starts reading as a design, and then nobody collects it.
