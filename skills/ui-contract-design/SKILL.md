---
name: ui-contract-design
description: Align an existing visual spec (design.md) against the structural spec - add the division-of-labor statement, move structural content out leaving a pointer, replace old component-style names with allowlist names, and move literal values into the token file so design.md holds rules rather than values. Use when a project has visual conventions that need to become a spec with a clean boundary. Or originate one when there are none at all - choose a brand direction on attributes rather than colours, derive the values, tune them on a page. Chinese: 生成品牌/配色规范/token 命名/主题调校.
---

# Visual spec — `design.md`

Produces one artifact: `design.md`, plus references into the project's **token file**. Skeleton in [design-md-outline.md](design-md-outline.md). **Read it.**

Two branches, same artifact and same completion criteria — so this is one unit, not two:

| What the project has | Branch |
|---|---|
| A visual spec, a token source, or mockups | **align** — this file, below |
| None of those | **originate** — [originate.md](originate.md). **Read it before asking anything.** |

For the interview discipline, call the Skill tool with "decision-interview".
For which document a thing belongs in, call the Skill tool with "ui-contract-glossary".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".
For handling change requests, call the Skill tool with "spec-before-code".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** The allowlist is what region names get aligned against; without it this step produces a second vocabulary. Call the Skill tool with "ui-contract-layout" first |
| `design.md` exists but `layout.md` does not | **Stop and say so.** Aligning a boundary against a document that doesn't exist means inventing the other half |
| No visual conventions exist anywhere — no `design.md`, no token source, no mockups | **Go to `originate.md`.** Do not start from this file's align procedure — there is nothing to align against |
| Nothing exists **and** the user asks for "something that looks good, you pick" | Still `originate.md`, still the interview. **Do not hand over a default palette.** A palette the user rubber-stamps is no longer their spec, which is the failure this whole method exists to prevent |

## Start by reading `layout.md`'s ⏳ list

Structure and visuals are two dimensions of one interface, so a few numbers belong to neither alone. `layout.md` marks those ⏳ — a fixed panel width, a minimum usable width, a page size — and this step is where they get settled.

**Read that list first.** A type scale chosen without knowing that nine fields and five actions have to fit in 360px is a scale somebody will revisit.

How it runs depends on one thing, and `config.md` records it: **is the same person answering for both dimensions?**

| | How to run it |
|---|---|
| **Same person** | Fold the ⏳ questions into this interview. They are already holding both dimensions in their head; asking in two separate sittings is overhead, and the coupling gets resolved on the spot |
| **Different people** | The ⏳ list **is the handover note.** Bring those numbers to the visual owner as "these three are waiting on your scale" — they should not have to read the whole structural spec to find them. Answers go back into `layout.md`, by its own change process |

**Do not require the two people to be in a room together.** That is often impossible, and a mechanism that assumes it simply fails in that half of the world. The marker travels between them precisely so the meeting is not the mechanism — this whole plugin exists because "somebody will remember to" is not one either.

## This step aligns; it does not rewrite

If the project already has a visual spec, **do not rewrite it.** Four things:

1. **Add the division-of-labor statement** at the top, naming the cut ("does it change when the brand skin changes") and naming the token file as the value authority.
2. **Move structural content out**: region trees, column widths, page archetypes go to `layout.md`. Leave a one-line "structure: see `layout.md` §X" behind, and rename the section if its title promised structure.
3. **Move literal values out to the token file.** Hex codes, px sizes, radius literals become token references. If the project already has a token source (`tailwind.config.*`, `tokens.css`, a theme file), **that is the token file** — do not create a second one.
4. **Align region names with the allowlist.** Old component-style names (camel-cased widget names) must be replaced with allowlist names, or an agent reading both docs gets two vocabularies — and the allowlist mechanism fails on the spot.

**Token names are not part of that.** Region names get aligned; token names do not. Record what the project already calls them in the declaration table, marked `this project`, and change nothing. Renaming tokens turns a boundary alignment into a repo-wide rename that touches every consumer — a change request, which goes through `spec-before-code`.

Appendices that record **mockup** reality (value-drift mapping tables and the like) **stay untouched** — they document the mockup, not the spec.

## The document is the name authority

The token file holds the **values**; this document settles which **names** exist. Say so in the opening blockquote, and carry the declaration table (`design-md-outline.md` §Opening) with it.

This has to be written down for the same reason the value authority is: without it, a borrowed naming convention quietly becomes the authority instead, and **nothing in the output shows it** — a token file produced either way is byte-for-byte the same. The health check reads its whitelist from that table, so a missing table degrades the check to nothing.

The same applies to `tokens.input.json` when the `originate` branch produced one:

| | Records | On conflict |
|---|---|---|
| `tokens.input.json` | where the user left the knobs (an input record) | does not count |
| the token file | the values that are currently correct | wins |

Its keys are the names from the declaration table. Per-stack mapping changes the format, never the names.

## When there is no token file yet

Say so **in the document, not only in the report** — the reader who never sees the report is the one this has to reach. Write the token references as they should be, and two things with them:

- **Name no path that is not on disk.** Write "the token file is the value authority; this project does not have one yet" rather than pointing at `src/tokens.css` and hoping. Following a pointer to a missing file is how a reader concludes the whole spec is stale.
- **Say who closes the gap.** On the `align` branch no unit generates the token file — the asset layer produces structural components only, so whoever builds it fills in the values under the names written here. **On the `originate` branch this section does not apply**: that branch derives the values and writes the token file itself, so a deliverable from it should never contain "there is no token file yet".

Do **not** silently invent values back into `design.md` to make it self-contained. A document that quietly re-absorbs its values is exactly the second value authority this rule exists to prevent.

## Before you call this document done

- [ ] **Every ⏳ in `layout.md` was resolved, or is explicitly left open with a reason** — and read **before** settling the scales, not after: a scale chosen without knowing what has to fit at it is a scale that will be revisited
- [ ] **Resolving one means editing `layout.md`** — the ⏳ becomes a plain number. Not the type size written into `layout.md`, not the width copied into `design.md`: both directions are the bleed the split exists to prevent
- [ ] `design.md` contains no literal color or size values; the token file is the single value authority
- [ ] Structural content has been moved out and only a one-line pointer remains
- [ ] Every region name matches the allowlist; no old component-style naming survives in the normative body
- [ ] Mockup-reality appendices were left alone
- [ ] If no token file exists yet, `design.md` says so in its own body, and no path to a missing file is written anywhere in it
- [ ] The declaration table is present in the opening section, one row per token, each row marked `borrowed` / `this project` / `not used` — **those three keywords in ASCII even in a non-English deliverable**, because the health check anchors on them and a translation silently turns the check off
- [ ] Every row marked `borrowed` is actually in the borrowed set; no `sidebar-*` and no `chart-*` among them
- [ ] Chapters the borrowed set does not cover say so, and their names follow the pairing rule
- [ ] On the `originate` branch: the three directions differ on at least two axes, and each cost is a consequence in this product rather than an adjective
- [ ] On the `originate` branch: every derived value traces to a coordinate, and the **hue's basis is named in `design.md` §1** — one of the four in `originate.md` §The gap the axes do not close, or an explicit "none applies" that marks the hue as the weakest value in the set. The axes fix count and saturation but not hue, so it is the one slot with no source
- [ ] On the `originate` branch: no value in `tokens.input.json` is a framework default (the list is in `originate.md` §Do not emit a framework default) — emitting one means the coordinates never reached the values
- [ ] On the `originate` branch: the hue's basis is stated **without a literal colour** — not the chosen value, not the default being contrasted against. `design.md` carries no hex anywhere, and explaining a choice is not an exemption from that
- [ ] On the `originate` branch: **the token file itself was written** — the real one, at the path and format the paths table gives, committed. Not described, not left for another unit: the old handoff landed 2 of 5 runs
- [ ] On the `originate` branch: `tokens.input.json` was also written, at **`.ui-contract-local/tokens.input.json`** — pinned, not configurable, because the instrument and a grader both need one answer
- [ ] On the `originate` branch: **the user was not told to keep or commit the knobs record.** It is not a deliverable; describing it as one invites somebody to maintain a file nothing reads
- [ ] On the `originate` branch: **the two are not confused in the deliverable** (identity table above). Describing the record as where the values live is the second value authority this split exists to prevent
- [ ] Reported to the user: which sections were touched, how many names were replaced, what was deliberately left alone
