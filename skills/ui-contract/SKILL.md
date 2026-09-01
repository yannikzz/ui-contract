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
| `layout.md`, and a visual spec / token source already exists | `ui-contract-design`, **align** branch — a boundary cleanup, not the visual half. It needs the "may the existing spec be edited" authorisation, not the scope one |
| `layout.md`, no visual conventions anywhere, visual half **not** authorised | `ui-contract-assets` → `ui-contract-enforce` (entry layer) → `ui-contract-wireframe`. The structural half ends there |
| `layout.md`, no visual conventions anywhere, visual half **is** authorised | `ui-contract-design`, **originate** branch — entered from here, never as a next step |
| `layout.md` + `design.md` | `ui-contract-assets` |
| Asset layer exists | `ui-contract-wireframe` / `ui-contract-enforce` |
| Everything exists, and the question is whether it still holds | `ui-contract-audit` |

**Entering in the middle is normal, not an exception.** In a real product the person who writes the information architecture and the person who does the visual work are usually different people, with a review in between; the frontend engineer picks it up weeks after both are done. Each unit reads its inputs from disk and must not re-ask questions an earlier unit already answered.

## The order

```
   structural half
   setup ─┬─ (existing project) baseline ─┐
          └─ (greenfield) ────────────────┴─→ layout ─→ assets ─→ enforce (entry) ─→ wireframe

   ─────────── entered again, separately. No edge crosses this line. ───────────

   visual half
                      design ─→ assets (2nd pass) ─→ enforce (type layer) ─→ wireframe

   audit — maintenance time, months later. On neither line.
```

Both starting points run the same units; the only difference is whether `baseline` runs.

**Each half ends at the wireframe, and for the same reason both times: a source just changed, so
the projection is rebuilt.** The first pass projects `layout.md` alone and comes out grey. The
second has `design.md` connected, so the skin has something to read. It is the same layer both
times, rebuilt — not two artifacts, and not a step that produces something new to keep.

**What separates the two halves is the absence of an edge, not a step that says "halt".** There is
nothing on the line to walk past: `design` has no incoming arrow, so reaching it means entering
from the routing table above, with the authorisation that table asks for. Drawing a halt would be
weaker *and* wrong — weaker because a prohibition can be read and walked past (measured here, on
this plugin, with the full text of the gate in front of the reader), and wrong because it would
put the visual half's absence on the line as if it were work the structural half performs.

### Two orders that read alike and are opposite

| | Verdict | The mechanism behind the verdict |
|---|---|---|
| wireframe **before `layout.md`** | **Forbidden** | The spec would then be written by reading the wireframe, which makes it a description of what exists rather than a constraint on what comes next |
| wireframe **before `design.md`** | **Normal, and usually what happens** | The projection carries no brand values at all — and that is mechanically checked by the colour check shipped with it — so a visual spec has nothing there to describe |

The second is **not an exception to the first.** They differ in what is being read off what: in the
first, structure is read off a drawing; in the second, there is nothing to read, by construction.

Any unit can still be entered directly, so each capability unit carries its own precondition gate.
Those gates catch a **missing** upstream artifact; they cannot catch an upstream artifact that was
written afterwards by reading the code. If you can see that has happened, say so.

## Where the structural half ends

It ends after the projection has been rebuilt, and what it hands back is **`layout.md`** — the
artifact that gets committed, reviewed and signed off. The projection is rebuilt so the user has
something to look *at* while judging it; it is a viewing device, not a deliverable, and it does
not survive a fresh clone. Never describe the wireframe as the thing being delivered, and never
ask the user to sign off on it: it is regenerated from `layout.md`, so signing off on it signs
off on nothing that lasts.

On a greenfield project exactly one file is committed at that point: `layout.md`. The asset layer
and the projection are both in the workbench — the asset layer because it is production code and
writing it into somebody's tree is theirs to authorise, the projection because it is thrown away.
`ui-contract-assets` says when the asset layer moves.

**"The visual half" means originating one.** Slimming a visual spec the project already has — moving structural content out and leaving a pointer — is a boundary cleanup the structural half needs anyway, and it is authorised separately. `ui-contract-design` draws that line inside itself.

Whether the visual half follows immediately or later is **not this unit's guess**. Two answers in
`docs/ui-contract/config.md` settle it, and `ui-contract-setup` asks them separately on purpose:
**how far this session is authorised to go**, and **who answers for the visual half**. Merging them produces a session authorised to write a visual spec with nobody to
answer for it — which is exactly how a spec nobody asked for gets written.

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

That last one is the easiest to skip. Tell them in plain language **what you did / why / where it may differ from what they expected**, and be explicit about what you verified and what you didn't.

**"You usually cannot verify rendered output" is not a standing fact — check before you assert it.** With browser tooling available, a wireframe can be opened, its console captured and a screenshot taken; with `Bash` and Node, the dev server, the type-check and `check-colours.sh` all run. Whether you have those changes what "verified" means, so **branch on what you actually have** rather than declaring blindness by default:

| What you have | What to say |
|---|---|
| Browser tooling | You looked. Say what you saw, and what the screenshot does not settle |
| `Bash` and Node, no browser | It builds, type-checks and passes the colour check. **Nobody has looked at it** — density is the reading that needs eyes |
| Neither | Name each unrun check individually and hand over the commands. The artifact is whole and the *readings* are missing — that is a different sentence from "grey by default", which is a source not being connected |
